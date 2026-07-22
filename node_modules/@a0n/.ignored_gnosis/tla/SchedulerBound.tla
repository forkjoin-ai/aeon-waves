------------------------------ MODULE SchedulerBound ------------------------------
EXTENDS Naturals

\* Conditional runtime claim formalization:
\* Under finite topology execution, bounded frame metadata and constant-time
\* scheduler primitives, scheduler overhead is additive, bounded, and
\* independent of handler runtime.

CONSTANTS MaxScheduleSteps, MaxMetadataBytes, SchedStepCost, MetaByteCost, HandlerCostDomain

VARIABLES scheduleSteps, metadataBytes, handlerCost

vars == <<scheduleSteps, metadataBytes, handlerCost>>

SchedulerRuntime(steps, metaBytes, h) ==
  (steps * SchedStepCost) + (metaBytes * MetaByteCost)

SchedulerBound ==
  (MaxScheduleSteps * SchedStepCost) + (MaxMetadataBytes * MetaByteCost)

TotalRuntime ==
  SchedulerRuntime(scheduleSteps, metadataBytes, handlerCost) + handlerCost

Init ==
  /\ scheduleSteps \in 0..MaxScheduleSteps
  /\ metadataBytes \in 0..MaxMetadataBytes
  /\ handlerCost \in HandlerCostDomain
  /\ SchedStepCost \in Nat
  /\ MetaByteCost \in Nat
  /\ MaxScheduleSteps \in Nat
  /\ MaxMetadataBytes \in Nat

Change ==
  /\ scheduleSteps' \in 0..MaxScheduleSteps
  /\ metadataBytes' \in 0..MaxMetadataBytes
  /\ handlerCost' \in HandlerCostDomain

Stutter == UNCHANGED vars

Next == Change \/ Stutter
Spec == Init /\ [][Next]_vars

InvFiniteTopologyExecution ==
  scheduleSteps \in 0..MaxScheduleSteps

InvBoundedFrameMetadata ==
  metadataBytes \in 0..MaxMetadataBytes

InvAdditiveRuntimeDecomposition ==
  TotalRuntime = SchedulerRuntime(scheduleSteps, metadataBytes, handlerCost) + handlerCost

InvSchedulerOverheadBounded ==
  SchedulerRuntime(scheduleSteps, metadataBytes, handlerCost) <= SchedulerBound

InvSchedulerOverheadIndependentOfHandler ==
  \A h1 \in HandlerCostDomain :
    \A h2 \in HandlerCostDomain :
      SchedulerRuntime(scheduleSteps, metadataBytes, h1) =
      SchedulerRuntime(scheduleSteps, metadataBytes, h2)

InvConditionalHandlerDominance ==
  (\A h \in HandlerCostDomain : h >= SchedulerBound)
    =>
  (handlerCost >= SchedulerRuntime(scheduleSteps, metadataBytes, handlerCost))

InvSchedulerBoundClaim ==
  /\ InvFiniteTopologyExecution
  /\ InvBoundedFrameMetadata
  /\ InvAdditiveRuntimeDecomposition
  /\ InvSchedulerOverheadBounded
  /\ InvSchedulerOverheadIndependentOfHandler

=============================================================================
