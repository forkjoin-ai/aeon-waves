------------------------------ MODULE open_source_gnosis_isolation_tests ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"discovery", "test_path", "raw_outcome", "total_summary", "verified_state", "exit", "test_path:IsolatedPath", "raw_outcome:Outcome", "total_summary:Summary", "verified_state:FinalState", "exit:SystemExit"}
ROOTS == {"discovery", "test_path", "raw_outcome", "total_summary", "verified_state"}
TERMINALS == {"test_path:IsolatedPath", "raw_outcome:Outcome", "total_summary:Summary", "verified_state:FinalState", "exit:SystemExit"}
FOLD_TARGETS == {"total_summary:Summary"}
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
  /\ CanFire({"discovery"})
  /\ active' = UpdateActive({"discovery"}, {"test_path:IsolatedPath"})
  /\ beta1' = beta1 + (Cardinality({"test_path:IsolatedPath"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"test_path:IsolatedPath"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"test_path"})
  /\ active' = UpdateActive({"test_path"}, {"raw_outcome:Outcome"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"raw_outcome:Outcome"} \cap FOLD_TARGETS # {})
Edge_03_FOLD ==
  /\ CanFire({"raw_outcome"})
  /\ active' = UpdateActive({"raw_outcome"}, {"total_summary:Summary"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"total_summary:Summary"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"total_summary"})
  /\ active' = UpdateActive({"total_summary"}, {"verified_state:FinalState"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verified_state:FinalState"} \cap FOLD_TARGETS # {})
Edge_05_VENT ==
  /\ CanFire({"verified_state"})
  /\ active' = UpdateActive({"verified_state"}, {"exit:SystemExit"})
  /\ beta1' = Max2(0, beta1 - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"exit:SystemExit"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_FOLD
  \/ Edge_04_PROCESS
  \/ Edge_05_VENT

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
