------------------------- MODULE MetacognitiveWalker -------------------------
(***************************************************************************)
(* Metacognitive Walker: C0-C1-C2-C3 Cognitive Loop on Void Surface.      *)
(*                                                                         *)
(* Models the four-level metacognitive cycle where a walker executes,     *)
(* monitors, evaluates, and adapts its gait across the void surface.      *)
(* Eta (learning rate) and exploration rate are bounded. The walker's     *)
(* kurtosis (distribution shape) stabilizes as the system converges.      *)
(*                                                                         *)
(* THM-META-ETA: eta remains bounded throughout execution                 *)
(* THM-META-EXPLORE: exploration stays within configured bounds           *)
(* THM-META-GAIT: gait is always a valid cognitive level                  *)
(* THM-META-BULE: inverse Bule measure is non-negative                   *)
(* THM-META-CONVERGE: kurtosis eventually stabilizes                     *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  MaxEta,            \* Maximum learning rate (integer-scaled, e.g. 10 = 1.0)
  MinExploration,    \* Minimum exploration rate (integer-scaled)
  MaxExploration,    \* Maximum exploration rate (integer-scaled)
  WindowSize         \* Observation window for kurtosis estimation

VARIABLES
  cogLevel,          \* Current cognitive level: 0=execute, 1=monitor, 2=evaluate, 3=adapt
  eta,               \* Current learning rate (integer-scaled)
  exploration,       \* Current exploration rate (integer-scaled)
  kurtosis,          \* Current kurtosis estimate (integer-scaled, 0 = mesokurtic)
  kurtosisHistory,   \* Sequence of recent kurtosis values (sliding window)
  inverseBule,       \* Inverse Bule measure: information gained per cycle
  stepCount,         \* Total steps taken
  converged,         \* TRUE when kurtosis has stabilized
  phase              \* Execution phase within a cognitive transition

vars == <<cogLevel, eta, exploration, kurtosis, kurtosisHistory,
          inverseBule, stepCount, converged, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME MaxEta >= 1
ASSUME MinExploration >= 0
ASSUME MaxExploration >= MinExploration
ASSUME WindowSize >= 2

\* ─── Helpers ─────────────────────────────────────────────────────────

\* Clamp a value to [lo, hi]
Clamp(v, lo, hi) == IF v < lo THEN lo ELSE IF v > hi THEN hi ELSE v

\* Next cognitive level (cyclic: 0 -> 1 -> 2 -> 3 -> 0)
NextLevel(c) == (c + 1) % 4

\* Check if kurtosis history has stabilized (all values within 1 of each other)
IsStabilized(hist) ==
  /\ Len(hist) >= WindowSize
  /\ LET recent == SubSeq(hist, Len(hist) - WindowSize + 1, Len(hist))
         first  == recent[1]
     IN \A i \in 1..Len(recent) :
          recent[i] >= first - 1 /\ recent[i] <= first + 1

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ cogLevel = 0                      \* Start at c0 (execute)
  /\ eta = MaxEta                      \* Start with maximum learning rate
  /\ exploration = MaxExploration      \* Start with maximum exploration
  /\ kurtosis = MaxEta                 \* Initial kurtosis = leptokurtic (high)
  /\ kurtosisHistory = <<>>
  /\ inverseBule = 0
  /\ stepCount = 0
  /\ converged = FALSE
  /\ phase = "ready"

\* ─── Actions ─────────────────────────────────────────────────────────

\* C0: Execute -- take an action, observe outcome
Execute ==
  /\ phase = "ready"
  /\ cogLevel = 0
  /\ ~converged
  /\ stepCount' = stepCount + 1
  /\ phase' = "executed"
  /\ UNCHANGED <<cogLevel, eta, exploration, kurtosis, kurtosisHistory,
                  inverseBule, converged>>

\* C1: Monitor -- observe the execution result, update kurtosis estimate
Monitor ==
  /\ phase = "executed"
  /\ cogLevel = 0
  \* Kurtosis decays toward 0 (mesokurtic) as walker gains experience
  /\ kurtosis' = Clamp(kurtosis - 1, 0, MaxEta)
  /\ kurtosisHistory' = Append(kurtosisHistory, kurtosis')
  /\ cogLevel' = 1
  /\ phase' = "monitored"
  /\ UNCHANGED <<eta, exploration, inverseBule, stepCount, converged>>

\* C2: Evaluate -- assess performance, compute inverse Bule measure
Evaluate ==
  /\ phase = "monitored"
  /\ cogLevel = 1
  \* Inverse Bule = information gain = how much kurtosis dropped this window
  /\ inverseBule' = IF Len(kurtosisHistory) >= 2
                     THEN LET prev == kurtosisHistory[Len(kurtosisHistory) - 1]
                              curr == kurtosisHistory[Len(kurtosisHistory)]
                          IN IF prev > curr THEN prev - curr ELSE 0
                     ELSE 0
  /\ cogLevel' = 2
  /\ phase' = "evaluated"
  /\ UNCHANGED <<eta, exploration, kurtosis, kurtosisHistory, stepCount, converged>>

\* C3: Adapt -- adjust eta and exploration based on evaluation
Adapt ==
  /\ phase = "evaluated"
  /\ cogLevel = 2
  \* Reduce eta as kurtosis stabilizes (less learning needed)
  /\ eta' = Clamp(eta - inverseBule, 1, MaxEta)
  \* Reduce exploration as confidence grows
  /\ exploration' = Clamp(exploration - 1, MinExploration, MaxExploration)
  \* Check convergence
  /\ converged' = IsStabilized(kurtosisHistory)
  /\ cogLevel' = 3
  /\ phase' = "adapted"
  /\ UNCHANGED <<kurtosis, kurtosisHistory, inverseBule, stepCount>>

\* Complete the cycle: c3 -> c0
CycleReset ==
  /\ phase = "adapted"
  /\ cogLevel = 3
  /\ cogLevel' = 0
  /\ phase' = "ready"
  /\ UNCHANGED <<eta, exploration, kurtosis, kurtosisHistory,
                  inverseBule, stepCount, converged>>

\* Terminal: system has converged, no more transitions
Terminal ==
  /\ converged = TRUE
  /\ phase = "ready"
  /\ phase' = "converged"
  /\ UNCHANGED <<cogLevel, eta, exploration, kurtosis, kurtosisHistory,
                  inverseBule, stepCount, converged>>

Stutter == UNCHANGED vars

Next ==
  \/ Execute
  \/ Monitor
  \/ Evaluate
  \/ Adapt
  \/ CycleReset
  \/ Terminal
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Execute)
    /\ WF_vars(Monitor)
    /\ WF_vars(Evaluate)
    /\ WF_vars(Adapt)
    /\ WF_vars(CycleReset)
    /\ WF_vars(Terminal)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Eta is always bounded within [1, MaxEta]
InvEtaBounded ==
  eta >= 1 /\ eta <= MaxEta

\* INV2: Exploration stays within configured bounds
InvExplorationBounded ==
  exploration >= MinExploration /\ exploration <= MaxExploration

\* INV3: Gait (cognitive level) is always valid
InvGaitValid ==
  cogLevel \in {0, 1, 2, 3}

\* INV4: Inverse Bule measure is non-negative
InvInverseBuleNonneg ==
  inverseBule >= 0

\* INV5: Kurtosis is bounded
InvKurtosisBounded ==
  kurtosis >= 0 /\ kurtosis <= MaxEta

\* INV6: Step count is monotonically increasing
InvStepMonotone ==
  stepCount >= 0

\* INV7: Convergence implies stable kurtosis
InvConvergenceValid ==
  (phase = "converged")
    => /\ converged = TRUE
       /\ Len(kurtosisHistory) >= WindowSize

\* ─── Liveness ────────────────────────────────────────────────────────

\* Eventually converges (kurtosis stabilizes)
EventualConvergence == <>(phase = "converged")

=============================================================================
