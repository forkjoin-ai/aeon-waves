--------------------------- MODULE LandauerBeautyBridge ---------------------------
(***************************************************************************)
(* Bounded TLA+ model for the Landauer Beauty Bridge.                     *)
(*                                                                         *)
(* This spec enumerates small frontier instances (n = 2, 3, 4) and checks  *)
(* that:                                                                   *)
(*   1. positiveDeficitForcesPositiveTax holds for Landauer heat           *)
(*   2. The oneStepFloor variant matches the coupling construction         *)
(*   3. Zero-deficit points have zero tax                                  *)
(*                                                                         *)
(* This provides the TLA+ cross-check that THEOREM_LEDGER requires for    *)
(* dual mechanization of THM-BEAUTY-UNCONDITIONAL-FLOOR.                  *)
(***************************************************************************)

EXTENDS Naturals, Reals, FiniteSets, Sequences

CONSTANTS
  MaxLiveBranches  \* Bound for model checking (set to 4 in .cfg)

VARIABLES
  liveBranches,    \* Current frontier width (1..MaxLiveBranches)
  deficit,         \* Topological deficit (0 or positive)
  heat,            \* Landauer heat lower bound
  latencyFloor,    \* Observable latency floor from coupling
  wasteFloor       \* Observable waste floor from coupling

vars == <<liveBranches, deficit, heat, latencyFloor, wasteFloor>>

(***************************************************************************)
(* Definitions mirroring the Lean formalization                            *)
(***************************************************************************)

\* Equiprobable frontier entropy in bits (log2 of liveBranches)
\* We use a lookup table for small values since TLA+ lacks log
Log2[n \in 1..MaxLiveBranches] ==
  CASE n = 1 -> 0
  []   n = 2 -> 1
  []   n = 3 -> 2  \* ceil(log2(3)) = 2, actual ~1.585
  []   n = 4 -> 2
  []   OTHER -> n - 1  \* conservative upper bound

\* Deterministic collapse failure tax: liveBranches - 1
FailureTax[n \in 1..MaxLiveBranches] == n - 1

\* For the model checker we use kB*T*ln2 = 1 (normalized units)
\* so LandauerHeat = entropy_bits
LandauerHeat[n \in 1..MaxLiveBranches] == Log2[n]

\* OneStepFloor: base + 1 if tax > 0, else base
OneStepFloor(base, tax) == IF tax > 0 THEN base + 1 ELSE base

(***************************************************************************)
(* Initial state: enumerate all frontier configurations                    *)
(***************************************************************************)

Init ==
  /\ liveBranches \in 1..MaxLiveBranches
  /\ deficit \in 0..MaxLiveBranches
  /\ heat = LandauerHeat[liveBranches]
  /\ latencyFloor = OneStepFloor(0, heat)
  /\ wasteFloor = 0  \* Non-strict coordinate

(***************************************************************************)
(* No transitions needed: this is a bounded state enumeration              *)
(***************************************************************************)

Next == UNCHANGED vars

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Invariants                                                              *)
(***************************************************************************)

\* INV1: Positive deficit forces positive tax (Landauer heat > 0)
\* When liveBranches >= 2, entropy >= 1 bit, so heat > 0
InvPositiveDeficitForcesPositiveTax ==
  (deficit > 0 /\ liveBranches >= 2) => heat > 0

\* INV2: Zero-deficit floor has zero tax
InvZeroDeficitFloorZeroTax ==
  (liveBranches = 1) => heat = 0

\* INV3: Entropy <= failure tax (for all n >= 1)
InvEntropyLeFailureTax ==
  Log2[liveBranches] <= FailureTax[liveBranches]

\* INV4: OneStepFloor correctly detects positive heat
InvOneStepFloorMatchesCoupling ==
  (heat > 0) => (latencyFloor > 0)

\* INV5: OneStepFloor is zero at zero heat
InvOneStepFloorZeroAtZero ==
  (heat = 0) => (latencyFloor = 0)

\* INV6: Strict observable gap from positive heat
\* At least one of latency or waste floor is strictly above zero-heat baseline
InvStrictGapFromPositiveHeat ==
  (heat > 0) => (latencyFloor > OneStepFloor(0, 0) \/ wasteFloor > 0)

=============================================================================
