------------------------------ MODULE open_source_gnosis_crdt_sync_conflict ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"sync_event", "converged", "sync_event: Trigger", "apply_local: State", "merge_remote: State", "apply_local", "merge_remote", "converged: State"}
ROOTS == {"sync_event: Trigger", "apply_local", "merge_remote"}
TERMINALS == {"apply_local: State", "merge_remote: State", "converged: State"}
FOLD_TARGETS == {"converged: State"}
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
  /\ CanFire({"sync_event: Trigger"})
  /\ active' = UpdateActive({"sync_event: Trigger"}, {"apply_local: State", "merge_remote: State"})
  /\ beta1' = beta1 + (Cardinality({"apply_local: State", "merge_remote: State"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"apply_local: State", "merge_remote: State"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"apply_local", "merge_remote"})
  /\ active' = UpdateActive({"apply_local", "merge_remote"}, {"converged: State"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"converged: State"} \cap FOLD_TARGETS # {})

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
