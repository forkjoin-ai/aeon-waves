import Gnosis.TreeShapes
import Gnosis.GeoShapes
import Gnosis.ImpossibleFireworkShapes

namespace Gnosis

/-!
# Scene shape layers

This module provides a finite bridge for composing procedural scene layers from
the existing nature catalogs.  It does not merge catalogs into one undifferentiated
type; each layer keeps its source morphology while sharing an explicit scene
role and Phyle-carried procedural context.
-/

/-- High-level role of a procedural shape in a 3D scene. -/
inductive SceneLayerRole where
  | terrain
  | vegetation
  | skyDisplay
deriving DecidableEq, Repr

/-- Source catalog preserved by a scene layer. -/
inductive SceneShapeSource where
  | botanical
  | geologic
  | impossibleFirework
deriving DecidableEq, Repr

/-- A layer references one source catalog and one representative shape label. -/
structure SceneShapeLayer where
  role : SceneLayerRole
  source : SceneShapeSource
  representativeIndex : Nat
  phyleCarried : Bool
deriving DecidableEq, Repr

def terrainLayer : SceneShapeLayer :=
  { role := SceneLayerRole.terrain
    source := SceneShapeSource.geologic
    representativeIndex := 0
    phyleCarried := true }

def vegetationLayer : SceneShapeLayer :=
  { role := SceneLayerRole.vegetation
    source := SceneShapeSource.botanical
    representativeIndex := 0
    phyleCarried := true }

def skyDisplayLayer : SceneShapeLayer :=
  { role := SceneLayerRole.skyDisplay
    source := SceneShapeSource.impossibleFirework
    representativeIndex := 0
    phyleCarried := true }

def defaultNatureSceneStack : List SceneShapeLayer :=
  [terrainLayer, vegetationLayer, skyDisplayLayer]

def defaultNatureSceneRoles : List SceneLayerRole :=
  defaultNatureSceneStack.map SceneShapeLayer.role

def defaultNatureSceneSources : List SceneShapeSource :=
  defaultNatureSceneStack.map SceneShapeLayer.source

def defaultNatureSceneCarrierFlags : List Bool :=
  defaultNatureSceneStack.map SceneShapeLayer.phyleCarried

def defaultNatureSceneStackCertified : Prop :=
  defaultNatureSceneRoles =
      [SceneLayerRole.terrain, SceneLayerRole.vegetation,
        SceneLayerRole.skyDisplay] /\
    defaultNatureSceneSources =
      [SceneShapeSource.geologic, SceneShapeSource.botanical,
        SceneShapeSource.impossibleFirework] /\
    defaultNatureSceneCarrierFlags = [true, true, true]

theorem default_nature_scene_stack_certified :
    defaultNatureSceneStackCertified := by
  simp [defaultNatureSceneStackCertified,
    defaultNatureSceneRoles, defaultNatureSceneSources,
    defaultNatureSceneCarrierFlags, defaultNatureSceneStack,
    terrainLayer, vegetationLayer, skyDisplayLayer]

theorem default_nature_scene_stack_cardinality :
    defaultNatureSceneStack.length = 3 := by
  simp [defaultNatureSceneStack]

end Gnosis
