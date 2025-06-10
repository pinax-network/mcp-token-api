# mcp-token-api

Run with [Bun](https://bun.sh):
```console
$ bun run index.ts
```

Server will be running on `http://localhost:8080/sse` for SSE and `http://localhost:8080/stream` for HTTP streaming.

```console
Usage: mcp-token-api [options]

MCP server for The Graph Token API

Options:
  -V, --version               output the version number
  -p, --port <number>         HTTP port on which to attach the MCP SSE server (default: "8080", env: PORT)
  --url <string>              Database HTTP hostname (default: "http://localhost:8123", env: URL)
  --database <string>         The database to use inside ClickHouse (default: "default", env: DATABASE)
  --username <string>         Database user for API (default: "default", env: USERNAME)
  --password <string>         Password associated with the specified API username (default: "", env: PASSWORD)
  --pretty-logging <boolean>  Enable pretty logging (default JSON) (choices: "true", "false", default: false, env: PRETTY_LOGGING)
  -v, --verbose <boolean>     Enable verbose logging (choices: "true", "false", default: false, env: VERBOSE)
  -h, --help                  display help for command
```

