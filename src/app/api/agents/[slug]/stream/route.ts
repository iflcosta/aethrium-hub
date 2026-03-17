const thoughtChunks = [
  "Analyzing task requirements...",
  "Loading context from previous execution...",
  "Checking Lua script compatibility...",
  "Running static analysis on module dependencies...",
  "Generating implementation plan...",
  "Writing function signatures...",
  "Implementing core logic...",
  "Adding error handling...",
  "Validating output against schema...",
  "Preparing handoff documentation...",
  "Cross-referencing with existing codebase...",
  "Optimizing performance bottlenecks...",
  "Running unit test simulations...",
  "Finalizing code review comments...",
  "Task checkpoint saved.",
];

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;

  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      let i = 0;
      const interval = setInterval(() => {
        const chunk = thoughtChunks[i % thoughtChunks.length];
        const data = JSON.stringify({
          agent: slug,
          chunk: `[${new Date().toISOString().slice(11, 19)}] ${chunk}`,
          index: i,
        });
        controller.enqueue(encoder.encode(`data: ${data}\n\n`));
        i++;
        if (i > 100) {
          clearInterval(interval);
          controller.close();
        }
      }, 3000);
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    },
  });
}
