--------------------------- MODULE WarmupController ---------------------------
EXTENDS WarmupEfficiency, Naturals

CONSTANTS UnderDeficitDomain, OverDeficitDomain, DeficitWeightDomain, ShedPenaltyDomain

VARIABLES underDeficit, overDeficit, deficitWeight, shedPenalty

ctrlVars == <<vars, underDeficit, overDeficit, deficitWeight, shedPenalty>>

InitController ==
  /\ Init
  /\ underDeficit \in UnderDeficitDomain
  /\ overDeficit \in OverDeficitDomain
  /\ deficitWeight \in DeficitWeightDomain
  /\ shedPenalty \in ShedPenaltyDomain
  /\ deficitWeight > 0
  /\ shedPenalty > 0
  /\ underDeficit = 0 \/ overDeficit = 0
  /\ underDeficit + overDeficit > 0

StutterController == UNCHANGED ctrlVars

SpecController == InitController /\ [][StutterController]_ctrlVars

TotalDeficit == underDeficit + overDeficit

ExpandResidual ==
  IF underDeficit > 0
    THEN (underDeficit - 1) + overDeficit
    ELSE TotalDeficit

ConstrainResidual ==
  IF overDeficit > 0
    THEN underDeficit + (overDeficit - 1)
    ELSE TotalDeficit

ShedResidual == TotalDeficit

ExpandScore == BurdenScalar + deficitWeight * ExpandResidual
ConstrainScore == BurdenScalar + deficitWeight * ConstrainResidual
ShedScore == deficitWeight * ShedResidual + shedPenalty

Redline == deficitWeight + shedPenalty

ChosenAction ==
  IF ExpandScore <= ConstrainScore /\ ExpandScore <= ShedScore
    THEN "expand"
    ELSE IF ConstrainScore <= ShedScore
      THEN "constrain"
      ELSE "shed-load"

ChosenScore ==
  IF ChosenAction = "expand"
    THEN ExpandScore
    ELSE IF ChosenAction = "constrain"
      THEN ConstrainScore
      ELSE ShedScore

InvControllerWellFormed ==
  /\ deficitWeight > 0
  /\ shedPenalty > 0
  /\ underDeficit = 0 \/ overDeficit = 0
  /\ TotalDeficit > 0

InvChosenActionDomain ==
  ChosenAction \in {"expand", "constrain", "shed-load"}

InvChosenScoreMinimal ==
  /\ ChosenScore <= ExpandScore
  /\ ChosenScore <= ConstrainScore
  /\ ChosenScore <= ShedScore

InvExpandBeatsConstrainWhenUnder ==
  underDeficit > 0 =>
    ExpandScore + deficitWeight = ConstrainScore

InvConstrainBeatsExpandWhenOver ==
  overDeficit > 0 =>
    ConstrainScore + deficitWeight = ExpandScore

InvExpandOptimalBelowRedline ==
  (/\ underDeficit > 0
   /\ BurdenScalar < Redline)
    =>
      /\ ExpandScore < ShedScore
      /\ ChosenAction = "expand"

InvConstrainOptimalBelowRedline ==
  (/\ overDeficit > 0
   /\ BurdenScalar < Redline)
    =>
      /\ ConstrainScore < ShedScore
      /\ ChosenAction = "constrain"

InvShedLoadOptimalAboveRedline ==
  BurdenScalar > Redline =>
    /\ ShedScore < ExpandScore
    /\ ShedScore < ConstrainScore
    /\ ChosenAction = "shed-load"

=============================================================================
