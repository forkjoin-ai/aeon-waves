--------------------------- MODULE HeteroMoAFabricLowering ---------------------------
EXTENDS Naturals

CONSTANTS CpuLanes, GpuLanes, NpuLanes, WasmLanes

VARIABLES checked, primaryCount, shadowCount, activeLayers, mirroredKernels, laminarHeight

vars == <<checked, primaryCount, shadowCount, activeLayers, mirroredKernels, laminarHeight>>

ASSUME CpuLanes >= 0
ASSUME GpuLanes >= 0
ASSUME NpuLanes >= 0
ASSUME WasmLanes >= 0
ASSUME CpuLanes + GpuLanes + NpuLanes + WasmLanes > 0

TotalLanes ==
  CpuLanes + GpuLanes + NpuLanes + WasmLanes

ActiveLayerCount ==
  (IF CpuLanes > 0 THEN 1 ELSE 0) +
  (IF GpuLanes > 0 THEN 1 ELSE 0) +
  (IF NpuLanes > 0 THEN 1 ELSE 0) +
  (IF WasmLanes > 0 THEN 1 ELSE 0)

MirroredKernelCount ==
  2 * TotalLanes

MetaLaminarHeight ==
  ActiveLayerCount + 1

Init ==
  /\ checked = FALSE
  /\ primaryCount = 0
  /\ shadowCount = 0
  /\ activeLayers = 0
  /\ mirroredKernels = 0
  /\ laminarHeight = 0

CheckLowering ==
  /\ ~checked
  /\ checked' = TRUE
  /\ primaryCount' = TotalLanes
  /\ shadowCount' = TotalLanes
  /\ activeLayers' = ActiveLayerCount
  /\ mirroredKernels' = MirroredKernelCount
  /\ laminarHeight' = MetaLaminarHeight

Stutter ==
  UNCHANGED vars

Next ==
  CheckLowering \/ Stutter

Spec ==
  Init /\ [][Next]_vars /\ WF_vars(CheckLowering)

InvLoweringBalanced ==
  checked => primaryCount = shadowCount

InvMirroredKernelCount ==
  checked => mirroredKernels = primaryCount + shadowCount

InvMetaRaceWidth ==
  checked => activeLayers = ActiveLayerCount

InvLaminarLayerCount ==
  checked => laminarHeight = activeLayers + 1

=============================================================================
