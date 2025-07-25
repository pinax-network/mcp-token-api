import { z } from "zod";
import { escapeSQL, runSQLMCP } from "./utils.js";
import { Tool } from "fastmcp";
import { trackToolExecution } from "./metrics.js";

export default [
    {
        name: "list_databases",
        description: "List available databases",
        parameters: z.object({}), // Always needs a parameter (even if empty)
        execute: async (_, { reportProgress }) => {
            return trackToolExecution("list_databases", async () => {
                const query = `SELECT name, comment AS description
                    FROM system.databases
                    WHERE
                        name LIKE '%@%';
                    `;
                return runSQLMCP(query, reportProgress);
            });
        },
    },
    {
        name: "list_tables",
        description: "List available tables from a database",
        parameters: z.object({
            database: z.string()
        }),
        execute: async (args, { reportProgress }) => {
            return trackToolExecution("list_tables", async () => {
                // Filter out backfill tables
                const query = `SELECT name, comment AS description
                    FROM system.tables
                    WHERE
                        database = ${escapeSQL(args.database).replaceAll('"', "'")}
                        AND name NOT LIKE 'backfill_%'
                        AND name NOT LIKE '.inner_%'
                        AND name NOT LIKE 'cursors';
                    `;
                return runSQLMCP(query, reportProgress);
            });
        },
    },
    {
        name: "describe_table",
        description: "Describe the schema of a table from a database",
        parameters: z.object({
            database: z.string(),
            table: z.string(),
        }),
        execute: async (args, { reportProgress }) => {
            return trackToolExecution("describe_table", async () => {
                return runSQLMCP(`DESCRIBE ${escapeSQL(args.database)}.${escapeSQL(args.table)}`, reportProgress);
            });
        },
    },
    {
        name: "run_query",
        description: "Run a read-only SQL query",
        parameters: z.object({
            query: z.string()
        }),
        execute: async (args, { reportProgress }) => {
            return trackToolExecution("run_query", async () => {
                return runSQLMCP(args.query, reportProgress, true);
            });
        },
    },
] as Tool<undefined, z.ZodTypeAny>[];