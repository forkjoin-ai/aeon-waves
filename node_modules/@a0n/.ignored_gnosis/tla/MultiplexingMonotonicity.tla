------------------------------ MODULE MultiplexingMonotonicity ------------------------------
EXTENDS Naturals

CONSTANTS BusyDomain, SequentialCapacityDomain, OverlapDomain

VARIABLES busy, seqCap, overlap

vars == <<busy, seqCap, overlap>>

Init ==
  /\ busy \in BusyDomain
  /\ seqCap \in SequentialCapacityDomain
  /\ overlap \in OverlapDomain
  /\ busy > 0
  /\ seqCap >= busy
  /\ overlap <= seqCap - busy

Change ==
  /\ busy' \in BusyDomain
  /\ seqCap' \in SequentialCapacityDomain
  /\ overlap' \in OverlapDomain
  /\ busy' > 0
  /\ seqCap' >= busy'
  /\ overlap' <= seqCap' - busy'

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

MuxCap == seqCap - overlap

SeqFillNum == busy
SeqFillDen == seqCap
MuxFillNum == busy
MuxFillDen == MuxCap

SeqWallaceNum == seqCap - busy
SeqWallaceDen == seqCap
MuxWallaceNum == MuxCap - busy
MuxWallaceDen == MuxCap

InvWellFormed ==
  /\ busy > 0
  /\ seqCap >= busy
  /\ overlap <= seqCap - busy

InvMuxCapacityBounds ==
  /\ MuxCap > 0
  /\ MuxCap >= busy

InvWallaceNumeratorMonotone ==
  /\ MuxWallaceNum <= SeqWallaceNum
  /\ SeqWallaceNum - MuxWallaceNum = overlap

InvFillMonotone ==
  SeqFillNum * MuxFillDen <= MuxFillNum * SeqFillDen

InvWallaceRatioMonotone ==
  MuxWallaceNum * SeqWallaceDen <= SeqWallaceNum * MuxWallaceDen

InvWallaceRatioStrictWhenOverlapRecovered ==
  overlap > 0 =>
    MuxWallaceNum * SeqWallaceDen < SeqWallaceNum * MuxWallaceDen

=============================================================================
