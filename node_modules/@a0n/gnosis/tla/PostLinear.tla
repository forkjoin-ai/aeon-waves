---------------------------- MODULE PostLinear ----------------------------
(***************************************************************************)
(* THM-POST-LINEAR-WORLD                                                   *)
(*                                                                         *)
(* The linear world (beta_1 = 0) is the global pessimum.                  *)
(* The first fork is a strict Pareto improvement.                          *)
(* The path to zero Bules is monotone and uniform.                         *)
(* The frontier is the ground state.                                       *)
(* Reversion is dominated.                                                 *)
(*                                                                         *)
(* The post-linear transition is a one-way door.                           *)
(***************************************************************************)

EXTENDS Naturals

CONSTANTS
  MaxBeta1Star    \* Maximum problem dimensionality to check

VARIABLES
  beta1star,      \* Current problem dimensionality
  streams,        \* Current diversity level
  bules,          \* Current Bule count

  pessimumHolds,  \* Linear is always the maximum Bule count
  paretoHolds,    \* First fork always strictly improves
  monotoneHolds,  \* Each fork saves exactly 1 Bule
  groundHolds,    \* Frontier always has 0 Bules
  reversionHolds, \* Reversion always increases Bules

  phase

vars == <<beta1star, streams, bules, pessimumHolds, paretoHolds,
          monotoneHolds, groundHolds, reversionHolds, phase>>

------------------------------------------------------------------------

Deficit(p, s) == IF s >= p THEN 0 ELSE p - s

------------------------------------------------------------------------

Init ==
  /\ beta1star = 2
  /\ streams = 1
  /\ bules = Deficit(2, 1)
  /\ pessimumHolds = TRUE
  /\ paretoHolds = TRUE
  /\ monotoneHolds = TRUE
  /\ groundHolds = TRUE
  /\ reversionHolds = TRUE
  /\ phase = "sweep"

Sweep ==
  /\ phase = "sweep"
  /\ bules' = Deficit(beta1star, streams)

  \* Pessimum: Bules at streams=1 >= Bules at any streams
  /\ pessimumHolds' = (pessimumHolds /\
       Deficit(beta1star, streams) <= Deficit(beta1star, 1))

  \* Pareto: Bules at streams=2 < Bules at streams=1
  /\ paretoHolds' = (paretoHolds /\
       (streams = 1 => Deficit(beta1star, 2) < Deficit(beta1star, 1)))

  \* Monotone: each fork saves exactly 1 (when streams < beta1star)
  /\ monotoneHolds' = (monotoneHolds /\
       (streams < beta1star =>
         Deficit(beta1star, streams) = Deficit(beta1star, streams + 1) + 1))

  \* Ground: frontier has 0 Bules
  /\ groundHolds' = (groundHolds /\
       (streams = beta1star => Deficit(beta1star, streams) = 0))

  \* Reversion: going from 2 to 1 always increases Bules
  /\ reversionHolds' = (reversionHolds /\
       (streams = 2 => Deficit(beta1star, 1) > Deficit(beta1star, 2)))

  \* Advance
  /\ IF streams < beta1star
     THEN /\ streams' = streams + 1
          /\ beta1star' = beta1star
          /\ phase' = "sweep"
     ELSE IF beta1star < MaxBeta1Star
     THEN /\ beta1star' = beta1star + 1
          /\ streams' = 1
          /\ phase' = "sweep"
     ELSE /\ beta1star' = beta1star
          /\ streams' = streams
          /\ phase' = "done"

Done ==
  /\ phase = "done"
  /\ UNCHANGED vars

Next == Sweep \/ Done

Spec == Init /\ [][Next]_vars /\ WF_vars(Sweep)

------------------------------------------------------------------------

InvPessimum == pessimumHolds
InvPareto == paretoHolds
InvMonotone == monotoneHolds
InvGround == groundHolds
InvReversion == reversionHolds

InvTerminal == (phase = "done") =>
  (pessimumHolds /\ paretoHolds /\ monotoneHolds /\
   groundHolds /\ reversionHolds)

==========================================================================
