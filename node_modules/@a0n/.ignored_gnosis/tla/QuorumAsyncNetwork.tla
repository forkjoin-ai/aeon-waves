--------------------------- MODULE QuorumAsyncNetwork ----------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS ReplicaCount, FailureBudget, MaxVersion, MaxTime

VARIABLES up, connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion, lastOp, failuresRemaining, time

vars == <<up, connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion, lastOp, failuresRemaining, time>>

Replicas == 1..ReplicaCount
Versions == 0..MaxVersion
QuorumSize == ReplicaCount - FailureBudget
Quorums == { q \in SUBSET Replicas : Cardinality(q) = QuorumSize }
MessageSpace == Versions \X Replicas
LiveConnected == up \cap connected
VersionSet(S) == { storedVersion[r] : r \in S }
MaxVersionInSet(S) == CHOOSE v \in S: \A w \in S: v >= w
ReadValue(q) == MaxVersionInSet(VersionSet(q))
MaxConnectedVersion == MaxVersionInSet(VersionSet(connected))
HasConnectedQuorum == \E q \in Quorums: q \subseteq LiveConnected

Init ==
  /\ ReplicaCount > 0
  /\ FailureBudget < ReplicaCount
  /\ 2 * QuorumSize > ReplicaCount
  /\ QuorumSize > 0
  /\ MaxVersion > 0
  /\ MaxTime > 0
  /\ up = Replicas
  /\ connected = Replicas
  /\ storedVersion = [r \in Replicas |-> 0]
  /\ ackedVersion = 0
  /\ pendingVersion = 0
  /\ writeMsgs = {}
  /\ repairMsgs = {}
  /\ lastReadVersion = 0
  /\ lastOp = "init"
  /\ failuresRemaining = FailureBudget
  /\ time = 0

StartWrite ==
  /\ time < MaxTime
  /\ pendingVersion = 0
  /\ ackedVersion < MaxVersion
  /\ LET newVersion == ackedVersion + 1
     IN /\ pendingVersion' = newVersion
        /\ writeMsgs' = { <<newVersion, r>> : r \in Replicas }
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, storedVersion, ackedVersion, repairMsgs, lastReadVersion, failuresRemaining>>

DeliverWrite(m) ==
  /\ time < MaxTime
  /\ m \in writeMsgs
  /\ LET version == m[1]
         replica == m[2]
     IN /\ version = pendingVersion
        /\ replica \in up
        /\ replica \in connected
        /\ storedVersion[replica] < version
        /\ storedVersion' = [storedVersion EXCEPT ![replica] = version]
        /\ writeMsgs' = writeMsgs \ {m}
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, ackedVersion, pendingVersion, repairMsgs, lastReadVersion, failuresRemaining>>

DropWrite(m) ==
  /\ time < MaxTime
  /\ m \in writeMsgs
  /\ writeMsgs' = writeMsgs \ {m}
  /\ lastOp' = "write"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, storedVersion, ackedVersion, pendingVersion, repairMsgs, lastReadVersion, failuresRemaining>>

AckWrite ==
  /\ time < MaxTime
  /\ pendingVersion > ackedVersion
  /\ Cardinality({ r \in LiveConnected : storedVersion[r] >= pendingVersion }) >= QuorumSize
  /\ ackedVersion' = pendingVersion
  /\ pendingVersion' = 0
  /\ writeMsgs' = {}
  /\ lastOp' = "ack"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, storedVersion, repairMsgs, lastReadVersion, failuresRemaining>>

Partition(c) ==
  /\ time < MaxTime
  /\ c \subseteq up
  /\ c # {}
  /\ connected' = c
  /\ lastOp' = "partition"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion, failuresRemaining>>

Heal ==
  /\ time < MaxTime
  /\ connected' = up
  /\ lastOp' = "heal"
  /\ time' = time + 1
  /\ UNCHANGED <<up, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion, failuresRemaining>>

EnqueueRepair(r) ==
  /\ time < MaxTime
  /\ pendingVersion = 0
  /\ HasConnectedQuorum
  /\ r \in up
  /\ r \in connected
  /\ storedVersion[r] < ackedVersion
  /\ repairMsgs' = repairMsgs \cup { <<ackedVersion, r>> }
  /\ lastOp' = "repair"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, lastReadVersion, failuresRemaining>>

DeliverRepair(m) ==
  /\ time < MaxTime
  /\ m \in repairMsgs
  /\ LET version == m[1]
         replica == m[2]
     IN /\ replica \in up
        /\ replica \in connected
        /\ storedVersion[replica] < version
        /\ storedVersion' = [storedVersion EXCEPT ![replica] = version]
        /\ repairMsgs' = repairMsgs \ {m}
  /\ lastOp' = "repair"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, ackedVersion, pendingVersion, writeMsgs, lastReadVersion, failuresRemaining>>

DropRepair(m) ==
  /\ time < MaxTime
  /\ m \in repairMsgs
  /\ repairMsgs' = repairMsgs \ {m}
  /\ lastOp' = "repair"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, lastReadVersion, failuresRemaining>>

Crash(r) ==
  /\ time < MaxTime
  /\ r \in up
  /\ up \ {r} # {}
  /\ failuresRemaining > 0
  /\ up' = up \ {r}
  /\ connected' = IF connected = {r} THEN up' ELSE connected \ {r}
  /\ failuresRemaining' = failuresRemaining - 1
  /\ lastOp' = "crash"
  /\ time' = time + 1
  /\ UNCHANGED <<storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion>>

Recover(r) ==
  /\ time < MaxTime
  /\ r \notin up
  /\ up' = up \cup {r}
  /\ lastOp' = "recover"
  /\ time' = time + 1
  /\ UNCHANGED <<connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion, failuresRemaining>>

Read(q) ==
  /\ time < MaxTime
  /\ pendingVersion = 0
  /\ q \in Quorums
  /\ q \subseteq LiveConnected
  /\ lastReadVersion' = ReadValue(q)
  /\ lastOp' = "read"
  /\ time' = time + 1
  /\ UNCHANGED <<up, connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, failuresRemaining>>

Tick ==
  /\ time < MaxTime
  /\ time' = time + 1
  /\ lastOp' = "tick"
  /\ UNCHANGED <<up, connected, storedVersion, ackedVersion, pendingVersion, writeMsgs, repairMsgs, lastReadVersion, failuresRemaining>>

Stutter == UNCHANGED vars

Next ==
  \/ StartWrite
  \/ \E m \in writeMsgs: DeliverWrite(m)
  \/ \E m \in writeMsgs: DropWrite(m)
  \/ AckWrite
  \/ \E c \in SUBSET up: Partition(c)
  \/ Heal
  \/ \E r \in Replicas: EnqueueRepair(r)
  \/ \E m \in repairMsgs: DeliverRepair(m)
  \/ \E m \in repairMsgs: DropRepair(m)
  \/ \E r \in Replicas: Crash(r)
  \/ \E r \in Replicas: Recover(r)
  \/ \E q \in Quorums: Read(q)
  \/ Tick
  \/ Stutter

Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ up \subseteq Replicas
  /\ connected \subseteq up
  /\ connected # {}
  /\ storedVersion \in [Replicas -> Versions]
  /\ ackedVersion \in Versions
  /\ pendingVersion \in Versions
  /\ writeMsgs \subseteq MessageSpace
  /\ repairMsgs \subseteq MessageSpace
  /\ lastReadVersion \in Versions
  /\ lastOp \in {"init", "write", "ack", "read", "partition", "heal", "repair", "crash", "recover", "tick"}
  /\ failuresRemaining \in 0..FailureBudget
  /\ time \in 0..MaxTime

InvConnectedAvailabilityBoundary ==
  HasConnectedQuorum <=> Cardinality(LiveConnected) >= QuorumSize

InvMinoritySplitUnavailable ==
  Cardinality(LiveConnected) < QuorumSize => ~HasConnectedQuorum

InvNoReplicaAheadWhenCommitted ==
  pendingVersion = 0 => \A r \in Replicas: storedVersion[r] <= ackedVersion

InvConnectedQuorumReadExact ==
  \A q \in Quorums:
    /\ q \subseteq LiveConnected
    /\ pendingVersion = 0
    => ReadValue(q) = ackedVersion

InvObservedReadSafe ==
  lastOp = "read" => lastReadVersion = ackedVersion

=============================================================================
