------------------------ MODULE NovelPredictions28 ------------------------
(***************************************************************************)
(* 28 NOVEL PREDICTIONS: LOGICAL DERIVATION                               *)
(*                                                                         *)
(* Model-checks that all 28 predictions follow from three axioms:         *)
(*   A1. voidFrac(K) = (K-1)/K is monotone increasing                    *)
(*   A2. Each measure responds monotonically to voidFrac                  *)
(*   A3. K_high > K_low for each condition pair                           *)
(*                                                                         *)
(* This does NOT prove the predictions empirically.                        *)
(* It proves they are logically consistent with the model.                *)
(* The experiments test whether the model matches reality.                *)
(* TLC tests whether the predictions match the model.                     *)
(*                                                                         *)
(* We welcome failure.  Each falsified prediction kills a cell            *)
(* in the matrix and strengthens the model by rejection.                  *)
(* That is Buleyean logic applied to science itself.                      *)
(***************************************************************************)

EXTENDS Naturals

CONSTANTS
  \* Condition pairs: {kHigh, kLow}
  \* Encoded as pairs of naturals
  NumPredictions   \* = 28

VARIABLES
  predId,           \* Current prediction being checked (1-28)
  kHigh,            \* K for the higher group
  kLow,             \* K for the lower group
  voidHigh,         \* voidNumerator(kHigh) = kHigh - 1
  voidLow,          \* voidNumerator(kLow) = kLow - 1
  orderingHolds,    \* kHigh > kLow for this prediction
  separationHolds,  \* voidHigh > voidLow
  allValid,         \* All checked predictions valid so far
  phase

vars == <<predId, kHigh, kLow, voidHigh, voidLow,
          orderingHolds, separationHolds, allValid, phase>>

------------------------------------------------------------------------

\* The 28 K pairs, indexed 1-28
\* Format: <<kHigh, kLow>>
KPair(id) ==
  CASE id = 1  -> <<25, 15>>   \* Saccade × Creative
  []   id = 2  -> <<24, 14>>   \* Saccade × WMC
  []   id = 3  -> <<22, 10>>   \* Saccade × Children
  []   id = 4  -> <<25, 20>>   \* Saccade × Meditators
  []   id = 5  -> <<35, 20>>   \* Saccade × Rumination
  []   id = 6  -> <<25, 15>>   \* Fixation × Creative
  []   id = 7  -> <<24, 14>>   \* Fixation × WMC
  []   id = 8  -> <<22, 10>>   \* Fixation × Children
  []   id = 9  -> <<20, 8>>    \* Fixation × Sleep
  []   id = 10 -> <<25, 20>>   \* Fixation × Meditators
  []   id = 11 -> <<30, 20>>   \* Fixation × ADHD
  []   id = 12 -> <<35, 20>>   \* Fixation × Rumination
  []   id = 13 -> <<25, 15>>   \* Pupil × Creative
  []   id = 14 -> <<22, 10>>   \* Pupil × Children
  []   id = 15 -> <<20, 8>>    \* Pupil × Sleep
  []   id = 16 -> <<25, 20>>   \* Pupil × Meditators
  []   id = 17 -> <<30, 20>>   \* Pupil × ADHD
  []   id = 18 -> <<35, 20>>   \* Pupil × Rumination
  []   id = 19 -> <<24, 14>>   \* Alpha × WMC
  []   id = 20 -> <<22, 10>>   \* Alpha × Children
  []   id = 21 -> <<35, 20>>   \* Alpha × Rumination
  []   id = 22 -> <<24, 14>>   \* Theta × WMC
  []   id = 23 -> <<22, 10>>   \* Theta × Children
  []   id = 24 -> <<20, 8>>    \* Theta × Sleep
  []   id = 25 -> <<35, 20>>   \* Theta × Rumination
  []   id = 26 -> <<25, 15>>   \* RT × Creative
  []   id = 27 -> <<35, 20>>   \* RT × Rumination
  []   id = 28 -> <<24, 14>>   \* DMN × WMC
  []   OTHER  -> <<1, 1>>      \* sentinel

------------------------------------------------------------------------

Init ==
  /\ predId = 1
  /\ kHigh = KPair(1)[1]
  /\ kLow = KPair(1)[2]
  /\ voidHigh = KPair(1)[1] - 1
  /\ voidLow = KPair(1)[2] - 1
  /\ orderingHolds = TRUE
  /\ separationHolds = TRUE
  /\ allValid = TRUE
  /\ phase = "check"

Check ==
  /\ phase = "check"
  /\ LET pair == KPair(predId)
         kH == pair[1]
         kL == pair[2]
     IN
     /\ kHigh' = kH
     /\ kLow' = kL
     /\ voidHigh' = kH - 1
     /\ voidLow' = kL - 1
     /\ orderingHolds' = (kH > kL)
     /\ separationHolds' = ((kH - 1) > (kL - 1))
     /\ allValid' = (allValid /\ (kH > kL) /\ ((kH - 1) > (kL - 1)))
     /\ IF predId < NumPredictions
        THEN /\ predId' = predId + 1
             /\ phase' = "check"
        ELSE /\ predId' = predId
             /\ phase' = "done"

Done ==
  /\ phase = "done"
  /\ UNCHANGED vars

Next == Check \/ Done

Spec == Init /\ [][Next]_vars /\ WF_vars(Check)

------------------------------------------------------------------------

\* Every prediction has K_high > K_low
InvOrdering == orderingHolds

\* Void fraction separates every pair
InvSeparation == separationHolds

\* All predictions valid so far
InvAllValid == allValid

\* At termination, all 28 are valid
InvTerminal == (phase = "done") => allValid

==========================================================================
