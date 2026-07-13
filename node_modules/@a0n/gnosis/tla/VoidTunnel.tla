------------------------------ MODULE VoidTunnel ------------------------------
(***************************************************************************)
(* THM-VOID-TUNNEL: Void regions sharing a common ancestor fork have      *)
(* positive mutual information. Correlation decays exponentially but       *)
(* never reaches zero for finite fold sequences.                           *)
(*                                                                         *)
(* I(dV_A; dV_B) > 0 when both branches share a common ancestor fork      *)
(* with H(F) > 0. This is *why counterfactual reasoning works*:           *)
(* different decision branches retain information about each other         *)
(* through shared ancestry.                                                *)
(*                                                                         *)
(* Void analogue of quantum entanglement: two void regions from a shared  *)
(* origin retain correlations across subsequent folds.                     *)
(***************************************************************************)

EXTENDS Naturals, Sequences

CONSTANTS
  AncestorEntropy,   \* H(F) > 0 from the common ancestor fork
  MaxDepthA,         \* Maximum fold depth for branch A
  MaxDepthB,         \* Maximum fold depth for branch B
  RetentionFactor    \* Per-fold retention (encoded as percentage 1-99)

VARIABLES
  depthA,            \* Current fold depth on branch A
  depthB,            \* Current fold depth on branch B
  retainedInfoA,     \* Information retained in branch A's void
  retainedInfoB,     \* Information retained in branch B's void
  mutualInfo,        \* I(dV_A; dV_B) -- mutual information between void regions
  phase

vars == <<depthA, depthB, retainedInfoA, retainedInfoB, mutualInfo, phase>>

ASSUME AncestorEntropy > 0
ASSUME MaxDepthA >= 1
ASSUME MaxDepthB >= 1
ASSUME RetentionFactor > 0
ASSUME RetentionFactor < 100

Init ==
  /\ depthA = 0
  /\ depthB = 0
  /\ retainedInfoA = AncestorEntropy * 100  \* Scaled by 100 for integer arithmetic
  /\ retainedInfoB = AncestorEntropy * 100
  /\ mutualInfo = AncestorEntropy * 100
  /\ phase = "forked"

\* Branch A undergoes a fold: some information is erased
FoldBranchA ==
  /\ phase = "forked"
  /\ depthA < MaxDepthA
  /\ retainedInfoA' = (retainedInfoA * RetentionFactor) \div 100
  /\ depthA' = depthA + 1
  \* Mutual info is bounded by min of retained info on both sides
  /\ mutualInfo' = IF (retainedInfoA * RetentionFactor) \div 100 < retainedInfoB
                   THEN (retainedInfoA * RetentionFactor) \div 100
                   ELSE retainedInfoB
  /\ UNCHANGED <<depthB, retainedInfoB, phase>>

\* Branch B undergoes a fold: some information is erased
FoldBranchB ==
  /\ phase = "forked"
  /\ depthB < MaxDepthB
  /\ retainedInfoB' = (retainedInfoB * RetentionFactor) \div 100
  /\ depthB' = depthB + 1
  /\ mutualInfo' = IF retainedInfoA < (retainedInfoB * RetentionFactor) \div 100
                   THEN retainedInfoA
                   ELSE (retainedInfoB * RetentionFactor) \div 100
  /\ UNCHANGED <<depthA, retainedInfoA, phase>>

\* Both branches have reached their maximum depth
Complete ==
  /\ depthA = MaxDepthA
  /\ depthB = MaxDepthB
  /\ phase' = "complete"
  /\ UNCHANGED <<depthA, depthB, retainedInfoA, retainedInfoB, mutualInfo>>

Stutter == UNCHANGED vars

Next ==
  \/ FoldBranchA
  \/ FoldBranchB
  \/ Complete
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(FoldBranchA)
    /\ WF_vars(FoldBranchB)
    /\ WF_vars(Complete)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Retained information on branch A is always positive
\* (retention factor > 0, so scaled info stays > 0 for finite depths)
InvRetainedInfoAPositive ==
  retainedInfoA > 0

\* INV2: Retained information on branch B is always positive
InvRetainedInfoBPositive ==
  retainedInfoB > 0

\* INV3: Mutual information is positive -- THE KEY THEOREM
\* Correlation between void regions never reaches zero
InvMutualInfoPositive ==
  mutualInfo > 0

\* INV4: Mutual info bounded by both branches
InvMutualInfoBounded ==
  /\ mutualInfo <= retainedInfoA
  /\ mutualInfo <= retainedInfoB

\* INV5: Retained info decreases monotonically (DPI)
InvRetainedInfoDecreases ==
  /\ retainedInfoA <= AncestorEntropy * 100
  /\ retainedInfoB <= AncestorEntropy * 100

\* INV6: At completion, mutual info is still positive
InvCompleteMutualInfoPositive ==
  (phase = "complete") => mutualInfo > 0

\* ─── Liveness ────────────────────────────────────────────────────────

TunnelComplete == <>(phase = "complete")

=============================================================================
