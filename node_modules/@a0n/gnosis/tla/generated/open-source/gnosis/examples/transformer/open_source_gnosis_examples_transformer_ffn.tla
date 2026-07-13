------------------------------ MODULE open_source_gnosis_examples_transformer_ffn ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"ffn_input", "expand", "activate", "contract", "dropout", "ffn_out"}
ROOTS == {"ffn_input"}
TERMINALS == {"ffn_out"}
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
  /\ CanFire({"ffn_input"})
  /\ active' = UpdateActive({"ffn_input"}, {"expand"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"expand"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"expand"})
  /\ active' = UpdateActive({"expand"}, {"activate"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"activate"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"activate"})
  /\ active' = UpdateActive({"activate"}, {"contract"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"contract"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"contract"})
  /\ active' = UpdateActive({"contract"}, {"dropout"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"dropout"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"dropout"})
  /\ active' = UpdateActive({"dropout"}, {"ffn_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ffn_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS

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
