#!/usr/bin/env node

// oh-my-tbd CLI — post-reset (session-9 architectural reset, slice 6).
//
// The s3 narrow safety hook: refuses ONLY three chainsaw operations on trunk.
// Everything else is conversation, not refusal.
//
//   1. git push --force (and --force-with-lease, --force-if-includes) to trunk
//   2. git reset --hard on trunk (or when current branch is undetectable)
//   3. git branch -D / -d / --delete <trunk> (never delete trunk)
//
// Trunk is detected dynamically:
//   1. .tbd/config.yaml trunk_branch: <name> override (manual config)
//   2. git symbolic-ref refs/remotes/origin/HEAD (the remote default)
//   3. git config init.defaultBranch (the user's git default)
//   4. probe local branches main / master / trunk in that order
//   5. fall back to "main"
//
// Surface: `tbd hook safety-check`, `tbd version`. No pa-coordination,
// no archive-pa, no navigator carve-out, no skip-detection. Those came
// out in the slice-6 collapse.

'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

// ---------- main ----------

const args = process.argv.slice(2);
const [verb, name] = args;

if (verb === 'hook' && name === 'safety-check') {
  runSafetyCheck()
    .then((decision) => emit(decision))
    .catch((err) => emit(allow('tbd safety-check: internal error — ' + redact(err && err.message ? err.message : String(err)))));
} else if (verb === 'version' || verb === '--version' || verb === '-v') {
  process.stdout.write('oh-my-tbd 0.1.0 (post-reset)\n');
  process.exit(0);
} else {
  process.stdout.write('oh-my-tbd CLI — available subcommands: `hook safety-check`, `version`.\n');
  process.exit(0);
}

// ---------- safety-check ----------

async function runSafetyCheck() {
  const hookInput = await readStdinJson();
  const toolName = hookInput && hookInput.tool_name;
  const toolInput = (hookInput && hookInput.tool_input) || {};

  // Only Bash can issue chainsaw operations. Everything else (Write, Edit,
  // NotebookEdit, Read, Grep, Glob, etc.) is conversation surface.
  if (toolName !== 'Bash') {
    return allow('tbd: ' + String(toolName) + ' is not a chainsaw operation surface');
  }

  const command = (typeof toolInput.command === 'string') ? toolInput.command : '';
  const cwd = process.env.CLAUDE_PROJECT_DIR || hookInput.cwd || process.cwd();

  const refusal = chainsawRefusal(command, cwd);
  if (refusal) return deny(refusal);
  return allow('tbd: not a chainsaw operation against trunk');
}

function chainsawRefusal(command, cwd) {
  const tokens = tokeniseGitCommand(command);
  if (!tokens || tokens[0] !== 'git') return null;

  // Skip global git options between `git` and the subcommand.
  let i = 1;
  while (i < tokens.length && tokens[i].startsWith('-')) {
    if (tokens[i] === '-c' || tokens[i] === '-C' || tokens[i] === '--git-dir' || tokens[i] === '--work-tree') {
      i++; // consume the option's argument
    }
    i++;
  }

  const sub = tokens[i];
  const rest = tokens.slice(i + 1);
  const trunk = detectTrunk(cwd);

  if (sub === 'push') return refusePushIfForceOnTrunk(rest, trunk, cwd);
  if (sub === 'reset') return refuseResetIfHardOnTrunk(rest, trunk, cwd);
  if (sub === 'branch') return refuseBranchIfDeleteTrunk(rest, trunk);
  return null;
}

function refusePushIfForceOnTrunk(args, trunk, cwd) {
  const isForce = args.some((a) =>
    a === '--force' || a === '-f' ||
    a === '--force-with-lease' || a.startsWith('--force-with-lease=') ||
    a === '--force-if-includes'
  );
  if (!isForce) return null;

  const positional = args.filter((a) => !a.startsWith('-'));
  let targetBranch = null;
  if (positional.length >= 2) {
    // refspec syntax: [+]<src>[:<dst>] — target is dst if present else src.
    let refspec = positional[1].replace(/^\+/, '');
    const colonIdx = refspec.indexOf(':');
    const part = (colonIdx >= 0) ? refspec.slice(colonIdx + 1) : refspec;
    targetBranch = part.replace(/^refs\/heads\//, '');
  } else {
    // No explicit refspec — push pushes the current branch.
    targetBranch = currentBranch(cwd);
  }

  if (targetBranch === trunk) {
    return 'TBD safety hook: refusing force-push to trunk (' + trunk + '). Force-push to a feature branch instead, or discuss with the human if rewriting trunk history is truly intended.';
  }
  return null;
}

function refuseResetIfHardOnTrunk(args, trunk, cwd) {
  if (!args.includes('--hard')) return null;
  const current = currentBranch(cwd);
  // Fail-closed: refuse when current is trunk OR undetectable.
  if (current === null || current === trunk) {
    return 'TBD safety hook: refusing hard-reset on trunk (' + (current || 'current branch undetectable') + '). Switch to a feature branch first, or use --soft / --mixed.';
  }
  return null;
}

function refuseBranchIfDeleteTrunk(args, trunk) {
  const isDelete = args.some((a) => a === '-D' || a === '-d' || a === '--delete');
  if (!isDelete) return null;

  const positional = args.filter((a) => !a.startsWith('-'));
  const target = positional[positional.length - 1];
  if (target === trunk) {
    return 'TBD safety hook: refusing to delete trunk branch (' + trunk + '). Trunk is not deletable through this hook.';
  }
  return null;
}

// ---------- trunk detection ----------

function detectTrunk(cwd) {
  // 1. .tbd/config.yaml override
  try {
    const cfg = fs.readFileSync(path.join(cwd, '.tbd', 'config.yaml'), 'utf8');
    const m = cfg.match(/^trunk_branch:\s*(\S+)/m);
    if (m) return m[1];
  } catch (_) {}

  // 2. origin/HEAD symbolic ref
  try {
    const out = execFileSync('git', ['-C', cwd, 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD'],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    if (out) return out.replace(/^origin\//, '');
  } catch (_) {}

  // 3. git config init.defaultBranch
  try {
    const out = execFileSync('git', ['-C', cwd, 'config', 'init.defaultBranch'],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    if (out) return out;
  } catch (_) {}

  // 4. Probe common trunk names
  for (const candidate of ['main', 'master', 'trunk']) {
    try {
      execFileSync('git', ['-C', cwd, 'show-ref', '--verify', '--quiet', 'refs/heads/' + candidate],
        { stdio: 'ignore' });
      return candidate;
    } catch (_) {}
  }

  // 5. Final fallback
  return 'main';
}

function currentBranch(cwd) {
  try {
    const out = execFileSync('git', ['-C', cwd, 'branch', '--show-current'],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    return out || null;
  } catch (_) {
    return null;
  }
}

// ---------- helpers ----------

function tokeniseGitCommand(command) {
  if (typeof command !== 'string' || !command.trim()) return null;
  // Reject shell-control characters — they can hide a chainsaw behind a leading safe command.
  // For now, treat such commands as "we can't parse, let it through" — chained chainsaws are
  // a separate concern. The hook is a fat-finger guard, not a sandbox.
  if (/[;&]|&&|\|\|/.test(command) || /[><]/.test(command) || /\$\(|`/.test(command)) {
    return null;
  }
  let rest = command.trim();
  // Strip leading env-var assignments (FOO=bar VAR=x cmd ...)
  while (/^[A-Za-z_][A-Za-z0-9_]*=\S+\s+/.test(rest)) {
    rest = rest.replace(/^[A-Za-z_][A-Za-z0-9_]*=\S+\s+/, '');
  }
  return rest.split(/\s+/);
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
