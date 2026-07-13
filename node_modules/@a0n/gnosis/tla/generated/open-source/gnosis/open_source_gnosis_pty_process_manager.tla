------------------------------ MODULE open_source_gnosis_pty_process_manager ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"spawn_cmd", "terminal", "spawn_cmd: Command", "pty_stdout: Stream", "pty_stderr: Stream", "pty_stdout", "pty_stderr", "terminal: TTY"}
ROOTS == {"spawn_cmd: Command", "pty_stdout", "pty_stderr"}
TERMINALS == {"pty_stdout: Stream", "pty_stderr: Stream", "terminal: TTY"}
FOLD_TARGETS == {"terminal: TTY"}
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
  /\ CanFire({"spawn_cmd: Command"})
  /\ active' = UpdateActive({"spawn_cmd: Command"}, {"pty_stdout: Stream", "pty_stderr: Stream"})
  /\ beta1' = beta1 + (Cardinality({"pty_stdout: Stream", "pty_stderr: Stream"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"pty_stdout: Stream", "pty_stderr: Stream"} \cap FOLD_TARGETS # {})
Edge_02_FOLD ==
  /\ CanFire({"pty_stdout", "pty_stderr"})
  /\ active' = UpdateActive({"pty_stdout", "pty_stderr"}, {"terminal: TTY"})
  /\ beta1' = 0
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"terminal: TTY"} \cap FOLD_TARGETS # {})

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
