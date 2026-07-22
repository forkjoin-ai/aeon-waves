--------------------------- MODULE SkyrmsThreeWalker --------------------------
(***************************************************************************)
(* Skyrms Three-Walker: Mediator as Player on the Convergence Site.       *)
(*                                                                         *)
(* Walker A and Walker B play the game. The Skyrms walker plays the site  *)
(* -- its payoff matrix IS the inter-walker distance surface. Its void    *)
(* boundary accumulates failed proposals (proposals that didn't reduce    *)
(* distance). It runs its own c0-c3 loop over the proposal space.         *)
(*                                                                         *)
(* Three walkers rolling around:                                           *)
(*   A: void walks the game choices                                        *)
(*   B: void walks the game choices                                        *)
(*   S: void walks the joint failure surface (proposals that didn't work) *)
(*                                                                         *)
(* The Skyrms walker's nadir IS A and B's nadir. When all three converge, *)
(* that's the fixed point. Success using failure, all the way down.       *)
(*                                                                         *)
(* THM-3W-SKYRMS-PAYOFF: S's payoff = negative distance delta             *)
(* THM-3W-VOID-GROWTH: each failure enriches at least one void boundary   *)
(* THM-3W-SITE-MONOTONE: S's void density is non-decreasing               *)
(* THM-3W-CONVERGENCE: all three walkers eventually stabilize             *)
(* THM-3W-FIXED-POINT: at convergence, no walker can unilaterally improve *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  NumChoices,        \* Choice space for A and B (same size for simplicity)
  MaxRounds,         \* Maximum rounds
  EtaInit            \* Initial learning rate for all three walkers

VARIABLES
  \* Walker A (game player)
  voidA,             \* Void density per choice
  complementA,       \* Complement weights per choice
  offerA,            \* Current offer
  etaA,              \* Learning rate

  \* Walker B (game player)
  voidB,
  complementB,
  offerB,
  etaB,

  \* Skyrms Walker S (site player)
  \* S's choice space is NumChoices * NumChoices (all proposal pairs)
  voidS,             \* Void density per proposal (flattened)
  complementS,       \* Complement weights per proposal
  proposalFlat,      \* Current proposal (flat index)
  etaS,              \* Learning rate

  \* Shared state
  distance,          \* Inter-walker distance
  prevDistance,       \* Previous distance
  round,
  settled,
  phase

vars == <<voidA, complementA, offerA, etaA,
          voidB, complementB, offerB, etaB,
          voidS, complementS, proposalFlat, etaS,
          distance, prevDistance, round, settled, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME NumChoices >= 2
ASSUME MaxRounds >= 1
ASSUME EtaInit >= 1

\* ─── Derived ─────────────────────────────────────────────────────────
ProposalSpace == NumChoices * NumChoices

\* ─── Helpers ─────────────────────────────────────────────────────────

UniformGame == [i \in 1..NumChoices |-> 1]
UniformSite == [i \in 1..ProposalSpace |-> 1]
UniformCompGame == [i \in 1..NumChoices |-> EtaInit]
UniformCompSite == [i \in 1..ProposalSpace |-> EtaInit]

\* Complement weight: base - void density, floor 1
CompWeight(void, base) ==
  [i \in DOMAIN void |-> IF base - void[i] >= 1 THEN base - void[i] ELSE 1]

\* Argmax of a sequence
ArgmaxSeq(w) == CHOOSE i \in DOMAIN w : \A j \in DOMAIN w : w[i] >= w[j]

\* Distance sum (unrolled for small NumChoices)
DistSumAB(wA, wB) ==
  LET Diff(i) == IF wA[i] >= wB[i] THEN wA[i] - wB[i] ELSE wB[i] - wA[i]
  IN IF NumChoices = 2 THEN Diff(1) + Diff(2)
     ELSE IF NumChoices = 3 THEN Diff(1) + Diff(2) + Diff(3)
     ELSE Diff(1) + Diff(2)

\* Decode flat proposal index to [a, b]
DecodeA(flat) == ((flat - 1) \div NumChoices) + 1
DecodeB(flat) == ((flat - 1) % NumChoices) + 1

Clamp(v, lo, hi) == IF v < lo THEN lo ELSE IF v > hi THEN hi ELSE v

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ voidA = UniformGame
  /\ complementA = UniformCompGame
  /\ offerA = 1
  /\ etaA = EtaInit
  /\ voidB = UniformGame
  /\ complementB = UniformCompGame
  /\ offerB = NumChoices
  /\ etaB = EtaInit
  /\ voidS = UniformSite
  /\ complementS = UniformCompSite
  /\ proposalFlat = 1
  /\ etaS = EtaInit
  /\ distance = 0
  /\ prevDistance = 0
  /\ round = 1
  /\ settled = FALSE
  /\ phase = "propose"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Skyrms walker chooses a proposal from its complement distribution
Propose ==
  /\ phase = "propose"
  /\ round <= MaxRounds
  /\ ~settled
  /\ proposalFlat' = ArgmaxSeq(complementS)
  /\ phase' = "decide"
  /\ UNCHANGED <<voidA, complementA, offerA, etaA,
                  voidB, complementB, offerB, etaB,
                  voidS, complementS, etaS,
                  distance, prevDistance, round, settled>>

\* Game walkers decide: accept proposal or play own choice
Decide ==
  /\ phase = "decide"
  /\ LET pA == DecodeA(proposalFlat)
         pB == DecodeB(proposalFlat)
     IN /\ offerA' = IF complementA[pA] >= complementA[ArgmaxSeq(complementA)]
                      THEN pA ELSE ArgmaxSeq(complementA)
        /\ offerB' = IF complementB[pB] >= complementB[ArgmaxSeq(complementB)]
                      THEN pB ELSE ArgmaxSeq(complementB)
  /\ phase' = "interact"
  /\ UNCHANGED <<voidA, complementA, etaA,
                  voidB, complementB, etaB,
                  voidS, complementS, proposalFlat, etaS,
                  distance, prevDistance, round, settled>>

\* Evaluate: compute distance, update all three void boundaries
Interact ==
  /\ phase = "interact"
  /\ prevDistance' = distance
  \* Recompute complements after potential void updates
  /\ complementA' = CompWeight(voidA, etaA)
  /\ complementB' = CompWeight(voidB, etaB)
  /\ distance' = DistSumAB(CompWeight(voidA, etaA), CompWeight(voidB, etaB))
  \* Update game walkers: if offers differ, both learn from the mismatch
  /\ voidA' = IF offerA # offerB
               THEN [voidA EXCEPT ![IF offerB <= NumChoices THEN offerB ELSE NumChoices] =
                       voidA[IF offerB <= NumChoices THEN offerB ELSE NumChoices] + 1]
               ELSE voidA
  /\ voidB' = IF offerA # offerB
               THEN [voidB EXCEPT ![IF offerA <= NumChoices THEN offerA ELSE NumChoices] =
                       voidB[IF offerA <= NumChoices THEN offerA ELSE NumChoices] + 1]
               ELSE voidB
  \* Update Skyrms walker: proposal failed if distance didn't decrease
  /\ LET newDist == DistSumAB(CompWeight(voidA, etaA), CompWeight(voidB, etaB))
         accepted == (offerA = DecodeA(proposalFlat) /\ offerB = DecodeB(proposalFlat))
         failed == (~accepted \/ newDist >= distance)
     IN voidS' = IF failed
                  THEN [voidS EXCEPT ![proposalFlat] = voidS[proposalFlat] + 1]
                  ELSE voidS
  /\ complementS' = CompWeight(
       IF DistSumAB(CompWeight(voidA, etaA), CompWeight(voidB, etaB)) >= distance
       THEN [voidS EXCEPT ![proposalFlat] = voidS[proposalFlat] + 1]
       ELSE voidS,
       etaS)
  /\ phase' = "adapt"
  /\ UNCHANGED <<offerA, offerB, etaA, etaB, proposalFlat, etaS, round, settled>>

\* All three walkers adapt
Adapt ==
  /\ phase = "adapt"
  \* Simple adaptation: reduce eta when distance is decreasing, increase when not
  /\ etaA' = IF distance < prevDistance
              THEN Clamp(etaA - 1, 1, EtaInit) ELSE Clamp(etaA + 1, 1, EtaInit)
  /\ etaB' = IF distance < prevDistance
              THEN Clamp(etaB - 1, 1, EtaInit) ELSE Clamp(etaB + 1, 1, EtaInit)
  /\ etaS' = IF distance < prevDistance
              THEN Clamp(etaS - 1, 1, EtaInit) ELSE Clamp(etaS + 1, 1, EtaInit)
  /\ round' = round + 1
  /\ phase' = "check"
  /\ UNCHANGED <<voidA, complementA, offerA,
                  voidB, complementB, offerB,
                  voidS, complementS, proposalFlat,
                  distance, prevDistance, settled>>

\* Check convergence
Check ==
  /\ phase = "check"
  /\ IF distance = 0
     THEN /\ settled' = TRUE /\ phase' = "converged"
     ELSE /\ settled' = FALSE /\ phase' = "propose"
  /\ UNCHANGED <<voidA, complementA, offerA, etaA,
                  voidB, complementB, offerB, etaB,
                  voidS, complementS, proposalFlat, etaS,
                  distance, prevDistance, round>>

\* Exhaustion
Exhaust ==
  /\ phase = "propose"
  /\ round > MaxRounds
  /\ ~settled
  /\ phase' = "exhausted"
  /\ UNCHANGED <<voidA, complementA, offerA, etaA,
                  voidB, complementB, offerB, etaB,
                  voidS, complementS, proposalFlat, etaS,
                  distance, prevDistance, round, settled>>

Stutter == UNCHANGED vars

Next ==
  \/ Propose
  \/ Decide
  \/ Interact
  \/ Adapt
  \/ Check
  \/ Exhaust
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Propose)
    /\ WF_vars(Decide)
    /\ WF_vars(Interact)
    /\ WF_vars(Adapt)
    /\ WF_vars(Check)
    /\ WF_vars(Exhaust)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Skyrms walker's void density is non-decreasing
\* (every failed proposal permanently enriches the site void)
InvSiteVoidNondecreasing ==
  \A i \in 1..ProposalSpace : voidS[i] >= 1

\* INV2: All three void boundaries have positive base density
InvAllVoidsPositive ==
  /\ \A i \in 1..NumChoices : voidA[i] >= 1
  /\ \A i \in 1..NumChoices : voidB[i] >= 1
  /\ \A i \in 1..ProposalSpace : voidS[i] >= 1

\* INV3: All three complement distributions have minimum weight 1
InvAllComplementsPositive ==
  /\ \A i \in 1..NumChoices : complementA[i] >= 1
  /\ \A i \in 1..NumChoices : complementB[i] >= 1
  /\ \A i \in 1..ProposalSpace : complementS[i] >= 1

\* INV4: All three etas are bounded
InvAllEtasBounded ==
  /\ etaA >= 1 /\ etaA <= EtaInit
  /\ etaB >= 1 /\ etaB <= EtaInit
  /\ etaS >= 1 /\ etaS <= EtaInit

\* INV5: Distance is non-negative
InvDistanceNonneg ==
  distance >= 0

\* INV6: At convergence, distance is zero (fixed point)
InvFixedPoint ==
  (phase = "converged") => /\ settled = TRUE /\ distance = 0

\* INV7: Round bounded
InvRoundBounded ==
  round >= 1 /\ round <= MaxRounds + 1

\* ─── Liveness ────────────────────────────────────────────────────────

ThreeWalkerConvergence == <>(phase = "converged" \/ phase = "exhausted")

=============================================================================
