----- MODULE ContinuousHarris -----
\* Continuous Harris Certificate Synthesis — TLA+ model
\*
\* Verifies:
\*   - Synthesis pipeline: observable → small set → lyapunov → minorization → certificate
\*   - Drift condition: λ < 1 (contractive)
\*   - Minorization: ε > 0 (positive)
\*   - Certificate completeness: all components present

EXTENDS Naturals, Reals

CONSTANTS
    NumNodes,       \* Number of state nodes
    MaxDriftGap     \* Maximum drift gap parameter

VARIABLES
    observableInferred,     \* Whether observable has been inferred
    smallSetSynthesized,    \* Whether small set has been synthesized
    lyapunovSynthesized,    \* Whether Lyapunov function has been synthesized
    minorizationSynthesized,\* Whether minorization has been synthesized
    certificateComplete,    \* Whether full certificate is assembled
    lambda,                 \* Drift contraction rate (must be < 1)
    epsilon,                \* Minorization constant (must be > 0)
    verified                \* Whether certificate has been verified

vars == <<observableInferred, smallSetSynthesized, lyapunovSynthesized,
          minorizationSynthesized, certificateComplete, lambda, epsilon, verified>>

Init ==
    /\ observableInferred = FALSE
    /\ smallSetSynthesized = FALSE
    /\ lyapunovSynthesized = FALSE
    /\ minorizationSynthesized = FALSE
    /\ certificateComplete = FALSE
    /\ lambda = 1  \* Not yet contractive
    /\ epsilon = 0 \* Not yet positive
    /\ verified = FALSE

\* -- Step 1: Infer observable from node properties --
InferObservable ==
    /\ ~observableInferred
    /\ observableInferred' = TRUE
    /\ UNCHANGED <<smallSetSynthesized, lyapunovSynthesized, minorizationSynthesized,
                   certificateComplete, lambda, epsilon, verified>>

\* -- Step 2: Synthesize small set from observable --
SynthesizeSmallSet ==
    /\ observableInferred
    /\ ~smallSetSynthesized
    /\ smallSetSynthesized' = TRUE
    /\ UNCHANGED <<observableInferred, lyapunovSynthesized, minorizationSynthesized,
                   certificateComplete, lambda, epsilon, verified>>

\* -- Step 3: Synthesize Lyapunov function --
SynthesizeLyapunov ==
    /\ observableInferred
    /\ ~lyapunovSynthesized
    /\ lyapunovSynthesized' = TRUE
    /\ lambda' = 1 - 1  \* lambda = 1 - driftGap, simplified
    /\ UNCHANGED <<observableInferred, smallSetSynthesized, minorizationSynthesized,
                   certificateComplete, epsilon, verified>>

\* -- Step 4: Synthesize minorization --
SynthesizeMinorization ==
    /\ smallSetSynthesized
    /\ ~minorizationSynthesized
    /\ minorizationSynthesized' = TRUE
    /\ epsilon' = 1  \* Positive minorization constant
    /\ UNCHANGED <<observableInferred, smallSetSynthesized, lyapunovSynthesized,
                   certificateComplete, lambda, verified>>

\* -- Step 5: Assemble certificate --
AssembleCertificate ==
    /\ observableInferred
    /\ smallSetSynthesized
    /\ lyapunovSynthesized
    /\ minorizationSynthesized
    /\ ~certificateComplete
    /\ certificateComplete' = TRUE
    /\ verified' = (lambda < 1 /\ epsilon > 0)
    /\ UNCHANGED <<observableInferred, smallSetSynthesized, lyapunovSynthesized,
                   minorizationSynthesized, lambda, epsilon>>

Next ==
    \/ InferObservable
    \/ SynthesizeSmallSet
    \/ SynthesizeLyapunov
    \/ SynthesizeMinorization
    \/ AssembleCertificate

\* ==================================================================
\* INVARIANTS
\* ==================================================================

TypeInvariant ==
    /\ observableInferred \in BOOLEAN
    /\ smallSetSynthesized \in BOOLEAN
    /\ lyapunovSynthesized \in BOOLEAN
    /\ minorizationSynthesized \in BOOLEAN
    /\ certificateComplete \in BOOLEAN
    /\ verified \in BOOLEAN

\* Pipeline ordering: each step requires its prerequisite
PipelineOrdering ==
    /\ (smallSetSynthesized => observableInferred)
    /\ (minorizationSynthesized => smallSetSynthesized)
    /\ (certificateComplete => observableInferred /\ smallSetSynthesized
                             /\ lyapunovSynthesized /\ minorizationSynthesized)

\* Verified certificate has contractive drift and positive minorization
VerifiedImpliesSound ==
    verified => (lambda < 1 /\ epsilon > 0)

\* ==================================================================
\* LIVENESS
\* ==================================================================

EventuallyCertified == <>(certificateComplete)
DeadlockFree == []<>(ENABLED Next)

\* ==================================================================
\* SPECIFICATION
\* ==================================================================

Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ WF_vars(Next)

THEOREM Spec => []TypeInvariant
THEOREM Spec => []PipelineOrdering
THEOREM Spec => []VerifiedImpliesSound

=====
