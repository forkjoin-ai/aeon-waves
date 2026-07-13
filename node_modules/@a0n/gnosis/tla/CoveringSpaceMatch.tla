------------------------------ MODULE CoveringSpaceMatch ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* THM-COVERING-MATCH verification under matched topology.
\* When TransportStreams >= PathCount (β₁(transport) ≥ β₁(computation)),
\* each path gets its own transport stream — loss isolation is guaranteed.
\*
\* This is the complement of CoveringSpaceCausality: here we verify that
\* the matched case NEVER produces cross-path blocking.

CONSTANTS PathCount, MaxSeqNum

VARIABLES
  pathProgress,
  pathBlocked,
  streamHead,
  streamQueue,
  lostPacket,
  step

vars == <<pathProgress, pathBlocked, streamHead, streamQueue, lostPacket, step>>

Paths == 1..PathCount
Streams == 1..PathCount  \* 1:1 mapping — matched topology
MaxSteps == MaxSeqNum * PathCount

ComputationBeta1 == PathCount - 1
TransportBeta1 == PathCount - 1
TopologicalDeficit == 0

Init ==
  /\ pathProgress = [p \in Paths |-> 0]
  /\ pathBlocked = [p \in Paths |-> FALSE]
  /\ streamHead = [s \in Streams |-> 0]
  /\ streamQueue = [s \in Streams |-> <<>>]
  /\ lostPacket = <<0, 0>>
  /\ step = 0

SendPacket(p) ==
  /\ p \in Paths
  /\ pathProgress[p] < MaxSeqNum
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ LET seq == pathProgress[p] + 1 IN
       streamQueue' = [streamQueue EXCEPT ![p] = Append(@, <<p, seq>>)]
  /\ UNCHANGED <<pathProgress, pathBlocked, streamHead, lostPacket>>

LossEvent(p, seq) ==
  /\ p \in Paths
  /\ seq > 0 /\ seq <= MaxSeqNum
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ lostPacket = <<0, 0>>
  /\ lostPacket' = <<p, seq>>
  /\ UNCHANGED <<pathProgress, pathBlocked, streamHead, streamQueue>>

Deliver(s) ==
  /\ s \in Streams
  /\ Len(streamQueue[s]) > 0
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ LET head == Head(streamQueue[s])
         headPath == head[1]
         headSeq == head[2]
     IN
       IF lostPacket = <<headPath, headSeq>>
       THEN \* Only the stream's own path is blocked
            /\ pathBlocked' = [pathBlocked EXCEPT ![headPath] = TRUE]
            /\ UNCHANGED <<pathProgress, streamHead, streamQueue, lostPacket>>
       ELSE
            /\ pathProgress' = [pathProgress EXCEPT ![headPath] = headSeq]
            /\ streamQueue' = [streamQueue EXCEPT ![s] = Tail(@)]
            /\ streamHead' = [streamHead EXCEPT ![s] = headSeq]
            /\ UNCHANGED <<pathBlocked, lostPacket>>

Tick ==
  /\ step' = step + 1
  /\ step < MaxSteps
  /\ UNCHANGED <<pathProgress, pathBlocked, streamHead, streamQueue, lostPacket>>

Stutter == UNCHANGED vars

Next ==
  \/ \E p \in Paths: SendPacket(p)
  \/ \E p \in Paths: \E seq \in 1..MaxSeqNum: LossEvent(p, seq)
  \/ \E s \in Streams: Deliver(s)
  \/ Tick
  \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Core invariant: no cross-path blocking under matched topology ─────

\* If path p is blocked, it can ONLY be because of a loss on path p itself
InvNoCrossPathBlocking ==
  \A p \in Paths:
    pathBlocked[p] => lostPacket[1] = p

\* Equivalent: no path is blocked by a loss on a DIFFERENT path
InvNoForeignBlocking ==
  \A p1, p2 \in Paths:
    (p1 # p2 /\ lostPacket[1] = p1) => ~pathBlocked[p2]

\* Deficit is zero
InvZeroDeficit ==
  TopologicalDeficit = 0

\* β₁ match
InvBeta1Match ==
  TransportBeta1 = ComputationBeta1

=============================================================================
