------------------------------ MODULE open_source_gnosis_aeon_arch_05_llm_mesh ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"prompt", "stream", "prompt: Prompt", "node_a: GPU", "node_b: GPU", "node_c: GPU", "node_a", "node_b", "node_c", "stream: Output"}
ROOTS == {"prompt: Prompt", "node_a", "node_b", "node_c"}
TERMINALS == {"node_a: GPU", "node_b: GPU", "node_c: GPU", "stream: Output"}
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
  /\ CanFire({"prompt: Prompt"})
  /\ active' = UpdateActive({"prompt: Prompt"}, {"node_a: GPU", "node_b: GPU", "node_c: GPU"})
  /\ beta1' = beta1 + (Cardinality({"node_a: GPU", "node_b: GPU", "node_c: GPU"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"node_a: GPU", "node_b: GPU", "node_c: GPU"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"node_a", "node_b", "node_c"})
  /\ \E winner \in {"stream: Output"}:
      /\ active' = UpdateActive({"node_a", "node_b", "node_c"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"node_a", "node_b", "node_c"}) - 1))
      /\ payloadPresent' = payloadPresent
      /\ consensusReached' = consensusReached \/ (winner \in FOLD_TARGETS)

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_RACE

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
