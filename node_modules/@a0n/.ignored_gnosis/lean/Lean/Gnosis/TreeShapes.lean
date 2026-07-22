namespace Gnosis

/-!
# Tree shape variants

This module specializes the Phyle-carried impossible-firework shape language for
major tree architectures and a fern form.  The entries are finite morphology
labels: they distinguish recognizable branching habits while preserving the
shared growth/branching carrier that makes them similar.
-/

/-- Shared carrier for abstract botanical display shapes. -/
inductive BotanicalCarrier where
  | phyle
deriving DecidableEq, Repr

/-- Broad botanical class. -/
inductive BotanicalMajor where
  | tree
  | fern
deriving DecidableEq, Repr

/-- Major tree and fern forms represented by the catalog. -/
inductive BotanicalShape where
  | oak
  | pine
  | maple
  | willow
  | birch
  | cedar
  | cypress
  | palm
  | baobab
  | redwood
  | spruce
  | fir
  | elm
  | aspen
  | fern
deriving DecidableEq, Repr

/-- Branch habit is the visible structure that makes related forms distinct. -/
inductive BranchHabit where
  | broadCrown
  | conicalWhorled
  | palmateCanopy
  | pendulousCurtain
  | fineColumnar
  | layeredFan
  | verticalSpire
  | radialCrown
  | swollenTrunkCrown
  | giantColumn
  | denseConical
  | softConical
  | vaseCrown
  | tremblingColumn
  | frondRecursion
deriving DecidableEq, Repr

/-- Shared growth constraints for botanical display morphologies. -/
inductive BotanicalConstraint where
  | lightCapture
  | waterTransport
  | windLoad
  | selfSimilarFrondGrowth
deriving DecidableEq, Repr

/-- One Phyle-carried botanical display form. -/
structure BotanicalShapeSpec where
  carrier : BotanicalCarrier
  major : BotanicalMajor
  shape : BotanicalShape
  habit : BranchHabit
  primaryConstraint : BotanicalConstraint
deriving DecidableEq, Repr

def oakShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.oak
    habit := BranchHabit.broadCrown
    primaryConstraint := BotanicalConstraint.lightCapture }

def pineShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.pine
    habit := BranchHabit.conicalWhorled
    primaryConstraint := BotanicalConstraint.windLoad }

def mapleShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.maple
    habit := BranchHabit.palmateCanopy
    primaryConstraint := BotanicalConstraint.lightCapture }

def willowShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.willow
    habit := BranchHabit.pendulousCurtain
    primaryConstraint := BotanicalConstraint.waterTransport }

def birchShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.birch
    habit := BranchHabit.fineColumnar
    primaryConstraint := BotanicalConstraint.lightCapture }

def cedarShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.cedar
    habit := BranchHabit.layeredFan
    primaryConstraint := BotanicalConstraint.windLoad }

def cypressShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.cypress
    habit := BranchHabit.verticalSpire
    primaryConstraint := BotanicalConstraint.windLoad }

def palmShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.palm
    habit := BranchHabit.radialCrown
    primaryConstraint := BotanicalConstraint.lightCapture }

def baobabShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.baobab
    habit := BranchHabit.swollenTrunkCrown
    primaryConstraint := BotanicalConstraint.waterTransport }

def redwoodShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.redwood
    habit := BranchHabit.giantColumn
    primaryConstraint := BotanicalConstraint.waterTransport }

def spruceShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.spruce
    habit := BranchHabit.denseConical
    primaryConstraint := BotanicalConstraint.windLoad }

def firShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.fir
    habit := BranchHabit.softConical
    primaryConstraint := BotanicalConstraint.windLoad }

def elmShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.elm
    habit := BranchHabit.vaseCrown
    primaryConstraint := BotanicalConstraint.lightCapture }

def aspenShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.tree
    shape := BotanicalShape.aspen
    habit := BranchHabit.tremblingColumn
    primaryConstraint := BotanicalConstraint.lightCapture }

def fernShape : BotanicalShapeSpec :=
  { carrier := BotanicalCarrier.phyle
    major := BotanicalMajor.fern
    shape := BotanicalShape.fern
    habit := BranchHabit.frondRecursion
    primaryConstraint := BotanicalConstraint.selfSimilarFrondGrowth }

/-- Finite catalog of distinct but related botanical display forms. -/
def botanicalShapeCatalog : List BotanicalShapeSpec :=
  [ oakShape
  , pineShape
  , mapleShape
  , willowShape
  , birchShape
  , cedarShape
  , cypressShape
  , palmShape
  , baobabShape
  , redwoodShape
  , spruceShape
  , firShape
  , elmShape
  , aspenShape
  , fernShape
  ]

def botanicalShapeTrace : List BotanicalShape :=
  botanicalShapeCatalog.map BotanicalShapeSpec.shape

def botanicalMajorTrace : List BotanicalMajor :=
  botanicalShapeCatalog.map BotanicalShapeSpec.major

def botanicalCarrierTrace : List BotanicalCarrier :=
  botanicalShapeCatalog.map BotanicalShapeSpec.carrier

def botanicalHabitTrace : List BranchHabit :=
  botanicalShapeCatalog.map BotanicalShapeSpec.habit

def expectedBotanicalShapeTrace : List BotanicalShape :=
  [ BotanicalShape.oak
  , BotanicalShape.pine
  , BotanicalShape.maple
  , BotanicalShape.willow
  , BotanicalShape.birch
  , BotanicalShape.cedar
  , BotanicalShape.cypress
  , BotanicalShape.palm
  , BotanicalShape.baobab
  , BotanicalShape.redwood
  , BotanicalShape.spruce
  , BotanicalShape.fir
  , BotanicalShape.elm
  , BotanicalShape.aspen
  , BotanicalShape.fern
  ]

def expectedBotanicalHabitTrace : List BranchHabit :=
  [ BranchHabit.broadCrown
  , BranchHabit.conicalWhorled
  , BranchHabit.palmateCanopy
  , BranchHabit.pendulousCurtain
  , BranchHabit.fineColumnar
  , BranchHabit.layeredFan
  , BranchHabit.verticalSpire
  , BranchHabit.radialCrown
  , BranchHabit.swollenTrunkCrown
  , BranchHabit.giantColumn
  , BranchHabit.denseConical
  , BranchHabit.softConical
  , BranchHabit.vaseCrown
  , BranchHabit.tremblingColumn
  , BranchHabit.frondRecursion
  ]

/-- All entries share Phyle while retaining distinct botanical shape labels. -/
def botanicalCatalogCertified : Prop :=
  botanicalShapeTrace = expectedBotanicalShapeTrace /\
    botanicalHabitTrace = expectedBotanicalHabitTrace /\
    botanicalCarrierTrace = List.replicate 15 BotanicalCarrier.phyle /\
    botanicalMajorTrace =
      List.replicate 14 BotanicalMajor.tree ++ [BotanicalMajor.fern]

theorem botanical_catalog_certified :
    botanicalCatalogCertified := by
  simp [botanicalCatalogCertified,
    botanicalShapeTrace, botanicalHabitTrace,
    botanicalCarrierTrace, botanicalMajorTrace,
    botanicalShapeCatalog,
    expectedBotanicalShapeTrace, expectedBotanicalHabitTrace,
    oakShape, pineShape, mapleShape, willowShape, birchShape,
    cedarShape, cypressShape, palmShape, baobabShape, redwoodShape,
    spruceShape, firShape, elmShape, aspenShape, fernShape]

theorem botanical_catalog_cardinality :
    botanicalShapeCatalog.length = 15 := by
  simp [botanicalShapeCatalog]

theorem oak_and_pine_distinct_but_phyle_carried :
    oakShape.shape ≠ pineShape.shape /\
      oakShape.carrier = pineShape.carrier := by
  simp [oakShape, pineShape]

theorem tree_forms_similar_by_major :
    oakShape.major = BotanicalMajor.tree /\
      pineShape.major = BotanicalMajor.tree /\
      mapleShape.major = BotanicalMajor.tree /\
      willowShape.major = BotanicalMajor.tree := by
  simp [oakShape, pineShape, mapleShape, willowShape]

theorem fern_distinct_from_tree_major :
    fernShape.major = BotanicalMajor.fern /\
      fernShape.major ≠ oakShape.major := by
  simp [fernShape, oakShape]

end Gnosis
