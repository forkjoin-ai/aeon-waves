------------------------------ MODULE open_source_gnosis_examples_crdt_qregister ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"register", "write_a", "write_b", "write_c", "observed"}
ROOTS == {"register"}
TERMINALS == {"observed"}
FOLD_TARGETS == {"observed"}
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
  /\ CanFire({"register"})
  /\ active' = UpdateActive({"register"}, {"write_a", "write_b", "write_c"})
  /\ beta1' = beta1 + (Cardinality({"write_a", "write_b", "write_c"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"write_a", "write_b", "write_c"} \cap FOLD_TARGETS # {})
Edge_02_OBSERVE ==
  /\ CanFire({"write_a", "write_b", "write_c"})
  /\ active' = UpdateActive({"write_a", "write_b", "write_c"}, {"observed"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"observed"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_OBSERVE

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
