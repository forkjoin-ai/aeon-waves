------------------------------ MODULE open_source_gnosis_flux_state_reconciliation ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"merged_state", "local_state: Graph", "remote_state: Graph", "merged_state: Graph"}
ROOTS == {"local_state: Graph", "remote_state: Graph"}
TERMINALS == {"merged_state: Graph"}
FOLD_TARGETS == {"merged_state: Graph"}
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

Edge_01_FOLD ==
  /\ CanFire({"local_state: Graph", "remote_state: Graph"})
  /\ active' = UpdateActive({"local_state: Graph", "remote_state: Graph"}, {"merged_state: Graph"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"merged_state: Graph"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FOLD

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
