------------------------------ MODULE open_source_gnosis_warmup_mixed_cold_calling ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"call_session", "script", "rapport_building", "rejection_feedback", "pitch_adapter", "tailored_pitch", "conversation", "outcome"}
ROOTS == {"call_session"}
TERMINALS == {"outcome"}
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

Edge_01_FORK ==
  /\ CanFire({"call_session"})
  /\ active' = UpdateActive({"call_session"}, {"script", "rapport_building", "rejection_feedback"})
  /\ beta1' = beta1 + (Cardinality({"script", "rapport_building", "rejection_feedback"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"script", "rapport_building", "rejection_feedback"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"rejection_feedback"})
  /\ active' = UpdateActive({"rejection_feedback"}, {"pitch_adapter"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"pitch_adapter"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"pitch_adapter"})
  /\ active' = UpdateActive({"pitch_adapter"}, {"tailored_pitch"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"tailored_pitch"} \cap FOLD_TARGETS # {})
Edge_04_RACE ==
  /\ CanFire({"script", "tailored_pitch"})
  /\ \E winner \in {"conversation"}:
      /\ active' = UpdateActive({"script", "tailored_pitch"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"script", "tailored_pitch"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)
Edge_05_INTERFERE ==
  /\ CanFire({"conversation", "rapport_building"})
  /\ active' = UpdateActive({"conversation", "rapport_building"}, {"outcome"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"outcome"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_RACE
  \/ Edge_05_INTERFERE

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
