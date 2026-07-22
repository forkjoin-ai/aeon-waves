----------------------------- MODULE HeteroMoAFabricWaste -----------------------------
EXTENDS Naturals

CONSTANTS MaxBytes, MaxSequence, MaxScheduledShadows, HeaderBytes

VARIABLES checked, byteConservationOk, skippedBudgetOk, sequenceOk, frameOk

vars == <<checked, byteConservationOk, skippedBudgetOk, sequenceOk, frameOk>>

ConservedAccounting(winnerBytes, loserBytes, ventBytes, totalBytes) ==
  winnerBytes + loserBytes + ventBytes = totalBytes

SkippedWithinBudget(skippedHedges, scheduledShadows) ==
  skippedHedges <= scheduledShadows

MonotoneSequence(seq, nextSeq) ==
  seq <= nextSeq

FrameBytes(payloadBytes) ==
  HeaderBytes + payloadBytes

Init ==
  /\ checked = FALSE
  /\ byteConservationOk = TRUE
  /\ skippedBudgetOk = TRUE
  /\ sequenceOk = TRUE
  /\ frameOk = TRUE

CheckAll ==
  /\ ~checked
  /\ checked' = TRUE
  /\ byteConservationOk' =
      \A winnerBytes \in 0..MaxBytes,
         loserBytes \in 0..MaxBytes,
         ventBytes \in 0..MaxBytes:
        ConservedAccounting(
          winnerBytes,
          loserBytes,
          ventBytes,
          winnerBytes + loserBytes + ventBytes
        )
  /\ skippedBudgetOk' =
      \A scheduledShadows \in 0..MaxScheduledShadows,
         skippedHedges \in 0..scheduledShadows:
        SkippedWithinBudget(skippedHedges, scheduledShadows)
  /\ sequenceOk' =
      \A seq \in 0..MaxSequence, delta \in 0..MaxSequence:
        MonotoneSequence(seq, seq + delta)
  /\ frameOk' =
      /\ HeaderBytes = 10
      /\ \A payloadBytes \in 0..MaxBytes: FrameBytes(payloadBytes) >= HeaderBytes

Stutter ==
  UNCHANGED vars

Next ==
  CheckAll \/ Stutter

Spec ==
  Init /\ [][Next]_vars /\ WF_vars(CheckAll)

InvByteConservation ==
  checked => byteConservationOk

InvSkippedWithinBudget ==
  checked => skippedBudgetOk

InvMonotoneSequence ==
  checked => sequenceOk

InvFrameSize ==
  checked => frameOk

=============================================================================
