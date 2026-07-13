------------------------------ MODULE open_source_gnosis_aeon_arch_02_ucan_auth ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"token", "verify_sig", "check_caps", "auth_ok", "token: Token", "verify_sig: Check", "check_caps: Check", "auth_ok: Result"}
ROOTS == {"token: Token"}
TERMINALS == {"auth_ok: Result"}
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
  /\ CanFire({"token: Token"})
  /\ active' = UpdateActive({"token: Token"}, {"verify_sig: Check"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verify_sig: Check"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"verify_sig: Check"})
  /\ active' = UpdateActive({"verify_sig: Check"}, {"check_caps: Check"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"check_caps: Check"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"check_caps: Check"})
  /\ active' = UpdateActive({"check_caps: Check"}, {"auth_ok: Result"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"auth_ok: Result"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS

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
