------------------------------ MODULE PredictionsRound11 ------------------------------
(*
  Predictions Round 11: Student Learning Curves, Herd Immunity,
  Code Review, Battery Degradation, Brainstorming Quality.
*)
EXTENDS Naturals

CONSTANTS TotalTopics, FailedQuizzes,
          TotalPop, ImmuneCount,
          Reviewers,
          InitialCapacity, DegradationEvents,
          TotalIdeas, RejectedIdeas

VARIABLES phase, currentFailures, learningStrength,
          susceptibilityDeficit, immuneWeight,
          reviewDeficit,
          currentDegradation, remainingCapacity,
          ideaQuality

vars == <<phase, currentFailures, learningStrength,
          susceptibilityDeficit, immuneWeight,
          reviewDeficit,
          currentDegradation, remainingCapacity,
          ideaQuality>>

Min(a, b) == IF a <= b THEN a ELSE b

Init ==
  /\ phase = "learning"
  /\ currentFailures = 0
  /\ learningStrength = TotalTopics - Min(0, TotalTopics) + 1
  /\ susceptibilityDeficit = TotalPop - ImmuneCount
  /\ immuneWeight = ImmuneCount + 1
  /\ reviewDeficit = Reviewers - 1
  /\ currentDegradation = 0
  /\ remainingCapacity = InitialCapacity - Min(0, InitialCapacity) + 1
  /\ ideaQuality = TotalIdeas - Min(RejectedIdeas, TotalIdeas) + 1

\* P137: Quiz failure step (failed quiz = void boundary entry)
QuizFailStep ==
  /\ phase = "learning"
  /\ currentFailures < TotalTopics
  /\ currentFailures' = currentFailures + 1
  /\ learningStrength' = TotalTopics - Min(currentFailures + 1, TotalTopics) + 1
  /\ phase' = "epidemic"
  /\ UNCHANGED <<susceptibilityDeficit, immuneWeight, reviewDeficit,
                  currentDegradation, remainingCapacity, ideaQuality>>

\* P138-P141: Cycle through remaining phases
EpidemicStep ==
  /\ phase = "epidemic"
  /\ phase' = "review"
  /\ UNCHANGED <<currentFailures, learningStrength, susceptibilityDeficit,
                  immuneWeight, reviewDeficit, currentDegradation,
                  remainingCapacity, ideaQuality>>

ReviewStep ==
  /\ phase = "review"
  /\ phase' = "battery"
  /\ UNCHANGED <<currentFailures, learningStrength, susceptibilityDeficit,
                  immuneWeight, reviewDeficit, currentDegradation,
                  remainingCapacity, ideaQuality>>

\* P140: Battery degradation step (charge cycle = void entry)
BatteryDegradeStep ==
  /\ phase = "battery"
  /\ currentDegradation < InitialCapacity
  /\ currentDegradation' = currentDegradation + 1
  /\ remainingCapacity' = InitialCapacity - Min(currentDegradation + 1, InitialCapacity) + 1
  /\ phase' = "brainstorm"
  /\ UNCHANGED <<currentFailures, learningStrength, susceptibilityDeficit,
                  immuneWeight, reviewDeficit, ideaQuality>>

BatteryIdleStep ==
  /\ phase = "battery"
  /\ currentDegradation >= InitialCapacity
  /\ phase' = "brainstorm"
  /\ UNCHANGED <<currentFailures, learningStrength, susceptibilityDeficit,
                  immuneWeight, reviewDeficit, currentDegradation,
                  remainingCapacity, ideaQuality>>

BrainstormStep ==
  /\ phase = "brainstorm"
  /\ phase' = "learning"
  /\ UNCHANGED <<currentFailures, learningStrength, susceptibilityDeficit,
                  immuneWeight, reviewDeficit, currentDegradation,
                  remainingCapacity, ideaQuality>>

Stutter == UNCHANGED vars

Next == QuizFailStep \/ EpidemicStep \/ ReviewStep
     \/ BatteryDegradeStep \/ BatteryIdleStep \/ BrainstormStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* P137: Learning strength always positive (the sliver)
InvLearningPositive ==
  learningStrength >= 1

\* P137: Quiz failures bounded
InvFailuresBounded ==
  currentFailures <= TotalTopics

\* P138: Susceptibility deficit non-negative
InvSusceptibilityNonneg ==
  susceptibilityDeficit >= 0

\* P138: Immune weight positive (the sliver)
InvImmuneWeightPositive ==
  immuneWeight >= 1

\* P139: Review deficit non-negative
InvReviewDeficitNonneg ==
  reviewDeficit >= 0

\* P139: Review deficit exact (k - 1)
InvReviewDeficitExact ==
  reviewDeficit = Reviewers - 1

\* P140: Battery capacity always positive (the sliver)
InvBatteryPositive ==
  remainingCapacity >= 1

\* P140: Degradation bounded
InvDegradationBounded ==
  currentDegradation <= InitialCapacity

\* P141: Idea quality always positive (the sliver)
InvIdeaQualityPositive ==
  ideaQuality >= 1

=============================================================================
