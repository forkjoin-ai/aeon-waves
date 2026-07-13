------------------------------ MODULE PredictionsRound13 ------------------------------
(*
  Predictions Round 13: Vulnerability Diagnostic, Curvature Therapy,
  Community Merge, Molecular Attenuation, Cultural Convergence.
*)
EXTENDS Naturals

CONSTANTS TotalDims, Shared, HiddenA, HiddenB, Unexplored,
          FailureDims, ContextT, ContextT1,
          ComplexityG, ContextGA, ContextGB,
          ModesAlone, ModesWith,
          CultureA, CultureB

VARIABLES phase, demand, growthRate, growthRateNext,
          mergedDeficit, deficitA, deficitB,
          attenuation, resolutionRounds

vars == <<phase, demand, growthRate, growthRateNext,
          mergedDeficit, deficitA, deficitB,
          attenuation, resolutionRounds>>

Min(a, b) == IF a <= b THEN a ELSE b
Max(a, b) == IF a >= b THEN a ELSE b

Init ==
  /\ phase = "vulnerability"
  /\ demand = HiddenA + HiddenB
  /\ growthRate = FailureDims - 1 - Min(ContextT, FailureDims - 1)
  /\ growthRateNext = FailureDims - 1 - Min(ContextT1, FailureDims - 1)
  /\ deficitA = ComplexityG - 1 - Min(ContextGA, ComplexityG - 1)
  /\ deficitB = ComplexityG - 1 - Min(ContextGB, ComplexityG - 1)
  /\ mergedDeficit = ComplexityG - 1 - Min(Max(ContextGA, ContextGB), ComplexityG - 1)
  /\ attenuation = ModesAlone - ModesWith
  /\ resolutionRounds = CultureA + CultureB - 1

VulnerabilityStep ==
  /\ phase = "vulnerability"
  /\ phase' = "curvature"
  /\ UNCHANGED <<demand, growthRate, growthRateNext, mergedDeficit,
                  deficitA, deficitB, attenuation, resolutionRounds>>

CurvatureStep ==
  /\ phase = "curvature"
  /\ phase' = "merge"
  /\ UNCHANGED <<demand, growthRate, growthRateNext, mergedDeficit,
                  deficitA, deficitB, attenuation, resolutionRounds>>

MergeStep ==
  /\ phase = "merge"
  /\ phase' = "molecular"
  /\ UNCHANGED <<demand, growthRate, growthRateNext, mergedDeficit,
                  deficitA, deficitB, attenuation, resolutionRounds>>

MolecularStep ==
  /\ phase = "molecular"
  /\ phase' = "cultural"
  /\ UNCHANGED <<demand, growthRate, growthRateNext, mergedDeficit,
                  deficitA, deficitB, attenuation, resolutionRounds>>

CulturalStep ==
  /\ phase = "cultural"
  /\ phase' = "vulnerability"
  /\ UNCHANGED <<demand, growthRate, growthRateNext, mergedDeficit,
                  deficitA, deficitB, attenuation, resolutionRounds>>

Stutter == UNCHANGED vars

Next == VulnerabilityStep \/ CurvatureStep \/ MergeStep
     \/ MolecularStep \/ CulturalStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* P162: Demand is non-negative
InvDemandNonneg == demand >= 0

\* P162: Zero demand ↔ no hidden (structural)
InvDemandZeroIffNoHidden ==
  (demand = 0) <=> (HiddenA = 0 /\ HiddenB = 0)

\* P163: Growth rate at t+1 ≤ growth rate at t
InvCurvatureMonotone ==
  (ContextT <= ContextT1) => (growthRateNext <= growthRate)

\* P164: Merged deficit ≤ both local deficits
InvMergedLeBoth ==
  mergedDeficit <= deficitA /\ mergedDeficit <= deficitB

\* P165: Attenuation non-negative
InvAttenuationNonneg == attenuation >= 0

\* P165: Attenuation bounded
InvAttenuationBounded == attenuation <= ModesAlone

\* P166: Resolution rounds positive
InvResolutionPositive == resolutionRounds >= 1

=============================================================================
