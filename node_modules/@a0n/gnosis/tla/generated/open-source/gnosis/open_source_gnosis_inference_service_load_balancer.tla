------------------------------ MODULE open_source_gnosis_inference_service_load_balancer ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"req", "assigned_worker", "req: Payload", "worker_1: GPU", "worker_2: GPU", "worker_1", "worker_2", "assigned_worker: Worker"}
ROOTS == {"req: Payload", "worker_1", "worker_2"}
TERMINALS == {"worker_1: GPU", "worker_2: GPU", "assigned_worker: Worker"}
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

Edge_01_FORK ==
  /\ CanFire({"req: Payload"})
  /\ active' = UpdateActive({"req: Payload"}, {"worker_1: GPU", "worker_2: GPU"})
  /\ beta1' = beta1 + (Cardinality({"worker_1: GPU", "worker_2: GPU"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"worker_1: GPU", "worker_2: GPU"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"worker_1", "worker_2"})
  /\ \E winner \in {"assigned_worker: Worker"}:
      /\ active' = UpdateActive({"worker_1", "worker_2"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"worker_1", "worker_2"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE

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
