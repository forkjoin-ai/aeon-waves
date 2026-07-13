------------------------------ MODULE open_source_gnosis_aeon_arch_18_webgpu_infer ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"tensor", "shader_prep", "gpu_exec", "logits", "tensor: Data", "shader_prep: Compiler", "gpu_exec: Compute", "logits: Output"}
ROOTS == {"tensor: Data"}
TERMINALS == {"logits: Output"}
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
  /\ CanFire({"tensor: Data"})
  /\ active' = UpdateActive({"tensor: Data"}, {"shader_prep: Compiler"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"shader_prep: Compiler"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"shader_prep: Compiler"})
  /\ active' = UpdateActive({"shader_prep: Compiler"}, {"gpu_exec: Compute"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"gpu_exec: Compute"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"gpu_exec: Compute"})
  /\ active' = UpdateActive({"gpu_exec: Compute"}, {"logits: Output"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"logits: Output"} \cap FOLD_TARGETS # {})

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
