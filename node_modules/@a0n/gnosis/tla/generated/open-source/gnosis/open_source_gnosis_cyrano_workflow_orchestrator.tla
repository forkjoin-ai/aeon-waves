------------------------------ MODULE open_source_gnosis_cyrano_workflow_orchestrator ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"workflow_trigger", "template_lookup", "execute_workflow_steps", "workflow_trigger: Event", "template_lookup: Config", "execute_workflow_steps: Flow"}
ROOTS == {"workflow_trigger: Event"}
TERMINALS == {"execute_workflow_steps: Flow"}
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

Edge_01_PROCESS ==
  /\ CanFire({"workflow_trigger: Event"})
  /\ active' = UpdateActive({"workflow_trigger: Event"}, {"template_lookup: Config"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"template_lookup: Config"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"template_lookup: Config"})
  /\ active' = UpdateActive({"template_lookup: Config"}, {"execute_workflow_steps: Flow"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"execute_workflow_steps: Flow"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS

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
