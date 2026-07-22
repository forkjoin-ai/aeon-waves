------------------------------ MODULE ChaitinOmega ------------------------------
(*
  Chaitin's Omega as Universal Void Boundary.

  The halting probability Omega is the void boundary of all programs
  on a Universal Turing Machine. Each program either halts (survives
  the fold of execution) or doesn't (is vented to the void of
  non-termination).

  This spec model-checks the finite approximation: enumerate programs
  up to length L on alphabet A. Count halting vs non-halting. Verify
  the structural invariants of the fold.

  The uncomputability of Omega is modeled by the extension action:
  each step enumerates more programs, monotonically increasing the
  halting count while never exceeding the total.
*)
EXTENDS Naturals

CONSTANTS AlphabetSize, MaxLength

VARIABLES totalPrograms, haltingPrograms, nonHalting, enumLength, phase

vars == <<totalPrograms, haltingPrograms, nonHalting, enumLength, phase>>

\* ─── Helpers ──────────────────────────────────────────────────────────

ProgramCount(len) == AlphabetSize ^ len

\* ─── Initial state: minimal enumeration ───────────────────────────────

Init ==
  /\ enumLength = 1
  /\ totalPrograms = AlphabetSize
  /\ haltingPrograms = 1
  /\ nonHalting = AlphabetSize - 1
  /\ phase = "enumerating"

\* ─── Extend: enumerate longer programs ────────────────────────────────

Extend ==
  /\ phase = "enumerating"
  /\ enumLength' = enumLength + 1
  /\ totalPrograms' = totalPrograms + ProgramCount(enumLength + 1)
  /\ \E newHalting \in 0..ProgramCount(enumLength + 1) :
       /\ haltingPrograms' = haltingPrograms + newHalting
       /\ nonHalting' = nonHalting + (ProgramCount(enumLength + 1) - newHalting)
  /\ phase' = "enumerating"

\* ─── Freeze: stop enumerating (model finite prefix) ──────────────────

Freeze ==
  /\ phase = "enumerating"
  /\ phase' = "frozen"
  /\ UNCHANGED <<totalPrograms, haltingPrograms, nonHalting, enumLength>>

Stutter == UNCHANGED vars

Next == Extend \/ Freeze \/ Stutter
Spec == Init /\ [][Next]_vars

\* ─── Invariants ───────────────────────────────────────────────────────

\* Fold conservation: halting + non-halting = total
InvFoldConservation ==
  haltingPrograms + nonHalting = totalPrograms

\* Omega is positive: at least one program halts
InvOmegaPositive ==
  haltingPrograms > 0

\* Omega is subuniversal: not every program halts
InvOmegaSubuniversal ==
  haltingPrograms < totalPrograms

\* Non-halting void is nonempty
InvVoidNonempty ==
  nonHalting > 0

\* Halting count is bounded by total
InvHaltingBounded ==
  haltingPrograms <= totalPrograms

\* Total programs is positive
InvTotalPositive ==
  totalPrograms > 0

=============================================================================
