------------------------------ MODULE CancerTreatments ------------------------------
EXTENDS Naturals

\* Five novel cancer treatment strategies from the LEDGER.
\*
\* Prediction 76: Metabolic gate sequencing (mTOR-first maximizes p53 rejections)
\* Prediction 77: Checkpoint cascade amplification (hub restoration cascades beta-1)
\* Prediction 78: Senescence-then-senolytic two-step (dormancy as therapeutic waypoint)
\* Prediction 79: Viral oncoprotein displacement (HPV+ ceiling strictly higher)
\* Prediction 80: Counter-vent depletion before immunotherapy
\*
\* For Sandy.

CONSTANTS
  HealthyVentBeta1,    \* total vent beta-1 of healthy cell (9)
  MaxSteps,            \* maximum simulation steps
  DormancyThreshold,   \* arrest signals needed for senescence (6)
  VentBeta1PerFraction \* arrest signals per radiation fraction (2)

VARIABLES
  \* Prediction 66: Metabolic gate
  gateRemoved,         \* has the metabolic gate been removed?
  therapyApplied,      \* has the checkpoint therapy been applied?
  effectiveRejections, \* cumulative effective rejections
  \* Prediction 67: Cascade
  hubRestored,         \* is the hub checkpoint (p53) restored?
  cascadeBeta1,        \* total beta-1 from cascade
  \* Prediction 68: Senescence
  radiationFractions,  \* number of radiation fractions delivered
  totalArrestSignals,  \* cumulative arrest signals
  senescent,           \* has the tumor entered senescence?
  senolyticApplied,    \* has the senolytic been applied?
  \* Prediction 69: Viral displacement
  viralBlocking,       \* are viral oncoproteins blocking checkpoints?
  displacementApplied, \* has displacement therapy been applied?
  viralRestoredBeta1,  \* beta-1 restored by displacement
  \* Prediction 70: Counter-vent depletion
  suppression,         \* current immune suppression level
  rawImmuneBeta1,      \* raw immune vent beta-1
  depletionApplied,    \* has counter-vent depletion been applied?
  immunotherapyApplied,\* has immunotherapy been applied?
  effectiveImmune,     \* effective immune beta-1 after suppression
  \* Step counter
  step

vars == <<gateRemoved, therapyApplied, effectiveRejections,
          hubRestored, cascadeBeta1,
          radiationFractions, totalArrestSignals, senescent, senolyticApplied,
          viralBlocking, displacementApplied, viralRestoredBeta1,
          suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
          effectiveImmune, step>>

\* ═══════════════════════════════════════════════════════════════════════════════
\* Init
\* ═══════════════════════════════════════════════════════════════════════════════

Init ==
  /\ gateRemoved = FALSE
  /\ therapyApplied = FALSE
  /\ effectiveRejections = 0
  /\ hubRestored = FALSE
  /\ cascadeBeta1 = 0
  /\ radiationFractions = 0
  /\ totalArrestSignals = 0
  /\ senescent = FALSE
  /\ senolyticApplied = FALSE
  /\ viralBlocking = TRUE
  /\ displacementApplied = FALSE
  /\ viralRestoredBeta1 = 0
  /\ suppression = 3
  /\ rawImmuneBeta1 = 2
  /\ depletionApplied = FALSE
  /\ immunotherapyApplied = FALSE
  /\ effectiveImmune = 0
  /\ step = 0

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Prediction 66 -- Metabolic Gate Sequencing
\* ═══════════════════════════════════════════════════════════════════════════════

\* Remove the metabolic gate (rapamycin)
RemoveGate ==
  /\ step < MaxSteps
  /\ gateRemoved = FALSE
  /\ gateRemoved' = TRUE
  /\ UNCHANGED <<therapyApplied, effectiveRejections,
                 hubRestored, cascadeBeta1,
                 radiationFractions, totalArrestSignals, senescent, senolyticApplied,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
                 effectiveImmune>>
  /\ step' = step + 1

\* Apply checkpoint therapy (nutlin-3a)
ApplyTherapy ==
  /\ step < MaxSteps
  /\ therapyApplied = FALSE
  /\ therapyApplied' = TRUE
  /\ effectiveRejections' = IF gateRemoved THEN effectiveRejections + 3 ELSE effectiveRejections
  /\ UNCHANGED <<gateRemoved,
                 hubRestored, cascadeBeta1,
                 radiationFractions, totalArrestSignals, senescent, senolyticApplied,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
                 effectiveImmune>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Prediction 67 -- Checkpoint Cascade Amplification
\* ═══════════════════════════════════════════════════════════════════════════════

\* Restore hub checkpoint (p53)
RestoreHub ==
  /\ step < MaxSteps
  /\ hubRestored = FALSE
  /\ hubRestored' = TRUE
  /\ cascadeBeta1' = 3 + 2 + 2  \* p53 (3) + ATM/ATR (2) + p21->Rb (2) cascade
  /\ UNCHANGED <<gateRemoved, therapyApplied, effectiveRejections,
                 radiationFractions, totalArrestSignals, senescent, senolyticApplied,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
                 effectiveImmune>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Prediction 68 -- Senescence-then-Senolytic
\* ═══════════════════════════════════════════════════════════════════════════════

\* Deliver radiation fraction
DeliverRadiation ==
  /\ step < MaxSteps
  /\ ~senescent
  /\ radiationFractions' = radiationFractions + 1
  /\ totalArrestSignals' = totalArrestSignals + VentBeta1PerFraction
  /\ senescent' = ((totalArrestSignals + VentBeta1PerFraction) >= DormancyThreshold)
  /\ UNCHANGED <<gateRemoved, therapyApplied, effectiveRejections,
                 hubRestored, cascadeBeta1,
                 senolyticApplied,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
                 effectiveImmune>>
  /\ step' = step + 1

\* Apply senolytic after senescence
ApplySenolytic ==
  /\ step < MaxSteps
  /\ senescent
  /\ senolyticApplied = FALSE
  /\ senolyticApplied' = TRUE
  /\ UNCHANGED <<gateRemoved, therapyApplied, effectiveRejections,
                 hubRestored, cascadeBeta1,
                 radiationFractions, totalArrestSignals, senescent,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
                 effectiveImmune>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Prediction 69 -- Viral Oncoprotein Displacement
\* ═══════════════════════════════════════════════════════════════════════════════

\* Apply displacement therapy (competitive peptide inhibitor)
DisplaceOncoproteins ==
  /\ step < MaxSteps
  /\ viralBlocking
  /\ displacementApplied = FALSE
  /\ displacementApplied' = TRUE
  /\ viralBlocking' = FALSE
  /\ viralRestoredBeta1' = 5  \* p53 (3) + Rb (2) = 5
  /\ UNCHANGED <<gateRemoved, therapyApplied, effectiveRejections,
                 hubRestored, cascadeBeta1,
                 radiationFractions, totalArrestSignals, senescent, senolyticApplied,
                 suppression, rawImmuneBeta1, depletionApplied, immunotherapyApplied,
                 effectiveImmune>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Actions: Prediction 70 -- Counter-Vent Depletion
\* ═══════════════════════════════════════════════════════════════════════════════

\* Deplete counter-vents (anti-CD25 + anti-Gr-1)
DepleteCounterVents ==
  /\ step < MaxSteps
  /\ depletionApplied = FALSE
  /\ depletionApplied' = TRUE
  /\ suppression' = 0
  /\ effectiveImmune' = IF immunotherapyApplied
                         THEN rawImmuneBeta1
                         ELSE 0
  /\ UNCHANGED <<gateRemoved, therapyApplied, effectiveRejections,
                 hubRestored, cascadeBeta1,
                 radiationFractions, totalArrestSignals, senescent, senolyticApplied,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 rawImmuneBeta1, immunotherapyApplied>>
  /\ step' = step + 1

\* Apply immunotherapy (anti-PD-1)
ApplyImmunotherapy ==
  /\ step < MaxSteps
  /\ immunotherapyApplied = FALSE
  /\ immunotherapyApplied' = TRUE
  /\ rawImmuneBeta1' = rawImmuneBeta1 + 2
  /\ effectiveImmune' = IF depletionApplied
                         THEN rawImmuneBeta1 + 2
                         ELSE IF (rawImmuneBeta1 + 2) > suppression
                              THEN (rawImmuneBeta1 + 2) - suppression
                              ELSE 0
  /\ UNCHANGED <<gateRemoved, therapyApplied, effectiveRejections,
                 hubRestored, cascadeBeta1,
                 radiationFractions, totalArrestSignals, senescent, senolyticApplied,
                 viralBlocking, displacementApplied, viralRestoredBeta1,
                 suppression, depletionApplied>>
  /\ step' = step + 1

\* ═══════════════════════════════════════════════════════════════════════════════
\* Next-state relation
\* ═══════════════════════════════════════════════════════════════════════════════

Next ==
  \/ RemoveGate
  \/ ApplyTherapy
  \/ RestoreHub
  \/ DeliverRadiation
  \/ ApplySenolytic
  \/ DisplaceOncoproteins
  \/ DepleteCounterVents
  \/ ApplyImmunotherapy

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* ═══════════════════════════════════════════════════════════════════════════════
\* Invariants
\* ═══════════════════════════════════════════════════════════════════════════════

\* Pred 76: Gate-first sequencing -- therapy without gate removal yields no rejections
InvGateSequencing == (~gateRemoved /\ therapyApplied) => (effectiveRejections = 0)

\* Pred 77: Cascade amplification -- hub restoration produces cascade beta-1 >= 2x hub
InvCascadeAmplification == hubRestored => (cascadeBeta1 >= 6)

\* Pred 78: Senescence trapping -- senolytic only applies after senescence
InvSenescenceTrapping == senolyticApplied => senescent

\* Pred 79: Viral displacement ceiling -- displacement restores full p53+Rb
InvViralDisplacementCeiling == displacementApplied => (viralRestoredBeta1 = 5)

\* Pred 80: Counter-vent depletion -- fully suppressed immune is zero
InvFullySuppressedImmuneZero == (suppression >= rawImmuneBeta1 /\ ~depletionApplied) =>
                                (effectiveImmune = 0)

=============================================================================
