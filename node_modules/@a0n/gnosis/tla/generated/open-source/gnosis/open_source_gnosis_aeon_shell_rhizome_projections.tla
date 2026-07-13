------------------------------ MODULE open_source_gnosis_aeon_shell_rhizome_projections ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"shell_runtime", "project_globe", "project_constellation", "project_mold", "rendered_globe", "rendered_constellation", "rendered_mold", "active_camera", "locus_statement"}
ROOTS == {"shell_runtime", "active_camera"}
TERMINALS == {}
FOLD_TARGETS == {"locus_statement"}
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
  /\ CanFire({"shell_runtime"})
  /\ active' = UpdateActive({"shell_runtime"}, {"project_globe", "project_constellation", "project_mold"})
  /\ beta1' = beta1 + (Cardinality({"project_globe", "project_constellation", "project_mold"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"project_globe", "project_constellation", "project_mold"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"project_globe"})
  /\ active' = UpdateActive({"project_globe"}, {"rendered_globe"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"rendered_globe"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"project_constellation"})
  /\ active' = UpdateActive({"project_constellation"}, {"rendered_constellation"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"rendered_constellation"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"project_mold"})
  /\ active' = UpdateActive({"project_mold"}, {"rendered_mold"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"rendered_mold"} \cap FOLD_TARGETS # {})
Edge_05_RACE ==
  /\ CanFire({"rendered_globe", "active_camera"})
  /\ \E winner \in {"locus_statement"}:
      /\ active' = UpdateActive({"rendered_globe", "active_camera"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"rendered_globe", "active_camera"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_06_RACE ==
  /\ CanFire({"rendered_constellation", "active_camera"})
  /\ \E winner \in {"locus_statement"}:
      /\ active' = UpdateActive({"rendered_constellation", "active_camera"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"rendered_constellation", "active_camera"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_07_RACE ==
  /\ CanFire({"rendered_mold", "active_camera"})
  /\ \E winner \in {"locus_statement"}:
      /\ active' = UpdateActive({"rendered_mold", "active_camera"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"rendered_mold", "active_camera"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_08_FOLD ==
  /\ CanFire({"rendered_globe", "rendered_constellation", "rendered_mold", "locus_statement"})
  /\ active' = UpdateActive({"rendered_globe", "rendered_constellation", "rendered_mold", "locus_statement"}, {"locus_statement"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"locus_statement"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_RACE
  \/ Edge_06_RACE
  \/ Edge_07_RACE
  \/ Edge_08_FOLD

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
