import fs from 'fs';
import path from 'path';

const outDir = path.resolve('.');

const categories = {
  aeon_core: [
    {
      name: 'esi_resolution',
      desc: 'Edge Side Includes resolution and stitching',
      flow: "(req: Request)-[:FORK]->(frag_header: Fragment | frag_body: Fragment)\n(frag_header | frag_body)-[:FOLD { strategy: 'stitch' }]->(page: RenderedPage)",
    },
    {
      name: 'tui_keyboard_dispatch',
      desc: 'TUI keyboard input handling',
      flow: '(keypress: Event)-[:PROCESS]->(key_mapper: Logic)-[:PROCESS]->(action_dispatch: Dispatcher)',
    },
    {
      name: 'tui_layout_engine',
      desc: 'TUI Layout engine recalculation',
      flow: "(resize: Event)-[:FORK]->(calc_sidebar: Layout | calc_main: Layout)\n(calc_sidebar | calc_main)-[:FOLD { strategy: 'merge-rects' }]->(screen: View)",
    },
    {
      name: 'pty_process_manager',
      desc: 'PTY Process management',
      flow: "(spawn_cmd: Command)-[:FORK]->(pty_stdout: Stream | pty_stderr: Stream)\n(pty_stdout | pty_stderr)-[:FOLD { strategy: 'multiplex' }]->(terminal: TTY)",
    },
    {
      name: 'pensieve_memory_compaction',
      desc: 'Pensieve memory compaction',
      flow: "(trigger: Cron)-[:FORK]->(scan_old: GC | scan_redundant: GC)\n(scan_old | scan_redundant)-[:FOLD { strategy: 'union' }]->(compact: Action)",
    },
    {
      name: 'background_daemon_telemetry',
      desc: 'Background Daemon Telemetry',
      flow: "(tick: Timer)-[:FORK]->(cpu_stat: Metric | mem_stat: Metric)\n(cpu_stat | mem_stat)-[:FOLD { strategy: 'batch' }]->(log_sink: Storage)",
    },
    {
      name: 'agent_store_provisioner',
      desc: 'Agent Store Provisioning',
      flow: "(install: Cmd)-[:FORK]->(fetch_wasm: Net | alloc_storage: Disk)\n(fetch_wasm | alloc_storage)-[:FOLD { strategy: 'all-ready' }]->(ready: Agent)",
    },
    {
      name: 'speculative_ui_render',
      desc: 'Speculative UI Rendering',
      flow: "(intent: Action)-[:FORK]->(render_spec: UI | fetch_data: API)\n(render_spec | fetch_data)-[:FOLD { strategy: 'verify' }]->(final_ui: UI)",
    },
    {
      name: 'memento_chain_anchor',
      desc: 'Memento Blockchain Anchoring',
      flow: '(memory: Fact)-[:PROCESS]->(hash: Crypto)-[:PROCESS]->(merkle_tree: Data)-[:PROCESS]->(chain_anchor: Ledger)',
    },
    {
      name: 'reality_branch_fork',
      desc: 'Reality Forking',
      flow: "(base_state: Graph)-[:FORK]->(branch_a: Simulation | branch_b: Simulation)\n(branch_a | branch_b)-[:FOLD { strategy: 'wisdom-merge' }]->(next_state: Graph)",
    },
  ],
  aeon_network: [
    {
      name: 'ucan_capability_auth',
      desc: 'UCAN capability delegation validation',
      flow: '(token: Token)-[:PROCESS]->(verify_sig: Check)-[:PROCESS]->(check_caps: Check)-[:PROCESS]->(auth_ok: Result)',
    },
    {
      name: 'd1_database_sync',
      desc: 'D1 database write pool sync',
      flow: "(write: Mutation)-[:FORK]->(local_cache: DB | remote_pool: DB)\n(local_cache | remote_pool)-[:RACE { expect: 'fastest' }]->(ack: Ack)",
    },
    {
      name: 'edge_cache_fallback',
      desc: 'Cache with origin fallback',
      flow: "(req: Request)-[:FORK]->(edge_cache: Cache | origin: Server)\n(edge_cache | origin)-[:RACE { expect: 'first-arrival' }]->(res: Response)",
    },
    {
      name: 'agent_mesh_gossip',
      desc: 'Agent mesh gossip protocol',
      flow: "(event: Gossip)-[:FORK]->(peer_1: Agent | peer_2: Agent)\n(peer_1 | peer_2)-[:FOLD { strategy: 'consensus' }]->(global_state: State)",
    },
    {
      name: 'crdt_sync_conflict',
      desc: 'CRDT synchronization and conflict resolution',
      flow: "(sync_event: Trigger)-[:FORK]->(apply_local: State | merge_remote: State)\n(apply_local | merge_remote)-[:FOLD { strategy: 'lww' }]->(converged: State)",
    },
    {
      name: 'worker_failover_dist',
      desc: 'Distributed Worker Fallover',
      flow: "(task: Job)-[:FORK]->(primary: Worker | secondary: Worker)\n(primary | secondary)-[:RACE { expect: 'success' }]->(result: Output)",
    },
    {
      name: 'ucan_revocation_gossip',
      desc: 'UCAN Revocation Propagation',
      flow: "(revoke: Cmd)-[:FORK]->(edge_a: Cache | edge_b: Cache)\n(edge_a | edge_b)-[:FOLD { strategy: 'gossip-sync' }]->(global_ban: List)",
    },
    {
      name: 'edge_queue_batcher',
      desc: 'Edge Queue Batching',
      flow: "(trigger: Time)-[:FORK]->(event1: Log | event2: Log | event3: Log)\n(event1 | event2 | event3)-[:FOLD { strategy: 'size-trigger' }]->(batch: Array)-[:PROCESS]->(warehouse: DB)",
    },
    {
      name: 'flux_client_sync',
      desc: 'Aeon Flux Client Sync',
      flow: "(ui_mutation: Event)-[:FORK]->(optimistic_update: DOM | server_sync: WSS)\n(server_sync)-[:PROCESS]->(ack: Network)\n(optimistic_update | ack)-[:FOLD { strategy: 'reconcile' }]->(confirmed_ui: DOM)",
    },
  ],
  aeon_cognitive: [
    {
      name: 'llm_inference_mesh',
      desc: 'LLM Distributed Inference Mesh',
      flow: "(prompt: Prompt)-[:FORK]->(node_a: GPU | node_b: GPU | node_c: GPU)\n(node_a | node_b | node_c)-[:RACE { expect: 'fastest-chunk' }]->(stream: Output)",
    },
    {
      name: 'agent_waking_service',
      desc: 'Agent waking service',
      flow: '(ping: Signal)-[:PROCESS]->(check_sleep: Logic)-[:PROCESS]->(boot_container: Process)',
    },
    {
      name: 'vector_search_l1_l2',
      desc: 'L1/L2 Vector Search Fallback',
      flow: "(query: Vector)-[:FORK]->(l1_memory: Search | l2_disk: Search)\n(l1_memory | l2_disk)-[:RACE { expect: 'quality-threshold' }]->(results: Matches)",
    },
    {
      name: 'model_weight_fetcher',
      desc: 'Model Zoo Weight Fetch',
      flow: "(request_model: Intent)-[:FORK]->(local_cache: FS | huggingface: API | r2_bucket: Storage)\n(local_cache | huggingface | r2_bucket)-[:RACE { expect: 'first-chunk' }]->(weights: Tensor)",
    },
    {
      name: 'webgpu_neural_compute',
      desc: 'WebGPU Neural Inference',
      flow: '(tensor: Data)-[:PROCESS]->(shader_prep: Compiler)-[:PROCESS]->(gpu_exec: Compute)-[:PROCESS]->(logits: Output)',
    },
    {
      name: 'audio_vad_chunker',
      desc: 'Audio Stream Chunking',
      flow: '(mic_stream: Audio)-[:PROCESS]->(vad_gate: Filter)-[:PROCESS]->(buffer: Memory)-[:PROCESS]->(stt_engine: Speech)',
    },
    {
      name: 'intent_classifier_route',
      desc: 'Intent Routing',
      flow: "(user_msg: Text)-[:PROCESS]->(classifier: LLM)-[:FORK]->(tool_a: Action | tool_b: Action | fallback: Action)\n(tool_a | tool_b | fallback)-[:RACE { expect: 'highest-confidence' }]->(execution: Route)",
    },
    {
      name: 'context_rag_injector',
      desc: 'Context Injection',
      flow: "(prompt: Text)-[:FORK]->(fetch_history: RAG | fetch_profile: DB)\n(fetch_history | fetch_profile)-[:FOLD { strategy: 'concat' }]->(enriched_prompt: Text)",
    },
    {
      name: 'moderation_guardrail',
      desc: 'Moderation Shield',
      flow: "(output: Text)-[:FORK]->(pii_check: Guard | toxicity_check: Guard)\n(pii_check | toxicity_check)-[:FOLD { strategy: 'all-pass' }]->(safe_output: Text)",
    },
    {
      name: 'fast_slow_llm_router',
      desc: 'Cognitive Routing (Fast/Slow)',
      flow: "(query: Text)-[:FORK]->(fast_lane: SmallLLM | slow_lane: LargeLLM)\n(fast_lane | slow_lane)-[:RACE { expect: 'adequate-quality' }]->(answer: Text)",
    },
    {
      name: 'boundary_probe_walk',
      desc: 'Boundary Walk Probing',
      flow: "(probe: Test)-[:FORK]->(model_a: Target | model_b: Target)\n(model_a | model_b)-[:FOLD { strategy: 'compare-drift' }]->(report: Diff)",
    },
    {
      name: 'emotion_resonance_fusion',
      desc: 'Emotional Resonance Calculation',
      flow: "(input: Multimodal)-[:FORK]->(facial_cvm: Vision | vocal_prosody: Audio | semantic_text: NLP)\n(facial_cvm | vocal_prosody | semantic_text)-[:FOLD { strategy: 'vector-fusion' }]->(affect_state: State)",
    },
    {
      name: 'cyrano_shadow_mode',
      desc: 'Cyrano Shadow Mode',
      flow: "(user_action: Event)-[:FORK]->(live_ui: View | shadow_agent: Observer)\n(shadow_agent)-[:PROCESS]->(insight: Memory)\n(live_ui | insight)-[:FOLD { strategy: 'async-collect' }]->(done: End)",
    },
  ],
  aeon_apps: [
    {
      name: 'cli_command_parser',
      desc: 'CLI argument parsing and resolution',
      flow: '(args: List)-[:PROCESS]->(parser: Logic)-[:PROCESS]->(command: Cmd)',
    },
    {
      name: 'forge_build_pipeline',
      desc: 'Aeon Forge Build Pipeline',
      flow: "(source: Source)-[:FORK]->(lint: Check | test: Check)\n(lint | test)-[:FOLD { strategy: 'all-pass' }]->(artifact: Binary)",
    },
    {
      name: 'foundation_did_resolver',
      desc: 'Decentralized Identifier Resolution',
      flow: '(did: URI)-[:PROCESS]->(resolver: Network)-[:PROCESS]->(document: DIDDoc)',
    },
    {
      name: 'inference_service_load_balancer',
      desc: 'Load balancing for inference requests',
      flow: "(req: Payload)-[:FORK]->(worker_1: GPU | worker_2: GPU)\n(worker_1 | worker_2)-[:RACE { expect: 'fastest-availability' }]->(assigned_worker: Worker)",
    },
    {
      name: 'publisher_content_syndication',
      desc: 'Content Syndication for Aeon Publisher',
      flow: "(post: Article)-[:FORK]->(twitter: API | linkedin: API | blog: DB)\n(twitter | linkedin | blog)-[:FOLD { strategy: 'all-settled' }]->(publish_receipt: Status)",
    },
    {
      name: 'flux_state_reconciliation',
      desc: 'State Reconciliation in Flux',
      flow: "(local_state: Graph | remote_state: Graph)-[:FOLD { strategy: 'reconcile-diff' }]->(merged_state: Graph)",
    },
    {
      name: 'logic_theorem_prover',
      desc: 'Theorem Proving with Aeon Logic',
      flow: '(theorem: Logic)-[:PROCESS]->(solver: Z3)-[:PROCESS]->(proof: Result)',
    },
  ],
};

for (const [categoryName, models] of Object.entries(categories)) {
  let testSuiteContent = `// ${categoryName}.test.gg — Verification harness for ${categoryName.replace(
    '_',
    ' '
  )}\n(test_suite: TestSuite { name: '${categoryName}' })\n\n`;

  const verifyNodes: string[] = [];
  const forkNames: string[] = [];
  const raceFolds: string[] = [];
  const results: string[] = [];

  models.forEach((m) => {
    const filePath = path.join(outDir, `${m.name}.gg`);
    const content = `// ${m.name}.gg — ${m.desc}\n\n${m.flow}\n`;
    fs.writeFileSync(filePath, content, 'utf8');

    verifyNodes.push(
      `(${m.name}: Verify { module: './${m.name}.gg', beta1_max: '6' })`
    );
    forkNames.push(m.name);
    raceFolds.push(
      `(${m.name})-[:RACE { expect: 'safe' }]->(${m.name}_res: Result)`
    );
    results.push(`${m.name}_res`);
  });

  testSuiteContent += verifyNodes.join('\n') + '\n\n';
  testSuiteContent += `(test_suite)-[:FORK]->(${forkNames.join(' | ')})\n\n`;
  testSuiteContent += raceFolds.join('\n') + '\n\n';
  testSuiteContent += `(${results.join(
    ' | '
  )})-[:FOLD { strategy: 'all-pass' }]->(verdict: Verdict)\n`;

  fs.writeFileSync(
    path.join(outDir, `${categoryName}.test.gg`),
    testSuiteContent,
    'utf8'
  );
}

console.log(
  `Successfully generated models and test harnesses for all categories without temporal numbering.`
);
