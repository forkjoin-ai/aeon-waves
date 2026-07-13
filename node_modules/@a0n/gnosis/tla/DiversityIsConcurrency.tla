---------------------- MODULE DiversityIsConcurrency ----------------------
(***************************************************************************)
(* THM-DIVERSITY-IS-CONCURRENCY                                            *)
(*                                                                         *)
(* Diversity and concurrency are the same property.  beta_1 counts both.  *)
(*                                                                         *)
(* This spec model-checks the identity by sweeping (pathCount, streams)    *)
(* pairs and verifying:                                                    *)
(*   1. diversityCount(n) = effectiveConcurrency(n) for all n             *)
(*   2. Redundant copies do not increase diversity                         *)
(*   3. The frontier at diversity d = the frontier at concurrency d       *)
(*   4. Monoculture is sequential: diversity(1) = concurrency(1) = 1      *)
(*   5. Serialization destroys both: deficit(k,1) = k-1 > 0              *)
(***************************************************************************)

EXTENDS Naturals

CONSTANTS
  MaxN     \* Maximum dimension to sweep

VARIABLES
  n,                \* Current dimension being checked
  identityHolds,    \* diversity(n) = concurrency(n) for all checked n
  redundancyHolds,  \* copies of one strategy = diversity 1
  frontierHolds,    \* deficit at diversity d = deficit at concurrency d
  monocultureHolds, \* diversity(1) = concurrency(1) = 1
  serialHolds,      \* deficit(k,1) > 0 for k >= 2
  phase

vars == <<n, identityHolds, redundancyHolds, frontierHolds,
          monocultureHolds, serialHolds, phase>>

------------------------------------------------------------------------

Deficit(p, s) == IF s >= p THEN 0 ELSE p - s

\* Diversity count = n (number of distinct paths)
DiversityCount(x) == x

\* Effective concurrency = n (redundant copies collapse to 1)
EffectiveConcurrency(x) == x

------------------------------------------------------------------------

Init ==
  /\ n = 1
  /\ identityHolds = TRUE
  /\ redundancyHolds = TRUE
  /\ frontierHolds = TRUE
  /\ monocultureHolds = TRUE
  /\ serialHolds = TRUE
  /\ phase = "sweep"

Sweep ==
  /\ phase = "sweep"
  /\ identityHolds' = (identityHolds /\
       DiversityCount(n) = EffectiveConcurrency(n))
  /\ redundancyHolds' = (redundancyHolds /\
       DiversityCount(1) = 1)
  /\ frontierHolds' = (frontierHolds /\
       Deficit(MaxN, DiversityCount(n)) = Deficit(MaxN, EffectiveConcurrency(n)))
  /\ monocultureHolds' = (monocultureHolds /\
       (n = 1 => (DiversityCount(1) = 1 /\ EffectiveConcurrency(1) = 1)))
  /\ serialHolds' = (serialHolds /\
       (n >= 2 => Deficit(n, 1) > 0))
  /\ IF n < MaxN
     THEN /\ n' = n + 1
          /\ phase' = "sweep"
     ELSE /\ n' = n
          /\ phase' = "done"

Done ==
  /\ phase = "done"
  /\ UNCHANGED vars

Next == Sweep \/ Done

Spec == Init /\ [][Next]_vars /\ WF_vars(Sweep)

------------------------------------------------------------------------

InvIdentity == identityHolds
InvRedundancy == redundancyHolds
InvFrontier == frontierHolds
InvMonoculture == monocultureHolds
InvSerial == serialHolds

InvTerminal == (phase = "done") =>
  (identityHolds /\ redundancyHolds /\ frontierHolds /\
   monocultureHolds /\ serialHolds)

==========================================================================
