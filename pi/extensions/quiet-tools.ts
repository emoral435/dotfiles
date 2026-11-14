import { ToolExecutionComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Hides tool call blocks (assistant text still shows) and shows RUNNING while tools work. /tools toggles.
const FRAMES = ["▰▱▱▱▱", "▰▰▱▱▱", "▰▰▰▱▱", "▰▰▰▰▱", "▰▰▰▰▰", "▱▰▰▰▰", "▱▱▰▰▰", "▱▱▱▰▰", "▱▱▱▱▰", "▱▱▱▱▱"];
let hidden = true;
const proto = ToolExecutionComponent.prototype as any;
proto.__quietRender ??= proto.render;
proto.render = function (width: number) {
  return hidden ? [] : proto.__quietRender.call(this, width);
};

export default function (pi: ExtensionAPI) {
  let running = 0;
  const show = (ctx: any) => {
    if (!ctx.hasUI) return;
    if (hidden && running > 0) {
      ctx.ui.setWorkingIndicator({ frames: FRAMES.map((f) => `\x1b[36m${f}\x1b[0m`), intervalMs: 90 });
      ctx.ui.setWorkingMessage(`\x1b[1mRUNNING\x1b[0m \x1b[2m${running} tool${running > 1 ? "s" : ""}\x1b[0m`);
    } else {
      ctx.ui.setWorkingIndicator();
      ctx.ui.setWorkingMessage();
    }
  };
  pi.on("tool_execution_start", (_e, ctx) => { running++; show(ctx); });
  pi.on("tool_execution_end", (_e, ctx) => { running = Math.max(0, running - 1); show(ctx); });
  pi.on("agent_end", (_e, ctx) => { running = 0; show(ctx); });
  pi.registerCommand("tools", {
    description: "Show or hide tool call blocks",
    handler: async (_args, ctx) => {
      hidden = !hidden;
      show(ctx);
      ctx.ui.notify(hidden ? "Tool calls hidden" : "Tool calls shown", "info");
    },
  });
}
