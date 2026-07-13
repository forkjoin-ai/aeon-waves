------------------------------ MODULE open_source_gnosis_examples_webgpu_graph_flattening ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"object_graph", "cpu_pointer_chase", "id_index", "bias_vector", "weight_matrix", "flatten_buffer", "gpu_kernel", "prediction_out"}
ROOTS == {"object_graph"}
TERMINALS == {"prediction_out"}
FOLD_TARGETS == {"flatten_buffer"}
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
  /\ CanFire({"object_graph"})
  /\ active' = UpdateActive({"object_graph"}, {"cpu_pointer_chase"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cpu_pointer_chase"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"object_graph"})
  /\ active' = UpdateActive({"object_graph"}, {"id_index", "bias_vector", "weight_matrix"})
  /\ beta1' = beta1 + (Cardinality({"id_index", "bias_vector", "weight_matrix"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"id_index", "bias_vector", "weight_matrix"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"id_index", "bias_vector", "weight_matrix"})
  /\ active' = UpdateActive({"id_index", "bias_vector", "weight_matrix"}, {"flatten_buffer"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"flatten_buffer"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"flatten_buffer"})
  /\ active' = UpdateActive({"flatten_buffer"}, {"gpu_kernel"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"gpu_kernel"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"cpu_pointer_chase", "gpu_kernel"})
  /\ \E winner \in {"prediction_out"}:
      /\ active' = UpdateActive({"cpu_pointer_chase", "gpu_kernel"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"cpu_pointer_chase", "gpu_kernel"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_FOLD
  \/ Edge_04_PROCESS
  \/ Edge_05_RACE

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
