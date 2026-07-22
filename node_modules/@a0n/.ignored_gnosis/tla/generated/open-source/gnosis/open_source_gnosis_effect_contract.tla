------------------------------ MODULE open_source_gnosis_effect_contract ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"reader", "sync"}
ROOTS == {"reader"}
TERMINALS == {"sync"}
FOLD_TARGETS == {}
EFFECTS == {"auth.zk", "fs.local"}
DECLARED_EFFECTS == {"auth.zk", "fs.local"}
INFERRED_EFFECTS == {"auth.zk", "fs.local"}
\* EFFECT_NODE reader declared={"fs.local"} inferred={"fs.local"}
\* EFFECT_NODE sync declared={"auth.zk"} inferred={"auth.zk"}

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
  /\ CanFire({"reader"})
  /\ active' = UpdateActive({"reader"}, {"sync"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"sync"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS

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
