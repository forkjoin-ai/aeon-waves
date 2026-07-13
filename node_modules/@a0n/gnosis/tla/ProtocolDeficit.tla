------------------------------ MODULE ProtocolDeficit ------------------------------
EXTENDS Naturals

CONSTANTS StreamDomain

VARIABLE streamCount

vars == <<streamCount>>

Init ==
  /\ streamCount \in StreamDomain
  /\ streamCount > 1

Change ==
  /\ streamCount' \in StreamDomain
  /\ streamCount' > 1

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

IntrinsicBeta1 == streamCount - 1
TcpBeta1 == 0
QuicBeta1 == streamCount - 1
FlowBeta1 == streamCount - 1

TcpDeficit == IntrinsicBeta1 - TcpBeta1
QuicDeficit == IntrinsicBeta1 - QuicBeta1
FlowDeficit == IntrinsicBeta1 - FlowBeta1

InvIntrinsicShape ==
  /\ streamCount > 1
  /\ IntrinsicBeta1 = streamCount - 1

InvTcpDeficit ==
  /\ TcpDeficit = streamCount - 1

InvQuicDeficit ==
  /\ QuicDeficit = 0

InvFlowDeficit ==
  /\ FlowDeficit = 0

=============================================================================
