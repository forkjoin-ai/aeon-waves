export interface SessionEventRecord {
  type: string;
  at: string;
  detail?: Record<string, unknown>;
}
