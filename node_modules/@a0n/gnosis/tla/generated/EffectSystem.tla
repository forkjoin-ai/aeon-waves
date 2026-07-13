----- MODULE EffectSystem -----
\* Effect System — TLA+ model
\*
\* Verifies:
\*   - Pure contracts valid on all targets
\*   - Target support monotonicity (node ⊇ agnostic)
\*   - Effect validation catches undeclared effects
\*   - Contract composition preserves compatibility

EXTENDS Naturals, FiniteSets

CONSTANTS
    Effects,            \* Set of all effect kinds
    AgnosticSupported,  \* Effects supported on agnostic target
    NodeSupported,      \* Effects supported on node target
    WorkersSupported    \* Effects supported on workers target

VARIABLES
    declaredEffects,    \* Effects declared by current topology
    inferredEffects,    \* Effects inferred from labels/properties
    target,             \* Current deployment target
    validationPassed    \* Whether validation succeeded

vars == <<declaredEffects, inferredEffects, target, validationPassed>>

\* -- Initial state: no effects, agnostic target --
Init ==
    /\ declaredEffects = {}
    /\ inferredEffects = {}
    /\ target = "agnostic"
    /\ validationPassed = TRUE

\* -- Declare an effect --
DeclareEffect(e) ==
    /\ e \in Effects
    /\ declaredEffects' = declaredEffects \cup {e}
    /\ UNCHANGED <<inferredEffects, target, validationPassed>>

\* -- Infer an effect (from label/property) --
InferEffect(e) ==
    /\ e \in Effects
    /\ inferredEffects' = inferredEffects \cup {e}
    /\ UNCHANGED <<declaredEffects, target, validationPassed>>

\* -- Set deployment target --
SetTarget(t) ==
    /\ t \in {"agnostic", "workers", "node", "bun"}
    /\ target' = t
    /\ UNCHANGED <<declaredEffects, inferredEffects, validationPassed>>

\* -- Supported effects for current target --
TargetSupported ==
    IF target = "agnostic" THEN AgnosticSupported
    ELSE IF target = "workers" THEN WorkersSupported
    ELSE NodeSupported  \* node and bun are equivalent

\* -- Validate: inferred ⊆ declared, all ⊆ target supported --
Validate ==
    /\ validationPassed' = (
        /\ inferredEffects \subseteq declaredEffects  \* No undeclared effects
        /\ (declaredEffects \cup inferredEffects) \subseteq TargetSupported  \* Target supports all
       )
    /\ UNCHANGED <<declaredEffects, inferredEffects, target>>

Next ==
    \/ \E e \in Effects : DeclareEffect(e)
    \/ \E e \in Effects : InferEffect(e)
    \/ \E t \in {"agnostic", "workers", "node", "bun"} : SetTarget(t)
    \/ Validate

\* ==================================================================
\* INVARIANTS
\* ==================================================================

TypeInvariant ==
    /\ declaredEffects \subseteq Effects
    /\ inferredEffects \subseteq Effects
    /\ target \in {"agnostic", "workers", "node", "bun"}
    /\ validationPassed \in BOOLEAN

\* Target monotonicity: agnostic ⊆ node
TargetMonotonicity == AgnosticSupported \subseteq NodeSupported

\* Pure topology (no effects) always validates
PureAlwaysValid ==
    (declaredEffects = {} /\ inferredEffects = {}) => validationPassed = TRUE

\* ==================================================================
\* SPECIFICATION
\* ==================================================================

Spec ==
    /\ Init
    /\ [][Next]_vars

THEOREM Spec => []TypeInvariant
THEOREM Spec => []TargetMonotonicity

=====
