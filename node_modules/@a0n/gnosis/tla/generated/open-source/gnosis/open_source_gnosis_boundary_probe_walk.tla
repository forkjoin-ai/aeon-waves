------------------------------ MODULE open_source_gnosis_boundary_probe_walk ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"probe", "report", "probe: Test", "model_a: Target", "model_b: Target", "model_a", "model_b", "report: Diff"}
ROOTS == {"probe: Test", "model_a", "model_b"}
TERMINALS == {"model_a: Target", "model_b: Target", "report: Diff"}
FOLD_TARGETS == {"report: Diff"}
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
  /\ CanFire({"probe: Test"})
  /\ active' = UpdateActive({"probe: Test"}, {"model_a: Target", "model_b: Target"})
  /\ beta1' = beta1 + (Cardinality({"model_a: Target", "model_b: Target"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"model_a: Target", "model_b: Target"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"model_a", "model_b"})
  /\ active' = UpdateActive({"model_a", "model_b"}, {"report: Diff"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"report: Diff"} \cap FOLD_TARGETS # {})

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
