const baseUrl = (
  process.argv[2] ||
  process.env.GNOSIS_CHURCH_BASE_URL ||
  'https://forkjoin.ai'
).replace(/\/+$/, '');
const sessionHeaderName = 'mcp-session-id';

interface JsonRpcPayload {
  jsonrpc: '2.0';
  id: string | number;
  method: string;
  params?: Record<string, unknown>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) {
    throw new Error(message);
  }
}

async function fetchJson(path: string, init?: RequestInit): Promise<unknown> {
  const response = await fetch(`${baseUrl}${path}`, init);
  const raw = await response.text();
  let parsed: unknown = null;
  if (raw.trim().length > 0) {
    try {
      parsed = JSON.parse(raw) as unknown;
    } catch {
      parsed = raw;
    }
  }

  if (!response.ok) {
    throw new Error(
      `Request ${path} failed (${response.status}): ${JSON.stringify(parsed)}`
    );
  }

  return parsed;
}

async function postMcp(
  payload: JsonRpcPayload,
  sessionId?: string
): Promise<{ body: Record<string, unknown>; sessionId: string | null }> {
  const headers = new Headers({ 'content-type': 'application/json' });
  if (sessionId) {
    headers.set(sessionHeaderName, sessionId);
  }

  const response = await fetch(`${baseUrl}/mcp`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });

  const parsed = (await response.json()) as unknown;
  const body = isRecord(parsed) ? parsed : {};
  const nextSessionId = response.headers.get(sessionHeaderName);

  if (!response.ok) {
    throw new Error(
      `MCP request failed (${response.status}): ${JSON.stringify(body)}`
    );
  }

  return {
    body,
    sessionId: nextSessionId,
  };
}

async function expectReachable(path: string): Promise<void> {
  const response = await fetch(`${baseUrl}${path}`);
  if (!response.ok) {
    throw new Error(`${path} returned ${response.status}`);
  }
}

async function main(): Promise<void> {
  console.log(`[smoke] base URL: ${baseUrl}`);

  const health = (await fetchJson('/health')) as {
    status?: string;
    service?: string;
  };
  assert(
    health.status === 'healthy',
    'Health endpoint did not return healthy status.'
  );
  assert(
    health.service === 'forkjoin-app',
    'Health endpoint service mismatch.'
  );
  console.log('[smoke] /health ok');

  const initialize = await postMcp({
    jsonrpc: '2.0',
    id: 1,
    method: 'initialize',
  });
  const initializeResult = isRecord(initialize.body.result)
    ? initialize.body.result
    : {};
  assert(
    typeof initializeResult.protocolVersion === 'string',
    'MCP initialize missing protocolVersion.'
  );
  const sessionId = initialize.sessionId;
  assert(
    sessionId && sessionId.length > 0,
    'MCP initialize missing mcp-session-id header.'
  );
  console.log('[smoke] mcp initialize ok');

  const toolsList = await postMcp(
    {
      jsonrpc: '2.0',
      id: 2,
      method: 'tools/list',
    },
    sessionId
  );

  const toolsListResult = isRecord(toolsList.body.result)
    ? toolsList.body.result
    : {};
  const tools = toolsListResult.tools;
  assert(
    Array.isArray(tools) && tools.length > 0,
    'tools/list returned no tools.'
  );
  console.log('[smoke] mcp tools/list ok');

  const compileCall = await postMcp(
    {
      jsonrpc: '2.0',
      id: 3,
      method: 'tools/call',
      params: {
        name: 'gnosis_compile',
        arguments: {
          source: '(start)-[:PROCESS]->(finish)',
        },
      },
    },
    sessionId
  );
  assert(
    !compileCall.body?.error,
    `gnosis_compile unexpectedly failed: ${JSON.stringify(compileCall.body)}`
  );
  console.log('[smoke] mcp public tool call ok');

  const authDenied = await postMcp(
    {
      jsonrpc: '2.0',
      id: 4,
      method: 'tools/call',
      params: {
        name: 'gnosis_run',
        arguments: {
          source: '(start)-[:PROCESS]->(finish)',
        },
      },
    },
    sessionId
  );
  const authDeniedError = isRecord(authDenied.body.error)
    ? authDenied.body.error
    : {};
  assert(
    authDeniedError.code === -32001,
    'Expected auth denial for gnosis_run without token.'
  );
  console.log('[smoke] mcp auth denial ok');

  await expectReachable('/');
  await expectReachable('/docs');
  await expectReachable('/privacy');
  await expectReachable('/cookies');
  await expectReachable('/cookie-settings');
  await expectReachable('/terms');
  await expectReachable('/colophon');
  console.log('[smoke] web/legal routes ok');

  await expectReachable('/llms.txt');
  await expectReachable('/llms-full.txt');
  await expectReachable('/skills/index.json');
  await expectReachable('/agents.json');
  await expectReachable('/.well-known/mcp.json');
  console.log('[smoke] discovery routes ok');

  console.log('[smoke] all checks passed');
}

main().catch((error) => {
  console.error(
    `[smoke] failed: ${error instanceof Error ? error.message : String(error)}`
  );
  process.exit(1);
});
