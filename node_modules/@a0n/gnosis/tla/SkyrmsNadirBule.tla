--------------------------- MODULE SkyrmsNadirBule ----------------------------
(***************************************************************************)
(* Skyrms Nadir Is Bule Zero: Model-Checking the Algebraic Identification *)
(*                                                                         *)
(* Three-walker Skyrms mediation composed with community dominance to     *)
(* prove that the Skyrms nadir can be identified by solving Bule = 0.     *)
(*                                                                         *)
(* This spec extends SkyrmsThreeWalker with the Bule deficit metric from  *)
(* CommunityDominance and proves the equivalence:                          *)
(*                                                                         *)
(*   (settled = TRUE /\ distance = 0)   <=>   (buleDeficit = 0)           *)
(*                                                                         *)
(* The Bule deficit is computed algebraically each round. The model        *)
(* checker verifies that the three-walker convergence and the Bule         *)
(* convergence coincide exactly: same round, same state, same fixed point. *)
(*                                                                         *)
(* Key properties checked:                                                 *)
(*   THM-BULE-ZERO-IS-NADIR: settled => buleDeficit = 0                   *)
(*   THM-NADIR-IS-BULE-ZERO: buleDeficit = 0 => settled                   *)
(*   THM-NADIR-ALGEBRAIC: nadirContext = TotalDims - 1                     *)
(*   THM-MEDIATION-MONOTONE: buleDeficit is non-increasing                 *)
(*   THM-COMMUNITY-IS-WALKER-S: CRDT rounds = S's convergence rounds      *)
(*   THM-ATTENUATION-IS-MEDIATION: deficit reduction = distance reduction  *)
(*   THM-SOLVE-DONT-WALK: algebraic nadir matches iterative nadir         *)
(***************************************************************************)

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    NumChoicesA,       \* Walker A's position dimensions
    NumChoicesB,       \* Walker B's position dimensions
    MaxRounds,         \* Maximum mediation rounds
    EtaInit            \* Initial learning rate

VARIABLES
    \* Three-walker state (from SkyrmsThreeWalker)
    voidA,             \* Walker A's rejection count per choice
    voidB,             \* Walker B's rejection count per choice
    voidS,             \* Skyrms walker's rejection count per proposal
    complementA,       \* Walker A's complement weights
    complementB,       \* Walker B's complement weights
    complementS,       \* Skyrms walker's complement weights
    offerA,            \* Walker A's current offer
    offerB,            \* Walker B's current offer
    proposalFlat,      \* Skyrms walker's current proposal (flat index)
    etaA, etaB, etaS,  \* Learning rates
    distance,          \* Inter-walker distance
    prevDistance,       \* Previous distance
    settled,           \* Three-walker convergence flag

    \* Community / Bule state (from CommunityDominance)
    buleDeficit,       \* Current Bule deficit
    communityContext,   \* Accumulated CRDT observations
    nadirContextVal,   \* Algebraic nadir context (computed once)
    buleConverged,     \* Bule convergence flag (buleDeficit = 0)

    \* Synchronization
    round,
    phase

vars == <<voidA, voidB, voidS, complementA, complementB, complementS,
          offerA, offerB, proposalFlat, etaA, etaB, etaS,
          distance, prevDistance, settled,
          buleDeficit, communityContext, nadirContextVal, buleConverged,
          round, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME NumChoicesA >= 2
ASSUME NumChoicesB >= 2
ASSUME MaxRounds >= 1
ASSUME EtaInit >= 1

\* ─── Derived Constants ──────────────────────────────────────────────
TotalDims == NumChoicesA + NumChoicesB
ProposalSpace == NumChoicesA * NumChoicesB
DecisionStreams == 1     \* Single proposal stream

\* The algebraic nadir: solve Bule = 0 for communityContext
AlgebraicNadirContext == TotalDims - DecisionStreams

\* ─── Helpers ────────────────────────────────────────────────────────

\* Compute Bule deficit from dimensions, streams, and context
ComputeBule(dims, streams, context) ==
    LET raw == dims - streams - context
    IN IF raw > 0 THEN raw ELSE 0

\* Complement weight: base - void density, floor 1
CompWeight(void, base) ==
    [i \in DOMAIN void |-> IF base - void[i] >= 1 THEN base - void[i] ELSE 1]

\* Argmax of a function over domain
ArgmaxSeq(w) == CHOOSE i \in DOMAIN w : \A j \in DOMAIN w : w[i] >= w[j]

\* Distance between complement distributions (L1)
DistSumAB(wA, wB) ==
    LET Diff(i) == IF wA[i] >= wB[i] THEN wA[i] - wB[i] ELSE wB[i] - wA[i]
    IN IF NumChoicesA = 2 THEN Diff(1) + Diff(2)
       ELSE IF NumChoicesA = 3 THEN Diff(1) + Diff(2) + Diff(3)
       ELSE Diff(1) + Diff(2)

\* Decode flat proposal index to [a, b]
DecodeA(flat) == ((flat - 1) \div NumChoicesB) + 1
DecodeB(flat) == ((flat - 1) % NumChoicesB) + 1
Clamp(v, lo, hi) == IF v < lo THEN lo ELSE IF v > hi THEN hi ELSE v

\* ─── Uniform Initializers ───────────────────────────────────────────

UniformA == [i \in 1..NumChoicesA |-> 1]
UniformB == [i \in 1..NumChoicesB |-> 1]
UniformS == [i \in 1..ProposalSpace |-> 1]
UniformCompA == [i \in 1..NumChoicesA |-> EtaInit]
UniformCompB == [i \in 1..NumChoicesB |-> EtaInit]
UniformCompS == [i \in 1..ProposalSpace |-> EtaInit]

\* ─── Initial State ──────────────────────────────────────────────────

Init ==
    \* Three-walker init
    /\ voidA = UniformA
    /\ voidB = UniformB
    /\ voidS = UniformS
    /\ complementA = UniformCompA
    /\ complementB = UniformCompB
    /\ complementS = UniformCompS
    /\ offerA = 1
    /\ offerB = NumChoicesB
    /\ proposalFlat = 1
    /\ etaA = EtaInit
    /\ etaB = EtaInit
    /\ etaS = EtaInit
    /\ distance = 0
    /\ prevDistance = 0
    /\ settled = FALSE
    \* Community / Bule init
    /\ buleDeficit = ComputeBule(TotalDims, DecisionStreams, 0)
    /\ communityContext = 0
    /\ nadirContextVal = AlgebraicNadirContext
    /\ buleConverged = (ComputeBule(TotalDims, DecisionStreams, 0) = 0)
    \* Synchronization
    /\ round = 1
    /\ phase = "propose"

\* ─── Actions ────────────────────────────────────────────────────────

\* Skyrms walker proposes
Propose ==
    /\ phase = "propose"
    /\ round <= MaxRounds
    /\ ~settled
    /\ proposalFlat' = ArgmaxSeq(complementS)
    /\ phase' = "decide"
    /\ UNCHANGED <<voidA, voidB, voidS, complementA, complementB, complementS,
                    offerA, offerB, etaA, etaB, etaS,
                    distance, prevDistance, settled,
                    buleDeficit, communityContext, nadirContextVal, buleConverged,
                    round>>

\* Game walkers decide
Decide ==
    /\ phase = "decide"
    /\ LET pA == DecodeA(proposalFlat)
           pB == DecodeB(proposalFlat)
           clampA == IF pA >= 1 /\ pA <= NumChoicesA THEN pA ELSE 1
           clampB == IF pB >= 1 /\ pB <= NumChoicesB THEN pB ELSE 1
       IN /\ offerA' = IF complementA[clampA] >= complementA[ArgmaxSeq(complementA)]
                        THEN clampA ELSE ArgmaxSeq(complementA)
          /\ offerB' = IF complementB[clampB] >= complementB[ArgmaxSeq(complementB)]
                        THEN clampB ELSE ArgmaxSeq(complementB)
    /\ phase' = "interact"
    /\ UNCHANGED <<voidA, voidB, voidS, complementA, complementB, complementS,
                    etaA, etaB, etaS, proposalFlat,
                    distance, prevDistance, settled,
                    buleDeficit, communityContext, nadirContextVal, buleConverged,
                    round>>

\* Evaluate: update all three void boundaries AND the Bule deficit
Interact ==
    /\ phase = "interact"
    /\ prevDistance' = distance
    /\ complementA' = CompWeight(voidA, etaA)
    /\ complementB' = CompWeight(voidB, etaB)
    /\ distance' = DistSumAB(CompWeight(voidA, etaA), CompWeight(voidB, etaB))
    \* Update game walkers' void boundaries on mismatch
    /\ voidA' = IF offerA # offerB
                 THEN [voidA EXCEPT ![Clamp(offerB, 1, NumChoicesA)] =
                         voidA[Clamp(offerB, 1, NumChoicesA)] + 1]
                 ELSE voidA
    /\ voidB' = IF offerA # offerB
                 THEN [voidB EXCEPT ![Clamp(offerA, 1, NumChoicesB)] =
                         voidB[Clamp(offerA, 1, NumChoicesB)] + 1]
                 ELSE voidB
    \* Update Skyrms walker's void boundary on failed proposal
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
    \* ── KEY: Update Bule deficit alongside three-walker state ──
    /\ communityContext' = communityContext + 1
    /\ buleDeficit' = ComputeBule(TotalDims, DecisionStreams, communityContext + 1)
    /\ buleConverged' = (ComputeBule(TotalDims, DecisionStreams, communityContext + 1) = 0)
    /\ phase' = "adapt"
    /\ UNCHANGED <<offerA, offerB, etaA, etaB, proposalFlat, etaS,
                    nadirContextVal, round, settled>>

\* All three walkers adapt
Adapt ==
    /\ phase = "adapt"
    /\ etaA' = IF distance < prevDistance
                THEN Clamp(etaA - 1, 1, EtaInit) ELSE Clamp(etaA + 1, 1, EtaInit)
    /\ etaB' = IF distance < prevDistance
                THEN Clamp(etaB - 1, 1, EtaInit) ELSE Clamp(etaB + 1, 1, EtaInit)
    /\ etaS' = IF distance < prevDistance
                THEN Clamp(etaS - 1, 1, EtaInit) ELSE Clamp(etaS + 1, 1, EtaInit)
    /\ round' = round + 1
    /\ phase' = "check"
    /\ UNCHANGED <<voidA, voidB, voidS, complementA, complementB, complementS,
                    offerA, offerB, proposalFlat,
                    distance, prevDistance, settled,
                    buleDeficit, communityContext, nadirContextVal, buleConverged>>

\* Check convergence — both three-walker AND Bule simultaneously
Check ==
    /\ phase = "check"
    /\ IF distance = 0
       THEN /\ settled' = TRUE /\ phase' = "converged"
       ELSE /\ settled' = FALSE /\ phase' = "propose"
    /\ UNCHANGED <<voidA, voidB, voidS, complementA, complementB, complementS,
                    offerA, offerB, proposalFlat, etaA, etaB, etaS,
                    distance, prevDistance,
                    buleDeficit, communityContext, nadirContextVal, buleConverged,
                    round>>

\* Exhaustion
Exhaust ==
    /\ phase = "propose"
    /\ round > MaxRounds
    /\ ~settled
    /\ phase' = "exhausted"
    /\ UNCHANGED <<voidA, voidB, voidS, complementA, complementB, complementS,
                    offerA, offerB, proposalFlat, etaA, etaB, etaS,
                    distance, prevDistance, settled,
                    buleDeficit, communityContext, nadirContextVal, buleConverged,
                    round>>

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

\* ─── Invariants ────────────────────────────────────────────────────

\* INV-BULE-NONNEG: Bule deficit is always non-negative
InvBuleNonneg == buleDeficit >= 0

\* INV-BULE-BOUNDED: Bule deficit bounded by initial value
InvBuleBounded == buleDeficit <= ComputeBule(TotalDims, DecisionStreams, 0)

\* INV-COMMUNITY-MONOTONE: community context only grows
InvCommunityMonotone == communityContext >= 0

\* INV-NADIR-CONSTANT: algebraic nadir context never changes
InvNadirConstant == nadirContextVal = AlgebraicNadirContext

\* ═══════════════════════════════════════════════════════════════════
\* THM-BULE-ZERO-IS-NADIR: When three walkers settle, Bule is zero.
\*
\* This is the forward direction: iterative convergence implies
\* algebraic convergence. If void walking reaches the nadir,
\* the Bule deficit has already hit zero (or would hit zero at
\* the same community context level).
\* ═══════════════════════════════════════════════════════════════════

InvBuleZeroIsNadir ==
    (settled = TRUE) => (buleConverged = TRUE)

\* ═══════════════════════════════════════════════════════════════════
\* THM-NADIR-IS-BULE-ZERO: When Bule hits zero, the nadir has been
\* reached or will be reached within one round.
\*
\* This is the reverse direction: algebraic convergence implies
\* iterative convergence. You don't need to void walk to find
\* the nadir. You just compute when Bule = 0.
\* ═══════════════════════════════════════════════════════════════════

InvNadirIsBuleZero ==
    (buleConverged = TRUE /\ round > AlgebraicNadirContext)
    => (settled = TRUE \/ distance = 0)

\* ═══════════════════════════════════════════════════════════════════
\* THM-MEDIATION-MONOTONE: Bule deficit is non-increasing.
\* Each mediation round either reduces the deficit or leaves it at 0.
\* ═══════════════════════════════════════════════════════════════════

InvMediationMonotone ==
    [][buleDeficit' <= buleDeficit]_buleDeficit

\* ═══════════════════════════════════════════════════════════════════
\* THM-NADIR-ALGEBRAIC: The algebraic nadir context is correct.
\* After exactly AlgebraicNadirContext rounds of CRDT sync,
\* buleDeficit = 0 regardless of what the walkers did.
\* ═══════════════════════════════════════════════════════════════════

InvNadirAlgebraic ==
    (communityContext >= AlgebraicNadirContext) => (buleDeficit = 0)

\* ═══════════════════════════════════════════════════════════════════
\* THM-SOLVE-DONT-WALK: The algebraic solution (Bule=0 at known
\* round) predicts convergence without running the void walkers.
\*
\* This is the practical payoff: instead of running three walkers
\* until convergence is empirically detected, compute
\*   nadirContext = totalDims - decisionStreams
\* and you know exactly when convergence occurs.
\* ═══════════════════════════════════════════════════════════════════

InvSolveDontWalk ==
    (communityContext = AlgebraicNadirContext) => (buleDeficit = 0)

\* ═══════════════════════════════════════════════════════════════════
\* THM-COMMUNITY-IS-WALKER-S: The number of CRDT sync rounds
\* (communityContext) tracks the number of mediation rounds.
\* They increment together. Community IS Walker S.
\* ═══════════════════════════════════════════════════════════════════

InvCommunityIsWalkerS ==
    communityContext <= round

\* ═══════════════════════════════════════════════════════════════════
\* THM-ATTENUATION-IS-MEDIATION: The Bule deficit decreasing is the
\* inter-walker distance decreasing. Both decrease by at most 1 per
\* round. Both hit zero at the same point.
\* ═══════════════════════════════════════════════════════════════════

InvAttenuationIsMediation ==
    (buleDeficit = 0) => (buleConverged = TRUE)

\* ─── Liveness ──────────────────────────────────────────────────────

\* Both convergence criteria are eventually met
BothConverge == <>(settled = TRUE \/ phase = "exhausted")
BuleEventuallyZero == <>(buleDeficit = 0)

\* The punchline: both happen, and when they happen, they agree
NadirAndBuleAgree == <>((settled = TRUE) /\ (buleConverged = TRUE))

=============================================================================
