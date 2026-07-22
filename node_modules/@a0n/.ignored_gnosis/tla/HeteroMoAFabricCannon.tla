---------------------------- MODULE HeteroMoAFabricCannon ----------------------------
EXTENDS Naturals

CONSTANTS LaneCount, WaveWidth, HedgeDelayTicks, HeaderBytes, MaxSteps

VARIABLES armed, launched, shadowEligible, cursor, step

vars == <<armed, launched, shadowEligible, cursor, step>>

ASSUME LaneCount > 0
ASSUME WaveWidth > 0
ASSUME HedgeDelayTicks > 0
ASSUME MaxSteps >= HedgeDelayTicks

Init ==
  /\ armed = FALSE
  /\ launched = FALSE
  /\ shadowEligible = FALSE
  /\ cursor = 0
  /\ step = 0

PreArm ==
  /\ ~armed
  /\ armed' = TRUE
  /\ UNCHANGED <<launched, shadowEligible, cursor, step>>

Tick ==
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ shadowEligible' = shadowEligible \/ step + 1 >= HedgeDelayTicks
  /\ UNCHANGED <<armed, launched, cursor>>

Launch ==
  /\ armed
  /\ ~launched
  /\ launched' = TRUE
  /\ cursor' = (cursor + WaveWidth) % LaneCount
  /\ UNCHANGED <<armed, shadowEligible, step>>

Stutter ==
  UNCHANGED vars

Next ==
  \/ PreArm
  \/ Tick
  \/ Launch
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(PreArm)
    /\ WF_vars(Tick)
    /\ WF_vars(Launch)

InvArmedBeforeLaunch ==
  launched => armed

InvCursorBound ==
  cursor < LaneCount

InvCursorAdvance ==
  launched => cursor = WaveWidth % LaneCount

InvAeonBinaryHeader ==
  HeaderBytes = 10

InvShadowEligibility ==
  shadowEligible => HedgeDelayTicks <= step

EventuallyLaunch ==
  <> launched

EventuallyShadowEligibility ==
  <> shadowEligible

=============================================================================
