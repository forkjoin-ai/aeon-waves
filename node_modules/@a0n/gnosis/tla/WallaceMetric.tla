------------------------------ MODULE WallaceMetric ------------------------------
EXTENDS Naturals

CONSTANTS LayerWidthDomain, DiamondWidthDomain

VARIABLES w1, w2, w3, k

vars == <<w1, w2, w3, k>>

Max2(a, b) == IF a >= b THEN a ELSE b

Init ==
  /\ w1 \in LayerWidthDomain
  /\ w2 \in LayerWidthDomain
  /\ w3 \in LayerWidthDomain
  /\ k \in DiamondWidthDomain

Change ==
  /\ w1' \in LayerWidthDomain
  /\ w2' \in LayerWidthDomain
  /\ w3' \in LayerWidthDomain
  /\ k' \in DiamondWidthDomain

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

FrontierArea == w1 + w2 + w3
PeakFrontier == Max2(w1, Max2(w2, w3))
EnvelopeArea == 3 * PeakFrontier
WallaceNum == EnvelopeArea - FrontierArea
WallaceDen == EnvelopeArea

FrontierFillNum == FrontierArea
FrontierFillDen == EnvelopeArea

DiamondFrontierArea == 1 + k + 1
DiamondPeak == Max2(1, Max2(k, 1))
DiamondEnvelope == 3 * DiamondPeak
DiamondWallaceNum == DiamondEnvelope - DiamondFrontierArea
DiamondWallaceDen == DiamondEnvelope

InvWellFormed ==
  /\ w1 > 0
  /\ w2 > 0
  /\ w3 > 0
  /\ k > 0

InvWallaceBounds ==
  /\ WallaceDen > 0
  /\ FrontierArea <= WallaceDen
  /\ WallaceNum >= 0
  /\ WallaceNum <= WallaceDen

InvWallaceComplement ==
  /\ FrontierFillDen = WallaceDen
  /\ FrontierFillNum + WallaceNum = WallaceDen

InvWallaceZeroIffFull ==
  (WallaceNum = 0) <=> (FrontierArea = WallaceDen)

InvDiamondPeak ==
  DiamondPeak = k

InvDiamondBounds ==
  /\ DiamondWallaceDen > 0
  /\ DiamondFrontierArea <= DiamondWallaceDen
  /\ DiamondWallaceNum >= 0
  /\ DiamondWallaceNum <= DiamondWallaceDen

InvDiamondClosedForm ==
  /\ DiamondFrontierArea = k + 2
  /\ DiamondEnvelope = 3 * k
  /\ DiamondWallaceNum = 2 * (k - 1)
  /\ DiamondWallaceDen = 3 * k

InvDiamondComplement ==
  DiamondFrontierArea + DiamondWallaceNum = DiamondWallaceDen

InvDiamondZeroIffUnit ==
  (DiamondWallaceNum = 0) <=> (k = 1)

=============================================================================
