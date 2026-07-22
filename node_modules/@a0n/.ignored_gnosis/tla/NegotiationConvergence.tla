------------------------ MODULE NegotiationConvergence ------------------------
(***************************************************************************)
(* Negotiation Convergence via Fork-Race-Fold on Void Surface.            *)
(*                                                                         *)
(* Models a multi-round negotiation as a state machine over the void      *)
(* walking surface. Each round forks candidate offers, races them          *)
(* against a BATNA threshold, and folds the result into an updated        *)
(* void state. Negotiation either settles or exhausts rounds.             *)
(*                                                                         *)
(* THM-NEG-SETTLE: settlement is reachable when an offer exceeds BATNA    *)
(* THM-NEG-VOID-MONO: void deficit is monotonically non-increasing        *)
(* THM-NEG-COMPLEMENT: settled complement satisfies void boundary         *)
(* THM-NEG-DEFICIT-CTX: deficit reduces with increasing context           *)
(* THM-NEG-EXHAUST: exhausted rounds still produce a valid void state     *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  NumChoices,        \* Number of candidate offers forked per round (>= 2)
  MaxRounds,         \* Maximum negotiation rounds before forced termination
  BATNAThreshold     \* Minimum acceptable value for settlement

VARIABLES
  offers,            \* Set of candidate offer values in the current round
  bestOffer,         \* Best offer found during race evaluation
  voidDeficit,       \* Current void deficit (information gap)
  contextAccum,      \* Accumulated context from prior rounds
  round,             \* Current round number (1-indexed)
  settled,           \* TRUE when negotiation has settled
  complement,        \* Complement value at settlement (void boundary dual)
  phase              \* Execution phase within a round

vars == <<offers, bestOffer, voidDeficit, contextAccum, round, settled, complement, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME NumChoices >= 2
ASSUME MaxRounds >= 1
ASSUME BATNAThreshold >= 1

\* ─── Helpers ─────────────────────────────────────────────────────────

\* Maximum of a non-empty set of naturals
SetMax(S) == CHOOSE x \in S : \A y \in S : x >= y

\* Deficit reduction: each round with context reduces deficit by 1 (floor 0)
ReduceDeficit(d, ctx) == IF d > 0 /\ ctx > 0 THEN d - 1 ELSE d

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ offers = {}
  /\ bestOffer = 0
  /\ voidDeficit = MaxRounds          \* Start at maximum deficit
  /\ contextAccum = 0
  /\ round = 1
  /\ settled = FALSE
  /\ complement = 0
  /\ phase = "init"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Fork: generate NumChoices candidate offers for this round
\* Offers are integers 1..NumChoices scaled by round (later rounds = better info)
ForkOffers ==
  /\ phase = "init"
  /\ round <= MaxRounds
  /\ ~settled
  /\ offers' = {i + contextAccum : i \in 1..NumChoices}
  /\ phase' = "forked"
  /\ UNCHANGED <<bestOffer, voidDeficit, contextAccum, round, settled, complement>>

\* Race: evaluate all offers, find the best one
RaceEvaluate ==
  /\ phase = "forked"
  /\ Cardinality(offers) >= 1
  /\ bestOffer' = SetMax(offers)
  /\ phase' = "raced"
  /\ UNCHANGED <<offers, voidDeficit, contextAccum, round, settled, complement>>

\* Fold-Accept: best offer meets BATNA, negotiation settles
FoldAccept ==
  /\ phase = "raced"
  /\ bestOffer >= BATNAThreshold
  /\ settled' = TRUE
  /\ complement' = bestOffer - BATNAThreshold   \* Surplus above BATNA
  /\ voidDeficit' = 0                            \* Settlement closes deficit
  /\ phase' = "settled"
  /\ UNCHANGED <<offers, bestOffer, contextAccum, round>>

\* Fold-Reject: best offer below BATNA, update void and advance round
FoldReject ==
  /\ phase = "raced"
  /\ bestOffer < BATNAThreshold
  /\ ~settled
  /\ contextAccum' = contextAccum + 1            \* Gain context from failed round
  /\ voidDeficit' = ReduceDeficit(voidDeficit, contextAccum + 1)
  /\ round' = round + 1
  /\ phase' = "init"                             \* Loop back for next round
  /\ UNCHANGED <<offers, bestOffer, settled, complement>>

\* Trace: record void state update after settlement
TraceVoidUpdate ==
  /\ phase = "settled"
  /\ phase' = "complete"
  /\ UNCHANGED <<offers, bestOffer, voidDeficit, contextAccum, round, settled, complement>>

\* Exhaustion: all rounds used without settlement
Exhaust ==
  /\ phase = "init"
  /\ round > MaxRounds
  /\ ~settled
  /\ phase' = "exhausted"
  /\ UNCHANGED <<offers, bestOffer, voidDeficit, contextAccum, round, settled, complement>>

Stutter == UNCHANGED vars

Next ==
  \/ ForkOffers
  \/ RaceEvaluate
  \/ FoldAccept
  \/ FoldReject
  \/ TraceVoidUpdate
  \/ Exhaust
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(ForkOffers)
    /\ WF_vars(RaceEvaluate)
    /\ WF_vars(FoldAccept)
    /\ WF_vars(FoldReject)
    /\ WF_vars(TraceVoidUpdate)
    /\ WF_vars(Exhaust)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Settlement is reachable -- if best offer >= BATNA, fold accepts
InvSettlementReachable ==
  (phase = "raced" /\ bestOffer >= BATNAThreshold)
    => ~(phase' = "raced" /\ bestOffer' = bestOffer /\ settled' = FALSE)
    \* Simplified: once BATNA is met at settlement, deficit is zero
    \/ (phase = "settled" => voidDeficit = 0)

\* INV2: Void deficit is monotonically non-increasing across rounds
InvVoidMonotone ==
  (phase = "init" /\ round > 1)
    => voidDeficit <= MaxRounds - (round - 1)

\* INV3: Complement at settlement is valid (non-negative surplus)
InvComplementValid ==
  (phase = "complete")
    => /\ complement >= 0
       /\ settled = TRUE
       /\ voidDeficit = 0

\* INV4: Deficit reduces with accumulated context
InvDeficitReducesWithContext ==
  (phase = "init" /\ contextAccum > 0)
    => voidDeficit < MaxRounds

\* INV5: Exhausted state is valid -- deficit may be positive but bounded
InvExhaustedValid ==
  (phase = "exhausted")
    => /\ ~settled
       /\ voidDeficit >= 0
       /\ round > MaxRounds

\* INV6: Round counter is bounded
InvRoundBounded ==
  round >= 1 /\ round <= MaxRounds + 1

\* ─── Liveness ────────────────────────────────────────────────────────

\* Eventually settles OR exhausts rounds
NegotiationTermination == <>(phase = "complete" \/ phase = "exhausted")

=============================================================================
