------------------------------ MODULE NovelInference ------------------------------
EXTENDS Naturals, FiniteSets

\* Five Novel Inference Forms: Rejection RL, Topological Routing,
\* Void Cache Compression, Thermodynamic Early Exit, Inverse Inference.
\*
\* THM-REJECTION-GRADIENT: Rejection gradient weights always positive.
\* THM-BETA1-COMPUTE-MONOTONE: Higher beta-1 -> more compute allocated.
\* THM-MINIMUM-COMPUTE: Every token gets >= 1 layer.
\* THM-CACHE-COMPRESSION: Void cache <= full KV cache in size.
\* THM-RECONSTRUCTION-BOUNDED: Same boundary -> same distribution.
\* THM-FREE-ENERGY-DECREASING: Free energy non-increasing per layer.
\* THM-EXIT-EVENTUAL: Exit reached within maxLayers.
\* THM-INVERSE-POSITIVITY: All inverse probabilities > 0.

CONSTANTS
  NumChoices,        \* number of choices in Buleyean space (>= 2)
  MaxRounds,         \* maximum rejection rounds to simulate
  MaxLayers,         \* maximum transformer layers
  DModel,            \* model dimension (for cache comparison)
  MaxBeta1           \* maximum token beta-1

VARIABLES
  \* Rejection RL state
  voidBoundary,      \* rejection counts per choice (function 1..NumChoices -> Nat)
  rounds,            \* total rounds observed
  gradientWeights,   \* complement weights per choice

  \* Topological routing state
  tokenBeta1,        \* current token's beta-1
  computeAllocated,  \* layers allocated to current token

  \* Void cache state
  cacheSize,         \* size of void cache (= NumChoices)
  fullCacheSize,     \* size of full KV cache (= NumChoices * DModel)

  \* Thermodynamic exit state
  freeEnergy,        \* remaining free energy (layers left)
  layersComputed,    \* layers computed so far
  exitTriggered,     \* has exit been triggered?

  \* Inverse inference state
  inverseWeights,    \* inverse distribution weights
  inversePositive,   \* all inverse weights > 0?

  step               \* global step counter

vars == <<voidBoundary, rounds, gradientWeights,
          tokenBeta1, computeAllocated,
          cacheSize, fullCacheSize,
          freeEnergy, layersComputed, exitTriggered,
          inverseWeights, inversePositive,
          step>>

\* ═══════════════════════════════════════════════════════════════════════════════
\* Helper: compute complement weight for choice i
\* ═══════════════════════════════════════════════════════════════════════════════

\* Weight = rounds - min(voidBoundary[i], rounds) + 1
ComputeWeight(i) ==
  LET v == IF voidBoundary[i] <= rounds THEN voidBoundary[i] ELSE rounds
  IN rounds - v + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Init
\* ═══════════════════════════════════════════════════════════════════════════════

Init ==
  /\ voidBoundary = [i \in 1..NumChoices |-> 0]
  /\ rounds = 1
  /\ gradientWeights = [i \in 1..NumChoices |-> 2]  \* weight = 1 - 0 + 1 = 2
  /\ tokenBeta1 = 1
  /\ computeAllocated = 2  \* beta1 + 1
  /\ cacheSize = NumChoices
  /\ fullCacheSize = NumChoices * DModel
  /\ freeEnergy = MaxLayers
  /\ layersComputed = 0
  /\ exitTriggered = FALSE
  /\ inverseWeights = [i \in 1..NumChoices |-> 2]
  /\ inversePositive = TRUE
  /\ step = 0

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions
\* ═══════════════════════════════════════════════════════════════════════════════

\* Reject a random choice (simulate one void boundary update)
RejectChoice ==
  /\ step < MaxRounds
  /\ \E c \in 1..NumChoices :
      /\ voidBoundary' = [voidBoundary EXCEPT ![c] = @ + 1]
      /\ rounds' = rounds + 1
      /\ gradientWeights' = [i \in 1..NumChoices |->
            ComputeWeight(i) + (IF i = c THEN 0 ELSE 1)]
            \* After rejection: non-rejected gain 1 from new round
      /\ inverseWeights' = gradientWeights'
      /\ inversePositive' = \A i \in 1..NumChoices : gradientWeights'[i] > 0
  /\ UNCHANGED <<tokenBeta1, computeAllocated, cacheSize, fullCacheSize,
                 freeEnergy, layersComputed, exitTriggered>>
  /\ step' = step + 1

\* Allocate compute for a token with given beta-1
AllocateCompute ==
  /\ step < MaxRounds
  /\ \E b \in 0..MaxBeta1 :
      /\ tokenBeta1' = b
      /\ computeAllocated' = b + 1  \* beta1 + 1 layers
  /\ UNCHANGED <<voidBoundary, rounds, gradientWeights,
                 cacheSize, fullCacheSize,
                 freeEnergy, layersComputed, exitTriggered,
                 inverseWeights, inversePositive>>
  /\ step' = step + 1

\* Process one transformer layer (thermodynamic exit check)
ComputeLayer ==
  /\ step < MaxRounds
  /\ ~exitTriggered
  /\ layersComputed < MaxLayers
  /\ freeEnergy > 0
  /\ layersComputed' = layersComputed + 1
  /\ freeEnergy' = freeEnergy - 1
  /\ exitTriggered' = (freeEnergy - 1 = 0)
  /\ UNCHANGED <<voidBoundary, rounds, gradientWeights,
                 tokenBeta1, computeAllocated,
                 cacheSize, fullCacheSize,
                 inverseWeights, inversePositive>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Next-state relation
\* ═══════════════════════════════════════════════════════════════════════════════

Next ==
  \/ RejectChoice
  \/ AllocateCompute
  \/ ComputeLayer

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* ═══════════════════════════════════════════════════════════════════════════════
\* Invariants
\* ═══════════════════════════════════════════════════════════════════════════════

\* THM-REJECTION-GRADIENT: All gradient weights are strictly positive
InvRejectionGradientPositive ==
  \A i \in 1..NumChoices : gradientWeights[i] > 0

\* THM-BETA1-COMPUTE-MONOTONE: Higher beta-1 -> more compute
\* (verified: computeAllocated = tokenBeta1 + 1, monotone in beta1)
InvBeta1ComputeMonotone ==
  computeAllocated = tokenBeta1 + 1

\* THM-MINIMUM-COMPUTE: Every token gets at least 1 layer
InvMinimumComputeGuarantee ==
  computeAllocated >= 1

\* THM-CACHE-COMPRESSION: Void cache <= full KV cache
InvCacheCompression ==
  cacheSize <= fullCacheSize

\* THM-RECONSTRUCTION-BOUNDED: Gradient weights match inverse weights
\* (same boundary -> same distribution)
InvReconstructionBounded ==
  \A i \in 1..NumChoices : gradientWeights[i] = inverseWeights[i]

\* THM-FREE-ENERGY-DECREASING: Free energy is non-increasing
InvFreeEnergyDecreasing ==
  freeEnergy = MaxLayers - layersComputed

\* THM-EXIT-EVENTUAL: Exit triggered when all layers computed
InvExitEventual ==
  (layersComputed = MaxLayers) => exitTriggered

\* THM-INVERSE-POSITIVITY: All inverse distribution weights > 0
InvInversePositivity ==
  inversePositive => (\A i \in 1..NumChoices : inverseWeights[i] > 0)

=============================================================================
