------------------------------ MODULE QueueingProbabilisticNetworkKernel ------------------------------
EXTENDS Naturals, Sequences

\* Exact finite-state probabilistic transition kernel for a bounded multiclass
\* open network. Two possible arrivals branch over {none, alpha, beta}; alpha
\* follows route 1 -> 2 with service quanta <<2, 1>>, beta follows route 2 -> 1
\* with service quanta <<1, 2>>. The model keeps the exact probability-mass
\* distribution over phase pairs and carries exact lifted first moments for
\* accumulated area and departed sojourn, which is sufficient to check the
\* customer-time conservation law directly at the distribution level.

VARIABLES tick, massDist, areaDist, departedDist

vars == <<tick, massDist, areaDist, departedDist>>

TerminationBound == 6
PhaseSet == {0, 1, 2, 3, 4, 5, 6, 7}
PhaseSeq == <<0, 1, 2, 3, 4, 5, 6, 7>>

Pair(p1, p2) == <<p1, p2>>

Phase1(pair) == pair[1]
Phase2(pair) == pair[2]

PhasePairSet ==
  {Pair(p1, p2) : p1 \in PhaseSet, p2 \in PhaseSet}

RECURSIVE SeqSum(_)
SeqSum(seq) ==
  IF Len(seq) = 0 THEN 0 ELSE Head(seq) + SeqSum(Tail(seq))

OutcomeList(t) ==
  IF t < 2 THEN <<0, 1, 4>> ELSE <<0>>

OutcomeMass(t, outcome) ==
  IF t < 2 THEN 1 ELSE 1

PhaseActive(phase) ==
  phase \in {1, 2, 3, 4, 5, 6}

PhaseNode(phase) ==
  IF phase \in {1, 2, 5, 6} THEN 1
  ELSE IF phase \in {3, 4} THEN 2
  ELSE 0

AdvancePhase(phase) ==
  IF phase = 1 THEN 2
  ELSE IF phase = 2 THEN 3
  ELSE IF phase = 3 THEN 7
  ELSE IF phase = 4 THEN 5
  ELSE IF phase = 5 THEN 6
  ELSE IF phase = 6 THEN 7
  ELSE phase

Occupancy(pair) ==
  (IF PhaseActive(Phase1(pair)) THEN 1 ELSE 0) +
  (IF PhaseActive(Phase2(pair)) THEN 1 ELSE 0)

ApplyArrival(pair, t, outcome) ==
  IF t = 0
  THEN Pair(outcome, Phase2(pair))
  ELSE IF t = 1
       THEN Pair(Phase1(pair), outcome)
       ELSE pair

ServeSlot1(pair) ==
  PhaseActive(Phase1(pair))

ServeSlot2(pair) ==
  /\ PhaseActive(Phase2(pair))
  /\ (~PhaseActive(Phase1(pair)) \/ PhaseNode(Phase1(pair)) # PhaseNode(Phase2(pair)))

DepartedIncrement1(pair, t) ==
  IF ServeSlot1(pair) /\ AdvancePhase(Phase1(pair)) = 7 THEN t + 1 ELSE 0

DepartedIncrement2(pair, t) ==
  IF ServeSlot2(pair) /\ AdvancePhase(Phase2(pair)) = 7 THEN t ELSE 0

ServeFifoPair(pair, t) ==
  Pair(
    IF ServeSlot1(pair) THEN AdvancePhase(Phase1(pair)) ELSE Phase1(pair),
    IF ServeSlot2(pair) THEN AdvancePhase(Phase2(pair)) ELSE Phase2(pair)
  )

NextPair(pair, t, outcome) ==
  LET preService == ApplyArrival(pair, t, outcome) IN
    ServeFifoPair(preService, t)

AreaContribution(pair, t, outcome) ==
  LET preService == ApplyArrival(pair, t, outcome) IN
    Occupancy(preService)

DepartedContribution(pair, t, outcome) ==
  LET preService == ApplyArrival(pair, t, outcome) IN
    DepartedIncrement1(preService, t) + DepartedIncrement2(preService, t)

TransitionMassTo(target) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      SeqSum([n \in 1..Len(OutcomeList(tick)) |->
        LET source == Pair(p1, p2) IN
        LET outcome == OutcomeList(tick)[n] IN
        IF NextPair(source, tick, outcome) = target
        THEN massDist[source] * OutcomeMass(tick, outcome)
        ELSE 0
      ])
    ])
  ])

TransitionAreaTo(target) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      SeqSum([n \in 1..Len(OutcomeList(tick)) |->
        LET source == Pair(p1, p2) IN
        LET outcome == OutcomeList(tick)[n] IN
        IF NextPair(source, tick, outcome) = target
        THEN
          areaDist[source] * OutcomeMass(tick, outcome) +
            massDist[source] * OutcomeMass(tick, outcome) *
              AreaContribution(source, tick, outcome)
        ELSE 0
      ])
    ])
  ])

TransitionDepartedTo(target) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      SeqSum([n \in 1..Len(OutcomeList(tick)) |->
        LET source == Pair(p1, p2) IN
        LET outcome == OutcomeList(tick)[n] IN
        IF NextPair(source, tick, outcome) = target
        THEN
          departedDist[source] * OutcomeMass(tick, outcome) +
            massDist[source] * OutcomeMass(tick, outcome) *
              DepartedContribution(source, tick, outcome)
        ELSE 0
      ])
    ])
  ])

TotalMass(d) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      d[Pair(p1, p2)]
    ])
  ])

ActiveMass(d) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      IF PhaseActive(p1) \/ PhaseActive(p2)
      THEN d[Pair(p1, p2)]
      ELSE 0
    ])
  ])

WeightedArea(d) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      d[Pair(p1, p2)]
    ])
  ])

WeightedDepartedSojourn(d) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      d[Pair(p1, p2)]
    ])
  ])

OpenAgeContribution(pair, t) ==
  (IF PhaseActive(Phase1(pair)) THEN t ELSE 0) +
  (IF PhaseActive(Phase2(pair)) /\ t > 0 THEN t - 1 ELSE 0)

WeightedOpenAge(m, t) ==
  SeqSum([i \in 1..Len(PhaseSeq) |->
    LET p1 == PhaseSeq[i] IN
    SeqSum([j \in 1..Len(PhaseSeq) |->
      LET p2 == PhaseSeq[j] IN
      m[Pair(p1, p2)] * OpenAgeContribution(Pair(p1, p2), t)
    ])
  ])

ExpectedMassAt(t) ==
  IF t = 0 THEN 1
  ELSE IF t = 1 THEN 3
  ELSE 9

Done == tick >= 2 /\ ActiveMass(massDist) = 0

Init ==
  /\ tick = 0
  /\ massDist = [pair \in PhasePairSet |->
      IF pair = Pair(0, 0) THEN 1 ELSE 0]
  /\ areaDist = [pair \in PhasePairSet |-> 0]
  /\ departedDist = [pair \in PhasePairSet |-> 0]

Advance ==
  /\ ~Done
  /\ tick < TerminationBound
  /\ tick' = tick + 1
  /\ massDist' = [pair \in PhasePairSet |-> TransitionMassTo(pair)]
  /\ areaDist' = [pair \in PhasePairSet |-> TransitionAreaTo(pair)]
  /\ departedDist' = [pair \in PhasePairSet |-> TransitionDepartedTo(pair)]

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
  /\ massDist \in [PhasePairSet -> Nat]
  /\ areaDist \in [PhasePairSet -> Nat]
  /\ departedDist \in [PhasePairSet -> Nat]

InvMassSchedule ==
  TotalMass(massDist) = ExpectedMassAt(tick)

InvDistributionConservationLaw ==
  WeightedArea(areaDist) = WeightedDepartedSojourn(departedDist) + WeightedOpenAge(massDist, tick)

InvFinalExpectationIdentity ==
  Done => WeightedArea(areaDist) = WeightedDepartedSojourn(departedDist)

Termination == <>Done

=============================================================================
