------------------------------ MODULE QuantumDeficit ------------------------------
EXTENDS Naturals

CONSTANTS SqrtDomain

VARIABLE rootN

vars == <<rootN>>

Init ==
  /\ rootN \in SqrtDomain
  /\ rootN > 0

Change ==
  /\ rootN' \in SqrtDomain
  /\ rootN' > 0

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

N == rootN * rootN
ProblemBeta1 == rootN - 1
ClassicalBeta1 == 0
QuantumBeta1 == ProblemBeta1
ClassicalDeficit == ProblemBeta1 - ClassicalBeta1
QuantumDeficit == ProblemBeta1 - QuantumBeta1
SequentialRounds == N
ParallelRounds == rootN
Speedup == SequentialRounds \div ParallelRounds

InvPerfectSquare ==
  /\ N = rootN * rootN
  /\ rootN > 0

InvClassicalDeficit ==
  ClassicalDeficit = rootN - 1

InvQuantumDeficitZero ==
  QuantumDeficit = 0

InvSpeedupIdentity == Speedup = ClassicalDeficit + 1

=============================================================================
