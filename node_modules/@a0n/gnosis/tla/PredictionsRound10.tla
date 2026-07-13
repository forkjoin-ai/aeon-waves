------------------------------ MODULE PredictionsRound10 ------------------------------
(*
  Predictions Round 10: Addiction Recovery, Paradigm Shifts,
  Organizational Hierarchy, Translation Loss, Ecosystem Valuation.
*)
EXTENDS Naturals

CONSTANTS RecoveryOpps, FailedAttempts,
          TotalAnomalies, OldAnomalies, NewAnomalies,
          Roles, ManagementLayers,
          SourceDims, SharedDims,
          TotalServices, PricedServices, PricedValue

VARIABLES phase, currentRelapses, recoveryStrength,
          oldWeight, newWeight,
          hierarchyDeficit, translationDeficit,
          structuralHoles

vars == <<phase, currentRelapses, recoveryStrength,
          oldWeight, newWeight,
          hierarchyDeficit, translationDeficit,
          structuralHoles>>

Min(a, b) == IF a <= b THEN a ELSE b

Init ==
  /\ phase = "addiction"
  /\ currentRelapses = 0
  /\ recoveryStrength = RecoveryOpps - Min(0, RecoveryOpps) + 1
  /\ oldWeight = TotalAnomalies - Min(OldAnomalies, TotalAnomalies) + 1
  /\ newWeight = TotalAnomalies - Min(NewAnomalies, TotalAnomalies) + 1
  /\ hierarchyDeficit = IF ManagementLayers > Roles
                         THEN ManagementLayers - Roles ELSE 0
  /\ translationDeficit = SourceDims - SharedDims
  /\ structuralHoles = TotalServices - PricedServices

\* P106: Relapse step (failed sobriety attempt = void boundary entry)
RelapseStep ==
  /\ phase = "addiction"
  /\ currentRelapses < RecoveryOpps
  /\ currentRelapses' = currentRelapses + 1
  /\ recoveryStrength' = RecoveryOpps - Min(currentRelapses + 1, RecoveryOpps) + 1
  /\ phase' = "paradigm"
  /\ UNCHANGED <<oldWeight, newWeight, hierarchyDeficit,
                  translationDeficit, structuralHoles>>

\* P107-P110: Cycle through remaining phases
ParadigmStep ==
  /\ phase = "paradigm"
  /\ phase' = "hierarchy"
  /\ UNCHANGED <<currentRelapses, recoveryStrength, oldWeight, newWeight,
                  hierarchyDeficit, translationDeficit, structuralHoles>>

HierarchyStep ==
  /\ phase = "hierarchy"
  /\ phase' = "translation"
  /\ UNCHANGED <<currentRelapses, recoveryStrength, oldWeight, newWeight,
                  hierarchyDeficit, translationDeficit, structuralHoles>>

TranslationStep ==
  /\ phase = "translation"
  /\ phase' = "ecosystem"
  /\ UNCHANGED <<currentRelapses, recoveryStrength, oldWeight, newWeight,
                  hierarchyDeficit, translationDeficit, structuralHoles>>

EcosystemStep ==
  /\ phase = "ecosystem"
  /\ phase' = "addiction"
  /\ UNCHANGED <<currentRelapses, recoveryStrength, oldWeight, newWeight,
                  hierarchyDeficit, translationDeficit, structuralHoles>>

Stutter == UNCHANGED vars

Next == RelapseStep \/ ParadigmStep \/ HierarchyStep
     \/ TranslationStep \/ EcosystemStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* P106: Recovery strength always positive (the sliver)
InvRecoveryPositive ==
  recoveryStrength >= 1

\* P106: Relapses bounded
InvRelapsesBounded ==
  currentRelapses <= RecoveryOpps

\* P107: Old paradigm weight positive
InvOldWeightPositive ==
  oldWeight >= 1

\* P107: New paradigm weight positive
InvNewWeightPositive ==
  newWeight >= 1

\* P107: Paradigm shift dominance (new >= old when old has more anomalies)
InvParadigmShift ==
  (NewAnomalies <= OldAnomalies) => (newWeight >= oldWeight)

\* P108: Hierarchy deficit non-negative
InvHierarchyNonneg ==
  hierarchyDeficit >= 0

\* P109: Translation deficit non-negative
InvTranslationNonneg ==
  translationDeficit >= 0

\* P110: Structural holes non-negative
InvHolesNonneg ==
  structuralHoles >= 0

=============================================================================
