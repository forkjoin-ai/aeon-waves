------------------------------ MODULE open_source_gnosis_aeon_arch_16_store_provision ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"install", "ready", "install: Cmd", "fetch_wasm: Net", "alloc_storage: Disk", "fetch_wasm", "alloc_storage", "ready: Agent"}
ROOTS == {"install: Cmd", "fetch_wasm", "alloc_storage"}
TERMINALS == {"fetch_wasm: Net", "alloc_storage: Disk", "ready: Agent"}
FOLD_TARGETS == {"ready: Agent"}
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
  /\ CanFire({"install: Cmd"})
  /\ active' = UpdateActive({"install: Cmd"}, {"fetch_wasm: Net", "alloc_storage: Disk"})
  /\ beta1' = beta1 + (Cardinality({"fetch_wasm: Net", "alloc_storage: Disk"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fetch_wasm: Net", "alloc_storage: Disk"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"fetch_wasm", "alloc_storage"})
  /\ active' = UpdateActive({"fetch_wasm", "alloc_storage"}, {"ready: Agent"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"ready: Agent"} \cap FOLD_TARGETS # {})

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
