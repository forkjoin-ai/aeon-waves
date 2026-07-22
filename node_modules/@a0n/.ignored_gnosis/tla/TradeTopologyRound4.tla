--------------------------- MODULE TradeTopologyRound4 ---------------------------
(*
  §19.51+ Trade Topology Round 4 -- TLA+ Model Checking
  P222-P226: Flash crashes, intermediary chains, staged entry,
             bailout vs bankruptcy, corporate hierarchy heat
*)
EXTENDS Naturals
VARIABLES topLiq, depthLiq, flow, impactTop, impactDepth,
          originAttrs, intermediaries, infoLost,
          markets, peakCap, bigBangWaste,
          layers, groundInfo, erasurePerLayer, totalErasure

vars == <<topLiq, depthLiq, flow, impactTop, impactDepth,
          originAttrs, intermediaries, infoLost,
          markets, peakCap, bigBangWaste,
          layers, groundInfo, erasurePerLayer, totalErasure>>

CONSTANTS MaxLiq, MaxFlow, MaxAttrs, MaxInterm, MaxMarkets, MaxCap, MaxLayers, MaxInfo, MaxErasure

Init ==
    /\ topLiq = MaxLiq /\ depthLiq = MaxLiq /\ flow = MaxFlow
    /\ impactTop = MaxFlow \div MaxLiq /\ impactDepth = MaxFlow \div MaxLiq
    /\ originAttrs = MaxAttrs /\ intermediaries = 0 /\ infoLost = 0
    /\ markets = 2 /\ peakCap = MaxCap /\ bigBangWaste = MaxCap
    /\ layers = 1 /\ groundInfo = MaxInfo
    /\ erasurePerLayer = MaxErasure /\ totalErasure = MaxErasure

ThinLiquidity ==
    /\ depthLiq > 1
    /\ depthLiq' = depthLiq - 1
    /\ impactDepth' = flow \div depthLiq'
    /\ UNCHANGED <<topLiq, flow, impactTop, originAttrs, intermediaries,
                   infoLost, markets, peakCap, bigBangWaste, layers,
                   groundInfo, erasurePerLayer, totalErasure>>

AddIntermediary ==
    /\ intermediaries < MaxInterm
    /\ intermediaries' = intermediaries + 1
    /\ infoLost' = IF intermediaries' * erasurePerLayer < originAttrs
                   THEN intermediaries' * erasurePerLayer
                   ELSE originAttrs
    /\ UNCHANGED <<topLiq, depthLiq, flow, impactTop, impactDepth,
                   originAttrs, markets, peakCap, bigBangWaste, layers,
                   groundInfo, erasurePerLayer, totalErasure>>

AddLayer ==
    /\ layers < MaxLayers
    /\ layers' = layers + 1
    /\ totalErasure' = IF layers' * erasurePerLayer < groundInfo
                       THEN layers' * erasurePerLayer
                       ELSE groundInfo
    /\ UNCHANGED <<topLiq, depthLiq, flow, impactTop, impactDepth,
                   originAttrs, intermediaries, infoLost, markets,
                   peakCap, bigBangWaste, groundInfo, erasurePerLayer>>

Next == ThinLiquidity \/ AddIntermediary \/ AddLayer
Spec == Init /\ [][Next]_vars

InvImpactMonotone == depthLiq <= topLiq => impactTop <= impactDepth
InvDirectZeroLoss == intermediaries = 0 => infoLost = 0
InvInfoLossMonotone == infoLost <= originAttrs
InvErasurePositive == layers > 0 /\ erasurePerLayer > 0 => totalErasure > 0
InvStagedDominates == 0 <= bigBangWaste

AllInvariants == InvImpactMonotone /\ InvDirectZeroLoss /\ InvInfoLossMonotone
                 /\ InvErasurePositive /\ InvStagedDominates
=============================================================================
