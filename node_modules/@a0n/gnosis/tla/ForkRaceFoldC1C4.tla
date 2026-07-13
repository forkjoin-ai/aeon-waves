------------------------------ MODULE ForkRaceFoldC1C4 ------------------------------
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS ItemCount, StageCount, BranchCount, MaxTime

VARIABLES pipeQ, done, bStatus, bSeq, bOut, time, folded, foldOut

vars == <<pipeQ, done, bStatus, bSeq, bOut, time, folded, foldOut>>

Branches == 1..BranchCount

RECURSIVE RangeSeq(_)
RangeSeq(n) == IF n = 0 THEN <<>> ELSE RangeSeq(n - 1) \o <<n>>

IsPrefix(prefix, full) ==
  /\ Len(prefix) <= Len(full)
  /\ \A i \in 1..Len(prefix): prefix[i] = full[i]

RECURSIVE MergeUpTo(_, _, _)
MergeUpTo(i, status, outputs) ==
  IF i = 0 THEN <<>>
  ELSE MergeUpTo(i - 1, status, outputs)
       \o IF status[i] = "done" THEN outputs[i] ELSE <<>>

DeterministicMerge(status, outputs) == MergeUpTo(BranchCount, status, outputs)

Init ==
  /\ pipeQ = [s \in 1..StageCount |-> IF s = 1 THEN RangeSeq(ItemCount) ELSE <<>>]
  /\ done = <<>>
  /\ bStatus = [b \in Branches |-> "active"]
  /\ bSeq = [b \in Branches |-> 1]
  /\ bOut = [b \in Branches |-> <<>>]
  /\ time = 0
  /\ folded = FALSE
  /\ foldOut = <<>>

PipeAdvance(s) ==
  /\ s \in 1..(StageCount - 1)
  /\ Len(pipeQ[s]) > 0
  /\ LET item == Head(pipeQ[s]) IN
       /\ pipeQ' = [pipeQ EXCEPT ![s] = Tail(@), ![s + 1] = Append(@, item)]
       /\ UNCHANGED <<done, bStatus, bSeq, bOut, time, folded, foldOut>>

PipeFinish ==
  /\ Len(pipeQ[StageCount]) > 0
  /\ LET item == Head(pipeQ[StageCount]) IN
       /\ pipeQ' = [pipeQ EXCEPT ![StageCount] = Tail(@)]
       /\ done' = Append(done, item)
       /\ UNCHANGED <<bStatus, bSeq, bOut, time, folded, foldOut>>

Work(b) ==
  /\ b \in Branches
  /\ bStatus[b] = "active"
  /\ bSeq[b] <= ItemCount
  /\ bOut' = [bOut EXCEPT ![b] = Append(@, (b * 100) + bSeq[b])]
  /\ bSeq' = [bSeq EXCEPT ![b] = @ + 1]
  /\ UNCHANGED <<pipeQ, done, bStatus, time, folded, foldOut>>

Complete(b) ==
  /\ b \in Branches
  /\ bStatus[b] = "active"
  /\ bSeq[b] > ItemCount
  /\ bStatus' = [bStatus EXCEPT ![b] = "done"]
  /\ UNCHANGED <<pipeQ, done, bSeq, bOut, time, folded, foldOut>>

Vent(b) ==
  /\ b \in Branches
  /\ bStatus[b] = "active"
  /\ bStatus' = [bStatus EXCEPT ![b] = "vented"]
  /\ UNCHANGED <<pipeQ, done, bSeq, bOut, time, folded, foldOut>>

Tick ==
  /\ time < MaxTime
  /\ time' = time + 1
  /\ bStatus' =
       IF time' = MaxTime
       THEN [b \in Branches |-> IF bStatus[b] = "active" THEN "vented" ELSE bStatus[b]]
       ELSE bStatus
  /\ UNCHANGED <<pipeQ, done, bSeq, bOut, folded, foldOut>>

Fold ==
  /\ ~folded
  /\ \A b \in Branches: bStatus[b] # "active"
  /\ folded' = TRUE
  /\ foldOut' = DeterministicMerge(bStatus, bOut)
  /\ UNCHANGED <<pipeQ, done, bStatus, bSeq, bOut, time>>

Stutter == UNCHANGED vars

Next ==
  \/ \E s \in 1..(StageCount - 1): PipeAdvance(s)
  \/ PipeFinish
  \/ \E b \in Branches: Work(b)
  \/ \E b \in Branches: Complete(b)
  \/ \E b \in Branches: Vent(b)
  \/ Tick
  \/ Fold
  \/ Stutter

Spec ==
  Init
    /\ [][Next]_vars
    /\ WF_vars(Tick)
    /\ WF_vars(Fold)

C1_Locality == IsPrefix(done, RangeSeq(ItemCount))

C2_BranchIsolation ==
  \A b \in Branches:
    \A i \in 1..Len(bOut[b]): bOut[b][i] = (b * 100) + i

C3_DeterministicFold ==
  folded => foldOut = DeterministicMerge(bStatus, bOut)

C4_BoundedTermination ==
  time = MaxTime => \A b \in Branches: bStatus[b] # "active"

Termination == <>folded

=============================================================================
