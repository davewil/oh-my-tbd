#!/usr/bin/env node

// oh-my-tbd CLI
// Design context: DESIGN-LOG.md decisions D-014, D-034, D-037, D-038, D-039, D-043, D-046, D-047, D-048.
// Walking-skeleton surface: `tbd hook veto-check`, `tbd version`.
// Per D-038 the eventual source-of-truth is TypeScript in src/, compiled to bin/.
// Build chain not in this milestone — plain JS for now.

'use strict';

const fs = require('fs');
const path = require('path');

const STATE_CHANGING_TOOLS = new Set(['Write', 'Edit', 'NotebookEdit', 'Bash']);

// Read-only Bash commands bypass veto-check (analogous to Read/Grep/Glob bypass — D-043).
// Match the first verb of the command; if it's in this set, the call is treated as read-only.
// Conservative: anything not on this list goes through the discipline.
const READ_ONLY_BASH_VERBS = new Set([
  'ls', 'cat', 'head', 'tail', 'wc', 'grep', 'find', 'pwd', 'echo', 'printf',
  'file', 'stat', 'diff', 'tree', 'which', 'whereis', 'env', 'true', 'false',
  'date', 'uname', 'hostname', 'whoami', 'id', 'uptime', 'tty', 'awk', 'sed',
  'cut', 'sort', 'uniq', 'tr', 'jq', 'yq', 'column', 'tee',
]);

const READ_ONLY_GIT_SUBCOMMANDS = new Set([
  'status', 'diff', 'log', 'show', 'branch', 'tag', 'remote', 'config',
  'blame', 'describe', 'rev-parse', 'rev-list', 'ls-files', 'ls-tree',
  'cat-file', 'reflog', 'shortlog',
  'help', 'version',
]);

// ---------- main ----------

const args = process.argv.slice(2);
const [verb, name] = args;

if (verb === 'hook' && name === 'veto-check') {
  runVetoCheck()
    .then((decision) => emit(decision))
    .catch((err) => emit(allow('tbd veto-check: internal error — ' + redact(err && err.message ? err.message : String(err)))));
} else if (verb === 'hook' && name === 'archive-pa') {
  runArchivePa()
    .then((result) => emit(result))
    .catch((err) => emit(noop('tbd archive-pa: internal error — ' + redact(err && err.message ? err.message : String(err)))));
} else if (verb === 'version' || verb === '--version' || verb === '-v') {
  process.stdout.write('oh-my-tbd 0.0.1 (walking-skeleton)\n');
  process.exit(0);
} else {
  process.stdout.write('oh-my-tbd CLI — available subcommands: `hook veto-check`, `hook archive-pa`, `version`.\n');
  process.exit(0);
}

// ---------- veto-check ----------

async function runVetoCheck() {
  const hookInput = await readStdinJson();
  const toolName = hookInput && hookInput.tool_name;
  const toolInput = (hookInput && hookInput.tool_input) || {};

  if (!STATE_CHANGING_TOOLS.has(toolName)) {
    return allow('tbd: ' + String(toolName) + ' is not a state-changing tool');
  }

  if (toolName === 'Bash' && isReadOnlyBash(toolInput.command || '')) {
    return allow('tbd: read-only Bash command bypasses discipline');
  }

  const projectDir = process.env.CLAUDE_PROJECT_DIR || hookInput.cwd || process.cwd();
  const tbdDir = path.join(projectDir, '.tbd');

  // If the project has not initialised oh-my-tbd (no .tbd dir), discipline is dormant — allow.
  // The /oh-my-tbd:init flow (future milestone) creates .tbd and switches discipline on.
  if (!fs.existsSync(tbdDir)) {
    return allow('tbd: project not initialised (no .tbd directory)');
  }

  // D-051: orchestration substrate carve-out — Write/Edit/NotebookEdit calls targeting
  // paths inside .tbd/ bypass the pending-action.tool match. The discipline files
  // (veto.json, dissent-log.jsonl, pending-action.json itself, navigator-questions.jsonl)
  // are the discipline's own substrate; gating writes to them by pending-action creates
  // recursion (navigator cannot raise its own veto; pilot cannot update pa between actions
  // without tool gymnastics). Bash carve-out is OUT OF SCOPE — deferred per simple-design
  // concern about regex false positives over Bash command text.
  if (targetsTbdSubstrate(toolName, toolInput, tbdDir)) {
    return allow('tbd: orchestration substrate write bypasses pending-action check (D-051)');
  }

  const pendingPath = path.join(tbdDir, 'pending-action.json');
  const vetoPath = path.join(tbdDir, 'veto.json');

  // Skip-detection (D-043): no pending-action → hard refuse.
  if (!fs.existsSync(pendingPath)) {
    return deny(
      'TBD discipline: no pending action declared. ' +
      'Run /oh-my-tbd:start to declare intent, then write .tbd/pending-action.json and invoke the navigator subagent before mutating tools.'
    );
  }

  const pending = readJson(pendingPath);
  if (!pending) {
    return deny('TBD discipline: .tbd/pending-action.json is unreadable or malformed. Re-propose the action.');
  }
  if (pending.tool !== toolName) {
    return deny(
      'TBD discipline: pending action declares tool "' + pending.tool +
      '" but call is "' + toolName + '". Re-propose the actual action and re-invoke the navigator.'
    );
  }

  // Veto refusal (D-014 + D-048).
  if (fs.existsSync(vetoPath)) {
    const veto = readJson(vetoPath);
    if (!veto) {
      return deny('TBD discipline: .tbd/veto.json is unreadable or malformed. Navigator must rewrite or remove it before proceeding.');
    }
    if (veto.status === 'standing' && veto.blocked_action_ref === pending.id) {
      const parts = [];
      if (veto.principle_source && veto.principle) {
        parts.push(veto.principle_source + '/' + veto.principle);
      }
      if (veto.reason) parts.push(veto.reason);
      const firstRemedy = Array.isArray(veto.remedy) && veto.remedy.length > 0 ? veto.remedy[0] : null;
      if (firstRemedy) parts.push('Remedy: ' + firstRemedy);
      const body = parts.map((p) => p.replace(/\.\s*$/, '')).join('. ') + '.';
      return deny('TBD veto ' + (veto.id || '<no-id>') + ' standing — ' + body);
    }
    if (veto.status === 'escalated') {
      return deny('TBD veto ' + (veto.id || '<no-id>') + ' escalated — human resolution required before proceeding.');
    }
  }

  return allow('tbd: pending action matches, no standing veto');
}

// ---------- helpers ----------

function isReadOnlyBash(command) {
  if (typeof command !== 'string' || command.trim() === '') return false;

  // Reject shell-control characters that could chain mutations behind a read-only verb.
  if (/[;&]|&&|\|\|/.test(command)) return false;
  if (/[><]/.test(command)) return false;
  if (/\$\(|`/.test(command)) return false;

  // Strip leading env-var assignments (FOO=bar VAR=x cmd ...).
  let rest = command.trim();
  while (/^[A-Za-z_][A-Za-z0-9_]*=\S+\s+/.test(rest)) {
    rest = rest.replace(/^[A-Za-z_][A-Za-z0-9_]*=\S+\s+/, '');
  }

  const tokens = rest.split(/\s+/);
  const verb = tokens[0];
  if (!verb) return false;

  if (verb === 'git') {
    const sub = tokens[1] || '';
    if (sub === 'stash') {
      const stashSub = tokens[2] || '';
      return stashSub === '' || stashSub === 'list' || stashSub === 'show';
    }
    return READ_ONLY_GIT_SUBCOMMANDS.has(sub);
  }

  return READ_ONLY_BASH_VERBS.has(verb);
}

// ---------- archive-pa (D-052 soft per Q-034) ----------
//
// PostToolUse hook handler: when the just-completed tool call succeeded
// (hook_input.tool_response.success === true), move the consumed
// .tbd/pending-action.json to .tbd/archive/<session_id>/pa-<id>.json and
// remove the original. This makes pa truly single-shot: the next state-
// changing call requires a fresh pa (the existing PreToolUse skip-detection
// catches "no pa on disk"), and the audit trail of consumed pa's is preserved
// in .tbd/archive/.
//
// Per D-053 baseline-not-doctrine: this is a soft variant. Failures (missing
// pa, missing session-state, write errors) are silent no-ops, not refusals.
// The navigator catches semantic drift at next review; the hook only handles
// the success path.

async function runArchivePa() {
  const hookInput = await readStdinJson();
  const toolResponse = (hookInput && hookInput.tool_response) || {};

  // Success predicate (explicit per D-052 design + navigator Q1):
  // archive ONLY when the tool succeeded. Pilot can retry against the
  // same declared pa on failure.
  if (toolResponse.success !== true) {
    return noop('tbd archive-pa: tool did not succeed; pa not archived');
  }

  const projectDir = process.env.CLAUDE_PROJECT_DIR || hookInput.cwd || process.cwd();
  const tbdDir = path.join(projectDir, '.tbd');

  if (!fs.existsSync(tbdDir)) {
    return noop('tbd archive-pa: project not initialised (no .tbd directory)');
  }

  const pendingPath = path.join(tbdDir, 'pending-action.json');
  if (!fs.existsSync(pendingPath)) {
    return noop('tbd archive-pa: no pending-action to archive');
  }

  const pending = readJson(pendingPath);
  if (!pending || !pending.id) {
    return noop('tbd archive-pa: pending-action unreadable or missing id');
  }

  const sessionState = readJson(path.join(tbdDir, 'session-state.json'));
  const sessionId = (sessionState && sessionState.session_id) || 'unknown-session';

  const archiveDir = path.join(tbdDir, 'archive', sessionId);
  try {
    fs.mkdirSync(archiveDir, { recursive: true });
    const archivePath = path.join(archiveDir, pending.id + '.json');
    fs.copyFileSync(pendingPath, archivePath);
    fs.unlinkSync(pendingPath);
    return noop('tbd archive-pa: archived ' + pending.id + ' to ' + archivePath);
  } catch (_err) {
    return noop('tbd archive-pa: archive move failed; pa remains in place');
  }
}

function noop(reason) {
  // PostToolUse informational output — no permissionDecision needed.
  return {
    hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      reason: reason,
    },
  };
}

// D-051: precise carve-out for Write/Edit/NotebookEdit targeting .tbd/. Bash is intentionally
// excluded — see DESIGN-LOG D-051 and navigator's pa-004 simple-design concern about regex
// false positives over Bash command text.
function targetsTbdSubstrate(toolName, toolInput, tbdDir) {
  if (toolName !== 'Write' && toolName !== 'Edit' && toolName !== 'NotebookEdit') {
    return false;
  }
  const filePath = toolInput && toolInput.file_path;
  if (typeof filePath !== 'string') return false;
  return filePath.startsWith(tbdDir + path.sep) || filePath.startsWith(tbdDir + '/');
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (_) {
    return null;
  }
}

function readStdinJson() {
  return new Promise((resolve) => {
    if (process.stdin.isTTY) { resolve({}); return; }
    let buf = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => { buf += chunk; });
    process.stdin.on('end', () => {
      if (!buf.trim()) { resolve({}); return; }
      try { resolve(JSON.parse(buf)); } catch (_) { resolve({}); }
    });
    process.stdin.on('error', () => resolve({}));
  });
}

function allow(reason) {
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'allow',
      permissionDecisionReason: reason,
    },
  };
}

function deny(reason) {
  return {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: reason,
    },
  };
}

function emit(decision) {
  process.stdout.write(JSON.stringify(decision));
  process.exit(0);
}

function redact(s) {
  return String(s).replace(/(Authorization:\s*\S+|--password=\S+|api[_-]?key=\S+)/gi, '[redacted]');
}
