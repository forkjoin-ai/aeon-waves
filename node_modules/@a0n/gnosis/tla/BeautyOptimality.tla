------------------------------ MODULE BeautyOptimality ------------------------------
EXTENDS Naturals

\* Bu (Bule) is the Betti-deficit unit.
\* deficitBu = beta1* - beta1(implementation)

CONSTANTS Beta1StarDomain, DeficitBuDomain, PipelineBu, ProtocolBu, CompressionBu

VARIABLES beta1Star, deficitBuA, deficitBuB, latencyA, latencyB, wasteA, wasteB

vars == <<beta1Star, deficitBuA, deficitBuB, latencyA, latencyB, wasteA, wasteB>>

Init ==
  /\ beta1Star \in Beta1StarDomain
  /\ deficitBuA \in DeficitBuDomain
  /\ deficitBuB \in DeficitBuDomain
  /\ deficitBuA <= deficitBuB
  /\ deficitBuB <= beta1Star
  /\ latencyA = deficitBuA + 1
  /\ latencyB = deficitBuB + 1
  /\ wasteA = deficitBuA
  /\ wasteB = deficitBuB

Change ==
  /\ beta1Star' \in Beta1StarDomain
  /\ deficitBuA' \in DeficitBuDomain
  /\ deficitBuB' \in DeficitBuDomain
  /\ deficitBuA' <= deficitBuB'
  /\ deficitBuB' <= beta1Star'
  /\ latencyA' = deficitBuA' + 1
  /\ latencyB' = deficitBuB' + 1
  /\ wasteA' = deficitBuA'
  /\ wasteB' = deficitBuB'

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

BeautyBuA == beta1Star - deficitBuA
BeautyBuB == beta1Star - deficitBuB

GlobalDeficitBu == PipelineBu + ProtocolBu + CompressionBu

InvBuWellFormed ==
  /\ deficitBuA \in Nat
  /\ deficitBuB \in Nat
  /\ deficitBuA <= deficitBuB
  /\ deficitBuB <= beta1Star

InvBeautyDefinition ==
  /\ BeautyBuA = beta1Star - deficitBuA
  /\ BeautyBuB = beta1Star - deficitBuB

InvBeautyLatencyMonotone ==
  deficitBuA <= deficitBuB => latencyA <= latencyB

InvBeautyWasteMonotone ==
  deficitBuA <= deficitBuB => wasteA <= wasteB

InvBeautyPareto ==
  deficitBuA = 0 => /\ latencyA <= latencyB /\ wasteA <= wasteB

InvBeautyComposition ==
  /\ GlobalDeficitBu = PipelineBu + ProtocolBu + CompressionBu
  /\ deficitBuB <= GlobalDeficitBu

InvBeautyOptimality ==
  /\ InvBeautyDefinition
  /\ InvBeautyLatencyMonotone
  /\ InvBeautyWasteMonotone
  /\ InvBeautyPareto
  /\ InvBeautyComposition
  /\ BeautyBuB <= BeautyBuA

=============================================================================
