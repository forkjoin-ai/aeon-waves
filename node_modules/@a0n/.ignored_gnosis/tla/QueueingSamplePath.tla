------------------------------ MODULE QueueingSamplePath ------------------------------
EXTENDS Naturals, Sequences, FiniteSets

\* Finite-trace queueing sample-path identity:
\* area under occupancy equals departed sojourn plus open age.
\* Nondeterministic service choices quantify over every work-conserving
\* single-server discipline in the bounded discrete model.

CONSTANTS TraceDomain

VARIABLES traceId, tick, remaining, area, departedSojourn, lastActiveCount, lastServed

vars == <<traceId, tick, remaining, area, departedSojourn, lastActiveCount, lastServed>>

ArrivalSeq(id) ==
  IF id = 1 THEN <<0, 1, 1, 2>>
  ELSE IF id = 2 THEN <<0, 2, 2>>
  ELSE <<1, 1, 3, 4>>

ServiceSeq(id) ==
  IF id = 1 THEN <<2, 2, 1, 1>>
  ELSE IF id = 2 THEN <<1, 2, 1>>
  ELSE <<1, 1, 2, 1>>

ArrivalTicks == ArrivalSeq(traceId)
ServiceQuanta == ServiceSeq(traceId)

JobCount == Len(ArrivalTicks)
Jobs == 1..JobCount
NoJob == 0

RECURSIVE SeqSum(_)
SeqSum(seq) ==
  IF Len(seq) = 0 THEN 0 ELSE Head(seq) + SeqSum(Tail(seq))

RECURSIVE SeqMax(_)
SeqMax(seq) ==
  IF Len(seq) = 0 THEN 0
  ELSE IF Len(seq) = 1 THEN Head(seq)
  ELSE IF Head(seq) >= SeqMax(Tail(seq)) THEN Head(seq) ELSE SeqMax(Tail(seq))

ArrivedJobsAt(t) ==
  {j \in Jobs : ArrivalTicks[j] <= t}

ActiveJobsAt(t, rem) ==
  {j \in Jobs : ArrivalTicks[j] <= t /\ rem[j] > 0}

OpenAgeAt(t, rem) ==
  SeqSum([j \in Jobs |-> IF ArrivalTicks[j] <= t /\ rem[j] > 0 THEN t - ArrivalTicks[j] ELSE 0])

TotalRequiredService == SeqSum(ServiceQuanta)
LastArrivalTick == SeqMax(ArrivalTicks)
TerminationBound == LastArrivalTick + TotalRequiredService
Done == \A j \in Jobs : remaining[j] = 0

Init ==
  /\ traceId \in TraceDomain
  /\ JobCount > 0
  /\ Len(ServiceQuanta) = JobCount
  /\ \A j \in Jobs :
       /\ ArrivalTicks[j] \in Nat
       /\ ServiceQuanta[j] \in Nat
       /\ ServiceQuanta[j] > 0
  /\ tick = 0
  /\ remaining = ServiceQuanta
  /\ area = 0
  /\ departedSojourn = 0
  /\ lastActiveCount = 0
  /\ lastServed = NoJob

IdleAdvance ==
  /\ ~Done
  /\ ActiveJobsAt(tick, remaining) = {}
  /\ tick' = tick + 1
  /\ traceId' = traceId
  /\ remaining' = remaining
  /\ area' = area
  /\ departedSojourn' = departedSojourn
  /\ lastActiveCount' = 0
  /\ lastServed' = NoJob

Serve(j) ==
  /\ ~Done
  /\ j \in ActiveJobsAt(tick, remaining)
  /\ tick' = tick + 1
  /\ traceId' = traceId
  /\ remaining' = [remaining EXCEPT ![j] = @ - 1]
  /\ area' = area + Cardinality(ActiveJobsAt(tick, remaining))
  /\ departedSojourn' =
       IF remaining[j] = 1
       THEN departedSojourn + ((tick + 1) - ArrivalTicks[j])
       ELSE departedSojourn
  /\ lastActiveCount' = Cardinality(ActiveJobsAt(tick, remaining))
  /\ lastServed' = j

Stutter ==
  /\ Done
  /\ UNCHANGED vars

Next ==
  \/ IdleAdvance
  \/ \E j \in Jobs : Serve(j)
  \/ Stutter

Progress ==
  \/ IdleAdvance
  \/ \E j \in Jobs : Serve(j)

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Progress)

InvWellFormed ==
  /\ traceId \in TraceDomain
  /\ tick \in Nat
  /\ remaining \in [Jobs -> Nat]
  /\ area \in Nat
  /\ departedSojourn \in Nat
  /\ lastActiveCount \in 0..JobCount
  /\ lastServed \in Jobs \cup {NoJob}

InvWorkConservingChoice ==
  /\ (lastActiveCount = 0) <=> (lastServed = NoJob)
  /\ lastActiveCount > 0 => lastServed \in Jobs

InvTickBounded ==
  tick <= TerminationBound

InvConservationLaw ==
  area = departedSojourn + OpenAgeAt(tick, remaining)

InvFinalLittleIdentity ==
  Done => area = departedSojourn

Termination == <>Done

=============================================================================
