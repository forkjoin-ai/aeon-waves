import fs from 'fs';
import path from 'path';

const outDir = path.resolve('.');

const categories = {
  backend_account_management: [
    {
      name: 'account_link_service',
      desc: 'Account linking service flow',
      flow: `(req: LinkAccount)-[:PROCESS]->(verify_identity: Check)-[:PROCESS]->(create_link: DB)`,
    },
    {
      name: 'digital_twin_access_service',
      desc: 'Digital twin data access service',
      flow: `(req: DataAccess)-[:PROCESS]->(permission_check: Auth)-[:PROCESS]->(access_twin_data: Data)`,
    },
    {
      name: 'permission_audit_log',
      desc: 'Permission audit logging',
      flow: `(action: Event)-[:PROCESS]->(log_permission: Audit)-[:PROCESS]->(store_audit: DB)`,
    },
  ],
  backend_cyrano_core: [
    {
      name: 'hologram_service',
      desc: 'Hologram response generation',
      flow: `(user_utterance: Text)-[:PROCESS]->(nlp_parse: NLP)-[:PROCESS]->(generate_hologram_response: AI)`,
    },
    {
      name: 'autonomous_action_engine',
      desc: 'Autonomous action decision and execution',
      flow: `(event: Trigger)-[:PROCESS]->(action_approver: Logic)-[:PROCESS]->(execute_action: System)`,
    },
    {
      name: 'cyrano_workflow_orchestrator',
      desc: 'Cyrano workflow orchestration',
      flow: `(workflow_trigger: Event)-[:PROCESS]->(template_lookup: Config)-[:PROCESS]->(execute_workflow_steps: Flow)`,
    },
  ],
  backend_predictive_analytics: [
    {
      name: 'predictive_engine',
      desc: 'General predictive engine flow',
      flow: `(input_data: Metrics)-[:PROCESS]->(model_inference: ML)-[:PROCESS]->(prediction: Forecast)`,
    },
    {
      name: 'behavioral_predictor',
      desc: 'Behavioral prediction from user data',
      flow: `(behavior_stream: Log)-[:PROCESS]->(pattern_recognizer: ML)-[:PROCESS]->(next_behavior_prediction: Event)`,
    },
    {
      name: 'financial_stress_predictor',
      desc: 'Financial stress prediction',
      flow: `(financial_data: Metrics)-[:PROCESS]->(stress_model: ML)-[:PROCESS]->(stress_alert: Alert)`,
    },
  ],
  backend_data_persistence: [
    {
      name: 'firestore_client',
      desc: 'Firestore database interaction',
      flow: `(request: Query)-[:PROCESS]->(firestore_api: DB)-[:PROCESS]->(results: Data)`,
    },
    {
      name: 'user_profile_repository',
      desc: 'User profile storage and retrieval',
      flow: `(update: Profile)-[:PROCESS]->(validate_schema: Schema)-[:PROCESS]->(persist_profile: DB)`,
    },
    {
      name: 'log_repository',
      desc: 'System log persistence',
      flow: `(log_event: Event)-[:PROCESS]->(format_log: Transform)-[:PROCESS]->(store_log: DB)`,
    },
  ],
  backend_communications: [
    {
      name: 'email_service',
      desc: 'Email sending service',
      flow: `(email_request: Message)-[:PROCESS]->(template_renderer: HTML)-[:PROCESS]->(send_email: Mailgun)`,
    },
    {
      name: 'sms_service',
      desc: 'SMS sending service',
      flow: `(sms_request: Message)-[:PROCESS]->(sms_gateway: Network)-[:PROCESS]->(send_sms: SMS)`,
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
    // Use template literal for content directly, ensuring newlines are literal
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
  `Successfully generated TypeScript shared-backend service topologies.`
);
