------------------------------ MODULE open_source_gnosis_agent_mesh_gossip ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"event", "global_state", "event: Gossip", "peer_1: Agent", "peer_2: Agent", "peer_1", "peer_2", "global_state: State"}
ROOTS == {"event: Gossip", "peer_1", "peer_2"}
TERMINALS == {"peer_1: Agent", "peer_2: Agent", "global_state: State"}
FOLD_TARGETS == {"global_state: State"}
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
  /\ CanFire({"event: Gossip"})
  /\ active' = UpdateActive({"event: Gossip"}, {"peer_1: Agent", "peer_2: Agent"})
  /\ beta1' = beta1 + (Cardinality({"peer_1: Agent", "peer_2: Agent"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"peer_1: Agent", "peer_2: Agent"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"peer_1", "peer_2"})
  /\ active' = UpdateActive({"peer_1", "peer_2"}, {"global_state: State"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"global_state: State"} \cap FOLD_TARGETS # {})

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
