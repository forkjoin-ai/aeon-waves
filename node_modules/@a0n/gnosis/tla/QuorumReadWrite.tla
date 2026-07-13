------------------------------ MODULE QuorumReadWrite ------------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS ReplicaCount, FailureBudget, MaxVersion, MaxTime

VARIABLES up, storedVersion, ackedVersion, pendingVersion, lastReadVersion, lastOp, failuresRemaining, time

vars == <<up, storedVersion, ackedVersion, pendingVersion, lastReadVersion, lastOp, failuresRemaining, time>>

Replicas == 1..ReplicaCount
Versions == 0..MaxVersion
QuorumSize == ReplicaCount - FailureBudget
Quorums == { q \in SUBSET Replicas : Cardinality(q) = QuorumSize }
LiveCount == Cardinality(up)
LiveAckedReplicas == { r \in up : storedVersion[r] >= ackedVersion }

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
  /\ lastReadVersion = 0
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
  /\ UNCHANGED <<up, storedVersion, ackedVersion, lastReadVersion, failuresRemaining>>

DeliverWrite(r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ pendingVersion > ackedVersion
  /\ storedVersion[r] < pendingVersion
  /\ storedVersion' = [storedVersion EXCEPT ![r] = pendingVersion]
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, ackedVersion, pendingVersion, lastReadVersion, failuresRemaining>>

AckWrite ==
  /\ time < MaxTime
  /\ pendingVersion > ackedVersion
  /\ Cardinality({ r \in up : storedVersion[r] >= pendingVersion }) >= QuorumSize
  /\ ackedVersion' = pendingVersion
  /\ pendingVersion' = 0
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, lastReadVersion, failuresRemaining>>

Crash(r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ failuresRemaining > 0
  /\ up' = up \ {r}
  /\ failuresRemaining' = failuresRemaining - 1
  /\ lastOp' = "crash"
  /\ time' = time + 1
  /\ UNCHANGED <<storedVersion, ackedVersion, pendingVersion, lastReadVersion>>

Recover(r) ==
  /\ time < MaxTime
  /\ r \notin up
  /\ up # {}
  /\ up' = up \cup {r}
  /\ storedVersion' = [storedVersion EXCEPT ![r] = MaxLiveVersion]
  /\ lastOp' = "recover"
  /\ time' = time + 1
  /\ UNCHANGED <<ackedVersion, pendingVersion, lastReadVersion, failuresRemaining>>

Read(q) ==
  /\ time < MaxTime
  /\ q \in Quorums
  /\ q \subseteq up
  /\ lastReadVersion' = ReadValue(q)
  /\ lastOp' = "read"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, ackedVersion, pendingVersion, failuresRemaining>>

Tick ==
  /\ time < MaxTime
  /\ time' = time + 1
  /\ lastOp' = "tick"
  /\ UNCHANGED <<up, storedVersion, ackedVersion, pendingVersion, lastReadVersion, failuresRemaining>>

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
  /\ lastReadVersion \in Versions
  /\ lastOp \in {"init", "write", "read", "crash", "recover", "tick"}
  /\ failuresRemaining \in 0..FailureBudget
  /\ time \in 0..MaxTime

InvQuorumIntersection ==
  \A q1 \in Quorums:
    \A q2 \in Quorums:
      (q1 \subseteq up /\ q2 \subseteq up) => q1 \cap q2 # {}

InvPositiveLive ==
  LiveCount > 0

InvAckedQuorumCoverage ==
  Cardinality({ r \in Replicas : storedVersion[r] >= ackedVersion }) >= QuorumSize

InvLiveAckedCoverage ==
  Cardinality(LiveAckedReplicas) >= LiveCount - FailureBudget

InvReadQuorumHitsAckedReplica ==
  \A q \in Quorums:
    q \subseteq up =>
      (\E r \in q: storedVersion[r] >= ackedVersion)

InvAnyReadReturnsAckedOrNewer ==
  \A q \in Quorums:
    q \subseteq up =>
      ReadValue(q) >= ackedVersion

InvObservedReadVisible ==
  lastOp = "read" => lastReadVersion >= ackedVersion

=============================================================================
