---------------------------- MODULE HeteroMoAFabricPairing ----------------------------
EXTENDS Naturals

CONSTANTS HedgeDelayTicks

VARIABLES checked, agreementOk, earlyPrimaryOk, disagreementOk, singleDecisionOk

vars == <<checked, agreementOk, earlyPrimaryOk, disagreementOk, singleDecisionOk>>

ASSUME HedgeDelayTicks > 0

PairDecision(agree, primarySufficient, tick) ==
  IF agree THEN "accept-agreement"
  ELSE IF primarySufficient /\ tick < HedgeDelayTicks THEN "accept-primary"
  ELSE "escalate"

AgreementAccepts(agree, primarySufficient, tick) ==
  agree => PairDecision(agree, primarySufficient, tick) = "accept-agreement"

EarlyPrimarySkipsShadow(primarySufficient, tick) ==
  (primarySufficient /\ tick < HedgeDelayTicks) =>
    PairDecision(FALSE, primarySufficient, tick) = "accept-primary"

DisagreementEscalates(agree, primarySufficient, tick) ==
  (~agree /\ (~primarySufficient \/ HedgeDelayTicks <= tick)) =>
    PairDecision(agree, primarySufficient, tick) = "escalate"

SingleDecision(agree, primarySufficient, tick) ==
  PairDecision(agree, primarySufficient, tick) \in
    {"accept-agreement", "accept-primary", "escalate"}

Init ==
  /\ checked = FALSE
  /\ agreementOk = TRUE
  /\ earlyPrimaryOk = TRUE
  /\ disagreementOk = TRUE
  /\ singleDecisionOk = TRUE

CheckAll ==
  /\ ~checked
  /\ checked' = TRUE
  /\ agreementOk' =
      \A agree \in BOOLEAN, primarySufficient \in BOOLEAN, tick \in 0..(HedgeDelayTicks + 1):
        AgreementAccepts(agree, primarySufficient, tick)
  /\ earlyPrimaryOk' =
      \A primarySufficient \in BOOLEAN, tick \in 0..(HedgeDelayTicks + 1):
        EarlyPrimarySkipsShadow(primarySufficient, tick)
  /\ disagreementOk' =
      \A agree \in BOOLEAN, primarySufficient \in BOOLEAN, tick \in 0..(HedgeDelayTicks + 1):
        DisagreementEscalates(agree, primarySufficient, tick)
  /\ singleDecisionOk' =
      \A agree \in BOOLEAN, primarySufficient \in BOOLEAN, tick \in 0..(HedgeDelayTicks + 1):
        SingleDecision(agree, primarySufficient, tick)

Stutter ==
  UNCHANGED vars

Next ==
  CheckAll \/ Stutter

Spec ==
  Init /\ [][Next]_vars /\ WF_vars(CheckAll)

InvAgreementAccepts ==
  checked => agreementOk

InvSufficientPrimarySkipsShadow ==
  checked => earlyPrimaryOk

InvDisagreementEscalates ==
  checked => disagreementOk

InvNoDoubleAccept ==
  checked => singleDecisionOk

=============================================================================
