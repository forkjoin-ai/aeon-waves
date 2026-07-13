------------------------------ MODULE open_source_gnosis_examples_synth_effects ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"fx_input", "dry_mix", "dry", "delay", "reverb", "chorus", "fx_out"}
ROOTS == {"fx_input"}
TERMINALS == {"fx_out"}
FOLD_TARGETS == {"fx_out"}
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
  /\ CanFire({"fx_input"})
  /\ active' = UpdateActive({"fx_input"}, {"dry", "delay", "reverb", "chorus"})
  /\ beta1' = beta1 + (Cardinality({"dry", "delay", "reverb", "chorus"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"dry", "delay", "reverb", "chorus"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"dry", "delay", "reverb", "chorus"})
  /\ active' = UpdateActive({"dry", "delay", "reverb", "chorus"}, {"fx_out"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fx_out"} \cap FOLD_TARGETS # {})

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
