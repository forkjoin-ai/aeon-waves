------------------------------ MODULE open_source_gnosis_aeon_flow_inference ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"prompt", "chunk_1", "chunk_2", "idle_slot", "processed_1", "processed_2", "final_output"}
ROOTS == {"prompt", "idle_slot"}
TERMINALS == {"final_output"}
FOLD_TARGETS == {"final_output"}
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
  /\ CanFire({"prompt"})
  /\ active' = UpdateActive({"prompt"}, {"chunk_1", "chunk_2"})
  /\ beta1' = beta1 + (Cardinality({"chunk_1", "chunk_2"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"chunk_1", "chunk_2"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"chunk_1", "idle_slot"})
  /\ \E winner \in {"processed_1"}:
      /\ active' = UpdateActive({"chunk_1", "idle_slot"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"chunk_1", "idle_slot"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_03_RACE ==
  /\ CanFire({"chunk_2", "idle_slot"})
  /\ \E winner \in {"processed_2"}:
      /\ active' = UpdateActive({"chunk_2", "idle_slot"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"chunk_2", "idle_slot"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_FOLD ==
  /\ CanFire({"processed_1", "processed_2"})
  /\ active' = UpdateActive({"processed_1", "processed_2"}, {"final_output"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"final_output"} \cap FOLD_TARGETS # {})

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
