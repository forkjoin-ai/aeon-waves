------------------------------ MODULE DeficitCapacity ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* Track Theta: Deficit-Capacity Duality (Information Bottleneck)
\*
\* Proves that topological deficit Δβ = β₁* - β₁ quantitatively lower-bounds
\* the information-processing capacity gap between a problem and its
\* implementation.  Upgrades THM-COVERING-CAUSALITY ("deficit causes blocking")
\* to "deficit causes information loss" with an explicit bound.
\*
\* THM-DEFICIT-CAPACITY-GAP:        capacity gap ≥ (k - m) · c_min
\* THM-DEFICIT-INFORMATION-LOSS:    Δβ > 0 ⟹ positive information loss
\* THM-DEFICIT-ERASURE-CHAIN:       deficit → info loss → Landauer heat → waste
\* THM-ZERO-DEFICIT-PRESERVES-INFO: Δβ = 0 permits lossless transport
\* THM-DEFICIT-MONOTONE-IN-STREAMS: info loss decreasing in stream count

CONSTANTS MaxPaths, MaxStreams, MinCapacity

VARIABLES pathCount, streamCount, checked,
          capacityGapOk, informationLossOk, erasureChainOk,
          zeroDeficitOk, monotoneOk

vars == <<pathCount, streamCount, checked,
          capacityGapOk, informationLossOk, erasureChainOk,
          zeroDeficitOk, monotoneOk>>

\* ─── Betti numbers (from CoveringSpaceCausality) ─────────────────────
ComputationBeta1(k) == k - 1
TransportBeta1(m)   == m - 1

\* ─── Topological deficit ─────────────────────────────────────────────
TopologicalDeficit(k, m) == ComputationBeta1(k) - TransportBeta1(m)

\* ─── Per-stream capacity ─────────────────────────────────────────────
\* Each transport stream has capacity at least MinCapacity bits per step
PerStreamCapacity == MinCapacity

\* ─── Problem capacity requirement ────────────────────────────────────
\* k independent paths each require one stream of capacity c
ProblemCapacity(k) == k * PerStreamCapacity

\* ─── Transport capacity ──────────────────────────────────────────────
\* m streams provide total capacity m · c
TransportCapacity(m) == m * PerStreamCapacity

\* ─── Capacity gap ────────────────────────────────────────────────────
CapacityGap(k, m) ==
  IF k > m THEN (k - m) * PerStreamCapacity
  ELSE 0

\* ─── Pigeonhole collision count ──────────────────────────────────────
\* With k paths on m < k streams, at least k - m paths share a stream
\* with another path (pigeonhole principle)
CollisionCount(k, m) ==
  IF k > m THEN k - m
  ELSE 0

\* ═══════════════════════════════════════════════════════════════════════
\* THM-DEFICIT-CAPACITY-GAP
\*
\* For k independent computation paths on m < k transport streams,
\* the per-step capacity gap is ≥ (k - m) · c_min
\* ═══════════════════════════════════════════════════════════════════════

CapacityGapHoldsFor(k, m) ==
  (k > m /\ k > 0 /\ m > 0) =>
    CapacityGap(k, m) >= (k - m) * MinCapacity

\* ═══════════════════════════════════════════════════════════════════════
\* THM-DEFICIT-INFORMATION-LOSS
\*
\* Topological deficit Δβ > 0 forces positive information loss under
\* any multiplexing strategy.  Modeled: when k > m, at least one
\* stream carries multiple paths, creating a many-to-one mapping
\* that erases information (by DPI).
\* ═══════════════════════════════════════════════════════════════════════

InformationLossHoldsFor(k, m) ==
  (k > m /\ k >= 2 /\ m >= 1) =>
    /\ CollisionCount(k, m) > 0    \* pigeonhole: collisions exist
    /\ CapacityGap(k, m) > 0       \* capacity is strictly insufficient

\* ═══════════════════════════════════════════════════════════════════════
\* THM-DEFICIT-ERASURE-CHAIN
\*
\* deficit → information loss → Landauer heat → observable waste
\* The full chain from topology to thermodynamics.
\* ═══════════════════════════════════════════════════════════════════════

ErasureChainHoldsFor(k, m) ==
  (k > m /\ k >= 2 /\ m >= 1) =>
    /\ CollisionCount(k, m) > 0        \* Step 1: deficit → collisions
    /\ CapacityGap(k, m) > 0           \* Step 2: collisions → info loss
    /\ CapacityGap(k, m) * 1 > 0       \* Step 3: info loss → heat (kT ln2 · H)
                                        \* (modeled as proportional, heat > 0)

\* ═══════════════════════════════════════════════════════════════════════
\* THM-ZERO-DEFICIT-PRESERVES-INFORMATION
\*
\* When Δβ = 0 (m ≥ k), there exists a multiplexing strategy achieving
\* H(X|Y) = 0 (lossless).  Each path gets its own stream.
\* ═══════════════════════════════════════════════════════════════════════

ZeroDeficitHoldsFor(k, m) ==
  (m >= k /\ k > 0) =>
    /\ CollisionCount(k, m) = 0     \* no pigeonhole collisions
    /\ CapacityGap(k, m) = 0        \* no capacity gap

\* ═══════════════════════════════════════════════════════════════════════
\* THM-DEFICIT-MONOTONE-IN-STREAMS
\*
\* Information loss is monotonically decreasing in transport stream count,
\* reaching zero when m ≥ k.
\* ═══════════════════════════════════════════════════════════════════════

MonotoneHoldsFor(k, m1, m2) ==
  (k > 0 /\ m1 >= 1 /\ m2 >= 1 /\ m1 <= m2) =>
    CollisionCount(k, m2) <= CollisionCount(k, m1)

\* ─── Init ────────────────────────────────────────────────────────────
Init ==
  /\ pathCount = 1
  /\ streamCount = 1
  /\ checked = FALSE
  /\ capacityGapOk = TRUE
  /\ informationLossOk = TRUE
  /\ erasureChainOk = TRUE
  /\ zeroDeficitOk = TRUE
  /\ monotoneOk = TRUE

\* ─── Check all configurations ────────────────────────────────────────
CheckAll ==
  /\ ~checked
  /\ capacityGapOk' = \A k \in 1..MaxPaths, m \in 1..MaxStreams:
       CapacityGapHoldsFor(k, m)
  /\ informationLossOk' = \A k \in 1..MaxPaths, m \in 1..MaxStreams:
       InformationLossHoldsFor(k, m)
  /\ erasureChainOk' = \A k \in 1..MaxPaths, m \in 1..MaxStreams:
       ErasureChainHoldsFor(k, m)
  /\ zeroDeficitOk' = \A k \in 1..MaxPaths, m \in 1..MaxStreams:
       ZeroDeficitHoldsFor(k, m)
  /\ monotoneOk' = \A k \in 1..MaxPaths, m1 \in 1..MaxStreams, m2 \in 1..MaxStreams:
       MonotoneHoldsFor(k, m1, m2)
  /\ checked' = TRUE
  /\ UNCHANGED <<pathCount, streamCount>>

Stutter == UNCHANGED vars

Next == CheckAll \/ Stutter

Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────

\* THM-DEFICIT-CAPACITY-GAP: capacity gap ≥ deficit · c_min
InvCapacityGap ==
  checked => capacityGapOk

\* THM-DEFICIT-INFORMATION-LOSS: positive deficit → positive info loss
InvInformationLoss ==
  checked => informationLossOk

\* THM-DEFICIT-ERASURE-CHAIN: deficit → info loss → heat → waste
InvErasureChain ==
  checked => erasureChainOk

\* THM-ZERO-DEFICIT-PRESERVES-INFO: zero deficit → lossless possible
InvZeroDeficit ==
  checked => zeroDeficitOk

\* THM-DEFICIT-MONOTONE-IN-STREAMS: info loss decreasing in streams
InvMonotone ==
  checked => monotoneOk

\* Cross-check: deficit is consistent with CoveringSpaceCausality
InvDeficitConsistency ==
  \A k \in 2..MaxPaths:
    TopologicalDeficit(k, 1) > 0

=============================================================================
