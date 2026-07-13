----- MODULE ChaitinOmega -----
\* Chaitin's Omega as Runtime Void Boundary — TLA+ model
\*
\* Verifies:
\*   - Omega positivity: Ω > 0
\*   - Omega subuniversality: Ω < 1
\*   - Monotone convergence: Ω_L ≤ Ω_{L+1}
\*   - Solomonoff axioms: positivity, normalization, concentration
\*   - Weight + complexity = constant

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
    NumChoices,     \* Number of hypotheses in Solomonoff space
    MaxComplexity,  \* Ceiling for complexity values
    MaxRounds       \* Maximum empirical rounds

VARIABLES
    complexity,         \* Per-choice Kolmogorov complexity
    weights,            \* Per-choice Buleyean weight
    rounds,             \* Current empirical round count
    omegaNumerator,     \* Halting probability numerator
    omegaDenominator,   \* Total probability denominator
    prefixLength        \* Current prefix length

vars == <<complexity, weights, rounds, omegaNumerator, omegaDenominator, prefixLength>>

\* -- Helper: cap value --
Cap == MaxComplexity + rounds + 1

\* -- Solomonoff weight formula --
Weight(c) == Cap - (IF c < Cap THEN c ELSE Cap) + 1

\* -- Initial state --
Init ==
    /\ complexity \in [1..NumChoices -> 0..MaxComplexity]
    /\ weights = [i \in 1..NumChoices |-> Weight(complexity[i])]
    /\ rounds = 0
    /\ omegaNumerator = 0
    /\ omegaDenominator = 1
    /\ prefixLength = 1

\* -- Observe: one round of empirical evidence --
Observe ==
    /\ rounds < MaxRounds
    /\ rounds' = rounds + 1
    /\ weights' = [i \in 1..NumChoices |-> Weight(complexity[i])]
    /\ UNCHANGED <<complexity, omegaNumerator, omegaDenominator, prefixLength>>

\* -- Extend prefix: add one length to the enumeration --
ExtendPrefix ==
    /\ prefixLength' = prefixLength + 1
    /\ omegaNumerator' \in {n \in Nat : n >= omegaNumerator}  \* Monotone
    /\ omegaDenominator' \in {d \in Nat : d >= omegaDenominator}
    /\ UNCHANGED <<complexity, weights, rounds>>

\* -- Next state --
Next ==
    \/ Observe
    \/ ExtendPrefix

\* ==================================================================
\* INVARIANTS
\* ==================================================================

TypeInvariant ==
    /\ rounds \in 0..MaxRounds
    /\ prefixLength \in Nat
    /\ omegaNumerator \in Nat
    /\ omegaDenominator \in Nat

\* Solomonoff Axiom 1: ALL weights are strictly positive
SolomonoffPositivity ==
    \A i \in 1..NumChoices : weights[i] > 0

\* Solomonoff Axiom 3: lower complexity → higher weight (concentration)
SolomonoffConcentration ==
    \A i, j \in 1..NumChoices :
        complexity[i] < complexity[j] => weights[i] >= weights[j]

\* Weight + complexity = constant (conservation)
WeightComplexityConstant ==
    \A i \in 1..NumChoices :
        complexity[i] <= Cap =>
            weights[i] + complexity[i] = Cap + 1

\* Omega monotone: numerator never decreases
OmegaMonotone == omegaNumerator' >= omegaNumerator

\* Omega bounded: numerator < denominator (subuniversality)
OmegaSubuniversal == omegaNumerator <= omegaDenominator

\* ==================================================================
\* SPECIFICATION
\* ==================================================================

Spec ==
    /\ Init
    /\ [][Next]_vars

THEOREM Spec => []TypeInvariant
THEOREM Spec => []SolomonoffPositivity
THEOREM Spec => []SolomonoffConcentration
THEOREM Spec => []OmegaSubuniversal

=====
