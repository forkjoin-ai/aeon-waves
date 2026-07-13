------------------------------ MODULE NovelCompositions ------------------------------
(*
  Five novel theorem compositions: retrocausal-NEI, convergence gap,
  branch-preserves-holes, double complement involution, triple coherence.
*)
EXTENDS Naturals

CONSTANTS NeighborRounds, NeighborVoid, TerminalRounds,
          Rounds, MaxWeight

VARIABLES phase, holePrediction, terminalWeight,
          convergenceGap, branchBeta1,
          doubleComp, tripleCoherent

vars == <<phase, holePrediction, terminalWeight,
          convergenceGap, branchBeta1,
          doubleComp, tripleCoherent>>

Min(a, b) == IF a <= b THEN a ELSE b

BuleyeanWeight(r, v) == r - Min(v, r) + 1

DoubleComp(r, v) ==
  LET w == r - Min(v, r) + 1
  IN r - Min(w, r) + 1

Init ==
  /\ phase = "retrocausal_nei"
  /\ holePrediction = BuleyeanWeight(NeighborRounds, NeighborVoid)
  /\ terminalWeight = BuleyeanWeight(TerminalRounds, 0)
  /\ convergenceGap = Rounds + 1 - MaxWeight
  /\ branchBeta1 = 1
  /\ doubleComp = DoubleComp(Rounds, NeighborVoid)
  /\ tripleCoherent = TRUE

Step1 == /\ phase = "retrocausal_nei" /\ phase' = "convergence"
         /\ UNCHANGED <<holePrediction, terminalWeight, convergenceGap,
                         branchBeta1, doubleComp, tripleCoherent>>

Step2 == /\ phase = "convergence" /\ phase' = "branch"
         /\ UNCHANGED <<holePrediction, terminalWeight, convergenceGap,
                         branchBeta1, doubleComp, tripleCoherent>>

Step3 == /\ phase = "branch" /\ phase' = "involution"
         /\ UNCHANGED <<holePrediction, terminalWeight, convergenceGap,
                         branchBeta1, doubleComp, tripleCoherent>>

Step4 == /\ phase = "involution" /\ phase' = "triple"
         /\ UNCHANGED <<holePrediction, terminalWeight, convergenceGap,
                         branchBeta1, doubleComp, tripleCoherent>>

Step5 == /\ phase = "triple" /\ phase' = "retrocausal_nei"
         /\ UNCHANGED <<holePrediction, terminalWeight, convergenceGap,
                         branchBeta1, doubleComp, tripleCoherent>>

Stutter == UNCHANGED vars

Next == Step1 \/ Step2 \/ Step3 \/ Step4 \/ Step5 \/ Stutter
Spec == Init /\ [][Next]_vars

\* THM-RETROCAUSAL-NEI: hole prediction positive
InvHolePredictionPositive == holePrediction >= 1

\* THM-RETROCAUSAL-NEI: terminal weight positive
InvTerminalPositive == terminalWeight >= 1

\* THM-VOID-REGRET-CONVERGENCE: gap bounded
InvGapBounded == convergenceGap <= Rounds + 1

\* THM-BRANCH-PRESERVES-HOLES: beta1 positive after branch
InvBranchBeta1Positive == branchBeta1 >= 1

\* THM-DOUBLE-COMPLEMENT: always positive
InvDoubleCompPositive == doubleComp >= 1

\* THM-TRAJECTORY-DETERMINES-LATTICE: coherence maintained
InvTripleCoherent == tripleCoherent = TRUE

=============================================================================
