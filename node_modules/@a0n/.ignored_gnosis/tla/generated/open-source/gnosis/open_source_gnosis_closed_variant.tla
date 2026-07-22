------------------------------ MODULE open_source_gnosis_closed_variant ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "state", "ready_payload", "retry_payload", "timeout_payload", "sink", "seed:Source", "state:Variant { adt: \"ReviewState\", cases: \"ready,retry,timeout\", caseFrom: \"status\" }", "ready_payload:Destructure { fields: \"message,score\" }", "retry_payload:Destructure { fields: \"attempts,message\" }", "timeout_payload:Sink", "sink:Sink"}
ROOTS == {"seed:Source", "state", "ready_payload", "retry_payload", "timeout_payload"}
TERMINALS == {"state:Variant { adt: \"ReviewState\", cases: \"ready,retry,timeout\", caseFrom: \"status\" }", "ready_payload:Destructure { fields: \"message,score\" }", "retry_payload:Destructure { fields: \"attempts,message\" }", "timeout_payload:Sink", "sink:Sink", "sink"}
FOLD_TARGETS == {}
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

Edge_01_PROCESS ==
  /\ CanFire({"seed:Source"})
  /\ active' = UpdateActive({"seed:Source"}, {"state:Variant { adt: \"ReviewState\", cases: \"ready,retry,timeout\", caseFrom: \"status\" }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"state:Variant { adt: \"ReviewState\", cases: \"ready,retry,timeout\", caseFrom: \"status\" }"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"state"})
  /\ active' = UpdateActive({"state"}, {"ready_payload:Destructure { fields: \"message,score\" }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ready_payload:Destructure { fields: \"message,score\" }"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"state"})
  /\ active' = UpdateActive({"state"}, {"retry_payload:Destructure { fields: \"attempts,message\" }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"retry_payload:Destructure { fields: \"attempts,message\" }"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"state"})
  /\ active' = UpdateActive({"state"}, {"timeout_payload:Sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"timeout_payload:Sink"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"ready_payload"})
  /\ active' = UpdateActive({"ready_payload"}, {"sink:Sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink:Sink"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"retry_payload"})
  /\ active' = UpdateActive({"retry_payload"}, {"sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"timeout_payload"})
  /\ active' = UpdateActive({"timeout_payload"}, {"sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_PROCESS
  \/ Edge_07_PROCESS

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
