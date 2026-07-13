------------------------------ MODULE open_source_gnosis_qubit_measure ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "superposed", "collapse", "one_path", "zero_path"}
ROOTS == {"seed"}
TERMINALS == {"one_path", "zero_path"}
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
  /\ CanFire({"seed"})
  /\ active' = UpdateActive({"seed"}, {"superposed"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"superposed"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"superposed"})
  /\ active' = UpdateActive({"superposed"}, {"collapse"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"collapse"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"collapse"})
  /\ active' = UpdateActive({"collapse"}, {"one_path"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"one_path"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"collapse"})
  /\ active' = UpdateActive({"collapse"}, {"zero_path"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"zero_path"} \cap FOLD_TARGETS # {})

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
