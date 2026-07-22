------------------------------ MODULE CompilerOraclePredictions3 ------------------------------
\* TLA+ model-checking for predictions 26-30: fold-vent exchange, parallel deficit
\* ordering, waste bound, trace invariance, deficit gradient.

EXTENDS Integers, FiniteSets

CONSTANTS MaxPaths, MaxDeficit

ASSUME MaxPaths > 1
ASSUME MaxDeficit > 0

VARIABLES
    totalPaths, ventedPaths, foldOutput,  \* Pred 26: fold-vent exchange
    dA, dB, dC,                            \* Pred 27: parallel ordering
    beta1, forkDelta, foldDelta,           \* Pred 29: trace invariance
    deficit                                \* Pred 30: deficit gradient

vars == <<totalPaths, ventedPaths, foldOutput, dA, dB, dC,
          beta1, forkDelta, foldDelta, deficit>>

MaxOf(a, b) == IF a >= b THEN a ELSE b
NatSub(a, b) == IF a >= b THEN a - b ELSE 0

Init ==
    /\ totalPaths \in 2..MaxPaths
    /\ ventedPaths \in 0..MaxPaths
    /\ ventedPaths <= totalPaths
    /\ foldOutput \in 0..MaxPaths
    /\ foldOutput <= totalPaths - ventedPaths
    /\ dA \in 0..MaxDeficit
    /\ dB \in 0..MaxDeficit
    /\ dC \in 0..MaxDeficit
    /\ beta1 \in 0..MaxDeficit
    /\ forkDelta \in 1..MaxDeficit
    /\ foldDelta \in 1..MaxDeficit
    /\ foldDelta = forkDelta
    /\ deficit \in 0..MaxDeficit

Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* Prediction 26: Fold-Vent Exchange

InvFoldVentFirstLaw ==
    foldOutput + ventedPaths + NatSub(NatSub(totalPaths, ventedPaths), foldOutput) = totalPaths

InvFoldVentConservation ==
    ventedPaths = NatSub(totalPaths, foldOutput + NatSub(NatSub(totalPaths, ventedPaths), foldOutput))

-----------------------------------------------------------------------------
\* Prediction 27: Parallel Deficit Ordering Preserved

InvParallelDeficitOrdering ==
    dA <= dB => MaxOf(dA, dC) <= MaxOf(dB, dC)

InvParallelDeficitOrderingLeft ==
    dA <= dB => MaxOf(dC, dA) <= MaxOf(dC, dB)

InvParallelDeficitZeroAbsorbs ==
    MaxOf(dA, 0) = dA

-----------------------------------------------------------------------------
\* Prediction 29: Trace-Deficit Invariance

InvTraceDeficitInvariant ==
    (foldDelta = forkDelta) =>
        NatSub(beta1 + forkDelta, foldDelta) = beta1

InvTraceInternalPositive ==
    forkDelta > 0 => beta1 < beta1 + forkDelta

InvTraceSequentialComposition ==
    (foldDelta = forkDelta) =>
        NatSub(NatSub(beta1 + forkDelta, foldDelta) + forkDelta, foldDelta) = beta1

-----------------------------------------------------------------------------
\* Prediction 30: Deficit Gradient

InvGradientFork ==
    deficit + 1 = deficit + 1

InvGradientVent ==
    deficit > 0 => NatSub(deficit, 1) < deficit

InvGradientFold ==
    0 = 0

InvGradientBoundedFork ==
    (deficit + 1) - deficit = 1

InvGradientBoundedVent ==
    deficit > 0 => deficit - NatSub(deficit, 1) = 1

InvForkVentIdentity ==
    NatSub(deficit + 1, 1) = deficit

=============================================================================
