namespace Gnosis

/-!
# Impossible firework shapes

This module records a finite, proof-checkable catalog of abstract firework
shape carriers.  The catalog uses `PhyleCarrier` as the universal display
carrier and tags natural form families by the constraint that makes the form
legible: growth, surface energy, tiling, tension, lattice packing, flow,
drag, or biological symmetry.

The entries are intentionally non-operational.  They describe display topology
and visual constraints, not pyrotechnic mixtures, construction methods, or
physical realizability.
-/

/-- Major natural-form groups used by the impossible-firework catalog. -/
inductive NatureShapeMajor where
  | growthBranching
  | physicalThermodynamic
  | crystallineMineral
  | fluidMotion
  | biologicalCellular
deriving DecidableEq, Repr

/-- Natural shape labels available to the abstract display solver. -/
inductive NatureShape where
  | fractal
  | logarithmicSpiral
  | dendritic
  | sphere
  | hexagon
  | catenary
  | octahedron
  | prism
  | dodecahedron
  | vortex
  | undulation
  | streamline
  | radialSymmetry
  | bilateralSymmetry
  | torus
deriving DecidableEq, Repr

/-- Constraint labels explain why a natural form is stable or recurrent. -/
inductive ShapeConstraint where
  | surfaceAreaTransport
  | selfSimilarGrowth
  | distributionEnergy
  | minimumSurfaceEnergy
  | perimeterTilingEfficiency
  | tensionEquilibrium
  | latticePacking
  | directionalBondGrowth
  | symmetricDeposition
  | angularMomentumDissipation
  | substrateWaveCoupling
  | dragReduction
  | radialEnvironmentalAccess
  | mirroredLocomotion
  | closedCirculation
deriving DecidableEq, Repr

/-- Abstract Phyle carrier used as the common display support. -/
inductive PhyleCarrier where
  | universalShape
deriving DecidableEq, Repr

/-- Impossible display status: topological display only, no physical recipe. -/
inductive DisplayStatus where
  | abstractOnly
  | impossibleComposite
deriving DecidableEq, Repr

/-- A natural shape with its major class and constraint witness. -/
structure NatureShapeSpec where
  major : NatureShapeMajor
  shape : NatureShape
  constraint : ShapeConstraint
deriving DecidableEq, Repr

/-- A firework display shape carried by Phyle. -/
structure ImpossibleFireworkShape where
  carrier : PhyleCarrier
  spec : NatureShapeSpec
  status : DisplayStatus
deriving DecidableEq, Repr

def fractalSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.growthBranching
    shape := NatureShape.fractal
    constraint := ShapeConstraint.surfaceAreaTransport }

def spiralSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.growthBranching
    shape := NatureShape.logarithmicSpiral
    constraint := ShapeConstraint.selfSimilarGrowth }

def dendriticSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.growthBranching
    shape := NatureShape.dendritic
    constraint := ShapeConstraint.distributionEnergy }

def sphereSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.physicalThermodynamic
    shape := NatureShape.sphere
    constraint := ShapeConstraint.minimumSurfaceEnergy }

def hexagonSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.physicalThermodynamic
    shape := NatureShape.hexagon
    constraint := ShapeConstraint.perimeterTilingEfficiency }

def catenarySpec : NatureShapeSpec :=
  { major := NatureShapeMajor.physicalThermodynamic
    shape := NatureShape.catenary
    constraint := ShapeConstraint.tensionEquilibrium }

def octahedronSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.crystallineMineral
    shape := NatureShape.octahedron
    constraint := ShapeConstraint.latticePacking }

def prismSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.crystallineMineral
    shape := NatureShape.prism
    constraint := ShapeConstraint.directionalBondGrowth }

def dodecahedronSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.crystallineMineral
    shape := NatureShape.dodecahedron
    constraint := ShapeConstraint.symmetricDeposition }

def vortexSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.fluidMotion
    shape := NatureShape.vortex
    constraint := ShapeConstraint.angularMomentumDissipation }

def undulationSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.fluidMotion
    shape := NatureShape.undulation
    constraint := ShapeConstraint.substrateWaveCoupling }

def streamlineSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.fluidMotion
    shape := NatureShape.streamline
    constraint := ShapeConstraint.dragReduction }

def radialSymmetrySpec : NatureShapeSpec :=
  { major := NatureShapeMajor.biologicalCellular
    shape := NatureShape.radialSymmetry
    constraint := ShapeConstraint.radialEnvironmentalAccess }

def bilateralSymmetrySpec : NatureShapeSpec :=
  { major := NatureShapeMajor.biologicalCellular
    shape := NatureShape.bilateralSymmetry
    constraint := ShapeConstraint.mirroredLocomotion }

def torusSpec : NatureShapeSpec :=
  { major := NatureShapeMajor.biologicalCellular
    shape := NatureShape.torus
    constraint := ShapeConstraint.closedCirculation }

/-- Lift a natural shape spec into the Phyle-carried impossible display catalog. -/
def phyleImpossibleShape (spec : NatureShapeSpec) : ImpossibleFireworkShape :=
  { carrier := PhyleCarrier.universalShape
    spec
    status := DisplayStatus.impossibleComposite }

/-- The finite catalog covers all listed major natural shape examples. -/
def impossibleFireworkShapeCatalog : List ImpossibleFireworkShape :=
  [ phyleImpossibleShape fractalSpec
  , phyleImpossibleShape spiralSpec
  , phyleImpossibleShape dendriticSpec
  , phyleImpossibleShape sphereSpec
  , phyleImpossibleShape hexagonSpec
  , phyleImpossibleShape catenarySpec
  , phyleImpossibleShape octahedronSpec
  , phyleImpossibleShape prismSpec
  , phyleImpossibleShape dodecahedronSpec
  , phyleImpossibleShape vortexSpec
  , phyleImpossibleShape undulationSpec
  , phyleImpossibleShape streamlineSpec
  , phyleImpossibleShape radialSymmetrySpec
  , phyleImpossibleShape bilateralSymmetrySpec
  , phyleImpossibleShape torusSpec
  ]

def impossibleFireworkMajorTrace : List NatureShapeMajor :=
  impossibleFireworkShapeCatalog.map (fun row => row.spec.major)

def impossibleFireworkShapeTrace : List NatureShape :=
  impossibleFireworkShapeCatalog.map (fun row => row.spec.shape)

def impossibleFireworkConstraintTrace : List ShapeConstraint :=
  impossibleFireworkShapeCatalog.map (fun row => row.spec.constraint)

def impossibleFireworkCarrierTrace : List PhyleCarrier :=
  impossibleFireworkShapeCatalog.map ImpossibleFireworkShape.carrier

def impossibleFireworkStatusTrace : List DisplayStatus :=
  impossibleFireworkShapeCatalog.map ImpossibleFireworkShape.status

/-- Expected major trace with each major group represented by three examples. -/
def expectedImpossibleFireworkMajorTrace : List NatureShapeMajor :=
  [ NatureShapeMajor.growthBranching
  , NatureShapeMajor.growthBranching
  , NatureShapeMajor.growthBranching
  , NatureShapeMajor.physicalThermodynamic
  , NatureShapeMajor.physicalThermodynamic
  , NatureShapeMajor.physicalThermodynamic
  , NatureShapeMajor.crystallineMineral
  , NatureShapeMajor.crystallineMineral
  , NatureShapeMajor.crystallineMineral
  , NatureShapeMajor.fluidMotion
  , NatureShapeMajor.fluidMotion
  , NatureShapeMajor.fluidMotion
  , NatureShapeMajor.biologicalCellular
  , NatureShapeMajor.biologicalCellular
  , NatureShapeMajor.biologicalCellular
  ]

/-- Exact shape trace for the first impossible-firework catalog. -/
def expectedImpossibleFireworkShapeTrace : List NatureShape :=
  [ NatureShape.fractal
  , NatureShape.logarithmicSpiral
  , NatureShape.dendritic
  , NatureShape.sphere
  , NatureShape.hexagon
  , NatureShape.catenary
  , NatureShape.octahedron
  , NatureShape.prism
  , NatureShape.dodecahedron
  , NatureShape.vortex
  , NatureShape.undulation
  , NatureShape.streamline
  , NatureShape.radialSymmetry
  , NatureShape.bilateralSymmetry
  , NatureShape.torus
  ]

/-- Exact natural-constraint trace for the first impossible-firework catalog. -/
def expectedImpossibleFireworkConstraintTrace : List ShapeConstraint :=
  [ ShapeConstraint.surfaceAreaTransport
  , ShapeConstraint.selfSimilarGrowth
  , ShapeConstraint.distributionEnergy
  , ShapeConstraint.minimumSurfaceEnergy
  , ShapeConstraint.perimeterTilingEfficiency
  , ShapeConstraint.tensionEquilibrium
  , ShapeConstraint.latticePacking
  , ShapeConstraint.directionalBondGrowth
  , ShapeConstraint.symmetricDeposition
  , ShapeConstraint.angularMomentumDissipation
  , ShapeConstraint.substrateWaveCoupling
  , ShapeConstraint.dragReduction
  , ShapeConstraint.radialEnvironmentalAccess
  , ShapeConstraint.mirroredLocomotion
  , ShapeConstraint.closedCirculation
  ]

/-- Catalog certificate tying shapes, constraints, carrier, and display status together. -/
def impossibleFireworkCatalogCertified : Prop :=
  impossibleFireworkMajorTrace = expectedImpossibleFireworkMajorTrace /\
    impossibleFireworkShapeTrace = expectedImpossibleFireworkShapeTrace /\
    impossibleFireworkConstraintTrace = expectedImpossibleFireworkConstraintTrace /\
    impossibleFireworkCarrierTrace =
      List.replicate 15 PhyleCarrier.universalShape /\
    impossibleFireworkStatusTrace =
      List.replicate 15 DisplayStatus.impossibleComposite

theorem impossible_firework_catalog_certified :
    impossibleFireworkCatalogCertified := by
  simp [impossibleFireworkCatalogCertified,
    impossibleFireworkMajorTrace,
    impossibleFireworkShapeTrace,
    impossibleFireworkConstraintTrace,
    impossibleFireworkCarrierTrace,
    impossibleFireworkStatusTrace,
    impossibleFireworkShapeCatalog,
    expectedImpossibleFireworkMajorTrace,
    expectedImpossibleFireworkShapeTrace,
    expectedImpossibleFireworkConstraintTrace,
    phyleImpossibleShape,
    fractalSpec, spiralSpec, dendriticSpec,
    sphereSpec, hexagonSpec, catenarySpec,
    octahedronSpec, prismSpec, dodecahedronSpec,
    vortexSpec, undulationSpec, streamlineSpec,
    radialSymmetrySpec, bilateralSymmetrySpec, torusSpec]

theorem impossible_firework_catalog_cardinality :
    impossibleFireworkShapeCatalog.length = 15 := by
  simp [impossibleFireworkShapeCatalog]

theorem impossible_firework_catalog_phyle_carried :
    impossibleFireworkCarrierTrace =
      List.replicate 15 PhyleCarrier.universalShape := by
  simp [impossibleFireworkCarrierTrace, impossibleFireworkShapeCatalog,
    phyleImpossibleShape]

theorem impossible_firework_catalog_non_operational :
    impossibleFireworkStatusTrace =
      List.replicate 15 DisplayStatus.impossibleComposite := by
  simp [impossibleFireworkStatusTrace, impossibleFireworkShapeCatalog,
    phyleImpossibleShape]

end Gnosis
