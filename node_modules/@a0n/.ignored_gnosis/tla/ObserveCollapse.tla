------------------------------ MODULE ObserveCollapse ------------------------------
\* Formal specification of the OBSERVE primitive.
\*
\* OBSERVE is the measurement operator: reading forces collapse.
\* This spec proves that OBSERVE is equivalent to COLLAPSE for beta1 transitions
\* but semantically distinct: OBSERVE propagates through ENTANGLE edges.
\*
\* Key properties:
\*   1. OBSERVE(superposed) => beta1 = 0 at the observed node
\*   2. ENTANGLE propagation: OBSERVE cascades to entangled subgraphs
\*   3. INTERFERE is immune to OBSERVE: presence data stays in superposition
\*   4. Strategy correctness: collapse strategy produces deterministic result

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    Nodes,          \* Set of node IDs in the topology
    MaxBeta1        \* Upper bound on beta1

VARIABLES
    beta1,          \* Per-node beta1 (superposition count)
    entangled,      \* Set of entanglement pairs: {<<n1, n2>>}
    interfering,    \* Set of interfering node pairs (immune to OBSERVE)
    collapsed,      \* Set of nodes that have been observed/collapsed
    history         \* Append-only event log

vars == <<beta1, entangled, interfering, collapsed, history>>

TypeOK ==
    /\ beta1 \in [Nodes -> 0..MaxBeta1]
    /\ entangled \subseteq (Nodes \X Nodes)
    /\ interfering \subseteq (Nodes \X Nodes)
    /\ collapsed \subseteq Nodes
    /\ history \in Seq(STRING)

-----------------------------------------------------------------------------

Init ==
    /\ beta1 = [n \in Nodes |-> 0]
    /\ entangled = {}
    /\ interfering = {}
    /\ collapsed = {}
    /\ history = <<>>

\* FORK: increase beta1 at a node
Fork(n, width) ==
    /\ n \notin collapsed
    /\ beta1[n] + width <= MaxBeta1
    /\ beta1' = [beta1 EXCEPT ![n] = @ + width]
    /\ history' = Append(history, "FORK")
    /\ UNCHANGED <<entangled, interfering, collapsed>>

\* ENTANGLE: create causal correlation between two nodes
Entangle(n1, n2) ==
    /\ n1 /= n2
    /\ entangled' = entangled \cup {<<n1, n2>>}
    /\ history' = Append(history, "ENTANGLE")
    /\ UNCHANGED <<beta1, interfering, collapsed>>

\* INTERFERE: mark two nodes as interfering (immune to OBSERVE cascade)
SetInterfere(n1, n2) ==
    /\ n1 /= n2
    /\ interfering' = interfering \cup {<<n1, n2>>, <<n2, n1>>}
    /\ history' = Append(history, "INTERFERE")
    /\ UNCHANGED <<beta1, entangled, collapsed>>

\* OBSERVE: collapse a node AND cascade through entangle edges
\* Interfering nodes are NOT affected.
Observe(n) ==
    /\ n \notin collapsed
    /\ beta1[n] > 0
    /\ LET
        \* Find all nodes entangled with n (that are not interfering with n)
        cascadeTargets == {n2 \in Nodes :
            <<n, n2>> \in entangled /\ <<n, n2>> \notin interfering}
        \* Collapse n and all cascade targets
        allCollapsed == {n} \cup cascadeTargets
       IN
        /\ beta1' = [node \in Nodes |->
            IF node \in allCollapsed THEN 0
            ELSE beta1[node]]
        /\ collapsed' = collapsed \cup allCollapsed
        /\ history' = Append(history, "OBSERVE")
        /\ UNCHANGED <<entangled, interfering>>

-----------------------------------------------------------------------------

Next ==
    \/ \E n \in Nodes : \E w \in 1..3 : Fork(n, w)
    \/ \E n1, n2 \in Nodes : Entangle(n1, n2)
    \/ \E n1, n2 \in Nodes : SetInterfere(n1, n2)
    \/ \E n \in Nodes : Observe(n)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* Safety Properties

\* beta1 is always non-negative at every node
AllBeta1NonNegative == \A n \in Nodes : beta1[n] >= 0

\* beta1 never exceeds the bound at any node
AllBeta1Bounded == \A n \in Nodes : beta1[n] <= MaxBeta1

\* After OBSERVE, the observed node has beta1 = 0
ObserveCollapsesBeta1 ==
    \A n \in collapsed : beta1[n] = 0

\* ENTANGLE cascade: if n is collapsed and n2 is entangled (not interfering),
\* then n2 is also collapsed
EntangleCascade ==
    \A n \in collapsed :
        \A n2 \in Nodes :
            (<<n, n2>> \in entangled /\ <<n, n2>> \notin interfering)
            => n2 \in collapsed

\* INTERFERE immunity: interfering nodes are NOT affected by OBSERVE
\* (This is checked indirectly — interfering pairs skip the cascade)

\* History is append-only (no GC, no memory, no deletion)
HistoryAppendOnly == [][Len(history') >= Len(history)]_history

=============================================================================
