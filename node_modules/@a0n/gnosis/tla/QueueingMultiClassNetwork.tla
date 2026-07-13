------------------------------ MODULE QueueingMultiClassNetwork ------------------------------
EXTENDS Naturals, Sequences, FiniteSets

\* Bounded multi-class open-network queueing model.
\* Classes carry different routes through the network, and scenario selection
\* ranges over finite service-law realizations. Node-local dispatch remains
\* nondeterministic but work-conserving, so TLC quantifies over all such
\* policies in the bounded model.

CONSTANTS ScenarioDomain

VARIABLES scenarioId, tick, stageIx, remaining, area, departedSojourn,
          lastActiveNodeCount, lastDispatchCount

vars ==
  <<scenarioId, tick, stageIx, remaining, area, departedSojourn,
    lastActiveNodeCount, lastDispatchCount>>

NoJob == 0
Nodes == {1, 2}

ArrivalSeq(id) ==
  IF id = 1 THEN <<0, 0, 1>>
  ELSE IF id = 2 THEN <<0, 0, 1>>
  ELSE <<1, 1, 3>>

ClassSeq(id) ==
  IF id = 1 THEN <<1, 2, 1>>
  ELSE IF id = 2 THEN <<1, 2, 1>>
  ELSE <<2, 1, 1>>

RouteForClass(c) ==
  IF c = 1 THEN <<1, 2>> ELSE <<2, 1>>

ServiceSeq(id, job) ==
  IF id = 1 /\ job = 1 THEN <<2, 1>>
  ELSE IF id = 1 /\ job = 2 THEN <<1, 1>>
  ELSE IF id = 1 /\ job = 3 THEN <<1, 1>>
  ELSE IF id = 2 /\ job = 1 THEN <<2, 1>>
  ELSE IF id = 2 /\ job = 2 THEN <<1, 2>>
  ELSE IF id = 2 /\ job = 3 THEN <<1, 1>>
  ELSE IF id = 3 /\ job = 1 THEN <<1, 1>>
  ELSE IF id = 3 /\ job = 2 THEN <<1, 2>>
  ELSE <<1, 1>>

ArrivalTicks == ArrivalSeq(scenarioId)
JobClasses == ClassSeq(scenarioId)
JobCount == Len(ArrivalTicks)
Jobs == 1..JobCount

RouteOf(job) == RouteForClass(JobClasses[job])
ServiceOf(job) == ServiceSeq(scenarioId, job)

RECURSIVE SeqSum(_)
SeqSum(seq) ==
  IF Len(seq) = 0 THEN 0 ELSE Head(seq) + SeqSum(Tail(seq))

DoneJob(job, stages) ==
  stages[job] > Len(RouteOf(job))

ActiveJobAtNode(t, stages, rem, job, node) ==
  /\ ArrivalTicks[job] <= t
  /\ ~DoneJob(job, stages)
  /\ RouteOf(job)[stages[job]] = node
  /\ rem[job] > 0

ActiveNodesAt(t, stages, rem) ==
  {node \in Nodes : \E job \in Jobs : ActiveJobAtNode(t, stages, rem, job, node)}

ActiveJobCountAt(t, stages) ==
  Cardinality({job \in Jobs : ArrivalTicks[job] <= t /\ ~DoneJob(job, stages)})

OpenAgeAt(t, stages) ==
  SeqSum([job \in Jobs |->
    IF ArrivalTicks[job] <= t /\ ~DoneJob(job, stages)
    THEN t - ArrivalTicks[job]
    ELSE 0
  ])

InitialRemaining(job) == ServiceOf(job)[1]
Done == \A job \in Jobs : DoneJob(job, stageIx)

Init ==
  /\ scenarioId \in ScenarioDomain
  /\ JobCount > 0
  /\ \A job \in Jobs :
       /\ ArrivalTicks[job] \in Nat
       /\ JobClasses[job] \in {1, 2}
       /\ Len(ServiceOf(job)) = Len(RouteOf(job))
       /\ \A k \in 1..Len(ServiceOf(job)) : ServiceOf(job)[k] \in Nat /\ ServiceOf(job)[k] > 0
  /\ tick = 0
  /\ stageIx = [job \in Jobs |-> 1]
  /\ remaining = [job \in Jobs |-> InitialRemaining(job)]
  /\ area = 0
  /\ departedSojourn = 0
  /\ lastActiveNodeCount = 0
  /\ lastDispatchCount = 0

IdleAdvance ==
  /\ ~Done
  /\ ActiveNodesAt(tick, stageIx, remaining) = {}
  /\ tick' = tick + 1
  /\ UNCHANGED <<scenarioId, stageIx, remaining, area, departedSojourn>>
  /\ lastActiveNodeCount' = 0
  /\ lastDispatchCount' = 0

Selected(sel, job) ==
  \E node \in Nodes : sel[node] = job

AdmissibleDispatch(sel) ==
  /\ sel \in [Nodes -> Jobs \cup {NoJob}]
  /\ \A node \in Nodes :
       IF \E job \in Jobs : ActiveJobAtNode(tick, stageIx, remaining, job, node)
       THEN /\ sel[node] \in Jobs
            /\ ActiveJobAtNode(tick, stageIx, remaining, sel[node], node)
       ELSE sel[node] = NoJob

ServeDispatch(sel) ==
  /\ ~Done
  /\ AdmissibleDispatch(sel)
  /\ tick' = tick + 1
  /\ stageIx' =
       [job \in Jobs |->
         IF Selected(sel, job) /\ remaining[job] = 1
         THEN stageIx[job] + 1
         ELSE stageIx[job]
       ]
  /\ remaining' =
       [job \in Jobs |->
         IF Selected(sel, job)
         THEN
           IF remaining[job] > 1
           THEN remaining[job] - 1
           ELSE IF stageIx[job] < Len(RouteOf(job))
                THEN ServiceOf(job)[stageIx[job] + 1]
                ELSE 0
         ELSE remaining[job]
       ]
  /\ area' = area + ActiveJobCountAt(tick, stageIx)
  /\ departedSojourn' =
       departedSojourn +
         SeqSum([job \in Jobs |->
           IF Selected(sel, job) /\ remaining[job] = 1 /\ stageIx[job] = Len(RouteOf(job))
           THEN (tick + 1) - ArrivalTicks[job]
           ELSE 0
         ])
  /\ UNCHANGED scenarioId
  /\ lastActiveNodeCount' = Cardinality(ActiveNodesAt(tick, stageIx, remaining))
  /\ lastDispatchCount' = Cardinality(ActiveNodesAt(tick, stageIx, remaining))

Serve ==
  \E sel \in [Nodes -> Jobs \cup {NoJob}] : ServeDispatch(sel)

Progress ==
  \/ IdleAdvance
  \/ Serve

Stutter ==
  /\ Done
  /\ UNCHANGED vars

Next ==
  \/ Progress
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Progress)

InvWellFormed ==
  /\ scenarioId \in ScenarioDomain
  /\ tick \in Nat
  /\ stageIx \in [Jobs -> Nat]
  /\ remaining \in [Jobs -> Nat]
  /\ area \in Nat
  /\ departedSojourn \in Nat
  /\ lastActiveNodeCount \in 0..Cardinality(Nodes)
  /\ lastDispatchCount \in 0..Cardinality(Nodes)

InvWorkConservingNetworkDispatch ==
  /\ lastDispatchCount = lastActiveNodeCount
  /\ lastDispatchCount <= Cardinality(Nodes)

InvNetworkConservationLaw ==
  area = departedSojourn + OpenAgeAt(tick, stageIx)

InvFinalNetworkIdentity ==
  Done => area = departedSojourn

Termination == <>Done

=============================================================================
