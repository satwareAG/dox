#!/usr/bin/env node
// collect.mjs - summarize the eval run: raw counts per run, no derived claims.
// Reads runs/<slug>/{meta.json, transcript.json, result.txt, checks.txt}
// and writes summary.json next to them.
import { readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const runDir = resolve(dirname(fileURLToPath(import.meta.url)), "2026-11-24-run1");
const runsDir = join(runDir, "runs");
const summary = { run: "2026-11-24-run1", model: null, runs: [] };

function countTranscript(transcript) {
  // defensive: export schema may vary between opencode versions.
  // observed (opencode 2.4.1): { data: { messages: [ { type: user|assistant|idle,
  //   content: [ { type: reasoning|tool|text, state: { status } } ], tokens, cost } ] } }
  const out = { turnsUser: 0, turnsAssistant: 0, toolCalls: 0, toolErrors: 0, errors: 0 };
  let msgs = [];
  if (Array.isArray(transcript?.data?.messages)) msgs = transcript.data.messages;
  else if (Array.isArray(transcript)) msgs = transcript;
  else if (Array.isArray(transcript?.messages)) msgs = transcript.messages;
  for (const m of msgs) {
    const role = m?.type ?? m?.info?.role ?? m?.role;
    if (role === "user") out.turnsUser++;
    if (role === "assistant") out.turnsAssistant++;
    if (role === "assistant" && (m?.finish === "error" || m?.rawFinish === "error")) out.errors++;
    const parts = m?.content ?? m?.parts ?? m?.info?.parts ?? [];
    for (const p of parts) {
      const t = p?.type;
      if (t === "tool" || t === "tool-invocation" || t === "tool_use") {
        out.toolCalls++;
        if (p?.state?.status === "error" || p?.error) out.toolErrors++;
      }
    }
  }
  return out;
}

for (const slug of readdirSync(runsDir).sort()) {
  const d = join(runsDir, slug);
  if (!existsSync(join(d, "result.txt"))) continue;
  const entry = { slug, success: null, criteria: [], tokens: null, cost: null, model: null, sessionId: null, counts: null, timeSec: null };
  entry.success = readFileSync(join(d, "result.txt"), "utf8").trim().endsWith("true");
  if (existsSync(join(d, "checks.txt"))) {
    entry.criteria = readFileSync(join(d, "checks.txt"), "utf8").trim().split("\n").filter(Boolean);
  }
  if (existsSync(join(d, "meta.json"))) {
    try {
      const meta = JSON.parse(readFileSync(join(d, "meta.json"), "utf8"));
      const m = meta.data ?? meta;
      entry.tokens = m.tokens ?? null;
      entry.cost = m.cost ?? null;
      entry.model = m.model ?? null;
      entry.sessionId = m.id ?? null;
      summary.model ??= m.model ?? null;
      if (m.time?.created && m.time?.updated) entry.timeSec = Math.round((m.time.updated - m.time.created) / 1000);
    } catch (e) {
      entry.metaError = String(e);
    }
  }
  if (existsSync(join(d, "transcript.json"))) {
    try {
      const t = JSON.parse(readFileSync(join(d, "transcript.json"), "utf8"));
      entry.counts = countTranscript(t);
      // derive the model from the transcript when the session record lacks it
      if (!entry.model) {
        const msgs = t?.data?.messages ?? [];
        entry.model = msgs.find((m) => m.type === "assistant")?.model ?? null;
        if (entry.model) summary.model ??= entry.model;
      }
    } catch (e) {
      entry.transcriptError = String(e);
    }
  }
  summary.runs.push(entry);
}

writeFileSync(join(runDir, "summary.json"), JSON.stringify(summary, null, 2) + "\n");
console.log(JSON.stringify(summary.runs.map((r) => ({
  slug: r.slug,
  success: r.success,
  tokensIn: r.tokens?.input ?? null,
  tokensOut: r.tokens ? (r.tokens.output ?? 0) + (r.tokens.reasoning ?? 0) : null,
  model: r.model ? `${r.model.providerID ?? ""}/${r.model.id ?? ""}`.replace(/\/$/, "") : null,
  toolCalls: r.counts?.toolCalls ?? null,
  turns: r.counts ? r.counts.turnsUser + r.counts.turnsAssistant : null,
  timeSec: r.timeSec,
})), null, 1));
