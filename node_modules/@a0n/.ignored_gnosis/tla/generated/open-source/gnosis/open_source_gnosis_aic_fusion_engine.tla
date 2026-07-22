------------------------------ MODULE open_source_gnosis_aic_fusion_engine ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"fused_state", "text_cvm: Vector", "audio_cvm: Vector", "visual_cvm: Vector", "fused_state: State"}
ROOTS == {"text_cvm: Vector", "audio_cvm: Vector", "visual_cvm: Vector"}
TERMINALS == {"fused_state: State"}
FOLD_TARGETS == {"fused_state: State"}
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

Edge_01_FOLD ==
  /\ CanFire({"text_cvm: Vector", "audio_cvm: Vector", "visual_cvm: Vector"})
  /\ active' = UpdateActive({"text_cvm: Vector", "audio_cvm: Vector", "visual_cvm: Vector"}, {"fused_state: State"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fused_state: State"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FOLD

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
