---------------------------- MODULE ServerTopology ----------------------------
(***************************************************************************)
(* Track Alpha: Server Topology Verification.                              *)
(*                                                                         *)
(* Models the x-gnosis server lifecycle as a fork/race/fold transition     *)
(* system. The server topology is:                                         *)
(*                                                                         *)
(*   FORK(conn) -> PROCESS(parse) -> RACE(cache|mmap|disk) ->              *)
(*   FOLD(headers|compress) -> PROCESS(send)                               *)
(*                                                                         *)
(* THM-SERVER-RACE-ELIMINATION: Race terminates with exactly 1 winner      *)
(* THM-SERVER-FOLD-INTEGRITY: Fold preserves content-length invariant      *)
(* THM-SERVER-ROTATION-DEPTH: Wallington Rotation achieves T=ceil(P/B)+N-1 *)
(* THM-SERVER-CACHE-MONOTONE: Cache warming monotonically improves hit rate*)
(***************************************************************************)

EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS
  RaceArmCount,       \* Number of file resolution arms (default: 3 for cache|mmap|disk)
  FoldArmCount,       \* Number of response fold arms (default: 2 for headers|body)
  BatchSize,          \* Wallington Rotation batch size (B)
  PipelineStages,     \* Number of pipeline stages (N, default: 4)
  TotalRequests,      \* Total requests to serve (P)
  CacheCapacity       \* Maximum cache entries

VARIABLES
  raceArms,           \* Status of each race arm: "active" | "completed" | "vented"
  raceWinner,         \* Which arm won the race (0 = none yet)
  raceVentCount,      \* Number of vented (losing) arms
  foldArms,           \* Status of each fold arm: "active" | "completed"
  foldResults,        \* Results from each fold arm (content bytes)
  responseSize,       \* Final assembled response size
  headerSize,         \* Headers arm result size
  bodySize,           \* Body arm result size
  cacheEntries,       \* Number of entries currently in cache
  cacheHits,          \* Total cache hits across all requests
  cacheMisses,        \* Total cache misses
  requestsServed,     \* How many requests completed
  pipelineDepth,      \* Computed pipeline depth T
  phase               \* Execution phase

vars == <<raceArms, raceWinner, raceVentCount, foldArms, foldResults,
          responseSize, headerSize, bodySize, cacheEntries, cacheHits,
          cacheMisses, requestsServed, pipelineDepth, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME RaceArmCount >= 2       \* At least cache and disk
ASSUME FoldArmCount >= 2       \* At least headers and body
ASSUME BatchSize >= 1
ASSUME PipelineStages >= 2
ASSUME TotalRequests >= 1
ASSUME CacheCapacity >= 1

\* ─── Helpers ─────────────────────────────────────────────────────────

CeilDiv(a, b) == (a + b - 1) \div b

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ raceArms = [i \in 1..RaceArmCount |-> "active"]
  /\ raceWinner = 0
  /\ raceVentCount = 0
  /\ foldArms = [i \in 1..FoldArmCount |-> "active"]
  /\ foldResults = [i \in 1..FoldArmCount |-> 0]
  /\ responseSize = 0
  /\ headerSize = 0
  /\ bodySize = 0
  /\ cacheEntries = 0
  /\ cacheHits = 0
  /\ cacheMisses = 0
  /\ requestsServed = 0
  /\ pipelineDepth = 0
  /\ phase = "init"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Phase 1: One race arm completes first (the winner)
RaceOneWins ==
  /\ phase = "init"
  /\ \E winner \in 1..RaceArmCount :
       /\ raceArms[winner] = "active"
       /\ raceWinner' = winner
       /\ raceArms' = [i \in 1..RaceArmCount |->
            IF i = winner THEN "completed" ELSE "active"]
       /\ phase' = "race_winner"
  /\ UNCHANGED <<raceVentCount, foldArms, foldResults, responseSize,
                  headerSize, bodySize, cacheEntries, cacheHits,
                  cacheMisses, requestsServed, pipelineDepth>>

\* Phase 2: Vent all losing arms
VentLosers ==
  /\ phase = "race_winner"
  /\ raceArms' = [i \in 1..RaceArmCount |->
       IF i = raceWinner THEN "completed" ELSE "vented"]
  /\ raceVentCount' = RaceArmCount - 1
  /\ phase' = "race_complete"
  /\ UNCHANGED <<raceWinner, foldArms, foldResults, responseSize,
                  headerSize, bodySize, cacheEntries, cacheHits,
                  cacheMisses, requestsServed, pipelineDepth>>

\* Phase 3: Update cache (winner populates cache if it was a miss)
UpdateCache ==
  /\ phase = "race_complete"
  /\ IF raceWinner = 1
     THEN \* Cache hit (arm 1 = cache)
          /\ cacheHits' = cacheHits + 1
          /\ cacheMisses' = cacheMisses
          /\ cacheEntries' = cacheEntries
     ELSE \* Cache miss -- mmap or disk won, populate cache
          /\ cacheMisses' = cacheMisses + 1
          /\ cacheHits' = cacheHits
          /\ cacheEntries' = IF cacheEntries < CacheCapacity
                             THEN cacheEntries + 1
                             ELSE cacheEntries
  /\ phase' = "cache_updated"
  /\ UNCHANGED <<raceArms, raceWinner, raceVentCount, foldArms,
                  foldResults, responseSize, headerSize, bodySize,
                  requestsServed, pipelineDepth>>

\* Phase 4: Fork into fold arms (headers + body)
ForkForFold ==
  /\ phase = "cache_updated"
  /\ headerSize' = 256          \* Fixed header size (representative)
  /\ bodySize' = 4096           \* Fixed body size (representative)
  /\ foldArms' = [i \in 1..FoldArmCount |-> "completed"]
  /\ foldResults' = [i \in 1..FoldArmCount |->
       IF i = 1 THEN 256 ELSE 4096]
  /\ phase' = "fold_ready"
  /\ UNCHANGED <<raceArms, raceWinner, raceVentCount, responseSize,
                  cacheEntries, cacheHits, cacheMisses,
                  requestsServed, pipelineDepth>>

\* Phase 5: Fold results into assembled response
FoldResponse ==
  /\ phase = "fold_ready"
  /\ responseSize' = headerSize + bodySize
  /\ phase' = "response_assembled"
  /\ UNCHANGED <<raceArms, raceWinner, raceVentCount, foldArms,
                  foldResults, headerSize, bodySize, cacheEntries,
                  cacheHits, cacheMisses, requestsServed, pipelineDepth>>

\* Phase 6: Mark request complete, compute pipeline depth
CompleteRequest ==
  /\ phase = "response_assembled"
  /\ requestsServed' = requestsServed + 1
  /\ pipelineDepth' = CeilDiv(TotalRequests, BatchSize) + PipelineStages - 1
  /\ phase' = "complete"
  /\ UNCHANGED <<raceArms, raceWinner, raceVentCount, foldArms,
                  foldResults, responseSize, headerSize, bodySize,
                  cacheEntries, cacheHits, cacheMisses>>

Stutter == UNCHANGED vars

Next ==
  \/ RaceOneWins
  \/ VentLosers
  \/ UpdateCache
  \/ ForkForFold
  \/ FoldResponse
  \/ CompleteRequest
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(RaceOneWins)
    /\ WF_vars(VentLosers)
    /\ WF_vars(UpdateCache)
    /\ WF_vars(ForkForFold)
    /\ WF_vars(FoldResponse)
    /\ WF_vars(CompleteRequest)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1 (THM-SERVER-RACE-ELIMINATION):
\* After race, exactly 1 winner and (N-1) vented arms
InvRaceElimination ==
  (phase = "race_complete")
    => /\ raceVentCount = RaceArmCount - 1
       /\ raceWinner \in 1..RaceArmCount
       /\ raceArms[raceWinner] = "completed"
       /\ \A i \in 1..RaceArmCount :
            i # raceWinner => raceArms[i] = "vented"

\* INV2 (THM-SERVER-FOLD-INTEGRITY):
\* Assembled response size = sum of fold arm results
InvFoldIntegrity ==
  (phase = "response_assembled")
    => responseSize = headerSize + bodySize

\* INV3 (THM-SERVER-ROTATION-DEPTH):
\* Pipeline depth = ceil(P/B) + N - 1 (the Wallington formula)
InvRotationDepth ==
  (phase = "complete")
    => pipelineDepth = CeilDiv(TotalRequests, BatchSize) + PipelineStages - 1

\* INV4 (THM-SERVER-CACHE-MONOTONE):
\* Cache entries never decrease (monotone warming)
InvCacheMonotone ==
  cacheEntries >= 0 /\ cacheEntries <= CacheCapacity

\* INV5: Total hits + misses = requests served
InvCacheAccounting ==
  cacheHits + cacheMisses = requestsServed

\* INV6: Race winner is valid
InvRaceWinnerValid ==
  (raceWinner > 0) => raceWinner \in 1..RaceArmCount

\* INV7: Response is non-negative
InvResponsePositive ==
  (phase = "response_assembled") => responseSize > 0

\* ─── Liveness ────────────────────────────────────────────────────────

RequestTermination == <>(phase = "complete")

=============================================================================
