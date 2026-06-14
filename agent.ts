// agent.ts — OpenAI Agents SDK + Composio

import { Composio } from "@composio/core";
import { Agent, run, hostedMcpTool } from "@openai/agents";

const composio = new Composio();
const userId = "user_nar8b";

// Create a tool router session
const session = await composio.create(userId);

// Create agent with MCP tool
const agent = new Agent({
  name: "Composio Assistant",
  model: "gpt-4.1",
  instructions: "You are a helpful assistant. Use Composio tools to execute tasks.",
  tools: [
    hostedMcpTool({
      serverLabel: "composio",
      serverUrl: session.mcp.url,
      headers: session.mcp.headers,
    }),
  ],
});

const result = await run(
  agent,
  "Star the composiohq/composio repo on GitHub"
);

if (result.finalOutput) {
  console.log(result.finalOutput);
}