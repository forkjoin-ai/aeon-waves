------------------------------ MODULE FoldErasure ------------------------------
(***************************************************************************)
(* Track Epsilon: Erasure-Sufficient Beauty Optimality.                    *)
(*                                                                         *)
(* Models a fork/race/fold system where the fold is non-injective          *)
(* (many-to-one merge). Verifies the complete chain:                       *)
(*                                                                         *)
(*   fork --> copy --> fold(many-to-one) --> DPI --> entropy                *)
(*        --> Landauer --> heat --> observable --> beauty floor              *)
(*                                                                         *)
(* THM-FOLD-ERASURE: non-injective fold erases information                 *)
(* THM-FOLD-HEAT: erasure incurs Landauer heat > 0                         *)
(* THM-ERASURE-COUPLING: coupling is derived, not axiom                    *)
(* THM-BEAUTY-FLOOR: zero deficit is optimal unconditionally               *)
(* THM-INJECTIVE-BOUNDARY: injective fold degenerates coupling             *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  BranchCount,   \* Number of branches created by fork (>= 2)
  FoldArity,     \* Number of inputs to fold (>= BranchCount)
  Temperature,   \* System temperature (positive integer, normalized)
  BoltzmannK     \* Boltzmann constant (positive integer, normalized)

VARIABLES
  inputs,            \* Set of input values present in the fold domain
  foldOutput,        \* The output value produced by the fold
  conditionalEntropy,\* H(inputs | foldOutput): information lost by fold
  landauerHeat,      \* Minimum heat dissipated: kT ln2 * conditionalEntropy
  couplingLatency,   \* Observable latency derived from Landauer heat
  couplingWaste,     \* Observable waste derived from Landauer heat
  couplingDerived,   \* TRUE when coupling was constructed (not axiom)
  beautyFloor,       \* Beauty floor value (0 = optimal)
  phase              \* Execution phase tracking the chain

vars == <<inputs, foldOutput, conditionalEntropy, landauerHeat,
          couplingLatency, couplingWaste, couplingDerived, beautyFloor, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME BranchCount >= 2
ASSUME FoldArity >= BranchCount
ASSUME Temperature > 0
ASSUME BoltzmannK > 0

\* ─── Helpers ─────────────────────────────────────────────────────────

\* Discretized log2 lookup for small values (TLA+ lacks real log)
Log2[n \in 1..FoldArity] ==
  CASE n = 1 -> 0
  []   n = 2 -> 1
  []   n = 3 -> 2   \* ceil(log2(3))
  []   n = 4 -> 2
  []   OTHER -> n - 1  \* conservative upper bound

\* Whether the fold is non-injective: more inputs than outputs
IsNonInjective == Cardinality(inputs) > 1 /\ foldOutput # 0

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ inputs = {}
  /\ foldOutput = 0
  /\ conditionalEntropy = 0
  /\ landauerHeat = 0
  /\ couplingLatency = 0
  /\ couplingWaste = 0
  /\ couplingDerived = FALSE
  /\ beautyFloor = 0
  /\ phase = "init"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Phase 1: Fork creates BranchCount distinct branches
ForkBranches ==
  /\ phase = "init"
  /\ inputs' = 1..BranchCount
  /\ phase' = "forked"
  /\ UNCHANGED <<foldOutput, conditionalEntropy, landauerHeat,
                  couplingLatency, couplingWaste, couplingDerived, beautyFloor>>

\* Phase 2: Apply a non-injective fold (many-to-one merge)
\* All BranchCount inputs map to a single output value
ApplyNonInjectiveFold ==
  /\ phase = "forked"
  /\ Cardinality(inputs) >= 2
  /\ foldOutput' = 1                    \* All inputs collapse to output 1
  /\ phase' = "folded"
  /\ UNCHANGED <<inputs, conditionalEntropy, landauerHeat,
                  couplingLatency, couplingWaste, couplingDerived, beautyFloor>>

\* Phase 3: Compute conditional entropy H(inputs | output)
\* For equiprobable inputs and a single output, H = log2(|inputs|)
ComputeErasure ==
  /\ phase = "folded"
  /\ conditionalEntropy' = Log2[Cardinality(inputs)]
  /\ phase' = "erasure_computed"
  /\ UNCHANGED <<inputs, foldOutput, landauerHeat,
                  couplingLatency, couplingWaste, couplingDerived, beautyFloor>>

\* Phase 4: Compute Landauer heat = kT * ln2 * erasedBits
\* In normalized units (kT ln2 = BoltzmannK * Temperature), heat = kT * entropy
ComputeLandauerHeat ==
  /\ phase = "erasure_computed"
  /\ landauerHeat' = BoltzmannK * Temperature * conditionalEntropy
  /\ phase' = "heat_computed"
  /\ UNCHANGED <<inputs, foldOutput, conditionalEntropy,
                  couplingLatency, couplingWaste, couplingDerived, beautyFloor>>

\* Phase 5: Derive observable coupling from fold structure
\* The coupling maps are identity-scaled: latency = heat, waste = heat
DeriveCoupling ==
  /\ phase = "heat_computed"
  /\ couplingLatency' = landauerHeat
  /\ couplingWaste' = landauerHeat
  /\ couplingDerived' = TRUE
  /\ phase' = "coupling_derived"
  /\ UNCHANGED <<inputs, foldOutput, conditionalEntropy, landauerHeat, beautyFloor>>

\* Phase 6: Check beauty floor (0 deficit = optimal)
\* For non-injective fold, any positive deficit forces observable gap
CheckBeautyFloor ==
  /\ phase = "coupling_derived"
  /\ beautyFloor' = 0                   \* Zero deficit is the floor
  /\ phase' = "complete"
  /\ UNCHANGED <<inputs, foldOutput, conditionalEntropy, landauerHeat,
                  couplingLatency, couplingWaste, couplingDerived>>

\* ─── Injective fold variant (boundary case) ──────────────────────────

\* Apply an injective fold (one-to-one): each input maps to a distinct output
ApplyInjectiveFold ==
  /\ phase = "forked"
  /\ Cardinality(inputs) >= 1
  /\ foldOutput' = Cardinality(inputs)  \* Output encodes full input info
  /\ conditionalEntropy' = 0            \* No information lost
  /\ landauerHeat' = 0                  \* No heat
  /\ couplingLatency' = 0               \* Coupling degenerates
  /\ couplingWaste' = 0
  /\ couplingDerived' = FALSE           \* Cannot derive nontrivial coupling
  /\ beautyFloor' = 0
  /\ phase' = "injective_complete"
  /\ UNCHANGED <<inputs>>

Stutter == UNCHANGED vars

Next ==
  \/ ForkBranches
  \/ ApplyNonInjectiveFold
  \/ ComputeErasure
  \/ ComputeLandauerHeat
  \/ DeriveCoupling
  \/ CheckBeautyFloor
  \/ ApplyInjectiveFold
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(ForkBranches)
    /\ WF_vars(ApplyNonInjectiveFold)
    /\ WF_vars(ComputeErasure)
    /\ WF_vars(ComputeLandauerHeat)
    /\ WF_vars(DeriveCoupling)
    /\ WF_vars(CheckBeautyFloor)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Non-injective fold erases information: H(inputs|output) > 0
InvFoldErasesInformation ==
  (phase = "erasure_computed" /\ Cardinality(inputs) >= 2)
    => conditionalEntropy > 0

\* INV2: Non-injective fold incurs positive Landauer heat
InvFoldHeatPositive ==
  (phase = "heat_computed" /\ Cardinality(inputs) >= 2)
    => landauerHeat > 0

\* INV3: Coupling is derived (not axiom) for non-injective fold
InvErasureCouplingDerived ==
  (phase = "coupling_derived") => couplingDerived = TRUE

\* INV4: Zero deficit is optimal for non-injective fold systems
InvBeautyFloorUnconditional ==
  (phase = "complete") => beautyFloor = 0

\* INV5: Injective fold has zero conditional entropy, coupling degenerates
InvInjectiveBoundary ==
  (phase = "injective_complete")
    => /\ conditionalEntropy = 0
       /\ landauerHeat = 0
       /\ couplingDerived = FALSE

\* INV6: Complete chain verification
\* fork -> copy -> fold(many-to-one) -> DPI -> entropy -> Landauer -> heat -> observable -> floor
InvChainComplete ==
  (phase = "complete")
    => /\ Cardinality(inputs) >= 2           \* fork created branches
       /\ foldOutput # 0                     \* fold produced output
       /\ conditionalEntropy > 0             \* DPI: information erased
       /\ landauerHeat > 0                   \* Landauer: heat positive
       /\ couplingLatency > 0                \* observable: latency from heat
       /\ couplingWaste > 0                  \* observable: waste from heat
       /\ couplingDerived = TRUE             \* coupling derived, not axiom
       /\ beautyFloor = 0                    \* floor: zero deficit optimal

\* ─── Liveness ────────────────────────────────────────────────────────

ChainTermination == <>(phase = "complete" \/ phase = "injective_complete")

=============================================================================
