------------------------------ MODULE open_source_gnosis_aeon_arch_03_d1_sync ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"write", "ack", "write: Mutation", "local_cache: DB", "remote_pool: DB", "local_cache", "remote_pool", "ack: Ack"}
ROOTS == {"write: Mutation", "local_cache", "remote_pool"}
TERMINALS == {"local_cache: DB", "remote_pool: DB", "ack: Ack"}
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
  /\ CanFire({"write: Mutation"})
  /\ active' = UpdateActive({"write: Mutation"}, {"local_cache: DB", "remote_pool: DB"})
  /\ beta1' = beta1 + (Cardinality({"local_cache: DB", "remote_pool: DB"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"local_cache: DB", "remote_pool: DB"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"local_cache", "remote_pool"})
  /\ \E winner \in {"ack: Ack"}:
      /\ active' = UpdateActive({"local_cache", "remote_pool"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"local_cache", "remote_pool"}) - 1))
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
