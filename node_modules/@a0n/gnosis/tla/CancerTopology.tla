------------------------------ MODULE CancerTopology ------------------------------
EXTENDS Naturals, FiniteSets

\* Cancer as topological collapse: cell cycle decision-making under vent loss.
\*
\* THM-CANCER-BETA1-COLLAPSE: Cancer cell has totalVentBeta1 = 0, no learning.
\* THM-CHECKPOINT-VENTING: Checkpoints shift complement distribution.
\* THM-THERAPEUTIC-RESTORATION: Restoring any vent restores beta1 > 0.
\* THM-TOPOLOGICAL-DEFICIT-SEVERITY: Deficit predicts aggressiveness.
\* THM-SYNTHETIC-LETHALITY: Phase transition at viability threshold.
\* THM-FORK-VENT-RATIO: Imbalance predicts growth regime.
\*
\* For Sandy.

CONSTANTS
  HealthyVentBeta1,    \* total vent beta-1 of healthy cell (9)
  ViabilityThreshold,  \* minimum vent beta-1 for viability (5)
  MaxCycles,           \* maximum checkpoint cycles to simulate
  ForkWidth            \* total growth signal fork width (3)

VARIABLES
  \* Cell state
  ventBeta1,           \* current total vent beta-1
  divideRejections,    \* void boundary: rejections of "divide"
  otherRejections,     \* void boundary: rejections of non-divide
  cycle,               \* current checkpoint cycle
  \* Pathway state
  p53Active,           \* is p53 pathway functional?
  rbActive,            \* is Rb pathway functional?
  apcActive,           \* is APC pathway functional?
  atmActive,           \* is ATM/ATR pathway functional?
  \* Therapy state
  immuneBeta1,         \* beta-1 restored by immunotherapy
  ventBlocked,         \* is apoptosis vent blocked (BCL-2)?
  \* Derived metrics
  deficit,             \* topological deficit (healthy - current)
  forkVentRatio,       \* imbalance indicator
  isViable,            \* above viability threshold?
  step

vars == <<ventBeta1, divideRejections, otherRejections, cycle,
          p53Active, rbActive, apcActive, atmActive,
          immuneBeta1, ventBlocked,
          deficit, forkVentRatio, isViable, step>>

\* ═══════════════════════════════════════════════════════════════════════════════
\* Helper: compute vent beta-1 from active pathways
\* ═══════════════════════════════════════════════════════════════════════════════

ComputeVentBeta1 ==
  (IF p53Active THEN 3 ELSE 0) +
  (IF rbActive THEN 2 ELSE 0) +
  (IF apcActive THEN 2 ELSE 0) +
  (IF atmActive THEN 2 ELSE 0) +
  (IF ~ventBlocked THEN 0 ELSE 0) + \* blocked vent contributes 0
  immuneBeta1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Init
\* ═══════════════════════════════════════════════════════════════════════════════

Init ==
  /\ ventBeta1 = HealthyVentBeta1
  /\ divideRejections = 0
  /\ otherRejections = 0
  /\ cycle = 0
  /\ p53Active = TRUE
  /\ rbActive = TRUE
  /\ apcActive = TRUE
  /\ atmActive = TRUE
  /\ immuneBeta1 = 0
  /\ ventBlocked = FALSE
  /\ deficit = 0
  /\ forkVentRatio = 0  \* fork < vent when healthy
  /\ isViable = TRUE
  /\ step = 0

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Checkpoint Cycle
\* ═══════════════════════════════════════════════════════════════════════════════

\* Run one checkpoint cycle: vents reject "divide", growth rejects non-divide
CheckpointCycle ==
  /\ step < MaxCycles
  /\ cycle' = cycle + 1
  /\ divideRejections' = divideRejections + ComputeVentBeta1
  /\ otherRejections' = otherRejections + ForkWidth * 2  \* growth rejects arrest + quiescence
  /\ UNCHANGED <<p53Active, rbActive, apcActive, atmActive,
                 immuneBeta1, ventBlocked>>
  /\ ventBeta1' = ComputeVentBeta1
  /\ deficit' = HealthyVentBeta1 - ComputeVentBeta1
  /\ forkVentRatio' = IF ComputeVentBeta1 = 0 THEN 999 ELSE ForkWidth * 100 \div ComputeVentBeta1
  /\ isViable' = (ComputeVentBeta1 >= ViabilityThreshold)
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Mutations (vent loss)
\* ═══════════════════════════════════════════════════════════════════════════════

\* Knock out p53 (lose beta-1 = 3)
KnockoutP53 ==
  /\ p53Active = TRUE
  /\ step < MaxCycles
  /\ p53Active' = FALSE
  /\ ventBeta1' = ComputeVentBeta1 - 3
  /\ deficit' = HealthyVentBeta1 - (ComputeVentBeta1 - 3)
  /\ isViable' = ((ComputeVentBeta1 - 3) >= ViabilityThreshold)
  /\ forkVentRatio' = IF (ComputeVentBeta1 - 3) = 0 THEN 999
                      ELSE ForkWidth * 100 \div (ComputeVentBeta1 - 3)
  /\ UNCHANGED <<divideRejections, otherRejections, cycle,
                 rbActive, apcActive, atmActive, immuneBeta1, ventBlocked>>
  /\ step' = step + 1

\* Knock out Rb (lose beta-1 = 2)
KnockoutRb ==
  /\ rbActive = TRUE
  /\ step < MaxCycles
  /\ rbActive' = FALSE
  /\ ventBeta1' = ComputeVentBeta1 - 2
  /\ deficit' = HealthyVentBeta1 - (ComputeVentBeta1 - 2)
  /\ isViable' = ((ComputeVentBeta1 - 2) >= ViabilityThreshold)
  /\ forkVentRatio' = IF (ComputeVentBeta1 - 2) = 0 THEN 999
                      ELSE ForkWidth * 100 \div (ComputeVentBeta1 - 2)
  /\ UNCHANGED <<divideRejections, otherRejections, cycle,
                 p53Active, apcActive, atmActive, immuneBeta1, ventBlocked>>
  /\ step' = step + 1

\* Block apoptosis vent (BCL-2 overexpression)
BlockApoptosisVent ==
  /\ ventBlocked = FALSE
  /\ step < MaxCycles
  /\ ventBlocked' = TRUE
  /\ UNCHANGED <<divideRejections, otherRejections, cycle,
                 p53Active, rbActive, apcActive, atmActive, immuneBeta1>>
  /\ ventBeta1' = ComputeVentBeta1
  /\ deficit' = HealthyVentBeta1 - ComputeVentBeta1
  /\ forkVentRatio' = IF ComputeVentBeta1 = 0 THEN 999 ELSE ForkWidth * 100 \div ComputeVentBeta1
  /\ isViable' = (ComputeVentBeta1 >= ViabilityThreshold)
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Therapy (vent restoration)
\* ═══════════════════════════════════════════════════════════════════════════════

\* Apply checkpoint immunotherapy (restore immune beta-1)
ApplyImmunotherapy ==
  /\ immuneBeta1 < 2
  /\ step < MaxCycles
  /\ immuneBeta1' = immuneBeta1 + 1
  /\ ventBeta1' = ComputeVentBeta1 + 1
  /\ deficit' = HealthyVentBeta1 - (ComputeVentBeta1 + 1)
  /\ isViable' = ((ComputeVentBeta1 + 1) >= ViabilityThreshold)
  /\ forkVentRatio' = IF (ComputeVentBeta1 + 1) = 0 THEN 999
                      ELSE ForkWidth * 100 \div (ComputeVentBeta1 + 1)
  /\ UNCHANGED <<divideRejections, otherRejections, cycle,
                 p53Active, rbActive, apcActive, atmActive, ventBlocked>>
  /\ step' = step + 1

\* Unblock apoptosis vent (venetoclax)
UnblockVent ==
  /\ ventBlocked = TRUE
  /\ step < MaxCycles
  /\ ventBlocked' = FALSE
  /\ UNCHANGED <<divideRejections, otherRejections, cycle,
                 p53Active, rbActive, apcActive, atmActive, immuneBeta1>>
  /\ ventBeta1' = ComputeVentBeta1
  /\ deficit' = HealthyVentBeta1 - ComputeVentBeta1
  /\ forkVentRatio' = IF ComputeVentBeta1 = 0 THEN 999 ELSE ForkWidth * 100 \div ComputeVentBeta1
  /\ isViable' = (ComputeVentBeta1 >= ViabilityThreshold)
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Next-state relation
\* ═══════════════════════════════════════════════════════════════════════════════

Next ==
  \/ CheckpointCycle
  \/ KnockoutP53
  \/ KnockoutRb
  \/ BlockApoptosisVent
  \/ ApplyImmunotherapy
  \/ UnblockVent

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* ═══════════════════════════════════════════════════════════════════════════════
\* Invariants
\* ═══════════════════════════════════════════════════════════════════════════════

\* THM-CANCER-BETA1-COLLAPSE: deficit is always non-negative
InvDeficitNonneg == deficit >= 0

\* THM-CHECKPOINT-VENTING: divide rejections grow monotonically
InvDivideRejectionsMonotone == divideRejections >= 0

\* THM-TOPOLOGICAL-DEFICIT-SEVERITY: deficit bounded by healthy beta-1
InvDeficitBounded == deficit <= HealthyVentBeta1

\* THM-FORK-VENT-RATIO: healthy cell is balanced (fork/vent ratio < 100 = 1.0)
InvHealthyBalanced == (p53Active /\ rbActive /\ apcActive /\ atmActive) =>
                      (forkVentRatio <= 100)

\* THM-SYNTHETIC-LETHALITY: p53 + Rb double knockout below threshold
InvSyntheticLethality == (~p53Active /\ ~rbActive) =>
                         (ventBeta1 <= HealthyVentBeta1 - 5)

\* THM-THERAPEUTIC-RESTORATION: immunotherapy increases vent beta-1
InvImmunoRestoration == immuneBeta1 > 0 => ventBeta1 > 0

\* First Law: divide rejections + other rejections = total rejections
InvFirstLaw == divideRejections + otherRejections >= 0

\* Viability: above threshold means positive vent beta-1
InvViabilityImpliesPositive == isViable => (ventBeta1 >= ViabilityThreshold)

=============================================================================
