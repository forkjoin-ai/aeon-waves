------------------------------ MODULE CompilerOraclePredictions2 ------------------------------
\* TLA+ model-checking for predictions 16-20: pipeline waste, deficit lattice,
\* vent necessity/sufficiency, Reynolds-deficit correspondence, countdown composition.

EXTENDS Integers, FiniteSets

CONSTANTS MaxStages, MaxDeficit, MaxArrival

ASSUME MaxStages > 0
ASSUME MaxDeficit > 0
ASSUME MaxArrival > 0

VARIABLES
    stageWaste1, stageWaste2,   \* Two stage waste values
    deficit1, deficit2, deficit3, \* Three deficits for lattice
    initialBeta, ventCount,      \* Vent necessity/sufficiency
    arrival, capacity,           \* Reynolds-deficit
    s1Start, s1End, s2End       \* Countdown composition

vars == <<stageWaste1, stageWaste2, deficit1, deficit2, deficit3,
          initialBeta, ventCount, arrival, capacity,
          s1Start, s1End, s2End>>

StageRange == 0..MaxStages
DeficitRange == 0..MaxDeficit
ArrivalRange == 0..MaxArrival

Init ==
    /\ stageWaste1 \in StageRange
    /\ stageWaste2 \in StageRange
    /\ deficit1 \in DeficitRange
    /\ deficit2 \in DeficitRange
    /\ deficit3 \in DeficitRange
    /\ initialBeta \in 1..MaxDeficit
    /\ ventCount \in 0..MaxDeficit
    /\ arrival \in ArrivalRange
    /\ capacity \in 1..MaxArrival
    /\ s1Start \in 1..MaxStages
    /\ s1End \in 0..MaxStages
    /\ s2End \in 0..MaxStages
    /\ s1End <= s1Start
    /\ s2End <= s1End

Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* Prediction 16: Pipeline Waste Monotonicity

InvPipelineWasteMonotone ==
    stageWaste1 <= stageWaste1 + stageWaste2

InvPipelineWasteStrictOnNontrivial ==
    stageWaste2 > 0 => stageWaste1 < stageWaste1 + stageWaste2

InvPipelineWasteZero ==
    (stageWaste1 = 0 /\ stageWaste2 = 0) => stageWaste1 + stageWaste2 = 0

-----------------------------------------------------------------------------
\* Prediction 17: Deficit Lattice

MaxOf(a, b) == IF a >= b THEN a ELSE b

InvDeficitForkJoin ==
    MaxOf(deficit1, deficit2) <= deficit1 + deficit2

InvDeficitForkZeroLeft ==
    MaxOf(0, deficit1) = deficit1

InvDeficitForkComm ==
    MaxOf(deficit1, deficit2) = MaxOf(deficit2, deficit1)

InvDeficitForkAssoc ==
    MaxOf(MaxOf(deficit1, deficit2), deficit3)
    = MaxOf(deficit1, MaxOf(deficit2, deficit3))

-----------------------------------------------------------------------------
\* Prediction 18: Vent Necessity and Sufficiency

InvVentSufficiency ==
    initialBeta - initialBeta = 0

InvVentNecessity ==
    ventCount < initialBeta => (initialBeta - ventCount) > 0

InvVentStep ==
    (ventCount < initialBeta) =>
        (initialBeta - ventCount) = (initialBeta - (ventCount + 1)) + 1

-----------------------------------------------------------------------------
\* Prediction 19: Reynolds-Deficit Monotone Correspondence

NatSub(a, b) == IF a >= b THEN a - b ELSE 0

InvDeficitZeroWithinCapacity ==
    arrival <= capacity => NatSub(arrival, capacity) = 0

InvDeficitPositiveOverCapacity ==
    capacity < arrival => NatSub(arrival, capacity) > 0

InvDeficitMonotoneArrival ==
    \A a1, a2 \in ArrivalRange :
        a1 <= a2 => NatSub(a1, capacity) <= NatSub(a2, capacity)

-----------------------------------------------------------------------------
\* Prediction 20: Countdown Composition

InvCountdownStepDecreases ==
    s2End < s1End => s1End - 1 >= s2End

InvCountdownComposition ==
    (s1Start - s1End) + (s1End - s2End) = s1Start - s2End

=============================================================================
