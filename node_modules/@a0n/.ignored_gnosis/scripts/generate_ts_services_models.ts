import fs from 'fs';
import path from 'path';

const outDir = path.resolve('.');

const categories = {
  shared_ui_sensors: [
    {
      name: 'sensor_context_intelligence',
      desc: 'Context Intelligence from multi-modal sensors',
      flow: '(raw_sensor: Data)-[:PROCESS]->(aggregator: Logic)-[:PROCESS]->(context_intelligence: State)',
    },
    {
      name: 'sensor_ambient_light',
      desc: 'Ambient Light Adaptation',
      flow: '(lux: Number)-[:PROCESS]->(theme_mapper: Logic)-[:PROCESS]->(ui_theme: Style)',
    },
    {
      name: 'sensor_digital_phenotyping',
      desc: 'Digital Phenotyping Analysis',
      flow: '(device_usage: Logs)-[:PROCESS]->(behavior_model: ML)-[:PROCESS]->(phenotype: Profile)',
    },
    {
      name: 'sensor_morphcast_mapper',
      desc: 'Morphcast Emotion Mapper',
      flow: '(camera_feed: Video)-[:PROCESS]->(morphcast_engine: WebAssembly)-[:PROCESS]->(emotion_vector: CVM)',
    },
  ],
  shared_ui_aic: [
    {
      name: 'aic_fusion_engine',
      desc: 'AIC Fusion Engine processing',
      flow: "(text_cvm: Vector | audio_cvm: Vector | visual_cvm: Vector)-[:FOLD { strategy: 'attention-weights' }]->(fused_state: State)",
    },
    {
      name: 'aic_reasoning_engine',
      desc: 'AIC Reasoning Engine',
      flow: '(fused_state: State)-[:PROCESS]->(inductive_inference: Logic)-[:PROCESS]->(hypothesis: Outcome)',
    },
    {
      name: 'aic_bias_inducer',
      desc: 'Cognitive Bias Induction & Analysis',
      flow: "(hypothesis: Outcome)-[:FORK]->(semantic_pass: Logic | contextual_pass: Logic | temporal_pass: Logic)\n(semantic_pass | contextual_pass | temporal_pass)-[:FOLD { strategy: 'consensus' }]->(bias_report: Data)",
    },
    {
      name: 'aic_emotional_trigger',
      desc: 'Emotional Trigger Detection',
      flow: '(user_input: Text)-[:PROCESS]->(trigger_dictionary: DB)-[:PROCESS]->(arousal_spike: Alert)',
    },
  ],
  shared_ui_neural: [
    {
      name: 'neural_optimal_self',
      desc: 'Optimal Self Neural Model',
      flow: '(current_state: State)-[:PROCESS]->(optimal_self_model: ONNX)-[:PROCESS]->(growth_vector: Vector)',
    },
    {
      name: 'neural_goal_achievement',
      desc: 'Goal Achievement Predictor',
      flow: '(action_history: Logs)-[:PROCESS]->(goal_model: ML)-[:PROCESS]->(success_probability: Metric)',
    },
    {
      name: 'neural_stress_response',
      desc: 'Stress Response Modeling',
      flow: '(biometrics: Data)-[:PROCESS]->(stress_model: ML)-[:PROCESS]->(intervention_plan: Strategy)',
    },
    {
      name: 'neural_live_word',
      desc: 'Live Word Model Inference',
      flow: '(audio_stream: Buffer)-[:PROCESS]->(live_word_model: WebGPU)-[:PROCESS]->(transcript: Text)',
    },
  ],
  shared_ui_pensieve: [
    {
      name: 'pensieve_offline_sync',
      desc: 'Pensieve Offline Repository Sync',
      flow: '(local_mutation: Event)-[:FORK]->(indexeddb: Storage | remote_queue: Queue)\n(remote_queue)-[:PROCESS]->(d1_database: DB)',
    },
    {
      name: 'pensieve_ucan_protection',
      desc: 'Pensieve UCAN Protection Gate',
      flow: '(memory_request: Intent)-[:PROCESS]->(ucan_validator: Logic)-[:PROCESS]->(decrypted_memory: Data)',
    },
    {
      name: 'pensieve_narrative_curation',
      desc: 'Narrative Curation Service',
      flow: '(memories: Array)-[:PROCESS]->(llm_curator: Model)-[:PROCESS]->(story_arc: Document)',
    },
    {
      name: 'pensieve_social_energy',
      desc: 'Social Energy Tracking',
      flow: '(interaction: Event)-[:PROCESS]->(energy_calculator: Logic)-[:PROCESS]->(social_battery: Metric)',
    },
  ],
  shared_ui_metacognition: [
    {
      name: 'metacog_cyrano_consciousness',
      desc: 'Cyrano Consciousness Loop',
      flow: "(user_action: Event)-[:FORK]->(self_evaluator: Logic | user_feedback: Logic)\n(self_evaluator | user_feedback)-[:FOLD { strategy: 'reconcile' }]->(agent_growth: State)",
    },
    {
      name: 'metacog_ombuds_mode',
      desc: 'Ombudsman Conflict Resolution',
      flow: '(conflict_detected: Alert)-[:PROCESS]->(ombuds_engine: Logic)-[:PROCESS]->(mediation_strategy: Plan)',
    },
    {
      name: 'metacog_halogram_bridge',
      desc: 'Halogram Memory Bridge',
      flow: '(current_context: Context)-[:PROCESS]->(senju_whispers: DB)-[:PROCESS]->(holographic_projection: UI)',
    },
    {
      name: 'metacog_personality_calibration',
      desc: 'Personality Calibration Layers',
      flow: '(base_traits: Profile)-[:PROCESS]->(c1_confidence: Logic)-[:PROCESS]->(c2_coherence: Logic)-[:PROCESS]->(c3_bias_check: Logic)',
    },
  ],
  shared_ui_core_services: [
    {
      name: 'core_entrainment_engine',
      desc: 'Binaural Entrainment Engine',
      flow: "(target_hz: Number)-[:FORK]->(left_ear: Audio | right_ear: Audio)\n(left_ear | right_ear)-[:FOLD { strategy: 'stereo-mix' }]->(brainwave_sync: Output)",
    },
    {
      name: 'core_hume_unified',
      desc: 'Hume Unified Emotion Service',
      flow: '(face_mesh: Data)-[:PROCESS]->(hume_api: Network)-[:PROCESS]->(unified_emotions: Map)',
    },
    {
      name: 'core_generative_ui',
      desc: 'Generative UI Service',
      flow: '(intent: Intent)-[:PROCESS]->(react_server_components: System)-[:PROCESS]->(dynamic_layout: DOM)',
    },
    {
      name: 'core_zk_encryption',
      desc: 'Zero Knowledge Encryption',
      flow: '(payload: Data)-[:PROCESS]->(key_derivation: Crypto)-[:PROCESS]->(cipher_text: Blob)',
    },
  ],
};

for (const [categoryName, models] of Object.entries(categories)) {
  let testSuiteContent = `// ${categoryName}.test.gg — Verification harness for ${categoryName.replace(
    /_/g,
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

console.log(`Successfully generated TypeScript shared-ui service topologies.`);
