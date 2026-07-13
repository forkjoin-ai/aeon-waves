------------------------------ MODULE open_source_gnosis_ai_hello ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"input", "encoder", "relu", "head1", "head2", "decoder", "output", "context", "prediction"}
ROOTS == {"input"}
TERMINALS == {"prediction"}
FOLD_TARGETS == {"context"}
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
  /\ CanFire({"input"})
  /\ active' = UpdateActive({"input"}, {"encoder"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"encoder"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"encoder"})
  /\ active' = UpdateActive({"encoder"}, {"relu"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"relu"} \cap FOLD_TARGETS # {})
Edge_03_FORK ==
  /\ CanFire({"relu"})
  /\ active' = UpdateActive({"relu"}, {"head1", "head2"})
  /\ beta1' = beta1 + (Cardinality({"head1", "head2"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"head1", "head2"} \cap FOLD_TARGETS # {})
Edge_04_FOLD ==
  /\ CanFire({"head1", "head2"})
  /\ active' = UpdateActive({"head1", "head2"}, {"context"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"context"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"context"})
  /\ active' = UpdateActive({"context"}, {"decoder"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"decoder"} \cap FOLD_TARGETS # {})
Edge_06_PROCESS ==
  /\ CanFire({"decoder"})
  /\ active' = UpdateActive({"decoder"}, {"output"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"output"} \cap FOLD_TARGETS # {})
Edge_07_PROCESS ==
  /\ CanFire({"output"})
  /\ active' = UpdateActive({"output"}, {"prediction"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"prediction"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_FORK
  \/ Edge_04_FOLD
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
