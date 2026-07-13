------------------------------ MODULE open_source_gnosis_aeon_arch_31_memento_chain ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"memory", "hash", "merkle_tree", "chain_anchor", "memory: Fact", "hash: Crypto", "merkle_tree: Data", "chain_anchor: Ledger"}
ROOTS == {"memory: Fact"}
TERMINALS == {"chain_anchor: Ledger"}
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
  /\ CanFire({"memory: Fact"})
  /\ active' = UpdateActive({"memory: Fact"}, {"hash: Crypto"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"hash: Crypto"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"hash: Crypto"})
  /\ active' = UpdateActive({"hash: Crypto"}, {"merkle_tree: Data"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"merkle_tree: Data"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"merkle_tree: Data"})
  /\ active' = UpdateActive({"merkle_tree: Data"}, {"chain_anchor: Ledger"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"chain_anchor: Ledger"} \cap FOLD_TARGETS # {})

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
