------------------------------ MODULE open_source_gnosis_aeon_flow_sync ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"base_state", "peer_1_delta", "peer_2_delta", "canonical_race_1", "canonical_race_2", "divergent_1", "divergent_2", "merged_state"}
ROOTS == {"base_state", "canonical_race_1", "canonical_race_2"}
TERMINALS == {"merged_state"}
FOLD_TARGETS == {"merged_state"}
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
  /\ CanFire({"base_state"})
  /\ active' = UpdateActive({"base_state"}, {"peer_1_delta", "peer_2_delta"})
  /\ beta1' = beta1 + (Cardinality({"peer_1_delta", "peer_2_delta"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"peer_1_delta", "peer_2_delta"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"peer_1_delta", "canonical_race_1"})
  /\ \E winner \in {"divergent_1"}:
      /\ active' = UpdateActive({"peer_1_delta", "canonical_race_1"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"peer_1_delta", "canonical_race_1"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_03_RACE ==
  /\ CanFire({"peer_2_delta", "canonical_race_2"})
  /\ \E winner \in {"divergent_2"}:
      /\ active' = UpdateActive({"peer_2_delta", "canonical_race_2"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"peer_2_delta", "canonical_race_2"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_FOLD ==
  /\ CanFire({"divergent_1", "divergent_2"})
  /\ active' = UpdateActive({"divergent_1", "divergent_2"}, {"merged_state"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"merged_state"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE
  \/ Edge_03_RACE
  \/ Edge_04_FOLD

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
