import { QDoc } from '@a0n/gnosis/crdt';

const DEBUG_STORAGE_KEY = 'gnosis-debug-session';
const DEBUG_TTL_MS = 3 * 24 * 60 * 60 * 1000;
const DEBUG_ALARM_INTERVAL_MS = 60 * 60 * 1000;

interface RelayConfigSnapshot {
  url: string;
  roomName: string;
  apiKey?: string;
  clientId?: string;
  webtransportUrl?: string;
  discoveryUrl?: string;
  connected: boolean;
  updatedAt: string;
}

interface DebugSessionState {
  guid: string;
  qdocStateBase64: string;
  relay?: RelayConfigSnapshot;
  createdAt: string;
  updatedAt: string;
}

type QDocOperation =
  | {
      type: 'map_set';
      map: string;
      key: string;
      value: unknown;
    }
  | {
      type: 'map_delete';
      map: string;
      key: string;
    }
  | {
      type: 'array_push';
      array: string;
      values: unknown[];
    }
  | {
      type: 'array_delete';
      array: string;
      index: number;
      length?: number;
    }
  | {
      type: 'text_insert';
      text: string;
      index: number;
      value: string;
    }
  | {
      type: 'text_delete';
      text: string;
      index: number;
      length: number;
    }
  | {
      type: 'counter_inc';
      counter: string;
      value: number;
    }
  | {
      type: 'presence_set';
      value: Record<string, unknown>;
    };

interface CreateBody {
  guid?: string;
  initialGg?: string;
}

interface ApplyUpdateBody {
  updateBase64?: string;
}

interface TransactBody {
  operations?: QDocOperation[];
}

interface DashRelayConnectBody {
  url?: string;
  roomName?: string;
  apiKey?: string;
  clientId?: string;
  webtransportUrl?: string;
  discoveryUrl?: string;
  ephemeral?: boolean;
}

export class GnosisDebugSessionDurableObject implements DurableObject {
  private readonly state: DurableObjectState;
  private initialized = false;
  private session: DebugSessionState | null = null;

  constructor(state: DurableObjectState, _env: unknown) {
    this.state = state;
  }

  async fetch(request: Request): Promise<Response> {
    await this.ensureInitialized();

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/qdoc/create' && request.method === 'POST') {
        const body = (await request.json()) as CreateBody;
        return this.handleQDocCreate(body);
      }

      if (path === '/qdoc/state' && request.method === 'GET') {
        return this.handleQDocState();
      }

      if (path === '/qdoc/apply-update' && request.method === 'POST') {
        const body = (await request.json()) as ApplyUpdateBody;
        return this.handleQDocApplyUpdate(body);
      }

      if (path === '/qdoc/transact' && request.method === 'POST') {
        const body = (await request.json()) as TransactBody;
        return this.handleQDocTransact(body);
      }

      if (path === '/qdoc/get-delta' && request.method === 'GET') {
        return this.handleQDocGetDelta();
      }

      if (path === '/dashrelay/connect' && request.method === 'POST') {
        const body = (await request.json()) as DashRelayConnectBody;
        return this.handleDashRelayConnect(body);
      }

      if (path === '/dashrelay/status' && request.method === 'GET') {
        return this.handleDashRelayStatus();
      }

      if (path === '/dashrelay/disconnect' && request.method === 'POST') {
        return this.handleDashRelayDisconnect();
      }

      return jsonResponse({ ok: false, error: 'not_found' }, 404);
    } catch (error) {
      return jsonResponse(
        {
          ok: false,
          error: 'debug_session_do_error',
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
      Date.now() - updatedAtMs > DEBUG_TTL_MS
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
        (await this.state.storage.get<DebugSessionState>(DEBUG_STORAGE_KEY)) ??
        null;
      await this.scheduleAlarm();
      this.initialized = true;
    })();

    return this.initPromise;
  }

  private async scheduleAlarm(): Promise<void> {
    await this.state.storage.setAlarm(Date.now() + DEBUG_ALARM_INTERVAL_MS);
  }

  private async persistSession(): Promise<void> {
    if (!this.session) {
      return;
    }

    await this.state.storage.put(DEBUG_STORAGE_KEY, this.session);
  }

  private createFreshDoc(guid?: string): QDoc {
    const doc = new QDoc({
      guid: guid && guid.trim().length > 0 ? guid.trim() : undefined,
    });
    return doc;
  }

  private decodeState(base64Value: string): Uint8Array | null {
    try {
      return base64ToBytes(base64Value);
    } catch {
      return null;
    }
  }

  private loadDoc(): QDoc {
    if (!this.session) {
      return this.createFreshDoc();
    }

    const doc = this.createFreshDoc(this.session.guid);
    const update = this.decodeState(this.session.qdocStateBase64);
    if (update) {
      doc.applyUpdate(update, 'storage');
    }
    return doc;
  }

  private saveDoc(doc: QDoc): void {
    const nowIso = new Date().toISOString();
    const update = doc.encodeStateAsUpdate();
    const encoded = bytesToBase64(update);

    if (!this.session) {
      this.session = {
        guid: doc.guid,
        qdocStateBase64: encoded,
        createdAt: nowIso,
        updatedAt: nowIso,
      };
      return;
    }

    this.session.guid = doc.guid;
    this.session.qdocStateBase64 = encoded;
    this.session.updatedAt = nowIso;
  }

  private async handleQDocCreate(body: CreateBody): Promise<Response> {
    const doc = this.createFreshDoc(body.guid);

    if (
      typeof body.initialGg === 'string' &&
      body.initialGg.trim().length > 0
    ) {
      const rootMap = doc.getMap<string>('document');
      rootMap.set('source.gg', body.initialGg.trim());
    }

    this.saveDoc(doc);
    await this.persistSession();

    return jsonResponse({
      ok: true,
      guid: doc.guid,
      beta1: doc.beta1,
      nodeCount: doc.nodeCount,
      edgeCount: doc.edgeCount,
    });
  }

  private handleQDocState(): Response {
    if (!this.session) {
      return jsonResponse({
        ok: true,
        state: null,
      });
    }

    const doc = this.loadDoc();
    const encoded = bytesToBase64(doc.encodeStateAsUpdate());

    return jsonResponse({
      ok: true,
      state: {
        guid: doc.guid,
        beta1: doc.beta1,
        clock: doc.clock,
        nodeCount: doc.nodeCount,
        edgeCount: doc.edgeCount,
        gg: doc.toGG(),
        updateBase64: encoded,
        relay: this.session.relay ?? null,
      },
    });
  }

  private async handleQDocApplyUpdate(
    body: ApplyUpdateBody
  ): Promise<Response> {
    if (
      typeof body.updateBase64 !== 'string' ||
      body.updateBase64.trim().length === 0
    ) {
      return jsonResponse(
        {
          ok: false,
          error: 'invalid_update',
          message: 'updateBase64 is required.',
        },
        400
      );
    }

    const update = this.decodeState(body.updateBase64.trim());
    if (!update) {
      return jsonResponse(
        {
          ok: false,
          error: 'invalid_update',
          message: 'Failed to decode updateBase64.',
        },
        400
      );
    }

    const doc = this.loadDoc();
    doc.applyUpdate(update, 'remote');
    this.saveDoc(doc);
    await this.persistSession();

    return jsonResponse({
      ok: true,
      guid: doc.guid,
      beta1: doc.beta1,
      nodeCount: doc.nodeCount,
      edgeCount: doc.edgeCount,
    });
  }

  private applyOperation(doc: QDoc, operation: QDocOperation): void {
    switch (operation.type) {
      case 'map_set': {
        doc.getMap<unknown>(operation.map).set(operation.key, operation.value);
        return;
      }
      case 'map_delete': {
        doc.getMap<unknown>(operation.map).delete(operation.key);
        return;
      }
      case 'array_push': {
        doc.getArray<unknown>(operation.array).push(operation.values);
        return;
      }
      case 'array_delete': {
        doc
          .getArray<unknown>(operation.array)
          .delete(operation.index, operation.length ?? 1);
        return;
      }
      case 'text_insert': {
        doc.getText(operation.text).insert(operation.index, operation.value);
        return;
      }
      case 'text_delete': {
        doc.getText(operation.text).delete(operation.index, operation.length);
        return;
      }
      case 'counter_inc': {
        doc.getCounter(operation.counter).increment(operation.value);
        return;
      }
      case 'presence_set': {
        doc.setPresence(operation.value);
        return;
      }
      default: {
        const exhaustiveCheck: never = operation;
        throw new Error(`Unsupported operation: ${String(exhaustiveCheck)}`);
      }
    }
  }

  private async handleQDocTransact(body: TransactBody): Promise<Response> {
    if (!Array.isArray(body.operations) || body.operations.length === 0) {
      return jsonResponse(
        {
          ok: false,
          error: 'invalid_operations',
          message: 'operations must be a non-empty array.',
        },
        400
      );
    }

    const doc = this.loadDoc();
    doc.transact(() => {
      for (const operation of body.operations ?? []) {
        this.applyOperation(doc, operation);
      }
    }, 'local');

    this.saveDoc(doc);
    await this.persistSession();

    return jsonResponse({
      ok: true,
      guid: doc.guid,
      beta1: doc.beta1,
      clock: doc.clock,
      nodeCount: doc.nodeCount,
      edgeCount: doc.edgeCount,
    });
  }

  private handleQDocGetDelta(): Response {
    const doc = this.loadDoc();
    const encoded = bytesToBase64(doc.encodeStateAsUpdate());

    return jsonResponse({
      ok: true,
      guid: doc.guid,
      updateBase64: encoded,
    });
  }

  private async handleDashRelayConnect(
    body: DashRelayConnectBody
  ): Promise<Response> {
    const nowIso = new Date().toISOString();
    const idSuffix = this.state.id.toString().slice(-8);
    const isEphemeral = body.ephemeral !== false;
    const roomNameRaw =
      typeof body.roomName === 'string' ? body.roomName.trim() : '';
    const roomName =
      roomNameRaw.length > 0
        ? roomNameRaw
        : isEphemeral
        ? `gnosis-${idSuffix}-${crypto.randomUUID().slice(0, 6)}`
        : `gnosis-${idSuffix}`;

    const relay: RelayConfigSnapshot = {
      url:
        typeof body.url === 'string' && body.url.trim().length > 0
          ? body.url.trim()
          : 'wss://relay.dashrelay.com/relay/sync',
      roomName,
      apiKey:
        typeof body.apiKey === 'string' && body.apiKey.trim().length > 0
          ? body.apiKey.trim()
          : isEphemeral
          ? `ephemeral_${crypto.randomUUID().slice(0, 12)}`
          : undefined,
      clientId:
        typeof body.clientId === 'string' && body.clientId.trim().length > 0
          ? body.clientId.trim()
          : `qdoc-${crypto.randomUUID().slice(0, 10)}`,
      webtransportUrl:
        typeof body.webtransportUrl === 'string' &&
        body.webtransportUrl.trim().length > 0
          ? body.webtransportUrl.trim()
          : 'https://relay.dashrelay.com/relay',
      discoveryUrl:
        typeof body.discoveryUrl === 'string' &&
        body.discoveryUrl.trim().length > 0
          ? body.discoveryUrl.trim()
          : 'https://relay.dashrelay.com/discovery',
      connected: true,
      updatedAt: nowIso,
    };

    if (!this.session) {
      const doc = this.createFreshDoc();
      this.saveDoc(doc);
    }

    if (this.session) {
      this.session.relay = relay;
      this.session.updatedAt = nowIso;
      await this.persistSession();
    }

    return jsonResponse({
      ok: true,
      relay,
      notes: {
        mode: isEphemeral ? 'ephemeral-fallback' : 'byo-room',
        handshake:
          'Worker stores session relay intent; client establishes websocket.',
      },
    });
  }

  private handleDashRelayStatus(): Response {
    return jsonResponse({
      ok: true,
      relay: this.session?.relay ?? null,
    });
  }

  private async handleDashRelayDisconnect(): Promise<Response> {
    if (this.session?.relay) {
      this.session.relay = {
        ...this.session.relay,
        connected: false,
        updatedAt: new Date().toISOString(),
      };
      await this.persistSession();
    }

    return jsonResponse({
      ok: true,
      relay: this.session?.relay ?? null,
    });
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

function bytesToBase64(value: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < value.length; i += 1) {
    binary += String.fromCharCode(value[i]);
  }
  return btoa(binary);
}

function base64ToBytes(value: string): Uint8Array {
  const binary = atob(value);
  const output = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    output[i] = binary.charCodeAt(i);
  }
  return output;
}
