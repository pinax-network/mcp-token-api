import "dotenv/config";
import { z } from 'zod';
import { Option, program } from "commander";
import { $ } from "bun";

import pkg from "../package.json" with { type: "json" };

// defaults
export const DEFAULT_PORT = "8080";
export const DEFAULT_METRICS_PORT = "9090";
export const DEFAULT_HOSTNAME = "localhost";
export const DEFAULT_URL = "http://localhost:8123";
export const DEFAULT_DATABASE = "default";
export const DEFAULT_USERNAME = "default";
export const DEFAULT_PASSWORD = "";
export const DEFAULT_PRETTY_LOGGING = false;
export const DEFAULT_VERBOSE = false;

// GitHub metadata
const GIT_COMMIT = (process.env.GIT_COMMIT ?? await $`git rev-parse HEAD`.text()).replace(/\n/, "").slice(0, 7);
const GIT_DATE = (process.env.GIT_DATE ?? await $`git log -1 --format=%cd --date=short`.text()).replace(/\n/, "");
const GIT_REPOSITORY = (process.env.GIT_REPOSITORY ?? await $`git config --get remote.origin.url`.text()).replace(/git@github.com:/, "").replace(".git", "").replace(/\n/, "");
export const GIT_APP = {
    version: pkg.version as `${number}.${number}.${number}`,
    commit: GIT_COMMIT,
    date: GIT_DATE as `${number}-${number}-${number}`,
    repo: GIT_REPOSITORY,
};
export const APP_NAME = pkg.name;
export const APP_DESCRIPTION = pkg.description;
export const APP_VERSION = `${GIT_APP.version}+${GIT_APP.commit} (${GIT_APP.date})`;

// parse command line options
const opts = program
    .name(pkg.name)
    .version(APP_VERSION)
    .description(APP_DESCRIPTION)
    .showHelpAfterError()
    .addOption(new Option("-p, --port <number>", "HTTP port on which to attach the MCP SSE server").env("PORT").default(DEFAULT_PORT))
    .addOption(new Option("--metrics-port <number>", "HTTP port for Prometheus metrics endpoint").env("METRICS_PORT").default(DEFAULT_METRICS_PORT))
    .addOption(new Option("--url <string>", "Database HTTP hostname").env("URL").default(DEFAULT_URL))
    .addOption(new Option("--database <string>", "The database to use inside ClickHouse").env("DATABASE").default(DEFAULT_DATABASE))
    .addOption(new Option("--username <string>", "Database user for API").env("USERNAME").default(DEFAULT_USERNAME))
    .addOption(new Option("--password <string>", "Password associated with the specified API username").env("PASSWORD").default(DEFAULT_PASSWORD))
    .addOption(new Option("--pretty-logging <boolean>", "Enable pretty logging (default JSON)").choices(["true", "false"]).env("PRETTY_LOGGING").default(DEFAULT_PRETTY_LOGGING))
    .addOption(new Option("-v, --verbose <boolean>", "Enable verbose logging").choices(["true", "false"]).env("VERBOSE").default(DEFAULT_VERBOSE))
    .parse()
    .opts();

let config = z.object({
    port: z.coerce.number(),
    metricsPort: z.coerce.number(),
    url: z.string(),
    database: z.string(),
    username: z.string(),
    password: z.string(),
    // `z.coerce.boolean` doesn't parse boolean string values as expected (see https://github.com/colinhacks/zod/issues/1630)
    prettyLogging: z.coerce.string().transform((val) => val.toLowerCase() === "true"),
    verbose: z.coerce.string().transform((val) => val.toLowerCase() === "true"),
}).parse(opts);

export { config };
