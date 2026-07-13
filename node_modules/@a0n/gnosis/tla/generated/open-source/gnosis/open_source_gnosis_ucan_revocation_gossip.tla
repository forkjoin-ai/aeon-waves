------------------------------ MODULE open_source_gnosis_ucan_revocation_gossip ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"revoke", "global_ban", "revoke: Cmd", "edge_a: Cache", "edge_b: Cache", "edge_a", "edge_b", "global_ban: List"}
ROOTS == {"revoke: Cmd", "edge_a", "edge_b"}
TERMINALS == {"edge_a: Cache", "edge_b: Cache", "global_ban: List"}
FOLD_TARGETS == {"global_ban: List"}
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
  /\ CanFire({"revoke: Cmd"})
  /\ active' = UpdateActive({"revoke: Cmd"}, {"edge_a: Cache", "edge_b: Cache"})
  /\ beta1' = beta1 + (Cardinality({"edge_a: Cache", "edge_b: Cache"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"edge_a: Cache", "edge_b: Cache"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"edge_a", "edge_b"})
  /\ active' = UpdateActive({"edge_a", "edge_b"}, {"global_ban: List"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"global_ban: List"} \cap FOLD_TARGETS # {})

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
