-------------------------- MODULE FibonacciConvergence --------------------------
\* Formal specification of the Fibonacci sequence as a state machine.
\*
\* The Fibonacci ratio b/a converges to phi (the golden ratio, ~1.618).
\* This spec models the iteration as a bounded state machine and verifies:
\*   1. The ratio stays within [1000, 2000] (i.e., 1.0 to 2.0) after step 0
\*   2. The ratio eventually stabilizes within Epsilon of 1618 (phi * 1000)
\*   3. Universality: different seed values converge to the same ratio
\*
\* Integer-scaled arithmetic throughout: ratio = b * 1000 / a.

EXTENDS Integers, Sequences

CONSTANTS
    Seed1,          \* First seed value (e.g., 1)
    Seed2,          \* Second seed value (e.g., 1)
    MaxSteps,       \* Bound on iteration count
    Epsilon         \* Convergence threshold (integer-scaled: real epsilon * 1000)

VARIABLES
    a,              \* First register (older value)
    b,              \* Second register (newer value)
    ratio,          \* b * 1000 / a (integer-scaled ratio)
    step            \* Step counter

vars == <<a, b, ratio, step>>

-----------------------------------------------------------------------------
\* Helper: integer-scaled phi = 1618 (representing 1.618...)
Phi == 1618

\* Integer absolute value
Abs(x) == IF x >= 0 THEN x ELSE -x

\* Safe ratio computation: (num * 1000) \div den, guarded against division by zero
SafeRatio(num, den) == IF den = 0 THEN 0 ELSE (num * 1000) \div den

-----------------------------------------------------------------------------
\* Type invariant
TypeOK ==
    /\ a \in Nat \ {0}
    /\ b \in Nat \ {0}
    /\ ratio \in Nat
    /\ step \in 0..MaxSteps

-----------------------------------------------------------------------------
\* Initial state: seed the sequence with Seed1, Seed2
Init ==
    /\ a = Seed1
    /\ b = Seed2
    /\ ratio = SafeRatio(Seed2, Seed1)
    /\ step = 0

\* STEP: advance the Fibonacci recurrence.
\* a' = b, b' = a + b, ratio' = b' * 1000 / a'
Step ==
    /\ step < MaxSteps
    /\ LET newA == b
           newB == a + b
       IN /\ a' = newA
          /\ b' = newB
          /\ ratio' = SafeRatio(newB, newA)
          /\ step' = step + 1

\* Terminal: hold state after MaxSteps
Done ==
    /\ step = MaxSteps
    /\ UNCHANGED vars

-----------------------------------------------------------------------------
\* Next-state relation
Next ==
    \/ Step
    \/ Done

\* Fairness: Step eventually executes when enabled
Fairness == WF_vars(Step)

\* Full specification
Spec == Init /\ [][Next]_vars /\ Fairness

-----------------------------------------------------------------------------
\* SAFETY INVARIANTS

\* After the first step, ratio is always between 1000 and 2000 (i.e., 1.0 to 2.0)
\* The Fibonacci ratio oscillates between 1 and 2, converging to phi from both sides.
RatioBounded ==
    step > 0 => (ratio >= 1000 /\ ratio <= 2000)

\* Registers are always positive (Fibonacci with positive seeds stays positive)
RegistersPositive ==
    /\ a > 0
    /\ b > 0

\* Combined safety invariant
SafetyInvariant ==
    /\ TypeOK
    /\ RatioBounded
    /\ RegistersPositive

-----------------------------------------------------------------------------
\* LIVENESS PROPERTIES

\* The ratio eventually converges to within Epsilon of phi.
\* Expressed as: eventually, and thereafter always, |ratio - Phi| <= Epsilon
EventuallyPhi ==
    <>[]( Abs(ratio - Phi) <= Epsilon )

\* The system eventually completes all steps
EventuallyDone ==
    <>(step = MaxSteps)

=============================================================================
\* UNIVERSALITY VARIANT
\* Use a separate .cfg with different seeds (e.g., Seed1=2, Seed2=7)
\* to verify that convergence to phi is independent of initial conditions.
\* The same SafetyInvariant and EventuallyPhi hold for any positive seeds.
=============================================================================
