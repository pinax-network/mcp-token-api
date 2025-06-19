import { Resource, ResourceTemplate, UserError } from "fastmcp";
import { instructions } from "./prompts";

export const resources: Resource[] = [{
	uri: "file:///mcp_token_api_general_instructions.txt",
	name: "Token API MCP General Usage Instructions",
	mimeType: "text/plain",
	async load() {
		return {
			text: instructions,
		};
	},
}];
export const resourceTemplates: ResourceTemplate[] = [];