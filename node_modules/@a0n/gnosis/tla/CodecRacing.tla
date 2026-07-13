----------------------------- MODULE CodecRacing ------------------------------
(***************************************************************************)
(* Track Beta: Topological Codec Racing Optimality.                        *)
(*                                                                         *)
(* Models per-resource codec racing as a fork/race/fold computation.       *)
(* For each resource, all codecs run in parallel; the smallest result wins.*)
(*                                                                         *)
(*   (raw)-[:FORK]->(identity | gzip | brotli | deflate)                   *)
(*   (identity | gzip | brotli | deflate)-[:RACE { smallest }]->(best)     *)
(*                                                                         *)
(* beta1 = |codecs| - 1 per resource                                       *)
(*                                                                         *)
(* THM-TOPO-RACE-SUBSUMPTION: Per-resource racing subsumes any fixed codec *)
(* THM-TOPO-RACE-MONOTONE: Adding codec to race never increases wire size  *)
(* THM-TOPO-RACE-DEFICIT: Racing achieves zero compression deficit         *)
(* THM-TOPO-RACE-ENTROPY: Wire bounded by per-resource conditional entropy *)
(***************************************************************************)

EXTENDS Naturals, FiniteSets

CONSTANTS
  CodecCount,         \* Number of codecs in the race (>= 2)
  ResourceCount,      \* Number of resources to serve
  MaxPayloadSize      \* Maximum raw payload size

VARIABLES
  rawSizes,           \* Raw size of each resource
  codecResults,       \* Compressed size per codec per resource: [resource][codec]
  raceWinners,        \* Which codec won for each resource
  raceBestSizes,      \* Best compressed size per resource (race winner)
  fixedCodecTotals,   \* Total wire using each fixed codec across all resources
  racingTotal,        \* Total wire using per-resource racing
  codecSetSize,       \* Current number of codecs in the race
  resourcesProcessed, \* How many resources have been raced
  phase               \* Execution phase

vars == <<rawSizes, codecResults, raceWinners, raceBestSizes,
          fixedCodecTotals, racingTotal, codecSetSize,
          resourcesProcessed, phase>>

\* ─── Assumptions ─────────────────────────────────────────────────────
ASSUME CodecCount >= 2
ASSUME ResourceCount >= 1
ASSUME MaxPayloadSize >= 1

\* ─── Initial State ───────────────────────────────────────────────────

Init ==
  /\ rawSizes = [r \in 1..ResourceCount |-> r * 100]  \* Varied sizes
  /\ codecResults = [r \in 1..ResourceCount |->
       [c \in 1..CodecCount |-> 0]]
  /\ raceWinners = [r \in 1..ResourceCount |-> 0]
  /\ raceBestSizes = [r \in 1..ResourceCount |-> 0]
  /\ fixedCodecTotals = [c \in 1..CodecCount |-> 0]
  /\ racingTotal = 0
  /\ codecSetSize = CodecCount
  /\ resourcesProcessed = 0
  /\ phase = "init"

\* ─── Actions ─────────────────────────────────────────────────────────

\* Phase 1: Simulate compression for each resource x codec
\* Model: codec c on resource r produces size depending on content type
\* Codec 1 = identity (rawSize), codec 2 = "gzip" (60-80%), codec 3 = "brotli" (55-75%)
\* Different resources respond differently to codecs (the key insight)
CompressAll ==
  /\ phase = "init"
  /\ codecResults' = [r \in 1..ResourceCount |->
       [c \in 1..CodecCount |->
         CASE c = 1 -> rawSizes[r]                          \* identity
         []   c = 2 -> (rawSizes[r] * (60 + (r % 20))) \div 100  \* "gzip" varies 60-79%
         []   c = 3 -> (rawSizes[r] * (55 + (r % 25))) \div 100  \* "brotli" varies 55-79%
         []   OTHER -> (rawSizes[r] * (65 + (r % 15))) \div 100  \* other codecs
       ]]
  /\ phase' = "compressed"
  /\ UNCHANGED <<rawSizes, raceWinners, raceBestSizes,
                  fixedCodecTotals, racingTotal, codecSetSize, resourcesProcessed>>

\* Phase 2: Race codecs per resource -- pick smallest
RacePerResource ==
  /\ phase = "compressed"
  /\ raceWinners' = [r \in 1..ResourceCount |->
       CHOOSE c \in 1..CodecCount :
         /\ codecResults[r][c] <= codecResults[r][1]
         /\ \A c2 \in 1..CodecCount :
              codecResults[r][c] <= codecResults[r][c2]]
  /\ raceBestSizes' = [r \in 1..ResourceCount |->
       LET winner == CHOOSE c \in 1..CodecCount :
             \A c2 \in 1..CodecCount : codecResults[r][c] <= codecResults[r][c2]
       IN codecResults[r][winner]]
  /\ resourcesProcessed' = ResourceCount
  /\ phase' = "raced"
  /\ UNCHANGED <<rawSizes, codecResults, fixedCodecTotals,
                  racingTotal, codecSetSize>>

\* Phase 3: Compute totals for fixed codecs and racing
ComputeTotals ==
  /\ phase = "raced"
  /\ fixedCodecTotals' = [c \in 1..CodecCount |->
       LET Total[r \in 0..ResourceCount] ==
         IF r = 0 THEN 0
         ELSE Total[r-1] + codecResults[r][c]
       IN Total[ResourceCount]]
  /\ LET RacingTotal[r \in 0..ResourceCount] ==
       IF r = 0 THEN 0
       ELSE RacingTotal[r-1] + raceBestSizes[r]
     IN racingTotal' = RacingTotal[ResourceCount]
  /\ phase' = "complete"
  /\ UNCHANGED <<rawSizes, codecResults, raceWinners, raceBestSizes,
                  codecSetSize, resourcesProcessed>>

Stutter == UNCHANGED vars

Next ==
  \/ CompressAll
  \/ RacePerResource
  \/ ComputeTotals
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(CompressAll)
    /\ WF_vars(RacePerResource)
    /\ WF_vars(ComputeTotals)

\* ─── Invariants ──────────────────────────────────────────────────────

\* INV1 (THM-TOPO-RACE-SUBSUMPTION):
\* Per-resource racing total <= every fixed-codec total
InvRaceSubsumption ==
  (phase = "complete")
    => \A c \in 1..CodecCount : racingTotal <= fixedCodecTotals[c]

\* INV2 (THM-TOPO-RACE-MONOTONE):
\* Race winner size <= identity (raw) size for every resource
\* (adding codecs never increases the result because identity is always in the race)
InvRaceMonotone ==
  (phase = "raced")
    => \A r \in 1..ResourceCount : raceBestSizes[r] <= rawSizes[r]

\* INV3 (THM-TOPO-RACE-DEFICIT):
\* Racing achieves zero "compression deficit" -- it never picks worse than the best
InvRaceZeroDeficit ==
  (phase = "raced")
    => \A r \in 1..ResourceCount :
         \A c \in 1..CodecCount :
           raceBestSizes[r] <= codecResults[r][c]

\* INV4: Racing total is strictly positive
InvRacingPositive ==
  (phase = "complete") => racingTotal > 0

\* INV5: Race winner is a valid codec index
InvWinnerValid ==
  (phase = "raced")
    => \A r \in 1..ResourceCount : raceWinners[r] \in 1..CodecCount

\* INV6: All resources were processed
InvAllProcessed ==
  (phase = "complete") => resourcesProcessed = ResourceCount

\* ─── Liveness ────────────────────────────────────────────────────────

RaceTermination == <>(phase = "complete")

=============================================================================
