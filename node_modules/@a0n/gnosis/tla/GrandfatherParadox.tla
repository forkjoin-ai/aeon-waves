------------------------------ MODULE GrandfatherParadox ------------------------------
(*
  The Grandfather Paradox as Self-Referential Deficit.

  A causal chain has events: ancestor -> ... -> time traveler.
  The traveler attempts a self-referential fold: eliminate the
  ancestor, which would eliminate the traveler, which would
  prevent the elimination, ad infinitum.

  Resolution: the void boundary is append-only. No event's weight
  can reach zero (the sliver). The paradox is an algebraically
  impossible operation. The Many-Worlds "resolution" is a fork
  (beta1 increases), not a fold (beta1 decreases).
*)
EXTENDS Naturals

CONSTANTS ChainLength

VARIABLES phase, ancestorWeight, travelerWeight,
          beta1, branchCount, paradoxAttempted

vars == <<phase, ancestorWeight, travelerWeight,
          beta1, branchCount, paradoxAttempted>>

\* ─── Initial state: causal chain exists ──────────────────────────────

Init ==
  /\ phase = "stable"
  /\ ancestorWeight = 1  \* Positive: ancestor exists
  /\ travelerWeight = 1  \* Positive: traveler exists
  /\ beta1 = 0           \* Single timeline (path graph)
  /\ branchCount = 1     \* One branch (the original timeline)
  /\ paradoxAttempted = FALSE

\* ─── AttemptParadox: traveler tries to eliminate ancestor ────────────

AttemptParadox ==
  /\ phase = "stable"
  /\ travelerWeight > 0  \* Traveler must exist to act
  /\ paradoxAttempted' = TRUE
  /\ phase' = "paradox_attempted"
  \* The paradox CANNOT reduce ancestor weight below 1 (the sliver)
  /\ ancestorWeight' = ancestorWeight  \* Weight is preserved!
  /\ travelerWeight' = travelerWeight  \* Traveler still exists!
  /\ UNCHANGED <<beta1, branchCount>>

\* ─── Branch: Many-Worlds resolution (fork, not fold) ─────────────────

Branch ==
  /\ phase = "paradox_attempted"
  /\ phase' = "branched"
  /\ beta1' = beta1 + 1          \* New cycle in causal graph
  /\ branchCount' = branchCount + 1  \* New timeline
  \* Original chain preserved
  /\ ancestorWeight' = ancestorWeight
  /\ travelerWeight' = travelerWeight
  /\ UNCHANGED paradoxAttempted

\* ─── Reset: return to stable (for model checking) ───────────────────

Reset ==
  /\ phase = "branched"
  /\ phase' = "stable"
  /\ paradoxAttempted' = FALSE
  /\ UNCHANGED <<ancestorWeight, travelerWeight, beta1, branchCount>>

Stutter == UNCHANGED vars

Next == AttemptParadox \/ Branch \/ Reset \/ Stutter
Spec == Init /\ [][Next]_vars

\* ─── Invariants ───────────────────────────────────────────────────────

\* The sliver: ancestor weight is always positive
InvAncestorAlive ==
  ancestorWeight > 0

\* The sliver: traveler weight is always positive
InvTravelerAlive ==
  travelerWeight > 0

\* No annihilation: weights never reach zero
InvNoAnnihilation ==
  ancestorWeight >= 1 /\ travelerWeight >= 1

\* Beta1 is non-negative (no negative cycles)
InvBeta1NonNeg ==
  beta1 >= 0

\* Branch count is always positive (at least original timeline)
InvBranchPositive ==
  branchCount >= 1

\* Branching only increases beta1 (fork, not fold)
InvBranchingMonotone ==
  phase = "branched" => beta1 > 0

\* Conservation: the paradox does not destroy events
InvConservation ==
  ancestorWeight = 1 /\ travelerWeight = 1

=============================================================================
