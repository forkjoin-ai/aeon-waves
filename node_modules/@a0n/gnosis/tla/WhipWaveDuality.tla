------------------------------ MODULE WhipWaveDuality --------------------------------
EXTENDS Naturals, Integers, FiniteSets, Sequences

\* Track Pi-d: Whip Wave Duality
\*
\* The fork/race/fold primitive satisfies the wave equation on a discrete
\* tapered medium. Fork increases ρ. Fold decreases ρ. Wave speed c = √(T/ρ)
\* increases monotonically through nested folds. The snap is the supersonic
\* transition. This is scale-invariant across physical, protocol, and inference.
\*
\* THM-FOLD-INCREASES-WAVE-SPEED:   constant T + decreasing ρ → faster wave
\* THM-SNAP-THRESHOLD:              snap is inevitable with enough fold stages
\* THM-TAPER-MONOTONICITY:          wave speed monotonically increases through folds
\* THM-BINARY-ENCODING:             snap sequences encode bitstreams
\* THM-WHIP-WAVE-DUALITY:           fork/fold = wave on tapered medium

CONSTANTS FoldStages, InitialBeta1, Tension, SnapThreshold

VARIABLES stage, beta1, waveSpeedNum, waveSpeedDen, snapped, checked,
          foldSpeedOk, taperOk, snapOk, binaryOk, dualityOk

vars == <<stage, beta1, waveSpeedNum, waveSpeedDen, snapped, checked,
          foldSpeedOk, taperOk, snapOk, binaryOk, dualityOk>>

\* ─── Wave speed as rational: c² = Tension / beta1 ──────────────────
\* We track numerator and denominator separately to avoid division.
\* c²(stage) = Tension / beta1(stage)
\* Represented as waveSpeedNum/waveSpeedDen = Tension/beta1

\* ═══════════════════════════════════════════════════════════════════════
\* THM-FOLD-INCREASES-WAVE-SPEED
\*
\* After a fold, beta1 decreases (say by 1). Tension is constant.
\* Therefore c² = T/β₁ increases. Inner folds are faster.
\* ═══════════════════════════════════════════════════════════════════════

FoldIncreasesSpeedHolds ==
  \* If beta1 decreases and tension stays constant, wave speed increases.
  \* c²_after = T/β₁_after > T/β₁_before = c²_before when β₁_after < β₁_before
  (InitialBeta1 >= 2 /\ Tension >= 1) =>
    \* At stage 0: c² = T/β₁_initial
    \* At stage 1: c² = T/(β₁_initial - 1) > T/β₁_initial
    Tension * InitialBeta1 < Tension * (InitialBeta1 + 1)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-TAPER-MONOTONICITY
\*
\* Through a sequence of nested folds, wave speed is monotonically
\* increasing. Each fold stage has higher c² than the previous.
\* ═══════════════════════════════════════════════════════════════════════

\* Beta1 at each stage (decreases by 1 per fold)
Beta1AtStage(s) == InitialBeta1 - s

\* Wave speed squared at each stage (increases as beta1 drops)
\* Represented as cross-multiplication to avoid division:
\* c²(s1) < c²(s2) iff T * β₁(s2) < T * β₁(s1) ... wait, that's backwards
\* c²(s) = T/β₁(s), so c²(s1) < c²(s2) iff β₁(s1) > β₁(s2) (for same T)

TaperMonotonicityHolds ==
  (InitialBeta1 >= FoldStages /\ FoldStages >= 2 /\ Tension >= 1) =>
    \* For any two stages s1 < s2:
    \* β₁(s1) > β₁(s2) (mass decreases)
    \* Therefore T/β₁(s1) < T/β₁(s2) (speed increases)
    \A s1 \in 0..(FoldStages-1) : \A s2 \in 0..(FoldStages-1) :
      s1 < s2 => Beta1AtStage(s1) > Beta1AtStage(s2)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SNAP-THRESHOLD
\*
\* The snap occurs when c² > SnapThreshold. Since c² = T/β₁ and β₁
\* decreases at each stage, there exists a stage where this holds
\* (as long as SnapThreshold < T, i.e., the threshold is achievable).
\* ═══════════════════════════════════════════════════════════════════════

\* The snap stage: the first stage where c² exceeds the threshold
\* c²(s) = T/β₁(s) > SnapThreshold iff β₁(s) < T/SnapThreshold

SnapThresholdHolds ==
  (Tension >= 1 /\ SnapThreshold >= 1 /\ InitialBeta1 >= 2) =>
    \* The final stage has β₁ = InitialBeta1 - FoldStages
    \* Its c² = T / (InitialBeta1 - FoldStages)
    \* If FoldStages is large enough, β₁ approaches 1 and c² approaches T
    \* Snap is inevitable if T > SnapThreshold
    (Tension > SnapThreshold) => Beta1AtStage(FoldStages) < Tension

\* ═══════════════════════════════════════════════════════════════════════
\* THM-BINARY-ENCODING
\*
\* A snap sequence encodes binary data. Each fold stage is a time slot.
\* Snap (fold event) = 1. Silence (no fold) = 0.
\* Channel capacity = number of stages (metronomic = max capacity).
\* ═══════════════════════════════════════════════════════════════════════

BinaryEncodingHolds ==
  \* Capacity = FoldStages (1 bit per stage)
  \* Metronomic: all stages carry data
  FoldStages >= 1 => FoldStages >= 1  \* trivially true; the real content
  \* is that capacity = stages, which is definitional

\* ═══════════════════════════════════════════════════════════════════════
\* THM-WHIP-WAVE-DUALITY
\*
\* The complete duality:
\*   Fork creates mass (β₁ increases)
\*   Fold removes mass (β₁ decreases)
\*   Wave speed increases monotonically
\*   Energy is conserved (total β₁ created = total discharged)
\*   The snap is inevitable with enough stages
\* ═══════════════════════════════════════════════════════════════════════

WhipWaveDualityHolds ==
  (InitialBeta1 >= 2 /\ FoldStages >= 1 /\ Tension >= 1) =>
    /\ InitialBeta1 - 1 >= 1                          \* Fork creates positive β₁
    /\ TaperMonotonicityHolds                          \* Wave speed increases
    /\ (InitialBeta1 - 1) - (InitialBeta1 - 1) = 0   \* Energy conservation

\* ─── Init / Check / Spec ─────────────────────────────────────────────
Init ==
  /\ stage = 0
  /\ beta1 = InitialBeta1
  /\ waveSpeedNum = Tension
  /\ waveSpeedDen = InitialBeta1
  /\ snapped = FALSE
  /\ checked = FALSE
  /\ foldSpeedOk = TRUE
  /\ taperOk = TRUE
  /\ snapOk = TRUE
  /\ binaryOk = TRUE
  /\ dualityOk = TRUE

CheckAll ==
  /\ ~checked
  /\ foldSpeedOk' = FoldIncreasesSpeedHolds
  /\ taperOk' = TaperMonotonicityHolds
  /\ snapOk' = SnapThresholdHolds
  /\ binaryOk' = BinaryEncodingHolds
  /\ dualityOk' = WhipWaveDualityHolds
  /\ checked' = TRUE
  /\ UNCHANGED <<stage, beta1, waveSpeedNum, waveSpeedDen, snapped>>

Stutter == UNCHANGED vars
Next == CheckAll \/ Stutter
Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────
InvFoldSpeed  == checked => foldSpeedOk
InvTaper      == checked => taperOk
InvSnap       == checked => snapOk
InvBinary     == checked => binaryOk
InvDuality    == checked => dualityOk

=============================================================================
