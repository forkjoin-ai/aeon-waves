import type { SessionEventRecord } from '../mcp/session-types';

const SESSION_STORAGE_KEY = 'gnosis-mcp-session';
const SESSION_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const SESSION_ALARM_INTERVAL_MS = 60 * 60 * 1000;
const MAX_EVENTS = 400;

interface SessionState {
  sessionId: string;
  createdAt: string;
  updatedAt: string;
  requestCount: number;
  events: SessionEventRecord[];
  publicToolWindowStartMs: number;
  publicToolCallCount: number;
}

interface InitializeBody {
  sessionId?: string;
}

interface RecordBody {
  type: string;
  detail?: Record<string, unknown>;
}

interface QuotaBody {
  toolName?: string;
  limitPerHour?: number;
}

export class GnosisMcpSessionDurableObject implements DurableObject {
  private readonly state: DurableObjectState;
  private initialized = false;
  private session: SessionState | null = null;

  constructor(state: DurableObjectState, _env: unknown) {
    this.state = state;
  }

  async fetch(request: Request): Promise<Response> {
    await this.ensureInitialized();

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/initialize' && request.method === 'POST') {
        const body = (await request.json()) as InitializeBody;
        return this.handleInitialize(body);
      }

      if (path === '/record' && request.method === 'POST') {
        const body = (await request.json()) as RecordBody;
        return this.handleRecord(body);
      }

      if (path === '/summary' && request.method === 'GET') {
        return this.handleSummary();
      }

      if (path === '/consume-public-quota' && request.method === 'POST') {
        const body = (await request.json()) as QuotaBody;
        return this.handleConsumePublicQuota(body);
      }

      return jsonResponse({ ok: false, error: 'not_found' }, 404);
    } catch (error) {
      return jsonResponse(
        {
          ok: false,
          error: 'session_do_error',
          message: error instanceof Error ? error.message : 'Unknown error',
        },
        500
      );
    }
  }

  async alarm(): Promise<void> {
    await this.ensureInitialized();

    if (!this.session) {
      await this.state.storage.deleteAll();
      return;
    }

    const updatedAtMs = Date.parse(this.session.updatedAt);
    if (
      Number.isFinite(updatedAtMs) &&
      Date.now() - updatedAtMs > SESSION_TTL_MS
    ) {
      await this.state.storage.deleteAll();
      this.session = null;
      return;
    }

    await this.scheduleAlarm();
  }

  private initPromise: Promise<void> | null = null;

  private ensureInitialized(): Promise<void> {
    if (this.initPromise) {
      return this.initPromise;
    }

    this.initPromise = (async () => {
      if (this.initialized) {
        return;
      }

      this.session =
        (await this.state.storage.get<SessionState>(SESSION_STORAGE_KEY)) ??
        null;
      await this.scheduleAlarm();
      this.initialized = true;
    })();

    return this.initPromise;
  }

  private async scheduleAlarm(): Promise<void> {
    await this.state.storage.setAlarm(Date.now() + SESSION_ALARM_INTERVAL_MS);
  }

  private async persistSession(): Promise<void> {
    if (!this.session) {
      return;
    }

    await this.state.storage.put(SESSION_STORAGE_KEY, this.session);
  }

  private async handleInitialize(body: InitializeBody): Promise<Response> {
    const nowIso = new Date().toISOString();
    const nowMs = Date.now();
    const sessionIdRaw =
      typeof body.sessionId === 'string' ? body.sessionId.trim() : '';
    const sessionId =
      sessionIdRaw.length > 0 ? sessionIdRaw : this.state.id.toString();

    this.session = {
      sessionId,
      createdAt: this.session?.createdAt ?? nowIso,
      updatedAt: nowIso,
      requestCount: (this.session?.requestCount ?? 0) + 1,
      events: this.session?.events ?? [],
      publicToolWindowStartMs: this.session?.publicToolWindowStartMs ?? nowMs,
      publicToolCallCount: this.session?.publicToolCallCount ?? 0,
    };

    this.pushEvent({
      type: 'initialize',
      at: nowIso,
      detail: { sessionId },
    });

    await this.persistSession();

    return jsonResponse({
      ok: true,
      sessionId,
      requestCount: this.session.requestCount,
    });
  }

  private async handleRecord(body: RecordBody): Promise<Response> {
    if (!this.session) {
      return jsonResponse(
        {
          ok: false,
          error: 'session_not_initialized',
          message: 'Call /initialize first.',
        },
        409
      );
    }

    const nowIso = new Date().toISOString();
    this.session.updatedAt = nowIso;
    this.session.requestCount += 1;

    this.pushEvent({
      type:
        typeof body.type === 'string' && body.type.length > 0
          ? body.type
          : 'event',
      at: nowIso,
      detail: body.detail,
    });

    await this.persistSession();

    return jsonResponse({
      ok: true,
      requestCount: this.session.requestCount,
    });
  }

  private handleSummary(): Response {
    return jsonResponse({
      ok: true,
      session: this.session
        ? {
            sessionId: this.session.sessionId,
            createdAt: this.session.createdAt,
            updatedAt: this.session.updatedAt,
            requestCount: this.session.requestCount,
            eventCount: this.session.events.length,
            publicToolWindowStartMs: this.session.publicToolWindowStartMs,
            publicToolCallCount: this.session.publicToolCallCount,
          }
        : null,
    });
  }

  private async handleConsumePublicQuota(body: QuotaBody): Promise<Response> {
    if (!this.session) {
      return jsonResponse(
        {
          ok: false,
          error: 'session_not_initialized',
        },
        409
      );
    }

    const nowMs = Date.now();
    const limitPerHour =
      typeof body.limitPerHour === 'number' &&
      Number.isFinite(body.limitPerHour)
        ? Math.max(1, Math.trunc(body.limitPerHour))
        : 20;

    // 24-hour window (free tier: just enough to try before subscribing)
    if (nowMs - this.session.publicToolWindowStartMs >= 24 * 60 * 60 * 1000) {
      this.session.publicToolWindowStartMs = nowMs;
      this.session.publicToolCallCount = 0;
    }

    const nextCount = this.session.publicToolCallCount + 1;
    const remaining = Math.max(0, limitPerHour - nextCount);
    const allowed = nextCount <= limitPerHour;

    if (allowed) {
      this.session.publicToolCallCount = nextCount;
      this.session.updatedAt = new Date(nowMs).toISOString();
      this.pushEvent({
        type: 'quota.consume.public',
        at: this.session.updatedAt,
        detail: {
          toolName: body.toolName ?? null,
          count: nextCount,
          limitPerHour,
          remaining,
        },
      });
      await this.persistSession();
    }

    return jsonResponse({
      ok: true,
      allowed,
      limitPerHour,
      count: nextCount,
      remaining,
      resetAtMs: this.session.publicToolWindowStartMs + 24 * 60 * 60 * 1000,
    });
  }

  private pushEvent(event: SessionEventRecord): void {
    if (!this.session) {
      return;
    }

    this.session.events.push(event);
    if (this.session.events.length > MAX_EVENTS) {
      this.session.events = this.session.events.slice(
        this.session.events.length - MAX_EVENTS
      );
    }
  }
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'content-type': 'application/json',
      'cache-control': 'no-store',
    },
  });
}
