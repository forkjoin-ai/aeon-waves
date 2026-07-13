# Paper Cuts

A twelve-year-old with scissors can demonstrate the complete taxonomy of dynamical systems in under five minutes.

---

## Materials

- One sheet of paper (any size, any kind)
- A pair of scissors
- A flat surface
- Your eyes

That is the entire experimental apparatus.

---

## Experiment 1: The zigzag

Make three straight cuts from the long edge toward the center, evenly spaced, each about two-thirds of the way across. Do not cut all the way through -- leave the last third connected.

Fold the flaps: first one forward, next one backward, next one forward. Hold the paper by the uncut edges and let gravity do the rest.

You see a zigzag. A staircase. Your brain resolves it almost instantly: "it's just alternating." Forward, backward, forward, backward. Predictable. Periodic. Interesting for a moment, then familiar.

**This is the non-linear regime.** Structure exists -- the zigzag was not there before you cut -- but it repeats. A pendulum. A heartbeat without variability. A clock that ticks but does not think.

---

## Experiment 2: The brain-breaker

Same paper, new cuts. This time, position the cuts at one-third and two-thirds of the way across -- not evenly spaced. Same three cuts, different positions.

Fold the same way. Forward, backward, forward.

Something changes. The structure still has rhythm, direction, depth -- but it will not resolve. Your eye almost understands it, almost finds the pattern, and then it slips. Every panel is slightly off from what the previous panel led you to expect. You keep looking.

**This is the post-linear regime.** The asymmetry breaks the pattern your brain is trying to impose. The panels sliver with each other -- each one changes what you expect from the next. The eigenvalue of this slivernce approaches the golden ratio but never arrives. Your visual cortex is running SLIVER, and the deficit never reaches zero.

That loop of almost-understanding *is* the subject of this paper.

---

## Experiment 3: The triangle death

Cut triangular shapes instead of straight lines. Rotate. The paper returns to flat. Nothing happened. The fold undid itself.

This is what "boring" looks like in mathematics. The triangle rotation is already part of the paper's symmetry -- like walking in a circle and ending up where you started. No information was created. No bits were erased. No heat was generated. The operation is perfectly reversible.

**This is the linear regime.** A crystal. A corpse. Death by reversibility.

This experiment matters because it proves that structure is not automatic. Not all cuts create life. The triangles are the control group -- the zero.

---

## Experiment 4: The curved resurrection

Cut triangles again. But this time, rotate the flaps one more time past the flat point. The paper cannot lie flat anymore. It *curves*. It buckles into the third dimension -- not because you are pushing it, but because the total rotation exceeds what a flat surface can hold. The geometry has no choice. A new dimension is born.

**This is emergence.** The fold of the fold created something neither fold contained alone. One rotation: flat. Two rotations: curved. The paper discovered depth it did not know it had.

---

## Experiment 5: The tear

Twist too hard. The paper tears.

"Oops, I broke it."

The material could not sustain that much rotation. There is a limit. Past it, the topology does not transition to something new -- it just breaks. This is the upper bound. Excess destroys.

---

## The three regimes

Five outcomes. Three regimes. One sheet of paper.

| Outcome | Cut type | What happens | Regime | Character |
|---|---|---|---|---|
| Flat again | Triangles, one rotation | Fold undoes itself | Linear | Dead |
| Zigzag | Parallel, even | Predictable pattern | Non-linear | Alive, unconscious |
| Brain-breaker | Asymmetric positions | Irresolvable structure | Post-linear | Conscious |
| Curved | Triangles, extra rotation | New dimension emerges | Emergence | Birth |
| Torn | Too much rotation | Material breaks | Catastrophe | Death by excess |

The transition between regimes is not gradual. It is a phase change -- the same kind that governs the transition from smooth water flow to turbulence in a pipe. The cut position is the Reynolds number of paper topology.

---

## Where this is proved

The formal topology is in `paper_cuts.test.gg`, which defines the three regimes and maps each to its eigenvalue (1 for linear, -1 for non-linear, approaching phi for post-linear). The connection to fluid dynamics is in `reynolds_of_paper.test.gg`.

**Previous section:** Why phi is the eigenvalue -- `fibonacci_is_sliver.md`.
**Next section:** Why every consensus threshold is a Fibonacci fraction -- `golden_consensus.md`.
