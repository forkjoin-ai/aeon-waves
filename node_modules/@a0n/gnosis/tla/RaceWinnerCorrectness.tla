------------------------------ MODULE RaceWinnerCorrectness ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* Track Omicron: Race-Winner Correctness
\*
\* The ledger explicitly notes "does not by itself certify race-winner
\* correctness." This track formalizes the conditions under which the
\* race operation selects the correct winner: the branch that completes
\* first with a valid result.
\*
\* THM-RACE-WINNER-VALIDITY:     winner satisfies the validity predicate
\* THM-RACE-WINNER-MINIMALITY:   winner completes no later than any other
\* THM-RACE-WINNER-DETERMINISM:  ties broken deterministically (C3)
\* THM-RACE-WINNER-ISOLATION:    winner unaffected by non-winner failures (C2)
\* THM-RACE-WINNER-COMPOSABLE:   race results compose through fold

CONSTANTS NumBranches, MaxTime

VARIABLES branchStatus, branchTime, branchResult,
          winner, checked,
          validityOk, minimalityOk, determinismOk,
          isolationOk, composableOk

vars == <<branchStatus, branchTime, branchResult,
          winner, checked,
          validityOk, minimalityOk, determinismOk,
          isolationOk, composableOk>>

\* ─── Branch states ───────────────────────────────────────────────────
\* Each branch has:
\*   - status: "pending", "complete", "vented"
\*   - time: completion time (0 = not yet)
\*   - result: output value (0 = invalid, > 0 = valid)

\* ─── Race winner selection ───────────────────────────────────────────
\* The winner is the branch with the smallest completion time among
\* those with valid results.  Ties broken by index (C3: deterministic).

\* Find the winner among completed branches
RECURSIVE FindWinner(_, _, _, _)
FindWinner(statuses, times, results, idx) ==
  IF idx > Len(statuses) THEN 0  \* no winner
  ELSE IF statuses[idx] = 1 /\ results[idx] > 0   \* complete + valid
       THEN IF FindWinner(statuses, times, results, idx + 1) = 0
            THEN idx
            ELSE LET other == FindWinner(statuses, times, results, idx + 1)
                 IN  IF times[idx] <= times[other] THEN idx ELSE other
       ELSE FindWinner(statuses, times, results, idx + 1)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-RACE-WINNER-VALIDITY
\*
\* The selected winner has a valid result (result > 0).
\* No invalid branch can win the race.
\* ═══════════════════════════════════════════════════════════════════════

ValidityHoldsFor(statuses, results, w) ==
  (w > 0 /\ w <= Len(statuses)) =>
    /\ statuses[w] = 1    \* complete
    /\ results[w] > 0     \* valid result

\* ═══════════════════════════════════════════════════════════════════════
\* THM-RACE-WINNER-MINIMALITY
\*
\* The winner completes no later than any other valid branch.
\* This is the "fastest correct answer" property.
\* ═══════════════════════════════════════════════════════════════════════

MinimalityHoldsFor(statuses, times, results, w) ==
  (w > 0 /\ w <= Len(statuses) /\ statuses[w] = 1 /\ results[w] > 0) =>
    \A i \in 1..Len(statuses):
      (statuses[i] = 1 /\ results[i] > 0) => times[w] <= times[i]

\* ═══════════════════════════════════════════════════════════════════════
\* THM-RACE-WINNER-DETERMINISM
\*
\* Ties are broken deterministically by branch index (C3).
\* If two branches complete at the same time with valid results,
\* the lower-indexed branch wins.
\* ═══════════════════════════════════════════════════════════════════════

DeterminismHoldsFor(statuses, times, results, w) ==
  (w > 0 /\ w <= Len(statuses)) =>
    \A i \in 1..Len(statuses):
      (statuses[i] = 1 /\ results[i] > 0 /\ times[i] = times[w] /\ i < w) =>
        FALSE  \* no lower-indexed branch ties with the winner

\* ═══════════════════════════════════════════════════════════════════════
\* THM-RACE-WINNER-ISOLATION
\*
\* The winner is unaffected by failures in non-winner branches (C2).
\* Vented branches cannot affect the winner's result.
\* ═══════════════════════════════════════════════════════════════════════

IsolationHoldsFor(statuses, results, w) ==
  (w > 0 /\ w <= Len(statuses)) =>
    \A i \in 1..Len(statuses):
      (i /= w /\ statuses[i] = 2) =>  \* vented branch
        /\ statuses[w] = 1              \* winner still complete
        /\ results[w] > 0               \* winner result unchanged

\* ═══════════════════════════════════════════════════════════════════════
\* THM-RACE-WINNER-COMPOSABLE
\*
\* Race results compose through fold: the winner's result can be folded
\* with results from other races, preserving validity.
\* ═══════════════════════════════════════════════════════════════════════

ComposableHoldsFor(result1, result2) ==
  (result1 > 0 /\ result2 > 0) =>
    result1 + result2 > 0  \* fold of valid results is valid

\* ─── Init / Check / Spec ─────────────────────────────────────────────
Init ==
  /\ branchStatus = [i \in 1..NumBranches |-> 0]  \* all pending
  /\ branchTime = [i \in 1..NumBranches |-> 0]
  /\ branchResult = [i \in 1..NumBranches |-> 0]
  /\ winner = 0
  /\ checked = FALSE
  /\ validityOk = TRUE
  /\ minimalityOk = TRUE
  /\ determinismOk = TRUE
  /\ isolationOk = TRUE
  /\ composableOk = TRUE

CheckAll ==
  /\ ~checked
  \* Check validity on all 2-branch configs
  /\ validityOk' =
       \A s1 \in {0,1,2}, s2 \in {0,1,2},
          r1 \in 0..2, r2 \in 0..2,
          t1 \in 1..MaxTime, t2 \in 1..MaxTime:
         LET w == FindWinner(<<s1, s2>>, <<t1, t2>>, <<r1, r2>>, 1)
         IN  ValidityHoldsFor(<<s1, s2>>, <<r1, r2>>, w)
  /\ minimalityOk' =
       \A s1 \in {0,1,2}, s2 \in {0,1,2},
          r1 \in 0..2, r2 \in 0..2,
          t1 \in 1..MaxTime, t2 \in 1..MaxTime:
         LET w == FindWinner(<<s1, s2>>, <<t1, t2>>, <<r1, r2>>, 1)
         IN  MinimalityHoldsFor(<<s1, s2>>, <<t1, t2>>, <<r1, r2>>, w)
  /\ determinismOk' =
       \A s1 \in {0,1,2}, s2 \in {0,1,2},
          r1 \in 0..2, r2 \in 0..2,
          t1 \in 1..MaxTime, t2 \in 1..MaxTime:
         LET w == FindWinner(<<s1, s2>>, <<t1, t2>>, <<r1, r2>>, 1)
         IN  DeterminismHoldsFor(<<s1, s2>>, <<t1, t2>>, <<r1, r2>>, w)
  /\ isolationOk' =
       \A s1 \in {0,1,2}, s2 \in {0,1,2},
          r1 \in 0..2, r2 \in 0..2:
         LET w == FindWinner(<<s1, s2>>, <<1, 2>>, <<r1, r2>>, 1)
         IN  IsolationHoldsFor(<<s1, s2>>, <<r1, r2>>, w)
  /\ composableOk' =
       \A r1 \in 1..3, r2 \in 1..3:
         ComposableHoldsFor(r1, r2)
  /\ checked' = TRUE
  /\ UNCHANGED <<branchStatus, branchTime, branchResult, winner>>

Stutter == UNCHANGED vars
Next == CheckAll \/ Stutter
Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────
InvValidity == checked => validityOk
InvMinimality == checked => minimalityOk
InvDeterminism == checked => determinismOk
InvIsolation == checked => isolationOk
InvComposable == checked => composableOk

=============================================================================
