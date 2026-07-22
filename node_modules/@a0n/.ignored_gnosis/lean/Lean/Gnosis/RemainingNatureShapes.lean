namespace Gnosis

/-!
# Remaining nature shapes

This module fills the main natural-form gaps left after the tree, geologic, and
impossible-firework catalogs.  It covers atmospheric, oceanic, aeolian, ice,
reef/shell, animal, collective-motion, and cellular/tissue forms for procedural
3D scene generation.
-/

/-- Shared carrier for non-tree, non-geologic natural scene forms. -/
inductive RemainingNatureCarrier where
  | phyle
deriving DecidableEq, Repr

/-- Major natural systems still needed before moving to manmade structures. -/
inductive RemainingNatureMajor where
  | atmospheric
  | oceanic
  | aeolian
  | cryospheric
  | reefShell
  | animalBody
  | collectiveMotion
  | cellularTissue
deriving DecidableEq, Repr

/-- Remaining finite natural shape labels. -/
inductive RemainingNatureShape where
  | cumulusCloud
  | anvilCloud
  | cyclone
  | lightningBranch
  | waveCrest
  | whirlpool
  | coralReef
  | sandDune
  | rippleField
  | snowflake
  | glacier
  | iceCrystal
  | shellSpiral
  | spiderWeb
  | birdWing
  | fishBody
  | insectBody
  | flock
  | swarm
  | murmuration
  | honeycombCells
  | leafVenation
  | foamCells
deriving DecidableEq, Repr

/-- Procedural morphology label for scene generation. -/
inductive RemainingNatureMorphology where
  | billowedVolume
  | flattenedAnvil
  | rotatingStormDisk
  | branchingDischarge
  | sinusoidalCrest
  | rotatingFunnel
  | porousBranchingMass
  | migratingRidge
  | repeatedRipple
  | hexagonalRadialCrystal
  | flowingIceTongue
  | facetedIceNeedle
  | logarithmicShell
  | radialTensionNet
  | aerofoilSpan
  | fusiformBody
  | segmentedBody
  | alignedGroup
  | particleSwarm
  | coherentTurningCloud
  | hexagonalCellTiling
  | branchingVeinGraph
  | packedBubbleFoam
deriving DecidableEq, Repr

/-- Constraint explaining why each remaining natural form is recurrent. -/
inductive RemainingNatureConstraint where
  | convection
  | shearOutflow
  | rotatingPressureGradient
  | ionizedPathFinding
  | fluidOscillation
  | angularMomentum
  | biologicalAccretion
  | windTransport
  | boundaryLayerInstability
  | crystalSymmetry
  | gravityDrivenIceFlow
  | anisotropicFreezing
  | accretiveGrowth
  | tensionOptimization
  | liftGeneration
  | dragReduction
  | modularSegmentation
  | localAlignment
  | attractionRepulsion
  | neighborCoupledTurning
  | perimeterEfficiency
  | nutrientTransport
  | surfaceTensionPacking
deriving DecidableEq, Repr

structure RemainingNatureShapeSpec where
  carrier : RemainingNatureCarrier
  major : RemainingNatureMajor
  shape : RemainingNatureShape
  morphology : RemainingNatureMorphology
  constraint : RemainingNatureConstraint
deriving DecidableEq, Repr

def cumulusCloudShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.atmospheric,
    shape := RemainingNatureShape.cumulusCloud, morphology := RemainingNatureMorphology.billowedVolume,
    constraint := RemainingNatureConstraint.convection }

def anvilCloudShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.atmospheric,
    shape := RemainingNatureShape.anvilCloud, morphology := RemainingNatureMorphology.flattenedAnvil,
    constraint := RemainingNatureConstraint.shearOutflow }

def cycloneShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.atmospheric,
    shape := RemainingNatureShape.cyclone, morphology := RemainingNatureMorphology.rotatingStormDisk,
    constraint := RemainingNatureConstraint.rotatingPressureGradient }

def lightningBranchShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.atmospheric,
    shape := RemainingNatureShape.lightningBranch, morphology := RemainingNatureMorphology.branchingDischarge,
    constraint := RemainingNatureConstraint.ionizedPathFinding }

def waveCrestShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.oceanic,
    shape := RemainingNatureShape.waveCrest, morphology := RemainingNatureMorphology.sinusoidalCrest,
    constraint := RemainingNatureConstraint.fluidOscillation }

def whirlpoolShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.oceanic,
    shape := RemainingNatureShape.whirlpool, morphology := RemainingNatureMorphology.rotatingFunnel,
    constraint := RemainingNatureConstraint.angularMomentum }

def coralReefShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.reefShell,
    shape := RemainingNatureShape.coralReef, morphology := RemainingNatureMorphology.porousBranchingMass,
    constraint := RemainingNatureConstraint.biologicalAccretion }

def sandDuneShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.aeolian,
    shape := RemainingNatureShape.sandDune, morphology := RemainingNatureMorphology.migratingRidge,
    constraint := RemainingNatureConstraint.windTransport }

def rippleFieldShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.aeolian,
    shape := RemainingNatureShape.rippleField, morphology := RemainingNatureMorphology.repeatedRipple,
    constraint := RemainingNatureConstraint.boundaryLayerInstability }

def snowflakeShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.cryospheric,
    shape := RemainingNatureShape.snowflake, morphology := RemainingNatureMorphology.hexagonalRadialCrystal,
    constraint := RemainingNatureConstraint.crystalSymmetry }

def glacierShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.cryospheric,
    shape := RemainingNatureShape.glacier, morphology := RemainingNatureMorphology.flowingIceTongue,
    constraint := RemainingNatureConstraint.gravityDrivenIceFlow }

def iceCrystalShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.cryospheric,
    shape := RemainingNatureShape.iceCrystal, morphology := RemainingNatureMorphology.facetedIceNeedle,
    constraint := RemainingNatureConstraint.anisotropicFreezing }

def shellSpiralShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.reefShell,
    shape := RemainingNatureShape.shellSpiral, morphology := RemainingNatureMorphology.logarithmicShell,
    constraint := RemainingNatureConstraint.accretiveGrowth }

def spiderWebShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.animalBody,
    shape := RemainingNatureShape.spiderWeb, morphology := RemainingNatureMorphology.radialTensionNet,
    constraint := RemainingNatureConstraint.tensionOptimization }

def birdWingShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.animalBody,
    shape := RemainingNatureShape.birdWing, morphology := RemainingNatureMorphology.aerofoilSpan,
    constraint := RemainingNatureConstraint.liftGeneration }

def fishBodyShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.animalBody,
    shape := RemainingNatureShape.fishBody, morphology := RemainingNatureMorphology.fusiformBody,
    constraint := RemainingNatureConstraint.dragReduction }

def insectBodyShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.animalBody,
    shape := RemainingNatureShape.insectBody, morphology := RemainingNatureMorphology.segmentedBody,
    constraint := RemainingNatureConstraint.modularSegmentation }

def flockShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.collectiveMotion,
    shape := RemainingNatureShape.flock, morphology := RemainingNatureMorphology.alignedGroup,
    constraint := RemainingNatureConstraint.localAlignment }

def swarmShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.collectiveMotion,
    shape := RemainingNatureShape.swarm, morphology := RemainingNatureMorphology.particleSwarm,
    constraint := RemainingNatureConstraint.attractionRepulsion }

def murmurationShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.collectiveMotion,
    shape := RemainingNatureShape.murmuration, morphology := RemainingNatureMorphology.coherentTurningCloud,
    constraint := RemainingNatureConstraint.neighborCoupledTurning }

def honeycombCellsShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.cellularTissue,
    shape := RemainingNatureShape.honeycombCells, morphology := RemainingNatureMorphology.hexagonalCellTiling,
    constraint := RemainingNatureConstraint.perimeterEfficiency }

def leafVenationShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.cellularTissue,
    shape := RemainingNatureShape.leafVenation, morphology := RemainingNatureMorphology.branchingVeinGraph,
    constraint := RemainingNatureConstraint.nutrientTransport }

def foamCellsShape : RemainingNatureShapeSpec :=
  { carrier := RemainingNatureCarrier.phyle, major := RemainingNatureMajor.cellularTissue,
    shape := RemainingNatureShape.foamCells, morphology := RemainingNatureMorphology.packedBubbleFoam,
    constraint := RemainingNatureConstraint.surfaceTensionPacking }

def remainingNatureShapeCatalog : List RemainingNatureShapeSpec :=
  [ cumulusCloudShape, anvilCloudShape, cycloneShape, lightningBranchShape,
    waveCrestShape, whirlpoolShape, coralReefShape, sandDuneShape,
    rippleFieldShape, snowflakeShape, glacierShape, iceCrystalShape,
    shellSpiralShape, spiderWebShape, birdWingShape, fishBodyShape,
    insectBodyShape, flockShape, swarmShape, murmurationShape,
    honeycombCellsShape, leafVenationShape, foamCellsShape ]

def remainingNatureShapeTrace : List RemainingNatureShape :=
  remainingNatureShapeCatalog.map RemainingNatureShapeSpec.shape

def remainingNatureCarrierTrace : List RemainingNatureCarrier :=
  remainingNatureShapeCatalog.map RemainingNatureShapeSpec.carrier

def remainingNatureCatalogCertified : Prop :=
  remainingNatureShapeTrace =
    [ RemainingNatureShape.cumulusCloud, RemainingNatureShape.anvilCloud,
      RemainingNatureShape.cyclone, RemainingNatureShape.lightningBranch,
      RemainingNatureShape.waveCrest, RemainingNatureShape.whirlpool,
      RemainingNatureShape.coralReef, RemainingNatureShape.sandDune,
      RemainingNatureShape.rippleField, RemainingNatureShape.snowflake,
      RemainingNatureShape.glacier, RemainingNatureShape.iceCrystal,
      RemainingNatureShape.shellSpiral, RemainingNatureShape.spiderWeb,
      RemainingNatureShape.birdWing, RemainingNatureShape.fishBody,
      RemainingNatureShape.insectBody, RemainingNatureShape.flock,
      RemainingNatureShape.swarm, RemainingNatureShape.murmuration,
      RemainingNatureShape.honeycombCells, RemainingNatureShape.leafVenation,
      RemainingNatureShape.foamCells ] /\
    remainingNatureCarrierTrace =
      List.replicate 23 RemainingNatureCarrier.phyle

theorem remaining_nature_catalog_certified :
    remainingNatureCatalogCertified := by
  simp [remainingNatureCatalogCertified,
    remainingNatureShapeTrace, remainingNatureCarrierTrace,
    remainingNatureShapeCatalog,
    cumulusCloudShape, anvilCloudShape, cycloneShape, lightningBranchShape,
    waveCrestShape, whirlpoolShape, coralReefShape, sandDuneShape,
    rippleFieldShape, snowflakeShape, glacierShape, iceCrystalShape,
    shellSpiralShape, spiderWebShape, birdWingShape, fishBodyShape,
    insectBodyShape, flockShape, swarmShape, murmurationShape,
    honeycombCellsShape, leafVenationShape, foamCellsShape]

theorem remaining_nature_catalog_cardinality :
    remainingNatureShapeCatalog.length = 23 := by
  simp [remainingNatureShapeCatalog]

theorem atmospheric_forms_share_major :
    cumulusCloudShape.major = RemainingNatureMajor.atmospheric /\
      cycloneShape.major = RemainingNatureMajor.atmospheric /\
      lightningBranchShape.major = RemainingNatureMajor.atmospheric := by
  simp [cumulusCloudShape, cycloneShape, lightningBranchShape]

theorem collective_motion_forms_distinct :
    flockShape.shape ≠ swarmShape.shape /\
      swarmShape.shape ≠ murmurationShape.shape /\
      flockShape.major = murmurationShape.major := by
  simp [flockShape, swarmShape, murmurationShape]

end Gnosis
