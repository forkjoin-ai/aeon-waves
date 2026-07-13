namespace Gnosis

/-!
# Manmade procedural shapes

This module records finite built-form morphology for procedural 3D scenes.  It
starts from major human-made structures: buildings, bridges, roads, towers,
domes, arches, grids, machines, walls, vessels, and settlement layouts.  Each
entry is Phyle-carried but distinct by built-form class, morphology, and
engineering constraint.
-/

/-- Shared carrier for human-built procedural forms. -/
inductive ManmadeCarrier where
  | phyle
deriving DecidableEq, Repr

/-- Broad category of built form. -/
inductive ManmadeMajor where
  | architecture
  | bridge
  | transport
  | civicGrid
  | monument
  | industrial
  | vessel
  | defensive
  | settlement
deriving DecidableEq, Repr

/-- Finite labels for common manmade procedural shapes. -/
inductive ManmadeShape where
  | hut
  | house
  | tower
  | skyscraper
  | dome
  | arch
  | vault
  | pyramid
  | bridgeBeam
  | suspensionBridge
  | trussBridge
  | road
  | railLine
  | tunnel
  | cityGrid
  | plaza
  | wall
  | aqueduct
  | factory
  | crane
  | shipHull
  | aircraftWing
  | fortress
  | villageCluster
  | suburbBlock
deriving DecidableEq, Repr

/-- Procedural morphology used by scene generation. -/
inductive ManmadeMorphology where
  | simpleEnclosure
  | pitchedRoofVolume
  | verticalStack
  | repeatedFloorColumn
  | shellCap
  | compressionCurve
  | extrudedArchShell
  | slopedMonolith
  | straightSpan
  | cableSagSpan
  | triangulatedSpan
  | linearPath
  | parallelTrack
  | buriedTube
  | orthogonalParcelGrid
  | openCivicVoid
  | linearBarrier
  | repeatedArcade
  | shedArray
  | rotatingLatticeArm
  | displacementHull
  | liftSurface
  | fortifiedPerimeter
  | clusteredCells
  | repeatedResidentialCells
deriving DecidableEq, Repr

/-- Constraint that explains the built-form morphology. -/
inductive ManmadeConstraint where
  | shelter
  | loadBearing
  | verticalDensity
  | pressureShell
  | compressionTransfer
  | spanning
  | tensileSupport
  | triangulation
  | directedMovement
  | gradeSeparation
  | parcelSubdivision
  | civicGathering
  | boundaryControl
  | waterTransport
  | productionFlow
  | mechanicalReach
  | buoyancy
  | aerodynamicLift
  | defense
  | socialClustering
deriving DecidableEq, Repr

structure ManmadeShapeSpec where
  carrier : ManmadeCarrier
  major : ManmadeMajor
  shape : ManmadeShape
  morphology : ManmadeMorphology
  constraint : ManmadeConstraint
deriving DecidableEq, Repr

def hutShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.architecture,
    shape := ManmadeShape.hut, morphology := ManmadeMorphology.simpleEnclosure,
    constraint := ManmadeConstraint.shelter }

def houseShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.architecture,
    shape := ManmadeShape.house, morphology := ManmadeMorphology.pitchedRoofVolume,
    constraint := ManmadeConstraint.shelter }

def towerShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.architecture,
    shape := ManmadeShape.tower, morphology := ManmadeMorphology.verticalStack,
    constraint := ManmadeConstraint.loadBearing }

def skyscraperShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.architecture,
    shape := ManmadeShape.skyscraper, morphology := ManmadeMorphology.repeatedFloorColumn,
    constraint := ManmadeConstraint.verticalDensity }

def domeShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.monument,
    shape := ManmadeShape.dome, morphology := ManmadeMorphology.shellCap,
    constraint := ManmadeConstraint.pressureShell }

def archShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.monument,
    shape := ManmadeShape.arch, morphology := ManmadeMorphology.compressionCurve,
    constraint := ManmadeConstraint.compressionTransfer }

def vaultShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.architecture,
    shape := ManmadeShape.vault, morphology := ManmadeMorphology.extrudedArchShell,
    constraint := ManmadeConstraint.compressionTransfer }

def pyramidShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.monument,
    shape := ManmadeShape.pyramid, morphology := ManmadeMorphology.slopedMonolith,
    constraint := ManmadeConstraint.loadBearing }

def bridgeBeamShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.bridge,
    shape := ManmadeShape.bridgeBeam, morphology := ManmadeMorphology.straightSpan,
    constraint := ManmadeConstraint.spanning }

def suspensionBridgeShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.bridge,
    shape := ManmadeShape.suspensionBridge, morphology := ManmadeMorphology.cableSagSpan,
    constraint := ManmadeConstraint.tensileSupport }

def trussBridgeShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.bridge,
    shape := ManmadeShape.trussBridge, morphology := ManmadeMorphology.triangulatedSpan,
    constraint := ManmadeConstraint.triangulation }

def roadShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.transport,
    shape := ManmadeShape.road, morphology := ManmadeMorphology.linearPath,
    constraint := ManmadeConstraint.directedMovement }

def railLineShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.transport,
    shape := ManmadeShape.railLine, morphology := ManmadeMorphology.parallelTrack,
    constraint := ManmadeConstraint.directedMovement }

def tunnelShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.transport,
    shape := ManmadeShape.tunnel, morphology := ManmadeMorphology.buriedTube,
    constraint := ManmadeConstraint.gradeSeparation }

def cityGridShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.civicGrid,
    shape := ManmadeShape.cityGrid, morphology := ManmadeMorphology.orthogonalParcelGrid,
    constraint := ManmadeConstraint.parcelSubdivision }

def plazaShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.civicGrid,
    shape := ManmadeShape.plaza, morphology := ManmadeMorphology.openCivicVoid,
    constraint := ManmadeConstraint.civicGathering }

def wallShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.defensive,
    shape := ManmadeShape.wall, morphology := ManmadeMorphology.linearBarrier,
    constraint := ManmadeConstraint.boundaryControl }

def aqueductShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.transport,
    shape := ManmadeShape.aqueduct, morphology := ManmadeMorphology.repeatedArcade,
    constraint := ManmadeConstraint.waterTransport }

def factoryShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.industrial,
    shape := ManmadeShape.factory, morphology := ManmadeMorphology.shedArray,
    constraint := ManmadeConstraint.productionFlow }

def craneShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.industrial,
    shape := ManmadeShape.crane, morphology := ManmadeMorphology.rotatingLatticeArm,
    constraint := ManmadeConstraint.mechanicalReach }

def shipHullShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.vessel,
    shape := ManmadeShape.shipHull, morphology := ManmadeMorphology.displacementHull,
    constraint := ManmadeConstraint.buoyancy }

def aircraftWingShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.vessel,
    shape := ManmadeShape.aircraftWing, morphology := ManmadeMorphology.liftSurface,
    constraint := ManmadeConstraint.aerodynamicLift }

def fortressShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.defensive,
    shape := ManmadeShape.fortress, morphology := ManmadeMorphology.fortifiedPerimeter,
    constraint := ManmadeConstraint.defense }

def villageClusterShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.settlement,
    shape := ManmadeShape.villageCluster, morphology := ManmadeMorphology.clusteredCells,
    constraint := ManmadeConstraint.socialClustering }

def suburbBlockShape : ManmadeShapeSpec :=
  { carrier := ManmadeCarrier.phyle, major := ManmadeMajor.settlement,
    shape := ManmadeShape.suburbBlock, morphology := ManmadeMorphology.repeatedResidentialCells,
    constraint := ManmadeConstraint.parcelSubdivision }

def manmadeShapeCatalog : List ManmadeShapeSpec :=
  [ hutShape, houseShape, towerShape, skyscraperShape, domeShape,
    archShape, vaultShape, pyramidShape, bridgeBeamShape,
    suspensionBridgeShape, trussBridgeShape, roadShape, railLineShape,
    tunnelShape, cityGridShape, plazaShape, wallShape, aqueductShape,
    factoryShape, craneShape, shipHullShape, aircraftWingShape,
    fortressShape, villageClusterShape, suburbBlockShape ]

def manmadeShapeTrace : List ManmadeShape :=
  manmadeShapeCatalog.map ManmadeShapeSpec.shape

def manmadeCarrierTrace : List ManmadeCarrier :=
  manmadeShapeCatalog.map ManmadeShapeSpec.carrier

def manmadeCatalogCertified : Prop :=
  manmadeShapeTrace =
    [ ManmadeShape.hut, ManmadeShape.house, ManmadeShape.tower,
      ManmadeShape.skyscraper, ManmadeShape.dome, ManmadeShape.arch,
      ManmadeShape.vault, ManmadeShape.pyramid, ManmadeShape.bridgeBeam,
      ManmadeShape.suspensionBridge, ManmadeShape.trussBridge,
      ManmadeShape.road, ManmadeShape.railLine, ManmadeShape.tunnel,
      ManmadeShape.cityGrid, ManmadeShape.plaza, ManmadeShape.wall,
      ManmadeShape.aqueduct, ManmadeShape.factory, ManmadeShape.crane,
      ManmadeShape.shipHull, ManmadeShape.aircraftWing,
      ManmadeShape.fortress, ManmadeShape.villageCluster,
      ManmadeShape.suburbBlock ] /\
    manmadeCarrierTrace = List.replicate 25 ManmadeCarrier.phyle

theorem manmade_catalog_certified :
    manmadeCatalogCertified := by
  simp [manmadeCatalogCertified,
    manmadeShapeTrace, manmadeCarrierTrace, manmadeShapeCatalog,
    hutShape, houseShape, towerShape, skyscraperShape, domeShape,
    archShape, vaultShape, pyramidShape, bridgeBeamShape,
    suspensionBridgeShape, trussBridgeShape, roadShape, railLineShape,
    tunnelShape, cityGridShape, plazaShape, wallShape, aqueductShape,
    factoryShape, craneShape, shipHullShape, aircraftWingShape,
    fortressShape, villageClusterShape, suburbBlockShape]

theorem manmade_catalog_cardinality :
    manmadeShapeCatalog.length = 25 := by
  simp [manmadeShapeCatalog]

theorem bridge_forms_distinct_but_same_major :
    bridgeBeamShape.shape ≠ suspensionBridgeShape.shape /\
      suspensionBridgeShape.shape ≠ trussBridgeShape.shape /\
      bridgeBeamShape.major = trussBridgeShape.major := by
  simp [bridgeBeamShape, suspensionBridgeShape, trussBridgeShape]

theorem transport_forms_share_directed_movement_family :
    roadShape.major = ManmadeMajor.transport /\
      railLineShape.major = ManmadeMajor.transport /\
      tunnelShape.major = ManmadeMajor.transport := by
  simp [roadShape, railLineShape, tunnelShape]

end Gnosis
