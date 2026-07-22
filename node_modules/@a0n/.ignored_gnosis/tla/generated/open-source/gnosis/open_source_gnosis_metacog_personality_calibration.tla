------------------------------ MODULE open_source_gnosis_metacog_personality_calibration ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"base_traits", "c1_confidence", "c2_coherence", "c3_bias_check", "base_traits: Profile", "c1_confidence: Logic", "c2_coherence: Logic", "c3_bias_check: Logic"}
ROOTS == {"base_traits: Profile"}
TERMINALS == {"c3_bias_check: Logic"}
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
  /\ CanFire({"base_traits: Profile"})
  /\ active' = UpdateActive({"base_traits: Profile"}, {"c1_confidence: Logic"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"c1_confidence: Logic"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"c1_confidence: Logic"})
  /\ active' = UpdateActive({"c1_confidence: Logic"}, {"c2_coherence: Logic"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"c2_coherence: Logic"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"c2_coherence: Logic"})
  /\ active' = UpdateActive({"c2_coherence: Logic"}, {"c3_bias_check: Logic"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"c3_bias_check: Logic"} \cap FOLD_TARGETS # {})

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
