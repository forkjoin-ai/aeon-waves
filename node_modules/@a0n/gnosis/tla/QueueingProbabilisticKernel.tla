------------------------------ MODULE QueueingProbabilisticKernel ------------------------------
EXTENDS Naturals, Sequences

\* Exact finite-state probabilistic transition kernel for a bounded FIFO queue.
\* The state carries the full mass distribution over local queue states rather
\* than a pre-expanded scenario family. Arrivals branch with finite support at
\* ticks 0 and 1, then a work-conserving FIFO server deterministically serves
\* one quantum per tick. Customer-time conservation is checked directly at the
\* distribution level.

VARIABLES tick, dist

vars == <<tick, dist>>

TerminationBound == 4
HistoryBound == 5
MassSet == {0, 1, 2}
HistorySet == 0..HistoryBound
MassSeq == <<0, 1, 2>>
HistorySeq == <<0, 1, 2, 3, 4, 5>>

State(r1, r2, area, departed) == <<r1, r2, area, departed>>

Remaining1(state) == state[1]
Remaining2(state) == state[2]
AreaOf(state) == state[3]
DepartedOf(state) == state[4]

LocalStateSet ==
  {State(r1, r2, area, departed) :
    r1 \in MassSet, r2 \in MassSet,
    area \in HistorySet, departed \in HistorySet}

RECURSIVE SeqSum(_)
SeqSum(seq) ==
  IF Len(seq) = 0 THEN 0 ELSE Head(seq) + SeqSum(Tail(seq))

OutcomeList(t) ==
  IF t < 2 THEN <<0, 1, 2>> ELSE <<0>>

OutcomeMass(t, outcome) ==
  IF t < 2 THEN 1 ELSE 1

Occupancy(state) ==
  (IF Remaining1(state) > 0 THEN 1 ELSE 0) +
  (IF Remaining2(state) > 0 THEN 1 ELSE 0)

ApplyArrival(state, t, outcome) ==
  IF t = 0
  THEN State(outcome, Remaining2(state), AreaOf(state), DepartedOf(state))
  ELSE IF t = 1
       THEN State(Remaining1(state), outcome, AreaOf(state), DepartedOf(state))
       ELSE state

ServeFifo(state, t) ==
  LET nextArea == AreaOf(state) + Occupancy(state) IN
    IF Remaining1(state) > 0
    THEN
      State(
        Remaining1(state) - 1,
        Remaining2(state),
        nextArea,
        DepartedOf(state) + IF Remaining1(state) = 1 THEN t + 1 ELSE 0
      )
    ELSE IF Remaining2(state) > 0
         THEN
           State(
             Remaining1(state),
             Remaining2(state) - 1,
             nextArea,
             DepartedOf(state) + IF Remaining2(state) = 1 THEN t ELSE 0
           )
         ELSE State(Remaining1(state), Remaining2(state), nextArea, DepartedOf(state))

TransitionMassTo(target) ==
  SeqSum([i \in 1..Len(MassSeq) |->
    LET r1 == MassSeq[i] IN
    SeqSum([j \in 1..Len(MassSeq) |->
      LET r2 == MassSeq[j] IN
      SeqSum([k \in 1..Len(HistorySeq) |->
        LET area == HistorySeq[k] IN
        SeqSum([m \in 1..Len(HistorySeq) |->
          LET departed == HistorySeq[m] IN
          SeqSum([n \in 1..Len(OutcomeList(tick)) |->
            LET source == State(r1, r2, area, departed) IN
            LET outcome == OutcomeList(tick)[n] IN
            IF ServeFifo(ApplyArrival(source, tick, outcome), tick) = target
            THEN dist[source] * OutcomeMass(tick, outcome)
            ELSE 0
          ])
        ])
      ])
    ])
  ])

TotalMass(d) ==
  SeqSum([i \in 1..Len(MassSeq) |->
    LET r1 == MassSeq[i] IN
    SeqSum([j \in 1..Len(MassSeq) |->
      LET r2 == MassSeq[j] IN
      SeqSum([k \in 1..Len(HistorySeq) |->
        LET area == HistorySeq[k] IN
        SeqSum([m \in 1..Len(HistorySeq) |->
          LET departed == HistorySeq[m] IN
          d[State(r1, r2, area, departed)]
        ])
      ])
    ])
  ])

ActiveMass(d) ==
  SeqSum([i \in 1..Len(MassSeq) |->
    LET r1 == MassSeq[i] IN
    SeqSum([j \in 1..Len(MassSeq) |->
      LET r2 == MassSeq[j] IN
      SeqSum([k \in 1..Len(HistorySeq) |->
        LET area == HistorySeq[k] IN
        SeqSum([m \in 1..Len(HistorySeq) |->
          LET departed == HistorySeq[m] IN
          IF r1 > 0 \/ r2 > 0
          THEN d[State(r1, r2, area, departed)]
          ELSE 0
        ])
      ])
    ])
  ])

WeightedArea(d) ==
  SeqSum([i \in 1..Len(MassSeq) |->
    LET r1 == MassSeq[i] IN
    SeqSum([j \in 1..Len(MassSeq) |->
      LET r2 == MassSeq[j] IN
      SeqSum([k \in 1..Len(HistorySeq) |->
        LET area == HistorySeq[k] IN
        SeqSum([m \in 1..Len(HistorySeq) |->
          LET departed == HistorySeq[m] IN
          d[State(r1, r2, area, departed)] * area
        ])
      ])
    ])
  ])

WeightedDepartedSojourn(d) ==
  SeqSum([i \in 1..Len(MassSeq) |->
    LET r1 == MassSeq[i] IN
    SeqSum([j \in 1..Len(MassSeq) |->
      LET r2 == MassSeq[j] IN
      SeqSum([k \in 1..Len(HistorySeq) |->
        LET area == HistorySeq[k] IN
        SeqSum([m \in 1..Len(HistorySeq) |->
          LET departed == HistorySeq[m] IN
          d[State(r1, r2, area, departed)] * departed
        ])
      ])
    ])
  ])

OpenAgeContribution(state, t) ==
  (IF Remaining1(state) > 0 THEN t ELSE 0) +
  (IF Remaining2(state) > 0 /\ t > 0 THEN t - 1 ELSE 0)

WeightedOpenAge(d, t) ==
  SeqSum([i \in 1..Len(MassSeq) |->
    LET r1 == MassSeq[i] IN
    SeqSum([j \in 1..Len(MassSeq) |->
      LET r2 == MassSeq[j] IN
      SeqSum([k \in 1..Len(HistorySeq) |->
        LET area == HistorySeq[k] IN
        SeqSum([m \in 1..Len(HistorySeq) |->
          LET departed == HistorySeq[m] IN
          d[State(r1, r2, area, departed)] *
            OpenAgeContribution(State(r1, r2, area, departed), t)
        ])
      ])
    ])
  ])

ExpectedMassAt(t) ==
  IF t = 0 THEN 1
  ELSE IF t = 1 THEN 3
  ELSE 9

Done == tick >= 2 /\ ActiveMass(dist) = 0

Init ==
  /\ tick = 0
  /\ dist = [state \in LocalStateSet |->
      IF state = State(0, 0, 0, 0) THEN 1 ELSE 0]

Advance ==
  /\ ~Done
  /\ tick < TerminationBound
  /\ tick' = tick + 1
  /\ dist' = [state \in LocalStateSet |-> TransitionMassTo(state)]

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
  /\ dist \in [LocalStateSet -> Nat]

InvMassSchedule ==
  TotalMass(dist) = ExpectedMassAt(tick)

InvDistributionConservationLaw ==
  WeightedArea(dist) = WeightedDepartedSojourn(dist) + WeightedOpenAge(dist, tick)

InvFinalExpectationIdentity ==
  Done => WeightedArea(dist) = WeightedDepartedSojourn(dist)

Termination == <>Done

=============================================================================
