------------------------------ MODULE RenormalizationComposition ------------------------------
EXTENDS Integers, FiniteSets

VARIABLE tick

vars == <<tick>>

FineNodes == {1, 2, 3, 4}
MidNodes == {1, 2}
OuterNodes == {1}

InnerQuotient == [fine \in FineNodes |-> IF fine = 1 \/ fine = 2 THEN 1 ELSE 2]
OuterQuotient == [mid \in MidNodes |-> 1]
ComposedQuotient == [fine \in FineNodes |-> OuterQuotient[InnerQuotient[fine]]]

Arrival ==
  [fine \in FineNodes |->
    CASE fine = 1 -> 2
      [] fine = 2 -> 1
      [] fine = 3 -> 1
      [] OTHER -> 0]

Service ==
  [fine \in FineNodes |->
    CASE fine = 1 -> 3
      [] fine = 2 -> 1
      [] fine = 3 -> 2
      [] OTHER -> 1]

Shed ==
  [fine \in FineNodes |->
    CASE fine = 2 -> 1
      [] OTHER -> 0]

RECURSIVE SumMap(_, _)
SumMap(nodeSet, rateMap) ==
  IF nodeSet = {} THEN 0
  ELSE LET chosen == CHOOSE node \in nodeSet : TRUE
       IN rateMap[chosen] + SumMap(nodeSet \ {chosen}, rateMap)

InnerFiber(mid) == {fine \in FineNodes : InnerQuotient[fine] = mid}
OuterFiber(outer) == {mid \in MidNodes : OuterQuotient[mid] = outer}
ComposedFiber(outer) == {fine \in FineNodes : ComposedQuotient[fine] = outer}

FineDrift(fine) == Arrival[fine] - (Service[fine] + Shed[fine])

MidArrival(mid) == SumMap(InnerFiber(mid), Arrival)
MidService(mid) == SumMap(InnerFiber(mid), Service)
MidShed(mid) == SumMap(InnerFiber(mid), Shed)
MidDrift(mid) == MidArrival(mid) - (MidService(mid) + MidShed(mid))

OuterArrival(outer) == SumMap(OuterFiber(outer), [mid \in MidNodes |-> MidArrival(mid)])
OuterService(outer) == SumMap(OuterFiber(outer), [mid \in MidNodes |-> MidService(mid)])
OuterShed(outer) == SumMap(OuterFiber(outer), [mid \in MidNodes |-> MidShed(mid)])
OuterDrift(outer) == OuterArrival(outer) - (OuterService(outer) + OuterShed(outer))

DirectArrival(outer) == SumMap(ComposedFiber(outer), Arrival)
DirectService(outer) == SumMap(ComposedFiber(outer), Service)
DirectShed(outer) == SumMap(ComposedFiber(outer), Shed)
DirectDrift(outer) == DirectArrival(outer) - (DirectService(outer) + DirectShed(outer))

TotalFineDrift == SumMap(FineNodes, [fine \in FineNodes |-> FineDrift(fine)])
TotalMidDrift == SumMap(MidNodes, [mid \in MidNodes |-> MidDrift(mid)])
TotalOuterDrift == SumMap(OuterNodes, [outer \in OuterNodes |-> OuterDrift(outer)])

Init == tick = 0

Stutter == UNCHANGED vars

Next == Stutter
Spec == Init /\ [][Next]_vars

InvMidCarriesFineAggregates ==
  /\ MidArrival(1) = 3
  /\ MidService(1) = 4
  /\ MidShed(1) = 1
  /\ MidDrift(1) = -2
  /\ MidArrival(2) = 1
  /\ MidService(2) = 3
  /\ MidShed(2) = 0
  /\ MidDrift(2) = -2

InvRecursiveReuseMatchesDirect ==
  \A outer \in OuterNodes :
    /\ OuterArrival(outer) = DirectArrival(outer)
    /\ OuterService(outer) = DirectService(outer)
    /\ OuterShed(outer) = DirectShed(outer)
    /\ OuterDrift(outer) = DirectDrift(outer)

InvRecursiveTotalsMatchFine ==
  /\ TotalMidDrift = TotalFineDrift
  /\ TotalOuterDrift = TotalFineDrift

InvRecursiveCollapsedDriftTransfer ==
  TotalFineDrift <= -4 => OuterDrift(1) <= -4

InvRecursiveClosedFormWitness ==
  /\ DirectArrival(1) = 4
  /\ DirectService(1) = 7
  /\ DirectShed(1) = 1
  /\ DirectDrift(1) = -4
  /\ OuterArrival(1) = 4
  /\ OuterService(1) = 7
  /\ OuterShed(1) = 1
  /\ OuterDrift(1) = -4
  /\ TotalFineDrift = -4
  /\ TotalMidDrift = -4
  /\ TotalOuterDrift = -4

=============================================================================
