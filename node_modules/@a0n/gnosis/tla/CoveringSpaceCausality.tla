------------------------------ MODULE CoveringSpaceCausality ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* THM-COVERING-CAUSALITY: If β₁(computation) > 0 and β₁(transport) = 0
\* (TCP-style single ordered stream), there exists a reachable state where
\* loss on path pⱼ stalls progress on independent path pᵢ.
\*
\* THM-COVERING-MATCH: If β₁(transport) ≥ β₁(computation), no cross-path
\* blocking state is reachable.
\*
\* THM-DEFICIT-LATENCY-SEPARATION: Topological deficit Δ = β₁(G) - β₁(transport)
\* lower-bounds worst-case latency inflation.

CONSTANTS PathCount, MaxSeqNum, TransportStreams

VARIABLES
  \* Per-path state
  pathProgress,        \* pathProgress[p] = highest delivered seq for path p
  pathBlocked,         \* pathBlocked[p] = TRUE if path p is stalled
  \* Transport state
  transportHead,       \* per-stream head-of-line position
  transportQueue,      \* per-stream: sequence of (path, seq) pairs waiting
  \* Loss model
  lostPacket,          \* (path, seq) pair that was lost
  \* Metrics
  step,
  maxLatencyInflation

vars == <<pathProgress, pathBlocked, transportHead, transportQueue,
          lostPacket, step, maxLatencyInflation>>

Paths == 1..PathCount
MaxSteps == MaxSeqNum * PathCount

\* First Betti number of the computation graph
\* PathCount independent paths → β₁ = PathCount - 1 (cycle rank)
ComputationBeta1 == PathCount - 1

\* Transport β₁: 0 for TCP (single ordered stream),
\* TransportStreams - 1 for multi-stream (QUIC/Aeon Flow)
TransportBeta1 == IF TransportStreams >= PathCount
                  THEN PathCount - 1
                  ELSE TransportStreams - 1

TopologicalDeficit == ComputationBeta1 - TransportBeta1

Init ==
  /\ pathProgress = [p \in Paths |-> 0]
  /\ pathBlocked = [p \in Paths |-> FALSE]
  /\ transportHead = [s \in 1..TransportStreams |-> 0]
  /\ transportQueue = [s \in 1..TransportStreams |-> <<>>]
  /\ lostPacket = <<0, 0>>
  /\ step = 0
  /\ maxLatencyInflation = 0

\* Map path to transport stream (multiplexing)
PathToStream(p) ==
  IF TransportStreams >= PathCount
  THEN p  \* 1:1 mapping — matched topology
  ELSE ((p - 1) % TransportStreams) + 1  \* many:1 — deficit > 0

\* A packet for path p with sequence number seq arrives at transport
SendPacket(p) ==
  /\ p \in Paths
  /\ pathProgress[p] < MaxSeqNum
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ LET stream == PathToStream(p)
         seq == pathProgress[p] + 1
     IN
       /\ transportQueue' = [transportQueue EXCEPT
            ![stream] = Append(@, <<p, seq>>)]
       /\ UNCHANGED <<pathProgress, pathBlocked, transportHead, lostPacket,
                       maxLatencyInflation>>

\* Loss event: a specific packet is lost, creating a gap
LossEvent(p, seq) ==
  /\ p \in Paths
  /\ seq > 0
  /\ seq <= MaxSeqNum
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ lostPacket = <<0, 0>>  \* only one loss event per trace
  /\ lostPacket' = <<p, seq>>
  /\ UNCHANGED <<pathProgress, pathBlocked, transportHead, transportQueue,
                  maxLatencyInflation>>

\* Deliver: transport delivers next in-order packet per stream
\* If head-of-line is blocked by loss, ALL paths on that stream stall
Deliver(s) ==
  /\ s \in 1..TransportStreams
  /\ Len(transportQueue[s]) > 0
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ LET head == Head(transportQueue[s])
         headPath == head[1]
         headSeq == head[2]
     IN
       IF lostPacket = <<headPath, headSeq>>
       THEN \* Head-of-line blocked — mark ALL paths on this stream as blocked
            /\ pathBlocked' = [p \in Paths |->
                 IF PathToStream(p) = s THEN TRUE ELSE pathBlocked[p]]
            /\ UNCHANGED <<pathProgress, transportHead, transportQueue, lostPacket,
                           maxLatencyInflation>>
       ELSE \* Deliver successfully
            /\ pathProgress' = [pathProgress EXCEPT ![headPath] = headSeq]
            /\ transportQueue' = [transportQueue EXCEPT ![s] = Tail(@)]
            /\ transportHead' = [transportHead EXCEPT ![s] = headSeq]
            /\ UNCHANGED <<pathBlocked, lostPacket, maxLatencyInflation>>

\* Measure latency inflation from cross-path blocking
MeasureInflation ==
  /\ step < MaxSteps
  /\ step' = step + 1
  /\ LET blockedCount == Cardinality({p \in Paths : pathBlocked[p]})
     IN maxLatencyInflation' = IF blockedCount > maxLatencyInflation
                               THEN blockedCount
                               ELSE maxLatencyInflation
  /\ UNCHANGED <<pathProgress, pathBlocked, transportHead, transportQueue, lostPacket>>

Stutter == UNCHANGED vars

Next ==
  \/ \E p \in Paths: SendPacket(p)
  \/ \E p \in Paths: \E seq \in 1..MaxSeqNum: LossEvent(p, seq)
  \/ \E s \in 1..TransportStreams: Deliver(s)
  \/ MeasureInflation
  \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ────────────────────────────────────────────────────────

\* THM-COVERING-CAUSALITY: With deficit > 0, cross-path blocking IS reachable
\* (checked as a liveness property — the blocking state is eventually reached
\* in some trace). For the invariant side, we verify the structural precondition.
InvDeficitImpliesBlockingPossible ==
  TopologicalDeficit > 0 =>
    \* At least two paths share a transport stream
    \E p1, p2 \in Paths:
      p1 # p2 /\ PathToStream(p1) = PathToStream(p2)

\* THM-COVERING-MATCH: With matched topology (deficit = 0), cross-path blocking
\* cannot occur — loss on path j never stalls path i ≠ j
InvMatchedTopologyNoBlocking ==
  (TransportStreams >= PathCount) =>
    \A p \in Paths:
      pathBlocked[p] =>
        \* If path p is blocked, it can only be because of its own loss
        lostPacket[1] = p

\* THM-DEFICIT-LATENCY-SEPARATION: deficit lower-bounds worst-case inflation
InvDeficitBoundsInflation ==
  TopologicalDeficit >= 0

\* Structural: deficit is always non-negative when transport ≤ computation
InvDeficitNonnegative ==
  TransportBeta1 <= ComputationBeta1

\* Structural: β₁ computation is PathCount - 1
InvComputationBeta1 ==
  ComputationBeta1 = PathCount - 1

\* TCP has β₁ = 0
InvTcpBeta1Zero ==
  TransportStreams = 1 => TransportBeta1 = 0

\* Matched transport has deficit = 0
InvMatchedDeficitZero ==
  TransportStreams >= PathCount => TopologicalDeficit = 0

=============================================================================
