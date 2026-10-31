import { spawnSync } from "node:child_process";
import {
  lstatSync,
  readdirSync,
  readlinkSync,
  symlinkSync,
  unlinkSync,
} from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";

const storePath = /^\/nix\/store\/[0-9a-df-np-sv-z]{32}-[^/\s]+$/;

export function enqueue(queue, paths) {
  // The queue's parent is root-owned. Never follow an existing queue entry.
  if (!lstatSync(queue).isDirectory()) {
    throw new Error("The upload queue must be a directory, not a symlink.");
  }
  for (const path of paths) {
    if (!storePath.test(path)) {
      throw new Error(`Invalid store path: ${path}`);
    }
    try {
      symlinkSync(path, join(queue, basename(path)));
    } catch (error) {
      if (error.code !== "EEXIST") throw error;
    }
  }
}

export function pending(queue) {
  return readdirSync(queue, { withFileTypes: true })
    .filter((entry) => entry.isSymbolicLink())
    .map((entry) => {
      const root = join(queue, entry.name);
      try {
        const path = readlinkSync(root);
        if (!storePath.test(path) || basename(path) !== entry.name) return null;
        return { root, path, created: lstatSync(root).mtimeMs };
      } catch (error) {
        if (error.code === "ENOENT") return null;
        throw error;
      }
    })
    .filter(Boolean)
    .sort((a, b) => a.created - b.created);
}

export function upload(queue, snowstead, run = spawnSync) {
  // systemd and launchd serialize service invocations, including manual starts.
  for (const { root, path } of pending(queue)) {
    console.log(`Uploading ${path}`);
    const result = run(
      snowstead,
      ["push", "main", "--server", "snowstead", "--closure", path],
      { stdio: "inherit", timeout: 60 * 60 * 1000 },
    );
    if (result.error || result.status !== 0) {
      console.error(
        "Upload failed; pending outputs will retry on the next run.",
      );
      return 1;
    }
    // Leave a concurrently replaced entry alone.
    try {
      if (readlinkSync(root) === path) unlinkSync(root);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
  return 0;
}

function main() {
  const [action, queue, snowstead] = process.argv.slice(2);
  try {
    if (action === "enqueue") {
      enqueue(
        queue,
        (process.env.OUT_PATHS ?? "").split(/\s+/).filter(Boolean),
      );
    } else if (action === "upload") {
      process.exitCode = upload(queue, snowstead);
    } else if (action === "status") {
      const outputs = pending(queue);
      console.log(`${outputs.length} pending build outputs`);
      for (const { path } of outputs) console.log(path);
    } else {
      throw new Error("Expected enqueue, upload, or status.");
    }
  } catch (error) {
    console.error(`Snowstead cache: ${error.message}`);
    // A broken queue must not turn a successful Nix build into a failure.
    process.exitCode = action === "enqueue" ? 0 : 1;
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
