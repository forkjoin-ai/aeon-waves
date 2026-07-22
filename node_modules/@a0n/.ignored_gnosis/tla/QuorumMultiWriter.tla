---------------------------- MODULE QuorumMultiWriter ----------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS ReplicaCount, WriterCount, FailureBudget, MaxBallot, MaxTime

VARIABLES up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, lastOp, failuresRemaining, time

vars == <<up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, lastOp, failuresRemaining, time>>

Replicas == 1..ReplicaCount
Writers == 1..WriterCount
WriterIds == 0..WriterCount
Ballots == 0..MaxBallot
QuorumSize == ReplicaCount - FailureBudget
Quorums == { q \in SUBSET Replicas : Cardinality(q) = QuorumSize }
NoPending == \A w \in Writers: pendingBallot[w] = 0
BallotSet(q) == { storedBallot[r] : r \in q }
MaxBallotInSet(S) == CHOOSE b \in S: \A c \in S: b >= c
ReadBallot(q) == MaxBallotInSet(BallotSet(q))
MaxLiveBallot == MaxBallotInSet(BallotSet(up))
PendingBallotSet == { pendingBallot[w] : w \in Writers }
MaxPendingBallot == MaxBallotInSet(PendingBallotSet)
LatestAckedReplicas == { r \in Replicas : storedBallot[r] >= ackedBallot }

Init ==
  /\ ReplicaCount > 0
  /\ WriterCount > 0
  /\ FailureBudget < ReplicaCount
  /\ 2 * QuorumSize > ReplicaCount
  /\ QuorumSize > 0
  /\ MaxBallot > 0
  /\ MaxTime > 0
  /\ up = Replicas
  /\ storedBallot = [r \in Replicas |-> 0]
  /\ pendingBallot = [w \in Writers |-> 0]
  /\ ballotWriter = [b \in Ballots |-> 0]
  /\ ackedBallot = 0
  /\ ackedWriter = 0
  /\ nextBallot = 1
  /\ sessionReadBallot = 0
  /\ sessionReadWriter = 0
  /\ priorSessionReadBallot = 0
  /\ lastOp = "init"
  /\ failuresRemaining = FailureBudget
  /\ time = 0

StartWrite(w) ==
  /\ time < MaxTime
  /\ pendingBallot[w] = 0
  /\ nextBallot <= MaxBallot
  /\ pendingBallot' = [pendingBallot EXCEPT ![w] = nextBallot]
  /\ ballotWriter' = [ballotWriter EXCEPT ![nextBallot] = w]
  /\ nextBallot' = nextBallot + 1
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedBallot, ackedBallot, ackedWriter, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, failuresRemaining>>

DeliverWrite(w, r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ pendingBallot[w] > 0
  /\ storedBallot[r] < pendingBallot[w]
  /\ storedBallot' = [storedBallot EXCEPT ![r] = pendingBallot[w]]
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, failuresRemaining>>

AckWrite(w) ==
  /\ time < MaxTime
  /\ pendingBallot[w] > ackedBallot
  /\ pendingBallot[w] = MaxPendingBallot
  /\ Cardinality({ r \in up : storedBallot[r] >= pendingBallot[w] }) >= QuorumSize
  /\ ackedBallot' = pendingBallot[w]
  /\ ackedWriter' = ballotWriter[pendingBallot[w]]
  /\ pendingBallot' = [v \in Writers |-> IF pendingBallot[v] <= pendingBallot[w] THEN 0 ELSE pendingBallot[v]]
  /\ lastOp' = "ack"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedBallot, ballotWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, failuresRemaining>>

Crash(r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ failuresRemaining > 0
  /\ up' = up \ {r}
  /\ failuresRemaining' = failuresRemaining - 1
  /\ lastOp' = "crash"
  /\ time' = time + 1
  /\ UNCHANGED <<storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot>>

Recover(r) ==
  /\ time < MaxTime
  /\ r \notin up
  /\ up # {}
  /\ up' = up \cup {r}
  /\ storedBallot' = [storedBallot EXCEPT ![r] = MaxLiveBallot]
  /\ lastOp' = "recover"
  /\ time' = time + 1
  /\ UNCHANGED <<pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, failuresRemaining>>

Read(q) ==
  /\ time < MaxTime
  /\ NoPending
  /\ q \in Quorums
  /\ q \subseteq up
  /\ priorSessionReadBallot' = sessionReadBallot
  /\ sessionReadBallot' = ReadBallot(q)
  /\ sessionReadWriter' = ballotWriter[ReadBallot(q)]
  /\ lastOp' = "read"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, failuresRemaining>>

Tick ==
  /\ time < MaxTime
  /\ time' = time + 1
  /\ lastOp' = "tick"
  /\ UNCHANGED <<up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, failuresRemaining>>

Stutter == UNCHANGED vars

Next ==
  \/ \E w \in Writers: StartWrite(w)
  \/ \E w \in Writers: \E r \in Replicas: DeliverWrite(w, r)
  \/ \E w \in Writers: AckWrite(w)
  \/ \E r \in Replicas: Crash(r)
  \/ \E r \in Replicas: Recover(r)
  \/ \E q \in Quorums: Read(q)
  \/ Tick
  \/ Stutter

Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ up \subseteq Replicas
  /\ storedBallot \in [Replicas -> Ballots]
  /\ pendingBallot \in [Writers -> Ballots]
  /\ ballotWriter \in [Ballots -> WriterIds]
  /\ ackedBallot \in Ballots
  /\ ackedWriter \in WriterIds
  /\ nextBallot \in 1..(MaxBallot + 1)
  /\ sessionReadBallot \in Ballots
  /\ sessionReadWriter \in WriterIds
  /\ priorSessionReadBallot \in Ballots
  /\ lastOp \in {"init", "write", "ack", "read", "crash", "recover", "tick"}
  /\ failuresRemaining \in 0..FailureBudget
  /\ time \in 0..MaxTime

InvAckedWriterMatchesBallotOwner ==
  ackedWriter = ballotWriter[ackedBallot]

InvAckedBallotBelowNext ==
  ackedBallot < nextBallot

InvPendingBallotsBelowNext ==
  \A w \in Writers: pendingBallot[w] < nextBallot

InvLatestAckCovered ==
  Cardinality(LatestAckedReplicas) >= QuorumSize

InvNoCommittedReplicaAhead ==
  NoPending => \A r \in Replicas: storedBallot[r] <= ackedBallot

InvCommittedReadsReturnLatestAck ==
  \A q \in Quorums:
    /\ q \subseteq up
    /\ NoPending
    => ReadBallot(q) = ackedBallot

InvObservedCommittedReadExact ==
  lastOp = "read" => sessionReadBallot = ackedBallot

InvObservedCommittedReadWriter ==
  lastOp = "read" => sessionReadWriter = ackedWriter

InvObservedCommittedReadsMonotone ==
  lastOp = "read" => sessionReadBallot >= priorSessionReadBallot

=============================================================================
