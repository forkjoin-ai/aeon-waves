------------------------------ MODULE RenormalizationCoarsening ------------------------------
EXTENDS Integers, FiniteSets

VARIABLE tick

vars == <<tick>>

FineNodes == {1, 2, 3, 4}
CoarseNodes == {1, 2}

Quotient == [i \in FineNodes |-> IF i = 1 \/ i = 2 THEN 1 ELSE 2]

Arrival ==
  [i \in FineNodes |->
    CASE i = 1 -> 2
      [] i = 2 -> 1
      [] i = 3 -> 1
      [] OTHER -> 0]

Service ==
  [i \in FineNodes |->
    CASE i = 1 -> 3
      [] i = 2 -> 1
      [] i = 3 -> 2
      [] OTHER -> 1]

Shed ==
  [i \in FineNodes |->
    CASE i = 2 -> 1
      [] OTHER -> 0]

RECURSIVE SumMap(_, _)
SumMap(nodeSet, rateMap) ==
  IF nodeSet = {} THEN 0
  ELSE LET chosen == CHOOSE node \in nodeSet : TRUE
       IN rateMap[chosen] + SumMap(nodeSet \ {chosen}, rateMap)

Fiber(coarse) == {fine \in FineNodes : Quotient[fine] = coarse}

FineDrift(fine) == Arrival[fine] - (Service[fine] + Shed[fine])

CoarseArrival(coarse) == SumMap(Fiber(coarse), Arrival)
CoarseService(coarse) == SumMap(Fiber(coarse), Service)
CoarseShed(coarse) == SumMap(Fiber(coarse), Shed)
CoarseDrift(coarse) == CoarseArrival(coarse) - (CoarseService(coarse) + CoarseShed(coarse))
CoarseMargin == [coarse \in CoarseNodes |->
  CASE coarse = 1 -> 2
    [] coarse = 2 -> 2
    [] OTHER -> 0]

TotalFineArrival == SumMap(FineNodes, Arrival)
TotalFineService == SumMap(FineNodes, Service)
TotalFineShed == SumMap(FineNodes, Shed)
TotalFineDrift == SumMap(FineNodes, [fine \in FineNodes |-> FineDrift(fine)])

TotalCoarseDrift == SumMap(CoarseNodes, [coarse \in CoarseNodes |-> CoarseDrift(coarse)])
TotalCoarseMargin == SumMap(CoarseNodes, CoarseMargin)

CollapsedArrival == TotalFineArrival
CollapsedService == TotalFineService
CollapsedShed == TotalFineShed
CollapsedDrift == CollapsedArrival - (CollapsedService + CollapsedShed)

Init == tick = 0

Stutter == UNCHANGED vars

Next == Stutter
Spec == Init /\ [][Next]_vars

InvManyToOneWitness ==
  \E coarse \in CoarseNodes : Cardinality(Fiber(coarse)) > 1

InvCoarseFiberDriftMatchesFineSum ==
  \A coarse \in CoarseNodes : CoarseDrift(coarse) = SumMap(Fiber(coarse), [fine \in FineNodes |-> FineDrift(fine)])

InvTotalCoarseDriftEqualsFine ==
  TotalCoarseDrift = TotalFineDrift

InvCoarseDriftCertificate ==
  \A coarse \in CoarseNodes : CoarseDrift(coarse) <= - CoarseMargin[coarse]

InvCoarseMarginTotal ==
  TotalCoarseMargin = 4

InvCoarseCertificateTransfersToFine ==
  TotalFineDrift <= - TotalCoarseMargin

InvCoarseCertificateTransfersToCollapsed ==
  CollapsedDrift <= - TotalCoarseMargin

InvCollapsedNodeCarriesAggregateRates ==
  /\ CollapsedArrival = TotalFineArrival
  /\ CollapsedService = TotalFineService
  /\ CollapsedShed = TotalFineShed

InvCollapsedDriftTransfer ==
  TotalFineDrift <= -4 => CollapsedDrift <= -4

InvClosedFormWitness ==
  /\ CoarseArrival(1) = 3
  /\ CoarseService(1) = 4
  /\ CoarseShed(1) = 1
  /\ CoarseDrift(1) = -2
  /\ CoarseMargin[1] = 2
  /\ CoarseArrival(2) = 1
  /\ CoarseService(2) = 3
  /\ CoarseShed(2) = 0
  /\ CoarseDrift(2) = -2
  /\ CoarseMargin[2] = 2
  /\ TotalCoarseMargin = 4
  /\ CollapsedArrival = 4
  /\ CollapsedService = 7
  /\ CollapsedShed = 1
  /\ CollapsedDrift = -4

=============================================================================
