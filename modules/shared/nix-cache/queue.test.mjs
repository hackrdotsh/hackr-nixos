import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readlinkSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { enqueue, pending, upload } from "./queue.mjs";

const first = `/nix/store/${"a".repeat(32)}-first`;
const second = `/nix/store/${"b".repeat(32)}-second`;

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), "snowstead-cache-test-"));
  const queue = join(root, "queue");
  mkdirSync(queue);
  t.after(() => rmSync(root, { recursive: true, force: true }));
  return { root, queue };
}

test("enqueue deduplicates outputs and creates direct GC roots", (t) => {
  const { queue } = fixture(t);
  enqueue(queue, [first, second, first]);
  assert.deepEqual(
    new Set(pending(queue).map(({ path }) => path)),
    new Set([first, second]),
  );
  for (const { root, path } of pending(queue)) {
    assert.equal(readlinkSync(root), path);
  }
});

test("enqueue rejects non-store paths and symlinked queues", (t) => {
  const { root, queue } = fixture(t);
  assert.throws(() => enqueue(queue, ["/etc/passwd"]), /Invalid store path/);
  const alias = join(root, "alias");
  symlinkSync(queue, alias);
  assert.throws(() => enqueue(alias, [first]), /must be a directory/);
});

test("enqueue never overwrites an existing entry or follows its target", (t) => {
  const { root, queue } = fixture(t);
  const target = join(root, "untouched");
  writeFileSync(target, "keep");
  const entry = join(queue, first.split("/").at(-1));
  symlinkSync(target, entry);
  enqueue(queue, [first]);
  assert.equal(readlinkSync(entry), target);
  assert.deepEqual(pending(queue), []);
});

test("successful uploads include closures and release their GC roots", (t) => {
  const { queue } = fixture(t);
  enqueue(queue, [first, second]);
  const calls = [];
  const result = upload(queue, "/bin/snowstead", (...args) => {
    calls.push(args);
    return { status: 0 };
  });
  assert.equal(result, 0);
  assert.equal(calls.length, 2);
  assert.equal(calls[0][0], "/bin/snowstead");
  assert.deepEqual(calls[0][1].slice(0, -1), [
    "push",
    "main",
    "--server",
    "snowstead",
  ]);
  assert.equal(calls[0][2].timeout, 3600000);
  assert.deepEqual(pending(queue), []);
});

test("upload failure preserves pending roots and retries successfully", (t) => {
  const { queue } = fixture(t);
  enqueue(queue, [first, second]);
  let calls = 0;
  assert.equal(
    upload(queue, "snowstead", () => {
      calls += 1;
      return { status: 1 };
    }),
    1,
  );
  assert.equal(calls, 1);
  assert.equal(pending(queue).length, 2);
  assert.equal(
    upload(queue, "snowstead", () => ({ status: 0 })),
    0,
  );
  assert.deepEqual(pending(queue), []);
});

test("spawn errors and timeouts preserve pending outputs", (t) => {
  const { queue } = fixture(t);
  enqueue(queue, [first]);
  assert.equal(
    upload(queue, "snowstead", () => ({
      error: new Error("timeout"),
      status: null,
    })),
    1,
  );
  assert.equal(pending(queue).length, 1);
});

test("outputs enqueued during upload remain for the next invocation", (t) => {
  const { queue } = fixture(t);
  enqueue(queue, [first]);
  assert.equal(
    upload(queue, "snowstead", () => {
      enqueue(queue, [second]);
      return { status: 0 };
    }),
    0,
  );
  assert.deepEqual(
    pending(queue).map(({ path }) => path),
    [second],
  );
});

test("enqueue CLI failures never fail the Nix hook", (t) => {
  const { root } = fixture(t);
  const result = spawnSync(
    process.execPath,
    [
      fileURLToPath(new URL("./queue.mjs", import.meta.url)),
      "enqueue",
      join(root, "missing"),
    ],
    {
      env: { ...process.env, OUT_PATHS: first },
      encoding: "utf8",
    },
  );
  assert.equal(result.status, 0);
  assert.match(result.stderr, /Snowstead cache:/);
});

test("worker CLI invokes the uploader and retains failed roots", (t) => {
  const { root, queue } = fixture(t);
  const executable = join(root, "snowstead.mjs");
  const marker = join(root, "called");
  writeFileSync(
    executable,
    `#!${process.execPath}\nimport { writeFileSync } from "node:fs";\nwriteFileSync(${JSON.stringify(marker)}, "called");\nprocess.exit(1);\n`,
    { mode: 0o755 },
  );
  enqueue(queue, [first]);
  const result = spawnSync(process.execPath, [
    fileURLToPath(new URL("./queue.mjs", import.meta.url)),
    "upload",
    queue,
    executable,
  ]);
  assert.equal(result.status, 1);
  assert.ok(existsSync(marker));
  assert.equal(pending(queue).length, 1);
});
