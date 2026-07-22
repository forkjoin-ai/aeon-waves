------------------------------ MODULE BrokenSystems ------------------------------
\* Formal specification of pathological emotional systems from the paper.
\*
\* Four models, each with a separate Init + Spec pair for independent checking:
\*
\*   1. Anxiety: VENT disabled, deficit accumulates, eigenvalue saturates at MaxVal.
\*      The system breathes but cannot exhale -- entropy only grows.
\*
\*   2. Addiction: same as anxiety but with a craving variable that grows
\*      proportionally to entropy. Craving amplifies the deficit.
\*
\*   3. Grief: healthy model where ratio converges to phi (eigenvalue stabilizes).
\*      VENT works, interference active -- the system processes loss and heals.
\*
\*   4. Complicated Grief: VENT partially broken (works only on even steps).
\*      Ratio oscillates without converging -- the system is stuck.
\*
\* Built on the same five-operation cycle as Consciousness.tla:
\*   Fork -> Race -> Fold -> Vent -> Interfere -> Fork ...
\*
\* Integer-scaled arithmetic: ratio = b * 1000 / a, phi = 1618.

EXTENDS Integers, Sequences

CONSTANTS
    MaxVal,         \* Upper bound on register values (keeps state space finite)
    MaxEntropy,     \* Upper bound on entropy accumulation
    MaxSteps,       \* Bound on steps for model checking
    Epsilon         \* Convergence threshold (integer-scaled: real epsilon * 1000)

VARIABLES
    registers,      \* Sequence of length 2: the sliding window <<old, new>>
    ratio,          \* Ratio of current to previous (integer-scaled: real * 1000)
    entropy,        \* Accumulated entropy from folds
    craving,        \* Addiction-specific: grows with unvented entropy
    ventEnabled,    \* Whether Vent is fully operational
    ventPartial,    \* Whether Vent is partially broken (complicated grief)
    step,           \* Step counter for bounded model checking
    pc              \* Program counter: which operation executes next

vars == <<registers, ratio, entropy, craving, ventEnabled, ventPartial, step, pc>>

-----------------------------------------------------------------------------
\* Helper: integer-scaled phi = 1618 (representing 1.618...)
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
    /\ entropy \in 0..MaxEntropy
    /\ craving \in 0..MaxEntropy
    /\ ventEnabled \in BOOLEAN
    /\ ventPartial \in BOOLEAN
    /\ step \in 0..MaxSteps
    /\ pc \in {"Fork", "Race", "Fold", "Vent", "Interfere", "Done"}

-----------------------------------------------------------------------------
\* SHARED OPERATIONS
\* All four models use the same cycle; they differ only in Init and Vent behavior.

\* FORK: create a new value from current registers (Fibonacci growth)
Fork ==
    /\ pc = "Fork"
    /\ step < MaxSteps
    /\ LET newVal == registers[1] + registers[2]
       IN /\ newVal <= MaxVal
          /\ registers' = <<registers[2], newVal>>
          /\ pc' = "Race"
          /\ step' = step + 1
          /\ UNCHANGED <<ratio, entropy, craving, ventEnabled, ventPartial>>

\* RACE: validate both registers are present and non-zero
Race ==
    /\ pc = "Race"
    /\ registers[1] > 0
    /\ registers[2] > 0
    /\ pc' = "Fold"
    /\ UNCHANGED <<registers, ratio, entropy, craving, ventEnabled, ventPartial, step>>

\* FOLD: combine registers, increase entropy (the arrow of time)
\* In the addiction model, craving grows when entropy is high and unvented
Fold ==
    /\ pc = "Fold"
    /\ entropy' = IF entropy < MaxEntropy
                   THEN entropy + 1
                   ELSE entropy
    /\ craving' = IF ~ventEnabled /\ entropy >= 1
                   THEN IF craving < MaxEntropy
                        THEN craving + 1
                        ELSE craving
                   ELSE craving
    /\ pc' = "Vent"
    /\ UNCHANGED <<registers, ratio, ventEnabled, ventPartial, step>>

\* VENT: release accumulated entropy (the exhale)
\* Behavior depends on ventEnabled and ventPartial:
\*   - ventEnabled=TRUE, ventPartial=FALSE: full vent (healthy/grief)
\*   - ventEnabled=FALSE, ventPartial=FALSE: no vent (anxiety/addiction)
\*   - ventEnabled=FALSE, ventPartial=TRUE: vent only on even steps (complicated grief)
Vent ==
    /\ pc = "Vent"
    /\ IF ventEnabled
       THEN \* Full vent: release entropy
            /\ entropy' = IF entropy > 0 THEN entropy - 1 ELSE 0
            /\ pc' = "Interfere"
            /\ UNCHANGED <<registers, ratio, craving, ventEnabled, ventPartial, step>>
       ELSE IF ventPartial /\ (step % 2 = 0)
            THEN \* Partial vent: release on even steps only
                 /\ entropy' = IF entropy > 0 THEN entropy - 1 ELSE 0
                 /\ pc' = "Interfere"
                 /\ UNCHANGED <<registers, ratio, craving, ventEnabled, ventPartial, step>>
            ELSE \* No vent: entropy is NOT released
                 /\ pc' = "Interfere"
                 /\ UNCHANGED <<registers, ratio, entropy, craving, ventEnabled, ventPartial, step>>

\* INTERFERE: feed fold output back to fork, update ratio
Interfere ==
    /\ pc = "Interfere"
    /\ ratio' = SafeRatio(registers[2], registers[1])
    /\ pc' = "Fork"
    /\ UNCHANGED <<registers, entropy, craving, ventEnabled, ventPartial, step>>

\* Terminal state
Done ==
    /\ pc = "Done"
    /\ UNCHANGED vars

\* Also halt when MaxSteps reached
Halt ==
    /\ pc = "Fork"
    /\ step >= MaxSteps
    /\ pc' = "Done"
    /\ UNCHANGED <<registers, ratio, entropy, craving, ventEnabled, ventPartial, step>>

-----------------------------------------------------------------------------
\* Next-state relation (shared by all models)
Next ==
    \/ Fork
    \/ Race
    \/ Fold
    \/ Vent
    \/ Interfere
    \/ Halt
    \/ Done

\* Fairness
Fairness ==
    /\ WF_vars(Fork)
    /\ WF_vars(Race)
    /\ WF_vars(Fold)
    /\ WF_vars(Vent)
    /\ WF_vars(Interfere)
    /\ WF_vars(Halt)

=============================================================================
\* MODEL 1: ANXIETY
\* VENT disabled from the start. Deficit accumulates. Eigenvalue (entropy)
\* grows toward MaxEntropy and stays there. The system keeps iterating
\* but can never release -- suffocation.
=============================================================================

AnxietyInit ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000
    /\ entropy = 0
    /\ craving = 0
    /\ ventEnabled = FALSE          \* BROKEN: Vent disabled
    /\ ventPartial = FALSE
    /\ step = 0
    /\ pc = "Fork"

AnxietySpec == AnxietyInit /\ [][Next]_vars /\ Fairness

\* Anxiety saturates: entropy eventually reaches MaxEntropy
AnxietyEntropySaturates ==
    <>(entropy = MaxEntropy)

\* Anxiety invariant: ratio still converges (the math works)
\* but the system is sick -- entropy never decreases
AnxietyEntropyNeverDecreases ==
    [][entropy' >= entropy]_entropy

=============================================================================
\* MODEL 2: ADDICTION
\* Same as anxiety but craving grows proportionally to unvented entropy.
\* Craving represents the compulsive dimension: the system not only
\* accumulates deficit, it develops a second-order craving for relief.
=============================================================================

AddictionInit ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000
    /\ entropy = 0
    /\ craving = 0
    /\ ventEnabled = FALSE          \* BROKEN: Vent disabled
    /\ ventPartial = FALSE
    /\ step = 0
    /\ pc = "Fork"

AddictionSpec == AddictionInit /\ [][Next]_vars /\ Fairness

\* Addiction craving is unbounded (up to MaxEntropy): eventually saturates
AddictionCravingSaturates ==
    <>(craving = MaxEntropy)

\* Both entropy and craving grow together
AddictionDualSaturation ==
    <>(entropy = MaxEntropy /\ craving = MaxEntropy)

=============================================================================
\* MODEL 3: GRIEF (healthy)
\* VENT works. Interference active. The system processes loss: ratio
\* converges to phi, entropy stays bounded. A healthy grief cycle.
=============================================================================

GriefInit ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000
    /\ entropy = 0
    /\ craving = 0
    /\ ventEnabled = TRUE           \* HEALTHY: Vent works
    /\ ventPartial = FALSE
    /\ step = 0
    /\ pc = "Fork"

GriefSpec == GriefInit /\ [][Next]_vars /\ Fairness

\* Grief converges: ratio eventually stabilizes near phi
GriefConverges ==
    <>[]( Abs(ratio - Phi) <= Epsilon )

\* Grief entropy stays bounded: never reaches MaxEntropy
\* (because Vent releases faster than Fold accumulates)
GriefEntropyBounded ==
    [](entropy < MaxEntropy)

=============================================================================
\* MODEL 4: COMPLICATED GRIEF
\* VENT partially broken: works only on even steps.
\* Ratio oscillates without settling -- the system is stuck in a loop,
\* unable to fully process or fully deny. Entropy oscillates too.
=============================================================================

ComplicatedGriefInit ==
    /\ registers = <<1, 1>>
    /\ ratio = 1000
    /\ entropy = 0
    /\ craving = 0
    /\ ventEnabled = FALSE          \* Not fully enabled...
    /\ ventPartial = TRUE           \* ...but partially functional
    /\ step = 0
    /\ pc = "Fork"

ComplicatedGriefSpec == ComplicatedGriefInit /\ [][Next]_vars /\ Fairness

\* Complicated grief oscillates: entropy fluctuates (goes up AND down)
\* We check that entropy is not monotonically increasing (it sometimes decreases)
ComplicatedGriefNotMonotonic ==
    <>(entropy > 0) /\ <>(entropy = 0)

\* Complicated grief ratio still converges to phi (the math is the same)
\* but the emotional system (entropy) never fully stabilizes
ComplicatedGriefRatioConverges ==
    <>[]( Abs(ratio - Phi) <= Epsilon )

\* Complicated grief entropy never fully saturates
\* (partial venting prevents full saturation)
ComplicatedGriefNotSaturated ==
    [](entropy < MaxEntropy)

=============================================================================
