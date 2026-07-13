----------------------- MODULE DynamicWarmupEfficiency -----------------------
EXTENDS WarmupEfficiency, Naturals

CONSTANTS DecayRateDomain, TurbulenceBuildDomain

VARIABLES decayRate, turbulenceBuild

dynVars == <<vars, decayRate, turbulenceBuild>>

InitDynamic ==
  /\ Init
  /\ decayRate \in DecayRateDomain
  /\ turbulenceBuild \in TurbulenceBuildDomain
  /\ decayRate > 0
  /\ turbulenceBuild > 0
  /\ decayRate > seqCap - busy
  /\ wallaceWeight * (seqCap - busy) > buleyRise * seqCap

\* Active cooling applies the warm-up when the burden threshold says the
\* optimization is spontaneous enough to justify the restructuring cost.
ActiveCooling ==
  /\ WorthWarmup
  /\ overlap' = IF overlap >= decayRate
                THEN overlap - decayRate
                ELSE 0
  /\ UNCHANGED <<busy, seqCap, buleyRise, wallaceWeight, decayRate, turbulenceBuild>>

\* When warm-up is not yet worth it, entropy creeps back into the boundary layer
\* until the system reaches the point where cooling becomes favorable.
EntropyCreep ==
  /\ ~WorthWarmup
  /\ overlap' = IF overlap + turbulenceBuild <= seqCap - busy
                THEN overlap + turbulenceBuild
                ELSE seqCap - busy
  /\ UNCHANGED <<busy, seqCap, buleyRise, wallaceWeight, decayRate, turbulenceBuild>>

NextDynamic == ActiveCooling \/ EntropyCreep

SpecDynamic ==
  InitDynamic /\
    [][NextDynamic]_dynVars /\
    WF_dynVars(ActiveCooling) /\
    WF_dynVars(EntropyCreep)

InvOverlapBounded ==
  /\ overlap >= 0
  /\ overlap <= seqCap - busy

InvDynamicAssumptions ==
  /\ decayRate > 0
  /\ turbulenceBuild > 0
  /\ decayRate > seqCap - busy
  /\ wallaceWeight * (seqCap - busy) > buleyRise * seqCap

InvWarmCapBounded ==
  /\ WarmCap >= busy
  /\ WarmCap <= seqCap

InvMaxOverlapTriggersCooling ==
  overlap = seqCap - busy => WorthWarmup

PropEventualLaminar ==
  <> (overlap = 0)

=============================================================================
