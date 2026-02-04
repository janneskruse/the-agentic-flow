#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const args = process.argv.slice(2);
const command = args[0];

const packageDir = path.dirname(__dirname);
const bootstrapScript = path.join(packageDir, 'bootstrap.py');

function getPythonCommand() {
  try {
    execSync('python3 --version', { stdio: 'ignore' });
    return 'python3';
  } catch (e) {
    try {
      execSync('python --version', { stdio: 'ignore' });
      return 'python';
    } catch (e2) {
      console.error('❌ Python 3 not found. Please install Python from https://python.org');
      process.exit(1);
    }
  }
}

function showHelp() {
  console.log(`
the-agentic-flow - Multi-agent orchestration for Claude Code

Usage:
  beads-orchestration <command> [options]

Commands:
  install          Run postinstall to copy skill to ~/.claude/
  bootstrap        Run bootstrap.py directly (advanced)
  help             Show this help message

Examples:
  npx @apapacho/the-agentic-flow install
  npx @apapacho/the-agentic-flow bootstrap --project-dir /path/to/project --claude-only
  npx @apapacho/the-agentic-flow bootstrap --project-dir /path/to/project --antigravity

After installing, use /create-beads-orchestration in Claude Code.
`);
}

function runInstall() {
  const postinstall = path.join(__dirname, 'postinstall.js');
  require(postinstall);
}

function runBootstrap() {
  const bootstrapArgs = args.slice(1).join(' ');
  const pythonCmd = getPythonCommand();
  try {
    execSync(`${pythonCmd} "${bootstrapScript}" ${bootstrapArgs}`, { stdio: 'inherit' });
  } catch (err) {
    process.exit(err.status || 1);
  }
}

switch (command) {
  case 'install':
    runInstall();
    break;
  case 'bootstrap':
    runBootstrap();
    break;
  case 'help':
  case '--help':
  case '-h':
  case undefined:
    showHelp();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    showHelp();
    process.exit(1);
}
