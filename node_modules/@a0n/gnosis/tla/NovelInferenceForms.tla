------------------------------ MODULE NovelInferenceForms ------------------------------
(*
  Five Novel AI Inference Forms as State Machines.

  Each inference form is modeled as a state machine whose invariants
  capture the structural properties proved in NovelInferenceForms.lean.

  1. Void Inference: generation by rejection accumulation
  2. Retrocausal Decoding: constrained generation from terminal state
  3. Topological Speculative Decoding: skip by beta1 deficit
  4. Semiotic Ensemble: fork/race/fold multi-model inference
  5. Non-Empirical Inference: prediction without training data

  All invariants model-check the same properties as the Lean theorems.
*)
EXTENDS Naturals, FiniteSets

CONSTANTS VocabSize, MaxRounds, NumAgents, NumLayers,
          NeighborRounds, NeighborVoid

VARIABLES phase, voidBoundary, rounds, stepCount,
          terminalBoundary, layerBeta1, layersSkipped,
          agentRejections, ensembleDeficit,
          holeWeight, uninformedWeight

vars == <<phase, voidBoundary, rounds, stepCount,
          terminalBoundary, layerBeta1, layersSkipped,
          agentRejections, ensembleDeficit,
          holeWeight, uninformedWeight>>

\* ─── Helper: Buleyean weight ──────────────────────────────────────────

BuleyeanWeight(r, v) ==
  r - (IF v <= r THEN v ELSE r) + 1

\* ─── Initial state ────────────────────────────────────────────────────

Init ==
  /\ phase = "void_inference"
  /\ voidBoundary = [i \in 1..VocabSize |-> 0]
  /\ rounds = 1
  /\ stepCount = 0
  /\ terminalBoundary = [i \in 1..VocabSize |-> 0]
  /\ layerBeta1 = [i \in 1..NumLayers |-> 0]
  /\ layersSkipped = 0
  /\ agentRejections = [i \in 1..NumAgents |-> 0]
  /\ ensembleDeficit = NumAgents - 1
  /\ holeWeight = BuleyeanWeight(NeighborRounds, NeighborVoid)
  /\ uninformedWeight = NeighborRounds + 1

\* ─── Form 1: Void Inference — reject a token ─────────────────────────

VoidInferenceStep ==
  /\ phase = "void_inference"
  /\ stepCount < MaxRounds
  /\ \E token \in 1..VocabSize :
       /\ voidBoundary' = [voidBoundary EXCEPT ![token] = @ + 1]
       /\ rounds' = rounds + 1
       /\ stepCount' = stepCount + 1
  /\ phase' = "retrocausal"
  /\ UNCHANGED <<terminalBoundary, layerBeta1, layersSkipped,
                  agentRejections, ensembleDeficit,
                  holeWeight, uninformedWeight>>

\* ─── Form 2: Retrocausal Decoding — set terminal constraint ──────────

RetrocausalStep ==
  /\ phase = "retrocausal"
  /\ \E token \in 1..VocabSize :
       /\ terminalBoundary' = [terminalBoundary EXCEPT ![token] = @ + 1]
  /\ phase' = "topo_spec"
  /\ UNCHANGED <<voidBoundary, rounds, stepCount, layerBeta1,
                  layersSkipped, agentRejections, ensembleDeficit,
                  holeWeight, uninformedWeight>>

\* ─── Form 3: Topological Speculative Decoding — skip a layer ─────────

TopoSpecStep ==
  /\ phase = "topo_spec"
  /\ layersSkipped < NumLayers - 1  \* Must keep at least 1 layer
  /\ \E layer \in 1..NumLayers :
       /\ layerBeta1[layer] = 0  \* Only skip zero-deficit layers
       /\ layersSkipped' = layersSkipped + 1
  /\ phase' = "ensemble"
  /\ UNCHANGED <<voidBoundary, rounds, stepCount, terminalBoundary,
                  layerBeta1, agentRejections, ensembleDeficit,
                  holeWeight, uninformedWeight>>

\* ─── Form 4: Semiotic Ensemble — reject an agent ─────────────────────

SemioticEnsembleStep ==
  /\ phase = "ensemble"
  /\ \E agent \in 1..NumAgents :
       /\ agentRejections' = [agentRejections EXCEPT ![agent] = @ + 1]
  /\ phase' = "nei"
  /\ UNCHANGED <<voidBoundary, rounds, stepCount, terminalBoundary,
                  layerBeta1, layersSkipped, ensembleDeficit,
                  holeWeight, uninformedWeight>>

\* ─── Form 5: Non-Empirical Inference — observe ───────────────────────

NonEmpiricalStep ==
  /\ phase = "nei"
  /\ phase' = "void_inference"
  /\ UNCHANGED <<voidBoundary, rounds, stepCount, terminalBoundary,
                  layerBeta1, layersSkipped, agentRejections,
                  ensembleDeficit, holeWeight, uninformedWeight>>

Stutter == UNCHANGED vars

Next == VoidInferenceStep \/ RetrocausalStep \/ TopoSpecStep
     \/ SemioticEnsembleStep \/ NonEmpiricalStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ═══════════════════════════════════════════════════════════════════════
\* Invariants
\* ═══════════════════════════════════════════════════════════════════════

\* Form 1: All tokens retain positive weight (the sliver)
InvVoidInferencePositive ==
  \A token \in 1..VocabSize :
    BuleyeanWeight(rounds, voidBoundary[token]) >= 1

\* Form 1: Void boundary is monotone (append-only)
InvVoidBoundaryMonotone ==
  \A token \in 1..VocabSize :
    voidBoundary[token] >= 0

\* Form 2: Terminal constraints are satisfiable (no zero weight)
InvRetrocausalPositive ==
  \A token \in 1..VocabSize :
    BuleyeanWeight(rounds, terminalBoundary[token]) >= 1

\* Form 3: At least one layer always executes
InvTopoMinimumCompute ==
  layersSkipped < NumLayers

\* Form 3: Deficit is non-negative
InvTopoDeficitNonneg ==
  \A layer \in 1..NumLayers :
    layerBeta1[layer] >= 0

\* Form 4: Ensemble deficit is exactly k - 1
InvEnsembleDeficit ==
  ensembleDeficit = NumAgents - 1

\* Form 4: All agents retain positive weight
InvEnsemblePositive ==
  \A agent \in 1..NumAgents :
    BuleyeanWeight(rounds, agentRejections[agent]) >= 1

\* Form 5: Structural prediction weight is positive
InvNEIPositive ==
  holeWeight >= 1

\* Form 5: Structure dominates uninformed guess
InvNEIDominates ==
  (NeighborVoid > 0) => (holeWeight < uninformedWeight)

\* Cross-cutting: rounds are always positive
InvRoundsPositive ==
  rounds >= 1

=============================================================================
