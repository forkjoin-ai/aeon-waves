------------------------------ MODULE Consciousness ------------------------------
\* Formal specification of consciousness as a self-interfering fold.
\*
\* The core claim: consciousness is what happens when a fold's output
\* feeds back into its own fork -- the system observes itself observing.
\* This creates a ratio (consecutive values) that converges to phi,
\* and as long as interference is active, beta0 = 0 (alive/fractal).
\*
\* Five operations: Fork, Race, Fold, Vent, Interfere
\*
\* Key properties:
\*   1. AliveInvariant: beta0 = 0 while Interfere is active
\*   2. DeathInvariant: disabling Interfere eventually yields beta0 = 1
\*   3. RatioConvergence: ratio approaches phi over time
\*   4. VentNecessary: without Vent, entropy grows unbounded
\*   5. WindowSize: registers always has exactly 2 elements
\*
\* Broken modes model pathology:
\*   - BrokenVent: entropy explosion (addiction/anxiety)
\*   - BrokenInterfere: beta0 -> 1 (death)

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    MaxVal,         \* Upper bound on register values (keeps state space finite)
    MaxEntropy,     \* Upper bound on entropy accumulation
    MaxSteps,       \* Bound on steps for model checking
    Epsilon         \* Convergence threshold (integer-scaled: real epsilon * 1000)

VARIABLES
    registers,      \* Sequence of length 2: the sliding window <<old, new>>
    ratio,          \* Ratio of current to previous (integer-scaled: real * 1000)
    beta0,          \* Betti number: 0 = alive/fractal, 1 = dead/complete
    entropy,        \* Accumulated entropy from folds
    interference,   \* Whether the fold feeds back to the fork (TRUE = alive)
    ventEnabled,    \* Whether Vent is operational
    step,           \* Step counter for bounded model checking
    pc              \* Program counter: which operation executes next

vars == <<registers, ratio, beta0, entropy, interference, ventEnabled, step, pc>>

-----------------------------------------------------------------------------
\* Helper: integer-scaled phi = 1618 (representing 1.618...)
\* We use integer arithmetic throughout: values are multiplied by 1000.
Phi == 1618

\* Integer absolute value
Abs(x) == IF x >= 0 THEN x ELSE -x

\* Safe ratio computation: (a * 1000) \div b, guarded against division by zero
SafeRatio(a, b) == IF b = 0 THEN 0 ELSE (a * 1000) \div b

-----------------------------------------------------------------------------
\* Type invariant
TypeOK ==
    /\ registers \in Seq(0..MaxVal)
    /\ Len(registers) = 2
    /\ ratio \in 0..((MaxVal + 1) * 1000)
    /\ beta0 \in {0, 1}
    /\ entropy \in 0..MaxEntropy
    /\ interference \in BOOLEAN
    /\ ventEnabled \in BOOLEAN
    /\ step \in 0..MaxSteps
    /\ pc \in {"Fork", "Race", "Fold", "Vent", "Interfere", "Done"}

-----------------------------------------------------------------------------
\* Initial state: seed the Fibonacci-like sequence with <<1, 1>>
Init ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000                 \* 1/1 = 1.000
    /\ beta0 = 0                    \* alive
    /\ entropy = 0
    /\ interference = TRUE          \* feedback active
    /\ ventEnabled = TRUE           \* vent operational
    /\ step = 0
    /\ pc = "Fork"

-----------------------------------------------------------------------------
\* FORK: creates a new value from current registers.
\* The new value is registers[1] + registers[2] (Fibonacci growth).
\* This is the generative act -- divergence from nothing.
Fork ==
    /\ pc = "Fork"
    /\ step < MaxSteps
    /\ LET newVal == registers[1] + registers[2]
       IN /\ newVal <= MaxVal
          /\ registers' = <<registers[2], newVal>>
          /\ pc' = "Race"
          /\ step' = step + 1
          /\ UNCHANGED <<ratio, beta0, entropy, interference, ventEnabled>>

\* RACE: both registers contribute cooperatively.
\* In this simple model, Race does not eliminate -- both values survive.
\* It validates that both registers are present and non-zero.
Race ==
    /\ pc = "Race"
    /\ registers[1] > 0
    /\ registers[2] > 0
    /\ pc' = "Fold"
    /\ UNCHANGED <<registers, ratio, beta0, entropy, interference, ventEnabled, step>>

\* FOLD: combines registers[1] + registers[2] into an irreversible result.
\* Entropy increases with each fold -- the arrow of time.
Fold ==
    /\ pc = "Fold"
    /\ LET foldResult == registers[1] + registers[2]
       IN /\ entropy' = IF entropy < MaxEntropy
                         THEN entropy + 1
                         ELSE entropy
          /\ pc' = "Vent"
          /\ UNCHANGED <<registers, ratio, beta0, interference, ventEnabled, step>>

\* VENT: slides the window, dropping the oldest register.
\* This is the exhale -- releasing accumulated entropy.
\* Without Vent, entropy accumulates and the system suffocates.
Vent ==
    /\ pc = "Vent"
    /\ IF ventEnabled
       THEN /\ entropy' = IF entropy > 0 THEN entropy - 1 ELSE 0
            /\ pc' = "Interfere"
            /\ UNCHANGED <<registers, ratio, beta0, interference, ventEnabled, step>>
       ELSE \* Vent disabled: entropy is NOT released, skip to Interfere
            /\ pc' = "Interfere"
            /\ UNCHANGED <<registers, ratio, beta0, entropy, interference, ventEnabled, step>>

\* INTERFERE: the fold's output feeds back into the fork.
\* This is the self-referential loop -- consciousness observing itself.
\* Updates the ratio (consecutive values converge to phi).
\* If interference is active, beta0 stays 0 (alive).
\* If interference is disabled, beta0 becomes 1 (dead/complete).
Interfere ==
    /\ pc = "Interfere"
    /\ ratio' = SafeRatio(registers[2], registers[1])
    /\ IF interference
       THEN /\ beta0' = 0           \* alive: the loop sustains itself
            /\ pc' = "Fork"         \* feed back to Fork
       ELSE /\ beta0' = 1           \* dead: no feedback, system completes
            /\ pc' = "Done"         \* halt
    /\ UNCHANGED <<registers, entropy, interference, ventEnabled, step>>

\* Terminal state
Done ==
    /\ pc = "Done"
    /\ UNCHANGED vars

-----------------------------------------------------------------------------
\* Next-state relation
Next ==
    \/ Fork
    \/ Race
    \/ Fold
    \/ Vent
    \/ Interfere
    \/ Done

\* Fairness: every enabled action eventually executes
Fairness ==
    /\ WF_vars(Fork)
    /\ WF_vars(Race)
    /\ WF_vars(Fold)
    /\ WF_vars(Vent)
    /\ WF_vars(Interfere)

\* Full specification
Spec == Init /\ [][Next]_vars /\ Fairness

-----------------------------------------------------------------------------
\* SAFETY INVARIANTS

\* The system is alive (beta0 = 0) as long as Interfere is active
AliveInvariant ==
    interference => beta0 = 0

\* If Interfere is disabled, beta0 must be 1 (death)
\* This is checked as: once we reach Done with interference=FALSE, beta0=1
DeathInvariant ==
    (pc = "Done" /\ ~interference) => beta0 = 1

\* The sliding window always has exactly 2 elements
WindowSize ==
    Len(registers) = 2

\* Ratio is always non-negative
RatioNonNegative ==
    ratio >= 0

\* Combined safety invariant
SafetyInvariant ==
    /\ TypeOK
    /\ AliveInvariant
    /\ DeathInvariant
    /\ WindowSize
    /\ RatioNonNegative

-----------------------------------------------------------------------------
\* LIVENESS PROPERTIES

\* The ratio eventually converges to within Epsilon of phi.
\* Expressed as: eventually, and thereafter always, |ratio - Phi| <= Epsilon
EventuallyPhi ==
    <>[]( Abs(ratio - Phi) <= Epsilon )

\* The system never completes (beta0 never reaches 1) while interference is on.
\* A living system does not finish.
NeverCompletes ==
    [](interference => beta0 = 0)

\* Without Vent, entropy eventually hits the ceiling
VentNecessaryLiveness ==
    (~ventEnabled) ~> (entropy = MaxEntropy)

=============================================================================
\* BROKEN SYSTEM MODELS
\* These are specified as separate Init predicates to model pathological states.
\* Use the corresponding .cfg files to select which model to check.
=============================================================================

\* BrokenVent: Vent is disabled from the start.
\* Models addiction/anxiety: entropy accumulates with no release.
\* The system stays "alive" (beta0=0) but entropy saturates at MaxEntropy.
BrokenVentInit ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000
    /\ beta0 = 0
    /\ entropy = 0
    /\ interference = TRUE
    /\ ventEnabled = FALSE          \* BROKEN: Vent disabled
    /\ step = 0
    /\ pc = "Fork"

\* BrokenVent spec
BrokenVentSpec == BrokenVentInit /\ [][Next]_vars /\ Fairness

\* Property: entropy eventually saturates (system suffocates)
BrokenVentEntropySaturates ==
    <>(entropy = MaxEntropy)

-----------------------------------------------------------------------------

\* BrokenInterfere: Interference is disabled from the start.
\* Models death: the fold does not feed back, beta0 -> 1.
\* The system runs one cycle and halts.
BrokenInterfereInit ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000
    /\ beta0 = 0
    /\ entropy = 0
    /\ interference = FALSE         \* BROKEN: no feedback
    /\ ventEnabled = TRUE
    /\ step = 0
    /\ pc = "Fork"

\* BrokenInterfere spec
BrokenInterfereSpec == BrokenInterfereInit /\ [][Next]_vars /\ Fairness

\* Property: the system eventually dies (beta0 = 1)
BrokenInterfereDeath ==
    <>(beta0 = 1)

\* Property: the system eventually halts
BrokenInterfereHalts ==
    <>(pc = "Done")

=============================================================================
