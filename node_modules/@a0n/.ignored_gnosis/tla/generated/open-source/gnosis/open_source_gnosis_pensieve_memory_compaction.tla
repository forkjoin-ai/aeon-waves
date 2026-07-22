------------------------------ MODULE open_source_gnosis_pensieve_memory_compaction ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"trigger", "compact", "trigger: Cron", "scan_old: GC", "scan_redundant: GC", "scan_old", "scan_redundant", "compact: Action"}
ROOTS == {"trigger: Cron", "scan_old", "scan_redundant"}
TERMINALS == {"scan_old: GC", "scan_redundant: GC", "compact: Action"}
FOLD_TARGETS == {"compact: Action"}
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
  /\ CanFire({"trigger: Cron"})
  /\ active' = UpdateActive({"trigger: Cron"}, {"scan_old: GC", "scan_redundant: GC"})
  /\ beta1' = beta1 + (Cardinality({"scan_old: GC", "scan_redundant: GC"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"scan_old: GC", "scan_redundant: GC"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"scan_old", "scan_redundant"})
  /\ active' = UpdateActive({"scan_old", "scan_redundant"}, {"compact: Action"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"compact: Action"} \cap FOLD_TARGETS # {})

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
