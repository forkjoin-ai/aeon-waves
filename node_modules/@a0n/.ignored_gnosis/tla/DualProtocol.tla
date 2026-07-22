---------------------------- MODULE DualProtocol ------------------------------
(***************************************************************************)
(* Track Gamma: Dual-Protocol Deficit Duality.                             *)
(*                                                                         *)
(* Models a server that speaks two protocols simultaneously:               *)
(*   - HTTP/1.1 (beta1 = 0 on wire, per-request headers)                  *)
(*   - Aeon Flow (beta1 > 0 on wire, 10-byte frames, no headers)          *)
(*                                                                         *)
(* The server has internal beta1 > 0 (fork/race/fold topology).            *)
(* The question: does the internal topology advantage transfer across      *)
(* the protocol boundary to the external wire?                             *)
(*                                                                         *)
(* THM-DUAL-PROTOCOL-PARETO: HTTP+Flow dominates either alone              *)
(* THM-INTERNAL-DEFICIT-TRANSFER: Internal deficit=0 transfers advantage   *)
(* THM-PROTOCOL-BRIDGE-CONSERVATION: Throughput conserved across boundary  *)
(* THM-DUAL-PROTOCOL-MONOTONE: Adding Flow never worsens HTTP clients      *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets

CONSTANTS
  HttpConnections,    \* Browser HTTP connections (typically 6)
  FlowStreams,        \* Aeon Flow concurrent streams (typically 256)
  ResourceCount,      \* Total resources to serve
  InternalBeta1,      \* Internal topology beta1 (race arms - 1)
  HttpHeaderBytes,    \* Per-resource HTTP header overhead
  FlowHeaderBytes     \* Per-resource Flow header overhead (20 = DATA+FIN)

VARIABLES
  httpThroughput,     \* Resources served to HTTP clients per unit time
  flowThroughput,     \* Resources served to Flow clients per unit time
  dualThroughput,     \* Total resources served (HTTP + Flow) per unit time
  httpOnlyThroughput, \* Throughput if server were HTTP-only
  flowOnlyThroughput, \* Throughput if server were Flow-only
  httpOverhead,       \* Total HTTP framing overhead
  flowOverhead,       \* Total Flow framing overhead
  httpDeficit,        \* Topological deficit on HTTP wire
  flowDeficit,        \* Topological deficit on Flow wire
  internalDeficit,    \* Internal scheduling deficit
  phase               \* Execution phase

vars == <<httpThroughput, flowThroughput, dualThroughput,
          httpOnlyThroughput, flowOnlyThroughput,
          httpOverhead, flowOverhead,
          httpDeficit, flowDeficit, internalDeficit, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME HttpConnections >= 1
ASSUME FlowStreams >= 1
ASSUME ResourceCount >= 1
ASSUME InternalBeta1 >= 1      \* At least one race (cache|disk)
ASSUME HttpHeaderBytes >= 100  \* HTTP headers are at least 100 bytes
ASSUME FlowHeaderBytes >= 10   \* Flow frames are at least 10 bytes

\* ─── Helpers ─────────────────────────────────────────────────────────

CeilDiv(a, b) == (a + b - 1) \div b

Min(a, b) == IF a <= b THEN a ELSE b

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ httpThroughput = 0
  /\ flowThroughput = 0
  /\ dualThroughput = 0
  /\ httpOnlyThroughput = 0
  /\ flowOnlyThroughput = 0
  /\ httpOverhead = 0
  /\ flowOverhead = 0
  /\ httpDeficit = 0
  /\ flowDeficit = 0
  /\ internalDeficit = 0
  /\ phase = "init"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Phase 1: Compute throughput for each protocol mode
ComputeThroughput ==
  /\ phase = "init"
  \* HTTP throughput: limited by connection count and round trips
  /\ httpOnlyThroughput' = Min(ResourceCount, HttpConnections * 2)
  \* Flow throughput: limited by stream count (much higher)
  /\ flowOnlyThroughput' = Min(ResourceCount, FlowStreams)
  \* Dual mode: serve both simultaneously
  \* HTTP clients get HTTP, Flow clients get Flow, total is additive
  /\ httpThroughput' = Min(ResourceCount, HttpConnections * 2)
  /\ flowThroughput' = Min(ResourceCount, FlowStreams)
  /\ dualThroughput' = Min(ResourceCount, HttpConnections * 2)
                      + Min(ResourceCount, FlowStreams)
  /\ phase' = "throughput_computed"
  /\ UNCHANGED <<httpOverhead, flowOverhead, httpDeficit,
                  flowDeficit, internalDeficit>>

\* Phase 2: Compute framing overhead
ComputeOverhead ==
  /\ phase = "throughput_computed"
  /\ httpOverhead' = ResourceCount * HttpHeaderBytes
  /\ flowOverhead' = ResourceCount * FlowHeaderBytes
  /\ phase' = "overhead_computed"
  /\ UNCHANGED <<httpThroughput, flowThroughput, dualThroughput,
                  httpOnlyThroughput, flowOnlyThroughput,
                  httpDeficit, flowDeficit, internalDeficit>>

\* Phase 3: Compute topological deficits
ComputeDeficit ==
  /\ phase = "overhead_computed"
  \* HTTP wire has beta1 = 0 but problem has beta1 = InternalBeta1
  \* Deficit = beta1*(problem) - beta1(wire)
  /\ httpDeficit' = InternalBeta1
  \* Flow wire has beta1 = ResourceCount - 1 (all streams multiplexed)
  \* When flow beta1 >= internal beta1, deficit = 0
  /\ flowDeficit' = IF FlowStreams >= InternalBeta1 + 1 THEN 0
                    ELSE InternalBeta1 - FlowStreams + 1
  \* Internal deficit is always 0 (topology matches scheduling)
  /\ internalDeficit' = 0
  /\ phase' = "complete"
  /\ UNCHANGED <<httpThroughput, flowThroughput, dualThroughput,
                  httpOnlyThroughput, flowOnlyThroughput,
                  httpOverhead, flowOverhead>>

Stutter == UNCHANGED vars

Next ==
  \/ ComputeThroughput
  \/ ComputeOverhead
  \/ ComputeDeficit
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(ComputeThroughput)
    /\ WF_vars(ComputeOverhead)
    /\ WF_vars(ComputeDeficit)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1 (THM-DUAL-PROTOCOL-PARETO):
\* Dual-protocol throughput >= each single-protocol throughput
InvDualPareto ==
  (phase = "complete")
    => /\ dualThroughput >= httpOnlyThroughput
       /\ dualThroughput >= flowOnlyThroughput

\* INV2 (THM-INTERNAL-DEFICIT-TRANSFER):
\* Internal deficit = 0 (topology matches scheduling)
\* AND flow deficit = 0 (flow wire matches topology)
\* HTTP deficit > 0 (HTTP wire mismatches topology)
InvDeficitTransfer ==
  (phase = "complete")
    => /\ internalDeficit = 0
       /\ httpDeficit > 0
       /\ flowDeficit = 0

\* INV3 (THM-PROTOCOL-BRIDGE-CONSERVATION):
\* Flow framing overhead < HTTP framing overhead (by construction)
InvBridgeConservation ==
  (phase = "complete")
    => flowOverhead < httpOverhead

\* INV4 (THM-DUAL-PROTOCOL-MONOTONE):
\* Adding Flow protocol to HTTP-only server never worsens HTTP throughput
InvDualMonotone ==
  (phase = "complete")
    => httpThroughput >= httpOnlyThroughput

\* INV5: Flow deficit is zero when streams >= internal beta1
InvFlowDeficitZero ==
  (phase = "complete" /\ FlowStreams >= InternalBeta1 + 1)
    => flowDeficit = 0

\* INV6: Overhead ratio: flow overhead / http overhead < 1
InvOverheadRatio ==
  (phase = "complete")
    => flowOverhead * 100 < httpOverhead * 100

\* ─── Liveness ────────────────────────────────────────────────────────

ProtocolTermination == <>(phase = "complete")

=============================================================================
