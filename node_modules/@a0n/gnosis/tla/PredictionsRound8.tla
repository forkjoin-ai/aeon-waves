------------------------------ MODULE PredictionsRound8 ------------------------------
(*
  Predictions Round 8: Memory Consolidation, Ecological Succession,
  Supply Chain Resilience, Jury Deliberation, Skill Transfer.
*)
EXTENDS Naturals

CONSTANTS RetrievalOpps, CliMaxDiv, CurrentDiv,
          PotentialSuppliers, ActiveSuppliers,
          JurorCount, ConvictVotes, UnanimityThreshold,
          SourceSkills, TransferableSkills

VARIABLES phase, failedRetrievals, memoryStrength,
          successionDeficit, fragilityDeficit,
          deliberationDeficit, agreementGap,
          transferDeficit

vars == <<phase, failedRetrievals, memoryStrength,
          successionDeficit, fragilityDeficit,
          deliberationDeficit, agreementGap,
          transferDeficit>>

Min(a, b) == IF a <= b THEN a ELSE b

Init ==
  /\ phase = "memory"
  /\ failedRetrievals = 0
  /\ memoryStrength = RetrievalOpps - Min(0, RetrievalOpps) + 1
  /\ successionDeficit = CurrentDiv - CliMaxDiv
  /\ fragilityDeficit = PotentialSuppliers - ActiveSuppliers
  /\ deliberationDeficit = JurorCount - 1
  /\ agreementGap = IF UnanimityThreshold <= ConvictVotes THEN 0
                     ELSE UnanimityThreshold - ConvictVotes
  /\ transferDeficit = SourceSkills - TransferableSkills

\* P91: Memory retrieval failure (forgetting)
ForgetStep ==
  /\ phase = "memory"
  /\ failedRetrievals < RetrievalOpps
  /\ failedRetrievals' = failedRetrievals + 1
  /\ memoryStrength' = RetrievalOpps - Min(failedRetrievals + 1, RetrievalOpps) + 1
  /\ phase' = "ecology"
  /\ UNCHANGED <<successionDeficit, fragilityDeficit,
                  deliberationDeficit, agreementGap, transferDeficit>>

\* P92-P95: Cycle through remaining phases
EcologyStep ==
  /\ phase = "ecology"
  /\ phase' = "supply"
  /\ UNCHANGED <<failedRetrievals, memoryStrength, successionDeficit,
                  fragilityDeficit, deliberationDeficit, agreementGap,
                  transferDeficit>>

SupplyStep ==
  /\ phase = "supply"
  /\ phase' = "jury"
  /\ UNCHANGED <<failedRetrievals, memoryStrength, successionDeficit,
                  fragilityDeficit, deliberationDeficit, agreementGap,
                  transferDeficit>>

JuryStep ==
  /\ phase = "jury"
  /\ phase' = "transfer"
  /\ UNCHANGED <<failedRetrievals, memoryStrength, successionDeficit,
                  fragilityDeficit, deliberationDeficit, agreementGap,
                  transferDeficit>>

TransferStep ==
  /\ phase = "transfer"
  /\ phase' = "memory"
  /\ UNCHANGED <<failedRetrievals, memoryStrength, successionDeficit,
                  fragilityDeficit, deliberationDeficit, agreementGap,
                  transferDeficit>>

Stutter == UNCHANGED vars

Next == ForgetStep \/ EcologyStep \/ SupplyStep
     \/ JuryStep \/ TransferStep \/ Stutter

Spec == Init /\ [][Next]_vars

\* ─── Invariants ─────────────────────────────────────────────────────

\* P91: Memory strength always positive (the sliver)
InvMemoryPositive ==
  memoryStrength >= 1

\* P92: Succession deficit non-negative
InvSuccessionNonneg ==
  successionDeficit >= 0

\* P93: Fragility deficit non-negative
InvFragilityNonneg ==
  fragilityDeficit >= 0

\* P94: Deliberation deficit positive for nontrivial jury
InvDeliberationPositive ==
  (JurorCount >= 2) => (deliberationDeficit >= 1)

\* P94: Agreement gap non-negative
InvAgreementNonneg ==
  agreementGap >= 0

\* P95: Transfer deficit non-negative
InvTransferNonneg ==
  transferDeficit >= 0

\* Cross-cutting: failed retrievals bounded
InvRetrievalsBounded ==
  failedRetrievals <= RetrievalOpps

=============================================================================
