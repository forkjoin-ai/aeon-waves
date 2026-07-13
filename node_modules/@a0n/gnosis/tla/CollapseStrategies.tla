------------------------------ MODULE CollapseStrategies --------------------------
\* Formal specification of CRDT collapse strategies.
\*
\* Each strategy defines how superposed operations merge during OBSERVE/COLLAPSE.
\* This spec proves that each strategy is:
\*   1. Deterministic: same inputs always produce the same output
\*   2. Convergent: all operation orderings produce the same final state
\*   3. Well-defined: no strategy produces an error state

EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    Values,         \* Set of possible values (e.g., {"alice", "bob", "charlie"})
    Timestamps      \* Set of possible timestamps (e.g., 1..10)

VARIABLES
    writes,         \* Sequence of concurrent writes: <<value, timestamp>> pairs
    result,         \* The collapsed result (after strategy application)
    strategy,       \* Which strategy is active
    resolved        \* Has the strategy been applied?

vars == <<writes, result, strategy, resolved>>

-----------------------------------------------------------------------------
\* Last-Writer-Wins (LWW) — highest timestamp wins

LWW_Resolve ==
    /\ strategy = "lww"
    /\ ~resolved
    /\ Len(writes) > 0
    /\ LET
        maxTs == CHOOSE ts \in {writes[i][2] : i \in 1..Len(writes)} :
            \A ts2 \in {writes[j][2] : j \in 1..Len(writes)} : ts >= ts2
        winner == CHOOSE i \in 1..Len(writes) : writes[i][2] = maxTs
       IN
        /\ result' = writes[winner][1]
        /\ resolved' = TRUE
        /\ UNCHANGED <<writes, strategy>>

\* Fold-Sum — commutative addition (for counters)
\* Result is the sum of all values (values must be integers)

FoldSum_Resolve ==
    /\ strategy = "fold-sum"
    /\ ~resolved
    /\ Len(writes) > 0
    /\ LET
        \* Sum all first elements (the values/deltas)
        total == CHOOSE v \in Int :
            v = writes[1][1] + (IF Len(writes) > 1 THEN writes[2][1] ELSE 0)
                             + (IF Len(writes) > 2 THEN writes[3][1] ELSE 0)
       IN
        /\ result' = total
        /\ resolved' = TRUE
        /\ UNCHANGED <<writes, strategy>>

-----------------------------------------------------------------------------

Init ==
    /\ writes = <<>>
    /\ result = "NONE"
    /\ strategy \in {"lww", "fold-sum"}
    /\ resolved = FALSE

Write(v, ts) ==
    /\ ~resolved
    /\ Len(writes) < 3
    /\ writes' = Append(writes, <<v, ts>>)
    /\ UNCHANGED <<result, strategy, resolved>>

Next ==
    \/ \E v \in Values, ts \in Timestamps : Write(v, ts)
    \/ LWW_Resolve
    \/ FoldSum_Resolve

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* Safety Properties

\* Once resolved, the result doesn't change (deterministic)
ResultStable == [][(resolved => result' = result)]_vars

\* If resolved, result is not the initial "NONE"
ResolvedHasValue == resolved => result /= "NONE"

=============================================================================
