import { FastMCP } from "fastmcp";

import { APP_VERSION, config, GIT_APP } from "./src/config.js";
import { logger } from "./src/logger.js";
import tools from "./src/tools.js";
import prompts from "./src/prompts.js";
import { resources, resourceTemplates } from "./src/resources.js";

const mcp = new FastMCP({
    name: APP_VERSION,
    version: GIT_APP.version,
});

// Catch session errors (default MCP SDK timeout of 10 seconds) and close connection
mcp.on("connect", (event) => {
    const session = event.session;
    session.on('error', async (e) => {
        logger.error(`[${session}] Error:`, e.error);
        await session.close();
    });
});

mcp.on("disconnect", (event) => {
    const session = event.session;
    session.removeAllListeners();
});

// Populate server features: Tools, ResourceTemplates, Resources and Prompts
// See https://spec.modelcontextprotocol.io/specification/2024-11-05/server/
tools.map((tool) => mcp.addTool(tool));
resourceTemplates.map((resourceTemplate) => mcp.addResourceTemplate(resourceTemplate));
//resources.map((resource) => mcp.addResource(resource));
prompts.map((prompt) => mcp.addPrompt(prompt));

await mcp.start({
    transportType: "httpStream",
    httpStream: {
        port: config.port,
    },
});
