------------------------------ MODULE open_source_gnosis_aeon_arch_04_cache_fallback ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"req", "res", "req: Request", "edge_cache: Cache", "origin: Server", "edge_cache", "origin", "res: Response"}
ROOTS == {"req: Request", "edge_cache", "origin"}
TERMINALS == {"edge_cache: Cache", "origin: Server", "res: Response"}
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
  /\ CanFire({"req: Request"})
  /\ active' = UpdateActive({"req: Request"}, {"edge_cache: Cache", "origin: Server"})
  /\ beta1' = beta1 + (Cardinality({"edge_cache: Cache", "origin: Server"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"edge_cache: Cache", "origin: Server"} \cap FOLD_TARGETS # {})
Edge_02_RACE ==
  /\ CanFire({"edge_cache", "origin"})
  /\ \E winner \in {"res: Response"}:
      /\ active' = UpdateActive({"edge_cache", "origin"}, {winner})
      /\ beta1' = Max2(0, beta1 - (Cardinality({"edge_cache", "origin"}) - 1))
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
