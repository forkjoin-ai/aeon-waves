------------------------------ MODULE MonoidalCoherence ------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* Monoidal coherence for the fork/race/fold category: verifies that the
\* pentagon, triangle, and hexagon identities hold for all small-valued
\* object tuples.  These are the three generator identities from which
\* Mac Lane's coherence theorem (every well-typed diagram commutes) follows.
\*
\* THM-PENTAGON:  Two paths ((A⊗B)⊗C)⊗D → A⊗(B⊗(C⊗D)) agree.
\* THM-TRIANGLE:  (A⊗I)⊗B → A⊗B via associator+unitor = direct unitor.
\* THM-HEXAGON:   Two braiding paths agree.

CONSTANTS ObjSet, UnitObj

VARIABLES a, b, c, d, checked,
          pentagonOk, triangleOk, hexagonOk,
          monoidalOk, symmetricOk

vars == <<a, b, c, d, checked,
          pentagonOk, triangleOk, hexagonOk,
          monoidalOk, symmetricOk>>

\* ─── Tensor product (Cartesian pair) ─────────────────────────────────
Tensor(x, y) == <<x, y>>

\* ─── Associator ──────────────────────────────────────────────────────
\* assocLR: ((A⊗B)⊗C) → (A⊗(B⊗C))
AssocLR(triple) == <<triple[1][1], <<triple[1][2], triple[2]>>>>

\* assocRL: (A⊗(B⊗C)) → ((A⊗B)⊗C)
AssocRL(triple) == <<<<triple[1], triple[2][1]>>, triple[2][2]>>

\* ─── Unitors ─────────────────────────────────────────────────────────
\* leftUnitor: (I⊗A) → A
LeftUnitor(pair) == pair[2]

\* rightUnitor: (A⊗I) → A
RightUnitor(pair) == pair[1]

\* ─── Braiding ────────────────────────────────────────────────────────
\* braid: (A⊗B) → (B⊗A)
Braid(pair) == <<pair[2], pair[1]>>

\* ─── tensorHom (id⊗f and f⊗id) ──────────────────────────────────────
TensorIdLeft(f(_), pair) == <<pair[1], f(pair[2])>>
TensorIdRight(f(_), pair) == <<f(pair[1]), pair[2]>>

\* ═══════════════════════════════════════════════════════════════════════
\* Pentagon identity
\*
\* Path 1: ((A⊗B)⊗C)⊗D ─assocLR──→ (A⊗B)⊗(C⊗D) ─assocLR──→ A⊗(B⊗(C⊗D))
\*
\* Path 2: ((A⊗B)⊗C)⊗D ─assocLR⊗id→ (A⊗(B⊗C))⊗D ─assocLR──→ A⊗((B⊗C)⊗D)
\*                                                   ─id⊗assocLR→ A⊗(B⊗(C⊗D))
\* ═══════════════════════════════════════════════════════════════════════

PentagonPath1(va, vb, vc, vd) ==
  LET start == Tensor(Tensor(Tensor(va, vb), vc), vd)
      step1 == AssocLR(<<start[1], start[2]>>)       \* (A⊗B)⊗(C⊗D)
      step2 == AssocLR(step1)                          \* A⊗(B⊗(C⊗D))
  IN step2

PentagonPath2(va, vb, vc, vd) ==
  LET start     == Tensor(Tensor(Tensor(va, vb), vc), vd)
      inner     == AssocLR(start[1])                   \* A⊗(B⊗C)
      step1     == Tensor(inner, vd)                   \* (A⊗(B⊗C))⊗D
      step2     == AssocLR(step1)                       \* A⊗((B⊗C)⊗D)
      finalPair == AssocLR(step2[2])                    \* (B⊗C)⊗D → B⊗(C⊗D)
      step3     == Tensor(step2[1], finalPair)          \* A⊗(B⊗(C⊗D))
  IN step3

PentagonHoldsFor(va, vb, vc, vd) ==
  PentagonPath1(va, vb, vc, vd) = PentagonPath2(va, vb, vc, vd)

\* ═══════════════════════════════════════════════════════════════════════
\* Triangle identity
\*
\* (A⊗I)⊗B ─assocLR──→ A⊗(I⊗B) ─id⊗leftUnitor→ A⊗B
\*          ─rightUnitor⊗id───────────────────────→ A⊗B
\* ═══════════════════════════════════════════════════════════════════════

TrianglePath1(va, vb) ==
  LET start == Tensor(Tensor(va, UnitObj), vb)
      step1 == AssocLR(start)                          \* A⊗(I⊗B)
      step2 == Tensor(step1[1], LeftUnitor(step1[2]))  \* A⊗B
  IN step2

TrianglePath2(va, vb) ==
  LET start == Tensor(Tensor(va, UnitObj), vb)
      step1 == Tensor(RightUnitor(start[1]), vb)       \* A⊗B
  IN step1

TriangleHoldsFor(va, vb) ==
  TrianglePath1(va, vb) = TrianglePath2(va, vb)

\* ═══════════════════════════════════════════════════════════════════════
\* Hexagon identity (first hexagon axiom for symmetric monoidal)
\*
\* Path 1: (A⊗B)⊗C ─assocLR──→ A⊗(B⊗C) ─braid──→ (B⊗C)⊗A
\*                                         ─assocLR→ B⊗(C⊗A)
\*
\* Path 2: (A⊗B)⊗C ─braid⊗id→ (B⊗A)⊗C ─assocLR──→ B⊗(A⊗C)
\*                                         ─id⊗braid→ B⊗(C⊗A)
\* ═══════════════════════════════════════════════════════════════════════

HexagonPath1(va, vb, vc) ==
  LET start == Tensor(Tensor(va, vb), vc)
      step1 == AssocLR(start)                          \* A⊗(B⊗C)
      step2 == Braid(step1)                            \* (B⊗C)⊗A
      step3 == AssocLR(step2)                          \* B⊗(C⊗A)
  IN step3

HexagonPath2(va, vb, vc) ==
  LET start    == Tensor(Tensor(va, vb), vc)
      swapped  == Braid(start[1])                      \* (B⊗A)
      step1    == Tensor(swapped, vc)                  \* (B⊗A)⊗C
      step2    == AssocLR(step1)                       \* B⊗(A⊗C)
      innerSw  == Braid(step2[2])                      \* (C⊗A)
      step3    == Tensor(step2[1], innerSw)            \* B⊗(C⊗A)
  IN step3

HexagonHoldsFor(va, vb, vc) ==
  HexagonPath1(va, vb, vc) = HexagonPath2(va, vb, vc)

\* ─── Init ────────────────────────────────────────────────────────────
Init ==
  /\ a = CHOOSE x \in ObjSet : TRUE
  /\ b = CHOOSE x \in ObjSet : TRUE
  /\ c = CHOOSE x \in ObjSet : TRUE
  /\ d = CHOOSE x \in ObjSet : TRUE
  /\ checked = FALSE
  /\ pentagonOk = TRUE
  /\ triangleOk = TRUE
  /\ hexagonOk = TRUE
  /\ monoidalOk = TRUE
  /\ symmetricOk = TRUE

\* ─── Check all tuples ────────────────────────────────────────────────
CheckAll ==
  /\ ~checked
  /\ pentagonOk' = \A va \in ObjSet, vb \in ObjSet, vc \in ObjSet, vd \in ObjSet:
       PentagonHoldsFor(va, vb, vc, vd)
  /\ triangleOk' = \A va \in ObjSet, vb \in ObjSet:
       TriangleHoldsFor(va, vb)
  /\ hexagonOk' = \A va \in ObjSet, vb \in ObjSet, vc \in ObjSet:
       HexagonHoldsFor(va, vb, vc)
  /\ monoidalOk' = pentagonOk' /\ triangleOk'
  /\ symmetricOk' = monoidalOk' /\ hexagonOk'
  /\ checked' = TRUE
  /\ UNCHANGED <<a, b, c, d>>

Stutter == UNCHANGED vars

Next == CheckAll \/ Stutter

Spec == Init /\ [][Next]_vars /\ WF_vars(CheckAll)

\* ─── Invariants ──────────────────────────────────────────────────────

\* THM-PENTAGON: both associator paths agree for all 4-tuples
InvPentagon ==
  checked => pentagonOk

\* THM-TRIANGLE: associator+unitor path = direct unitor path
InvTriangle ==
  checked => triangleOk

\* THM-HEXAGON: both braiding paths agree for all 3-tuples
InvHexagon ==
  checked => hexagonOk

\* Monoidal category bundle: pentagon + triangle
InvMonoidalCategory ==
  checked => monoidalOk

\* Symmetric monoidal: monoidal + hexagon
InvSymmetricMonoidal ==
  checked => symmetricOk

\* Mac Lane coherence: pentagon + triangle generate all coherence —
\* every well-typed diagram of associators/unitors commutes
InvCoherence ==
  checked => (pentagonOk /\ triangleOk /\ hexagonOk)

\* Associator roundtrip: assocLR ∘ assocRL = id
InvAssocRoundtrip ==
  \A va \in ObjSet, vb \in ObjSet, vc \in ObjSet:
    AssocRL(AssocLR(Tensor(Tensor(va, vb), vc))) = Tensor(Tensor(va, vb), vc)

\* Braid involution: braid ∘ braid = id
InvBraidInvolution ==
  \A va \in ObjSet, vb \in ObjSet:
    Braid(Braid(Tensor(va, vb))) = Tensor(va, vb)

=============================================================================
