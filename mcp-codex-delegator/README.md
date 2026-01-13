# MCP Codex Delegator

Delegates orchestration agents to Codex while preserving MCP tool access.

## Installation

```bash
pip install -e .
```

## Configuration

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "codex_delegator": {
      "type": "stdio",
      "command": "/path/to/.venv/bin/python",
      "args": ["-m", "mcp_codex_delegator.server"],
      "env": {
        "AGENT_TEMPLATES_PATH": ".claude/agents"
      }
    }
  }
}
```

## Usage

```python
mcp__codex_delegator__invoke_agent(
  agent="detective",
  task_prompt="Investigate authentication failure",
  task_id="RCH-123"
)
```

## Available Agents

- `scout` - Codebase exploration
- `detective` - Bug investigation
- `architect` - Implementation planning
- `scribe` - Documentation
- `code-reviewer` - Code review
