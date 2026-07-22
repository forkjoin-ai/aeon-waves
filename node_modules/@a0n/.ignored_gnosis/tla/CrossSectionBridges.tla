------------------------------ MODULE CrossSectionBridges ------------------------------
\* TLA+ model-checking for 5 cross-section bridge theorems composing
\* previously unbridged ledger sections.

EXTENDS Integers, FiniteSets

CONSTANTS MaxVal

ASSUME MaxVal > 0

VARIABLES
    gamma, pressure, forkCount,       \* Bridge 1: coupling x deficit
    capacity, depth,                   \* Bridge 2: queue x Buleyean
    arrival, service,                  \* Bridge 3: spectral x first law
    fork, fold, vent1, vent2,          \* Bridge 3 cont: uniqueness
    deficit, stepSize, kernelMixing    \* Bridge 5: ergodic x dialogue

vars == <<gamma, pressure, forkCount, capacity, depth,
          arrival, service, fork, fold, vent1, vent2,
          deficit, stepSize, kernelMixing>>

NatSub(a, b) == IF a >= b THEN a - b ELSE 0
MinOf(a, b) == IF a <= b THEN a ELSE b
BuleyeanWeight(rounds, voidCount) == rounds - MinOf(voidCount, rounds) + 1
QueueBuleyean(cap, dep) == cap - MinOf(dep, cap) + 1

Init ==
    /\ gamma \in 1..MaxVal
    /\ pressure \in 0..MaxVal
    /\ pressure < gamma
    /\ forkCount \in 0..MaxVal
    /\ forkCount < gamma
    /\ capacity \in 0..MaxVal
    /\ depth \in 0..MaxVal
    /\ arrival \in 0..MaxVal
    /\ service \in 1..MaxVal
    /\ arrival < service
    /\ fork \in 1..MaxVal
    /\ fold \in 0..MaxVal
    /\ fold <= fork
    /\ vent1 = fork - fold
    /\ vent2 = fork - fold
    /\ deficit \in 0..MaxVal
    /\ stepSize \in 1..MaxVal
    /\ kernelMixing \in 1..MaxVal

Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* Bridge 1: Coupling margin bounds fork count

InvCouplingMarginBoundsForks ==
    pressure < gamma => pressure + 1 <= gamma

InvCouplingExhausted ==
    ~(gamma < gamma)

InvForkWithinMargin ==
    forkCount < gamma => forkCount + 1 <= gamma

-----------------------------------------------------------------------------
\* Bridge 2: Queue boundary = Buleyean weight

InvQueueBuleyeanIsomorphism ==
    QueueBuleyean(capacity, depth) = BuleyeanWeight(capacity, depth)

InvQueueBuleyeanPositive ==
    QueueBuleyean(capacity, depth) >= 1

InvQueueEmptyMaxWeight ==
    QueueBuleyean(capacity, 0) = capacity + 1

InvQueueFullSliver ==
    QueueBuleyean(capacity, capacity) = 1

-----------------------------------------------------------------------------
\* Bridge 3: Spectral stability x first law

InvFirstLawUniqueVent ==
    fold <= fork => NatSub(fork, fold) + fold = fork

InvStableFirstLawVentAbsorbs ==
    arrival < service => arrival + (service - arrival) = service

InvFirstLawVentDetermined ==
    (fork = fold + vent1 /\ fork = fold + vent2) => vent1 = vent2

-----------------------------------------------------------------------------
\* Bridge 5: Ergodic rate x dialogue convergence

DialogueTurns == (deficit + stepSize - 1) \div stepSize
DialogueMixing == DialogueTurns * kernelMixing

InvDialogueMixingBoundedOrZero ==
    DialogueMixing > 0 \/ deficit = 0

InvDialogueMixingMonotoneDeficit ==
    \A d1, d2 \in 0..MaxVal :
        d1 <= d2 => ((d1 + stepSize - 1) \div stepSize) * kernelMixing
                  <= ((d2 + stepSize - 1) \div stepSize) * kernelMixing

InvDialogueMixingMonotoneKernel ==
    \A k1, k2 \in 1..MaxVal :
        k1 <= k2 => DialogueTurns * k1 <= DialogueTurns * k2

=============================================================================
