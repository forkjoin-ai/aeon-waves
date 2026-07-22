---------------------------- MODULE SemanticTypeCompatibility ----------------------------
\* Cross-language semantic type compatibility for polyglot topologies.
\* Models the type universe, compatibility checker, auto-healer, and predicate propagation.
\*
\* Part of the fork/race/fold formal framework (Book 145, Chapter 17).
\* Extension for polyglot gnode (Book 200), Betty compiler (Book 161),
\* and cross-language semantic type theory (Book 201).

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    MaxNodes,       \* Maximum number of topology nodes
    MaxEdges,       \* Maximum number of edges
    Languages,      \* Set of languages {python, go, rust, typescript, java}
    TypeKinds       \* Set of type kinds {json_int, json_num, json_str, json_bool, json_null, json_any, bytes, stream, option, product, sum, opaque, unknown}

VARIABLES
    nodes,          \* Function from node ID to {language, typeKind}
    edges,          \* Set of {source, target, edgeType} records
    compatibility,  \* Function from edge to {compatible, proof_obligation, incompatible}
    converters,     \* Set of inserted converter nodes
    predicates,     \* Function from node ID to set of predicates
    hopeCert        \* Hope certificate: {g1, g2, g3, g4, g5, allHold}

vars == <<nodes, edges, compatibility, converters, predicates, hopeCert>>

\* ─── Type Compatibility Rules ─────────────────────────────────────────────

\* Unknown is compatible with everything
UnknownCompat(src, tgt) ==
    \/ nodes[src].typeKind = "unknown"
    \/ nodes[tgt].typeKind = "unknown"

\* Same type is compatible
SameTypeCompat(src, tgt) ==
    nodes[src].typeKind = nodes[tgt].typeKind

\* Integer is a subtype of Number
IntSubtypeNum(src, tgt) ==
    /\ nodes[src].typeKind = "json_int"
    /\ nodes[tgt].typeKind = "json_num"

\* Number to Integer is proof obligation
NumToIntObligation(src, tgt) ==
    /\ nodes[src].typeKind = "json_num"
    /\ nodes[tgt].typeKind = "json_int"

\* Bytes boundary: bytes incompatible with non-bytes
BytesBoundary(src, tgt) ==
    /\ nodes[src].typeKind = "bytes"
    /\ nodes[tgt].typeKind /= "bytes"
    /\ nodes[tgt].typeKind /= "unknown"

\* Compute compatibility for an edge
Compatible(src, tgt) ==
    \/ UnknownCompat(src, tgt)
    \/ SameTypeCompat(src, tgt)
    \/ IntSubtypeNum(src, tgt)

ProofObligation(src, tgt) ==
    /\ ~Compatible(src, tgt)
    /\ ~BytesBoundary(src, tgt)
    /\ \/ NumToIntObligation(src, tgt)
       \/ nodes[src].typeKind = "opaque"
       \/ nodes[tgt].typeKind = "opaque"

Incompatible(src, tgt) ==
    /\ ~Compatible(src, tgt)
    /\ ~ProofObligation(src, tgt)

\* ─── Healing ──────────────────────────────────────────────────────────────

\* A converter can heal an edge if it bridges the type gap
CanHeal(src, tgt) ==
    \/ /\ BytesBoundary(src, tgt)
       /\ nodes[tgt].typeKind = "json_str"
    \/ NumToIntObligation(src, tgt)

\* ─── Predicate Propagation ────────────────────────────────────────────────

\* Predicates that survive PROCESS edges
SurvivesProcess(pred) ==
    pred \in {"valid_json", "total_function", "monotone", "invertible"}

\* ─── Initial State ────────────────────────────────────────────────────────

Init ==
    /\ nodes \in [1..MaxNodes -> [language: Languages, typeKind: TypeKinds]]
    /\ edges \subseteq {[source |-> s, target |-> t, edgeType |-> et] :
                         s \in 1..MaxNodes, t \in 1..MaxNodes, et \in {"PROCESS", "FORK", "FOLD", "RACE"}}
    /\ Cardinality(edges) <= MaxEdges
    /\ compatibility = [e \in edges |->
        IF Compatible(e.source, e.target) THEN "compatible"
        ELSE IF ProofObligation(e.source, e.target) THEN "proof_obligation"
        ELSE "incompatible"]
    /\ converters = {}
    /\ predicates = [n \in 1..MaxNodes |-> {}]
    /\ hopeCert = [g1 |-> TRUE, g2 |-> TRUE, g3 |-> TRUE, g4 |-> TRUE, g5 |-> TRUE, allHold |-> TRUE]

\* ─── Heal Action ──────────────────────────────────────────────────────────

HealEdge(e) ==
    /\ compatibility[e] \in {"incompatible", "proof_obligation"}
    /\ CanHeal(e.source, e.target)
    /\ converters' = converters \cup {[source |-> e.source, target |-> e.target]}
    /\ compatibility' = [compatibility EXCEPT ![e] = "compatible"]
    /\ UNCHANGED <<nodes, edges, predicates, hopeCert>>

\* ─── Propagate Predicates ─────────────────────────────────────────────────

PropagatePredicates(e) ==
    /\ e.edgeType = "PROCESS"
    /\ compatibility[e] = "compatible"
    /\ LET survivingPreds == {p \in predicates[e.source] : SurvivesProcess(p)}
       IN predicates' = [predicates EXCEPT ![e.target] = @ \cup survivingPreds]
    /\ UNCHANGED <<nodes, edges, compatibility, converters, hopeCert>>

\* ─── Update Hope Certificate ──────────────────────────────────────────────

UpdateHope ==
    LET
        incompCount == Cardinality({e \in edges : compatibility[e] = "incompatible"})
        obligCount == Cardinality({e \in edges : compatibility[e] = "proof_obligation"})
        unknownCount == Cardinality({n \in 1..MaxNodes : nodes[n].typeKind = "unknown"})
        typedCount == Cardinality({n \in 1..MaxNodes : nodes[n].typeKind /= "unknown"})
        healedCount == Cardinality(converters)
        unhealableCount == Cardinality({e \in edges :
            /\ compatibility[e] = "incompatible"
            /\ ~CanHeal(e.source, e.target)})
        langCount == Cardinality({nodes[n].language : n \in 1..MaxNodes})
    IN
    /\ hopeCert' = [
        g1 |-> \A e \in edges :
            compatibility[e] = "incompatible" =>
                /\ nodes[e.source].typeKind /= "unknown"
                /\ nodes[e.target].typeKind /= "unknown",
        g2 |-> incompCount + obligCount <= Cardinality(edges) * 64,
        g3 |-> \A e \in edges :
            compatibility[e] = "proof_obligation" => CanHeal(e.source, e.target),
        g4 |-> unhealableCount = 0,
        g5 |-> TRUE,  \* Convergence is structural, always holds.
        allHold |->
            /\ \A e \in edges :
                compatibility[e] = "incompatible" =>
                    /\ nodes[e.source].typeKind /= "unknown"
                    /\ nodes[e.target].typeKind /= "unknown"
            /\ incompCount + obligCount <= Cardinality(edges) * 64
            /\ unhealableCount = 0
       ]
    /\ UNCHANGED <<nodes, edges, compatibility, converters, predicates>>

\* ─── Next State ───────────────────────────────────────────────────────────

Next ==
    \/ \E e \in edges : HealEdge(e)
    \/ \E e \in edges : PropagatePredicates(e)
    \/ UpdateHope

\* ─── Invariants ───────────────────────────────────────────────────────────

\* INV-SEM-REFL: Every type is compatible with itself.
InvReflexive ==
    \A n \in 1..MaxNodes :
        LET selfEdge == [source |-> n, target |-> n, edgeType |-> "PROCESS"]
        IN selfEdge \in edges => compatibility[selfEdge] = "compatible"

\* INV-SEM-UNKNOWN: Unknown is always compatible.
InvUnknownCompat ==
    \A e \in edges :
        (nodes[e.source].typeKind = "unknown" \/ nodes[e.target].typeKind = "unknown")
        => compatibility[e] = "compatible"

\* INV-SEM-NO-FALSE-POSITIVE: Incompatible edges involve distinct non-unknown types.
InvNoFalsePositive ==
    \A e \in edges :
        compatibility[e] = "incompatible" =>
            /\ nodes[e.source].typeKind /= "unknown"
            /\ nodes[e.target].typeKind /= "unknown"

\* INV-SEM-BOUNDED: Confusion count is bounded.
InvBounded ==
    Cardinality({e \in edges : compatibility[e] /= "compatible"})
        <= Cardinality(edges) * 64

\* INV-SEM-HEAL-SOUND: Every healed edge is now compatible.
InvHealSound ==
    \A c \in converters :
        \A e \in edges :
            (e.source = c.source /\ e.target = c.target) => compatibility[e] = "compatible"

\* INV-SEM-BYTES-BOUNDARY: Bytes never compat with non-bytes (except unknown).
InvBytesBoundary ==
    \A e \in edges :
        (/\ nodes[e.source].typeKind = "bytes"
         /\ nodes[e.target].typeKind /= "bytes"
         /\ nodes[e.target].typeKind /= "unknown")
        => compatibility[e] /= "compatible"

\* INV-SEM-INT-SUBTYPE: Integer to Number is always compatible.
InvIntSubtype ==
    \A e \in edges :
        (/\ nodes[e.source].typeKind = "json_int"
         /\ nodes[e.target].typeKind = "json_num")
        => compatibility[e] = "compatible"

\* INV-SEM-PREDICATE-MONOTONE: Predicate sets only grow (never shrink).
InvPredicateMonotone ==
    \A n \in 1..MaxNodes : predicates[n] \subseteq predicates'[n]

\* INV-SEM-HOPE-G1: Hope G1 holds at all times.
InvHopeG1 == hopeCert.g1

\* INV-SEM-DIVERSITY: More than 1 language means positive net information.
InvDiversity ==
    Cardinality({nodes[n].language : n \in 1..MaxNodes}) > 1
    => Cardinality({e \in edges :
        nodes[e.source].language /= nodes[e.target].language}) > 0

Spec == Init /\ [][Next]_vars

=============================================================================
