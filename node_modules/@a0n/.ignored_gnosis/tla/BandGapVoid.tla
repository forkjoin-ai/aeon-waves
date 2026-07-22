------------------------------ MODULE BandGapVoid ------------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS MaxEnergy, AllowedFamilies

VARIABLE allowed

vars == <<allowed>>

Init == allowed \in AllowedFamilies
Next == allowed' \in AllowedFamilies
Spec == Init /\ [][Next]_vars

AllEnergies == 0..MaxEnergy
ForbiddenEnergies == AllEnergies \ allowed
BandGapExists == Cardinality(ForbiddenEnergies) > 0
Beta2 == IF BandGapExists THEN 1 ELSE 0

InvAllowedSubset ==
  allowed \subseteq AllEnergies

InvBandGapExists ==
  /\ BandGapExists
  /\ \E e \in 1..(MaxEnergy - 1): e \in ForbiddenEnergies

InvVoidIsPositive ==
  BandGapExists => Beta2 > 0

=============================================================================
