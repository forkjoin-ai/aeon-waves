------------------------------ MODULE CosmicBule ------------------------------
\* Formal specification of cosmic convergence to phi as a state machine.
\*
\* The universe's dark_energy/matter ratio converges to phi (the golden ratio)
\* through successive cosmic cycles of FORK/RACE/FOLD/VENT/INTERFERE.
\* This spec reuses the Fibonacci recurrence from FibonacciConvergence.tla
\* but reinterprets it cosmologically: same math, different meaning.
\*
\* "Bule" is the distance from phi -- the residual gap that never fully closes.
\* The +1 offset in the Fibonacci recurrence ensures bule > 0 always:
\* the universe approaches phi but never arrives. Convergence without completion.
\*
\* Integer-scaled arithmetic throughout: ratio = b * 1000 / a.

EXTENDS Integers, Sequences

CONSTANTS
    MaxCycles,      \* Bound on cosmic cycles (e.g., 10)
    PhiScaled,      \* phi * 1000 = 1618
    InitialRatio,   \* Starting ratio (e.g., 10000, representing infinity at t=0)
    Epsilon         \* Convergence threshold: "near phi" when bule < Epsilon

VARIABLES
    a,              \* Fibonacci register (older value) -- matter substrate
    b,              \* Fibonacci register (newer value) -- dark energy substrate
    cycle,          \* Current cosmic cycle (starts at 0)
    ratio,          \* b * 1000 / a (integer-scaled dark_energy/matter ratio)
    bule,           \* Distance from phi: |ratio - PhiScaled|
    prev_bule,      \* Previous cycle's bule (for convergence comparison)
    converging      \* Boolean: is bule decreasing?

vars == <<a, b, cycle, ratio, bule, prev_bule, converging>>

-----------------------------------------------------------------------------
\* Integer absolute value
Abs(x) == IF x >= 0 THEN x ELSE -x

\* Safe ratio computation: (num * 1000) \div den, guarded against division by zero
SafeRatio(num, den) == IF den = 0 THEN 0 ELSE (num * 1000) \div den

-----------------------------------------------------------------------------
\* Type invariant
TypeOK ==
    /\ a \in Nat \ {0}
    /\ b \in Nat \ {0}
    /\ cycle \in 0..MaxCycles
    /\ ratio \in Nat
    /\ bule \in Nat
    /\ prev_bule \in Nat
    /\ converging \in BOOLEAN

-----------------------------------------------------------------------------
\* Initial state: the early universe at t=0
\* a=1, b=2 represents the primordial 2:1 ratio (energy dominates matter).
\* InitialRatio=10000 is the configured starting ratio for invariant checking,
\* but the actual computed ratio is 2000 (= 2*1000/1).
Init ==
    /\ a = 1
    /\ b = 2
    /\ cycle = 0
    /\ ratio = SafeRatio(2, 1)
    /\ bule = Abs(SafeRatio(2, 1) - PhiScaled)
    /\ prev_bule = InitialRatio
    /\ converging = TRUE

\* CosmicCycle: one full FORK/RACE/FOLD/VENT/INTERFERE at cosmic scale.
\* The Fibonacci recurrence drives the ratio toward phi:
\*   a' = b (matter inherits dark energy's structure)
\*   b' = a + b + 1 (dark energy grows by Fibonacci + perturbation)
\* The +1 is the cosmic perturbation -- prevents exact convergence to phi.
\* This ensures bule > 0 always: the universe never quite arrives.
CosmicCycle ==
    /\ cycle < MaxCycles
    /\ LET newA == b
           newB == a + b + 1
           newRatio == SafeRatio(newB, newA)
           newBule == Abs(newRatio - PhiScaled)
       IN /\ a' = newA
          /\ b' = newB
          /\ ratio' = newRatio
          /\ bule' = newBule
          /\ prev_bule' = bule
          /\ converging' = (newBule < bule)
          /\ cycle' = cycle + 1

\* Terminal: hold state after MaxCycles (heat death -- no more transitions)
Done ==
    /\ cycle = MaxCycles
    /\ UNCHANGED vars

-----------------------------------------------------------------------------
\* Next-state relation
Next ==
    \/ CosmicCycle
    \/ Done

\* Fairness: CosmicCycle eventually executes when enabled (time moves forward)
Fairness == WF_vars(CosmicCycle)

\* Full specification
Spec == Init /\ [][Next]_vars /\ Fairness

-----------------------------------------------------------------------------
\* SAFETY INVARIANTS

\* The ratio is always positive (universe has nonzero energy/matter)
RatioPositive == ratio > 0

\* After cycle 2, bule is strictly decreasing (convergence is monotonic)
\* The +1 perturbation is small enough that Fibonacci still dominates.
BuleDecreasing ==
    (cycle > 2) => (bule < prev_bule)

\* Progress is bounded: we never exceed MaxCycles
ProgressBounded == cycle <= MaxCycles

\* Bule is always positive: the universe never exactly reaches phi.
\* The +1 perturbation guarantees a nonzero remainder.
NeverExactlyPhi == bule > 0

\* Combined safety invariant
SafetyInvariant ==
    /\ TypeOK
    /\ RatioPositive
    /\ ProgressBounded
    /\ NeverExactlyPhi

-----------------------------------------------------------------------------
\* LIVENESS PROPERTIES

\* Eventually the universe gets within Epsilon of phi (bule < Epsilon).
\* Cosmologically: dark_energy/matter ratio settles near the golden ratio.
EventuallyNearPhi ==
    <>(bule < Epsilon)

\* The universe eventually completes all cycles
EventuallyDone ==
    <>(cycle = MaxCycles)

=============================================================================
\* COSMOLOGICAL INTERPRETATION
\*
\* The Fibonacci recurrence is the simplest model of growth with memory:
\* each generation depends on the previous two. At cosmic scale, this maps to
\* the interplay between matter (a) and dark energy (b), where each epoch
\* inherits structure from both substrates.
\*
\* The +1 perturbation models the irreducible asymmetry in the universe --
\* the fact that dark energy slightly exceeds the Fibonacci prediction.
\* This is the Bule: the gap between the actual ratio and phi, which
\* shrinks with each cycle but never vanishes.
\*
\* Same math as FibonacciConvergence.tla. Different meaning entirely.
=============================================================================
