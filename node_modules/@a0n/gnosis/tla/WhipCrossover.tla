------------------------------ MODULE WhipCrossover ------------------------------
EXTENDS Naturals

CONSTANTS ItemDomain, StageDomain, CorrectionDomain, ShardDomain

VARIABLES p, n, c, s

vars == <<p, n, c, s>>

Init ==
  /\ p \in ItemDomain
  /\ n \in StageDomain
  /\ c \in CorrectionDomain
  /\ s \in ShardDomain
  /\ p > 0
  /\ n > 0
  /\ c > 0

Change ==
  /\ p' \in ItemDomain
  /\ n' \in StageDomain
  /\ c' \in CorrectionDomain
  /\ s' \in ShardDomain
  /\ p' > 0
  /\ n' > 0
  /\ c' > 0

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

TotalTime(shards) == ((p + shards - 1) \div shards) + (n - 1) + c * shards

BestShard ==
  CHOOSE k \in ShardDomain : \A j \in ShardDomain : TotalTime(k) <= TotalTime(j)

InvWellFormed ==
  /\ p > 0
  /\ n > 0
  /\ c > 0
  /\ s \in ShardDomain

InvFiniteOptimumExists ==
  \E k \in ShardDomain : \A j \in ShardDomain : TotalTime(k) <= TotalTime(j)

InvBestShardInDomain ==
  BestShard \in ShardDomain

InvBestShardMinimizes ==
  \A j \in ShardDomain : TotalTime(BestShard) <= TotalTime(j)

InvStrictCrossoverExists ==
  \E k \in ShardDomain :
    /\ (k + 1) \in ShardDomain
    /\ TotalTime(k + 1) > TotalTime(k)

InvPostBestNonImproving ==
  \A k \in ShardDomain :
    /\ k >= BestShard
    /\ (k + 1) \in ShardDomain
    => TotalTime(k + 1) >= TotalTime(k)

=============================================================================

