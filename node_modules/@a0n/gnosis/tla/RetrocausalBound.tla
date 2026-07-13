------------------------------ MODULE RetrocausalBound ------------------------------
EXTENDS Naturals, Sequences, FiniteSets

\* THM-RETROCAUSAL-BOUND: A converged void boundary statistically bounds
\* the rejection trajectory that produced it. The terminal state constrains
\* the past: rejection counts are exact, ordering is preserved, and
\* trajectory multiplicity is bounded by the multinomial coefficient.

CONSTANTS NumChoices, MaxRounds

VARIABLES round, voidBoundary, trajectory, phase

vars == <<round, voidBoundary, trajectory, phase>>

Choices == NumChoices

CountInSeq(seq, val) ==
  LET RECURSIVE Helper(_, _)
      Helper(s, acc) ==
        IF s = <<>> THEN acc
        ELSE IF Head(s) = val THEN Helper(Tail(s), acc + 1)
        ELSE Helper(Tail(s), acc)
  IN Helper(seq, 0)

Factorial(n) ==
  LET RECURSIVE F(_)
      F(k) == IF k <= 1 THEN 1 ELSE k * F(k - 1)
  IN F(n)

BoundaryTotal ==
  LET RECURSIVE SumOver(_, _)
      SumOver(S, acc) ==
        IF S = {} THEN acc
        ELSE LET c == CHOOSE x \in S : TRUE
             IN SumOver(S \ {c}, acc + voidBoundary[c])
  IN SumOver(Choices, 0)

MultinomialDenominator ==
  LET RECURSIVE ProdOver(_, _)
      ProdOver(S, acc) ==
        IF S = {} THEN acc
        ELSE LET c == CHOOSE x \in S : TRUE
             IN ProdOver(S \ {c}, acc * Factorial(voidBoundary[c]))
  IN ProdOver(Choices, 1)

Init ==
  /\ round = 0
  /\ voidBoundary = [c \in Choices |-> 0]
  /\ trajectory = <<>>
  /\ phase = "forward"

RejectChoice(c) ==
  /\ phase = "forward"
  /\ c \in Choices
  /\ round < MaxRounds
  /\ voidBoundary' = [voidBoundary EXCEPT ![c] = @ + 1]
  /\ trajectory' = Append(trajectory, c)
  /\ round' = round + 1
  /\ phase' = "forward"

CompleteForward ==
  /\ phase = "forward"
  /\ round = MaxRounds
  /\ phase' = "verify"
  /\ UNCHANGED <<round, voidBoundary, trajectory>>

Stutter == UNCHANGED vars

Next ==
  \/ \E c \in Choices : RejectChoice(c)
  \/ CompleteForward
  \/ Stutter

Spec == Init /\ [][Next]_vars

InvBoundaryMatchesTrajectory ==
  \A c \in Choices : voidBoundary[c] = CountInSeq(trajectory, c)

InvBoundaryBoundsTrajectory ==
  phase = "verify" => BoundaryTotal = round

InvOrderingPreserved ==
  \A i \in Choices : \A j \in Choices :
    voidBoundary[i] < voidBoundary[j]
    => CountInSeq(trajectory, i) < CountInSeq(trajectory, j)

InvTrajectoryMultiplicity ==
  phase = "verify" =>
    MultinomialDenominator > 0
    /\ Factorial(round) >= MultinomialDenominator

InvRoundBounded ==
  round <= MaxRounds

InvRetrocausalBound ==
  /\ InvBoundaryMatchesTrajectory
  /\ InvBoundaryBoundsTrajectory
  /\ InvOrderingPreserved
  /\ InvTrajectoryMultiplicity
  /\ InvRoundBounded

PropEventuallyVerified == <>(phase = "verify")

=============================================================================
