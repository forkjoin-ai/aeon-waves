------------------------------ MODULE WarmupEfficiency ------------------------------
EXTENDS Naturals

CONSTANTS BusyDomain, SequentialCapacityDomain, OverlapDomain, BuleyRiseDomain, WallaceWeightDomain

VARIABLES busy, seqCap, overlap, buleyRise, wallaceWeight

vars == <<busy, seqCap, overlap, buleyRise, wallaceWeight>>

Init ==
  /\ busy \in BusyDomain
  /\ seqCap \in SequentialCapacityDomain
  /\ overlap \in OverlapDomain
  /\ buleyRise \in BuleyRiseDomain
  /\ wallaceWeight \in WallaceWeightDomain
  /\ busy > 0
  /\ seqCap >= busy
  /\ overlap <= seqCap - busy
  /\ wallaceWeight > 0

Change ==
  /\ busy' \in BusyDomain
  /\ seqCap' \in SequentialCapacityDomain
  /\ overlap' \in OverlapDomain
  /\ buleyRise' \in BuleyRiseDomain
  /\ wallaceWeight' \in WallaceWeightDomain
  /\ busy' > 0
  /\ seqCap' >= busy'
  /\ overlap' <= seqCap' - busy'
  /\ wallaceWeight' > 0

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

WarmCap == seqCap - overlap

SeqWallaceNum == seqCap - busy
SeqWallaceDen == seqCap

WarmWallaceNum == WarmCap - busy
WarmWallaceDen == WarmCap

WallaceDropCross ==
  SeqWallaceNum * WarmWallaceDen - WarmWallaceNum * SeqWallaceDen

WeightedWallaceBenefit ==
  wallaceWeight * WallaceDropCross

BurdenScalar ==
  buleyRise * seqCap * WarmCap

WorthWarmup ==
  WeightedWallaceBenefit > BurdenScalar

InvWellFormed ==
  /\ busy > 0
  /\ seqCap >= busy
  /\ overlap <= seqCap - busy
  /\ wallaceWeight > 0

InvWarmCapacityBounds ==
  /\ WarmCap > 0
  /\ WarmCap >= busy

InvWallaceDropCrossClosedForm ==
  WallaceDropCross = busy * overlap

InvBurdenScalarClosedForm ==
  BurdenScalar = buleyRise * seqCap * WarmCap

InvWorthWarmupIffExplicit ==
  WorthWarmup <=>
    wallaceWeight * busy * overlap > BurdenScalar

InvWorthWarmupIffShiftedUtility ==
  WorthWarmup <=>
    wallaceWeight * busy * seqCap >
      wallaceWeight * busy * WarmCap +
        BurdenScalar

InvFreeWarmupWorthWhenOverlapRecovered ==
  (/\ buleyRise = 0
   /\ overlap > 0)
    => WorthWarmup

InvNoRecoveryNotWorthWhenBuleyPositive ==
  (/\ overlap = 0
   /\ buleyRise > 0)
    => ~WorthWarmup

=============================================================================
