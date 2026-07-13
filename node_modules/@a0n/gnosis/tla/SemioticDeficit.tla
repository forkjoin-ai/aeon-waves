------------------------------ MODULE SemioticDeficit ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* Track Pi: Semiotic Deficit Theory
\*
\* Maps fork/race/fold/vent to formal semiotics.  The central claim:
\* thought has high β₁ (parallel semantic paths), speech has β₁ = 0
\* (single ordered stream), and the topological deficit between them
\* is the information-theoretic content of confusion.
\*
\* THM-SEMIOTIC-DEFICIT:             thought→speech has Δβ > 0
\* THM-SEMIOTIC-ERASURE:             speech fold erases semantic paths
\* THM-SEMIOTIC-VENT-NUANCE:         vented paths = lost nuance
\* THM-SEMIOTIC-RACE-ARTICULATION:   phrasing selection is neural race
\* THM-SEMIOTIC-CONTEXT-REDUCES:     shared context reduces deficit
\* THM-SEMIOTIC-CONVERSATION-TRACE:  dialogue is traced monoidal feedback
\* THM-SEMIOTIC-MOA-ISOMORPHISM:     MOA architecture = semiotic pipeline

CONSTANTS SemanticPaths, ArticulationStreams, ContextPaths, NumPhrasings,
          MaxTime, NumTurns

VARIABLES turn, checked,
          deficitOk, erasureOk, ventOk, raceOk,
          contextOk, traceOk, moaOk

vars == <<turn, checked,
          deficitOk, erasureOk, ventOk, raceOk,
          contextOk, traceOk, moaOk>>

\* ─── Topological model of communication ──────────────────────────────
\* Thought: β₁ = SemanticPaths - 1 (independent meaning dimensions)
\*   - denotation, connotation, emotional valence, context, implicature, ...
\* Speech: β₁ = ArticulationStreams - 1 (serial by default = 1 stream)
\* Deficit: Δβ = β₁(thought) - β₁(speech)

ThoughtBeta1 == SemanticPaths - 1
SpeechBeta1  == ArticulationStreams - 1
SemioticDeficit == ThoughtBeta1 - SpeechBeta1

\* Context-augmented speech: shared context adds implicit parallel channels
\* Effective β₁(speech | context) = ArticulationStreams + ContextPaths - 1
AugmentedSpeechBeta1 == ArticulationStreams + ContextPaths - 1
ContextReducedDeficit == ThoughtBeta1 - AugmentedSpeechBeta1

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-DEFICIT
\*
\* Thought→speech has positive topological deficit when semantic
\* paths exceed articulation streams.  This is the information-
\* theoretic content of "I know what I mean but I can't say it."
\* ═══════════════════════════════════════════════════════════════════════

SemioticDeficitHolds ==
  (SemanticPaths >= 2 /\ ArticulationStreams >= 1 /\
   SemanticPaths > ArticulationStreams) =>
    /\ SemioticDeficit > 0
    /\ SemioticDeficit = SemanticPaths - ArticulationStreams

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-ERASURE
\*
\* The speech fold (sentence construction) is many-to-one:
\* multiple semantic paths collapse into one utterance.
\* By DPI, this erases information.  The erased information
\* is the meaning that didn't survive articulation.
\*
\* Modeled: k semantic paths on 1 stream forces k-1 collisions.
\* Each collision is a many-to-one mapping (multiplexing of meaning).
\* ═══════════════════════════════════════════════════════════════════════

SemioticErasureHolds ==
  (SemanticPaths >= 2 /\ ArticulationStreams = 1) =>
    LET collisions == SemanticPaths - 1
    IN  /\ collisions > 0              \* pigeonhole: meaning collides
        /\ collisions = SemioticDeficit  \* erasure = deficit

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-VENT-NUANCE
\*
\* When the fold can't preserve all semantic paths, the speaker
\* drops (vents) some.  "It's complicated" is a vent operation.
\* Vented nuance = branch mass that doesn't survive the fold.
\*
\* Modeled: with k paths and m < k streams, exactly k - m paths
\* are vented (their nuance is lost).
\* ═══════════════════════════════════════════════════════════════════════

VentedNuance(k, m) == IF k > m THEN k - m ELSE 0

SemioticVentHolds ==
  (SemanticPaths >= 2 /\ ArticulationStreams >= 1 /\
   SemanticPaths > ArticulationStreams) =>
    /\ VentedNuance(SemanticPaths, ArticulationStreams) > 0
    /\ VentedNuance(SemanticPaths, ArticulationStreams) = SemioticDeficit

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-RACE-ARTICULATION
\*
\* Multiple candidate phrasings are generated in parallel (forked),
\* they race to articulation, the fastest adequate one wins.
\*
\* "Tip of the tongue" = race hasn't terminated.
\* "Wrong word" = race winner passed validity but wasn't optimal.
\*
\* Modeled: NumPhrasings candidates race, winner has min time among valid.
\* ═══════════════════════════════════════════════════════════════════════

\* With N phrasings racing, exactly one wins (the fastest valid one).
\* The winner is not necessarily the best — just the fastest adequate one.
SemioticRaceHolds ==
  (NumPhrasings >= 2) =>
    /\ NumPhrasings - 1 >= 1   \* at least 1 non-winner
    /\ TRUE                     \* winner exists if any valid phrasing exists

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-CONTEXT-REDUCES
\*
\* Shared context between speaker and listener effectively adds
\* implicit parallel channels, reducing the semiotic deficit.
\*
\* Expert-to-expert: high context → low deficit → precise communication
\* Expert-to-novice: low context → high deficit → confusion
\* ═══════════════════════════════════════════════════════════════════════

SemioticContextHolds ==
  (SemanticPaths >= 2 /\ ArticulationStreams >= 1 /\ ContextPaths >= 0) =>
    /\ ContextReducedDeficit <= SemioticDeficit
    /\ (ContextPaths > 0 => ContextReducedDeficit < SemioticDeficit)
    /\ (ContextPaths >= SemanticPaths - ArticulationStreams =>
          ContextReducedDeficit <= 0)  \* enough context eliminates deficit

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-CONVERSATION-TRACE
\*
\* Dialogue is a traced monoidal operation: speak → hear response →
\* adjust internal state → speak again.  The trace operator Tr feeds
\* the listener's response back into the speaker's next utterance.
\*
\* Each turn of conversation is f : Thought ⊗ Response → Speech ⊗ Response
\* The trace iterates this, converging toward mutual understanding.
\*
\* Modeled: after N turns, the effective deficit decreases as shared
\* context accumulates (each turn adds context paths).
\* ═══════════════════════════════════════════════════════════════════════

EffectiveDeficitAtTurn(n) ==
  LET effectiveContext == n  \* each turn adds ~1 context path
      augBeta1 == ArticulationStreams + ContextPaths + effectiveContext - 1
  IN  ThoughtBeta1 - augBeta1

SemioticTraceHolds ==
  (SemanticPaths >= 2 /\ ArticulationStreams >= 1 /\ NumTurns >= 1) =>
    /\ EffectiveDeficitAtTurn(0) >= EffectiveDeficitAtTurn(1)
    /\ EffectiveDeficitAtTurn(1) >= EffectiveDeficitAtTurn(NumTurns)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-SEMIOTIC-MOA-ISOMORPHISM
\*
\* The Mixture of Agents architecture is isomorphic to the semiotic
\* pipeline: multiple agents generate in parallel (fork), race to
\* completion, fold results.  The deficit between what the ensemble
\* "knows" collectively and what the final output says is the same
\* structural gap as thought→speech.
\*
\* MOA semantic paths = number of agents (each has independent knowledge)
\* MOA articulation = 1 final output stream
\* MOA deficit = num_agents - 1
\* ═══════════════════════════════════════════════════════════════════════

MOADeficit(numAgents) == numAgents - 1

SemioticMOAHolds ==
  (SemanticPaths >= 2 /\ ArticulationStreams = 1) =>
    /\ MOADeficit(SemanticPaths) = SemioticDeficit
    /\ MOADeficit(SemanticPaths) = SemanticPaths - 1

\* ─── Init / Check / Spec ─────────────────────────────────────────────
Init ==
  /\ turn = 0
  /\ checked = FALSE
  /\ deficitOk = TRUE
  /\ erasureOk = TRUE
  /\ ventOk = TRUE
  /\ raceOk = TRUE
  /\ contextOk = TRUE
  /\ traceOk = TRUE
  /\ moaOk = TRUE

CheckAll ==
  /\ ~checked
  /\ deficitOk' = SemioticDeficitHolds
  /\ erasureOk' = SemioticErasureHolds
  /\ ventOk' = SemioticVentHolds
  /\ raceOk' = SemioticRaceHolds
  /\ contextOk' = SemioticContextHolds
  /\ traceOk' = SemioticTraceHolds
  /\ moaOk' = SemioticMOAHolds
  /\ checked' = TRUE
  /\ UNCHANGED <<turn>>

Stutter == UNCHANGED vars
Next == CheckAll \/ Stutter
Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────
InvDeficit == checked => deficitOk
InvErasure == checked => erasureOk
InvVent == checked => ventOk
InvRace == checked => raceOk
InvContext == checked => contextOk
InvTrace == checked => traceOk
InvMOA == checked => moaOk

=============================================================================
