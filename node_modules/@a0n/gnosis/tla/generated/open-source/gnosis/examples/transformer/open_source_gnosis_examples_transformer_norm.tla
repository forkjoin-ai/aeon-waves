------------------------------ MODULE open_source_gnosis_examples_transformer_norm ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"norm_input", "statistics", "normalize", "scale", "norm_out"}
ROOTS == {"norm_input"}
TERMINALS == {"norm_out"}
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
  /\ CanFire({"norm_input"})
  /\ active' = UpdateActive({"norm_input"}, {"statistics"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"statistics"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"statistics"})
  /\ active' = UpdateActive({"statistics"}, {"normalize"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"normalize"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"normalize"})
  /\ active' = UpdateActive({"normalize"}, {"scale"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"scale"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"scale"})
  /\ active' = UpdateActive({"scale"}, {"norm_out"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"norm_out"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS

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
