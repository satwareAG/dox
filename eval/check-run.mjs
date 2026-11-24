#!/usr/bin/env node
// check-run.mjs - verifies an eval run directory has complete raw artifacts:
// summary.json with N runs, per-run transcript/meta/checks/result, README.
// Usage: node check-run.mjs <run-dir> [expected-run-count=6]
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";

const dir = resolve(process.argv[2] ?? ".");
const expected = parseInt(process.argv[3] ?? "6", 10);
const fail = [];
const need = (p, label) => {
  if (!existsSync(p)) fail.push(label);
};

const readme = join(dir, "README.md");
need(readme, "README.md");
if (existsSync(readme)) {
  const t = readFileSync(readme, "utf8");
  if (!/raw counts/i.test(t) && !/Raw counts/i.test(t)) fail.push("README lacks raw counts section");
  if (!/[Cc]aveat/i.test(t)) fail.push("README lacks caveats");
}

const summaryPath = join(dir, "summary.json");
need(summaryPath, "summary.json");
if (existsSync(summaryPath)) {
  const s = JSON.parse(readFileSync(summaryPath, "utf8"));
  if (!Array.isArray(s.runs) || s.runs.length !== expected) {
    fail.push(`summary.runs length ${s.runs?.length} != ${expected}`);
  } else {
    for (const r of s.runs) {
      if (typeof r.success !== "boolean") fail.push(`${r.slug}: success not boolean`);
      if (!r.tokens || typeof r.tokens.input !== "number") fail.push(`${r.slug}: missing input tokens`);
      const d = join(dir, "runs", r.slug);
      for (const f of ["transcript.json", "meta.json", "checks.txt", "result.txt"]) {
        need(join(d, f), `${r.slug}/${f}`);
      }
    }
  }
}

if (fail.length) {
  console.error("eval run artifacts incomplete:");
  for (const f of fail) console.error(`  - ${f}`);
  process.exit(1);
}
console.log("eval run artifacts complete");
