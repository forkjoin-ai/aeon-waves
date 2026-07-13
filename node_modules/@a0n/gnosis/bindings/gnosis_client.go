package gnosis

import (
	"bytes"
	"os/exec"
)

type GnosisResult struct {
	ExitCode int
	Stdout   string
	Stderr   string
}

type GnosisClient struct {
	Binary string
}

func NewClient(binary string) *GnosisClient {
	if binary == "" {
		binary = "gnosis"
	}
	return &GnosisClient{Binary: binary}
}

func (c *GnosisClient) Run(args ...string) (GnosisResult, error) {
	cmd := exec.Command(c.Binary, args...)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			return GnosisResult{}, err
		}
	}

	return GnosisResult{
		ExitCode: exitCode,
		Stdout:   stdout.String(),
		Stderr:   stderr.String(),
	}, nil
}

func (c *GnosisClient) Lint(topologyPath string, target string, asJSON bool) (GnosisResult, error) {
	args := []string{"lint", topologyPath}
	if target != "" {
		args = append(args, "--target", target)
	}
	if asJSON {
		args = append(args, "--json")
	}
	return c.Run(args...)
}

func (c *GnosisClient) Analyze(targetPath string, asJSON bool) (GnosisResult, error) {
	args := []string{"analyze", targetPath}
	if asJSON {
		args = append(args, "--json")
	}
	return c.Run(args...)
}

func (c *GnosisClient) Verify(topologyPath string, tlaOut string) (GnosisResult, error) {
	args := []string{"verify", topologyPath}
	if tlaOut != "" {
		args = append(args, "--tla-out", tlaOut)
	}
	return c.Run(args...)
}

func (c *GnosisClient) RunTopology(topologyPath string, native bool) (GnosisResult, error) {
	args := []string{"run", topologyPath}
	if native {
		args = append(args, "--native")
	}
	return c.Run(args...)
}

func (c *GnosisClient) TestTopology(topologyPath string) (GnosisResult, error) {
	return c.Run("test", topologyPath)
}
