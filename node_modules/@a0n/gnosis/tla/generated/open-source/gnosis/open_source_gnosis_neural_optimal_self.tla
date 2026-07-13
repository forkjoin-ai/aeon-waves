------------------------------ MODULE open_source_gnosis_neural_optimal_self ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"current_state", "optimal_self_model", "growth_vector", "current_state: State", "optimal_self_model: ONNX", "growth_vector: Vector"}
ROOTS == {"current_state: State"}
TERMINALS == {"growth_vector: Vector"}
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
  /\ CanFire({"current_state: State"})
  /\ active' = UpdateActive({"current_state: State"}, {"optimal_self_model: ONNX"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"optimal_self_model: ONNX"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"optimal_self_model: ONNX"})
  /\ active' = UpdateActive({"optimal_self_model: ONNX"}, {"growth_vector: Vector"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"growth_vector: Vector"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS

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
