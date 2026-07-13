------------------------------ MODULE open_source_gnosis_aeon_arch_08_tui_layout ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"resize", "screen", "resize: Event", "calc_sidebar: Layout", "calc_main: Layout", "calc_sidebar", "calc_main", "screen: View"}
ROOTS == {"resize: Event", "calc_sidebar", "calc_main"}
TERMINALS == {"calc_sidebar: Layout", "calc_main: Layout", "screen: View"}
FOLD_TARGETS == {"screen: View"}
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
  /\ CanFire({"resize: Event"})
  /\ active' = UpdateActive({"resize: Event"}, {"calc_sidebar: Layout", "calc_main: Layout"})
  /\ beta1' = beta1 + (Cardinality({"calc_sidebar: Layout", "calc_main: Layout"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"calc_sidebar: Layout", "calc_main: Layout"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"calc_sidebar", "calc_main"})
  /\ active' = UpdateActive({"calc_sidebar", "calc_main"}, {"screen: View"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"screen: View"} \cap FOLD_TARGETS # {})

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
