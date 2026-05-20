#!/usr/bin/env node

// oh-my-tbd CLI — bootstrap placeholder
// Real implementation lands in the next session. See NEXT-SESSION.md priority 3.
// Design context: DESIGN-LOG.md decisions D-037, D-038, D-039, D-047.

'use strict';

const args = process.argv.slice(2);
const [verb, name] = args;

if (verb === 'hook' && name) {
  // Veto-check and other hook subcommands will live here.
  // For now: emit the JSON allow-shape so a wired hook does not block anything.
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'allow',
      permissionDecisionReason: 'tbd CLI bootstrap — no checks implemented yet'
    }
  }));
  process.exit(0);
}

if (verb === 'version' || verb === '--version' || verb === '-v') {
  process.stdout.write('oh-my-tbd 0.0.1 (bootstrap)\n');
  process.exit(0);
}

process.stdout.write('oh-my-tbd CLI — bootstrap placeholder. Args received: ' + JSON.stringify(args) + '\n');
process.exit(0);
