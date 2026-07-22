namespace Gnosis

/-!
# Geologic and map-scale procedural shapes

This module records finite shape labels for rocks, gems, landmasses, mountain
ranges, plateaus, and other map-scale forms.  The catalog is intended as a
machine-checkable morphology surface for procedural 3D scene generation: each
entry shares the Phyle carrier, but remains distinct by scale, form, and
formation constraint.
-/

/-- Shared carrier for abstract geologic and cartographic scene forms. -/
inductive GeoCarrier where
  | phyle
deriving DecidableEq, Repr

/-- Broad scale or material class for geologic procedural shapes. -/
inductive GeoMajor where
  | rock
  | gem
  | landmass
  | mountainSystem
  | hydrologic
  | erosional
  | volcanic
deriving DecidableEq, Repr

/-- Finite labels for rocks, gems, terrain, and map-scale morphology. -/
inductive GeoShape where
  | boulder
  | screeField
  | sedimentLayer
  | quartzPrism
  | diamondOctahedron
  | geode
  | continent
  | island
  | peninsula
  | isthmus
  | mountainRange
  | ridge
  | volcano
  | plateau
  | basin
  | valley
  | canyon
  | delta
  | coastline
  | fjord
  | archipelago
deriving DecidableEq, Repr

/-- Visual morphology used by the procedural scene generator. -/
inductive GeoMorphology where
  | roundedMass
  | angularScatter
  | stratifiedSheet
  | facetedColumn
  | facetedOctahedron
  | hollowCrystalPocket
  | continentalPlate
  | isolatedLand
  | projectingLand
  | narrowBridge
  | foldedChain
  | linearCrest
  | conicVent
  | raisedTable
  | depressedBowl
  | branchingValley
  | incisedChasm
  | distributaryFan
  | fractalBoundary
  | glacialInlet
  | islandCluster
deriving DecidableEq, Repr

/-- Formation constraint explaining why the form is recurrent. -/
inductive GeoConstraint where
  | weathering
  | gravitySorting
  | sedimentDeposition
  | directionalCrystalGrowth
  | latticePacking
  | cavityMineralization
  | plateTectonics
  | seaLevelIsolation
  | coastalErosion
  | compressiveUplift
  | volcanicAccumulation
  | differentialErosion
  | subsidence
  | fluvialIncision
  | distributarySedimentation
  | boundaryErosion
  | glacialCarving
deriving DecidableEq, Repr

/-- One Phyle-carried geologic or map-scale procedural form. -/
structure GeoShapeSpec where
  carrier : GeoCarrier
  major : GeoMajor
  shape : GeoShape
  morphology : GeoMorphology
  constraint : GeoConstraint
deriving DecidableEq, Repr

def boulderShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.rock
    shape := GeoShape.boulder
    morphology := GeoMorphology.roundedMass
    constraint := GeoConstraint.weathering }

def screeFieldShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.rock
    shape := GeoShape.screeField
    morphology := GeoMorphology.angularScatter
    constraint := GeoConstraint.gravitySorting }

def sedimentLayerShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.rock
    shape := GeoShape.sedimentLayer
    morphology := GeoMorphology.stratifiedSheet
    constraint := GeoConstraint.sedimentDeposition }

def quartzPrismShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.gem
    shape := GeoShape.quartzPrism
    morphology := GeoMorphology.facetedColumn
    constraint := GeoConstraint.directionalCrystalGrowth }

def diamondOctahedronShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.gem
    shape := GeoShape.diamondOctahedron
    morphology := GeoMorphology.facetedOctahedron
    constraint := GeoConstraint.latticePacking }

def geodeShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.gem
    shape := GeoShape.geode
    morphology := GeoMorphology.hollowCrystalPocket
    constraint := GeoConstraint.cavityMineralization }

def continentShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.landmass
    shape := GeoShape.continent
    morphology := GeoMorphology.continentalPlate
    constraint := GeoConstraint.plateTectonics }

def islandShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.landmass
    shape := GeoShape.island
    morphology := GeoMorphology.isolatedLand
    constraint := GeoConstraint.seaLevelIsolation }

def peninsulaShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.landmass
    shape := GeoShape.peninsula
    morphology := GeoMorphology.projectingLand
    constraint := GeoConstraint.coastalErosion }

def isthmusShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.landmass
    shape := GeoShape.isthmus
    morphology := GeoMorphology.narrowBridge
    constraint := GeoConstraint.coastalErosion }

def mountainRangeShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.mountainSystem
    shape := GeoShape.mountainRange
    morphology := GeoMorphology.foldedChain
    constraint := GeoConstraint.compressiveUplift }

def ridgeShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.mountainSystem
    shape := GeoShape.ridge
    morphology := GeoMorphology.linearCrest
    constraint := GeoConstraint.differentialErosion }

def volcanoShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.volcanic
    shape := GeoShape.volcano
    morphology := GeoMorphology.conicVent
    constraint := GeoConstraint.volcanicAccumulation }

def plateauShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.mountainSystem
    shape := GeoShape.plateau
    morphology := GeoMorphology.raisedTable
    constraint := GeoConstraint.differentialErosion }

def basinShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.hydrologic
    shape := GeoShape.basin
    morphology := GeoMorphology.depressedBowl
    constraint := GeoConstraint.subsidence }

def valleyShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.erosional
    shape := GeoShape.valley
    morphology := GeoMorphology.branchingValley
    constraint := GeoConstraint.fluvialIncision }

def canyonShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.erosional
    shape := GeoShape.canyon
    morphology := GeoMorphology.incisedChasm
    constraint := GeoConstraint.fluvialIncision }

def deltaShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.hydrologic
    shape := GeoShape.delta
    morphology := GeoMorphology.distributaryFan
    constraint := GeoConstraint.distributarySedimentation }

def coastlineShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.landmass
    shape := GeoShape.coastline
    morphology := GeoMorphology.fractalBoundary
    constraint := GeoConstraint.boundaryErosion }

def fjordShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.erosional
    shape := GeoShape.fjord
    morphology := GeoMorphology.glacialInlet
    constraint := GeoConstraint.glacialCarving }

def archipelagoShape : GeoShapeSpec :=
  { carrier := GeoCarrier.phyle
    major := GeoMajor.landmass
    shape := GeoShape.archipelago
    morphology := GeoMorphology.islandCluster
    constraint := GeoConstraint.seaLevelIsolation }

/-- Finite geologic and cartographic procedural-shape catalog. -/
def geoShapeCatalog : List GeoShapeSpec :=
  [ boulderShape
  , screeFieldShape
  , sedimentLayerShape
  , quartzPrismShape
  , diamondOctahedronShape
  , geodeShape
  , continentShape
  , islandShape
  , peninsulaShape
  , isthmusShape
  , mountainRangeShape
  , ridgeShape
  , volcanoShape
  , plateauShape
  , basinShape
  , valleyShape
  , canyonShape
  , deltaShape
  , coastlineShape
  , fjordShape
  , archipelagoShape
  ]

def geoShapeTrace : List GeoShape :=
  geoShapeCatalog.map GeoShapeSpec.shape

def geoMajorTrace : List GeoMajor :=
  geoShapeCatalog.map GeoShapeSpec.major

def geoMorphologyTrace : List GeoMorphology :=
  geoShapeCatalog.map GeoShapeSpec.morphology

def geoConstraintTrace : List GeoConstraint :=
  geoShapeCatalog.map GeoShapeSpec.constraint

def geoCarrierTrace : List GeoCarrier :=
  geoShapeCatalog.map GeoShapeSpec.carrier

def expectedGeoShapeTrace : List GeoShape :=
  [ GeoShape.boulder
  , GeoShape.screeField
  , GeoShape.sedimentLayer
  , GeoShape.quartzPrism
  , GeoShape.diamondOctahedron
  , GeoShape.geode
  , GeoShape.continent
  , GeoShape.island
  , GeoShape.peninsula
  , GeoShape.isthmus
  , GeoShape.mountainRange
  , GeoShape.ridge
  , GeoShape.volcano
  , GeoShape.plateau
  , GeoShape.basin
  , GeoShape.valley
  , GeoShape.canyon
  , GeoShape.delta
  , GeoShape.coastline
  , GeoShape.fjord
  , GeoShape.archipelago
  ]

def expectedGeoMorphologyTrace : List GeoMorphology :=
  [ GeoMorphology.roundedMass
  , GeoMorphology.angularScatter
  , GeoMorphology.stratifiedSheet
  , GeoMorphology.facetedColumn
  , GeoMorphology.facetedOctahedron
  , GeoMorphology.hollowCrystalPocket
  , GeoMorphology.continentalPlate
  , GeoMorphology.isolatedLand
  , GeoMorphology.projectingLand
  , GeoMorphology.narrowBridge
  , GeoMorphology.foldedChain
  , GeoMorphology.linearCrest
  , GeoMorphology.conicVent
  , GeoMorphology.raisedTable
  , GeoMorphology.depressedBowl
  , GeoMorphology.branchingValley
  , GeoMorphology.incisedChasm
  , GeoMorphology.distributaryFan
  , GeoMorphology.fractalBoundary
  , GeoMorphology.glacialInlet
  , GeoMorphology.islandCluster
  ]

/-- Catalog certificate for procedural scene generation metadata. -/
def geoCatalogCertified : Prop :=
  geoShapeTrace = expectedGeoShapeTrace /\
    geoMorphologyTrace = expectedGeoMorphologyTrace /\
    geoCarrierTrace = List.replicate 21 GeoCarrier.phyle

theorem geo_catalog_certified :
    geoCatalogCertified := by
  simp [geoCatalogCertified,
    geoShapeTrace, geoMorphologyTrace, geoCarrierTrace,
    geoShapeCatalog, expectedGeoShapeTrace, expectedGeoMorphologyTrace,
    boulderShape, screeFieldShape, sedimentLayerShape,
    quartzPrismShape, diamondOctahedronShape, geodeShape,
    continentShape, islandShape, peninsulaShape, isthmusShape,
    mountainRangeShape, ridgeShape, volcanoShape, plateauShape,
    basinShape, valleyShape, canyonShape, deltaShape,
    coastlineShape, fjordShape, archipelagoShape]

theorem geo_catalog_cardinality :
    geoShapeCatalog.length = 21 := by
  simp [geoShapeCatalog]

theorem rock_and_gem_distinct_but_phyle_carried :
    boulderShape.major = GeoMajor.rock /\
      quartzPrismShape.major = GeoMajor.gem /\
      boulderShape.carrier = quartzPrismShape.carrier := by
  simp [boulderShape, quartzPrismShape]

theorem mountain_range_and_plateau_distinct_system_forms :
    mountainRangeShape.shape ≠ plateauShape.shape /\
      mountainRangeShape.major = plateauShape.major := by
  simp [mountainRangeShape, plateauShape]

theorem map_scale_landmass_family_examples :
    continentShape.major = GeoMajor.landmass /\
      islandShape.major = GeoMajor.landmass /\
      coastlineShape.major = GeoMajor.landmass /\
      archipelagoShape.major = GeoMajor.landmass := by
  simp [continentShape, islandShape, coastlineShape, archipelagoShape]

end Gnosis
