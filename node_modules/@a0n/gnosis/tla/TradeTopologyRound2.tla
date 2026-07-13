--------------------------- MODULE TradeTopologyRound2 ---------------------------
(*
  §19.46 Trade Topology Round 2 -- TLA+ Model Checking

  Five deeper economic predictions from the LEDGER:
    P192: Supply chain disruption cascade amplification
    P193: Market concentration generates failure tax (merger heat)
    P194: Multi-party trade negotiation decomposes as Jackson product-form
    P195: Multi-attribute auction eliminates semiotic deficit
    P196: Currency union increases Tinbergen deficit
*)
EXTENDS Naturals, FiniteSets

VARIABLES
    suppliers,          \* Total potential suppliers
    activeSources,      \* Currently active sources
    supplyDeficit,      \* suppliers - activeSources
    firms,              \* Number of competing firms in market
    failureTax,         \* firms - 1 (cost of monopolization)
    valueDims,          \* Value dimensions in transaction
    priceStreams,       \* Number of price communication channels
    semioticDeficit,    \* valueDims - priceStreams
    sectors,            \* Economic sectors
    instruments,        \* Monetary policy instruments
    tinbergenDeficit,   \* sectors - instruments
    negTerms,           \* Trade negotiation terms
    negRounds           \* Negotiation rounds completed

vars == <<suppliers, activeSources, supplyDeficit, firms, failureTax,
          valueDims, priceStreams, semioticDeficit, sectors, instruments,
          tinbergenDeficit, negTerms, negRounds>>

CONSTANTS
    MaxSuppliers,       \* e.g., 8
    MaxFirms,           \* e.g., 8
    MaxDims,            \* e.g., 6
    MaxSectors,         \* e.g., 10
    MaxNegTerms,        \* e.g., 12
    MaxNegRounds        \* e.g., 20

(* ════════════════════════════════════════════════════════════════════════ *)
(* Initial State                                                           *)
(* ════════════════════════════════════════════════════════════════════════ *)

Init ==
    /\ suppliers = MaxSuppliers
    /\ activeSources = MaxSuppliers
    /\ supplyDeficit = 0
    /\ firms = MaxFirms
    /\ failureTax = MaxFirms - 1
    /\ valueDims = MaxDims
    /\ priceStreams = 1
    /\ semioticDeficit = MaxDims - 1
    /\ sectors = MaxSectors
    /\ instruments = MaxSectors
    /\ tinbergenDeficit = 0
    /\ negTerms = MaxNegTerms
    /\ negRounds = 0

(* ════════════════════════════════════════════════════════════════════════ *)
(* Actions                                                                  *)
(* ════════════════════════════════════════════════════════════════════════ *)

\* Supply chain: lose a supplier (disruption)
SupplierDisruption ==
    /\ activeSources > 1
    /\ activeSources' = activeSources - 1
    /\ supplyDeficit' = suppliers - activeSources'
    /\ UNCHANGED <<suppliers, firms, failureTax, valueDims, priceStreams,
                   semioticDeficit, sectors, instruments, tinbergenDeficit,
                   negTerms, negRounds>>

\* Supply chain: add a supplier (diversification)
AddSupplier ==
    /\ activeSources < suppliers
    /\ activeSources' = activeSources + 1
    /\ supplyDeficit' = suppliers - activeSources'
    /\ UNCHANGED <<suppliers, firms, failureTax, valueDims, priceStreams,
                   semioticDeficit, sectors, instruments, tinbergenDeficit,
                   negTerms, negRounds>>

\* Market: merger (reduce firms by 1)
Merger ==
    /\ firms > 2
    /\ firms' = firms - 1
    /\ failureTax' = firms' - 1
    /\ UNCHANGED <<suppliers, activeSources, supplyDeficit, valueDims,
                   priceStreams, semioticDeficit, sectors, instruments,
                   tinbergenDeficit, negTerms, negRounds>>

\* Price: add a price stream (multi-attribute auction)
AddPriceStream ==
    /\ priceStreams < valueDims
    /\ priceStreams' = priceStreams + 1
    /\ semioticDeficit' = valueDims - priceStreams'
    /\ UNCHANGED <<suppliers, activeSources, supplyDeficit, firms, failureTax,
                   valueDims, sectors, instruments, tinbergenDeficit,
                   negTerms, negRounds>>

\* Currency: form union (reduce instruments)
FormUnion ==
    /\ instruments > 1
    /\ instruments' = instruments - 1
    /\ tinbergenDeficit' = sectors - instruments'
    /\ UNCHANGED <<suppliers, activeSources, supplyDeficit, firms, failureTax,
                   valueDims, priceStreams, semioticDeficit, sectors,
                   negTerms, negRounds>>

\* Negotiation: complete a round
NegotiateRound ==
    /\ negRounds < MaxNegRounds
    /\ negRounds' = negRounds + 1
    /\ UNCHANGED <<suppliers, activeSources, supplyDeficit, firms, failureTax,
                   valueDims, priceStreams, semioticDeficit, sectors,
                   instruments, tinbergenDeficit, negTerms>>

(* ════════════════════════════════════════════════════════════════════════ *)
(* Next-State Relation                                                      *)
(* ════════════════════════════════════════════════════════════════════════ *)

Next ==
    \/ SupplierDisruption
    \/ AddSupplier
    \/ Merger
    \/ AddPriceStream
    \/ FormUnion
    \/ NegotiateRound

Spec == Init /\ [][Next]_vars

(* ════════════════════════════════════════════════════════════════════════ *)
(* Safety Invariants                                                        *)
(* ════════════════════════════════════════════════════════════════════════ *)

TypeOK ==
    /\ suppliers \in 1..MaxSuppliers
    /\ activeSources \in 1..MaxSuppliers
    /\ supplyDeficit \in 0..MaxSuppliers
    /\ firms \in 2..MaxFirms
    /\ failureTax \in 1..(MaxFirms - 1)
    /\ valueDims \in 1..MaxDims
    /\ priceStreams \in 1..MaxDims
    /\ semioticDeficit \in 0..MaxDims
    /\ sectors \in 1..MaxSectors
    /\ instruments \in 1..MaxSectors
    /\ tinbergenDeficit \in 0..MaxSectors
    /\ negTerms \in 1..MaxNegTerms
    /\ negRounds \in 0..MaxNegRounds

\* INV-1: Supply deficit = suppliers - active
InvSupplyDeficit == supplyDeficit = suppliers - activeSources

\* INV-2: Failure tax = firms - 1
InvFailureTax == failureTax = firms - 1

\* INV-3: Semiotic deficit = dims - streams
InvSemioticDeficit == semioticDeficit = valueDims - priceStreams

\* INV-4: Tinbergen deficit = sectors - instruments (non-negative)
InvTinbergenDeficit == tinbergenDeficit = IF sectors >= instruments
                                          THEN sectors - instruments
                                          ELSE 0

\* INV-5: Single-price communication has positive semiotic deficit
InvSinglePricePositive == priceStreams = 1 /\ valueDims >= 2 => semioticDeficit > 0

\* INV-6: Merger tax always positive for competitive markets
InvMergerTaxPositive == firms >= 2 => failureTax > 0

\* INV-7: Active sources bounded by total suppliers
InvActiveBounded == activeSources <= suppliers

\* INV-8: Negotiation rounds monotonically increase
InvNegRoundsBounded == negRounds <= MaxNegRounds

AllInvariants ==
    /\ TypeOK
    /\ InvSupplyDeficit
    /\ InvFailureTax
    /\ InvSemioticDeficit
    /\ InvTinbergenDeficit
    /\ InvSinglePricePositive
    /\ InvMergerTaxPositive
    /\ InvActiveBounded
    /\ InvNegRoundsBounded

=============================================================================
