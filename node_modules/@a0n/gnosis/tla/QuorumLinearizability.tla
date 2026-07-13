-------------------------- MODULE QuorumLinearizability --------------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS ReplicaCount, WriterCount, FailureBudget, MaxBallot, MaxTime

VARIABLES up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory, lastOp, failuresRemaining, time

vars == <<up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory, lastOp, failuresRemaining, time>>

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

WriteRecordSpace == { [ballot |-> b, writer |-> w] : b \in Ballots, w \in WriterIds }
OpRecordSpace ==
  { [kind |-> k, ballot |-> b, writer |-> w, writeIndex |-> i] :
      k \in {"write", "read"},
      b \in Ballots,
      w \in WriterIds,
      i \in 0..MaxBallot }

SpecWrite(i) ==
  IF i = 0
    THEN [ballot |-> 0, writer |-> 0]
    ELSE writeHistory[i]

LatestCompletedWrite == SpecWrite(Len(writeHistory))

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
  /\ writeHistory = <<>>
  /\ opHistory = <<>>
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
  /\ UNCHANGED <<up, storedBallot, ackedBallot, ackedWriter, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory, failuresRemaining>>

DeliverWrite(w, r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ pendingBallot[w] > 0
  /\ storedBallot[r] < pendingBallot[w]
  /\ storedBallot' = [storedBallot EXCEPT ![r] = pendingBallot[w]]
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory, failuresRemaining>>

AckWrite(w) ==
  /\ time < MaxTime
  /\ pendingBallot[w] > ackedBallot
  /\ pendingBallot[w] = MaxBallotInSet({ pendingBallot[v] : v \in Writers })
  /\ Cardinality({ r \in up : storedBallot[r] >= pendingBallot[w] }) >= QuorumSize
  /\ LET newWrite == [ballot |-> pendingBallot[w], writer |-> ballotWriter[pendingBallot[w]]]
     IN /\ ackedBallot' = newWrite.ballot
        /\ ackedWriter' = newWrite.writer
        /\ writeHistory' = Append(writeHistory, newWrite)
        /\ opHistory' = Append(
             opHistory,
             [kind |-> "write", ballot |-> newWrite.ballot, writer |-> newWrite.writer, writeIndex |-> Len(writeHistory) + 1]
           )
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
  /\ UNCHANGED <<storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory>>

Recover(r) ==
  /\ time < MaxTime
  /\ r \notin up
  /\ up # {}
  /\ up' = up \cup {r}
  /\ storedBallot' = [storedBallot EXCEPT ![r] = MaxLiveBallot]
  /\ lastOp' = "recover"
  /\ time' = time + 1
  /\ UNCHANGED <<pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory, failuresRemaining>>

Read(q) ==
  /\ time < MaxTime
  /\ NoPending
  /\ q \in Quorums
  /\ q \subseteq up
  /\ LET readBallot == ReadBallot(q)
         readWriter == ballotWriter[readBallot]
     IN /\ priorSessionReadBallot' = sessionReadBallot
        /\ sessionReadBallot' = readBallot
        /\ sessionReadWriter' = readWriter
        /\ opHistory' = Append(
             opHistory,
             [kind |-> "read", ballot |-> readBallot, writer |-> readWriter, writeIndex |-> Len(writeHistory)]
           )
  /\ lastOp' = "read"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, writeHistory, failuresRemaining>>

Tick ==
  /\ time < MaxTime
  /\ time' = time + 1
  /\ lastOp' = "tick"
  /\ UNCHANGED <<up, storedBallot, pendingBallot, ballotWriter, ackedBallot, ackedWriter, nextBallot, sessionReadBallot, sessionReadWriter, priorSessionReadBallot, writeHistory, opHistory, failuresRemaining>>

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
  /\ writeHistory \in Seq(WriteRecordSpace)
  /\ opHistory \in Seq(OpRecordSpace)
  /\ Len(writeHistory) <= MaxBallot
  /\ lastOp \in {"init", "write", "ack", "read", "crash", "recover", "tick"}
  /\ failuresRemaining \in 0..FailureBudget
  /\ time \in 0..MaxTime

InvLatestHistoryTracksAck ==
  /\ LatestCompletedWrite.ballot = ackedBallot
  /\ LatestCompletedWrite.writer = ackedWriter

InvWriteOpsMatchHistory ==
  \A i \in 1..Len(opHistory):
    opHistory[i].kind = "write" =>
      /\ opHistory[i].writeIndex \in 1..Len(writeHistory)
      /\ opHistory[i].ballot = writeHistory[opHistory[i].writeIndex].ballot
      /\ opHistory[i].writer = writeHistory[opHistory[i].writeIndex].writer

InvReadOpsRefineRegister ==
  \A i \in 1..Len(opHistory):
    opHistory[i].kind = "read" =>
      /\ opHistory[i].writeIndex \in 0..Len(writeHistory)
      /\ opHistory[i].ballot = SpecWrite(opHistory[i].writeIndex).ballot
      /\ opHistory[i].writer = SpecWrite(opHistory[i].writeIndex).writer

InvOpHistoryIndicesMonotone ==
  \A i, j \in 1..Len(opHistory):
    i < j => opHistory[i].writeIndex <= opHistory[j].writeIndex

InvObservedReadLinearizesToLatestCompletedWrite ==
  lastOp = "read" =>
    /\ sessionReadBallot = LatestCompletedWrite.ballot
    /\ sessionReadWriter = LatestCompletedWrite.writer

=============================================================================
