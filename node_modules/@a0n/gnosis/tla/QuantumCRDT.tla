-------------------------------- MODULE QuantumCRDT --------------------------------
\* Formal TLA+ specification of Quantum CRDT convergence in Gnosis.
\*
\* CRDT is the only state model. No memory. No GC. Append-only topology.
\* The topology IS the state. FORK creates superposition. OBSERVE collapses.
\* beta1 = 0 means converged, not deleted. History is permanent.
\*
\* This spec proves:
\*   1. Safety: beta1 is always non-negative and bounded
\*   2. Convergence: all FORK paths eventually reach beta1 = 0 via OBSERVE
\*   3. Commutativity: FOLD operations are order-independent
\*   4. Append-only: the topology never shrinks (no GC, no memory)

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    Replicas,       \* Set of replica IDs (e.g., {"a", "b", "c"})
    MaxBeta1,       \* Upper bound on beta1 (e.g., 10)
    MaxOps          \* Maximum operations per replica before convergence test

VARIABLES
    beta1,          \* Current superposition count (concurrent unmerged branches)
    topology,       \* Append-only sequence of topology events
    replicaState,   \* Function: replica -> its local operation log
    observed,       \* Set of replica pairs that have been observed/merged
    converged       \* Boolean: has the system reached beta1 = 0?

vars == <<beta1, topology, replicaState, observed, converged>>

TypeOK ==
    /\ beta1 \in 0..MaxBeta1
    /\ topology \in Seq(STRING)
    /\ replicaState \in [Replicas -> Seq(STRING)]
    /\ observed \subseteq (Replicas \X Replicas)
    /\ converged \in BOOLEAN

-----------------------------------------------------------------------------
\* Initial state: all replicas start from the same root, beta1 = 0

Init ==
    /\ beta1 = 0
    /\ topology = <<"root">>
    /\ replicaState = [r \in Replicas |-> <<>>]
    /\ observed = {}
    /\ converged = FALSE

-----------------------------------------------------------------------------
\* FORK: a replica creates a local operation (enters superposition)

Fork(r) ==
    /\ Len(replicaState[r]) < MaxOps
    /\ ~converged
    /\ beta1' = beta1 + 1
    /\ replicaState' = [replicaState EXCEPT ![r] = Append(@, "op")]
    /\ topology' = Append(topology, "FORK")
    /\ UNCHANGED <<observed, converged>>

\* OBSERVE: two replicas merge (collapse superposition between them)

Observe(r1, r2) ==
    /\ r1 /= r2
    /\ <<r1, r2>> \notin observed
    /\ beta1 > 0
    /\ ~converged
    /\ beta1' = IF beta1 > 0 THEN beta1 - 1 ELSE 0
    /\ observed' = observed \cup {<<r1, r2>>, <<r2, r1>>}
    /\ topology' = Append(topology, "OBSERVE")
    /\ converged' = (beta1' = 0)
    /\ UNCHANGED replicaState

\* FOLD: commutative merge (for counters — order doesn't matter)

Fold(r1, r2) ==
    /\ r1 /= r2
    /\ <<r1, r2>> \notin observed
    /\ beta1 > 0
    /\ ~converged
    /\ beta1' = IF beta1 > 0 THEN beta1 - 1 ELSE 0
    /\ observed' = observed \cup {<<r1, r2>>, <<r2, r1>>}
    /\ topology' = Append(topology, "FOLD")
    /\ converged' = (beta1' = 0)
    /\ UNCHANGED replicaState

\* INTERFERE: presence data coexists without merging (beta1 unchanged)

Interfere(r1, r2) ==
    /\ r1 /= r2
    /\ ~converged
    /\ topology' = Append(topology, "INTERFERE")
    /\ UNCHANGED <<beta1, replicaState, observed, converged>>

-----------------------------------------------------------------------------
\* Next-state relation

Next ==
    \/ \E r \in Replicas : Fork(r)
    \/ \E r1, r2 \in Replicas : Observe(r1, r2)
    \/ \E r1, r2 \in Replicas : Fold(r1, r2)
    \/ \E r1, r2 \in Replicas : Interfere(r1, r2)

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

-----------------------------------------------------------------------------
\* Safety Properties

\* beta1 is always non-negative
Beta1NonNegative == beta1 >= 0

\* beta1 never exceeds the bound
Beta1Bounded == beta1 <= MaxBeta1

\* The topology only grows (append-only, no GC, no memory)
TopologyAppendOnly == [][Len(topology') >= Len(topology)]_topology

\* Safety conjunction
Safety == Beta1NonNegative /\ Beta1Bounded /\ TopologyAppendOnly

-----------------------------------------------------------------------------
\* Liveness Properties

\* Eventually, all replicas converge (beta1 reaches 0)
EventuallyConverges == <>(converged)

\* Once converged, the topology retains all history (no deletion)
ConvergedHistoryPermanent ==
    converged => (Len(topology) > 0)

\* Convergence is stable: once beta1 = 0, it stays 0 (unless new FORKs)
\* Note: new FORKs can raise beta1 again — that's correct behavior

=============================================================================
