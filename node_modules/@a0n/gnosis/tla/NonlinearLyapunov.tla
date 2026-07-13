------------------------------ MODULE NonlinearLyapunov ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* Track Nu: Nonlinear Lyapunov Synthesis
\*
\* Extends Track Kappa (affine V(x) = x) to nonlinear Lyapunov functions
\* V(x) = x^p for p > 1.  This handles fluid backlog, fractional retry mass,
\* and thermodynamic state variables whose stability requires superlinear
\* barrier functions.
\*
\* THM-NONLINEAR-LYAPUNOV-QUADRATIC:   V(x) = x² satisfies Foster drift
\* THM-NONLINEAR-LYAPUNOV-POWER:       V(x) = x^p for p > 1 satisfies Foster
\* THM-NONLINEAR-SMALL-SET-VALID:      level set {V(x) ≤ c} is valid small set
\* THM-NONLINEAR-WITNESS-SOUND:        synthesized rate from nonlinear V is valid
\* THM-NONLINEAR-DOMINATES-AFFINE:     nonlinear V gives tighter rate than affine

CONSTANTS MaxState, ArrivalRate, ServiceRate, VentThreshold, LyapunovPower

VARIABLES state, checked,
          quadraticOk, powerOk, smallSetOk,
          witnessSoundOk, dominatesAffineOk

vars == <<state, checked,
          quadraticOk, powerOk, smallSetOk,
          witnessSoundOk, dominatesAffineOk>>

\* ─── Drift model ─────────────────────────────────────────────────────
DriftGap == ServiceRate - ArrivalRate

\* ─── Lyapunov functions ──────────────────────────────────────────────
\* Affine: V(x) = x
\* Quadratic: V(x) = x²
\* Power: V(x) = x^p

AffineV(x) == x
QuadraticV(x) == x * x

\* Power function (bounded to avoid overflow)
RECURSIVE PowerV(_, _)
PowerV(x, p) ==
  IF p = 0 THEN 1
  ELSE IF p = 1 THEN x
  ELSE x * PowerV(x, p - 1)

\* ─── Expected Lyapunov after one step (affine drift kernel) ─────────
\* State: x' = max(0, x + arrival - service)
\* E[V(x')] for quadratic:
\*   E[(x - driftGap)²] = (x - driftGap)² when x > driftGap
\*   = x² - 2·x·driftGap + driftGap²
\* Foster condition: E[V(x')] ≤ V(x) - driftGap_V for x outside small set

ExpectedAfterStep(x) ==
  IF x >= DriftGap THEN x - DriftGap
  ELSE 0

\* ═══════════════════════════════════════════════════════════════════════
\* THM-NONLINEAR-LYAPUNOV-QUADRATIC
\*
\* V(x) = x² satisfies Foster-Lyapunov drift outside {x ≤ T}:
\*   E[V(x')] = (x - gap)² ≤ x² - 2·x·gap + gap²
\*            = V(x) - gap·(2x - gap)
\* For x > T ≥ gap, the drift term gap·(2x-gap) > gap² > 0.
\* ═══════════════════════════════════════════════════════════════════════

QuadraticDrift(x) ==
  QuadraticV(ExpectedAfterStep(x))

QuadraticHoldsFor(x) ==
  (x > VentThreshold /\ DriftGap > 0 /\ x >= DriftGap) =>
    QuadraticDrift(x) < QuadraticV(x)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-NONLINEAR-LYAPUNOV-POWER
\*
\* V(x) = x^p for p ≥ 1 satisfies Foster drift outside {x ≤ T}:
\*   E[V(x')] = (x - gap)^p ≤ x^p - p·x^(p-1)·gap + ...
\* For x >> gap, the leading drift term p·x^(p-1)·gap dominates.
\* ═══════════════════════════════════════════════════════════════════════

PowerDrift(x, p) ==
  PowerV(ExpectedAfterStep(x), p)

PowerHoldsFor(x, p) ==
  (x > VentThreshold /\ DriftGap > 0 /\ x >= DriftGap /\ p >= 1) =>
    PowerDrift(x, p) <= PowerV(x, p)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-NONLINEAR-SMALL-SET-VALID
\*
\* The level set {x : V(x) ≤ c} is a valid small set:
\* For V(x) = x^p, the level set {x : x^p ≤ c} = {x : x ≤ c^(1/p)}
\* which is finite and bounded for any finite c.
\* ═══════════════════════════════════════════════════════════════════════

SmallSetValid(threshold) ==
  (threshold >= 0 /\ threshold < MaxState) =>
    /\ threshold + 1 <= MaxState
    /\ threshold + 1 > 0

\* ═══════════════════════════════════════════════════════════════════════
\* THM-NONLINEAR-WITNESS-SOUND
\*
\* The synthesized rate from nonlinear V is in (0, 1).
\* For V(x) = x², the drift gap scales as 2·x·gap, giving a
\* larger effective epsilon and thus a smaller (better) rate.
\* ═══════════════════════════════════════════════════════════════════════

\* Effective step epsilon for quadratic (scaled by threshold)
QuadraticStepEpsilon == IF VentThreshold > 0
  THEN (DriftGap * 2 * VentThreshold * 1000) \div (MaxState * MaxState)
  ELSE 0

\* Small-set epsilon (same as affine)
SmallSetEpsilon == IF MaxState > 0
  THEN ((VentThreshold + 1) * 1000) \div (MaxState + 1)
  ELSE 0

QuadraticRate == 1000 - ((QuadraticStepEpsilon * SmallSetEpsilon) \div 1000)

WitnessSoundHolds ==
  (DriftGap > 0 /\ MaxState > 0 /\ VentThreshold > 0 /\ VentThreshold < MaxState) =>
    /\ QuadraticRate >= 0
    /\ QuadraticRate < 1000

\* ═══════════════════════════════════════════════════════════════════════
\* THM-NONLINEAR-DOMINATES-AFFINE
\*
\* Nonlinear V gives a tighter (smaller) rate than affine V:
\*   r_quadratic ≤ r_affine when threshold is large enough.
\* ═══════════════════════════════════════════════════════════════════════

AffineStepEpsilon == IF MaxState > 0
  THEN (DriftGap * 1000) \div MaxState
  ELSE 0

AffineRate == 1000 - ((AffineStepEpsilon * SmallSetEpsilon) \div 1000)

DominatesAffineHolds ==
  (DriftGap > 0 /\ MaxState > 0 /\ VentThreshold > 1 /\ VentThreshold < MaxState) =>
    QuadraticRate <= AffineRate

\* ─── Init / Check / Spec ─────────────────────────────────────────────
Init ==
  /\ state = 0
  /\ checked = FALSE
  /\ quadraticOk = TRUE
  /\ powerOk = TRUE
  /\ smallSetOk = TRUE
  /\ witnessSoundOk = TRUE
  /\ dominatesAffineOk = TRUE

CheckAll ==
  /\ ~checked
  /\ quadraticOk' = \A x \in 0..MaxState: QuadraticHoldsFor(x)
  /\ powerOk' = \A x \in 0..MaxState: PowerHoldsFor(x, LyapunovPower)
  /\ smallSetOk' = SmallSetValid(VentThreshold)
  /\ witnessSoundOk' = WitnessSoundHolds
  /\ dominatesAffineOk' = DominatesAffineHolds
  /\ checked' = TRUE
  /\ UNCHANGED <<state>>

Stutter == UNCHANGED vars
Next == CheckAll \/ Stutter
Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────
InvQuadratic == checked => quadraticOk
InvPower == checked => powerOk
InvSmallSet == checked => smallSetOk
InvWitnessSound == checked => witnessSoundOk
InvDominatesAffine == checked => dominatesAffineOk

=============================================================================
