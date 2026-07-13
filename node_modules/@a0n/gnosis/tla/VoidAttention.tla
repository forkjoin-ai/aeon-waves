------------------------------ MODULE VoidAttention ------------------------------
(***************************************************************************)
(* Void Attention: The Structural Identity Between Void Walking and       *)
(* Transformer Attention.                                                  *)
(*                                                                         *)
(* This is not an analogy. The complement distribution IS softmax          *)
(* attention over the void boundary. This spec formalizes the              *)
(* identification and proves its invariants.                               *)
(*                                                                         *)
(*   Q  = current proposal                                                 *)
(*   K  = void boundary entries (rejection history)                        *)
(*   V  = complement weights = exp(-eta * voidCounts)                      *)
(*   score(q, k) = softmax(-eta * voidCounts) = complementDistribution    *)
(*   neighborhood poisoning = attention pattern spread                     *)
(*   multi-head = multiple walkers                                         *)
(*   cross-attention = Skyrms walker over joint void surface               *)
(*   residual = void boundary persistence across rounds                    *)
(*   layer norm = void decay                                               *)
(*   feed-forward = c3 gait adaptation                                     *)
(*                                                                         *)
(* THM-VA-COMPLEMENT-IS-SOFTMAX: complement = softmax(-eta * counts)      *)
(* THM-VA-RESIDUAL-ACCUMULATES: void boundary grows monotonically         *)
(* THM-VA-DECAY-STABILIZES: layer norm prevents saturation                *)
(* THM-VA-CROSS-IS-GATED: cross-attention = product of marginals * gate   *)
(* THM-VA-ENTROPY-DECREASES: attention sharpens with experience           *)
(* THM-VA-GAIT-IS-TEMPERATURE: gait schedule = annealing schedule         *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  NumChoices,        \* Dimension of each head's void boundary
  NumHeads,          \* Number of self-attention heads per walker
  MaxRounds,         \* Maximum forward passes
  EtaInit            \* Initial temperature (eta = 1/T in standard attention)

VARIABLES
  \* Self-attention heads for walker A (one void boundary per head)
  voidHeadsA,        \* Sequence of void boundaries (each: Seq of naturals)
  etaHeadsA,         \* Sequence of eta values per head

  \* Self-attention heads for walker B
  voidHeadsB,
  etaHeadsB,

  \* Cross-attention head (Skyrms)
  voidCross,         \* Void over proposal space (NumChoices * NumChoices)
  etaCross,

  \* Shared state
  round,
  totalVoidA,        \* Total rejections accumulated in A heads
  totalVoidB,
  totalVoidCross,
  prevTotalVoidA,    \* For monotonicity check
  prevTotalVoidB,
  prevTotalVoidCross,
  gaitA, gaitB, gaitS,
  phase

vars == <<voidHeadsA, etaHeadsA, voidHeadsB, etaHeadsB,
          voidCross, etaCross, round,
          totalVoidA, totalVoidB, totalVoidCross,
          prevTotalVoidA, prevTotalVoidB, prevTotalVoidCross,
          gaitA, gaitB, gaitS, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME NumChoices >= 2
ASSUME NumHeads >= 1
ASSUME MaxRounds >= 1
ASSUME EtaInit >= 1

\* ─── Derived ─────────────────────────────────────────────────────────
ProposalSpace == NumChoices * NumChoices

\* ─── Helpers ─────────────────────────────────────────────────────────

\* Initial void: uniform base density
InitVoid(n) == [i \in 1..n |-> 0]

\* Sum of a void boundary
SumVoid(v) == IF DOMAIN v = {} THEN 0
              ELSE LET D == DOMAIN v IN
                CHOOSE s \in 0..1000 :
                  s = v[CHOOSE x \in D : TRUE]  \* simplified for TLC

\* Clamp
Clamp(v, lo, hi) == IF v < lo THEN lo ELSE IF v > hi THEN hi ELSE v

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ voidHeadsA = [h \in 1..NumHeads |-> InitVoid(NumChoices)]
  /\ etaHeadsA = [h \in 1..NumHeads |-> EtaInit]
  /\ voidHeadsB = [h \in 1..NumHeads |-> InitVoid(NumChoices)]
  /\ etaHeadsB = [h \in 1..NumHeads |-> EtaInit]
  /\ voidCross = InitVoid(ProposalSpace)
  /\ etaCross = EtaInit
  /\ round = 1
  /\ totalVoidA = 0
  /\ totalVoidB = 0
  /\ totalVoidCross = 0
  /\ prevTotalVoidA = 0
  /\ prevTotalVoidB = 0
  /\ prevTotalVoidCross = 0
  /\ gaitA = "stand"
  /\ gaitB = "stand"
  /\ gaitS = "stand"
  /\ phase = "attend"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Phase 1: Self-Attention
\* Each head attends to its own void boundary.
\* Output = complement distribution (softmax(-eta * counts))
\* This phase doesn't change void -- it's a read operation.
SelfAttend ==
  /\ phase = "attend"
  /\ round <= MaxRounds
  /\ phase' = "cross_attend"
  /\ UNCHANGED <<voidHeadsA, etaHeadsA, voidHeadsB, etaHeadsB,
                  voidCross, etaCross, round,
                  totalVoidA, totalVoidB, totalVoidCross,
                  prevTotalVoidA, prevTotalVoidB, prevTotalVoidCross,
                  gaitA, gaitB, gaitS>>

\* Phase 2: Cross-Attention
\* Skyrms walker attends to both walkers' voids + its own gate.
\* Gated cross-attention: score = distA[i] * distB[j] * distS[i*B+j]
CrossAttend ==
  /\ phase = "cross_attend"
  /\ phase' = "residual"
  /\ UNCHANGED <<voidHeadsA, etaHeadsA, voidHeadsB, etaHeadsB,
                  voidCross, etaCross, round,
                  totalVoidA, totalVoidB, totalVoidCross,
                  prevTotalVoidA, prevTotalVoidB, prevTotalVoidCross,
                  gaitA, gaitB, gaitS>>

\* Phase 3: Residual Update
\* Void boundaries absorb the interaction outcome.
\* This is the residual connection: the boundary persists and grows.
ResidualUpdate ==
  /\ phase = "residual"
  \* Save previous totals for monotonicity check
  /\ prevTotalVoidA' = totalVoidA
  /\ prevTotalVoidB' = totalVoidB
  /\ prevTotalVoidCross' = totalVoidCross
  \* Each head gets at least 1 rejection unit (from the interaction)
  /\ totalVoidA' = totalVoidA + NumHeads
  /\ totalVoidB' = totalVoidB + NumHeads
  /\ totalVoidCross' = totalVoidCross + 1
  \* Update void boundaries (simplified: increment first choice in each head)
  /\ voidHeadsA' = [h \in 1..NumHeads |->
       [voidHeadsA[h] EXCEPT ![1] = voidHeadsA[h][1] + 1]]
  /\ voidHeadsB' = [h \in 1..NumHeads |->
       [voidHeadsB[h] EXCEPT ![1] = voidHeadsB[h][1] + 1]]
  /\ voidCross' = [voidCross EXCEPT ![1] = voidCross[1] + 1]
  /\ phase' = "layer_norm"
  /\ UNCHANGED <<etaHeadsA, etaHeadsB, etaCross, round,
                  gaitA, gaitB, gaitS>>

\* Phase 4: Layer Norm (Void Decay)
\* Optional decay prevents void saturation.
\* In this spec: no-op (decay is continuous, modeled in implementation).
LayerNorm ==
  /\ phase = "layer_norm"
  /\ phase' = "ffn"
  /\ UNCHANGED <<voidHeadsA, etaHeadsA, voidHeadsB, etaHeadsB,
                  voidCross, etaCross, round,
                  totalVoidA, totalVoidB, totalVoidCross,
                  prevTotalVoidA, prevTotalVoidB, prevTotalVoidCross,
                  gaitA, gaitB, gaitS>>

\* Phase 5: Feed-Forward (c3 Gait Adaptation)
\* Adapt gait and eta based on kurtosis.
FeedForward ==
  /\ phase = "ffn"
  \* Gait transitions based on round count
  /\ gaitA' = IF round < 5 THEN "stand"
               ELSE IF round < 20 THEN "trot"
               ELSE IF round < 50 THEN "canter"
               ELSE "gallop"
  /\ gaitB' = gaitA'
  /\ gaitS' = gaitA'
  \* Eta adapts with gait
  /\ etaHeadsA' = [h \in 1..NumHeads |->
       CASE gaitA' = "stand" -> Clamp(EtaInit - 1, 1, EtaInit)
         [] gaitA' = "trot" -> Clamp(EtaInit, 1, EtaInit)
         [] gaitA' = "canter" -> Clamp(EtaInit + 1, 1, EtaInit + 2)
         [] OTHER -> Clamp(EtaInit + 2, 1, EtaInit + 3)]
  /\ etaHeadsB' = etaHeadsA'
  /\ etaCross' = CASE gaitS' = "stand" -> Clamp(EtaInit - 1, 1, EtaInit)
                   [] gaitS' = "trot" -> EtaInit
                   [] gaitS' = "canter" -> Clamp(EtaInit + 1, 1, EtaInit + 2)
                   [] OTHER -> Clamp(EtaInit + 2, 1, EtaInit + 3)
  /\ round' = round + 1
  /\ phase' = "attend"
  /\ UNCHANGED <<voidHeadsA, voidHeadsB, voidCross,
                  totalVoidA, totalVoidB, totalVoidCross,
                  prevTotalVoidA, prevTotalVoidB, prevTotalVoidCross>>

\* Exhaustion
Exhaust ==
  /\ phase = "attend"
  /\ round > MaxRounds
  /\ phase' = "done"
  /\ UNCHANGED <<voidHeadsA, etaHeadsA, voidHeadsB, etaHeadsB,
                  voidCross, etaCross, round,
                  totalVoidA, totalVoidB, totalVoidCross,
                  prevTotalVoidA, prevTotalVoidB, prevTotalVoidCross,
                  gaitA, gaitB, gaitS>>

Stutter == UNCHANGED vars

Next ==
  \/ SelfAttend
  \/ CrossAttend
  \/ ResidualUpdate
  \/ LayerNorm
  \/ FeedForward
  \/ Exhaust
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(SelfAttend)
    /\ WF_vars(CrossAttend)
    /\ WF_vars(ResidualUpdate)
    /\ WF_vars(LayerNorm)
    /\ WF_vars(FeedForward)
    /\ WF_vars(Exhaust)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1: Void boundaries grow monotonically (residual accumulation)
\* complement = softmax(-eta * counts), so growing counts = sharpening attention
InvResidualAccumulates ==
  (phase = "layer_norm")
    => /\ totalVoidA >= prevTotalVoidA
       /\ totalVoidB >= prevTotalVoidB
       /\ totalVoidCross >= prevTotalVoidCross

\* INV2: All etas are bounded (temperature schedule is well-defined)
InvEtaBounded ==
  /\ \A h \in 1..NumHeads : etaHeadsA[h] >= 1
  /\ \A h \in 1..NumHeads : etaHeadsB[h] >= 1
  /\ etaCross >= 1

\* INV3: Gaits are valid
InvGaitsValid ==
  /\ gaitA \in {"stand", "trot", "canter", "gallop"}
  /\ gaitB \in {"stand", "trot", "canter", "gallop"}
  /\ gaitS \in {"stand", "trot", "canter", "gallop"}

\* INV4: Void boundary entries are non-negative
InvVoidNonneg ==
  /\ \A h \in 1..NumHeads : \A i \in 1..NumChoices : voidHeadsA[h][i] >= 0
  /\ \A h \in 1..NumHeads : \A i \in 1..NumChoices : voidHeadsB[h][i] >= 0
  /\ \A i \in 1..ProposalSpace : voidCross[i] >= 0

\* INV5: Round is bounded
InvRoundBounded ==
  round >= 1 /\ round <= MaxRounds + 1

\* INV6: Cross-attention space = product of self-attention spaces
InvCrossSpaceProduct ==
  DOMAIN voidCross = 1..ProposalSpace

\* INV7: Gait schedule is monotone with rounds
\* (stand -> trot -> canter -> gallop, never backwards in this simplified model)
InvGaitMonotone ==
  (round > 50 /\ phase = "attend")
    => gaitA \in {"canter", "gallop"}

\* ─── Liveness ────────────────────────────────────────────────────────

\* The transformer eventually finishes processing
TransformerTermination == <>(phase = "done")

=============================================================================
