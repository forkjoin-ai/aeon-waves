------------------------------ MODULE SleepDebt ------------------------------
EXTENDS Naturals

CONSTANTS
  BurdenDomain,
  DebtDomain,
  CapacityDomain,
  IntrusionDomain,
  MaxCapacity,
  RecoveryQuota,
  WakeGrowth,
  IntrusionThreshold

VARIABLES phase, burden, debt, capacity, intrusions, lastAction

vars == <<phase, burden, debt, capacity, intrusions, lastAction>>

EffectiveCapacity(d) ==
  IF d >= MaxCapacity THEN 0 ELSE MaxCapacity - d

IntrusionEnabled ==
  /\ phase = "wake"
  /\ burden > 0
  /\ debt >= IntrusionThreshold
  /\ intrusions + 1 \in IntrusionDomain

Init ==
  /\ phase = "wake"
  /\ burden \in BurdenDomain
  /\ debt \in DebtDomain
  /\ capacity = EffectiveCapacity(debt)
  /\ capacity \in CapacityDomain
  /\ intrusions \in IntrusionDomain
  /\ lastAction = "init"

StartSleep ==
  /\ phase = "wake"
  /\ phase' = "sleep"
  /\ UNCHANGED <<burden, debt, capacity, intrusions>>
  /\ lastAction' = "startSleep"

WakeStep ==
  /\ phase = "wake"
  /\ burden + WakeGrowth \in BurdenDomain
  /\ burden' = burden + WakeGrowth
  /\ debt' = debt
  /\ capacity' = EffectiveCapacity(debt')
  /\ intrusions' = intrusions
  /\ phase' = "wake"
  /\ lastAction' = "wake"

SleepPartial ==
  /\ phase = "sleep"
  /\ burden + debt > RecoveryQuota
  /\ burden + debt - RecoveryQuota \in DebtDomain
  /\ burden' = 0
  /\ debt' = burden + debt - RecoveryQuota
  /\ capacity' = EffectiveCapacity(debt')
  /\ capacity' \in CapacityDomain
  /\ intrusions' = intrusions
  /\ phase' = "wake"
  /\ lastAction' = "partialSleep"

SleepFull ==
  /\ phase = "sleep"
  /\ burden + debt <= RecoveryQuota
  /\ burden' = 0
  /\ debt' = 0
  /\ capacity' = EffectiveCapacity(debt')
  /\ capacity' \in CapacityDomain
  /\ intrusions' = intrusions
  /\ phase' = "wake"
  /\ lastAction' = "fullSleep"

Intrusion ==
  /\ IntrusionEnabled
  /\ burden' = burden - 1
  /\ debt' = debt
  /\ capacity' = EffectiveCapacity(debt')
  /\ intrusions' = intrusions + 1
  /\ phase' = "wake"
  /\ lastAction' = "intrusion"

Stutter == UNCHANGED vars

Next ==
  StartSleep \/
  WakeStep \/
  SleepPartial \/
  SleepFull \/
  Intrusion \/
  Stutter

Spec == Init /\ [][Next]_vars

InvWellFormed ==
  /\ phase \in {"wake", "sleep"}
  /\ burden \in BurdenDomain
  /\ debt \in DebtDomain
  /\ capacity \in CapacityDomain
  /\ intrusions \in IntrusionDomain

InvCapacityMatchesDebt ==
  capacity = EffectiveCapacity(debt)

InvPartialRecoveryLeavesDebt ==
  lastAction = "partialSleep" => debt > 0

InvPartialRecoveryResetsLocalBurden ==
  lastAction = "partialSleep" => burden = 0

InvPartialRecoveryReducesCapacity ==
  /\ lastAction = "partialSleep"
  /\ MaxCapacity > 0
  => capacity < MaxCapacity

InvFullRecoveryClearsDebt ==
  lastAction = "fullSleep" => debt = 0

InvFullRecoveryRestoresCapacity ==
  /\ lastAction = "fullSleep"
  /\ MaxCapacity \in CapacityDomain
  => capacity = MaxCapacity

InvPositiveDebtLowersCapacity ==
  /\ MaxCapacity > 0
  /\ debt > 0
  => capacity < MaxCapacity

PropDebtWakeCanIntrude ==
  []((phase = "wake" /\ burden > 0 /\ debt >= IntrusionThreshold /\
      intrusions + 1 \in IntrusionDomain) => ENABLED Intrusion)

=============================================================================
