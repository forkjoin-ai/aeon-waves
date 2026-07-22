// becky.go -- GG compiler in Go.
//
// Same two-sweep architecture as Rust Becky:
// 1. Strip comments, sweep for edges (create nodes lazily)
// 2. Sweep for standalone node declarations
// 3. Compute beta-1, void dimensions, Landauer heat, deficit
//
// Usage:
//   go run becky.go betti.gg
//   go run becky.go --beta1 betti.gg
//   go run becky.go --summary betti.gg
//   go run becky.go --bench 100000 betti.gg

package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// ═══════════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════════

type GgNode struct {
	ID         string            `json:"id"`
	Labels     []string          `json:"labels"`
	Properties map[string]string `json:"properties"`
}

type GgEdge struct {
	SourceIDs  []string          `json:"sourceIds"`
	TargetIDs  []string          `json:"targetIds"`
	EdgeType   string            `json:"type"`
	Properties map[string]string `json:"properties"`
}

type GgProgram struct {
	Nodes map[string]*GgNode `json:"nodes"`
	Edges []GgEdge           `json:"edges"`
}

type Diagnostic struct {
	Code     string `json:"code"`
	Message  string `json:"message"`
	Severity string `json:"severity"`
}

type BeckyResult struct {
	Program        GgProgram    `json:"program"`
	Beta1          int          `json:"beta1"`
	Diagnostics    []Diagnostic `json:"diagnostics"`
	VoidDimensions int          `json:"void_dimensions"`
	LandauerHeat   float64      `json:"landauer_heat"`
	TotalDeficit   int          `json:"total_deficit"`
}

// ═══════════════════════════════════════════════════════════════════════════════
// Parser
// ═══════════════════════════════════════════════════════════════════════════════

var (
	edgeRegex = regexp.MustCompile(`\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)`)
	nodeRegex = regexp.MustCompile(`\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)`)
)

func stripComments(source string) string {
	lines := strings.Split(source, "\n")
	var result []string
	for _, line := range lines {
		if idx := strings.Index(line, "//"); idx >= 0 {
			line = line[:idx]
		}
		line = strings.TrimSpace(line)
		if line != "" {
			result = append(result, line)
		}
	}
	return strings.Join(result, "\n")
}

func parseProperties(raw string) map[string]string {
	props := make(map[string]string)
	if raw == "" {
		return props
	}
	for _, segment := range strings.Split(raw, ",") {
		segment = strings.TrimSpace(segment)
		idx := strings.Index(segment, ":")
		if idx < 0 {
			continue
		}
		key := strings.TrimSpace(segment[:idx])
		value := strings.TrimSpace(segment[idx+1:])
		value = strings.Trim(value, "'\"")
		if key != "" && value != "" {
			props[key] = value
		}
	}
	return props
}

func splitPipe(raw string) []string {
	parts := strings.Split(raw, "|")
	var result []string
	for _, p := range parts {
		p = strings.TrimSpace(p)
		// Extract just the ID (before : or {)
		if idx := strings.Index(p, ":"); idx >= 0 {
			p = strings.TrimSpace(p[:idx])
		}
		if idx := strings.Index(p, "{"); idx >= 0 {
			p = strings.TrimSpace(p[:idx])
		}
		p = strings.Trim(p, "()")
		p = strings.TrimSpace(p)
		if p != "" {
			result = append(result, p)
		}
	}
	return result
}

func upsertNode(nodes map[string]*GgNode, id, label string, props map[string]string) {
	if existing, ok := nodes[id]; ok {
		if label != "" && len(existing.Labels) == 0 {
			existing.Labels = []string{label}
		}
		for k, v := range props {
			existing.Properties[k] = v
		}
	} else {
		labels := []string{}
		if label != "" {
			labels = []string{label}
		}
		nodes[id] = &GgNode{ID: id, Labels: labels, Properties: props}
	}
}

func parseGG(source string) GgProgram {
	cleaned := stripComments(source)
	nodes := make(map[string]*GgNode)
	var edges []GgEdge

	// Sweep 1: edges
	for _, match := range edgeRegex.FindAllStringSubmatch(cleaned, -1) {
		sourceRaw := strings.TrimSpace(match[1])
		edgeType := strings.TrimSpace(match[2])
		propsRaw := ""
		if len(match) > 3 {
			propsRaw = strings.TrimSpace(match[3])
		}
		targetRaw := strings.TrimSpace(match[4])

		sourceIDs := splitPipe(sourceRaw)
		targetIDs := splitPipe(targetRaw)

		edges = append(edges, GgEdge{
			SourceIDs:  sourceIDs,
			TargetIDs:  targetIDs,
			EdgeType:   edgeType,
			Properties: parseProperties(propsRaw),
		})

		for _, id := range sourceIDs {
			if _, ok := nodes[id]; !ok {
				nodes[id] = &GgNode{ID: id, Labels: []string{}, Properties: map[string]string{}}
			}
		}
		for _, id := range targetIDs {
			if _, ok := nodes[id]; !ok {
				nodes[id] = &GgNode{ID: id, Labels: []string{}, Properties: map[string]string{}}
			}
		}
	}

	// Sweep 2: standalone nodes (lines without edges)
	for _, line := range strings.Split(cleaned, "\n") {
		if strings.Contains(line, "-[:") {
			continue
		}
		for _, match := range nodeRegex.FindAllStringSubmatch(line, -1) {
			id := strings.TrimSpace(match[1])
			if id == "" || strings.Contains(id, "|") {
				continue
			}
			label := ""
			if len(match) > 2 {
				label = strings.TrimSpace(match[2])
			}
			propsRaw := ""
			if len(match) > 3 {
				propsRaw = strings.TrimSpace(match[3])
			}
			upsertNode(nodes, id, label, parseProperties(propsRaw))
		}
	}

	return GgProgram{Nodes: nodes, Edges: edges}
}

// ═══════════════════════════════════════════════════════════════════════════════
// Topology analysis
// ═══════════════════════════════════════════════════════════════════════════════

func computeBeta1(prog GgProgram) int {
	b1 := 0
	for _, edge := range prog.Edges {
		sources := len(edge.SourceIDs)
		targets := len(edge.TargetIDs)
		switch edge.EdgeType {
		case "FORK":
			b1 += targets - 1
		case "FOLD", "COLLAPSE", "OBSERVE":
			b1 -= sources - 1
			if b1 < 0 {
				b1 = 0
			}
		case "RACE", "SLIVER":
			diff := sources - targets
			if diff < 0 {
				diff = 0
			}
			b1 -= diff
			if b1 < 0 {
				b1 = 0
			}
		case "VENT":
			b1--
			if b1 < 0 {
				b1 = 0
			}
		}
	}
	return b1
}

func computeVoidDimensions(prog GgProgram) int {
	dims := 0
	for _, edge := range prog.Edges {
		if edge.EdgeType == "FORK" {
			dims += len(edge.TargetIDs)
		}
	}
	return dims
}

func computeLandauerHeat(prog GgProgram) float64 {
	heat := 0.0
	for _, edge := range prog.Edges {
		if edge.EdgeType == "FOLD" || edge.EdgeType == "COLLAPSE" || edge.EdgeType == "OBSERVE" {
			n := len(edge.SourceIDs)
			if n > 1 {
				heat += math.Log2(float64(n))
			}
		}
	}
	return heat
}

func computeDeficit(prog GgProgram) int {
	outBranching := make(map[string]int)
	inMerging := make(map[string]int)

	for _, edge := range prog.Edges {
		for _, src := range edge.SourceIDs {
			outBranching[src] += len(edge.TargetIDs)
		}
		for _, tgt := range edge.TargetIDs {
			inMerging[tgt] += len(edge.SourceIDs)
		}
	}

	total := 0
	for id := range prog.Nodes {
		deficit := outBranching[id] - inMerging[id]
		if deficit < 0 {
			deficit = -deficit
		}
		total += deficit
	}
	return total
}

func checkDiagnostics(prog GgProgram) []Diagnostic {
	var diags []Diagnostic

	// Fork-fold balance
	forkTargets := make(map[string]int)
	foldSources := make(map[string]bool)
	for _, edge := range prog.Edges {
		if edge.EdgeType == "FORK" {
			for _, t := range edge.TargetIDs {
				forkTargets[t]++
			}
		}
		if edge.EdgeType == "FOLD" || edge.EdgeType == "COLLAPSE" || edge.EdgeType == "OBSERVE" {
			for _, s := range edge.SourceIDs {
				foldSources[s] = true
			}
		}
	}
	for node, count := range forkTargets {
		if !foldSources[node] {
			diags = append(diags, Diagnostic{
				Code:     "BECKY_GO_UNFOLDED_FORK",
				Message:  fmt.Sprintf("Node '%s' is a FORK target (%d time(s)) but never FOLD source", node, count),
				Severity: "Warning",
			})
		}
	}

	// Disconnected nodes
	referenced := make(map[string]bool)
	for _, edge := range prog.Edges {
		for _, id := range edge.SourceIDs {
			referenced[id] = true
		}
		for _, id := range edge.TargetIDs {
			referenced[id] = true
		}
	}
	for id := range prog.Nodes {
		if !referenced[id] {
			diags = append(diags, Diagnostic{
				Code:     "BECKY_GO_DISCONNECTED",
				Message:  fmt.Sprintf("Node '%s' is not connected to any edge", id),
				Severity: "Info",
			})
		}
	}

	return diags
}

func compile(source string) BeckyResult {
	prog := parseGG(source)
	return BeckyResult{
		Program:        prog,
		Beta1:          computeBeta1(prog),
		Diagnostics:    checkDiagnostics(prog),
		VoidDimensions: computeVoidDimensions(prog),
		LandauerHeat:   computeLandauerHeat(prog),
		TotalDeficit:   computeDeficit(prog),
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLI
// ═══════════════════════════════════════════════════════════════════════════════

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "usage: becky-go [--beta1|--summary|--bench N] <file.gg>")
		os.Exit(1)
	}

	beta1Only := false
	summary := false
	benchIters := 0
	filePath := ""

	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--beta1":
			beta1Only = true
		case "--summary":
			summary = true
		case "--bench":
			i++
			if i < len(args) {
				benchIters, _ = strconv.Atoi(args[i])
			}
		default:
			filePath = args[i]
		}
	}

	if filePath == "" {
		fmt.Fprintln(os.Stderr, "becky-go: no file specified")
		os.Exit(1)
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "becky-go: %v\n", err)
		os.Exit(1)
	}
	source := string(data)

	if benchIters > 0 {
		// Warmup
		for i := 0; i < 10; i++ {
			compile(source)
		}
		start := time.Now()
		for i := 0; i < benchIters; i++ {
			compile(source)
		}
		elapsed := time.Since(start)
		usPerIter := float64(elapsed.Nanoseconds()) / float64(benchIters) / 1000.0
		result := compile(source)
		fmt.Printf("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | %d diag | void=%d heat=%.3f deficit=%d\n",
			usPerIter, benchIters,
			len(result.Program.Nodes), len(result.Program.Edges),
			result.Beta1, len(result.Diagnostics),
			result.VoidDimensions, result.LandauerHeat, result.TotalDeficit)
		return
	}

	result := compile(source)

	if beta1Only {
		fmt.Println(result.Beta1)
		return
	}

	if summary {
		fmt.Printf("%s: %d nodes, %d edges, b1=%d, %d diagnostics, void=%d, heat=%.3f, deficit=%d\n",
			filePath, len(result.Program.Nodes), len(result.Program.Edges),
			result.Beta1, len(result.Diagnostics),
			result.VoidDimensions, result.LandauerHeat, result.TotalDeficit)
		return
	}

	out, _ := json.MarshalIndent(result, "", "  ")
	fmt.Println(string(out))
}
