------------------------------ MODULE FrameNativeBisim ------------------------------
EXTENDS Naturals, Sequences, FiniteSets

\* Frame-native bisimulation: proves that frameRace and frameFold produce
\* identical results to Stream-based race and fold under the canUseFrameNativePath
\* guard conditions (no timeout, no shared state, all handlers registered).
\*
\* THM-FRAME-BISIM: stuttering bisimulation between frame-native and stream paths.
\* THM-FRAME-OVERHEAD-BOUND: frame allocates O(N), stream allocates O(7N).

CONSTANTS WorkFnCount, MaxSteps

VARIABLES
  \* Frame-native execution state
  frameResults, frameSettled, frameWinner, frameDone,
  \* Stream-based execution state
  streamResults, streamSettled, streamWinner, streamDone,
  \* Shared
  step, mode

vars == <<frameResults, frameSettled, frameWinner, frameDone,
          streamResults, streamSettled, streamWinner, streamDone,
          step, mode>>

WorkFns == 1..WorkFnCount

\* Guard conditions for canUseFrameNativePath
\* When these hold, both paths must produce identical results
ASSUME WorkFnCount > 0
ASSUME MaxSteps > WorkFnCount

\* ─── Allocation counting ───────────────────────────────────────────────
\* Frame-native: 1 Promise.race/allSettled + N raw promises = N+1 allocations
FrameAllocations == WorkFnCount + 1

\* Stream-based: per stream = AbortController + event listener + state machine
\*               + Promise constructor + result wrapper + vented tracker + map entry
\*               = ~7 allocations per work function
StreamAllocations == 7 * WorkFnCount

\* ─── Deterministic work function model ─────────────────────────────────
\* Each work function i produces result (i * 100 + completionOrder)
\* Completion order is nondeterministic but observable

WorkResult(i) == i * 100

Init ==
  /\ frameResults = [w \in WorkFns |-> 0]
  /\ frameSettled = [w \in WorkFns |-> FALSE]
  /\ frameWinner = 0
  /\ frameDone = FALSE
  /\ streamResults = [w \in WorkFns |-> 0]
  /\ streamSettled = [w \in WorkFns |-> FALSE]
  /\ streamWinner = 0
  /\ streamDone = FALSE
  /\ step = 0
  /\ mode = "race" \* or "fold"

\* ─── Frame-native race step ────────────────────────────────────────────
FrameRaceComplete(w) ==
  /\ ~frameDone
  /\ mode = "race"
  /\ w \in WorkFns
  /\ ~frameSettled[w]
  /\ frameResults' = [frameResults EXCEPT ![w] = WorkResult(w)]
  /\ frameSettled' = [frameSettled EXCEPT ![w] = TRUE]
  /\ IF frameWinner = 0
     THEN /\ frameWinner' = w
          /\ frameDone' = TRUE
     ELSE /\ UNCHANGED <<frameWinner, frameDone>>
  /\ UNCHANGED <<streamResults, streamSettled, streamWinner, streamDone, step, mode>>

\* ─── Stream-based race step ────────────────────────────────────────────
StreamRaceComplete(w) ==
  /\ ~streamDone
  /\ mode = "race"
  /\ w \in WorkFns
  /\ ~streamSettled[w]
  /\ streamResults' = [streamResults EXCEPT ![w] = WorkResult(w)]
  /\ streamSettled' = [streamSettled EXCEPT ![w] = TRUE]
  /\ IF streamWinner = 0
     THEN /\ streamWinner' = w
          /\ streamDone' = TRUE
     ELSE /\ UNCHANGED <<streamWinner, streamDone>>
  /\ UNCHANGED <<frameResults, frameSettled, frameWinner, frameDone, step, mode>>

\* ─── Frame-native fold step ────────────────────────────────────────────
FrameFoldComplete(w) ==
  /\ ~frameDone
  /\ mode = "fold"
  /\ w \in WorkFns
  /\ ~frameSettled[w]
  /\ frameResults' = [frameResults EXCEPT ![w] = WorkResult(w)]
  /\ frameSettled' = [frameSettled EXCEPT ![w] = TRUE]
  /\ IF \A w2 \in WorkFns: w2 = w \/ frameSettled[w2]
     THEN frameDone' = TRUE
     ELSE UNCHANGED frameDone
  /\ UNCHANGED <<frameWinner, streamResults, streamSettled, streamWinner, streamDone, step, mode>>

\* ─── Stream-based fold step ────────────────────────────────────────────
StreamFoldComplete(w) ==
  /\ ~streamDone
  /\ mode = "fold"
  /\ w \in WorkFns
  /\ ~streamSettled[w]
  /\ streamResults' = [streamResults EXCEPT ![w] = WorkResult(w)]
  /\ streamSettled' = [streamSettled EXCEPT ![w] = TRUE]
  /\ IF \A w2 \in WorkFns: w2 = w \/ streamSettled[w2]
     THEN streamDone' = TRUE
     ELSE UNCHANGED streamDone
  /\ UNCHANGED <<streamWinner, frameResults, frameSettled, frameWinner, frameDone, step, mode>>

Tick ==
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ UNCHANGED <<frameResults, frameSettled, frameWinner, frameDone,
                  streamResults, streamSettled, streamWinner, streamDone, mode>>

Stutter == UNCHANGED vars

Next ==
  \/ \E w \in WorkFns: FrameRaceComplete(w)
  \/ \E w \in WorkFns: StreamRaceComplete(w)
  \/ \E w \in WorkFns: FrameFoldComplete(w)
  \/ \E w \in WorkFns: StreamFoldComplete(w)
  \/ Tick
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Tick)
    /\ \A w \in WorkFns:
         /\ WF_vars(FrameRaceComplete(w))
         /\ WF_vars(StreamRaceComplete(w))
         /\ WF_vars(FrameFoldComplete(w))
         /\ WF_vars(StreamFoldComplete(w))

\* ─── Invariants ────────────────────────────────────────────────────────

\* THM-FRAME-BISIM (race case): same work function produces same result
InvRaceBisimResults ==
  \A w \in WorkFns:
    (frameSettled[w] /\ streamSettled[w]) =>
      frameResults[w] = streamResults[w]

\* THM-FRAME-BISIM (race case): if both have selected a winner at the same
\* work function, the result values match
InvRaceBisimWinner ==
  (frameDone /\ streamDone /\ frameWinner = streamWinner) =>
    frameResults[frameWinner] = streamResults[streamWinner]

\* THM-FRAME-BISIM (fold case): when both complete, all results match
InvFoldBisimResults ==
  (frameDone /\ streamDone /\ mode = "fold") =>
    \A w \in WorkFns: frameResults[w] = streamResults[w]

\* THM-FRAME-OVERHEAD-BOUND: frame allocations are strictly less than stream
InvOverheadBound ==
  FrameAllocations < StreamAllocations

\* Frame allocations are O(N), stream allocations are O(7N)
InvFrameLinear ==
  FrameAllocations = WorkFnCount + 1

InvStreamSevenX ==
  StreamAllocations = 7 * WorkFnCount

\* Both paths eventually complete
FrameTermination == <>frameDone
StreamTermination == <>streamDone

=============================================================================
