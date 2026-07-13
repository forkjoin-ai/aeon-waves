/// <reference types="@cloudflare/workers-types" />

export interface AssetBinding {
  fetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response>;
}

export interface Env {
  ENVIRONMENT: 'development' | 'staging' | 'production' | string;
  MCP_PUBLIC_BASE_URL?: string;
  MCP_AUTH_REQUIRED?: string;
  MCP_AUTH_TOKEN?: string;
  MCP_AUTH_TOKENS?: string;
  PUBLIC_TOOL_RATE_LIMIT?: string;
  DASH_RELAY_URL?: string;
  DASH_RELAY_WS_URL?: string;
  DASH_RELAY_WT_URL?: string;
  DASH_RELAY_DISCOVERY_URL?: string;
  AEON_FORGE_DEPLOY_URL?: string;
  MCP_SESSION_DO: DurableObjectNamespace;
  DEBUG_SESSION_DO: DurableObjectNamespace;
  CACHE?: KVNamespace;
  ASSETS?: AssetBinding;
}

export interface McpToolDefinition {
  name: string;
  description: string;
  access: 'public' | 'auth';
  inputSchema: {
    type: 'object';
    properties: Record<string, unknown>;
    required?: string[];
  };
}

export interface McpResourceDefinition {
  uri: string;
  name: string;
  description: string;
  mimeType: string;
}

export interface McpRequest {
  jsonrpc: '2.0';
  id: string | number | null;
  method: string;
  params?: Record<string, unknown>;
}

export interface McpResponse {
  jsonrpc: '2.0';
  id: string | number | null;
  result?: unknown;
  error?: {
    code: number;
    message: string;
    data?: unknown;
  };
}

export interface ToolCallResult {
  content: Array<{
    type: 'text';
    text: string;
  }>;
  isError?: boolean;
}

export interface ToolInvocationContext {
  env: Env;
  sessionId: string;
  authToken: string | null;
}
