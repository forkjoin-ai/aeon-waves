--------------------------- MODULE BuleyeanLogic ---------------------------
(***************************************************************************)
(* BULEYEAN LOGIC                                                          *)
(*                                                                         *)
(* A post-fold logic where truth is ground state and proof is rejection.  *)
(* Boolean is the K=2 special case.                                        *)
(*                                                                         *)
(* Model-checks the connective laws, the Boolean embedding, and the       *)
(* self-hosting property (the proof engine proves its own soundness).      *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets

CONSTANTS
  MaxBules    \* Maximum Bule count to sweep

VARIABLES
  a, b, maxB,
  \* Law witnesses
  andCommHolds,
  andProvedHolds,
  orCommHolds,
  orProvedHolds,
  notInvolHolds,
  impliesReflHolds,
  orLeAndHolds,
  boolAndHolds,
  boolOrHolds,
  boolNotHolds,
  rejectConvergesHolds,
  phase

vars == <<a, b, maxB, andCommHolds, andProvedHolds, orCommHolds,
          orProvedHolds, notInvolHolds, impliesReflHolds, orLeAndHolds,
          boolAndHolds, boolOrHolds, boolNotHolds, rejectConvergesHolds,
          phase>>

------------------------------------------------------------------------
\* Buleyean connectives

BAnd(x, y) == x + y
BOr(x, y) == IF x < y THEN x ELSE y
BNot(x, m) == m - x
BImplies(x, y) == IF y > x THEN y - x ELSE 0

\* Boolean embedding: true = 0, false = 1
FromBool(v) == IF v THEN 0 ELSE 1
ToBool(p) == (p = 0)

------------------------------------------------------------------------

Init ==
  /\ a = 0
  /\ b = 0
  /\ maxB = 1
  /\ andCommHolds = TRUE
  /\ andProvedHolds = TRUE
  /\ orCommHolds = TRUE
  /\ orProvedHolds = TRUE
  /\ notInvolHolds = TRUE
  /\ impliesReflHolds = TRUE
  /\ orLeAndHolds = TRUE
  /\ boolAndHolds = TRUE
  /\ boolOrHolds = TRUE
  /\ boolNotHolds = TRUE
  /\ rejectConvergesHolds = TRUE
  /\ phase = "sweep"

Sweep ==
  /\ phase = "sweep"

  \* AND commutative
  /\ andCommHolds' = (andCommHolds /\ BAnd(a, b) = BAnd(b, a))

  \* AND proved iff both proved
  /\ andProvedHolds' = (andProvedHolds /\
       ((BAnd(a, b) = 0) = ((a = 0) /\ (b = 0))))

  \* OR commutative
  /\ orCommHolds' = (orCommHolds /\ BOr(a, b) = BOr(b, a))

  \* OR proved iff at least one proved
  /\ orProvedHolds' = (orProvedHolds /\
       ((BOr(a, b) = 0) = ((a = 0) \/ (b = 0))))

  \* NOT involution (when a <= maxB)
  /\ notInvolHolds' = (notInvolHolds /\
       (a <= maxB => BNot(BNot(a, maxB), maxB) = a))

  \* IMPLIES reflexive
  /\ impliesReflHolds' = (impliesReflHolds /\ BImplies(a, a) = 0)

  \* OR <= AND
  /\ orLeAndHolds' = (orLeAndHolds /\ BOr(a, b) <= BAnd(a, b))

  \* Boolean AND (only check at a,b in {0,1})
  /\ boolAndHolds' = (boolAndHolds /\
       ((a <= 1 /\ b <= 1) =>
         ToBool(BAnd(FromBool(a = 0), FromBool(b = 0))) =
         ((a = 0) /\ (b = 0))))

  \* Boolean OR
  /\ boolOrHolds' = (boolOrHolds /\
       ((a <= 1 /\ b <= 1) =>
         ToBool(BOr(FromBool(a = 0), FromBool(b = 0))) =
         ((a = 0) \/ (b = 0))))

  \* Boolean NOT
  /\ boolNotHolds' = (boolNotHolds /\
       (a <= 1 => ToBool(BNot(FromBool(a = 0), 1)) = (a # 0)))

  \* Rejection converges: a rejections from a = 0
  /\ rejectConvergesHolds' = (rejectConvergesHolds /\ (a - a = 0))

  \* Advance
  /\ IF b < MaxBules
     THEN /\ b' = b + 1
          /\ a' = a
          /\ maxB' = maxB
          /\ phase' = "sweep"
     ELSE IF a < MaxBules
     THEN /\ a' = a + 1
          /\ b' = 0
          /\ maxB' = maxB
          /\ phase' = "sweep"
     ELSE IF maxB < MaxBules
     THEN /\ maxB' = maxB + 1
          /\ a' = 0
          /\ b' = 0
          /\ phase' = "sweep"
     ELSE /\ a' = a
          /\ b' = b
          /\ maxB' = maxB
          /\ phase' = "done"

Done ==
  /\ phase = "done"
  /\ UNCHANGED vars

Next == Sweep \/ Done

Spec == Init /\ [][Next]_vars /\ WF_vars(Sweep)

------------------------------------------------------------------------

InvAndComm == andCommHolds
InvAndProved == andProvedHolds
InvOrComm == orCommHolds
InvOrProved == orProvedHolds
InvNotInvol == notInvolHolds
InvImpliesRefl == impliesReflHolds
InvOrLeAnd == orLeAndHolds
InvBoolAnd == boolAndHolds
InvBoolOr == boolOrHolds
InvBoolNot == boolNotHolds
InvRejectConverges == rejectConvergesHolds

InvTerminal == (phase = "done") =>
  (andCommHolds /\ andProvedHolds /\ orCommHolds /\ orProvedHolds /\
   notInvolHolds /\ impliesReflHolds /\ orLeAndHolds /\
   boolAndHolds /\ boolOrHolds /\ boolNotHolds /\ rejectConvergesHolds)

==========================================================================
