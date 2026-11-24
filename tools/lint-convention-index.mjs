#!/usr/bin/env node
// lint-convention-index.mjs - validates a Child DOX Index against
// CONVENTION-INDEX.md rules:
//   1. Path ends with / and is relative to the owning AGENTS.md
//   2. File link resolves to an existing AGENTS.md in that path
//   3. Scope is a non-empty one-line description
//   4. Entries unique by path
//   5. Childless (empty or absent index) is VALID
// Usage: node lint-convention-index.mjs <dir-with-AGENTS.md>
//        node lint-convention-index.mjs --selftest
import { readdirSync, readFileSync, existsSync, statSync, mkdtempSync, rmSync, mkdirSync, writeFileSync, cpSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { tmpdir } from "node:os";

function lintDir(dir) {
  const file = join(dir, "AGENTS.md");
  const findings = [];
  let text;
  try {
    text = readFileSync(file, "utf8");
  } catch {
    return { dir, ok: false, findings: [`no AGENTS.md in ${dir}`] };
  }
  // index = markdown table with header | Path | Scope | File |
  const lines = text.split("\n");
  const headerIdx = lines.findIndex((l) => /^\s*\|\s*Path\s*\|\s*Scope\s*\|\s*File\s*\|\s*$/.test(l));
  if (headerIdx === -1) {
    // childless or absent index: valid (rule 5)
    return { dir, ok: true, findings: [], childless: true };
  }
  // collect table rows until the table ends
  const rows = [];
  for (let i = headerIdx + 1; i < lines.length; i++) {
    const l = lines[i];
    if (/^\s*\|[-\s|]+\|\s*$/.test(l)) continue; // separator
    if (!/^\s*\|.*\|.*\|.*\|\s*$/.test(l)) break;
    const cells = l.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map((c) => c.trim());
    // index paths are written wrapped in backticks (`X/`); strip them
    if (cells[0]) cells[0] = cells[0].replace(/^`+/, "").replace(/`+$/, "");
    rows.push({ line: i + 1, path: cells[0], scope: cells[1], file: cells[2] });
  }
  const seen = new Map();
  for (const r of rows) {
    const label = `${file}:${r.line}`;
    if (!r.path || !r.path.endsWith("/")) {
      findings.push(`${label}: path "${r.path}" must end with / (rule 1)`);
      continue;
    }
    if (r.path.includes("..") || r.path.startsWith("/")) {
      findings.push(`${label}: path "${r.path}" must be relative to the owning AGENTS.md (rule 1)`);
    }
    if (seen.has(r.path)) {
      findings.push(`${label}: duplicate path ${r.path} (rule 4, first at line ${seen.get(r.path)})`);
    } else {
      seen.set(r.path, r.line);
    }
    if (!r.scope || r.scope.length === 0) {
      findings.push(`${label}: empty scope (rule 3)`);
    }
    if (r.scope && r.scope.includes("\n")) {
      findings.push(`${label}: scope must be one line (rule 3)`);
    }
    const m = r.file && r.file.match(/\(([^)]+)\)/);
    if (!m) {
      findings.push(`${label}: File cell needs a markdown link to the child AGENTS.md (rule 2)`);
      continue;
    }
    const link = m[1];
    const target = resolve(dir, decodeURIComponent(link));
    if (!existsSync(target) || !statSync(target).isFile() || !target.endsWith("AGENTS.md")) {
      findings.push(`${label}: link ${link} does not resolve to an existing AGENTS.md (rule 2)`);
    }
  }
  return { dir, ok: findings.length === 0, findings, childless: false };
}

function walkTree(root) {
  // lint the root AGENTS.md and every AGENTS.md below it
  const results = [];
  const stack = [root];
  while (stack.length) {
    const d = stack.pop();
    let entries;
    try {
      entries = readdirSync(d, { withFileTypes: true });
    } catch {
      continue;
    }
    if (existsSync(join(d, "AGENTS.md"))) results.push(lintDir(d));
    for (const e of entries) {
      if (e.isDirectory() && e.name !== ".git" && e.name !== "node_modules") stack.push(join(d, e.name));
    }
  }
  return results;
}

function selftest() {
  const root = mkdtempSync(join(tmpdir(), "dox-lint-selftest."));
  const failures = [];
  const expect = (name, condition) => {
    if (!condition) failures.push(name);
  };

  // 1. childless: valid
  const childless = join(root, "childless");
  mkdirSync(childless);
  writeFileSync(join(childless, "AGENTS.md"), "# demo\n\nno index here\n");
  expect("childless should be valid", lintDir(childless).ok === true);

  // 2. valid tree
  const valid = join(root, "valid");
  mkdirSync(join(valid, "docs"), { recursive: true });
  writeFileSync(join(valid, "AGENTS.md"), "# root\n\n| Path | Scope | File |\n|------|-------|------|\n| `docs/` | documentation | [AGENTS.md](docs/AGENTS.md) |\n");
  writeFileSync(join(valid, "docs", "AGENTS.md"), "# docs\n");
  expect("valid tree should pass", lintDir(valid).ok === true);

  // 3. stale entry: path without trailing slash
  const stale = join(root, "stale");
  mkdirSync(stale);
  writeFileSync(join(stale, "AGENTS.md"), "# root\n\n| Path | Scope | File |\n|------|-------|------|\n| `docs` | documentation | [AGENTS.md](docs/AGENTS.md) |\n");
  const staleRes = lintDir(stale);
  expect("missing trailing slash must fail (rule 1)", staleRes.ok === false && staleRes.findings.some((f) => f.includes("rule 1")));

  // 4. missing file
  const missing = join(root, "missing");
  mkdirSync(missing);
  writeFileSync(join(missing, "AGENTS.md"), "# root\n\n| Path | Scope | File |\n|------|-------|------|\n| `docs/` | documentation | [AGENTS.md](docs/AGENTS.md) |\n");
  const missingRes = lintDir(missing);
  expect("unresolvable link must fail (rule 2)", missingRes.ok === false && missingRes.findings.some((f) => f.includes("rule 2")));

  // 5. duplicate path
  const dup = join(root, "dup");
  mkdirSync(join(dup, "docs"), { recursive: true });
  writeFileSync(join(dup, "AGENTS.md"), "# root\n\n| Path | Scope | File |\n|------|-------|------|\n| `docs/` | documentation | [AGENTS.md](docs/AGENTS.md) |\n| `docs/` | docs again | [AGENTS.md](docs/AGENTS.md) |\n");
  writeFileSync(join(dup, "docs", "AGENTS.md"), "# docs\n");
  const dupRes = lintDir(dup);
  expect("duplicate path must fail (rule 4)", dupRes.ok === false && dupRes.findings.some((f) => f.includes("rule 4")));

  rmSync(root, { recursive: true, force: true });
  if (failures.length) {
    console.error(`selftest FAILED: ${failures.join("; ")}`);
    process.exit(1);
  }
  console.log("lint selftest pass");
}

const arg = process.argv[2];
if (arg === "--selftest") {
  selftest();
} else if (arg) {
  const results = walkTree(resolve(arg));
  let bad = 0;
  for (const r of results) {
    if (r.ok) {
      console.log(`ok${r.childless ? " (childless)" : ""}: ${r.dir}`);
    } else {
      bad++;
      console.error(`failed: ${r.dir}`);
      for (const f of r.findings) console.error(`  - ${f}`);
    }
  }
  process.exit(bad ? 1 : 0);
} else {
  console.error("usage: lint-convention-index.mjs <dir> | --selftest");
  process.exit(2);
}
