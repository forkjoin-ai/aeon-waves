import { describe, it, expect } from 'vitest';
import { TurbulenceEngine } from '../src/TurbulenceEngine.js';

describe('TurbulenceEngine', () => {
  const engine = new TurbulenceEngine();

  describe('calculateEddyCount', () => {
    it('returns 0 when kineticInjection <= foldCapacity', () => {
      expect(engine.calculateEddyCount(10, 10)).toBe(0);
      expect(engine.calculateEddyCount(5, 10)).toBe(0);
    });

    it('returns the difference when kineticInjection > foldCapacity (THM-TURBULENCE-IS-HOPE-GAP)', () => {
      // eddyKnots = kineticInjection - foldCapacity
      expect(engine.calculateEddyCount(15, 10)).toBe(5);
      expect(engine.calculateEddyCount(100, 20)).toBe(80);
    });
  });

  describe('isTurbulent', () => {
    it('returns false when no eddies are present', () => {
      expect(engine.isTurbulent(10, 10)).toBe(false);
    });

    it('returns true when at least one eddy is present', () => {
      expect(engine.isTurbulent(11, 10)).toBe(true);
    });
  });

  describe('getTurbulenceMetrics', () => {
    it('returns full diagnostic metrics', () => {
      const metrics = engine.getTurbulenceMetrics(15, 10);
      expect(metrics.kineticInjection).toBe(15);
      expect(metrics.foldCapacity).toBe(10);
      expect(metrics.eddyKnots).toBe(5);
      expect(metrics.isTurbulent).toBe(true);
      expect(metrics.reidemeisterUtilization).toBe(1.0); // Capped at 1.0
    });
  });
});
