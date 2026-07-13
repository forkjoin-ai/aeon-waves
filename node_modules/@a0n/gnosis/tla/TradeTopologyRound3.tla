--------------------------- MODULE TradeTopologyRound3 ---------------------------
(*
  §19.50 Trade Topology Round 3 -- TLA+ Model Checking

  Five economic predictions from untapped theorem surfaces:
    P212: Price discrimination as rate-distortion quotient
    P213: Production line speedup via Wallington rotation
    P214: Cross-market inference via statistical teleportation
    P215: Organizational slack as Wallace waste
    P216: Regulatory harmonization as interference coarsening
*)
EXTENDS Naturals

VARIABLES
    segments,       \* Customer segments
    tiers,          \* Price tiers
    infoLoss,       \* segments - tiers
    stages,         \* Production stages
    lines,          \* Parallel production lines
    seqMakespan,    \* Sequential makespan
    flowMakespan,   \* Flow makespan
    deficit,        \* Market signal deficit
    stepsObserved,  \* Steps observed
    uncertainty,    \* Remaining uncertainty
    leadership,     \* Org leadership capacity
    middle,         \* Org middle capacity
    execution,      \* Org execution capacity
    slack,          \* Organizational slack
    jurisdictions,  \* Regulatory jurisdictions
    zones,          \* Harmonized zones
    fragmentation   \* jurisdictions - zones

vars == <<segments, tiers, infoLoss, stages, lines, seqMakespan, flowMakespan,
          deficit, stepsObserved, uncertainty, leadership, middle, execution,
          slack, jurisdictions, zones, fragmentation>>

CONSTANTS MaxSegments, MaxStages, MaxLines, MaxDeficit, MaxCapacity, MaxJurisdictions

Init ==
    /\ segments = MaxSegments
    /\ tiers = MaxSegments
    /\ infoLoss = 0
    /\ stages = MaxStages
    /\ lines = MaxLines
    /\ seqMakespan = MaxStages * MaxLines
    /\ flowMakespan = MaxStages
    /\ deficit = MaxDeficit
    /\ stepsObserved = 0
    /\ uncertainty = MaxDeficit
    /\ leadership = MaxCapacity
    /\ middle = MaxCapacity
    /\ execution = MaxCapacity
    /\ slack = 0
    /\ jurisdictions = MaxJurisdictions
    /\ zones = MaxJurisdictions
    /\ fragmentation = 0

CoarsenPricing ==
    /\ tiers > 1
    /\ tiers' = tiers - 1
    /\ infoLoss' = segments - tiers'
    /\ UNCHANGED <<segments, stages, lines, seqMakespan, flowMakespan,
                   deficit, stepsObserved, uncertainty, leadership, middle,
                   execution, slack, jurisdictions, zones, fragmentation>>

ObserveMarket ==
    /\ stepsObserved < deficit
    /\ stepsObserved' = stepsObserved + 1
    /\ uncertainty' = deficit - stepsObserved'
    /\ UNCHANGED <<segments, tiers, infoLoss, stages, lines, seqMakespan,
                   flowMakespan, deficit, leadership, middle, execution,
                   slack, jurisdictions, zones, fragmentation>>

HarmonizeRegulation ==
    /\ zones > 1
    /\ zones' = zones - 1
    /\ fragmentation' = jurisdictions - zones'
    /\ UNCHANGED <<segments, tiers, infoLoss, stages, lines, seqMakespan,
                   flowMakespan, deficit, stepsObserved, uncertainty,
                   leadership, middle, execution, slack, jurisdictions>>

Next == CoarsenPricing \/ ObserveMarket \/ HarmonizeRegulation
Spec == Init /\ [][Next]_vars

TypeOK ==
    /\ segments \in 1..MaxSegments
    /\ tiers \in 1..MaxSegments
    /\ infoLoss \in 0..MaxSegments
    /\ deficit \in 0..MaxDeficit
    /\ stepsObserved \in 0..MaxDeficit
    /\ uncertainty \in 0..MaxDeficit
    /\ jurisdictions \in 1..MaxJurisdictions
    /\ zones \in 1..MaxJurisdictions
    /\ fragmentation \in 0..MaxJurisdictions

InvInfoLoss == infoLoss = segments - tiers
InvUncertainty == uncertainty = deficit - stepsObserved
InvFragmentation == fragmentation = jurisdictions - zones
InvFlowDominates == flowMakespan <= seqMakespan
InvPerfectDiscriminationZero == tiers = segments => infoLoss = 0
InvConvergence == stepsObserved = deficit => uncertainty = 0
InvSlackNonneg == slack >= 0

AllInvariants ==
    /\ TypeOK /\ InvInfoLoss /\ InvUncertainty /\ InvFragmentation
    /\ InvFlowDominates /\ InvPerfectDiscriminationZero
    /\ InvConvergence /\ InvSlackNonneg

=============================================================================
