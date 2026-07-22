------------------------------ MODULE open_source_gnosis_publisher_content_syndication ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"post", "publish_receipt", "post: Article", "twitter: API", "linkedin: API", "blog: DB", "twitter", "linkedin", "blog", "publish_receipt: Status"}
ROOTS == {"post: Article", "twitter", "linkedin", "blog"}
TERMINALS == {"twitter: API", "linkedin: API", "blog: DB", "publish_receipt: Status"}
FOLD_TARGETS == {"publish_receipt: Status"}
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
  /\ CanFire({"post: Article"})
  /\ active' = UpdateActive({"post: Article"}, {"twitter: API", "linkedin: API", "blog: DB"})
  /\ beta1' = beta1 + (Cardinality({"twitter: API", "linkedin: API", "blog: DB"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"twitter: API", "linkedin: API", "blog: DB"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"twitter", "linkedin", "blog"})
  /\ active' = UpdateActive({"twitter", "linkedin", "blog"}, {"publish_receipt: Status"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"publish_receipt: Status"} \cap FOLD_TARGETS # {})

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
