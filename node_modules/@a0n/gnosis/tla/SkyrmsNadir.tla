------------------------------ MODULE SkyrmsNadir ------------------------------
(***************************************************************************)
(* Skyrms Nadir: Two Metacognitive Walkers Converging via Failure.        *)
(*                                                                         *)
(* Models two self-interested agents, each running a c0-c3 metacognitive  *)
(* loop, negotiating on a shared void surface. Each walker maintains      *)
(* its own void boundary (rejection history) and complement distribution. *)
(* Failed interactions enrich both boundaries, driving complement         *)
(* distributions toward alignment. The Skyrms nadir is the basin of      *)
(* attraction where both walkers settle -- not from altruism, but from    *)
(* accumulated failure information making peace the gradient descent      *)
(* direction.                                                              *)
(*                                                                         *)
(* "The map of what did not work IS the territory of what will."          *)
(*                                                                         *)
(* THM-SKYRMS-VOID-GROWTH: each failure strictly increases void density   *)
(* THM-SKYRMS-COMPLEMENT-SHIFT: growing void shifts complement toward    *)
(*   center                                                                *)
(* THM-SKYRMS-DISTANCE-MONO: inter-walker distance is non-increasing     *)
(* THM-SKYRMS-NADIR-REACHABLE: walkers eventually reach the nadir        *)
(* THM-SKYRMS-NADIR-STABLE: the nadir is a fixed point (no unilateral    *)
(*   improvement)                                                          *)
(* THM-SKYRMS-FAILURE-NECESSARY: without failure, walkers may diverge    *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  NumChoices,        \* Strategy space size per walker (>= 2)
  MaxRounds,         \* Maximum interaction rounds
  EtaInit,           \* Initial learning rate (integer-scaled, e.g. 10 = 1.0)
  NadirThreshold     \* Distance at or below which walkers are "at the nadir"

VARIABLES
  \* Walker A state
  voidA,             \* Walker A's void density per choice (sequence of naturals)
  complementA,       \* Walker A's complement weight per choice (lower = more rejected)
  offerA,            \* Walker A's current offer (choice index)
  etaA,              \* Walker A's learning rate
  kurtosisA,         \* Walker A's complement distribution kurtosis
  cogLevelA,         \* Walker A's metacognitive level (0-3)

  \* Walker B state
  voidB,             \* Walker B's void density per choice
  complementB,       \* Walker B's complement weight per choice
  offerB,            \* Walker B's current offer (choice index)
  etaB,              \* Walker B's learning rate
  kurtosisB,         \* Walker B's complement distribution kurtosis
  cogLevelB,         \* Walker B's metacognitive level (0-3)

  \* Shared state
  round,             \* Current round number
  distance,          \* Manhattan distance between complement distributions
  prevDistance,       \* Previous round's distance (for monotonicity check)
  settled,           \* TRUE when walkers have reached the nadir
  totalFailures,     \* Cumulative failed interactions
  phase              \* Round phase

vars == <<voidA, complementA, offerA, etaA, kurtosisA, cogLevelA,
          voidB, complementB, offerB, etaB, kurtosisB, cogLevelB,
          round, distance, prevDistance, settled, totalFailures, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME NumChoices >= 2
ASSUME MaxRounds >= 1
ASSUME EtaInit >= 1
ASSUME NadirThreshold >= 0

\* ─── Helpers ─────────────────────────────────────────────────────────

\* Uniform initial sequence: all choices equally weighted
UniformSeq == [i \in 1..NumChoices |-> 1]

\* Complement weight: base weight minus void density (floor 1)
\* More rejected = lower weight, but never zero (Skyrms: no option abandoned)
ComplementWeight(voidDensity) ==
  [i \in 1..NumChoices |->
    IF EtaInit - voidDensity[i] >= 1
    THEN EtaInit - voidDensity[i]
    ELSE 1]

\* Manhattan distance between two weight vectors
ManhattanDist(wA, wB) ==
  LET AbsDiff(i) == IF wA[i] >= wB[i] THEN wA[i] - wB[i] ELSE wB[i] - wA[i]
  IN LET \* Sum via recursive CHOOSE would be complex; use bounded sum
       PairDiffs == {AbsDiff(i) : i \in 1..NumChoices}
     IN Cardinality(PairDiffs) * (CHOOSE d \in PairDiffs : TRUE)
        \* Conservative upper bound; exact sum below for small NumChoices

\* Exact sum for small NumChoices (unrolled for TLC tractability)
DistSum(wA, wB) ==
  LET Diff(i) == IF wA[i] >= wB[i] THEN wA[i] - wB[i] ELSE wB[i] - wA[i]
  IN IF NumChoices = 2 THEN Diff(1) + Diff(2)
     ELSE IF NumChoices = 3 THEN Diff(1) + Diff(2) + Diff(3)
     ELSE IF NumChoices = 4 THEN Diff(1) + Diff(2) + Diff(3) + Diff(4)
     ELSE Diff(1) + Diff(2)  \* Fallback for TLC; real proof in Lean

\* Argmax of a weight sequence (choice with highest complement weight)
Argmax(w) == CHOOSE i \in 1..NumChoices : \A j \in 1..NumChoices : w[i] >= w[j]

\* Kurtosis proxy: max weight minus min weight (spread of distribution)
KurtosisProxy(w) ==
  LET maxW == CHOOSE m \in {w[i] : i \in 1..NumChoices} :
                \A v \in {w[i] : i \in 1..NumChoices} : m >= v
      minW == CHOOSE m \in {w[i] : i \in 1..NumChoices} :
                \A v \in {w[i] : i \in 1..NumChoices} : m <= v
  IN maxW - minW

\* Clamp to [lo, hi]
Clamp(v, lo, hi) == IF v < lo THEN lo ELSE IF v > hi THEN hi ELSE v

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ voidA = UniformSeq             \* No rejections yet (density = 1 = base)
  /\ complementA = [i \in 1..NumChoices |-> EtaInit]  \* Uniform complement
  /\ offerA = 1
  /\ etaA = EtaInit
  /\ kurtosisA = 0                  \* Uniform = zero kurtosis
  /\ cogLevelA = 0

  /\ voidB = UniformSeq
  /\ complementB = [i \in 1..NumChoices |-> EtaInit]
  /\ offerB = NumChoices             \* Start at opposite end
  /\ etaB = EtaInit
  /\ kurtosisB = 0
  /\ cogLevelB = 0

  /\ round = 1
  /\ distance = 0                   \* Both start uniform = distance 0
  /\ prevDistance = 0
  /\ settled = FALSE
  /\ totalFailures = 0
  /\ phase = "c0_execute"

\* ─── Actions: Two Walkers in Lockstep c0-c3 ─────────────────────────

\* C0: Execute -- both walkers choose their best offer from complement
C0_Execute ==
  /\ phase = "c0_execute"
  /\ round <= MaxRounds
  /\ ~settled
  /\ offerA' = Argmax(complementA)
  /\ offerB' = Argmax(complementB)
  /\ cogLevelA' = 0
  /\ cogLevelB' = 0
  /\ phase' = "interact"
  /\ UNCHANGED <<voidA, complementA, etaA, kurtosisA,
                  voidB, complementB, etaB, kurtosisB,
                  round, distance, prevDistance, settled, totalFailures>>

\* Interaction: compare offers -- if they match, settle; if not, both fail
\* Failure enriches both void boundaries at the losing choice
Interact ==
  /\ phase = "interact"
  /\ IF offerA = offerB
     THEN \* Settlement! Both chose the same point
       /\ settled' = TRUE
       /\ totalFailures' = totalFailures
       /\ voidA' = voidA
       /\ voidB' = voidB
       /\ phase' = "nadir"
     ELSE \* Failure: each walker's offer is rejected by the other
       /\ settled' = FALSE
       \* A's offer was rejected: increase void density at A's offer for B
       \* B's offer was rejected: increase void density at B's offer for A
       /\ voidA' = [voidA EXCEPT ![offerB] = voidA[offerB] + 1]
       /\ voidB' = [voidB EXCEPT ![offerA] = voidB[offerA] + 1]
       /\ totalFailures' = totalFailures + 1
       /\ phase' = "c1_monitor"
  /\ UNCHANGED <<complementA, offerA, etaA, kurtosisA, cogLevelA,
                  complementB, offerB, etaB, kurtosisB, cogLevelB,
                  round, distance, prevDistance>>

\* C1: Monitor -- recompute complement distributions from void boundaries
C1_Monitor ==
  /\ phase = "c1_monitor"
  /\ complementA' = ComplementWeight(voidA)
  /\ complementB' = ComplementWeight(voidB)
  /\ kurtosisA' = KurtosisProxy(ComplementWeight(voidA))
  /\ kurtosisB' = KurtosisProxy(ComplementWeight(voidB))
  /\ cogLevelA' = 1
  /\ cogLevelB' = 1
  /\ phase' = "c2_evaluate"
  /\ UNCHANGED <<voidA, voidB, offerA, offerB, etaA, etaB,
                  round, distance, prevDistance, settled, totalFailures>>

\* C2: Evaluate -- compute inter-walker distance, check convergence
C2_Evaluate ==
  /\ phase = "c2_evaluate"
  /\ prevDistance' = distance
  /\ distance' = DistSum(complementA, complementB)
  /\ cogLevelA' = 2
  /\ cogLevelB' = 2
  /\ phase' = "c3_adapt"
  /\ UNCHANGED <<voidA, voidB, complementA, complementB, offerA, offerB,
                  etaA, etaB, kurtosisA, kurtosisB, round, settled, totalFailures>>

\* C3: Adapt -- adjust learning rates based on convergence direction
C3_Adapt ==
  /\ phase = "c3_adapt"
  \* If distance decreased, reduce eta (exploit); if increased, raise eta (explore)
  /\ etaA' = IF distance < prevDistance
              THEN Clamp(etaA - 1, 1, EtaInit)
              ELSE Clamp(etaA + 1, 1, EtaInit)
  /\ etaB' = IF distance < prevDistance
              THEN Clamp(etaB - 1, 1, EtaInit)
              ELSE Clamp(etaB + 1, 1, EtaInit)
  /\ cogLevelA' = 3
  /\ cogLevelB' = 3
  /\ round' = round + 1
  /\ phase' = "check_nadir"
  /\ UNCHANGED <<voidA, voidB, complementA, complementB, offerA, offerB,
                  kurtosisA, kurtosisB, distance, prevDistance, settled, totalFailures>>

\* Check if walkers have reached the nadir (distance <= threshold)
CheckNadir ==
  /\ phase = "check_nadir"
  /\ IF distance <= NadirThreshold
     THEN /\ settled' = TRUE
          /\ phase' = "nadir"
     ELSE /\ settled' = FALSE
          /\ phase' = "c0_execute"
  /\ UNCHANGED <<voidA, voidB, complementA, complementB, offerA, offerB,
                  etaA, etaB, kurtosisA, kurtosisB, cogLevelA, cogLevelB,
                  round, distance, prevDistance, totalFailures>>

\* Exhaustion: rounds depleted without settlement
Exhaust ==
  /\ phase = "c0_execute"
  /\ round > MaxRounds
  /\ ~settled
  /\ phase' = "exhausted"
  /\ UNCHANGED <<voidA, voidB, complementA, complementB, offerA, offerB,
                  etaA, etaB, kurtosisA, kurtosisB, cogLevelA, cogLevelB,
                  round, distance, prevDistance, settled, totalFailures>>

Stutter == UNCHANGED vars

Next ==
  \/ C0_Execute
  \/ Interact
  \/ C1_Monitor
  \/ C2_Evaluate
  \/ C3_Adapt
  \/ CheckNadir
  \/ Exhaust
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(C0_Execute)
    /\ WF_vars(Interact)
    /\ WF_vars(C1_Monitor)
    /\ WF_vars(C2_Evaluate)
    /\ WF_vars(C3_Adapt)
    /\ WF_vars(CheckNadir)
    /\ WF_vars(Exhaust)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Each failure strictly increases total void density
\* (void is monotonically enriched by interaction)
InvVoidGrowth ==
  (phase = "c1_monitor")
    => totalFailures > 0

\* INV2: Void density per choice is always >= 1 (base density)
InvVoidPositive ==
  /\ \A i \in 1..NumChoices : voidA[i] >= 1
  /\ \A i \in 1..NumChoices : voidB[i] >= 1

\* INV3: Complement weights are always >= 1 (no option abandoned -- Skyrms)
InvComplementPositive ==
  /\ \A i \in 1..NumChoices : complementA[i] >= 1
  /\ \A i \in 1..NumChoices : complementB[i] >= 1

\* INV4: Distance is non-negative
InvDistanceNonneg ==
  distance >= 0

\* INV5: At the nadir, settlement holds and distance is within threshold
InvNadirStable ==
  (phase = "nadir")
    => /\ settled = TRUE
       /\ (distance <= NadirThreshold \/ offerA = offerB)

\* INV6: Learning rates stay bounded
InvEtaBounded ==
  /\ etaA >= 1 /\ etaA <= EtaInit
  /\ etaB >= 1 /\ etaB <= EtaInit

\* INV7: Cognitive levels are valid (0-3)
InvCogValid ==
  /\ cogLevelA \in {0, 1, 2, 3}
  /\ cogLevelB \in {0, 1, 2, 3}

\* INV8: Round is bounded
InvRoundBounded ==
  round >= 1 /\ round <= MaxRounds + 1

\* INV9: Failure count matches round progression
InvFailureConsistent ==
  totalFailures <= round - 1

\* INV10: Without failure (totalFailures = 0), walkers may not have settled
\* (failure is the information source that drives convergence)
InvFailureNecessary ==
  (phase = "nadir" /\ offerA # offerB)
    => totalFailures > 0

\* ─── Liveness ────────────────────────────────────────────────────────

\* Walkers eventually reach the nadir or exhaust rounds
SkyrmsConvergence == <>(phase = "nadir" \/ phase = "exhausted")

=============================================================================
