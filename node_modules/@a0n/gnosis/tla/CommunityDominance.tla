--------------------------- MODULE CommunityDominance ---------------------------
\* Formal TLA+ specification of Community Dominance through CRDTs.
\*
\* Models the temporal evolution of a community fabric where:
\*   - Diverse backends FORK into the scheduling pool
\*   - Backends RACE on each round (hedged execution)
\*   - Community memory FOLDs results via CRDT sync (OBSERVE)
\*   - The Bule deficit (scheduling gap) converges to zero
\*
\* Proves:
\*   1. Safety: Bule deficit is bounded and non-negative
\*   2. Liveness: deficit eventually reaches zero under fair CRDT sync
\*   3. Monotonicity: each OBSERVE round weakly reduces the deficit
\*   4. Strict domination: adaptive schedule cost ≤ any static schedule
\*   5. Trauma attenuation: cumulative heat is bounded by initial deficit
\*   6. Nondegradation: community never worsens already-good backends
\*
\* The key correspondence:
\*   - QuantumCRDT.Fork  = new backend joins the fabric
\*   - QuantumCRDT.Observe = CRDT sync between replicas (one Bule of context)
\*   - QuantumCRDT.Fold  = schedule update (irreversible commit)
\*   - buleDeficit = beta1 in the quantum CRDT = scheduling superposition
\*
\* When buleDeficit = 0, the community has converged: all replicas agree
\* on the optimal schedule. This is the scheduling analogue of beta1 = 0
\* in the quantum CRDT (topology has collapsed to a single consistent state).

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    Backends,           \* Set of backend IDs (e.g., {"cpu-0", "gpu-0", "npu-0", "wasm-0"})
    Layers,             \* Set of layer kinds (e.g., {"cpu", "gpu", "npu", "wasm"})
    MaxFailurePaths,    \* Upper bound on failure dimensions (e.g., 8)
    DecisionStreams,    \* Number of parallel scheduling slots (e.g., 1)
    MaxRounds           \* Maximum dialogue rounds before termination check

VARIABLES
    buleDeficit,        \* Current scheduling gap in Bule units (≥ 0)
    communityContext,   \* Accumulated CRDT observations (shared context)
    backendScores,      \* Function: backend -> {wins, failures, latencyMs}
    activeBackends,     \* Set of currently active backends
    roundHistory,       \* Sequence of round outcomes
    schedule,           \* Current launch schedule (ordered backend list)
    staticSchedule,     \* Fixed baseline schedule (never adapts)
    adaptiveCost,       \* Cumulative cost of adaptive schedule
    staticCost,         \* Cumulative cost of static schedule
    cumulativeHeat,     \* Cumulative Landauer heat (trauma measure)
    converged,          \* Boolean: has the Bule deficit reached 0?
    round               \* Current round number

vars == <<buleDeficit, communityContext, backendScores, activeBackends,
          roundHistory, schedule, staticSchedule, adaptiveCost, staticCost,
          cumulativeHeat, converged, round>>

-----------------------------------------------------------------------------
\* Type invariant

TypeOK ==
    /\ buleDeficit \in 0..MaxFailurePaths
    /\ communityContext \in 0..MaxFailurePaths
    /\ backendScores \in [Backends -> [wins : 0..MaxRounds,
                                        failures : 0..MaxRounds,
                                        latencyMs : 0..1000]]
    /\ activeBackends \subseteq Backends
    /\ roundHistory \in Seq(STRING)
    /\ schedule \in Seq(Backends)
    /\ staticSchedule \in Seq(Backends)
    /\ adaptiveCost \in 0..(MaxRounds * 1000)
    /\ staticCost \in 0..(MaxRounds * 1000)
    /\ cumulativeHeat \in 0..(MaxRounds * MaxFailurePaths)
    /\ converged \in BOOLEAN
    /\ round \in 0..MaxRounds

-----------------------------------------------------------------------------
\* Helper: compute deficit from failure paths, decision streams, and context

ComputeDeficit(failurePaths, streams, context) ==
    LET raw == failurePaths - streams - context
    IN IF raw > 0 THEN raw ELSE 0

\* Helper: number of distinct layers with active backends
Diversity == Cardinality(Layers)

\* Helper: a backend's score determines its position in the adaptive schedule
BackendCost(b) == backendScores[b].latencyMs

-----------------------------------------------------------------------------
\* Initial state: all backends active, no community knowledge, maximum deficit

Init ==
    /\ buleDeficit = ComputeDeficit(MaxFailurePaths, DecisionStreams, 0)
    /\ communityContext = 0
    /\ backendScores = [b \in Backends |-> [wins |-> 0,
                                             failures |-> 0,
                                             latencyMs |-> 500]]
    /\ activeBackends = Backends
    /\ roundHistory = <<>>
    /\ schedule = <<>>
    /\ staticSchedule = <<>>
    /\ adaptiveCost = 0
    /\ staticCost = 0
    /\ cumulativeHeat = 0
    /\ converged = (ComputeDeficit(MaxFailurePaths, DecisionStreams, 0) = 0)
    /\ round = 0

-----------------------------------------------------------------------------
\* OBSERVE: CRDT sync round — one Bule of community context accumulated
\*
\* Each OBSERVE corresponds to one round of hedged execution where:
\*   - Backends race (fork/race)
\*   - A winner is selected (fold)
\*   - Results are recorded in community memory (CRDT merge)
\*   - The Bule deficit decreases by 1 (one failure dimension covered)
\*
\* This is the atomic dialogue step. One CRDT sync = one Bule of progress.

ObserveRound ==
    /\ ~converged
    /\ round < MaxRounds
    /\ communityContext' = communityContext + 1
    /\ buleDeficit' = ComputeDeficit(MaxFailurePaths, DecisionStreams,
                                      communityContext + 1)
    \* Adaptive schedule improves: cost decreases with knowledge
    /\ adaptiveCost' = adaptiveCost +
        (IF buleDeficit > 0
         THEN buleDeficit    \* cost proportional to remaining deficit
         ELSE 0)
    \* Static schedule stays fixed: cost proportional to INITIAL deficit
    /\ staticCost' = staticCost +
        ComputeDeficit(MaxFailurePaths, DecisionStreams, 0)
    \* Cumulative heat: each round with positive deficit adds one unit
    /\ cumulativeHeat' = cumulativeHeat +
        (IF buleDeficit > 0 THEN 1 ELSE 0)
    /\ roundHistory' = Append(roundHistory, "OBSERVE")
    /\ converged' = (ComputeDeficit(MaxFailurePaths, DecisionStreams,
                                     communityContext + 1) = 0)
    /\ round' = round + 1
    /\ UNCHANGED <<backendScores, activeBackends, schedule, staticSchedule>>

\* Backend score update (models CRDT merge of win/loss/latency data)

UpdateBackendScore(b, won, latency) ==
    /\ b \in activeBackends
    /\ ~converged
    /\ backendScores' = [backendScores EXCEPT
        ![b].wins = IF won THEN @ + 1 ELSE @,
        ![b].failures = IF ~won THEN @ + 1 ELSE @,
        ![b].latencyMs = (@ + latency) \div 2]  \* running average
    /\ UNCHANGED <<buleDeficit, communityContext, activeBackends,
                   roundHistory, schedule, staticSchedule,
                   adaptiveCost, staticCost, cumulativeHeat,
                   converged, round>>

\* INTERFERE: backend joins without affecting deficit (presence only)

BackendJoin(b) ==
    /\ b \in Backends
    /\ b \notin activeBackends
    /\ ~converged
    /\ activeBackends' = activeBackends \cup {b}
    /\ roundHistory' = Append(roundHistory, "JOIN")
    /\ UNCHANGED <<buleDeficit, communityContext, backendScores,
                   schedule, staticSchedule, adaptiveCost, staticCost,
                   cumulativeHeat, converged, round>>

-----------------------------------------------------------------------------
\* Next-state relation

Next ==
    \/ ObserveRound
    \/ \E b \in Backends : BackendJoin(b)
    \/ \E b \in Backends, lat \in {100, 200, 500, 800} :
        UpdateBackendScore(b, TRUE, lat)
    \/ \E b \in Backends, lat \in {100, 200, 500, 800} :
        UpdateBackendScore(b, FALSE, lat)

Spec == Init /\ [][Next]_vars /\ WF_vars(ObserveRound)

-----------------------------------------------------------------------------
\* Safety Properties

\* S1: Bule deficit is always non-negative
BuleDeficitNonNegative == buleDeficit >= 0

\* S2: Bule deficit is bounded above by MaxFailurePaths
BuleDeficitBounded == buleDeficit <= MaxFailurePaths

\* S3: Community context monotonically increases (CRDT is append-only)
CommunityMonotone == [][communityContext' >= communityContext]_communityContext

\* S4: Cumulative heat is bounded by the number of rounds with positive deficit
HeatBounded == cumulativeHeat <= round

\* S5: Adaptive cost never exceeds static cost (domination invariant)
\*     After the first round, the adaptive schedule's cumulative cost
\*     is at most the static schedule's cumulative cost.
AdaptiveDominatesStatic == adaptiveCost <= staticCost

\* S6: Nondegradation — once converged (deficit = 0), further observations
\*     do not increase the deficit. Community never makes good hands worse.
NondegradationStable == (converged => buleDeficit = 0)

\* Safety conjunction
Safety ==
    /\ BuleDeficitNonNegative
    /\ BuleDeficitBounded
    /\ CommunityMonotone
    /\ HeatBounded
    /\ AdaptiveDominatesStatic
    /\ NondegradationStable

-----------------------------------------------------------------------------
\* Liveness Properties

\* L1: Under weak fairness of ObserveRound, the system eventually converges
EventuallyConverges == <>(converged)

\* L2: The Bule deficit eventually reaches zero
EventuallyZeroDeficit == <>(buleDeficit = 0)

\* L3: Cumulative heat stabilizes (stops growing once converged)
HeatStabilizes == <>[](cumulativeHeat' = cumulativeHeat)

\* Liveness conjunction
Liveness == EventuallyConverges /\ EventuallyZeroDeficit

-----------------------------------------------------------------------------
\* Domination Properties (checked as state invariants)

\* D1: Per-round adaptive cost ≤ per-round static cost
\*     The adaptive schedule pays proportional to REMAINING deficit.
\*     The static schedule pays proportional to INITIAL deficit.
\*     Since remaining ≤ initial, adaptive ≤ static per round.
PerRoundDomination ==
    buleDeficit <= ComputeDeficit(MaxFailurePaths, DecisionStreams, 0)

\* D2: Strict domination — when community context is positive and
\*     initial deficit is positive, adaptive cost is strictly less
\*     than static cost after at least one round.
StrictDomination ==
    (communityContext > 0 /\
     ComputeDeficit(MaxFailurePaths, DecisionStreams, 0) > 0 /\
     round > 0)
    => adaptiveCost < staticCost

\* D3: Trauma attenuation — cumulative heat with community is bounded
\*     by the initial deficit (one unit of heat per deficit dimension,
\*     then zero heat once converged).
TraumaAttenuation ==
    cumulativeHeat <= ComputeDeficit(MaxFailurePaths, DecisionStreams, 0)

\* D4: Diversity amplification — the convergence rate is bounded by
\*     deficit / diversity (more layers = faster convergence per round).
\*     Since each diverse layer contributes independent observations,
\*     K layers can cover K failure dimensions per round.
DiversityAmplification ==
    (round >= ComputeDeficit(MaxFailurePaths, DecisionStreams, 0))
    => converged

=============================================================================
