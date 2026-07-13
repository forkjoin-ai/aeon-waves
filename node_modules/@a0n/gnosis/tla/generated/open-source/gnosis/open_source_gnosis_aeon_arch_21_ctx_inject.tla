------------------------------ MODULE open_source_gnosis_aeon_arch_21_ctx_inject ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"prompt", "enriched_prompt", "prompt: Text", "fetch_history: RAG", "fetch_profile: DB", "fetch_history", "fetch_profile", "enriched_prompt: Text"}
ROOTS == {"prompt: Text", "fetch_history", "fetch_profile"}
TERMINALS == {"fetch_history: RAG", "fetch_profile: DB", "enriched_prompt: Text"}
FOLD_TARGETS == {"enriched_prompt: Text"}
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
  /\ CanFire({"prompt: Text"})
  /\ active' = UpdateActive({"prompt: Text"}, {"fetch_history: RAG", "fetch_profile: DB"})
  /\ beta1' = beta1 + (Cardinality({"fetch_history: RAG", "fetch_profile: DB"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"fetch_history: RAG", "fetch_profile: DB"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"fetch_history", "fetch_profile"})
  /\ active' = UpdateActive({"fetch_history", "fetch_profile"}, {"enriched_prompt: Text"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"enriched_prompt: Text"} \cap FOLD_TARGETS # {})

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
