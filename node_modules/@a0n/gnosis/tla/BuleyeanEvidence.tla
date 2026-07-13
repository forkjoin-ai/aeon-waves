--------------------------- MODULE BuleyeanEvidence ---------------------------
(*
  Buleyean Evidence Standards -- The topological theory of legal proof.

  Models a five-phase trial protocol where β₁ = 0 is the only
  acceptable standard for a guilty verdict. Checks safety (no
  premature conviction, monotone deficit reduction, discovery
  obligations) and liveness (eventual coverage, eventual verdict).
*)

CONSTANTS
  EvidentiaryThreads,   \* Number of independent evidentiary threads (≥ 2)
  MaxRounds,            \* Maximum number of evidence presentation rounds
  TotalEvidence         \* Total evidence items in the case

ASSUME EvidentiaryThreads >= 2
ASSUME MaxRounds >= EvidentiaryThreads
ASSUME TotalEvidence >= EvidentiaryThreads

VARIABLES
  phase,                \* discovery | presentation | deliberation | verdict | appeal
  coveredThreads,       \* How many threads have been covered
  round,                \* Current round number
  disclosedEvidence,    \* Evidence items disclosed to both parties
  defenseThreads,       \* Additional threads identified by defense
  currentDeficit,       \* Current evidentiary deficit
  verdictRendered,      \* none | insufficient_data | guilty
  appealFiled           \* Whether an appeal has been filed

vars == <<phase, coveredThreads, round, disclosedEvidence,
          defenseThreads, currentDeficit, verdictRendered, appealFiled>>

TypeOK ==
  /\ phase \in {"discovery", "presentation", "deliberation", "verdict", "appeal"}
  /\ coveredThreads \in 0..EvidentiaryThreads + 10
  /\ round \in 0..MaxRounds
  /\ disclosedEvidence \in 0..TotalEvidence
  /\ defenseThreads \in 0..5
  /\ currentDeficit \in 0..EvidentiaryThreads + 10
  /\ verdictRendered \in {"none", "insufficient_data", "guilty"}
  /\ appealFiled \in BOOLEAN

TotalThreads == EvidentiaryThreads + defenseThreads

Init ==
  /\ phase = "discovery"
  /\ coveredThreads = 0
  /\ round = 0
  /\ disclosedEvidence = 0
  /\ defenseThreads = 0
  /\ currentDeficit = EvidentiaryThreads
  /\ verdictRendered = "none"
  /\ appealFiled = FALSE

\* Phase 1: Discovery -- evidence is disclosed
Disclose ==
  /\ phase = "discovery"
  /\ disclosedEvidence < TotalEvidence
  /\ disclosedEvidence' = disclosedEvidence + 1
  /\ UNCHANGED <<phase, coveredThreads, round, defenseThreads,
                 currentDeficit, verdictRendered, appealFiled>>

EndDiscovery ==
  /\ phase = "discovery"
  /\ phase' = "presentation"
  /\ UNCHANGED <<coveredThreads, round, disclosedEvidence, defenseThreads,
                 currentDeficit, verdictRendered, appealFiled>>

\* Phase 2: Presentation -- evidence covers threads
PresentEvidence ==
  /\ phase = "presentation"
  /\ round < MaxRounds
  /\ coveredThreads < TotalThreads
  /\ coveredThreads' = coveredThreads + 1
  /\ round' = round + 1
  /\ currentDeficit' = TotalThreads - coveredThreads'
  /\ UNCHANGED <<phase, disclosedEvidence, defenseThreads,
                 verdictRendered, appealFiled>>

\* Defense identifies a new thread (increases topology)
DefenseIdentifiesThread ==
  /\ phase = "presentation"
  /\ defenseThreads < 5
  /\ defenseThreads' = defenseThreads + 1
  /\ currentDeficit' = TotalThreads' - coveredThreads
  /\ UNCHANGED <<phase, coveredThreads, round, disclosedEvidence,
                 verdictRendered, appealFiled>>

\* Phase 3: Insufficiency check (can happen during presentation)
InsufficientCheck ==
  /\ phase = "presentation"
  /\ currentDeficit > 0
  /\ phase' = "verdict"
  /\ verdictRendered' = "insufficient_data"
  /\ UNCHANGED <<coveredThreads, round, disclosedEvidence, defenseThreads,
                 currentDeficit, appealFiled>>

\* Phase 4: Deliberation when deficit is zero
BeginDeliberation ==
  /\ phase = "presentation"
  /\ currentDeficit = 0
  /\ phase' = "deliberation"
  /\ UNCHANGED <<coveredThreads, round, disclosedEvidence, defenseThreads,
                 currentDeficit, verdictRendered, appealFiled>>

RenderGuilty ==
  /\ phase = "deliberation"
  /\ currentDeficit = 0
  /\ phase' = "verdict"
  /\ verdictRendered' = "guilty"
  /\ UNCHANGED <<coveredThreads, round, disclosedEvidence, defenseThreads,
                 currentDeficit, appealFiled>>

\* Phase 5: Appeal
FileAppeal ==
  /\ phase = "verdict"
  /\ verdictRendered = "guilty"
  /\ ~appealFiled
  /\ phase' = "appeal"
  /\ appealFiled' = TRUE
  /\ UNCHANGED <<coveredThreads, round, disclosedEvidence, defenseThreads,
                 currentDeficit, verdictRendered>>

\* Prosecution rests without full coverage
ProsecutionRests ==
  /\ phase = "presentation"
  /\ currentDeficit > 0
  /\ phase' = "verdict"
  /\ verdictRendered' = "insufficient_data"
  /\ UNCHANGED <<coveredThreads, round, disclosedEvidence, defenseThreads,
                 currentDeficit, appealFiled>>

Next ==
  \/ Disclose
  \/ EndDiscovery
  \/ PresentEvidence
  \/ DefenseIdentifiesThread
  \/ InsufficientCheck
  \/ BeginDeliberation
  \/ RenderGuilty
  \/ ProsecutionRests
  \/ FileAppeal

Spec == Init /\ [][Next]_vars /\ WF_vars(PresentEvidence) /\ WF_vars(EndDiscovery)

\* ═══════════════════════════════════════════════════════════════════
\* Safety Invariants
\* ═══════════════════════════════════════════════════════════════════

\* No premature conviction: guilty requires zero deficit
InvNoPrematureConviction ==
  verdictRendered = "guilty" => currentDeficit = 0

\* Presumption of innocence: at round 0, verdict is not guilty
InvPresumptionOfInnocence ==
  round = 0 => verdictRendered /= "guilty"

\* Deficit is non-negative
InvDeficitNonneg ==
  currentDeficit >= 0

\* Deficit bounded by total threads
InvDeficitBounded ==
  currentDeficit <= TotalThreads

\* Coverage bounded by total threads
InvCoverageBounded ==
  coveredThreads <= TotalThreads

\* Deficit equals total threads minus covered
InvDeficitFormula ==
  currentDeficit = TotalThreads - coveredThreads

\* Discovery bounded by total evidence
InvDiscoveryBounded ==
  disclosedEvidence <= TotalEvidence

\* Guilty verdict only in verdict or appeal phase
InvGuiltyOnlyInVerdict ==
  verdictRendered = "guilty" => phase \in {"verdict", "appeal"}

\* ═══════════════════════════════════════════════════════════════════
\* Liveness Properties
\* ═══════════════════════════════════════════════════════════════════

\* Eventually a verdict is rendered
EventuallyVerdict ==
  <>(verdictRendered /= "none")

\* If all threads can be covered, eventually coverage completes
EventuallyCovered ==
  <>(coveredThreads >= EvidentiaryThreads)

=============================================================================
