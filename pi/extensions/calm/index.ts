// Calm: a standalone Pi transcript-presentation toggle for any project.
//
// Calm hides the noise of a working session - built-in tool-call shells, tool results,
// collapsed thinking, and mid-turn assistant working notes - and keeps only the genuine
// prompts and replies. It is off by default; the last /calm choice persists across Pi
// session starts and resumes in ~/.pi/agent/calm-preference. Pi's stock "Working..." row
// is left untouched, so working activity stays visible.
//
// This build has no Firstmate dependency: no supervision imports, no FM_HOME, no
// operational-message classification, and no Firstmate-only configuration. It reuses the
// same supported Pi seams as Firstmate's project-local Calm, so the two coexist (see the
// command and built-in collision handling below and pi-calm/README.md).
//
// Pi has one first-registration-wins ToolDefinition per tool name, with no merge or
// unregister operation. Calm-off registration is empty; Calm-on load-time registration is
// synchronous because restored rows capture the registry before session_start; and the
// collision check runs only on the later first-activation path, when getAllTools() is
// reliable. Pi exposes no global renderer for arbitrary built-in or custom rows.
import { randomUUID } from "node:crypto";
import {
  mkdirSync,
  readFileSync,
  realpathSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type {
  ExtensionAPI,
  ExtensionUIContext,
  ToolDefinition,
  ToolInfo,
  ToolRenderResultOptions,
} from "@earendil-works/pi-coding-agent";
import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
  getAgentDir,
} from "@earendil-works/pi-coding-agent";
import { Box, Container, getKeybindings } from "@earendil-works/pi-tui";
import type { Component } from "@earendil-works/pi-tui";
import type { TSchema } from "typebox";
import { installCalmAssistantLayout } from "./lib/assistant-layout.ts";
import {
  calmPresentationHides,
  calmPresentationIsActive,
  setCalmPresentation,
  setCalmStockExportRendering,
} from "./lib/visibility.ts";

type DefinitionFactory<TParams extends TSchema, TDetails, TState> = (
  cwd: string,
) => ToolDefinition<TParams, TDetails, TState>;

type RenderContext<TParams extends TSchema, TDetails, TState> = Parameters<
  NonNullable<ToolDefinition<TParams, TDetails, TState>["renderCall"]>
>[2];

type RenderArgs<TParams extends TSchema, TDetails, TState> = Parameters<
  NonNullable<ToolDefinition<TParams, TDetails, TState>["renderCall"]>
>[0];

type RenderTheme<TParams extends TSchema, TDetails, TState> = Parameters<
  NonNullable<ToolDefinition<TParams, TDetails, TState>["renderCall"]>
>[1];

type RenderResult<TParams extends TSchema, TDetails, TState> = Parameters<
  NonNullable<ToolDefinition<TParams, TDetails, TState>["renderResult"]>
>[0];

type StandardShellState = {
  shell?: Box;
  call?: Component;
  result?: Component;
};

const extensionFile = fileURLToPath(import.meta.url);

// Resolves symlinks before comparing tool-ownership identity below: sourceInfo.path
// values come from independent path-resolution code paths, and macOS symlinks /tmp and
// /var to /private/..., so a lexical comparison spuriously reads a symlinked self-path
// as foreign. Falls back to the raw path for synthetic, non-file sourceInfo paths such as
// "<builtin:read>", which realpathSync rejects.
const realpathOrSelf = (path: string): string => {
  try {
    return realpathSync(path);
  } catch {
    return path;
  }
};
const extensionRealFile = realpathOrSelf(extensionFile);

// Each presentation adapter probes the exact Pi API it patches. If a future Pi removes
// that API, only the affected adapter degrades; the rest of Calm keeps working.
function installCalmPresentationAdapter(name: string, install: () => void): void {
  try {
    install();
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    console.error(`Calm: ${name} presentation adapter unavailable, skipping. ${reason}`);
  }
}

export default function (pi: ExtensionAPI) {
  installCalmPresentationAdapter("collapsed-thinking", installCalmAssistantLayout);

  let exportRendering = false;
  let removeTerminalInputHandler: (() => void) | undefined;
  // This instance owns the /calm command and drives the shared UI (thinking label,
  // preference restore/persist, export redraw). It stands down to secondary when another
  // extension already provides a "calm" command, so a project-local Calm and this global
  // Calm never fight. Decided at session_start, when getCommands() is reliable.
  let isPrimary = true;
  let commandRegistered = false;

  const calmPreferencePath = resolve(getAgentDir(), "calm-preference");
  // "max" is a legacy on-value from an older Calm; treat it as on rather than off.
  const loadCalmPreference = (): boolean => {
    let stored: string;
    try {
      stored = readFileSync(calmPreferencePath, "utf8").trim();
    } catch {
      return false;
    }
    return stored === "on" || stored === "max";
  };
  const persistCalmPreference = (active: boolean): void => {
    mkdirSync(dirname(calmPreferencePath), { recursive: true });
    const temporaryPath = `${calmPreferencePath}.${process.pid}.${randomUUID()}.tmp`;
    try {
      writeFileSync(temporaryPath, active ? "on\n" : "off\n", {
        encoding: "utf8",
        flag: "wx",
        mode: 0o600,
      });
      renameSync(temporaryPath, calmPreferencePath);
    } finally {
      rmSync(temporaryPath, { force: true });
    }
  };

  // Every on-screen tool row Calm presents, keyed by the row-local state Pi hands its
  // render slots, so Calm can repaint exactly those rows without touching the transcript.
  // Rows Pi's exporter renders are excluded: those use throwaway state and never appear on
  // screen. Cleared per session lifetime, which rebuilds the rows.
  const calmToolRowRepaints = new Map<object, () => void>();
  const rememberCalmToolRow = (state: object, invalidate: unknown): void => {
    if (exportRendering || typeof invalidate !== "function") return;
    calmToolRowRepaints.set(state, invalidate as () => void);
  };
  const repaintCalmToolRows = (): void => {
    for (const invalidate of calmToolRowRepaints.values()) invalidate();
  };

  function wrapBuiltIn<TParams extends TSchema, TDetails, TState>(
    factory: DefinitionFactory<TParams, TDetails, TState>,
  ): ToolDefinition<TParams, TDetails, TState> {
    const definitions = new Map<string, ToolDefinition<TParams, TDetails, TState>>();
    const definitionFor = (cwd: string): ToolDefinition<TParams, TDetails, TState> => {
      let definition = definitions.get(cwd);
      if (!definition) {
        definition = factory(cwd);
        definitions.set(cwd, definition);
      }
      return definition;
    };

    const original = definitionFor(process.cwd());
    const originalRenderCall = original.renderCall;
    const originalRenderResult = original.renderResult;
    const originalSelfShell = original.renderShell === "self";
    const standardShells = new WeakMap<object, StandardShellState>();

    if (!originalRenderCall || !originalRenderResult) {
      throw new Error(`Calm requires both render slots for Pi built-in tool ${original.name}`);
    }

    const shellStateFor = (
      context: RenderContext<TParams, TDetails, TState>,
    ): StandardShellState => {
      const rowState = context.state as object;
      let shellState = standardShells.get(rowState);
      if (!shellState) {
        shellState = {};
        standardShells.set(rowState, shellState);
      }
      return shellState;
    };

    const refreshStandardShell = (
      state: StandardShellState,
      theme: RenderTheme<TParams, TDetails, TState>,
      context: RenderContext<TParams, TDetails, TState>,
    ): Box => {
      const background = context.isPartial
        ? (text: string) => theme.bg("toolPendingBg", text)
        : context.isError
          ? (text: string) => theme.bg("toolErrorBg", text)
          : (text: string) => theme.bg("toolSuccessBg", text);
      const shell = state.shell ?? new Box(1, 1, background);
      state.shell = shell;
      shell.setBgFn(background);
      shell.clear();
      if (state.call) shell.addChild(state.call);
      if (state.result) shell.addChild(state.result);
      return shell;
    };

    return {
      ...original,
      renderShell: "self",

      async execute(toolCallId, params, signal, onUpdate, ctx) {
        return definitionFor(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx);
      },

      renderCall(
        args: RenderArgs<TParams, TDetails, TState>,
        theme: RenderTheme<TParams, TDetails, TState>,
        context: RenderContext<TParams, TDetails, TState>,
      ) {
        rememberCalmToolRow(context.state as object, context.invalidate);
        if (exportRendering) return originalRenderCall(args, theme, context);
        if (calmPresentationHides("assistant-tool-call")) return new Container();
        if (originalSelfShell) return originalRenderCall(args, theme, context);

        const state = shellStateFor(context);
        state.call = originalRenderCall(args, theme, {
          ...context,
          lastComponent: state.call,
        });
        return refreshStandardShell(state, theme, context);
      },

      renderResult(
        result: RenderResult<TParams, TDetails, TState>,
        options: ToolRenderResultOptions,
        theme: RenderTheme<TParams, TDetails, TState>,
        context: RenderContext<TParams, TDetails, TState>,
      ) {
        rememberCalmToolRow(context.state as object, context.invalidate);
        if (exportRendering) return originalRenderResult(result, options, theme, context);
        if (calmPresentationHides("tool-result")) return new Container();
        if (originalSelfShell) return originalRenderResult(result, options, theme, context);

        const state = shellStateFor(context);
        state.result = originalRenderResult(result, options, theme, {
          ...context,
          lastComponent: state.result,
        });
        refreshStandardShell(state, theme, context);
        return new Container();
      },
    };
  }

  // Each wrapBuiltIn() call has its own concrete TParams/TDetails/TState; the array has no
  // single sound instantiation, so it is typed the way Pi's own consumers erase it.
  const wrappedBuiltIns: ToolDefinition<any, any, any>[] = [
    wrapBuiltIn(createReadToolDefinition),
    wrapBuiltIn(createBashToolDefinition),
    wrapBuiltIn(createEditToolDefinition),
    wrapBuiltIn(createWriteToolDefinition),
    wrapBuiltIn(createGrepToolDefinition),
    wrapBuiltIn(createFindToolDefinition),
    wrapBuiltIn(createLsToolDefinition),
  ];

  let builtInsRegistered = false;

  // Gate on Calm already being on at load time. This stays synchronous and unconditional
  // (see file header): a foreign-claim check is not reachable here, while deferral would
  // make restored rows capture the wrong definition. A Calm-off session registers nothing.
  if (loadCalmPreference()) {
    for (const tool of wrappedBuiltIns) pi.registerTool(tool);
    builtInsRegistered = true;
  }

  function contestedBuiltIns(): ToolDefinition<any, any, any>[] {
    let registered: ToolInfo[];
    try {
      registered = pi.getAllTools();
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      console.error(`Calm: built-in ownership check unavailable, claiming every built-in unconditionally. ${reason}`);
      return [];
    }
    return wrappedBuiltIns.filter((tool) => {
      const owner = registered.find((info) => info.name === tool.name)?.sourceInfo;
      return owner !== undefined && owner.source !== "builtin" && realpathOrSelf(owner.path) !== extensionRealFile;
    });
  }

  // First time Calm turns on in a session that started off: claim every uncontested
  // built-in, leave each contested tool and its owning extension untouched, and name the
  // built-ins Calm could not take over.
  function activateBuiltInsIfNeeded(ui: ExtensionUIContext): void {
    if (builtInsRegistered) return;
    const contested = contestedBuiltIns();
    const contestedNames = new Set(contested.map((tool) => tool.name));
    for (const tool of wrappedBuiltIns) {
      if (!contestedNames.has(tool.name)) pi.registerTool(tool);
    }
    builtInsRegistered = true;
    if (contested.length === 0) return;
    const names = contested.map((tool) => `"${tool.name}"`).join(", ");
    const plural = contested.length > 1;
    ui.notify(
      `Calm: the ${names} built-in tool${plural ? "s are" : " is"} already provided by another extension, so Calm may not fully function for ${plural ? "them" : "it"} this session.`,
      "warning",
    );
    for (const tool of contested) {
      console.error(`Calm: skipped claiming built-in "${tool.name}" because another extension already owns it.`);
    }
  }

  // Backstop for the one case activateBuiltInsIfNeeded cannot reach: Calm registered
  // unconditionally at load because it was already on, so it can still silently lose a
  // name to an earlier-loaded extension. Runs on every session_start because a reload
  // rebuilds every extension's registrations from scratch.
  function reportBuiltInLosses(): void {
    if (!builtInsRegistered) return;
    let registered: ToolInfo[];
    try {
      registered = pi.getAllTools();
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      console.error(`Calm: built-in ownership check unavailable. ${reason}`);
      return;
    }
    for (const tool of wrappedBuiltIns) {
      const owner = registered.find((info) => info.name === tool.name)?.sourceInfo;
      if (owner && owner.source !== "builtin" && realpathOrSelf(owner.path) !== extensionRealFile) {
        console.error(
          `Calm: another extension (${owner.path}) also claimed the built-in "${tool.name}" tool and won; Calm's presentation for it is unavailable this session.`,
        );
      }
    }
  }

  // A "calm" command from a different extension - typically a project-local Calm. Pi
  // disambiguates two same-named commands into calm:1/calm:2, which would break the plain
  // /calm toggle, so this instance stands down to secondary and lets that command own it.
  function foreignCalmCommandExists(): boolean {
    let commands: ReturnType<ExtensionAPI["getCommands"]>;
    try {
      commands = pi.getCommands();
    } catch {
      return false;
    }
    return commands.some(
      (command) =>
        command.name === "calm" &&
        command.source === "extension" &&
        realpathOrSelf(command.sourceInfo?.path ?? "") !== extensionRealFile,
    );
  }

  const applyToggleUi = (ui: ExtensionUIContext, active: boolean): void => {
    // Pi re-runs every assistant row's layout from this call even when the label is
    // unchanged, which is what makes a toggle apply to rows already on screen.
    ui.setHiddenThinkingLabel(active ? "" : undefined);
    ui.setStatus("calm", undefined);
    const expanded = ui.getToolsExpanded();
    ui.setToolsExpanded(!expanded);
    ui.setToolsExpanded(expanded);
  };

  function registerCalmCommand(): void {
    if (commandRegistered) return;
    commandRegistered = true;
    pi.registerCommand("calm", {
      description: "Toggle Calm: hide tool shells, results, thinking, and working notes.",
      handler: async (_args, ctx) => {
        const active = !calmPresentationIsActive();
        persistCalmPreference(active);
        setCalmPresentation(active);
        if (active) activateBuiltInsIfNeeded(ctx.ui);
        applyToggleUi(ctx.ui, active);
      },
    });
  }

  pi.on("session_start", (_event, ctx) => {
    reportBuiltInLosses();
    calmToolRowRepaints.clear();
    exportRendering = false;
    setCalmStockExportRendering(false);

    isPrimary = !foreignCalmCommandExists();
    if (!isPrimary) {
      // Another Calm owns /calm and the shared UI. Keep only the already-registered
      // built-in wrappers and the idempotent thinking adapter; do not restore, persist,
      // toggle, or drive the thinking label from here.
      console.error(
        "Calm: another extension already provides /calm here; standing down to avoid a duplicate command. That project's Calm owns the toggle.",
      );
      return;
    }

    registerCalmCommand();
    setCalmPresentation(loadCalmPreference());
    if (ctx.hasUI) {
      ctx.ui.setHiddenThinkingLabel(calmPresentationIsActive() ? "" : undefined);
      ctx.ui.setStatus("calm", undefined);
    }

    removeTerminalInputHandler?.();
    if (ctx.mode !== "tui") return;
    removeTerminalInputHandler = ctx.ui.onTerminalInput((data) => {
      if (!getKeybindings().matches(data, "tui.input.submit")) return undefined;

      const input = ctx.ui.getEditorText().trim();
      if (input !== "/share" && input !== "/export" && !input.startsWith("/export ")) {
        return undefined;
      }

      exportRendering = true;
      setCalmStockExportRendering(true);
      setTimeout(() => {
        exportRendering = false;
        setCalmStockExportRendering(false);
        // Repaint the rows Calm presents, never the whole transcript. Pi prints
        // "Session exported to: <path>" immediately before this, and since Pi 0.83.0
        // setToolsExpanded() emits its own status line that coalesces over that
        // confirmation. Invalidating the rows individually repaints the same content with
        // no status line of its own; setStatus adds the redraw the live rows need.
        repaintCalmToolRows();
        ctx.ui.setStatus("calm", undefined);
      }, 0);
      return undefined;
    });
  });

  pi.on("session_shutdown", () => {
    removeTerminalInputHandler?.();
    removeTerminalInputHandler = undefined;
  });
}
