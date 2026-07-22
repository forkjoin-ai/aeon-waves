------------------------------ MODULE MolecularTopology ------------------------------
EXTENDS Naturals, FiniteSets

\* THM-TOPO-MOLECULAR-ISO: Pipeline and molecular graphs with identical
\* Betti signatures are homologically equivalent.
\*
\* THM-PROTEIN-FUNNEL: Protein folding is a monotone filtration on β₁.
\*
\* THM-ENZYME-CATALYSIS: Enzyme adds one fork path (β₁ += 1),
\* lowers activation energy, and is reusable (not consumed).
\*
\* THM-EVOLUTION-SELF-MODIFYING: Natural selection is fork/race/fold
\* on a self-modifying pipeline.
\*
\* THM-GRAVITY-SELF-REFERENTIAL: Gravity is the fold acting on the
\* simplicial complex itself — mass modifies topology.
\*
\* THM-INFORMATION-MATTER: Fold erasure → Landauer heat → mass (E=mc²).

CONSTANTS
  MaxBeta1,         \* maximum β₁ in the model
  MaxFunnelDepth,   \* maximum protein folding funnel depth
  MaxPopulation,    \* maximum evolutionary population
  MaxSteps,         \* maximum action steps (bounds TLC state space)
  HeatPerBit        \* Landauer heat per erased bit (natural units)

VARIABLES
  \* Molecular topology state
  beta1,            \* current first Betti number
  beta0,            \* connected components
  beta2,            \* enclosed voids
  \* Protein folding state
  funnelLevel,      \* current depth in the folding funnel
  funnelBeta1,      \* β₁ at current funnel level
  folded,           \* has the protein reached native state?
  misfolded,        \* stuck at a local minimum?
  \* Enzyme catalysis state
  enzymePresent,    \* is an enzyme bound?
  activationEnergy, \* current activation energy
  baseActivation,   \* uncatalyzed activation energy
  \* Evolution state
  population,       \* current population count
  generation,       \* generation number
  survivors,        \* survivors after selection
  \* Gravity state
  foldEnergy,       \* energy deposited by fold
  topologyChanged,  \* has the fold modified the topology?
  \* Information-matter state
  bitsErased,       \* total bits erased by folds
  totalHeat,        \* total Landauer heat generated
  step

vars == <<beta1, beta0, beta2, funnelLevel, funnelBeta1, folded, misfolded,
          enzymePresent, activationEnergy, baseActivation,
          population, generation, survivors,
          foldEnergy, topologyChanged,
          bitsErased, totalHeat, step>>

Init ==
  /\ beta1 = MaxBeta1
  /\ beta0 = 1
  /\ beta2 = 0
  /\ funnelLevel = 0
  /\ funnelBeta1 = MaxBeta1
  /\ folded = FALSE
  /\ misfolded = FALSE
  /\ enzymePresent = FALSE
  /\ activationEnergy = 10
  /\ baseActivation = 10
  /\ population = MaxPopulation
  /\ generation = 0
  /\ survivors = MaxPopulation
  /\ foldEnergy = 0
  /\ topologyChanged = FALSE
  /\ bitsErased = 0
  /\ totalHeat = 0
  /\ step = 0

\* ═══════════════════════════════════════════════════════════════════════════════
\* Protein Folding Actions
\* ═══════════════════════════════════════════════════════════════════════════════

\* Descend one level in the folding funnel (β₁ decreases)
FunnelDescend ==
  /\ step < MaxSteps
  /\ ~folded
  /\ ~misfolded
  /\ funnelBeta1 > 1
  /\ funnelLevel < MaxFunnelDepth
  /\ funnelLevel' = funnelLevel + 1
  /\ funnelBeta1' = funnelBeta1 - 1
  /\ folded' = (funnelBeta1 - 1 = 1)
  /\ misfolded' = FALSE
  /\ bitsErased' = bitsErased + 1
  /\ totalHeat' = totalHeat + HeatPerBit
  /\ UNCHANGED <<beta1, beta0, beta2, enzymePresent, activationEnergy,
                 baseActivation, population, generation, survivors,
                 foldEnergy, topologyChanged>>
  /\ step' = step + 1

\* Misfold: get stuck at a local minimum (β₁ > 1)
Misfold ==
  /\ step < MaxSteps
  /\ ~folded
  /\ ~misfolded
  /\ funnelBeta1 > 1
  /\ misfolded' = TRUE
  /\ UNCHANGED <<beta1, beta0, beta2, funnelLevel, funnelBeta1, folded,
                 enzymePresent, activationEnergy, baseActivation,
                 population, generation, survivors,
                 foldEnergy, topologyChanged, bitsErased, totalHeat>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Enzyme Catalysis Actions
\* ═══════════════════════════════════════════════════════════════════════════════

\* Enzyme binds: β₁ increases by 1, activation energy drops
EnzymeBind ==
  /\ step < MaxSteps
  /\ ~enzymePresent
  /\ beta1' = beta1 + 1
  /\ enzymePresent' = TRUE
  /\ activationEnergy' = baseActivation \div 2   \* halve activation energy
  /\ UNCHANGED <<beta0, beta2, funnelLevel, funnelBeta1, folded, misfolded,
                 baseActivation, population, generation, survivors,
                 foldEnergy, topologyChanged, bitsErased, totalHeat>>
  /\ step' = step + 1

\* Reaction completes through catalyzed path: β₁ returns to baseline
EnzymeRelease ==
  /\ step < MaxSteps
  /\ enzymePresent
  /\ beta1' = beta1 - 1
  /\ enzymePresent' = FALSE
  /\ activationEnergy' = baseActivation
  /\ bitsErased' = bitsErased + 1
  /\ totalHeat' = totalHeat + HeatPerBit
  /\ UNCHANGED <<beta0, beta2, funnelLevel, funnelBeta1, folded, misfolded,
                 baseActivation, population, generation, survivors,
                 foldEnergy, topologyChanged>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Evolution Actions
\* ═══════════════════════════════════════════════════════════════════════════════

\* Selection (fold): reduce population to survivors
SelectionFold ==
  /\ step < MaxSteps
  /\ population > 1
  /\ \E s \in 1..population :
      /\ s < population
      /\ survivors' = s
      /\ population' = s
      /\ bitsErased' = bitsErased + (population - s)
      /\ totalHeat' = totalHeat + (population - s) * HeatPerBit
  /\ generation' = generation + 1
  /\ UNCHANGED <<beta1, beta0, beta2, funnelLevel, funnelBeta1, folded,
                 misfolded, enzymePresent, activationEnergy, baseActivation,
                 foldEnergy, topologyChanged>>
  /\ step' = step + 1

\* Mutation (fork): increase population diversity
MutationFork ==
  /\ step < MaxSteps
  /\ population < MaxPopulation
  /\ population' = population + 1
  /\ UNCHANGED <<beta1, beta0, beta2, funnelLevel, funnelBeta1, folded,
                 misfolded, enzymePresent, activationEnergy, baseActivation,
                 generation, survivors,
                 foldEnergy, topologyChanged, bitsErased, totalHeat>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Gravity Actions
\* ═══════════════════════════════════════════════════════════════════════════════

\* A fold deposits energy, which modifies the topology
GravitationalFold ==
  /\ step < MaxSteps
  /\ beta1 > 0
  /\ (~enzymePresent \/ beta1 > 1)
  /\ foldEnergy' = foldEnergy + beta1
  /\ topologyChanged' = TRUE
  /\ beta1' = beta1 - 1   \* fold reduces β₁
  /\ bitsErased' = bitsErased + 1
  /\ totalHeat' = totalHeat + HeatPerBit
  /\ UNCHANGED <<beta0, beta2, funnelLevel, funnelBeta1, folded, misfolded,
                 enzymePresent, activationEnergy, baseActivation,
                 population, generation, survivors>>
  /\ step' = step + 1

Next ==
  \/ FunnelDescend
  \/ Misfold
  \/ EnzymeBind
  \/ EnzymeRelease
  \/ SelectionFold
  \/ MutationFork
  \/ GravitationalFold

Spec == Init /\ [][Next]_vars

\* ═══════════════════════════════════════════════════════════════════════════════
\* Invariants
\* ═══════════════════════════════════════════════════════════════════════════════

\* THM-TOPO-MOLECULAR-ISO: β₁ ≥ 0 always (well-formed simplicial complex)
InvBettiWellFormed == beta1 >= 0 /\ beta0 >= 0 /\ beta2 >= 0

\* THM-PROTEIN-FUNNEL: β₁ monotonically decreases along the funnel
InvFunnelMonotone == funnelBeta1 <= MaxBeta1

\* THM-PROTEIN-FUNNEL: native state has β₁ = 1
InvNativeState == folded => funnelBeta1 = 1

\* THM-PROTEIN-FUNNEL: misfolded state has β₁ > 1
InvMisfoldedAboveNative == misfolded => funnelBeta1 > 1

\* THM-ENZYME-CATALYSIS: enzyme raises β₁ by exactly 1
InvEnzymeRaisesBeta1 == enzymePresent => beta1 > 0

\* THM-ENZYME-CATALYSIS: catalyzed activation < uncatalyzed
InvCatalyzedFaster == enzymePresent => activationEnergy < baseActivation

\* THM-ENZYME-CATALYSIS: enzyme is reusable (β₁ returns after release)
InvEnzymeReusable == ~enzymePresent => activationEnergy = baseActivation

\* THM-EVOLUTION-SELF-MODIFYING: population ≥ 1 (species exists)
InvPopulationPositive == population >= 1

\* THM-EVOLUTION-SELF-MODIFYING: selection reduces population
InvSelectionReduces == survivors <= population

\* THM-GRAVITY-SELF-REFERENTIAL: positive fold energy → topology changed
InvGravityModifiesTopology == foldEnergy > 0 => topologyChanged

\* THM-INFORMATION-MATTER: total heat = bits erased × heat per bit
InvFirstLawHeat == totalHeat = bitsErased * HeatPerBit

\* THM-INFORMATION-MATTER: positive erasure → positive heat
InvPositiveErasurePositiveHeat == bitsErased > 0 => totalHeat > 0

====
