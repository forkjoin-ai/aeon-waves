------------------------------ MODULE QueueingProbabilisticLargeNetworkKernel ------------------------------
EXTENDS Naturals, Sequences, Integers

\* Exact finite-support probabilistic cube for a larger bounded multiclass open
\* network. The full three-arrival outcome cube is carried at once: each of the
\* 64 scenarios selects {none, alpha, beta, gamma} independently at ticks
\* 0, 1, 2. Alpha follows 1 -> 2 -> 3 with service <<2,1,1>>, beta follows
\* 2 -> 3 -> 1 with <<1,1,2>>, and gamma follows 3 -> 1 -> 2 with <<1,2,1>>.
\* Each scenario evolves deterministically under per-node FIFO by arrival slot.
\* The model checks the exact weighted conservation law over the entire cube.

VARIABLES tick, slot1Phase, slot2Phase, slot3Phase, area, departed

vars == <<tick, slot1Phase, slot2Phase, slot3Phase, area, departed>>

TerminationBound == 10
PhaseSet == {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
ScenarioSeq ==
  <<0, 1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23,
    24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39,
    40, 41, 42, 43, 44, 45, 46, 47,
    48, 49, 50, 51, 52, 53, 54, 55,
    56, 57, 58, 59, 60, 61, 62, 63>>
ScenarioSet == {s \in 0..63 : TRUE}

Triple(p1, p2, p3) == <<p1, p2, p3>>

Phase1(triple) == triple[1]
Phase2(triple) == triple[2]
Phase3(triple) == triple[3]

RECURSIVE SeqSum(_)
SeqSum(seq) ==
  IF Len(seq) = 0 THEN 0 ELSE Head(seq) + SeqSum(Tail(seq))

PhaseActive(phase) ==
  phase \in {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

PhaseNode(phase) ==
  IF phase \in {1, 2, 7, 8, 10, 11} THEN 1
  ELSE IF phase \in {3, 5, 12} THEN 2
  ELSE IF phase \in {4, 6, 9} THEN 3
  ELSE 0

AdvancePhase(phase) ==
  IF phase = 1 THEN 2
  ELSE IF phase = 2 THEN 3
  ELSE IF phase = 3 THEN 4
  ELSE IF phase = 4 THEN 13
  ELSE IF phase = 5 THEN 6
  ELSE IF phase = 6 THEN 7
  ELSE IF phase = 7 THEN 8
  ELSE IF phase = 8 THEN 13
  ELSE IF phase = 9 THEN 10
  ELSE IF phase = 10 THEN 11
  ELSE IF phase = 11 THEN 12
  ELSE IF phase = 12 THEN 13
  ELSE phase

OutcomePhase(code) ==
  IF code = 1 THEN 1
  ELSE IF code = 2 THEN 5
  ELSE IF code = 3 THEN 9
  ELSE 0

ArrivalCode(id, t) ==
  IF t = 0 THEN id % 4
  ELSE IF t = 1 THEN (id \div 4) % 4
  ELSE IF t = 2 THEN (id \div 16) % 4
  ELSE 0

ArrivalPhase(id, t) ==
  OutcomePhase(ArrivalCode(id, t))

CurrentTriple(id) ==
  Triple(slot1Phase[id], slot2Phase[id], slot3Phase[id])

Occupancy(triple) ==
  (IF PhaseActive(Phase1(triple)) THEN 1 ELSE 0) +
  (IF PhaseActive(Phase2(triple)) THEN 1 ELSE 0) +
  (IF PhaseActive(Phase3(triple)) THEN 1 ELSE 0)

ApplyArrival(triple, id, t) ==
  IF t = 0
  THEN Triple(ArrivalPhase(id, t), Phase2(triple), Phase3(triple))
  ELSE IF t = 1
       THEN Triple(Phase1(triple), ArrivalPhase(id, t), Phase3(triple))
       ELSE IF t = 2
            THEN Triple(Phase1(triple), Phase2(triple), ArrivalPhase(id, t))
            ELSE triple

ServeSlot1(triple) ==
  PhaseActive(Phase1(triple))

ServeSlot2(triple) ==
  /\ PhaseActive(Phase2(triple))
  /\ (~PhaseActive(Phase1(triple)) \/ PhaseNode(Phase1(triple)) # PhaseNode(Phase2(triple)))

ServeSlot3(triple) ==
  /\ PhaseActive(Phase3(triple))
  /\ (~PhaseActive(Phase1(triple)) \/ PhaseNode(Phase1(triple)) # PhaseNode(Phase3(triple)))
  /\ (~PhaseActive(Phase2(triple)) \/ PhaseNode(Phase2(triple)) # PhaseNode(Phase3(triple)))

DepartedIncrement1(triple, t) ==
  IF ServeSlot1(triple) /\ AdvancePhase(Phase1(triple)) = 13 THEN t + 1 ELSE 0

DepartedIncrement2(triple, t) ==
  IF ServeSlot2(triple) /\ AdvancePhase(Phase2(triple)) = 13 THEN t ELSE 0

DepartedIncrement3(triple, t) ==
  IF ServeSlot3(triple) /\ AdvancePhase(Phase3(triple)) = 13 THEN t - 1 ELSE 0

ServeFifoTriple(triple, t) ==
  Triple(
    IF ServeSlot1(triple) THEN AdvancePhase(Phase1(triple)) ELSE Phase1(triple),
    IF ServeSlot2(triple) THEN AdvancePhase(Phase2(triple)) ELSE Phase2(triple),
    IF ServeSlot3(triple) THEN AdvancePhase(Phase3(triple)) ELSE Phase3(triple)
  )

NextTriple(id) ==
  LET preService == ApplyArrival(CurrentTriple(id), id, tick) IN
    ServeFifoTriple(preService, tick)

AreaIncrement(id) ==
  LET preService == ApplyArrival(CurrentTriple(id), id, tick) IN
    Occupancy(preService)

DepartedIncrement(id) ==
  LET preService == ApplyArrival(CurrentTriple(id), id, tick) IN
    DepartedIncrement1(preService, tick) +
      DepartedIncrement2(preService, tick) +
      DepartedIncrement3(preService, tick)

WeightedArea(d) ==
  SeqSum([i \in 1..Len(ScenarioSeq) |->
    LET id == ScenarioSeq[i] IN d[id]
  ])

WeightedOpenAge(t) ==
  SeqSum([i \in 1..Len(ScenarioSeq) |->
    LET id == ScenarioSeq[i] IN
    LET triple == CurrentTriple(id) IN
    (IF PhaseActive(Phase1(triple)) THEN t ELSE 0) +
      (IF PhaseActive(Phase2(triple)) /\ t > 0 THEN t - 1 ELSE 0) +
      (IF PhaseActive(Phase3(triple)) /\ t > 1 THEN t - 2 ELSE 0)
  ])

ActiveScenarioCount ==
  SeqSum([i \in 1..Len(ScenarioSeq) |->
    LET id == ScenarioSeq[i] IN
    LET triple == CurrentTriple(id) IN
    IF PhaseActive(Phase1(triple)) \/ PhaseActive(Phase2(triple)) \/ PhaseActive(Phase3(triple))
    THEN 1
    ELSE 0
  ])

FutureMultiplicity(t) ==
  IF t = 0 THEN 64
  ELSE IF t = 1 THEN 16
  ELSE IF t = 2 THEN 4
  ELSE 1

ExpectedMassAt(t) ==
  IF t = 0 THEN 1
  ELSE IF t = 1 THEN 4
  ELSE IF t = 2 THEN 16
  ELSE 64

Done == tick >= 3 /\ ActiveScenarioCount = 0

Init ==
  /\ tick = 0
  /\ slot1Phase = [id \in ScenarioSet |-> 0]
  /\ slot2Phase = [id \in ScenarioSet |-> 0]
  /\ slot3Phase = [id \in ScenarioSet |-> 0]
  /\ area = [id \in ScenarioSet |-> 0]
  /\ departed = [id \in ScenarioSet |-> 0]

Advance ==
  /\ ~Done
  /\ tick < TerminationBound
  /\ tick' = tick + 1
  /\ slot1Phase' = [id \in ScenarioSet |-> Phase1(NextTriple(id))]
  /\ slot2Phase' = [id \in ScenarioSet |-> Phase2(NextTriple(id))]
  /\ slot3Phase' = [id \in ScenarioSet |-> Phase3(NextTriple(id))]
  /\ area' = [id \in ScenarioSet |-> area[id] + AreaIncrement(id)]
  /\ departed' = [id \in ScenarioSet |-> departed[id] + DepartedIncrement(id)]

Stutter ==
  /\ Done
  /\ UNCHANGED vars

Next ==
  \/ Advance
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Advance)

InvWellFormed ==
  /\ tick \in Nat
  /\ tick <= TerminationBound
  /\ slot1Phase \in [ScenarioSet -> PhaseSet]
  /\ slot2Phase \in [ScenarioSet -> PhaseSet]
  /\ slot3Phase \in [ScenarioSet -> PhaseSet]
  /\ area \in [ScenarioSet -> Nat]
  /\ departed \in [ScenarioSet -> Nat]

InvMassSchedule ==
  Len(ScenarioSeq) \div FutureMultiplicity(tick) = ExpectedMassAt(tick)

InvDistributionConservationLaw ==
  WeightedArea(area) = WeightedArea(departed) + WeightedOpenAge(tick)

InvFinalExpectationIdentity ==
  Done => WeightedArea(area) = WeightedArea(departed)

Termination == <>Done

=============================================================================
