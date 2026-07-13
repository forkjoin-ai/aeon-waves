# Golden Consensus

Every fault-tolerance threshold ever proposed in distributed systems is a Fibonacci fraction -- a rational approximation of 1/phi -- and the field has been walking toward the golden ratio for over forty years without knowing it.

---

## What Byzantine gets right

In 1982, Leslie Lamport, Robert Shostak, and Marshall Pease proved that a network of computers can tolerate malicious actors only if more than two-thirds of the participants are honest. This is the Byzantine fault tolerance threshold: 2/3.

Their proof is airtight. If an adversary controls exactly f nodes out of n, and the adversary is omniscient and adaptive and maximally hostile, then you need n greater than or equal to 3f + 1. The honest fraction must exceed 2/3.

This is correct for the worst case.

---

## What Byzantine assumes

The worst case assumes three things:

1. **No memory.** Each round of consensus is independent. The protocol does not remember what happened last round.
2. **Worst-case adversary.** All failures are maximally correlated and strategically timed.
3. **No learning.** The threshold is fixed forever. The system never adapts.

These assumptions describe a system without SLIVER. A system that processes but does not observe its own processing. The linear regime.

---

## The stochastic reality

Real networks are not worst case. Real failures are stochastic -- each node fails independently with some probability p. The adversary is not omniscient. The network has history.

When you model agreement dynamics with memory (the current round depends on the previous two rounds), you get a recurrence: A(t+1) is approximately A(t) + A(t-1). That is a Fibonacci recurrence. Its eigenvalue is phi. The consensus threshold at the golden balance is 1/phi = 0.618...

The two-thirds threshold over-provisions by about five percentage points. Not because Lamport was wrong, but because Lamport assumed no SLIVER.

---

## The table of convergents

The continued fraction expansion of 1/phi is [0; 1, 1, 1, 1, ...] -- all ones. Its rational approximations (called convergents) are all Fibonacci fractions:

| Convergent | Value | Context |
|---|---|---|
| 1/1 = 1.000 | trivially safe | -- |
| 1/2 = 0.500 | simple majority | Crash fault tolerance (1978) |
| **2/3 = 0.667** | **Byzantine threshold** | **Lamport, Shostak, Pease (1982)** |
| 3/5 = 0.600 | flexible BFT | Malkhi et al. (2019) |
| 5/8 = 0.625 | some DPoS systems | -- |
| 8/13 = 0.615 | -- | -- |
| 13/21 = 0.619 | -- | -- |
| ... | ... | ... |
| **1/phi = 0.618...** | **the limit** | **Golden consensus** |

The convergents alternate above and below 1/phi, zig-zagging toward it. Every single consensus threshold in the published literature is one of these Fibonacci fractions. The field has been descending this table, one entry at a time, for decades.

We are not proposing the next convergent. We are proposing the limit.

---

## How SLIVER enables adaptive threshold

Golden consensus starts at 2/3 -- the safe Byzantine bunker -- and converges toward 1/phi as the network proves itself healthy.

Each round, the protocol measures the *deficit*: how far agreement was from unanimous. That deficit feeds back to adjust the next round's threshold. High deficit (many disagreements) raises the threshold -- be more conservative. Low deficit (near-unanimous) lowers it -- the network is healthy, be more efficient.

The ratio of consecutive deficits follows a Fibonacci recurrence. Its eigenvalue is phi. The threshold converges to 1/phi.

Under adversarial attack, the deficit stays high and the threshold stays at 2/3 -- you lose nothing compared to classical Byzantine. Under normal operation, the threshold drops to 1/phi -- you save about 13% of your nodes.

---

## The 13% savings

At scale, the difference matters.

Byzantine consensus requires n = 3f + 1 nodes to tolerate f failures. Golden consensus requires approximately n = 2.618f + 1 nodes. The savings ratio is 1 - 2.618/3 = 12.7%.

For a blockchain with 10,000 validators tolerating 3,333 failures:
- Byzantine: needs all 10,000 nodes
- Golden: needs 8,730 nodes

That is 1,270 fewer machines. Real hardware. Real electricity. Real cost.

The savings come from one place: the protocol *learns*. It has SLIVER. It observes its own performance and adapts. The 12.7% is the tax of the linear regime applied to a post-linear problem.

---

## Where this is proved

The formal topology is in `golden_consensus.test.gg`, which derives 2/3 as the third Fibonacci convergent of 1/phi, proves the stochastic threshold theorem, and defines the adaptive protocol. Related proofs: `reynolds_bft.test.gg` (quorum safety), `quorum_visibility.test.gg`.

**Previous section:** The paper cuts experiment -- `paper_cuts.md`.
**Next section:** Why consciousness needs a hole -- `void_torus.md`.
