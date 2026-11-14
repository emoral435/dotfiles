import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// In-session scheduler. Timers live only while pi runs; quitting cancels them.
export default function (pi: ExtensionAPI) {
  const timers = new Set<ReturnType<typeof setTimeout>>();

  pi.on("session_shutdown", () => {
    for (const t of timers) clearTimeout(t);
    timers.clear();
  });

  pi.registerTool({
    name: "schedule_wakeup",
    label: "Schedule Wakeup",
    description:
      "Wake the agent after a delay by injecting a follow-up message. Use to wait out a timed event (e.g. bot review ~6 min after a push) without blocking.",
    parameters: Type.Object({
      delaySeconds: Type.Number({ description: "Delay before wakeup, in seconds (1-86400)" }),
      note: Type.String({ description: "Reminder text delivered on wakeup" }),
    }),
    async execute(_toolCallId, params) {
      const delay = Math.min(Math.max(Math.round(params.delaySeconds), 1), 86400);
      const fireAt = new Date(Date.now() + delay * 1000).toISOString();
      const timer = setTimeout(() => {
        timers.delete(timer);
        pi.sendUserMessage(`[wakeup] ${params.note}`, { deliverAs: "followUp" });
      }, delay * 1000);
      timer.unref?.();
      timers.add(timer);
      return {
        content: [{ type: "text", text: `Wakeup scheduled in ${delay}s (at ${fireAt}): ${params.note}` }],
        details: {},
      };
    },
  });
}
