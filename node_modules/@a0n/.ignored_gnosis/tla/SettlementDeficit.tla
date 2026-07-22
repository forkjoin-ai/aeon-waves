------------------------------ MODULE SettlementDeficit ------------------------------
EXTENDS Naturals

VARIABLE mode

vars == <<mode>>

Modes == {"seq", "parallel"}

Init == mode \in Modes
Next == mode' \in Modes
Spec == Init /\ [][Next]_vars

IntrinsicBeta1 == 2
ImplBeta1 == IF mode = "seq" THEN 0 ELSE 2
Deficit == IntrinsicBeta1 - ImplBeta1

InvSequentialDeficitIsTwo ==
  mode = "seq" => Deficit = 2

InvParallelDeficitIsZero ==
  mode = "parallel" => Deficit = 0

=============================================================================
