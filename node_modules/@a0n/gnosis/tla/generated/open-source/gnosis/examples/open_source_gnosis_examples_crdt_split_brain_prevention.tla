------------------------------ MODULE open_source_gnosis_examples_crdt_split_brain_prevention ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"cluster_root", "replica_west", "replica_east", "write_west", "write_east", "guarded_west", "guarded_east", "canonical_state"}
ROOTS == {"cluster_root"}
TERMINALS == {"canonical_state"}
FOLD_TARGETS == {"canonical_state"}
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
  /\ CanFire({"cluster_root"})
  /\ active' = UpdateActive({"cluster_root"}, {"replica_west", "replica_east"})
  /\ beta1' = beta1 + (Cardinality({"replica_west", "replica_east"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"replica_west", "replica_east"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"replica_west"})
  /\ active' = UpdateActive({"replica_west"}, {"write_west"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"write_west"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"replica_east"})
  /\ active' = UpdateActive({"replica_east"}, {"write_east"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"write_east"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"write_west"})
  /\ active' = UpdateActive({"write_west"}, {"guarded_west"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"guarded_west"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"write_east"})
  /\ active' = UpdateActive({"write_east"}, {"guarded_east"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"guarded_east"} \cap FOLD_TARGETS # {})
Edge_06_OBSERVE ==
  /\ CanFire({"guarded_west", "guarded_east"})
  /\ active' = UpdateActive({"guarded_west", "guarded_east"}, {"canonical_state"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"canonical_state"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_OBSERVE

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
