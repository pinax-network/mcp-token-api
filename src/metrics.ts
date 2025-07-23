import promClient from 'prom-client';

// Create a registry for our metrics
export const register = new promClient.Registry();

// Tool calls counter metric
export const toolCallsCounter = new promClient.Counter({
  name: 'tokenapi_mcp_tool_calls_total',
  help: 'Total number of MCP tool calls',
  labelNames: ['tool_name', 'status'] as const,
  registers: [register]
});

// Tool call duration histogram metric
export const toolCallDurationHistogram = new promClient.Histogram({
  name: 'tokenapi_mcp_tool_call_duration_seconds',
  help: 'Duration of MCP tool calls in seconds',
  labelNames: ['tool_name'] as const,
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
  registers: [register]
});

// Helper function to track tool execution
export async function trackToolExecution<T>(
  toolName: string,
  execution: () => Promise<T>
): Promise<T> {
  const endTimer = toolCallDurationHistogram.startTimer({ tool_name: toolName });
  
  try {
    const result = await execution();
    
    // Record successful execution
    toolCallsCounter.inc({ tool_name: toolName, status: 'success' });
    endTimer();
    
    return result;
  } catch (error) {
    // Record failed execution
    toolCallsCounter.inc({ tool_name: toolName, status: 'error' });
    endTimer();
    
    throw error;
  }
}

// Export metrics endpoint handler
export async function getMetrics(): Promise<string> {
  return await register.metrics();
}

// Start metrics server using Bun
export function startMetricsServer(hostname: string = "0.0.0.0", port: number = 9090) {
  const server = Bun.serve({
    hostname,
    port,
    async fetch(req) {
      const url = new URL(req.url);
      
      if (url.pathname === '/metrics') {
        return new Response(await getMetrics(), {
          headers: {
            'Content-Type': 'text/plain; version=0.0.4; charset=utf-8',
          },
        });
      }
      
      if (url.pathname === '/health') {
        return new Response('OK', { status: 200 });
      }
      
      return new Response('Not Found', { status: 404 });
    },
  });

  console.log(`Metrics server running on http://localhost:${port}/metrics`);
  return server;
}