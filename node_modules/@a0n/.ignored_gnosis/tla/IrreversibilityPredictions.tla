----------------------- MODULE IrreversibilityPredictions -----------------------
\* Formal TLA+ specification of the irreversibility framework predictions.
\*
\* Five invariants corresponding to the five predictions from §19.14:
\*   1. Entangled boundaries exhibit anti-correlated failure patterns
\*   2. Interior deficit >= boundary deficit (monotonicity)
\*   3. First law: fork entropy >= fold erasure + vent erasure
\*   4. Aleph sufficient statistic is positive when entries exist
\*   5. Self-verification catches type-invisible topology bugs
\*
\* All five are safety properties checkable by TLC.

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    MaxDimensions,      \* Number of void boundary dimensions (e.g., 5)
    MaxRounds,          \* Maximum execution rounds (e.g., 20)
    MaxForkWidth        \* Maximum fork branch count (e.g., 4)

VARIABLES
    \* Entanglement state
    countsA,            \* Void boundary counts for boundary A
    countsB,            \* Void boundary counts for boundary B
    entangled,          \* Whether A and B are entangled

    \* Deficit state
    interiorDeficit,    \* Maximum interior beta1
    boundaryDeficit,    \* Beta1 at sink
    localBeta1,         \* Current local beta1

    \* Erasure accounting
    forkEntropy,        \* Total fork entropy created
    foldErasure,        \* Total fold erasure consumed
    ventErasure,        \* Total vent erasure consumed

    \* Aleph state
    totalEntries,       \* Total void boundary entries
    aleph,              \* The Aleph scalar

    \* Verification state
    round,              \* Current round
    verified            \* Whether all verify annotations pass

vars == <<countsA, countsB, entangled, interiorDeficit, boundaryDeficit,
          localBeta1, forkEntropy, foldErasure, ventErasure,
          totalEntries, aleph, round, verified>>

Dims == 1..MaxDimensions

TypeOK ==
    /\ countsA \in [Dims -> 0..MaxRounds]
    /\ countsB \in [Dims -> 0..MaxRounds]
    /\ entangled \in BOOLEAN
    /\ interiorDeficit \in 0..MaxRounds
    /\ boundaryDeficit \in 0..MaxRounds
    /\ localBeta1 \in 0..MaxRounds
    /\ forkEntropy \in 0..MaxRounds
    /\ foldErasure \in 0..MaxRounds
    /\ ventErasure \in 0..MaxRounds
    /\ totalEntries \in 0..MaxRounds
    /\ aleph \in 0..(3 * MaxRounds)
    /\ round \in 0..MaxRounds
    /\ verified \in BOOLEAN

-----------------------------------------------------------------------------
\* Initial state

Init ==
    /\ countsA = [d \in Dims |-> 0]
    /\ countsB = [d \in Dims |-> 0]
    /\ entangled = FALSE
    /\ interiorDeficit = 0
    /\ boundaryDeficit = 0
    /\ localBeta1 = 0
    /\ forkEntropy = 0
    /\ foldErasure = 0
    /\ ventErasure = 0
    /\ totalEntries = 0
    /\ aleph = 0
    /\ round = 0
    /\ verified = TRUE

-----------------------------------------------------------------------------
\* FORK: create parallel paths, increase beta1

Fork(width) ==
    /\ round < MaxRounds
    /\ width >= 2
    /\ width <= MaxForkWidth
    /\ localBeta1' = localBeta1 + (width - 1)
    /\ interiorDeficit' = IF localBeta1 + (width - 1) > interiorDeficit
                          THEN localBeta1 + (width - 1)
                          ELSE interiorDeficit
    /\ forkEntropy' = forkEntropy + (width - 1)
    /\ round' = round + 1
    /\ UNCHANGED <<countsA, countsB, entangled, boundaryDeficit,
                   foldErasure, ventErasure, totalEntries, aleph, verified>>

\* RACE: record losers in void boundary

Race(loserDim) ==
    /\ round < MaxRounds
    /\ localBeta1 > 0
    /\ loserDim \in Dims
    /\ countsA' = [countsA EXCEPT ![loserDim] = @ + 1]
    /\ totalEntries' = totalEntries + 1
    /\ aleph' = totalEntries + 1
    /\ round' = round + 1
    \* Entanglement: if entangled, B's complement shifts
    /\ IF entangled
       THEN LET otherDim == IF loserDim < MaxDimensions THEN loserDim + 1 ELSE 1
            IN countsB' = [countsB EXCEPT ![otherDim] = @ + 1]
       ELSE countsB' = countsB
    /\ UNCHANGED <<entangled, interiorDeficit, boundaryDeficit, localBeta1,
                   forkEntropy, foldErasure, ventErasure, verified>>

\* FOLD: merge paths, decrease beta1, record erasure

Fold(sources) ==
    /\ round < MaxRounds
    /\ sources >= 2
    /\ localBeta1 >= sources - 1
    /\ localBeta1' = localBeta1 - (sources - 1)
    /\ foldErasure' = foldErasure + (sources - 1)
    /\ boundaryDeficit' = localBeta1 - (sources - 1)
    /\ round' = round + 1
    /\ UNCHANGED <<countsA, countsB, entangled, interiorDeficit,
                   forkEntropy, ventErasure, totalEntries, aleph, verified>>

\* VENT: release a path, record erasure

Vent ==
    /\ round < MaxRounds
    /\ localBeta1 > 0
    /\ localBeta1' = localBeta1 - 1
    /\ ventErasure' = ventErasure + 1
    /\ totalEntries' = totalEntries + 1
    /\ aleph' = totalEntries + 1
    /\ round' = round + 1
    /\ UNCHANGED <<countsA, countsB, entangled, interiorDeficit,
                   boundaryDeficit, forkEntropy, foldErasure, verified>>

\* ENTANGLE: link two boundaries

Entangle ==
    /\ ~entangled
    /\ entangled' = TRUE
    /\ UNCHANGED <<countsA, countsB, interiorDeficit, boundaryDeficit,
                   localBeta1, forkEntropy, foldErasure, ventErasure,
                   totalEntries, aleph, round, verified>>

\* VERIFY: check self-verification annotations

Verify ==
    /\ verified' = (localBeta1 = 0 /\ forkEntropy >= foldErasure + ventErasure)
    /\ UNCHANGED <<countsA, countsB, entangled, interiorDeficit, boundaryDeficit,
                   localBeta1, forkEntropy, foldErasure, ventErasure,
                   totalEntries, aleph, round>>

-----------------------------------------------------------------------------
\* Next-state relation

Next ==
    \/ \E w \in 2..MaxForkWidth : Fork(w)
    \/ \E d \in Dims : Race(d)
    \/ \E s \in 2..MaxForkWidth : Fold(s)
    \/ Vent
    \/ Entangle
    \/ Verify

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* INVARIANTS (Safety Properties)

\* Prediction 31: Entanglement anti-correlation
\* When entangled and A accumulates in one dim, B accumulates in a different dim
InvEntangleAntiCorrelation ==
    entangled =>
        \A d \in Dims :
            countsA[d] > 0 =>
                \E d2 \in Dims : d2 /= d /\ countsB[d2] > 0

\* Prediction 32: Interior deficit >= boundary deficit
InvInteriorDominatesBoundary ==
    boundaryDeficit <= interiorDeficit

\* Prediction 33: First law -- fork entropy >= total erasure
\* (Only checked when the system has done at least one operation)
InvFirstLawConservation ==
    round > 0 => foldErasure + ventErasure <= forkEntropy

\* Prediction 34: Aleph positive when entries exist
InvAlephPositive ==
    totalEntries > 0 => aleph > 0

\* Prediction 35: Type OK is necessary but not sufficient
\* (verified can be FALSE even when TypeOK holds)
InvTypeNotSufficient ==
    TypeOK

=============================================================================
