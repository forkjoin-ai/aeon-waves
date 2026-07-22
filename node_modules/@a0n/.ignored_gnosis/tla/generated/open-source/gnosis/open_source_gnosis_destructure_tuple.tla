------------------------------ MODULE open_source_gnosis_destructure_tuple ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"seed", "extract", "sink", "seed:Source", "extract:Destructure { items: \"0.id:firstId,2.id:thirdId\" }", "sink:Sink"}
ROOTS == {"seed:Source", "extract"}
TERMINALS == {"extract:Destructure { items: \"0.id:firstId,2.id:thirdId\" }", "sink:Sink"}
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
  /\ CanFire({"seed:Source"})
  /\ active' = UpdateActive({"seed:Source"}, {"extract:Destructure { items: \"0.id:firstId,2.id:thirdId\" }"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"extract:Destructure { items: \"0.id:firstId,2.id:thirdId\" }"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"extract"})
  /\ active' = UpdateActive({"extract"}, {"sink:Sink"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sink:Sink"} \cap FOLD_TARGETS # {})

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
