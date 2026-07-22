------------------------------ MODULE open_source_gnosis_warmup_mixed_commercial_flight ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

NODES == {"flight_request", "takeoff_burn", "cruising_altitude", "engine_thermal_state", "engine_optimum", "flight_phase", "arrival"}
ROOTS == {"flight_request"}
TERMINALS == {"arrival"}
FOLD_TARGETS == {}
EFFECTS == {}
DECLARED_EFFECTS == {}
INFERRED_EFFECTS == {}

VARIABLES active, beta1, payloadPresent, consensusReached
vars == <<active, beta1, payloadPresent, consensusReached>>

Max2(a, b) == IF a > b THEN a ELSE b
CanFire(sourceSet) == sourceSet \subseteq active
UpdateActive(sourceSet, targetSet) == (active \ sourceSet) \cup targetSet

Init ==
  /\ active = ROOTS
  /\ beta1 = 0
  /\ payloadPresent = TRUE
  /\ consensusReached = FALSE

Edge_01_FORK ==
  /\ CanFire({"flight_request"})
  /\ active' = UpdateActive({"flight_request"}, {"takeoff_burn", "engine_thermal_state"})
  /\ beta1' = beta1 + (Cardinality({"takeoff_burn", "engine_thermal_state"}) - 1)
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"takeoff_burn", "engine_thermal_state"} \cap FOLD_TARGETS # {})
Edge_02_PROCESS ==
  /\ CanFire({"takeoff_burn"})
  /\ active' = UpdateActive({"takeoff_burn"}, {"cruising_altitude"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"cruising_altitude"} \cap FOLD_TARGETS # {})
Edge_03_PROCESS ==
  /\ CanFire({"engine_thermal_state"})
  /\ active' = UpdateActive({"engine_thermal_state"}, {"engine_optimum"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"engine_optimum"} \cap FOLD_TARGETS # {})
Edge_04_INTERFERE ==
  /\ CanFire({"cruising_altitude", "engine_optimum"})
  /\ active' = UpdateActive({"cruising_altitude", "engine_optimum"}, {"flight_phase"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"flight_phase"} \cap FOLD_TARGETS # {})
Edge_05_PROCESS ==
  /\ CanFire({"flight_phase"})
  /\ active' = UpdateActive({"flight_phase"}, {"arrival"})
  /\ beta1' = beta1
  /\ payloadPresent' = payloadPresent
  /\ consensusReached' = consensusReached \/ ({"arrival"} \cap FOLD_TARGETS # {})

Next ==
  \/ Edge_01_FORK
  \/ Edge_02_PROCESS
  \/ Edge_03_PROCESS
  \/ Edge_04_INTERFERE
  \/ Edge_05_PROCESS

TypeInvariant ==
  /\ active \subseteq NODES
  /\ beta1 \in Nat
  /\ payloadPresent \in BOOLEAN
  /\ consensusReached \in BOOLEAN

NoLostPayloadInvariant == payloadPresent = TRUE
HasFoldTargets == FOLD_TARGETS # {}
EventuallyTerminal == <> (active \cap TERMINALS # {})
EventuallyConsensus == IF HasFoldTargets THEN <> consensusReached ELSE TRUE
DeadlockFree == []<>(ENABLED Next)

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ WF_vars(Next)

THEOREM Spec => []NoLostPayloadInvariant

=============================================================================
