------------------------------ MODULE open_source_gnosis_examples_crdt_qcounter ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"counter", "inc_a", "inc_b", "dec_c", "total"}
ROOTS == {"counter"}
TERMINALS == {"total"}
FOLD_TARGETS == {"total"}
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
  /\ CanFire({"counter"})
  /\ active' = UpdateActive({"counter"}, {"inc_a", "inc_b", "dec_c"})
  /\ beta1' = beta1 + (Cardinality({"inc_a", "inc_b", "dec_c"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"inc_a", "inc_b", "dec_c"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"inc_a", "inc_b", "dec_c"})
  /\ active' = UpdateActive({"inc_a", "inc_b", "dec_c"}, {"total"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"total"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_FOLD

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
