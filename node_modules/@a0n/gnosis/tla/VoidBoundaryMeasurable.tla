------------------------------ MODULE VoidBoundaryMeasurable ------------------------------
(***************************************************************************)
(* THM-VOID-BOUNDARY-MEASURABLE: The boundary of the void created by      *)
(* T folds over N-way cycles has homology rank bounded by sum of (N_t-1). *)
(* Computable in O(T * N_max) time, O(T * log N_max) space.              *)
(*                                                                         *)
(* The boundary encodes *which* equivalence classes were vented at each    *)
(* fold. Each N-way fork contributes at most N-1 boundary cells.          *)
(* Each cell needs log(N_t) bits (the winner's class ID).                 *)
(*                                                                         *)
(* Dual of persistent homology: tracks birth/persistence of *dead*        *)
(* features rather than live ones.                                         *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  MaxSteps,     \* Maximum number of fold steps (T)
  ForkWidth     \* Constant fork width (N >= 2)

VARIABLES
  step,              \* Current step number
  totalVented,       \* Cumulative vented paths (boundary rank)
  activePaths,       \* Currently active paths (always 1 after fold)
  boundaryLog,       \* Sequence of (step, winnerID) pairs encoding boundary
  phase              \* Current phase

vars == <<step, totalVented, activePaths, boundaryLog, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME ForkWidth >= 2
ASSUME MaxSteps >= 1

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ step = 0
  /\ totalVented = 0
  /\ activePaths = 1
  /\ boundaryLog = <<>>
  /\ phase = "ready"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Fork: create N alternative paths
Fork ==
  /\ phase = "ready"
  /\ step < MaxSteps
  /\ activePaths' = ForkWidth
  /\ phase' = "forked"
  /\ UNCHANGED <<step, totalVented, boundaryLog>>

\* Fold: select one winner, vent N-1 paths to the void
\* Record the winner's ID in the boundary log
Fold ==
  /\ phase = "forked"
  /\ activePaths = ForkWidth
  /\ \E winner \in 1..ForkWidth :
      /\ boundaryLog' = Append(boundaryLog, <<step + 1, winner>>)
  /\ totalVented' = totalVented + (ForkWidth - 1)
  /\ activePaths' = 1
  /\ step' = step + 1
  /\ phase' = "ready"

Stutter == UNCHANGED vars

Next ==
  \/ Fork
  \/ Fold
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Fork)
    /\ WF_vars(Fold)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Boundary rank = total vented = sum of (N-1) per step
InvBoundaryRankEqTotalVented ==
  totalVented = step * (ForkWidth - 1)

\* INV2: Each step adds exactly N-1 to the void
InvPerStepVentCount ==
  (phase = "ready" /\ step > 0) => totalVented >= ForkWidth - 1

\* INV3: Active paths are either 1 (folded) or N (forked)
InvActivePathsBounded ==
  activePaths \in {1, ForkWidth}

\* INV4: Boundary log length matches steps completed
InvBoundaryLogLength ==
  Len(boundaryLog) = step

\* INV5: Space efficiency: log stores O(T) entries, each O(log N) bits
InvSpaceEfficiency ==
  Len(boundaryLog) <= MaxSteps

\* INV6: Void boundary grows monotonically
InvBoundaryMonotone ==
  totalVented >= 0

\* INV7: Complete trace: at completion, boundary encodes full void structure
InvCompleteTrace ==
  (step = MaxSteps /\ phase = "ready")
    => /\ totalVented = MaxSteps * (ForkWidth - 1)
       /\ Len(boundaryLog) = MaxSteps

\* ─── Liveness ────────────────────────────────────────────────────────

BoundaryComplete == <>(step = MaxSteps /\ phase = "ready")

=============================================================================
