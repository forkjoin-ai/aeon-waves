/* global process */
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [modulePath, inputJson, exportName = 'app'] = process.argv.slice(2);

if (!modulePath) {
  process.stderr.write(
    'Usage: invoke-app.mjs <module-path> [input-json] [export-name]\n'
  );
  process.exit(1);
}

const moduleUrl = pathToFileURL(path.resolve(modulePath)).href;
const namespace = await import(moduleUrl);
const callable = namespace[exportName];

if (typeof callable !== 'function') {
  process.stderr.write(`Export '${exportName}' was not found in ${modulePath}.\n`);
  process.exit(1);
}

const input = inputJson === undefined ? undefined : JSON.parse(inputJson);
const result = await callable(input);

if (typeof result === 'string') {
  process.stdout.write(`${result}\n`);
} else {
  process.stdout.write(`${JSON.stringify(result)}\n`);
}
