/**
 * GeologyEngine.ts
 *
 * Mechanizes the Geology Topology theorem (Pass 550).
 * Formalizes tectonic plate interactions as Tectonic Slams and Subduction Folds.
 */

export interface GeologyMetrics {
  tectonicStress: number; // accumulated v (seismic debt)
  crustalCapacity: number; // structural budget R
  slamProbability: number; // probability of a non-monotone fold
  isUnstable: boolean;
  lithosphericDilation: number; // expansion rate
}

export class GeologyEngine {
  /**
   * THM-TECTONIC-SLAM: Tectonic plates accumulate seismic debt (v) when 
   * relative velocity exceeds local subduction capacity (R).
   */
  public calculateSeismicDebt(velocity: number, capacity: number): number {
    return Math.max(0, velocity - capacity);
  }

  /**
   * Detects if a Tectonic Slam (Earthquake) is imminent.
   */
  public isUnstable(stress: number, capacity: number): boolean {
    return stress > capacity;
  }

  /**
   * Returns a complete diagnostic of the geological state.
   */
  public getGeologyMetrics(velocity: number, capacity: number): GeologyMetrics {
    const tectonicStress = this.calculateSeismicDebt(velocity, capacity);
    const slamProbability = Math.min(1.0, tectonicStress / Math.max(1, capacity));
    const isUnstable = tectonicStress > 0;
    const lithosphericDilation = Math.max(0.01, velocity / Math.max(1, capacity));

    return {
      tectonicStress,
      crustalCapacity: capacity,
      slamProbability,
      isUnstable,
      lithosphericDilation
    };
  }
}
