------------------------------ MODULE open_source_gnosis_esi_resolution ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"req", "page", "req: Request", "frag_header: Fragment", "frag_body: Fragment", "frag_header", "frag_body", "page: RenderedPage"}
ROOTS == {"req: Request", "frag_header", "frag_body"}
TERMINALS == {"frag_header: Fragment", "frag_body: Fragment", "page: RenderedPage"}
FOLD_TARGETS == {"page: RenderedPage"}
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
  /\ CanFire({"req: Request"})
  /\ active' = UpdateActive({"req: Request"}, {"frag_header: Fragment", "frag_body: Fragment"})
  /\ beta1' = beta1 + (Cardinality({"frag_header: Fragment", "frag_body: Fragment"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"frag_header: Fragment", "frag_body: Fragment"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"frag_header", "frag_body"})
  /\ active' = UpdateActive({"frag_header", "frag_body"}, {"page: RenderedPage"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"page: RenderedPage"} \cap FOLD_TARGETS # {})

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
