/**
 * LiveWord Training Service
 *
 * Client-side training orchestration for the LiveWord neural model.
 * Fetches training data from the server, trains locally, and syncs via Dash RTC.
 */

interface TrainingExample {
  id: string;
  word: string;
  timestamp: number;
  region?: string;
}

interface TrainingStats {
  examplesLoaded: number;
  isTraining: boolean;
  lastTrainedAt: number | null;
  modelReady: boolean;
}

/**
 * LiveWord Training Service
 * Manages client-side training for distributed neural model
 */
export class LiveWordTraining {
  private static instance: LiveWordTraining | null = null;
  private trainingExamples: TrainingExample[] = [];
  private isInitialized = false;
  private isTraining = false;
  private lastTrainedAt: number | null = null;
  private pollInterval: ReturnType<typeof setInterval> | null = null;
  private trainInterval: ReturnType<typeof setInterval> | null = null;

  private constructor() {
    /* noop - singleton pattern, initialization done in static getInstance() */
  }

  /**
   * Get singleton instance
   */
  static getInstance(): LiveWordTraining {
    if (!LiveWordTraining.instance) {
      LiveWordTraining.instance = new LiveWordTraining();
    }
    return LiveWordTraining.instance;
  }

  /**
   * Initialize the training service
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      // Fetch initial training data
      await this.fetchTrainingData();

      // Start polling for new training data
      this.pollInterval = setInterval(() => {
        this.fetchTrainingData().catch(console.error);
      }, 30000); // Poll every 30 seconds

      // Start periodic training (every 5 minutes if we have enough data)
      this.trainInterval = setInterval(() => {
        if (this.trainingExamples.length >= 10) {
          this.train().catch(console.error);
        }
      }, 300000); // Train every 5 minutes

      this.isInitialized = true;
      console.log('[LiveWordTraining] Initialized');
    } catch (error) {
      console.error('[LiveWordTraining] Initialization failed:', error);
    }
  }

  /**
   * Fetch training data from server
   */
  private async fetchTrainingData(): Promise<void> {
    try {
      const response = await fetch('/api/training-data');
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = (await response.json()) as {
        examples: TrainingExample[];
        totalExamples: number;
        lastUpdated: number;
      };

      // Merge with existing examples, avoiding duplicates
      const existingIds = new Set(this.trainingExamples.map((e) => e.id));
      const newExamples = data.examples.filter((e) => !existingIds.has(e.id));

      if (newExamples.length > 0) {
        this.trainingExamples = [...this.trainingExamples, ...newExamples]
          .sort((a, b) => b.timestamp - a.timestamp)
          .slice(0, 1000); // Keep last 1000

        console.log(
          '[LiveWordTraining] Fetched new examples:',
          newExamples.length
        );
      }
    } catch (error) {
      console.error('[LiveWordTraining] Failed to fetch training data:', error);
    }
  }

  /**
   * Train the model on collected examples
   * Note: In browser, we use a simplified training approach
   */
  private async train(): Promise<void> {
    if (this.isTraining || this.trainingExamples.length < 10) return;

    this.isTraining = true;
    console.log(
      '[LiveWordTraining] Starting training with',
      this.trainingExamples.length,
      'examples'
    );

    try {
      // In a full implementation, this would use the Neural library's BrowserLayerNode
      // For the demo, we just log the training
      const startTime = Date.now();

      // Simulate training delay
      await new Promise((resolve) => setTimeout(resolve, 100));

      this.lastTrainedAt = Date.now();
      console.log(
        '[LiveWordTraining] Training completed in',
        Date.now() - startTime,
        'ms'
      );
    } catch (error) {
      console.error('[LiveWordTraining] Training failed:', error);
    } finally {
      this.isTraining = false;
    }
  }

  /**
   * Add a training example (called when user submits a word)
   */
  addExample(word: string): void {
    const example: TrainingExample = {
      id: `local-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      word,
      timestamp: Date.now(),
    };

    this.trainingExamples.push(example);

    // Keep only the most recent
    if (this.trainingExamples.length > 1000) {
      this.trainingExamples = this.trainingExamples
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, 1000);
    }
  }

  /**
   * Get training statistics
   */
  getStats(): TrainingStats {
    return {
      examplesLoaded: this.trainingExamples.length,
      isTraining: this.isTraining,
      lastTrainedAt: this.lastTrainedAt,
      modelReady: this.trainingExamples.length >= 10,
    };
  }

  /**
   * Cleanup resources
   */
  destroy(): void {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
    if (this.trainInterval) {
      clearInterval(this.trainInterval);
      this.trainInterval = null;
    }
    this.isInitialized = false;
    LiveWordTraining.instance = null;
  }
}

/**
 * Get the singleton training service
 */
export function getLiveWordTraining(): LiveWordTraining {
  return LiveWordTraining.getInstance();
}
