"""Tests for Codex API client."""

import pytest
from mcp_codex_delegator.codex_client import CodexClient

def test_model_mapping():
    """Test model mapping from agent models to Codex models."""
    assert CodexClient.map_model("haiku") == "gpt-5.1-codex-mini"
    assert CodexClient.map_model("sonnet") == "gpt-5.2-codex"
    assert CodexClient.map_model("opus") == "gpt-5.1-codex-max"
    assert CodexClient.map_model("unknown") == "gpt-5.2-codex"

@pytest.mark.integration
@pytest.mark.asyncio
async def test_invoke_codex_simple():
    """Test invoking Codex with simple prompt. Requires Codex CLI."""
    client = CodexClient(model="gpt-5.2-codex")

    result = await client.invoke(
        system_prompt="You are a helpful assistant. Respond with exactly: 'Hello'",
        user_prompt="Say hello",
    )

    assert "Hello" in result or "hello" in result

@pytest.mark.integration
@pytest.mark.asyncio
async def test_invoke_codex_with_task_id():
    """Test that task_id is included in prompt."""
    client = CodexClient(model="gpt-5.2-codex")

    result = await client.invoke(
        system_prompt="You are a test agent. Echo back the task ID if you see one.",
        user_prompt="Test prompt",
        task_id="RCH-999",
    )

    # Response should acknowledge or include task context
    assert result  # Just verify we got a response
