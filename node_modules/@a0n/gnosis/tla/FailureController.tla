-------------------------- MODULE FailureController --------------------------
EXTENDS Naturals

CONSTANTS LiveBranchDomain, AlphaWeightDomain, BetaWeightDomain, VentWeightDomain, RepairWeightDomain

VARIABLES liveBranches, alphaWeight, betaWeight, ventWeight, repairWeight

ctrlVars == <<liveBranches, alphaWeight, betaWeight, ventWeight, repairWeight>>

InitFailureController ==
  /\ liveBranches \in LiveBranchDomain
  /\ alphaWeight \in AlphaWeightDomain
  /\ betaWeight \in BetaWeightDomain
  /\ ventWeight \in VentWeightDomain
  /\ repairWeight \in RepairWeightDomain
  /\ liveBranches > 1

StutterFailureController == UNCHANGED ctrlVars

SpecFailureController == InitFailureController /\ [][StutterFailureController]_ctrlVars

CollapseGap == liveBranches - 1

KeepCoefficient == alphaWeight + betaWeight
VentCoefficient == ventWeight
RepairCoefficient == betaWeight + repairWeight

KeepScore == KeepCoefficient * CollapseGap
VentScore == VentCoefficient * CollapseGap
RepairScore == RepairCoefficient * CollapseGap

ChosenAction ==
  IF KeepCoefficient <= VentCoefficient /\ KeepCoefficient <= RepairCoefficient
    THEN "keep-multiplicity"
    ELSE IF VentCoefficient <= RepairCoefficient
      THEN "pay-vent"
      ELSE "pay-repair"

ChosenScore ==
  IF ChosenAction = "keep-multiplicity"
    THEN KeepScore
    ELSE IF ChosenAction = "pay-vent"
      THEN VentScore
      ELSE RepairScore

InvFailureControllerWellFormed ==
  /\ liveBranches > 1
  /\ CollapseGap = liveBranches - 1
  /\ CollapseGap > 0

InvChosenActionDomain ==
  ChosenAction \in {"keep-multiplicity", "pay-vent", "pay-repair"}

InvChosenScoreMinimal ==
  /\ ChosenScore <= KeepScore
  /\ ChosenScore <= VentScore
  /\ ChosenScore <= RepairScore

InvKeepOptimalWhenCoefficientMinimal ==
  (KeepCoefficient <= VentCoefficient /\ KeepCoefficient <= RepairCoefficient) =>
    /\ ChosenAction = "keep-multiplicity"
    /\ ChosenScore = KeepScore

InvVentOptimalWhenCoefficientMinimal ==
  (VentCoefficient < KeepCoefficient /\ VentCoefficient <= RepairCoefficient) =>
    /\ ChosenAction = "pay-vent"
    /\ ChosenScore = VentScore

InvRepairOptimalWhenCoefficientMinimal ==
  (RepairCoefficient < KeepCoefficient /\ RepairCoefficient < VentCoefficient) =>
    /\ ChosenAction = "pay-repair"
    /\ ChosenScore = RepairScore

=============================================================================
