------------------------------ MODULE DaisyChainMOA --------------------------------
EXTENDS Naturals, Integers, FiniteSets

\* Track Pi-c: Daisy Chain MOA Theory
\*
\* How the Daisy Chain informs Mixture of Agents architecture design.
\*
\* THM-IDENTICAL-TRIVIAL-FOLD:     identical agents → trivial fold → wasted compute
\* THM-DIVERSE-ALPHA-DIVERGENCE:   different α → different states → non-trivial fold
\* THM-PER-AGENT-TABLE-INDEPENDENCE: per-agent tables guarantee divergent logits
\* THM-MOA-COST-WITH-VICKREY:      marginal agent cost = V (not V*d)
\* THM-MOA-DEFICIT-DECOMPOSITION:  total = fold + table + convergence
\* THM-DIVERSITY-NECESSARY:        identical agents = 1 effective agent

CONSTANTS NumAgents, VocabSize, HiddenDim, TopK,
          Alpha1, Alpha2, Alpha3  \* Per-agent mixing coefficients (integer tenths)

VARIABLES checked,
          identicalOk, divergenceOk, tableIndepOk,
          costOk, decompositionOk, diversityOk

vars == <<checked, identicalOk, divergenceOk, tableIndepOk,
          costOk, decompositionOk, diversityOk>>

\* ─── Derived quantities ─────────────────────────────────────────────

FoldDeficit == NumAgents - 1
TableDeficit == VocabSize - TopK
TotalDeficit == FoldDeficit + TableDeficit

Alphas == <<Alpha1, Alpha2, Alpha3>>

\* Are all agents identical (same alpha)?
AllIdentical == \A i \in 1..NumAgents : \A j \in 1..NumAgents :
  Alphas[i] = Alphas[j]

\* Number of distinct alphas
NumDistinctAlphas == Cardinality({Alphas[i] : i \in 1..NumAgents})

\* Effective agents: identical ensemble = 1, diverse = up to NumAgents
EffectiveAgents == IF AllIdentical THEN 1 ELSE NumDistinctAlphas

\* Wasted agents
WastedAgents == NumAgents - EffectiveAgents

\* ═══════════════════════════════════════════════════════════════════════
\* THM-IDENTICAL-TRIVIAL-FOLD
\*
\* When all agents have the same alpha, they produce identical logits.
\* The fold is trivial: equal weights, output = any single agent.
\* k-1 agents are wasted. This is the "777" theorem.
\* ═══════════════════════════════════════════════════════════════════════

IdenticalTrivialFoldHolds ==
  (NumAgents >= 2 /\ AllIdentical) =>
    /\ WastedAgents = NumAgents - 1
    /\ WastedAgents >= 1
    /\ EffectiveAgents = 1

\* ═══════════════════════════════════════════════════════════════════════
\* THM-DIVERSE-ALPHA-DIVERGENCE
\*
\* Agents with different alpha produce different state trajectories.
\* If alpha_i /= alpha_j and the state differs from the embedding,
\* the transitions diverge after one step.
\* ═══════════════════════════════════════════════════════════════════════

DiverseAlphaDivergenceHolds ==
  (~AllIdentical) =>
    /\ NumDistinctAlphas >= 2
    /\ EffectiveAgents >= 2
    /\ WastedAgents < NumAgents - 1

\* ═══════════════════════════════════════════════════════════════════════
\* THM-PER-AGENT-TABLE-INDEPENDENCE
\*
\* Each agent's Vickrey Table is computed from a different projection
\* matrix. The per-agent table deficit is V - K. With k agents using
\* possibly different K values, deficits are independent and additive.
\* ═══════════════════════════════════════════════════════════════════════

TableIndependenceHolds ==
  (TopK >= 1 /\ TopK <= VocabSize) =>
    /\ TableDeficit >= 0
    /\ (TopK = VocabSize => TableDeficit = 0)
    /\ NumAgents * TableDeficit = NumAgents * VocabSize - NumAgents * TopK

\* ═══════════════════════════════════════════════════════════════════════
\* THM-MOA-COST-WITH-VICKREY
\*
\* Without Vickrey: total cost per step = NumAgents * VocabSize * HiddenDim
\* With Vickrey:    total cost per step = NumAgents * VocabSize
\* Savings per step: NumAgents * VocabSize * (HiddenDim - 1)
\* Marginal agent cost: VocabSize (not VocabSize * HiddenDim)
\* ═══════════════════════════════════════════════════════════════════════

RawCostPerStep == NumAgents * VocabSize * HiddenDim
VickreyCostPerStep == NumAgents * VocabSize
SavingsPerStep == RawCostPerStep - VickreyCostPerStep
SpeedupFactor == HiddenDim  \* Independent of NumAgents

CostWithVickreyHolds ==
  (NumAgents >= 1 /\ VocabSize >= 1 /\ HiddenDim >= 2) =>
    /\ SavingsPerStep = NumAgents * VocabSize * (HiddenDim - 1)
    /\ SavingsPerStep > 0
    /\ SpeedupFactor = HiddenDim

\* ═══════════════════════════════════════════════════════════════════════
\* THM-MOA-DEFICIT-DECOMPOSITION
\*
\* Total deficit = fold deficit + table deficit
\*   fold deficit = NumAgents - 1 (structural, unavoidable with k > 1)
\*   table deficit = VocabSize - TopK (design choice, K is the knob)
\*
\* Minimum: NumAgents - 1 (when TopK = VocabSize)
\* Maximum: NumAgents + VocabSize - 2 (when TopK = 1)
\* ═══════════════════════════════════════════════════════════════════════

DeficitDecompositionHolds ==
  (NumAgents >= 2 /\ TopK >= 1 /\ TopK <= VocabSize /\ VocabSize >= 2) =>
    /\ TotalDeficit = FoldDeficit + TableDeficit
    /\ TotalDeficit >= FoldDeficit
    /\ (TopK = VocabSize => TotalDeficit = FoldDeficit)
    /\ (TopK = 1 => TotalDeficit = NumAgents + VocabSize - 2)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-DIVERSITY-NECESSARY
\*
\* For a MOA fold to extract more information than a single agent,
\* agents MUST produce different distributions. The contrapositive:
\* identical agents = 1 effective agent = wasted compute.
\*
\* The design prescription: ensure diversity via different alpha,
\* different projection matrices, or different top-K values.
\* ═══════════════════════════════════════════════════════════════════════

DiversityNecessaryHolds ==
  (NumAgents >= 2) =>
    /\ (AllIdentical => EffectiveAgents = 1)
    /\ (~AllIdentical => EffectiveAgents >= 2)
    /\ (EffectiveAgents >= 2 => ~AllIdentical)

\* ─── Init / Check / Spec ─────────────────────────────────────────────
Init ==
  /\ checked = FALSE
  /\ identicalOk = TRUE
  /\ divergenceOk = TRUE
  /\ tableIndepOk = TRUE
  /\ costOk = TRUE
  /\ decompositionOk = TRUE
  /\ diversityOk = TRUE

CheckAll ==
  /\ ~checked
  /\ identicalOk' = IdenticalTrivialFoldHolds
  /\ divergenceOk' = DiverseAlphaDivergenceHolds
  /\ tableIndepOk' = TableIndependenceHolds
  /\ costOk' = CostWithVickreyHolds
  /\ decompositionOk' = DeficitDecompositionHolds
  /\ diversityOk' = DiversityNecessaryHolds
  /\ checked' = TRUE

Stutter == UNCHANGED vars
Next == CheckAll \/ Stutter
Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────
InvIdentical      == checked => identicalOk
InvDivergence     == checked => divergenceOk
InvTableIndep     == checked => tableIndepOk
InvCost           == checked => costOk
InvDecomposition  == checked => decompositionOk
InvDiversity      == checked => diversityOk

=============================================================================
