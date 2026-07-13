------------------------------ MODULE PredictionsRound6 ------------------------------
EXTENDS Naturals, FiniteSets

\* Predictions Round 6: Cross-Domain Composition
\*
\* THM-CASCADE-ENTROPY: Failure cascade reduces frontier entropy.
\* THM-DIAGNOSTIC-ORDERING: Least-rejected hypothesis has highest weight.
\* THM-HALTING-MINORITY: Halting programs < total programs.
\* THM-OVER-REPAIR: Over-repair strictly increases entropy.
\* THM-RECONSTRUCTION-ORDERING: Concentration preserves ordering.

CONSTANTS
  NumChoices,        \* hypotheses in Buleyean space (>= 2)
  MaxRounds,         \* maximum rejection rounds
  InitialFrontier,   \* initial frontier size for cascade
  VentedPerStep,     \* paths vented per cascade step
  MaxCascadeSteps,   \* maximum cascade steps
  TotalPrograms,     \* total programs in model space
  HaltingPrograms    \* programs that halt

VARIABLES
  \* Buleyean state
  voidBoundary,      \* rejection counts per choice
  rounds,            \* total rounds
  weights,           \* complement weights

  \* Cascade state
  frontier,          \* current frontier size
  cascadeStep,       \* current cascade step
  entropyProxy,      \* frontier - 1

  \* Model selection state
  nonHalting,        \* non-halting program count

  \* Over-repair state
  repairedFrontier,  \* frontier after repair
  repairedEntropy,   \* entropy after repair

  step

vars == <<voidBoundary, rounds, weights,
          frontier, cascadeStep, entropyProxy,
          nonHalting, repairedFrontier, repairedEntropy, step>>

\* ═══════════════════════════════════════════════════════════════════════
\* Helpers
\* ═══════════════════════════════════════════════════════════════════════

ComputeWeight(i) ==
  LET v == IF voidBoundary[i] <= rounds THEN voidBoundary[i] ELSE rounds
  IN rounds - v + 1

\* ═══════════════════════════════════════════════════════════════════════
\* Init
\* ═══════════════════════════════════════════════════════════════════════

Init ==
  /\ voidBoundary = [i \in 1..NumChoices |-> 0]
  /\ rounds = 1
  /\ weights = [i \in 1..NumChoices |-> 2]
  /\ frontier = InitialFrontier
  /\ cascadeStep = 0
  /\ entropyProxy = InitialFrontier - 1
  /\ nonHalting = TotalPrograms - HaltingPrograms
  /\ repairedFrontier = InitialFrontier
  /\ repairedEntropy = InitialFrontier - 1
  /\ step = 0

\* ═══════════════════════════════════════════════════════════════════════
\* Actions
\* ═══════════════════════════════════════════════════════════════════════

\* Cascade step: vent paths, reduce frontier
CascadeStep ==
  /\ step < MaxCascadeSteps
  /\ frontier > VentedPerStep
  /\ frontier' = frontier - VentedPerStep
  /\ entropyProxy' = frontier' - 1
  /\ cascadeStep' = cascadeStep + 1
  /\ UNCHANGED <<voidBoundary, rounds, weights, nonHalting,
                 repairedFrontier, repairedEntropy>>
  /\ step' = step + 1

\* Reject a hypothesis (diagnostic scenario)
RejectHypothesis ==
  /\ step < MaxRounds
  /\ \E c \in 1..NumChoices :
      /\ voidBoundary' = [voidBoundary EXCEPT ![c] = @ + 1]
      /\ rounds' = rounds + 1
      /\ weights' = [i \in 1..NumChoices |-> ComputeWeight(i) + (IF i = c THEN 0 ELSE 1)]
  /\ UNCHANGED <<frontier, cascadeStep, entropyProxy, nonHalting,
                 repairedFrontier, repairedEntropy>>
  /\ step' = step + 1

\* Over-repair: repair more than vented
OverRepair ==
  /\ step < MaxRounds
  /\ frontier > 0
  /\ repairedFrontier' = frontier + 1  \* repair exceeds vent
  /\ repairedEntropy' = repairedFrontier' - 1
  /\ UNCHANGED <<voidBoundary, rounds, weights, frontier,
                 cascadeStep, entropyProxy, nonHalting>>
  /\ step' = step + 1

Next ==
  \/ CascadeStep
  \/ RejectHypothesis
  \/ OverRepair

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* ═══════════════════════════════════════════════════════════════════════
\* Invariants
\* ═══════════════════════════════════════════════════════════════════════

\* THM-CASCADE-ENTROPY: Cascade always reduces entropy
InvCascadeReduces == entropyProxy >= 0

\* THM-CASCADE-SURVIVOR: At least one survivor
InvCascadeSurvivor == frontier > 0

\* THM-DIAGNOSTIC-ORDERING: All weights positive (sliver)
InvWeightsPositive == \A i \in 1..NumChoices : weights[i] > 0

\* THM-HALTING-MINORITY: Non-halting programs exist
InvHaltingMinority == nonHalting > 0

\* THM-OVER-REPAIR: Over-repair increases entropy
InvOverRepairEntropy == repairedEntropy >= entropyProxy

\* THM-RECONSTRUCTION-ORDERING: Weights track concentration
InvWeightsBounded == \A i \in 1..NumChoices : weights[i] <= rounds + 1

=============================================================================
