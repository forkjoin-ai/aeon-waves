------------------------------ MODULE open_source_gnosis_aic_bias_inducer ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"hypothesis", "bias_report", "hypothesis: Outcome", "semantic_pass: Logic", "contextual_pass: Logic", "temporal_pass: Logic", "semantic_pass", "contextual_pass", "temporal_pass", "bias_report: Data"}
ROOTS == {"hypothesis: Outcome", "semantic_pass", "contextual_pass", "temporal_pass"}
TERMINALS == {"semantic_pass: Logic", "contextual_pass: Logic", "temporal_pass: Logic", "bias_report: Data"}
FOLD_TARGETS == {"bias_report: Data"}
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
  /\ CanFire({"hypothesis: Outcome"})
  /\ active' = UpdateActive({"hypothesis: Outcome"}, {"semantic_pass: Logic", "contextual_pass: Logic", "temporal_pass: Logic"})
  /\ beta1' = beta1 + (Cardinality({"semantic_pass: Logic", "contextual_pass: Logic", "temporal_pass: Logic"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"semantic_pass: Logic", "contextual_pass: Logic", "temporal_pass: Logic"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"semantic_pass", "contextual_pass", "temporal_pass"})
  /\ active' = UpdateActive({"semantic_pass", "contextual_pass", "temporal_pass"}, {"bias_report: Data"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"bias_report: Data"} \cap FOLD_TARGETS # {})

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
