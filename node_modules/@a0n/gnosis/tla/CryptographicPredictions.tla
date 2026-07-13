----------------------- MODULE CryptographicPredictions -----------------------
\* Formal TLA+ specification of the cryptographic predictions.
\*
\* Five invariants corresponding to the five predictions from §19.28:
\*   1. Hash collision search heat floor is positive
\*   2. Inversion of many-to-one requires side information
\*   3. ZK deficit-zero implies no leakage
\*   4. Commitment dual-witness: hiding implies positive erasure
\*   5. Password hashing side-channel shadow monotone in stretch rounds
\*
\* All five are safety properties checkable by TLC.

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    MaxEvaluations,     \* Maximum hash evaluations (e.g., 10)
    MaxRounds,          \* Maximum stretch rounds (e.g., 8)
    MaxSpaceSize        \* Maximum space size for domain/range (e.g., 16)

VARIABLES
    \* Hash collision search state (Prediction 86)
    hashEvaluations,    \* Number of hash evaluations performed
    perEvalHeat,        \* Heat per evaluation (positive)
    totalHeat,          \* Cumulative heat dissipated

    \* One-way coarsening state (Prediction 87)
    preimageSize,       \* Size of preimage set
    imageSize,          \* Size of image set
    condEntropy,        \* Conditional entropy H(X|f(X))
    sideInfoBits,       \* Side information available for inversion

    \* ZK proof state (Prediction 88)
    witnessPaths,       \* Number of witness paths
    transcriptStreams,  \* Number of transcript streams
    claimDimensions,    \* Claim dimensions
    zkDeficit,          \* Topological deficit of proof system

    \* Commitment fold state (Prediction 89)
    messageSpace,       \* Number of possible messages
    commitErasure,      \* Hiding erasure (conditional entropy)
    bindingCollisions,  \* Number of binding collisions found

    \* Password hashing state (Prediction 90)
    stretchRounds,      \* Current stretch rounds
    sideChannelFloor,   \* Per-evaluation side-channel floor
    cumulativeErasure,  \* Cumulative erasure from hashing

    \* Control
    round               \* Current execution round

vars == <<hashEvaluations, perEvalHeat, totalHeat,
          preimageSize, imageSize, condEntropy, sideInfoBits,
          witnessPaths, transcriptStreams, claimDimensions, zkDeficit,
          messageSpace, commitErasure, bindingCollisions,
          stretchRounds, sideChannelFloor, cumulativeErasure,
          round>>

TypeOK ==
    /\ hashEvaluations \in 0..MaxEvaluations
    /\ perEvalHeat \in 1..MaxSpaceSize
    /\ totalHeat \in 0..(MaxEvaluations * MaxSpaceSize)
    /\ preimageSize \in 1..MaxSpaceSize
    /\ imageSize \in 1..MaxSpaceSize
    /\ condEntropy \in 0..MaxSpaceSize
    /\ sideInfoBits \in 0..MaxSpaceSize
    /\ witnessPaths \in 1..MaxSpaceSize
    /\ transcriptStreams \in 1..MaxSpaceSize
    /\ claimDimensions \in 0..MaxSpaceSize
    /\ zkDeficit \in 0..MaxSpaceSize
    /\ messageSpace \in 2..MaxSpaceSize
    /\ commitErasure \in 0..MaxSpaceSize
    /\ bindingCollisions \in 0..MaxSpaceSize
    /\ stretchRounds \in 1..MaxRounds
    /\ sideChannelFloor \in 1..MaxSpaceSize
    /\ cumulativeErasure \in 0..(MaxRounds * MaxSpaceSize)
    /\ round \in 0..MaxRounds

-----------------------------------------------------------------------------
\* Initial state

Init ==
    /\ hashEvaluations = 0
    /\ perEvalHeat = 1
    /\ totalHeat = 0
    /\ preimageSize = 2
    /\ imageSize = 1
    /\ condEntropy = 1
    /\ sideInfoBits = 0
    /\ witnessPaths = 1
    /\ transcriptStreams = 1
    /\ claimDimensions = 1
    /\ zkDeficit = 0
    /\ messageSpace = 2
    /\ commitErasure = 1
    /\ bindingCollisions = 0
    /\ stretchRounds = 1
    /\ sideChannelFloor = 1
    /\ cumulativeErasure = 1
    /\ round = 0

-----------------------------------------------------------------------------
\* HASH-EVAL: perform a hash evaluation, accumulate heat

HashEval ==
    /\ round < MaxRounds
    /\ hashEvaluations < MaxEvaluations
    /\ hashEvaluations' = hashEvaluations + 1
    /\ totalHeat' = totalHeat + perEvalHeat
    /\ round' = round + 1
    /\ UNCHANGED <<perEvalHeat, preimageSize, imageSize, condEntropy,
                   sideInfoBits, witnessPaths, transcriptStreams,
                   claimDimensions, zkDeficit, messageSpace,
                   commitErasure, bindingCollisions, stretchRounds,
                   sideChannelFloor, cumulativeErasure>>

\* INVERSION-ATTEMPT: try to invert with side information

InversionAttempt ==
    /\ round < MaxRounds
    /\ imageSize < preimageSize
    /\ sideInfoBits' = sideInfoBits + 1
    /\ round' = round + 1
    /\ UNCHANGED <<hashEvaluations, perEvalHeat, totalHeat,
                   preimageSize, imageSize, condEntropy,
                   witnessPaths, transcriptStreams, claimDimensions,
                   zkDeficit, messageSpace, commitErasure,
                   bindingCollisions, stretchRounds, sideChannelFloor,
                   cumulativeErasure>>

\* ZK-TRANSPORT: add a transcript stream, potentially increasing deficit

ZKTransport ==
    /\ round < MaxRounds
    /\ transcriptStreams < MaxSpaceSize
    /\ transcriptStreams' = transcriptStreams + 1
    /\ zkDeficit' = IF transcriptStreams + 1 > claimDimensions
                     THEN transcriptStreams + 1 - claimDimensions
                     ELSE 0
    /\ round' = round + 1
    /\ UNCHANGED <<hashEvaluations, perEvalHeat, totalHeat,
                   preimageSize, imageSize, condEntropy, sideInfoBits,
                   witnessPaths, claimDimensions,
                   messageSpace, commitErasure, bindingCollisions,
                   stretchRounds, sideChannelFloor, cumulativeErasure>>

\* COMMIT: perform a commitment, generating erasure

Commit ==
    /\ round < MaxRounds
    /\ commitErasure' = IF messageSpace > 1 THEN messageSpace - 1 ELSE 0
    /\ round' = round + 1
    /\ UNCHANGED <<hashEvaluations, perEvalHeat, totalHeat,
                   preimageSize, imageSize, condEntropy, sideInfoBits,
                   witnessPaths, transcriptStreams, claimDimensions,
                   zkDeficit, messageSpace, bindingCollisions,
                   stretchRounds, sideChannelFloor, cumulativeErasure>>

\* STRETCH: add stretch rounds to password hash

Stretch ==
    /\ round < MaxRounds
    /\ stretchRounds < MaxRounds
    /\ stretchRounds' = stretchRounds + 1
    /\ cumulativeErasure' = cumulativeErasure + sideChannelFloor
    /\ round' = round + 1
    /\ UNCHANGED <<hashEvaluations, perEvalHeat, totalHeat,
                   preimageSize, imageSize, condEntropy, sideInfoBits,
                   witnessPaths, transcriptStreams, claimDimensions,
                   zkDeficit, messageSpace, commitErasure,
                   bindingCollisions, sideChannelFloor>>

-----------------------------------------------------------------------------
\* Next-state relation

Next ==
    \/ HashEval
    \/ InversionAttempt
    \/ ZKTransport
    \/ Commit
    \/ Stretch

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* INVARIANTS (Safety Properties)

\* Prediction 86: Hash heat floor -- cumulative heat = evaluations * perEvalHeat
InvHashHeatFloor ==
    totalHeat = hashEvaluations * perEvalHeat

\* Prediction 87: Inversion side-info -- many-to-one requires condEntropy > 0
InvInversionSideInfo ==
    imageSize < preimageSize => condEntropy > 0

\* Prediction 88: ZK deficit-zero -- zero deficit means no excess leakage
InvZKDeficitZero ==
    transcriptStreams <= claimDimensions => zkDeficit = 0

\* Prediction 89: Commitment dual-witness -- messageSpace >= 2 implies positive erasure
InvCommitmentDualWitness ==
    messageSpace >= 2 => commitErasure > 0

\* Prediction 90: Password shadow monotone -- more stretch rounds, more cumulative erasure
InvPasswordShadowMonotone ==
    cumulativeErasure >= stretchRounds * sideChannelFloor

=============================================================================
