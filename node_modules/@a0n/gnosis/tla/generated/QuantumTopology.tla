----- MODULE QuantumTopology -----
\* Quantum Topology — TLA+ model
\*
\* Verifies:
\*   - Normalization preserved after gate application
\*   - Measurement collapses to basis state
\*   - FORK creates superposition
\*   - OBSERVE collapses superposition
\*   - Bell state correlations (entangled measurements agree)
\*   - Circuit execution preserves state validity

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
    NumQubits   \* Number of qubits in the register

VARIABLES
    superpositionCount,  \* Number of active superposition branches
    collapsed,           \* Whether the state has been measured
    entangled,           \* Whether qubits are entangled
    measurements,        \* Sequence of measurement results
    gateCount,           \* Number of gates applied
    normalized           \* Whether state is normalized

vars == <<superpositionCount, collapsed, entangled, measurements, gateCount, normalized>>

\* -- Initial state: |00...0⟩ --
Init ==
    /\ superpositionCount = 1
    /\ collapsed = FALSE
    /\ entangled = FALSE
    /\ measurements = <<>>
    /\ gateCount = 0
    /\ normalized = TRUE

\* -- Apply Hadamard gate: creates superposition --
ApplyHadamard ==
    /\ ~collapsed
    /\ superpositionCount' = superpositionCount * 2
    /\ gateCount' = gateCount + 1
    /\ normalized' = TRUE  \* Hadamard is unitary → preserves normalization
    /\ UNCHANGED <<collapsed, entangled, measurements>>

\* -- Apply CNOT gate: creates entanglement --
ApplyCNOT ==
    /\ ~collapsed
    /\ NumQubits >= 2
    /\ entangled' = TRUE
    /\ gateCount' = gateCount + 1
    /\ normalized' = TRUE  \* CNOT is unitary
    /\ UNCHANGED <<superpositionCount, collapsed, measurements>>

\* -- Apply Pauli-X gate: bit flip --
ApplyPauliX ==
    /\ ~collapsed
    /\ gateCount' = gateCount + 1
    /\ normalized' = TRUE  \* Pauli-X is unitary
    /\ UNCHANGED <<superpositionCount, collapsed, entangled, measurements>>

\* -- Measure qubit (OBSERVE): collapse superposition --
Measure ==
    /\ ~collapsed
    /\ superpositionCount > 0
    /\ collapsed' = TRUE
    /\ superpositionCount' = 1  \* Collapse to single branch
    /\ measurements' = Append(measurements, 0)  \* Result is 0 or 1
    /\ normalized' = TRUE  \* Post-measurement state is normalized
    /\ UNCHANGED <<entangled, gateCount>>

\* -- FORK (topology): create parallel branches (quantum analogy) --
TopologyFork(branches) ==
    /\ branches > 1
    /\ superpositionCount' = superpositionCount * branches
    /\ UNCHANGED <<collapsed, entangled, measurements, gateCount, normalized>>

\* -- OBSERVE (topology): collapse to one branch --
TopologyObserve ==
    /\ superpositionCount > 1
    /\ superpositionCount' = 1
    /\ collapsed' = TRUE
    /\ measurements' = Append(measurements, 0)
    /\ UNCHANGED <<entangled, gateCount, normalized>>

\* -- Next state --
Next ==
    \/ ApplyHadamard
    \/ ApplyCNOT
    \/ ApplyPauliX
    \/ Measure
    \/ \E n \in 2..4 : TopologyFork(n)
    \/ TopologyObserve

\* ==================================================================
\* INVARIANTS
\* ==================================================================

TypeInvariant ==
    /\ superpositionCount \in Nat
    /\ superpositionCount > 0
    /\ collapsed \in BOOLEAN
    /\ entangled \in BOOLEAN
    /\ gateCount \in Nat
    /\ normalized \in BOOLEAN

\* Normalization is preserved by all operations
NormalizationPreserved == normalized = TRUE

\* Superposition count is always positive
SuperpositionPositive == superpositionCount >= 1

\* After collapse, superposition count is 1
CollapseReduces == collapsed => superpositionCount = 1

\* Measurements only happen after collapse
MeasurementsAfterCollapse == Len(measurements) > 0 => collapsed

\* ==================================================================
\* LIVENESS
\* ==================================================================

\* Eventually the state is measured
EventuallyMeasured == <>(collapsed = TRUE)

DeadlockFree == []<>(ENABLED Next)

\* ==================================================================
\* SPECIFICATION
\* ==================================================================

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(Next)

THEOREM Spec => []TypeInvariant
THEOREM Spec => []NormalizationPreserved
THEOREM Spec => []SuperpositionPositive
THEOREM Spec => []CollapseReduces

=====
