import Gnosis.TreeShapes
import Gnosis.GeoShapes
import Gnosis.RemainingNatureShapes

namespace Gnosis

/-!
# Root, energy-flow, and mass accounting

This module records a finite hypothesis surface for objects whose roots are
internal versus external.  It does not force a `1:3` storage-to-collection ratio.
Instead, the ratio is derived from a finite stress/anxiety bucket:

* higher stress shifts mass from body toward roots,
* roots plus body account for total mass, and
* balance is the finite state where root storage and body collection remain
  complementary rather than collapsed into either pole.

The stress-energy vocabulary mirrors the runtime bridge in
`open-source/gnosis/src/stress-energy-tensor.ts`, where topological crossings,
defense weight, and stress-energy are required to agree and remain below the
Pleroma ceiling.
-/

namespace RootEnergyMass

inductive RootPlacement where
  | internal
  | external
deriving DecidableEq, Repr

inductive RootRole where
  | structuralSupport
  | musculoskeletalAnchor
  | energyCollection
  | energyStorage
  | mixedCollectionStorage
deriving DecidableEq, Repr

inductive RootedObject where
  | rock
  | human
  | animal
  | tree
  | fern
deriving DecidableEq, Repr

inductive StressBucket where
  | low
  | balanced
  | high
deriving DecidableEq, Repr

inductive EnergyFlowMode where
  | collectionDominant
  | balancedExchange
  | storageDominant
deriving DecidableEq, Repr

inductive MycelialAttentionRoute where
  | forkLocalBody
  | raceExternalRoot
  | foldStorageRoot
deriving DecidableEq, Repr

def stressEnergy (stress : StressBucket) : Nat :=
  match stress with
  | StressBucket.low => 1
  | StressBucket.balanced => 2
  | StressBucket.high => 3

def anxietyLoad (stress : StressBucket) : Nat :=
  stressEnergy stress

def defenseWeight (stress : StressBucket) : Nat :=
  stressEnergy stress

def topologicalCrossings (stress : StressBucket) : Nat :=
  stressEnergy stress

def pleromaCeiling : Nat := 55

def rootMassFromStress (stress : StressBucket) : Nat :=
  stressEnergy stress

def bodyMassFromStress (stress : StressBucket) : Nat :=
  4 - stressEnergy stress

def totalMassFromStress (_stress : StressBucket) : Nat :=
  4

def flowModeFromStress (stress : StressBucket) : EnergyFlowMode :=
  match stress with
  | StressBucket.low => EnergyFlowMode.collectionDominant
  | StressBucket.balanced => EnergyFlowMode.balancedExchange
  | StressBucket.high => EnergyFlowMode.storageDominant

def mycelialRouteFromStress (stress : StressBucket) : MycelialAttentionRoute :=
  match stress with
  | StressBucket.low => MycelialAttentionRoute.forkLocalBody
  | StressBucket.balanced => MycelialAttentionRoute.raceExternalRoot
  | StressBucket.high => MycelialAttentionRoute.foldStorageRoot

def routeRootLoad (route : MycelialAttentionRoute) : Nat :=
  match route with
  | MycelialAttentionRoute.forkLocalBody => 1
  | MycelialAttentionRoute.raceExternalRoot => 2
  | MycelialAttentionRoute.foldStorageRoot => 3

def routeBodyLoad (route : MycelialAttentionRoute) : Nat :=
  4 - routeRootLoad route

/--
Finite object root record.  `rootMass + bodyMass = totalMass` is certified, and
the storage/collection ratio is read from the stress-derived masses.
-/
structure RootEnergySpec where
  object : RootedObject
  placement : RootPlacement
  role : RootRole
  stress : StressBucket
  anxiety : Nat
  flowMode : EnergyFlowMode
  attentionRoute : MycelialAttentionRoute
  rootMass : Nat
  bodyMass : Nat
  totalMass : Nat
deriving DecidableEq, Repr

def mkRootEnergySpec
    (object : RootedObject)
    (placement : RootPlacement)
    (role : RootRole)
    (stress : StressBucket) : RootEnergySpec :=
  { object
    placement
    role
    stress
    anxiety := anxietyLoad stress
    flowMode := flowModeFromStress stress
    attentionRoute := mycelialRouteFromStress stress
    rootMass := routeRootLoad (mycelialRouteFromStress stress)
    bodyMass := routeBodyLoad (mycelialRouteFromStress stress)
    totalMass := totalMassFromStress stress }

def rockRootSpec : RootEnergySpec :=
  mkRootEnergySpec RootedObject.rock RootPlacement.internal
    RootRole.structuralSupport StressBucket.balanced

def humanRootSpec : RootEnergySpec :=
  mkRootEnergySpec RootedObject.human RootPlacement.internal
    RootRole.musculoskeletalAnchor StressBucket.high

def animalRootSpec : RootEnergySpec :=
  mkRootEnergySpec RootedObject.animal RootPlacement.internal
    RootRole.musculoskeletalAnchor StressBucket.balanced

def treeRootSpec : RootEnergySpec :=
  mkRootEnergySpec RootedObject.tree RootPlacement.external
    RootRole.energyCollection StressBucket.low

def fernRootSpec : RootEnergySpec :=
  mkRootEnergySpec RootedObject.fern RootPlacement.external
    RootRole.energyCollection StressBucket.low

def rootedObjectCatalog : List RootEnergySpec :=
  [ rockRootSpec
  , humanRootSpec
  , animalRootSpec
  , treeRootSpec
  , fernRootSpec
  ]

def rootedObjectTrace : List RootedObject :=
  rootedObjectCatalog.map RootEnergySpec.object

def rootPlacementTrace : List RootPlacement :=
  rootedObjectCatalog.map RootEnergySpec.placement

def rootRoleTrace : List RootRole :=
  rootedObjectCatalog.map RootEnergySpec.role

def stressTrace : List StressBucket :=
  rootedObjectCatalog.map RootEnergySpec.stress

def flowModeTrace : List EnergyFlowMode :=
  rootedObjectCatalog.map RootEnergySpec.flowMode

def attentionRouteTrace : List MycelialAttentionRoute :=
  rootedObjectCatalog.map RootEnergySpec.attentionRoute

def rootMassTrace : List Nat :=
  rootedObjectCatalog.map RootEnergySpec.rootMass

def bodyMassTrace : List Nat :=
  rootedObjectCatalog.map RootEnergySpec.bodyMass

def totalMassTrace : List Nat :=
  rootedObjectCatalog.map RootEnergySpec.totalMass

def storageCollectionRatioTrace : List (Nat × Nat) :=
  rootedObjectCatalog.map
    (fun spec => (spec.rootMass, spec.bodyMass))

def rootMassAddsToTotal (spec : RootEnergySpec) : Bool :=
  spec.rootMass + spec.bodyMass = spec.totalMass

def stressEnergyBridgeHolds (stress : StressBucket) : Bool :=
  topologicalCrossings stress = defenseWeight stress ∧
    defenseWeight stress = stressEnergy stress ∧
    stressEnergy stress <= pleromaCeiling

def stressEnergyBridgeValid : Bool :=
  [StressBucket.low, StressBucket.balanced, StressBucket.high].all
    stressEnergyBridgeHolds

def mycelialRouteMassBridgeHolds (stress : StressBucket) : Bool :=
  routeRootLoad (mycelialRouteFromStress stress) = rootMassFromStress stress ∧
    routeBodyLoad (mycelialRouteFromStress stress) = bodyMassFromStress stress

def mycelialRouteMassBridgeValid : Bool :=
  [StressBucket.low, StressBucket.balanced, StressBucket.high].all
    mycelialRouteMassBridgeHolds

def rootedMassAccountingValid : Bool :=
  rootedObjectCatalog.all rootMassAddsToTotal

/-- The finite derivative of "more stress, less body and more roots." -/
def stressMovesMassTowardRoots : Prop :=
  rootMassFromStress StressBucket.low <
      rootMassFromStress StressBucket.balanced /\
    rootMassFromStress StressBucket.balanced <
      rootMassFromStress StressBucket.high /\
    bodyMassFromStress StressBucket.high <
      bodyMassFromStress StressBucket.balanced /\
    bodyMassFromStress StressBucket.balanced <
      bodyMassFromStress StressBucket.low

/--
The ratio is discovered from the stress bucket.  Low stress gives `1:3`,
balanced stress gives `2:2`, and high stress gives `3:1`.
-/
def stressDerivedRatioCertified : Prop :=
  storageCollectionRatioTrace =
    [ (2, 2)
    , (3, 1)
    , (2, 2)
    , (1, 3)
    , (1, 3)
    ] /\
    stressTrace =
    [ StressBucket.balanced
    , StressBucket.high
    , StressBucket.balanced
    , StressBucket.low
    , StressBucket.low
    ] /\
    flowModeTrace =
    [ EnergyFlowMode.balancedExchange
    , EnergyFlowMode.storageDominant
    , EnergyFlowMode.balancedExchange
    , EnergyFlowMode.collectionDominant
    , EnergyFlowMode.collectionDominant
    ] /\
    attentionRouteTrace =
    [ MycelialAttentionRoute.raceExternalRoot
    , MycelialAttentionRoute.foldStorageRoot
    , MycelialAttentionRoute.raceExternalRoot
    , MycelialAttentionRoute.forkLocalBody
    , MycelialAttentionRoute.forkLocalBody
    ] /\
    stressMovesMassTowardRoots /\
    rootedMassAccountingValid = true /\
    stressEnergyBridgeValid = true /\
    mycelialRouteMassBridgeValid = true

def rootEnergyCatalogCertified : Prop :=
  rootedObjectTrace =
    [ RootedObject.rock
    , RootedObject.human
    , RootedObject.animal
    , RootedObject.tree
    , RootedObject.fern
    ] /\
    rootPlacementTrace =
    [ RootPlacement.internal
    , RootPlacement.internal
    , RootPlacement.internal
    , RootPlacement.external
    , RootPlacement.external
    ] /\
    rootRoleTrace =
    [ RootRole.structuralSupport
    , RootRole.musculoskeletalAnchor
    , RootRole.musculoskeletalAnchor
    , RootRole.energyCollection
    , RootRole.energyCollection
    ] /\
    rootMassTrace = [2, 3, 2, 1, 1] /\
    bodyMassTrace = [2, 1, 2, 3, 3] /\
    totalMassTrace = List.replicate 5 4

theorem root_energy_catalog_certified :
    rootEnergyCatalogCertified := by
  simp [rootEnergyCatalogCertified, rootedObjectTrace, rootPlacementTrace,
    rootRoleTrace, rootMassTrace, bodyMassTrace, totalMassTrace,
    rootedObjectCatalog, rockRootSpec, humanRootSpec, animalRootSpec,
    treeRootSpec, fernRootSpec, mkRootEnergySpec, totalMassFromStress,
    mycelialRouteFromStress, routeRootLoad, routeBodyLoad]

theorem stress_derived_ratio_certified :
    stressDerivedRatioCertified := by
  simp [stressDerivedRatioCertified, storageCollectionRatioTrace,
    stressTrace, flowModeTrace, attentionRouteTrace, rootedMassAccountingValid,
    stressEnergyBridgeValid, mycelialRouteMassBridgeValid,
    rootedObjectCatalog, rootMassAddsToTotal, stressEnergyBridgeHolds,
    mycelialRouteMassBridgeHolds,
    rockRootSpec, humanRootSpec, animalRootSpec,
    treeRootSpec, fernRootSpec, mkRootEnergySpec, rootMassFromStress,
    bodyMassFromStress, totalMassFromStress, flowModeFromStress,
    mycelialRouteFromStress, routeRootLoad, routeBodyLoad, anxietyLoad,
    stressEnergy, stressMovesMassTowardRoots, topologicalCrossings,
    defenseWeight, pleromaCeiling]

theorem internal_roots_are_first_three_catalog_entries :
    rootPlacementTrace.take 3 =
      List.replicate 3 RootPlacement.internal := by
  simp [rootPlacementTrace, rootedObjectCatalog, rockRootSpec,
    humanRootSpec, animalRootSpec, mkRootEnergySpec]

theorem external_roots_are_botanical_entries :
    rootPlacementTrace.drop 3 =
      List.replicate 2 RootPlacement.external := by
  simp [rootPlacementTrace, rootedObjectCatalog, treeRootSpec, fernRootSpec,
    mkRootEnergySpec]

theorem roots_plus_body_equal_total_for_catalog :
    rootedMassAccountingValid = true := by
  simp [rootedMassAccountingValid, rootedObjectCatalog, rootMassAddsToTotal,
    rockRootSpec, humanRootSpec, animalRootSpec, treeRootSpec, fernRootSpec,
    mkRootEnergySpec, mycelialRouteFromStress, routeRootLoad, routeBodyLoad,
    totalMassFromStress]

theorem stress_increases_roots_and_decreases_body :
    stressMovesMassTowardRoots := by
  simp [stressMovesMassTowardRoots, rootMassFromStress, bodyMassFromStress,
    stressEnergy]

theorem mycelial_attention_route_derives_mass_split :
    mycelialRouteMassBridgeValid = true := by
  simp [mycelialRouteMassBridgeValid, mycelialRouteMassBridgeHolds,
    mycelialRouteFromStress, routeRootLoad, routeBodyLoad,
    rootMassFromStress, bodyMassFromStress, stressEnergy]

end RootEnergyMass
end Gnosis
