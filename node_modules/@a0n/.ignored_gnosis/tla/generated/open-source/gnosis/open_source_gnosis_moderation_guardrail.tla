------------------------------ MODULE open_source_gnosis_moderation_guardrail ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"output", "safe_output", "output: Text", "pii_check: Guard", "toxicity_check: Guard", "pii_check", "toxicity_check", "safe_output: Text"}
ROOTS == {"output: Text", "pii_check", "toxicity_check"}
TERMINALS == {"pii_check: Guard", "toxicity_check: Guard", "safe_output: Text"}
FOLD_TARGETS == {"safe_output: Text"}
EFFECTS == {}
DECLARED_EFFECTS == {}
INFERRED_EFFECTS == {}

VARIABLES active, beta1, payloadPresent, consensusReached
vars == <<active, beta1, payloadPresent, consensusReached>>

Max2(a, b) == IF a > b THEN a ELSE b
CanFire(sourceSet) == sourceSet \subseteq active
UpdateActive(sourceSet, targetSet) == (active \ sourceSet) \cup targetSet

Init ==
  /\ active = ROOTS
  /\ beta1 = 0
  /\ payloadPresent = TRUE
  /\ consensusReached = FALSE

Edge_01_FORK ==
  /\ CanFire({"output: Text"})
  /\ active' = UpdateActive({"output: Text"}, {"pii_check: Guard", "toxicity_check: Guard"})
  /\ beta1' = beta1 + (Cardinality({"pii_check: Guard", "toxicity_check: Guard"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"pii_check: Guard", "toxicity_check: Guard"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"pii_check", "toxicity_check"})
  /\ active' = UpdateActive({"pii_check", "toxicity_check"}, {"safe_output: Text"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"safe_output: Text"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD

TypeInvariant ==
  /\ active \subseteq NODES
  /\ beta1 \in Nat
  /\ payloadPresent \in BOOLEAN
  /\ consensusReached \in BOOLEAN

NoLostPayloadInvariant == payloadPresent = TRUE
HasFoldTargets == FOLD_TARGETS # {}
EventuallyTerminal == <> (active \cap TERMINALS # {})
EventuallyConsensus == IF HasFoldTargets THEN <> consensusReached ELSE TRUE
DeadlockFree == []<>(ENABLED Next)

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ WF_vars(Next)

THEOREM Spec => []NoLostPayloadInvariant

=============================================================================
