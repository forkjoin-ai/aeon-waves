------------------------------ MODULE open_source_gnosis_aeon_flow_esi ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"page_request", "renderer", "frag_header", "frag_body", "cache", "origin", "resolved_header", "resolved_body", "html_page"}
ROOTS == {"page_request", "cache", "origin"}
TERMINALS == {"html_page"}
FOLD_TARGETS == {"html_page"}
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
  /\ CanFire({"page_request"})
  /\ active' = UpdateActive({"page_request"}, {"renderer"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"renderer"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"renderer"})
  /\ active' = UpdateActive({"renderer"}, {"frag_header", "frag_body"})
  /\ beta1' = beta1 + (Cardinality({"frag_header", "frag_body"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"frag_header", "frag_body"} \cap FOLD_TARGETS # {})
Edge_03_RACE ==
  /\ CanFire({"frag_header", "cache"})
  /\ \E winner \in {"resolved_header"}:
      /\ active' = UpdateActive({"frag_header", "cache"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"frag_header", "cache"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_04_RACE ==
  /\ CanFire({"frag_body", "origin"})
  /\ \E winner \in {"resolved_body"}:
      /\ active' = UpdateActive({"frag_body", "origin"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"frag_body", "origin"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_05_FOLD ==
  /\ CanFire({"resolved_header", "resolved_body"})
  /\ active' = UpdateActive({"resolved_header", "resolved_body"}, {"html_page"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"html_page"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_RACE
  \/ Edge_04_RACE
  \/ Edge_05_FOLD

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
