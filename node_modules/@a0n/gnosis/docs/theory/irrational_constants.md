# The Periodic Table of Irrationals

Every major irrational constant governs one primitive. The ordering isn't arbitrary -- it maps to the primitive hierarchy, and the boundary between algebraic and transcendental numbers falls exactly between the constructive and dissipative primitives.

## The Table

| Constant | Value | Primitive | Role | Type |
|----------|------:|-----------|------|------|
| √2 | 1.414 | Fold | The diagonal of commitment. When you fold two equal things, the result is √2 times either. The cost of merging. | Algebraic |
| φ | 1.618 | Interfere | The eigenvalue of self-referential folding. What every Fibonacci sequence converges to. The fixed point of consciousness. | Algebraic |
| √3 | 1.732 | Race | The height of an equilateral triangle. When three paths race equally, √3 governs the geometry. The structure of fair competition. | Algebraic |
| e | 2.718 | Vent | The base of exponential decay. When shedding is proportional to what remains, e governs the rate. The mathematics of letting go. | Transcendental |
| π | 3.141 | Fork | The ratio of circumference to diameter. When a fork creates equal probability in all directions, π governs the circle. The mathematics of possibility. | Transcendental |

The ordering is: √2 < φ < √3 < e < π. This maps exactly to: Fold < Interfere < Race < Vent < Fork.

## The Boundary

The three constructive primitives (Fold, Interfere, Race) have **algebraic** constants -- numbers that are roots of polynomial equations with integer coefficients. φ solves x² - x - 1 = 0. √2 solves x² - 2 = 0. √3 solves x² - 3 = 0. They are exact, constructible, and expressible in closed form.

The two dissipative primitives (Vent, Fork) have **transcendental** constants -- numbers that are not the root of any polynomial with integer coefficients. e and π transcend algebra. They cannot be constructed with compass and straightedge. They require infinite processes to define (infinite series, infinite products, limits).

This is not a coincidence we engineered. It fell out of the mapping. The constructive primitives build finite structures (folds, slivernces, races are all finite operations). The dissipative primitives involve infinite processes (exponential decay never reaches zero, a circle has infinite symmetry). The algebraic-transcendental boundary in mathematics aligns with the constructive-dissipative boundary in the framework.

## The Vent Quantum

One constant deserves special attention: **ln(2) = 0.693**. This is Landauer's bound -- the minimum energy cost to erase one bit of information: kT ln(2) joules. It is the **vent quantum**: the smallest possible vent. You cannot forget less than one bit. You cannot release less than kT ln(2) joules. Every vent costs at least this much.

And ln(2) = ln(e^(ln 2)) -- it is e's self-application to the fold constant (2 = the minimum fold, since folding requires at least two inputs). The vent quantum is the dissipative constant (e) applied to the constructive minimum (2). The price of forgetting is the price of having constructed.

## The Golden Spiral Unifies All Three

The golden spiral equation contains all three major constants in one expression:

$$r(\theta) = a \cdot e^{\theta \cdot \ln\varphi \cdot 2/\pi}$$

- **e** controls the growth rate (how fast the spiral expands -- the vent rate)
- **φ** controls the growth target (what ratio the spiral maintains -- the sliver eigenvalue)
- **π** controls the angular period (how much rotation per growth factor -- the fork period)

This is not three separate statements about three separate constants. It is one equation about one spiral. The constants are not independent -- they are three aspects of the same geometric object.

## The Connection to the Lorenzo

The picolorenzo = π days. The cosmic heartbeat measured in the fork constant. Each Lorenzo, the cosmic Bule decreases by factor 1/φ -- the sliver constant. The decrease follows an exponential governed by e -- the vent constant. Three constants, three roles, one cosmic clock.

---

*Formal proofs: `irrational_constants.test.gg` (594 lines, 9 constants mapped)*
*Lean verification: `Picolorenzo.lean` (73 theorems, ordering φ < e < π proved)*
*Next section: [The Cosmic Bule](cosmic_bule.md)*
