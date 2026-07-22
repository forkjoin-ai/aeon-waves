------------------------------ MODULE open_source_gnosis_aeon_flow_speculative_decode ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"context", "draft_model", "branch_1", "branch_2", "branch_3", "full_model", "verified_tokens"}
ROOTS == {"context"}
TERMINALS == {"full_model", "verified_tokens"}
FOLD_TARGETS == {"verified_tokens"}
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
  /\ CanFire({"context"})
  /\ active' = UpdateActive({"context"}, {"draft_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"draft_model"} \cap FOLD_TARGETS # {})
Edge_02_FORK ==
  /\ CanFire({"draft_model"})
  /\ active' = UpdateActive({"draft_model"}, {"branch_1", "branch_2", "branch_3"})
  /\ beta1' = beta1 + (Cardinality({"branch_1", "branch_2", "branch_3"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"branch_1", "branch_2", "branch_3"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"branch_1"})
  /\ active' = UpdateActive({"branch_1"}, {"full_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"full_model"} \cap FOLD_TARGETS # {})
Edge_04_PROCESS ==
  /\ CanFire({"branch_2"})
  /\ active' = UpdateActive({"branch_2"}, {"full_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"full_model"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"branch_3"})
  /\ active' = UpdateActive({"branch_3"}, {"full_model"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"full_model"} \cap FOLD_TARGETS # {})
Edge_06_FOLD ==
  /\ CanFire({"branch_1", "branch_2", "branch_3"})
  /\ active' = UpdateActive({"branch_1", "branch_2", "branch_3"}, {"verified_tokens"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"verified_tokens"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_PROCESS
  \/ Edge_02_FORK
  \/ Edge_03_PROCESS
  \/ Edge_04_PROCESS
  \/ Edge_05_PROCESS
  \/ Edge_06_FOLD

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
