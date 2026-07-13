--------------------------- MODULE QuorumSessionConsistency ---------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS ReplicaCount, FailureBudget, MaxVersion, MaxTime

VARIABLES up, storedVersion, ackedVersion, pendingVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion, lastOp, failuresRemaining, time

vars == <<up, storedVersion, ackedVersion, pendingVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion, lastOp, failuresRemaining, time>>

Replicas == 1..ReplicaCount
Versions == 0..MaxVersion
QuorumSize == ReplicaCount - FailureBudget
Quorums == { q \in SUBSET Replicas : Cardinality(q) = QuorumSize }

VersionSet(q) == { storedVersion[r] : r \in q }
MaxVersionInSet(S) == CHOOSE v \in S: \A w \in S: v >= w
ReadValue(q) == MaxVersionInSet(VersionSet(q))
MaxLiveVersion == MaxVersionInSet(VersionSet(up))

Init ==
  /\ ReplicaCount > 0
  /\ FailureBudget < ReplicaCount
  /\ 2 * QuorumSize > ReplicaCount
  /\ QuorumSize > 0
  /\ MaxVersion > 0
  /\ MaxTime > 0
  /\ up = Replicas
  /\ storedVersion = [r \in Replicas |-> 0]
  /\ ackedVersion = 0
  /\ pendingVersion = 0
  /\ sessionWriteVersion = 0
  /\ sessionReadVersion = 0
  /\ priorSessionReadVersion = 0
  /\ lastOp = "init"
  /\ failuresRemaining = FailureBudget
  /\ time = 0

StartWrite ==
  /\ time < MaxTime
  /\ pendingVersion = 0
  /\ ackedVersion < MaxVersion
  /\ pendingVersion' = ackedVersion + 1
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, ackedVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion, failuresRemaining>>

DeliverWrite(r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ pendingVersion > ackedVersion
  /\ storedVersion[r] < pendingVersion
  /\ storedVersion' = [storedVersion EXCEPT ![r] = pendingVersion]
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, ackedVersion, pendingVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion, failuresRemaining>>

AckWrite ==
  /\ time < MaxTime
  /\ pendingVersion > ackedVersion
  /\ Cardinality({ r \in up : storedVersion[r] >= pendingVersion }) >= QuorumSize
  /\ ackedVersion' = pendingVersion
  /\ pendingVersion' = 0
  /\ sessionWriteVersion' = ackedVersion'
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, sessionReadVersion, priorSessionReadVersion, failuresRemaining>>

Crash(r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ failuresRemaining > 0
  /\ up' = up \ {r}
  /\ failuresRemaining' = failuresRemaining - 1
  /\ lastOp' = "crash"
  /\ time' = time + 1
  /\ UNCHANGED <<storedVersion, ackedVersion, pendingVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion>>

Recover(r) ==
  /\ time < MaxTime
  /\ r \notin up
  /\ up # {}
  /\ up' = up \cup {r}
  /\ storedVersion' = [storedVersion EXCEPT ![r] = MaxLiveVersion]
  /\ lastOp' = "recover"
  /\ time' = time + 1
  /\ UNCHANGED <<ackedVersion, pendingVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion, failuresRemaining>>

Read(q) ==
  /\ time < MaxTime
  /\ pendingVersion = 0
  /\ q \in Quorums
  /\ q \subseteq up
  /\ priorSessionReadVersion' = sessionReadVersion
  /\ sessionReadVersion' = ReadValue(q)
  /\ lastOp' = "read"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, ackedVersion, pendingVersion, sessionWriteVersion, failuresRemaining>>

Tick ==
  /\ time < MaxTime
  /\ time' = time + 1
  /\ lastOp' = "tick"
  /\ UNCHANGED <<up, storedVersion, ackedVersion, pendingVersion, sessionWriteVersion, sessionReadVersion, priorSessionReadVersion, failuresRemaining>>

Stutter == UNCHANGED vars

Next ==
  \/ StartWrite
  \/ \E r \in Replicas: DeliverWrite(r)
  \/ AckWrite
  \/ \E r \in Replicas: Crash(r)
  \/ \E r \in Replicas: Recover(r)
  \/ \E q \in Quorums: Read(q)
  \/ Tick
  \/ Stutter

Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ up \subseteq Replicas
  /\ storedVersion \in [Replicas -> Versions]
  /\ ackedVersion \in Versions
  /\ pendingVersion \in Versions
  /\ sessionWriteVersion \in Versions
  /\ sessionReadVersion \in Versions
  /\ priorSessionReadVersion \in Versions
  /\ lastOp \in {"init", "write", "read", "crash", "recover", "tick"}
  /\ failuresRemaining \in 0..FailureBudget
  /\ time \in 0..MaxTime

InvClientWriteTracksAck ==
  sessionWriteVersion = ackedVersion

InvNoPendingMeansNoReplicaAhead ==
  pendingVersion = 0 => \A r \in Replicas: storedVersion[r] <= ackedVersion

InvCommittedReadReturnsAck ==
  \A q \in Quorums:
    /\ q \subseteq up
    /\ pendingVersion = 0
    => ReadValue(q) = ackedVersion

InvReadYourWrites ==
  lastOp = "read" => sessionReadVersion >= sessionWriteVersion

InvMonotonicReads ==
  lastOp = "read" => sessionReadVersion >= priorSessionReadVersion

InvObservedCommittedReadExact ==
  lastOp = "read" => sessionReadVersion = ackedVersion

=============================================================================
