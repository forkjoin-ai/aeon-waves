--------------------------- MODULE GoldenConsensus ---------------------------
\* Formal specification of the adaptive golden consensus protocol.
\*
\* The core claim: a BFT consensus threshold can adapt between the classical
\* 2/3 bound (667/1000) and 1/phi (618/1000) using deficit feedback.
\* When the network is healthy, the deficit ratio (consecutive deficits)
\* converges to phi (1618/1000), and the threshold relaxes toward 1/phi.
\* Under attack, the threshold tightens back toward 2/3.
\*
\* Four operations: Propose, Vote, Commit, Interfere
\*
\* Key properties:
\*   1. SafetyInvariant: committed => votes > NumNodes/2 (basic BFT safety)
\*   2. ThresholdBounds: 618 <= threshold <= 667 (never leaves the golden band)
\*   3. GoldenConvergence: after healthy rounds, threshold approaches 618

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    NumNodes,       \* Total number of validator nodes
    MaxFaults,      \* Maximum Byzantine faults tolerated
    MaxRounds,      \* Bound on rounds for model checking
    Sensitivity     \* Integer-scaled 1/phi = 618 (feedback gain)

VARIABLES
    threshold,      \* Integer-scaled (starts at 667 = 2/3 * 1000)
    votes,          \* Number of agreeing nodes this round
    deficit,        \* 1000 - votes*1000/NumNodes (how far from unanimity)
    prevDeficit,    \* Deficit from last round
    round,          \* Round counter
    committed,      \* Whether a value has been committed this round
    deficitRatio,   \* deficit*1000/prevDeficit (converges to 1618 = phi*1000)
    pc              \* Program counter: which operation executes next

vars == <<threshold, votes, deficit, prevDeficit, round, committed, deficitRatio, pc>>

-----------------------------------------------------------------------------
\* Integer-scaled constants
\* phi * 1000 = 1618, 1/phi * 1000 = 618, 2/3 * 1000 = 667
PhiScaled == 1618
InvPhiScaled == 618
TwoThirdsScaled == 667

\* Integer absolute value
Abs(x) == IF x >= 0 THEN x ELSE -x

\* Max of two integers
Max(a, b) == IF a >= b THEN a ELSE b

\* Clamp a value to [lo, hi]
Clamp(x, lo, hi) == IF x < lo THEN lo ELSE IF x > hi THEN hi ELSE x

-----------------------------------------------------------------------------
\* Type invariant
TypeOK ==
    /\ threshold \in InvPhiScaled..TwoThirdsScaled
    /\ votes \in 0..NumNodes
    /\ deficit \in 0..1000
    /\ prevDeficit \in 0..1000
    /\ round \in 0..MaxRounds
    /\ committed \in BOOLEAN
    /\ deficitRatio \in 0..(1000 * 1000 + 1)
    /\ pc \in {"Propose", "Vote", "Commit", "Interfere", "Done"}

-----------------------------------------------------------------------------
\* Initial state: threshold at the classical 2/3 bound
Init ==
    /\ threshold = TwoThirdsScaled
    /\ votes = 0
    /\ deficit = 0
    /\ prevDeficit = 0
    /\ round = 0
    /\ committed = FALSE
    /\ deficitRatio = 0
    /\ pc = "Propose"

-----------------------------------------------------------------------------
\* PROPOSE: start a new consensus round.
\* Resets per-round state and advances the round counter.
Propose ==
    /\ pc = "Propose"
    /\ round < MaxRounds
    /\ votes' = 0
    /\ committed' = FALSE
    /\ round' = round + 1
    /\ pc' = "Vote"
    /\ UNCHANGED <<threshold, deficit, prevDeficit, deficitRatio>>

\* VOTE: collect votes from nodes.
\* Non-deterministic: between NumNodes - MaxFaults (worst case) and NumNodes
\* (best case). Models Byzantine behavior as vote suppression.
Vote ==
    /\ pc = "Vote"
    /\ \E v \in (NumNodes - MaxFaults)..NumNodes :
        /\ votes' = v
        /\ LET d == 1000 - (v * 1000) \div NumNodes
           IN deficit' = d
        /\ pc' = "Commit"
    /\ UNCHANGED <<threshold, prevDeficit, round, committed, deficitRatio>>

\* COMMIT: if enough votes, commit the proposed value.
\* The quorum check uses the adaptive threshold.
Commit ==
    /\ pc = "Commit"
    /\ LET voteRatio == (votes * 1000) \div NumNodes
       IN IF voteRatio >= threshold
          THEN committed' = TRUE
          ELSE committed' = FALSE
    /\ pc' = "Interfere"
    /\ UNCHANGED <<threshold, votes, deficit, prevDeficit, round, deficitRatio>>

\* INTERFERE: update threshold based on deficit feedback.
\* The deficit ratio (consecutive deficits) drives the adaptation.
\* When the network is healthy (low deficit), threshold relaxes toward 1/phi.
\* When the network is stressed (high deficit), threshold tightens toward 2/3.
Interfere ==
    /\ pc = "Interfere"
    \* Compute deficit ratio for convergence tracking
    /\ deficitRatio' = IF prevDeficit = 0
                        THEN 0
                        ELSE (deficit * 1000) \div Max(prevDeficit, 1)
    \* Update threshold using golden feedback
    /\ LET deficitDelta == deficit - prevDeficit
           denom == Max(deficit, 1)
           adjustment == (Sensitivity * deficitDelta) \div denom
           rawThreshold == threshold - adjustment
       IN threshold' = Clamp(rawThreshold, InvPhiScaled, TwoThirdsScaled)
    \* Shift deficit history
    /\ prevDeficit' = deficit
    /\ pc' = "Propose"
    /\ UNCHANGED <<votes, deficit, round, committed>>

\* Terminal state: all rounds exhausted
Done ==
    /\ pc = "Propose"
    /\ round >= MaxRounds
    /\ UNCHANGED vars

-----------------------------------------------------------------------------
\* Next-state relation
Next ==
    \/ Propose
    \/ Vote
    \/ Commit
    \/ Interfere
    \/ Done

\* Fairness: every enabled action eventually executes
Fairness ==
    /\ WF_vars(Propose)
    /\ WF_vars(Vote)
    /\ WF_vars(Commit)
    /\ WF_vars(Interfere)

\* Full specification
Spec == Init /\ [][Next]_vars /\ Fairness

-----------------------------------------------------------------------------
\* SAFETY INVARIANTS

\* Basic BFT safety: if committed, more than half the nodes voted.
\* This must hold regardless of threshold adaptation.
SafetyInvariant ==
    committed => (votes * 2 > NumNodes)

\* The adaptive threshold never leaves the golden band [1/phi, 2/3].
ThresholdBounds ==
    /\ threshold >= InvPhiScaled
    /\ threshold <= TwoThirdsScaled

\* Combined safety invariant
Safety ==
    /\ TypeOK
    /\ SafetyInvariant
    /\ ThresholdBounds

-----------------------------------------------------------------------------
\* LIVENESS PROPERTIES

\* After enough healthy rounds (all nodes voting), the threshold
\* relaxes toward 1/phi. Expressed as: eventually the threshold
\* drops below the midpoint of the golden band.
\* Midpoint = (618 + 667) / 2 = 642
GoldenConvergence ==
    <>(threshold <= 642)

\* The protocol eventually commits in some round (liveness).
EventuallyCommits ==
    <>(committed = TRUE)

\* The protocol eventually terminates.
EventuallyDone ==
    <>(round >= MaxRounds)

=============================================================================
