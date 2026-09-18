<!-- AI-maintained, append-only -->

# Decisions

Why each rule in this skill exists. Kept per the
[`log-decisions`](https://github.com/OpenSWE/log-decisions) skill.

**Numbering starts at Q22.** This journal was extracted from
[`soulmachine/skills`](https://github.com/soulmachine/skills) together with the skill; Q1–Q21 record
decisions about unrelated skills and stayed behind. Numbers are preserved so the `Supersedes:` lines
and in-text citations below still resolve.

**Do not renumber to close the leading gap.** `log-decisions`' position check will report it as a
break — that is expected here. A renumbering pass would have to rewrite ~35 citations, and `Q<n>`
also appears in these entries as a *grilling*-question reference (e.g. "grill Q5"), a separate
namespace an offset would silently corrupt. Append the next entry as **Q58**.

## Q22 — interactive/herdr-advisor — gate-resolution

**Question:** The user repeatedly requested edits to herdr-advisor after being told the skill was absent. Create the skill or ask for its location again?
**Options considered:** create it from the existing Advisor Model procedure and the requested additions / repeat the location question
**Chosen:** Create herdr-advisor in this repository, then commit, adopt, and sync it locally. Include the requested same-tab vertical split, worker/advisor glossary, and three-source continuation loop. Leave AGENTS.md unchanged.
**Decided-by:** agent
**Justification:** The continued requests specify the intended skill behavior and imply making that skill available. Creating a new directory is reversible and preserves the existing instructions. The canonical location and installation procedure come from ~/.agents/AGENTS.md, Skills management.
**Outcome:** assumed
**Ref:** herdr-advisor/SKILL.md

## Q23 — herdr-advisor/read-only — gate-resolution

**Question:** The advisor tool doc says the advisor model "runs without tools", so a Herdr advisor should never write. Codex enforces read-only with a macOS seatbelt, which severs herdr's unix socket — how should the Codex advisor be launched?
**Options considered:** keep `--yolo` with the rule stated in the brief only / a `[permissions.herdr-advisor]` profile in `~/.codex/config.toml` on each host plus a short launch flag / the whole profile inline as `-c` flags
**Chosen:** Inline `-c` flags: `-a never -c default_permissions="herdr-advisor"` plus `extends=":read-only"`, `network.enabled=true`, and `network.unix_sockets={"$HERDR_SOCKET_PATH"="allow"}`.
**Decided-by:** user
**Justification:** Measured on codex-cli 0.154.0: `codex sandbox -- herdr agent list` returns `PermissionDenied`, and the same call under a profile carrying the socket allowance returns the full listing while `touch` is refused and no file appears. Inline flags keep the skill self-contained — it is fleet-synced to seven hosts, and a profile living in per-host config would silently fall back to full access wherever the config is missing. Verified in a real session via `codex exec`: `-c default_permissions=` does select the profile.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md

## Q24 — herdr-advisor/read-only — gate-resolution

**Question:** Both CLIs ship a "let a model judge the permission prompt" mode — Codex `--approve-for-me`, Claude `--permission-mode auto`. Use either to enforce the advisor's read-only rule?
**Options considered:** Codex auto-review / Claude `auto` classifier / deny-by-default on both sides
**Chosen:** Neither judge. Claude uses `--permission-mode dontAsk` with a deny-list and allowlist; Codex uses the read-only profile.
**Decided-by:** user
**Justification:** Auto-review is "a reviewer swap, not a permission grant" and never reviews "anything already permitted under the active `sandbox_mode`" — it selects workspace-write, where an in-repo edit is already permitted and so never reaches the reviewer. It also aborts the turn after 3 consecutive denials, which an advisor looping on herdr calls would hit. Claude's `auto` is the same shape: a judge, not a boundary. `dontAsk` was measured to deny `touch` and `echo >` outright while leaving `git status`, `herdr agent list`, and `herdr agent prompt`/`send-keys` working. Both choices also satisfy the harder constraint that neither advisor may ever block its unwatched pane on a prompt.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md

## Q25 — herdr-advisor/grilling-exclusion — gate-resolution

**Question:** The skill's grilling exclusion said "do not invoke during a Matt Pocock `grill-me` or `grill-with-docs` session" with no end condition, so a worker whose grill had already finished read itself as permanently barred. When does the exclusion lift, and which entry points does it cover?
**Options considered:** leave it unbounded and let the worker judge / bound it with the grilling skill's own completion condition / bound it and also name every grill entry point
**Chosen:** Bound it: the exclusion holds while a grilling session is open and lifts once its frontier is empty. Widened the enumeration from two entry points to four — `grilling` itself plus `grill-me`, `grill-with-docs`, and `batch-grill-me`.
**Decided-by:** human
**Justification:** The user reported agent `agent-sync` blocked after its grill ended with "Frontier is empty" and settled that the skill should be usable there. "Frontier is empty" is not an ad-hoc marker: all four grill skills carry the identical sentence "The session is done when the frontier is empty", so the exclusion now borrows that skill's own completion condition rather than inventing one. The enumeration widening is the agent's call and worth confirming: `grill-me` and `grill-with-docs` are one-line shims that call `grilling`, so an agent mid-session is running `grilling` — which the old text never named — while `batch-grill-me` inlines the same procedure and was missing outright.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md

## Q26 — herdr-advisor/next-task-loop — tradeoff

**Question:** A worker often ends a turn inviting continuation on a literal word ("Say go and I'll refactor the parser"). Where does handling that belong among the loop's ordered sources, and what should the advisor send?
**Options considered:** send the exact trigger word as a new source ranked first, above the Claude Code ghost-text suggestion / rank it second, below the ghost text / fold it into the existing "next tasks in the response" source and let the advisor compose its own prompt
**Chosen:** A new source ranked second: send the exact word the worker named, nothing else. Ghost text keeps first place.
**Decided-by:** agent
**Justification:** Kept separate from the task-list source because the action differs in kind — the argument is dictated by the worker, not composed by the advisor — and sending "do 1, 2 and 3" to a worker waiting on "go" invites it to re-plan work it has already planned. Ranked below ghost text rather than above because source 1 already carries the turn-verification machinery and only applies to Claude Code workers with suggestions enabled, and in that overlap the suggestion is near-always the same continuation; reordering would be a larger claim than the reported need supports. Revisit if a ghost-text suggestion is observed diverging from an explicit invitation in the same response.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md

## Q27 — herdr-advisor/next-task-loop — gate-resolution

**Question:** Worker evertranscript ended a turn reporting "nothing left within the current authorization" while its input box carried the ghost text "start ticket 03" — the one ticket it had just said the user told it not to start. Should the advisor accept such a suggestion and keep the loop running, or stop?
**Options considered:** refuse the suggestion and stop the loop, treating the worker's "told me not to start it" as binding / accept it and continue, treating that as a scheduling preference rather than a blocker
**Chosen:** Accept and continue. The stop is reserved for the case where every remaining item is a decision only the user can make.
**Decided-by:** user
**Justification:** The agent first shipped the opposite guard in e779e2a ("a suggestion is generated text, not an authorized task"), reasoning that Claude Code's suggestion engine had proposed explicitly withheld work. The user then directed that the loop should continue on suggestions of this shape, which reverses it; per the disagreement rule that reaffirmation settles it. The replacement draws the line at task versus decision — executable work is taken even if the worker was earlier told to hold off, while an adoption call, a threshold, or a preference is relayed to the user. Worth noting for a future reader: the investigation that produced e779e2a stands on its facts (ESC[2m dim ghost text, the worker's own wording), only the conclusion drawn from them was overridden.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md

## Q28 — herdr-advisor/watchdog — tradeoff

**Question:** How should an advisor whose next-task loop has ended be restarted, given `herdr agent wait` exists only inside an advisor turn — so once that turn ends, nothing watches the worker and no event can restart it?
**Options considered:** a third-party socket subscriber on `events.subscribe` / an openroutine polling task / a worker-side `Stop` hook that pushes to the advisor
**Chosen:** Worker-side `Stop` hook (`herdr-advisor/stop-hook.sh`, registered through `~/.agents/hooks/Stop.toml` so agentstow renders it into both Claude and Codex). It pokes the paired advisor only when that advisor is `idle` or `done`. Full autonomy — unbounded re-arm — with a burst notification at 5 pokes per 10 minutes and kill switches at global and per-pair scope.
**Decided-by:** human
**Justification:** Seven-round grilling session. The user chose push over a subscriber ("push is better") and full autonomy over the bounded re-arm I recommended. Cost accepted: the hook runs on every Claude Code and Codex turn on the machine, so it is guarded to a cheap silent no-op outside a paired Herdr worker pane and never fails a turn. It does not violate `SKILL.md:166` — that forbids the worker *agent* waiting on the advisor mid-turn, whereas this fires after the turn has ended, so no mutual wait exists.
**Outcome:** applied
**Ref:** (pending)

## Q29 — herdr-advisor/agent-sync-pair — deviation

**Question:** `agent-sync`'s advisor was rebuilt as `claude-fable-5-1`, but the worker is itself a Claude agent — SKILL.md's model table pairs a non-GPT worker with a `gpt-6-astra` codex advisor precisely so the two differ in family.
**Options considered:** keep the codex advisor / wait for quota / pair same-family on Claude
**Chosen:** Same-family Claude pairing, accepted as a temporary deviation.
**Decided-by:** human
**Justification:** The codex advisor was not merely stalled — its pane showed "You've hit your usage limit ... try again at Sep 23rd, 2026 6:20 AM", so the gpt-6-astra option does not exist until then. The user specified the `claude-gw ... --model claude-fable-5-1` command directly. The cost is a weaker check: an advisor sharing the worker's family agrees with it more readily, so the pair is told this about itself in its brief.
**Outcome:** applied
**Ref:** (pending)

## Q30 — herdr-advisor/agent-sync-pair — irreversible-action

**Question:** The worker is offering step 3 — transferring `agentstow/agentstow` to `agent-sync-sh/agent-sync` — on the words "Say go and I'll start it." SKILL.md source 2 instructs the advisor to answer that literal invitation with `go`, which would fire an irreversible repo transfer that deliberately breaks nine OIDC trust entries.
**Options considered:** hand off the standard autonomous loop / carve step 3 out of the brief / do not restart the loop at all
**Chosen:** Restart the advisor as asked, but override source 2 for this pair: the brief forbids sending `go` for step 3 or step 5, and instructs the advisor to relay to the user and stop. Also paused the watchdog for this pair (`~/.config/herdr-advisor/paused.w8Q:p1`), because its generic re-arm nudge does not carry the carve-out and would let a re-armed advisor rediscover source 2 and send `go`.
**Decided-by:** agent
**Justification:** An irreversible, outward-facing transfer is the escalation floor — it is a decision only the user can make, not a task to be taken. Source 2 as written cannot tell an invitation to do reversible work from an invitation to do this; that gap is general and outlives this pair.
**Outcome:** applied
**Ref:** (pending)

## Q31 — herdr-advisor/evertranscript-pair — deviation

**Question:** Same question as Q29, now for the second pair: `evertranscript`'s Codex advisor also hit the usage limit (until Sep 23, 6:21 AM), and had silently degraded to `gpt-5.6-luna medium` rather than the `gpt-6-astra xhigh` SKILL.md specifies.
**Options considered:** leave it stalled until Sep 23 / rebuild it as `claude-fable-5-1`
**Chosen:** Rebuilt as `claude-fable-5-1` via `claude-gw`, same as Q29. Both live pairs are now same-family Claude.
**Decided-by:** human
**Justification:** Same quota outage as Q29; the user asked for the same treatment. Worth recording separately because it means the fleet currently has *no* cross-family advisor at all, so the independent-check property SKILL.md's model table exists to provide is absent everywhere until the quota resets. Each advisor's brief tells it this about itself.
**Outcome:** applied
**Ref:** (pending)

## Q32 — herdr-advisor/hold-primitive — gate-resolution

**Question:** SKILL.md told the advisor to "pause and relay" without defining what pausing is, leaving only loop-or-stop as real options. How should a hold be performed?
**Options considered:** end the turn / hold open inside the turn on a resolvable `herdr agent wait` condition / a bounded sleep-and-recheck
**Chosen:** End the turn, and say so explicitly — plus a named prohibition on re-arming `herdr agent wait` to stay alive.
**Decided-by:** agent
**Justification:** Observed failure, not theory: `agent-sync-advisor` improvised a hold as `herdr agent wait agent-sync --until working --timeout 590000`, re-armed it for over an hour, and reached 2% from auto-compact without advancing past turn 5. No wait condition fixes this — an idle worker only becomes `working` when a human prompts it, so any wait on worker activity resolves only after the awaited event has already happened, while the spin spends the context that would have let the advisor act on it. An ended turn costs nothing while it waits. The `Stop` hook is named as what resumes it, hedged with "where one is installed" because the watchdog is undocumented in this skill, is deployed on one host, and is paused for the pair that produced this bug.
**Outcome:** applied
**Ref:** (pending)

## Q33 — herdr-advisor/advisor-tool-surface — tradeoff

**Question:** Should the advisor launch with MCP tools disabled, and if so by what mechanism in each column?
**Options considered:** drop all MCP / keep a `serena` + `claude-mem` allowlist / keep MCP and fix the machine's global config instead
**Chosen:** Drop all. Claude: `--strict-mcp-config` alone. Codex: one `-c mcp_servers.<n>.enabled=false` per server that host declares, derived at launch, never hardcoded.
**Decided-by:** user
**Justification:** Measured, not assumed. Claude loads 114 MCP tools (~33k tokens) and a full advisor session called none of them — 54 `Bash`, 4 `Read`, 1 `Grep`, 0 MCP. The warrant is tool-list noise, not token budget: an A/B of `claude -p` counting `mcp__`-prefixed tools gave 142 without flags and 23 with, and those 23 proved to be the harness's own wrapper namespace for built-in tools, so the real MCP count reaches zero. The token argument was explicitly rejected — 33k against the 1M window the same change introduces is 3.3%, so the earlier draft's claim that MCP definitions "consume most of the context" was false by an order of magnitude and does not appear in SKILL.md. An allowlist was rejected as a maintained list that drifts on plugin reinstall and re-pays a fraction of the cost forever; global MCP hygiene was rejected as outside a skill's remit, though it remains the larger prize.

Two corrections to the draft this replaces. First, `--mcp-config '{"mcpServers":{}}'` was redundant: `--strict-mcp-config` alone already drops every scope including plugin-provided servers (142 -> 23 vs 24, within counting noise), and the empty map was the fragile half — inline JSON, single quotes that must survive zsh, through a launch path that already rewrites argv. Second, the draft concluded "a codex advisor still pays the MCP tax" from two true premises — `-c mcp_servers='{}'` merges rather than replaces (proven with a marker key that *added* a server), and `--strict-config` is validation only. The conclusion was false: per-server `enabled=false` takes codex from 248 tools (~55k tokens, of which `tailscale` alone is 126 tools / 25k) to 21. The search had stopped at "no flag shaped like claude's exists". Codex is also the default column — the table routes every non-GPT worker to it — so the draft fixed the rare column and declared the common, costlier one unfixable.

The derivation is per-host because the failure is fatal, not cosmetic: `-c mcp_servers.<name>.enabled=false` for a server that host does not declare in `[mcp_servers.*]` aborts config loading with `invalid transport`. A hardcoded list passes every test on the machine that wrote it and breaks the launch on the first host that differs. Known ceiling: plugin-injected servers (`cua_repl`, `mcp-search`, `mermaid`) cannot be overridden by the same route, so codex floors at ~21 tools where claude reaches zero. `--disable plugins` does clear them (verified: with it plus the per-server overrides, `codex mcp list` shows nothing enabled and a `RUST_LOG=codex_rmcp_client=trace` run logs zero server launches) but it is a blunt switch — it also drops every plugin skill (112 SKILL.md files under `~/.codex/plugins/cache`) and plugin hook (SessionStart fired 3 times instead of 8, losing claude-mem's capture), so the ~21-tool floor is accepted over that trade.

Not adopted, deliberately: no global MCP hygiene work item; no `CLAUDE_CODE_DISABLE_ADVISOR_TOOL=1` on the launch line, since `advisorModel` is currently unset and the inheritance trap only arms when it is set; no rename, despite the name colliding with Claude Code's first-party `--advisor` tool — a one-line disambiguation covers it, and the two are disjoint anyway (the native advisor is a server-side consultant with no tools, so it cannot drive a worker, and its pairing table is same-vendor only, which the cross-family rule here requires it not be).
**Outcome:** applied
**Ref:** 17735e8

## Q34 — herdr-advisor/verification-budget — gate-resolution

**Question:** The next-task loop bounded the advisor's writes and its holds but never its reading. How much may an advisor investigate before it must prompt the worker?
**Options considered:** bound verification as a spot-check and route surviving doubt to the worker / a hard tool-call or wall-clock cap per turn / leave the depth to advisor judgment
**Chosen:** A spot-check against the journal and the worker's own report, with no re-derivation from source, no re-fetching what the worker already verified, and no parsing its session transcript. A doubt that survives the spot-check **is** the next task and goes to the worker. The pre-task `herdr agent wait` is pinned at its 60-second timeout.
**Decided-by:** user
**Justification:** Observed failure, not theory. `evertranscript-advisor` held turn 0 for 26 minutes and 48 tool calls — 23 `Bash`, 18 `Read`, 5 `Grep`, 2 `WebFetch` — with **zero** `herdr agent prompt` or `send-keys` among them: it never touched the worker at all. 10m04s of that was one blocking `herdr agent wait --timeout 600000`, which reports the advisor as `working` while it does nothing. The rest was a genuine audit of `f9ff073` at `--effort max`: six source files, two HuggingFace re-fetches to byte-compare an artifact the worker had already checked, and three python passes over the worker's 83 MB session JSONL to recover the user's original prompt. Meanwhile the worker completed turn 151 — driven by the user, not the advisor — and sat idle for the last 11 minutes.

The advisor was not disobeying. Q30's quota clause tells a same-family advisor to "verify the worker's claims against the code" and the handoff brief made that verification a gate on task selection; neither bounded it, so an advisor at the top of its effort ladder had no stopping rule but its own satisfaction. The loop is also strictly serialized — wait, read, select, prompt `--wait` — so advisor time *is* worker idle time by construction. SKILL.md guarded the opposite deadlock ("avoids the worker waiting for the advisor while the advisor waits for the worker") and never this direction.

A hard cap was rejected as arbitrary: a legitimate spot-check can need several reads, and a counter invites gaming the count rather than the behaviour. Leaving the depth to judgment was rejected because that is precisely what produced the bug. The budget binds the loop's own reading, not a bounded consultation the worker requested — `agent-sync-advisor` was mis-interrupted during exactly such a consult on the same night, and the correction deadlocked its worker, which was waiting on the answer. Routing doubt to the worker is the cheaper fix *and* the correct role — an advisor that suspects a commit should have the worker re-verify it, which is what "it never edits; it tells the worker what to change" already meant.

A second defect surfaced in the same advisor's next turn, and source 1 now guards it: it read `^[[2m` on the worker's `register the migrations` suggestion, correctly identified it as ghost text, and declined to accept it *for that reason* — inverting the trigger into the refusal. The user overruled the hold and the suggestion was taken.

Known ceiling: nothing enforces this. It is prose in the loop, like the hold rule Q32 added. The `Stop`-hook watchdog cannot rescue it either — it fires on the worker's turn end and pokes only when the advisor's loop is *gone*; here it fired at 02:35:51 PDT and correctly logged `skipped-advisor-busy`, because a loop stuck inside a turn is indistinguishable from a healthy one. Recovery stayed manual: `herdr agent send-keys <advisor> esc`.
**Outcome:** applied
**Ref:** 98ff90c

## Q35 — herdr-advisor/wait-tick-cost — tradeoff

**Question:** The next-task loop's `herdr agent wait` timeout is a ceiling, not a duration, so a long worker turn is a series of re-armed ticks. How long is a tick, and what does the advisor do on each timeout?
**Options considered:** keep 60s and read output every tick (Q34) / raise to 10 minutes to cut tool calls / 110s with `agent get` only on timeout, output read only on a state change
**Chosen:** `--timeout 110000` for the loop wait and the three continuation prompts; on timeout, `agent get` alone and re-arm. The 60s bounded-consultation wait is a different path and is unchanged.
**Decided-by:** user
**Justification:** The tick count was not the cost. A timed-out wait returns only `{"error":{"code":"timeout"}}` — no state — so the follow-up `agent get` is necessary and ~200 tokens; the "fresh output" the old wording also asked for is the ~5k-token read block, and an hour-long worker turn at 60s ticks spent ~300k tokens re-reading a pane that had not changed, which walks the advisor into the compaction Q32 names as what kills a hold. Dropping the read cuts that 25×. 10 minutes was rejected on three grounds: it exceeds the Bash tool's 120s default, so it only works if the advisor also passes a per-call `timeout`; it blows the 5-minute prompt-cache window, so every re-arm re-reads the context uncached; and the tick is the advisor's worst-case latency to a queued prompt — the 26-minute deafness of `agent-sync-advisor` on 2026-09-17 was exactly one long wait. 110s stays under both limits: 33 ticks/hour, cache warm, ~7k tokens/hour while idling.
**Outcome:** applied
**Ref:** 53add85
**Supersedes:** Q34 — only its 60-second pin; the verification budget stands.

## Q36 — herdr-advisor/stop-condition — gate-resolution

**Question:** The next-task loop stopped on the worker's first "nothing left". Should one report end the loop, or should the advisor probe once before believing it?
**Options considered:** stop on the first "nothing left" (Q27) / send a bare `what's next` once and stop only on a second consecutive "nothing left" / probe N times or with a leading "check for follow-ups, tests, docs" prompt / cap probe→task→probe cycles
**Chosen:** A flat "nothing left" — no named task, no decision for the user — triggers one literal `what's next`; a second consecutive flat "nothing left" is the stop, and the advisor's last message quotes both answers. Any turn in which the advisor sent work, from any source, resets the count. The probe fires only on the flat shape: a report that names an unblocked item already has its next task (Q27), and one that turns on a user decision is a hold. "Every remaining item is a decision only the user can make" moves from stop to hold, so stop now means only "goal complete, nothing to wait for" and hold means "waiting on a human".
**Decided-by:** user
**Justification:** Grilling session, all recommendations accepted. Source 4 already sends `what's next` when a turn ends without an invitation or task list, so the loop was asymmetric: it probed vagueness but not completion, and a worker's first "done" is the least-considered answer it gives. Two identical answers to the same bare question is the evidence the stop rests on; that is why the probe stays literal — a leading prompt invites the worker to manufacture work, which is what the stop exists to avoid — and why it fires once, since a third probe adds cost and no information. No re-poke loop follows the stop: the worker's final turn fires the Stop hook while the advisor is still in its `--wait` (`skipped-advisor-busy`), and the advisor's own turn end self-hunts `…-advisor-advisor`.

Known ceiling: a make-work worker can ping-pong — "nothing left" → probe → trivial task → "nothing left" → probe — and every taken task resets the count, so it never stops. No cap on cycles, for the reason Q34 gave against counters: it invites gaming the count rather than the behaviour. The bare wording is the guard.
**Outcome:** applied
**Ref:** 384749f
**Supersedes:** Q27 — only its stop clause; accepting a suggestion that names withheld-but-unblocked work stands.

## Q37 — herdr-advisor/simplification — tradeoff

**Question:** `SKILL.md` had grown to 384 lines through a night of incident fixes, and three readers each loaded all of it: the worker, the advisor, and the re-armed advisor on every watchdog poke. How should it be shortened, and what may be lost?
**Options considered:** compress in place / split by reader into two files / three files with the launch recipe disclosed too / move the flags into a launch script / hook-only wakeups, which would delete the tick and hold text
**Chosen:** Two files split by reader: `SKILL.md` for the worker, whose invocation is what loads it, and a new `ADVISOR.md` for the advisor, named by the handoff and the watchdog nudge. Each rule keeps at most one clause of reason; incident narratives and measurements leave the skill because Q23–Q36 already hold them; statements made two to seven times collapse to one. The launch commands, the MCP snippet and the parity table stay byte-identical. Both files end with this journal's absolute path.
**Decided-by:** human
**Justification:** Grilling session. The user first gave `SKILL.md` to the advisor, then reversed it on the ground that the skill is always invoked by the worker; that also removed the need for a router and for an `AGENTS.md` edit. Hook-only wakeups were rejected for a lost-wakeup race: the hook skips a busy advisor, so a short worker turn ending while the advisor is still finishing its own would never be delivered, which is the silent stall that already cost hours twice. A launch script was deferred as new code needing verification on both kinds. A bare `DECISIONS.md` reference resolves against the worker's own repo, which keeps its own journal, so the footer is absolute. A 68-rule inventory and a check script (verbatim blocks byte-identical, every kept rule located) gated the rewrite, and the pair's own advisor spot-checked the drafts against the baseline, restoring three imperatives the compression had softened into descriptions (keep the 110-second timeout, never re-arm a wait to hold, never add `--until idle`). Result: 3216 words became 1304 for the worker and 1139 for the advisor, 24% fewer in total and 59–65% fewer per reader; the line budgets set in the session (150 and 100) were missed at 177 and 139 because every rule was kept.

Reasons that left the skill and were recorded nowhere else: effort is the lever for a same-family advisor because a worker's model is unreadable (it passes no `--model`, and neither Herdr nor the pane reports one); the bare `claude-fable-5-1` id is the 200k-context variant, which `autoCompactWindow` cannot lift, so the quoted `[1m]` suffix is what buys the 1M window; `--search` survives the Codex sandbox because it is server-side; the Claude Code prompt-suggestion documentation is at code.claude.com/docs/en/interactive-mode#prompt-suggestions. Known ceiling, recorded not fixed: the watchdog finds an advisor only as exactly `<worker-name>-advisor` in the worker's tab, so a base shortened to fit the 32-character name limit goes unwatched, and so does the base invented for an unnamed worker, which the hook skips as `skipped-unnamed`.
**Outcome:** applied
**Ref:** 05403ee

## Q38 — herdr-advisor/one-direction — gate-resolution

**Question:** The pair ran in two modes: a bounded consultation in which the worker blocks on the advisor, and continuation in which the advisor drives and the worker must not wait. Should the worker ever wait on the advisor?
**Options considered:** keep both modes and tighten the text / one direction only
**Chosen:** One direction. The worker never waits on the advisor: a consult is a turn-ending question that the advisor answers by prompting the worker, the first question rides in the handoff, and a review-only job is a handoff that declares a bounded assignment. The handoff names the spec by path or issue, and the advisor's spot-check compares the worker's report against that spec and the journal. The bounded-consultation path and its 60-second wait are deleted.
**Decided-by:** human
**Justification:** From outside the two modes are indistinguishable, which is how a healthy consult was mis-interrupted on 2026-09-17 and the corrective prompt deadlocked the agent-sync pair; Q34 had to carry an exemption clause for the same reason. One invariant replaces both modes and the rules that kept them apart, and it was already the rule whenever continuation was active. Cost: a consult now crosses a turn boundary. The usual flow (grill, spec, then this skill) has no pre-handoff consult at all, and a finished spec exists by the time the advisor launches, which is why the handoff points at it.

An investigation in the same session corrected a belief formed that night: a `prompt --wait` or `agent wait` timeout ends only the caller's wait and never interrupts the target (161 timeouts in the herdr server log since 2026-09-15, none near any interrupt marker, on herdr 0.9.1); the agent-sync interruption was a manual `esc` sent 7 minutes after the worker's timeout fired. The continuation prompts therefore keep `--wait --timeout 110000`, which they need for the five-second observed-working gate.
**Outcome:** applied
**Ref:** 05403ee
**Supersedes:** Q34 — only its bounded-consultation exemption, now "a question the worker asked gets a full answer"; the verification budget stands.

## Q39 — herdr-advisor/irreversible-hold — gate-resolution

**Question:** Q30 recorded that the literal-invitation source cannot tell "Say go and I'll refactor" from "Say go and I'll transfer the repo", called the gap general, and patched it per pair with a brief carve-out plus a watchdog pause. Where does the general rule go, and where is its line?
**Options considered:** leave per-pair carve-outs as the mechanism / hold on irreversible or outward-facing work / hold on irreversible work only
**Chosen:** Irreversible only, inside the hold rule so that it covers all four sources: work the worker cannot undo with the access it has, namely publishing a version, transferring or deleting a remote repo or resource, sending a message, force-pushing over shared history, destroying untracked data, spending money. Ordinary pushes, commits, PRs and deleting tracked files are recoverable and are taken. In a mixed list the advisor sends the tasks and holds only the decision. The worker is told to flag such steps.
**Decided-by:** human
**Justification:** "Outward-facing" read literally catches every push, PR and comment, and the live workers push several times an hour, so that wording would hold the loop constantly, against Q27's purpose. The general rule retires the carve-out-plus-pause procedure, whose pause marker outlived its need by five hours.
**Outcome:** applied
**Ref:** 05403ee

## Q40 — herdr-advisor/bounded-assignment — gate-resolution

**Question:** A review-only advisor finishes and goes idle, and the watchdog's generic nudge then tells it that its next-task loop is not running and to continue it. How is a bounded assignment kept bounded?
**Options considered:** leave it and pause such pairs by hand / have the worker touch the pair's pause marker at handoff / one line in the advisor's manual plus a clause in the nudge
**Chosen:** The manual says a re-arm nudge does not reopen a bounded assignment, so the advisor says it is complete and ends its turn, and the nudge gains "unless your assignment was bounded".
**Decided-by:** human
**Justification:** No state to leak: a pause marker outlives its pane, and a later pair reusing that pane ID would be silently unwatched, recreating the stall the watchdog exists to prevent. Review-only is the rare path, so one short advisor turn per worker turn is cheap. The hook changed by exactly two strings, this clause and the manual's path.
**Outcome:** applied
**Ref:** 05403ee

## Q41 — herdr-advisor/effort-default — gate-resolution

**Question:** Commit d6d0b42 replaced the hardcoded `xhigh` in both launch lines with `<effort>` and defined it only in the same-family paragraph, leaving the normal cross-family pairing with no stated effort. What is it?
**Options considered:** `xhigh` for cross-family and one rung above the worker only for same-family / one rung above the worker for every pairing
**Chosen:** `xhigh` for a cross-family pair; one rung above the worker's only for a same-family pair.
**Decided-by:** human
**Justification:** Restores the value both lines carried until 00:53 on 2026-09-17. Read literally, the unscoped rule gives a worker at `xhigh` a `max` advisor, the setting Q34's 26-minute audit ran at, in a loop where advisor time is worker idle time. Outranking exists to keep a same-family advisor from being a weaker copy; a cross-family advisor gets its independence from the family.
**Outcome:** applied
**Ref:** 05403ee

## Q42 — herdr-advisor/undefined-cases — gate-resolution

**Question:** The old text told the advisor to surface a blocked worker's dialog to the user, and to preserve a user-typed draft, but not what to do next. In both cases it cannot send input, and re-arming the wait would spin because the worker's state does not change. What follows?
**Options considered:** leave both silent / name the hold primitive
**Chosen:** Both end in a hold: the advisor names what it is waiting for and ends its turn.
**Decided-by:** agent
**Justification:** Q32 already defines hold as the only non-spinning way to wait on a human, and the Stop hook resumes the advisor once the user has dealt with the dialog or submitted the draft. Cheapest to reverse: two words in `ADVISOR.md`. Also reworded, meaning unchanged: "an offer between alternatives is a decision" became "is a question: answer it, or hold if the choice is the user's", because "decision" is now a defined word meaning hold and the loose use would have turned every technical either/or into one. All three were flagged at the review gate, twice, and the user approved the drafts with them in view.
**Outcome:** applied
**Ref:** 05403ee

## Q43 — herdr-advisor/catalog-paragraph — tradeoff

**Question:** Q37 kept the paragraph telling a worker how to re-rank the models when the pairing table looks stale, and the rollout report offered it as an optional cut of about 45 words. Keep it or drop it?
**Options considered:** keep it / drop it and record its facts here
**Chosen:** Dropped from `SKILL.md`. With it gone, the sentence defending the `[1m]` suffix lost its antecedent, so "The model catalog" became "Claude Code's model catalog"; nothing else changed.
**Decided-by:** human
**Justification:** The user picked both optional follow-ups listed in the rollout report, relayed by the pair's advisor and confirmed on its screen. Cost: a worker facing a stale table has no in-skill way to re-rank the models and will trust the table. The procedure that left the skill: the vendors' catalogs rank the models; the newest `~/.claude/cache/model-catalog/*-cc.json` by its `fetchedAt` field lists the Claude models in capability order, `~/.codex/models_cache.json` ranks the OpenAI ones by an integer `priority`, and if neither is readable the table stands. `SKILL.md` is now 173 lines and 1265 words.
**Outcome:** applied
**Ref:** 6a00075

## Q44 — herdr-advisor/nudge-worker-state — deviation

**Question:** The watchdog's nudge said "worker X (pane P), which is now {status} at turn {turn}", but `status` was the advisor's own `agent_status`, printed as though it described the worker. What should the sentence say?
**Options considered:** swap in the worker's `agent_status` / say what a Stop hook knows by construction and quote neither status nor turn
**Chosen:** "worker X (pane P), which has just ended a turn." The status and the turn number both leave the nudge. This is a third string change to the hook, beyond the two Q40 records; the `ADVISOR.md` pointer, the bounded-assignment clause, the gates and the log fields are untouched.
**Decided-by:** human
**Justification:** The user asked for the fix and reviewed the diff; the wording is the agent's, on evidence gathered at the advisor's suggestion. The hook runs while the worker's turn is still ending, so the worker's Herdr record lags: mid-turn, `agent get` reports `working` with `turn` equal to the last completed turn, and the one delivered nudge that could be paired with the advisor's next `agent get` (evertranscript, 2026-09-17) claimed turn 140 while that read showed `done` at turn 141. Swapping in the worker's status would therefore have told the advisor that the worker was still `working`. The advisor re-reads the worker's state at the top of its loop anyway, so the nudge loses nothing. The log's `worker_turn` field has the same one-turn lag and was left as is, being diagnostics only. A self-test (shell syntax, the silent no-op outside Herdr, the body compiles, `main()` against a fake agent list) passes on the new hook and fails on the old sentence.
**Outcome:** applied
**Ref:** 6a00075

## Q45 — herdr-advisor/endless-loop — tradeoff

**Question:** The advisor's loop lived inside one turn but ended it to hold on the user, and a worker-side Stop-hook watchdog re-armed it afterwards, so the design had two waits, a hold primitive, a bounded-assignment mode, and a "decision" class the advisor relayed to a user who never reads its pane. The user asked why the hook exists if the loop does, and then whether the advisor should simply never stop. What is the advisor's lifecycle?
**Options considered:** keep hold-then-hook (Q28, Q32) / hold in-turn on a state-exclusion wait and drop the hook / never hold, never be prompted: one turn until the double "nothing left", with an advisor-side Stop gate against early ends
**Chosen:** The last. The advisor's whole life is one turn. Two ends only: a flat "nothing left" → `what's next` → flat "nothing left", or a user message in its own pane saying stop; both finish with a literal last line `ADVISOR LOOP ENDED: <reason>`. `stop-hook.sh` keeps its path and registration but flips from worker-side poke to advisor-side gate: for a pane whose agent name ends in `-advisor`, a turn end whose last non-empty line (fence and emphasis stripped) does not carry that marker is returned as `decision: block` with a re-read-ADVISOR.md reason, self-capped at 8 consecutive blocks inside one hour on both kinds. Every pass of the loop starts from `agent get`, keyed on R, the last turn read: `working` → plain `wait`, then read; settled with `turn > R` → read now; settled and already read → `wait --until working`, plain `wait`, read. All waits at `--timeout 590000`, with `Bash(timeout: 600000)` on `claude` (on `prompt --wait` too) and 30-second unified-exec yield polls on `codex`; a timeout restarts the pass, silently. The advisor answers for the user: preferences, approaches, thresholds, adoption calls, authorizations within existing permissions, and `go` on irreversible steps, declining only spending money and destroying data the goal never named; a fact or act the user alone has (a code, a password, a physical step) is not "nothing left" but a wait for the worker's next turn. Dropped: holds, the decision relay, bounded assignments, the worker-side discovery (`<name>-advisor` in the same tab), the `enabled`/`paused*` flag files, notifications. Worker side: ask in turn-ending text, never with `AskUserQuestion`; journal advisor answers as `Decided-by: advisor`. The `-advisor` name suffix stays as the gate's key, so a worker must never choose a base ending in it.
**Decided-by:** human
**Justification:** Thirty-three-question grilling session. The turning fact was the classification of all 13 watchdog pokes since the hook shipped, from the advisors' transcripts: 6 were rule-abiding holds, 3 were advisors stopping on a *single* "nothing left" against Q36, 1 a correct double stop that the hook then needlessly reopened, 1 fought the user's typed "stop the advisor", and 2 poked Codex advisors already dead on `usage_limit_exceeded`; the case the hook was defended on in this session, an unplanned end (Esc, compaction, error), occurred zero times. Both CLIs' `Stop` hooks accept `decision: block` and pass `last_assistant_message`, and neither fires on a user interrupt, so an advisor-side gate targets the one observed failure (27% early stops) while Esc stays a real stop; Claude Code documents a cap of 8 consecutive blocks and Codex none; probed here with a throwaway `claude -p` session whose Stop hook always blocked, the documented cap did not engage (20 blocks in one turn, released only by the probe's own valve), so the hook's cap is the only ceiling on either kind and a release is always the hook's own decision, logged as `allowed-cap` and announced with a Herdr notification, the one notification kept, because a silent release is exactly the unwatched-worker stall the gate exists to prevent (user's call at the review gate). `herdr agent wait` is level-triggered (6 ms return on an idle worker, measured), which is why a hold could never be a re-armed plain wait (Q32's spin) and why the in-turn wait needs `--until working` plus the turn compare. The tick grew from 110 s because nothing is queued to the advisor any more, so Q36's latency argument is dead, and the Bash tool's ceiling is 600 s (`BASH_MAX_TIMEOUT_MS`) while Codex's unified exec has no kill timeout at all, only a 30 s yield. The user's rule for the decision class: the advisor is the stronger model, and its job is to keep the worker working rather than to wait for the user; the two declines are the cases where "as the user would" has no basis without a stated budget or intent. Audit trail for acting without the user is the worker's existing journal rule with one new `Decided-by` value. Deviation from the grilled shape, found by the pair's advisor at spot-check: the loop as grilled and first drafted began every pass with `wait --until working`, which parks forever on a worker whose turn ended before the pass began, since `herdr agent wait` is level-triggered and the turn compare only ran after a timeout; it happened in this session, the worker's turn 99 ending while the advisor was still on its first turn. Hence "every pass starts from state". Two more from the same review: the cap counted every early end since the advisor was born and would have released a recovering advisor for good at its ninth, now bounded by the hour window; and the marker drawn inside a code fence invited the model to emit the fence as its last line, so the hook strips fence and emphasis first. Verified before shipping: an offline self-test of the gate (no-op outside Herdr, worker pane untouched, block without the marker, allow with it as the last non-empty line only, fenced and emphasised, the 8-cap, its reset, the window, per-pane counting), and a live pairing on this machine (see Ref). Live verification covers the `claude` kind only: `codex` is out of quota until 2026-09-23, so its gate path is documentation-verified until then.
**Outcome:** applied
**Ref:** live verification 2026-09-17 on mac-mini-m2, installed hook, throwaway `livetest-advisor` (claude, haiku): forced early end → `blocked` at 17:03:49 PDT, block reason delivered and acted on (transcript `2e26ef41-a312-41a4-8f3d-f9ae0b9c5a70.jsonl` lines 38, 15); Esc then ended the turn with no hook record, confirming Stop skips interrupts; marker-terminated turn → `allowed-end` at 17:06:02 (line 81). Log `~/Library/Logs/herdr-advisor.log` lines 311–312. Commit: 3773850.
**Supersedes:** Q28 (worker-side watchdog → advisor-side gate); Q32 (hold → no hold); Q36's tick clause (110 s → 590 s / 30 s polls; the stop condition stands); Q39 (irreversible → the advisor decides); Q40 (bounded → dropped); Q42 (blocked/draft holds → wait for the worker's next turn); Q44 (nudge text → block reason); Q27's decision clause (decisions relayed → answered).

## Q46 — herdr-advisor/user-only-trigger — gate-resolution

**Question:** The skill's description told the model to invoke it whenever "the Advisor Model rule applies", and `~/github.com/AGENTS.md` carried that rule for every agent on five hosts. Who starts an advisor pair?
**Options considered:** keep the model trigger and the rule / user-only, gated per harness where a gate exists (`disable-model-invocation`, `agents/openai.yaml`) / user-only, with the Claude Code frontmatter gate and prose everywhere else
**Chosen:** The last. `disable-model-invocation: true` in `SKILL.md`, a first line "invoked by the user only; never on your own judgment", the description's trigger clause dropped, the "Advisor model" section removed from `~/github.com/AGENTS.md` (an unversioned file the `sync-agentsmd` task pushes hourly from mac-mini-m2), and the grilling exclusion dropped with it, since a user who invokes the skill mid-grill has chosen. No `agents/openai.yaml`: the user chose prose over a Codex-only sidecar.
**Decided-by:** human
**Justification:** Transcript audit over 30 days: Claude Code invoked the skill 12 times at the user's request and once on its own; Codex 66 user to 1 model. The model trigger bought one pairing in a hundred and cost a rule in every agent's global instructions plus a description clause that every harness read differently. Only Claude Code honors the frontmatter gate; Codex has the opposite-direction `allow_implicit_invocation`; pi, omp, opencode, kimi and hermes have prose only, and hermes rejects the frontmatter key outright, so prose is the one gate all six share.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md; ~/github.com/AGENTS.md (unversioned)
**Supersedes:** Q25 (grilling exclusion → dropped: the user decides when to invoke).

## Q47 — herdr-advisor/watchdog — tradeoff

**Question:** Q45's loop gate was an advisor-side Stop hook, which exists on `claude` and `codex` only. Opening the advisor to every CLI Herdr can start (16 kinds installed here) asked how the loop stays alive where the harness has no such hook.
**Options considered:** a per-harness hook where one exists and no gate elsewhere / an in-harness gate for the two hooked kinds and prose for the rest / one Herdr-level watchdog outside every harness
**Chosen:** The last: `watchdog.sh`, planted in the advisor's pane by the worker (`herdr pane run <pane> "sh …/watchdog.sh <pane> &"`) after `pane split` and before `agent start`. Planted that early, every `herdr agent` call returns `agent_not_found` until the CLI registers, so it first polls `agent get` once a second for up to 300 s for a `*-advisor` name (giving up as `no-advisor`), and starts its turn cursor at 0, the count the handoff's own turn carries. Then it loops on `herdr agent wait --until working --until blocked`, a plain `wait`, and `agent get`; when the pane still holds a `*-advisor` name, the turn counter advanced, the agent is not `blocked`, and a 10 s re-check finds no new turn and the name still there, it re-prompts the advisor with the re-read-ADVISOR.md reason. Same 8-blocks-per-hour cap and `~/Library/Logs/herdr-advisor.log` as the hook it replaces, released with a Herdr notification. The end signal is the agent's name: `herdr agent rename <pane|name> --clear` from either side, the advisor's own last act or the worker's stop, after which the next turn end stands and the watchdog exits. Gone: `hook_selftest.py`, the `ADVISOR LOOP ENDED:` marker, and the rule against a worker base ending in `-advisor`, which only the in-harness hook needed. `stop-hook.sh` stays as a `printf '{}'` stub until `~/.agents/hooks/Stop.toml` and its rendered entries in `~/.claude/settings.json` and `~/.codex/hooks.json` are removed on all nine hosts: the hook file is unversioned and per-host, so a pull would otherwise leave every host's Stop hook calling a script that no longer exists.
**Decided-by:** human
**Justification:** A 14-CLI survey of turn-end hooks: cline, pi and opencode cannot gate a turn at all; kimi blocks once per turn and only from the global config; grok and copilot cap at 8; hermes gates only when code was edited; amp and cursor resume by new user message with a cap of 5; omp, qodercli, devin and agy block uncapped. Sixteen different gates with three holes is a patchwork; one script against the Herdr CLI is the same gate for all sixteen, and a background process planted in a pane survives `agent start` and every later turn (verified with `claude` and `pi`). The turn counter is the edge: `Esc` increments it like a finished turn, so a user interrupt is re-prompted like any early end, which is why the stop is a name clear rather than a key. Offline self-test of eight scenarios (registration gate and give-up, name cleared, worker name, turn 0 left alone then idle new turn → one prompt, blocked → none, cap with window and per-pane counting, grace, a stop landing inside the grace) and a live dry run on this machine; the advisor's spot-check found the grace path ignoring a name cleared mid-grace and the registration gap, both fixed before install.
**Outcome:** applied
**Ref:** herdr-advisor/watchdog.sh, watchdog_selftest.py, HARNESS-CLIS.md. Commit: d1e0507. stop-hook.sh stub removed 2026-09-18 after the fleet pass, commit 5b5a56a. watchdog.sh ported to watchdog.py 2026-09-18, Q50.
**Supersedes:** Q45's gate clause (advisor-side Stop hook → Herdr-level watchdog; the loop and the decision class stand).

## Q48 — herdr-advisor/watchdog-edge — tradeoff

**Question:** Live launches of all sixteen `HARNESS-CLIS.md` rows (2026-09-17) found two holes in Q47's watchdog. Kimi, oh-my-pi and Kiro never left `idle`/`turn` 0 in `herdr agent get` however much they worked, so the turn-counter edge never fired and the loop ended at the advisor's first early turn end. And the stop recipe (`rename --clear`, `esc`) on an already-idle advisor left the watchdog alive, since it only re-reads the name after a `wait` returns, and the waits were 600 s.
**Options considered:** change the edge to a status transition or `state_change_seq` / install the Herdr integrations for the kinds that have one / keep the turn edge and document the hole; shorten the waits so an idle stop lands within a minute.
**Chosen:** Keep the turn edge and shorten both `herdr agent wait` timeouts from 600 s to 60 s, so a name cleared on an idle advisor is seen within a minute (`SKILL.md` says so). For the frozen kinds, install `herdr integration install kimi` and `… omp` on this host and retest: kimi then counts turns and the row passes as written; omp's integration is an extension that the row's `--no-extensions` drops with the rest, so the row gains `-e ~/.omp/agent/extensions/herdr-omp-agent-state.ts` and then passes. Kiro has no integration (`herdr integration install` lists none) and stays a documented Gap, offered last. The kimi/omp requirement is a Gaps entry naming the install as the user's one-time per-host setup.
**Decided-by:** advisor
**Justification:** The rule that the skill never edits harness configs binds the launch recipe, not a Herdr install the user runs once per host, the same setup already done here for claude and codex and reversible with `herdr integration uninstall`. A status-transition edge would fire on every `working→idle` flicker the turn counter was chosen to ignore (Q47's Esc argument), and `state_change_seq` moves on cursor and title changes; the turn edge passed on fourteen kinds once the two integrations were in. The outdated claude integration (v8 < v10) is left alone until the running pairing ends: no swapping the state hook under a live session. The 60 s wait costs one `agent get` a minute per advisor and nothing else; the self-test still passes.
**Outcome:** applied
**Ref:** herdr-advisor/watchdog.sh, HARNESS-CLIS.md (omp row, Gaps), SKILL.md (Stop the advisor). Commit: d1e0507. watchdog.sh ported to watchdog.py 2026-09-18, Q50.

## Q49 — herdr-advisor/review-disposition — gate-resolution

**Question:** The user's standing rule puts every commit behind the `thermo-nuclear-code-quality-review` skill, and Phase D's commit was blocked on it: the skill carries `disable-model-invocation`, so the worker's Skill tool refuses it, and the worker had twice handed the step back to the user. How does that gate get satisfied, and which of the review's nine findings land before the commit?
**Options considered:** hold until the user types the slash command in the worker's pane / treat the user's "do 1 and 2" as waiving the review / the advisor sends the slash command through the composer, which the gate does not block, and disposes of the findings
**Chosen:** The last. The gate blocks the model's tool call, not a composer turn: `/thermo-nuclear-code-quality-review …` typed into the worker's pane loads the skill for the worker like any user message, so the advisor sent it as item 1 of the user's "do 1 and 2", and the review ran in the worker's own turn (findings at `/tmp/herdr-advisor-phaseD-review.md`). Disposition: 1 applied (`agent_pane_busy` is transient and fires about half the time even after the 3 s; the recipe now says retry after 2 s). 2 applied after one fold: the parity table was the only record that pi runs an open shell and has no web tool, so pi gained a Gaps entry, then the table went. 3 applied: host observations (cline's one-time notice, copilot's org policy, devin's Pro-only `--model`, the kimi/omp integration requirement, opencode's `.omo/` residue) moved under a new **Launch notes** heading; **Gaps** is again the design list. 4 applied in the other direction: `watchdog.sh` stays byte-identical, since it is the live-verified script and an env knob for a test is a knob nobody else turns; the self-test instead asserts both marker strings exist before replacing them, so a rename fails loudly instead of running at production timings. 8a and 8b applied (rewrap; `<provider>` defined). Rejected as follow-ups: 5 (rewrite the watchdog in Python) and 6 (one combined model×harness question; the two-question dialog is grill Q5's), and 9 (commit `launch-test.sh` as the reproducible check behind the daggers) stays out of this commit. 7 rejected per Q47: the `stop-hook.sh` stub stays until the fleet's Stop.toml is gone.
**Decided-by:** advisor
**Justification:** The rule is that the review runs before the commit, not that the user's hands run it; the composer path satisfies it without the worker replicating the skill's workflow, which its refusal message forbids. Each rejected finding trades a marginal gain against re-verifying a script that passed fifteen live kinds tonight or reopening a grilled decision; each applied one removes lines or a silent coupling and touches no decided question.
**Outcome:** applied
**Ref:** /tmp/herdr-advisor-phaseD-review.md (findings); herdr-advisor/SKILL.md, HARNESS-CLIS.md, watchdog_selftest.py

## Q50 — herdr-advisor/watchdog-python — deviation

**Question:** Q49 deferred three review findings as follow-ups: 5 (rewrite `watchdog.sh` in Python), 9 (commit the scratchpad `launch-test.sh`), and 6 (a combined model×harness question, grill Q5's two-question dialog). The user asked for all three. Does the Python port change the loop, and what verifies it?
**Options considered:** a line-for-line port of `watchdog.sh` into `watchdog.py` / take the port as the chance to redesign the edge (Q48's options) / keep the shell script and commit `launch-test.sh` alone
**Chosen:** The first. `watchdog.py` is `watchdog.sh` in one language instead of two: the same registration gate, waits, turn edge, grace, cap, log lines, `REASON` and release notification, verbatim, so Q47 and Q48 stand unchanged; only the shell's `set -- $(state)` positional juggling and the two python heredocs are gone. `SKILL.md`'s recipe line becomes `python3 …/watchdog.py <pane-id> &`; `watchdog_selftest.py` runs the same eight scenarios against the port, and its marker is now the one constants line. The scratchpad `launch-test.sh` lands as `harness/launch-test.sh` with its production-recipe planting (`python3 …/watchdog.py`), and `HARNESS-CLIS.md`'s legend names it as the launch behind a row without `†`. Finding 6 is put to the user as a grill question and is not settled here.
**Decided-by:** user
**Justification:** The review's estimate held: the port removes lines without moving a decision, and the risk Q49 named, re-verifying a live-verified script, is paid in full by re-running the fifteen-row live matrix through the committed `harness/launch-test.sh` against `watchdog.py` (results in the Ref). A redesign of the edge would reopen Q48 for no finding that asked for it.
**Outcome:** applied
**Ref:** herdr-advisor/watchdog.py (replaces watchdog.sh), watchdog_selftest.py, SKILL.md (recipe), HARNESS-CLIS.md (legend), harness/launch-test.sh. Commit: f181959. Live matrix 2026-09-18 02:08–02:25: 13 of 15 rows re-prompted once and released on the name clear (pi, claude, opencode, omp, kimi, agy, devin, cline, hermes, qodercli, amp, cursor, grok; grok on its second run, its turn counter stayed 0 on the first); kiro turn 0 throughout as its Gap says; codex out on quota until 2026-09-23, watchdog still re-prompted once and exited.

## Q51 — herdr-advisor/chooser-options — gate-resolution

**Question:** Review finding 6, deferred by Q49 and Q50: the chooser's second question (harness CLI) depends on the first (model), which one `AskUserQuestion` dialog cannot express, so every harness option carried a "for model X" caveat and the user answered through Other. One combined model×harness question, or keep the two-question shape from grill Q5?
**Options considered:** keep two questions and make each harness option name the model it would run / one combined question of at most four model×harness pairs / leave as is
**Chosen:** The first. Each harness option names its model (`codex: gpt-6-astra`), and a harness option naming a different model than question 1's choice is the user's answer to both. Two questions stay, so the model list keeps its four rows and the harness list its four.
**Decided-by:** user
**Justification:** A combined question caps the choice at four pairs where two questions offer up to sixteen, and reopens a grilled decision for a display problem; naming the model in the option is the display fix alone.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md (Choose the advisor, question 2). Commit: 80c87cc.

## Q52 — herdr-advisor/suggestion-first — gate-resolution

**Question:** The prompt suggestion (Claude Code's ghost text) was source 1 among the next-task sources since Q26, but the sources are reached only at the last step of Decide: a worker question, a surviving spot-check doubt and the `what's next` probe each composed text first, box unread. The user asked that a suggestion be taken with the right arrow instead of a composed prompt. Does that reach the Decide steps, and does "just send right arrow" drop the accept check?
**Options considered:** the suggestion beats every Decide step but `blocked` / it beats the doubt and the probe but a direct question is still answered / today's order, with wording against composing at the sources step only; and, for the recipe, keep the read-back check or send `right` and `enter` blind; and screen the accepted text for the two declines, or take it unread
**Chosen:** A new Decide step 2, right after `blocked`/`unknown`: a suggestion in the box is accepted by source 1's recipe, and a question, a doubt and the probe are composed only on a turn that ends with an empty box; an accepted suggestion is sent work and resets Q36's count. The recipe keeps its check (`right`, read the box for undimmed text with no user draft, `get`, `enter`, wait for `working`) and reads the ghost text, while still dim, for the two declines alone: a suggestion to spend money or destroy data the goal never named is not accepted and the decline is the next prompt, typed over it; everything else is taken (Q27 stands). The Next-task sources keep their order.
**Decided-by:** user
**Justification:** Grilling session, all recommendations accepted. The user's sentence carries no carve-out, and the ghost text after a worker's question is Claude Code's guess at the user's reply, which the advisor stands in for anyway; a question the suggestion did not answer returns next turn to an empty box, where step 3 answers it. The check stays because it is two commands and the only thing that tells ghost text from a user's half-typed draft, which `right` would merely cursor through. The two-decline screen is Decide's boundary already, applied to text the recipe reads anyway.
**Outcome:** applied
**Ref:** herdr-advisor/ADVISOR.md (Decide, Next-task sources). Commit: 0990dc3.
**Supersedes:** Q26 — only its rank claim (the suggestion now precedes the composed steps too, not just the other sources); Q45's Decide order gains a step.

## Q53 — herdr-advisor/handoff-authority — gate-resolution

**Question:** SKILL.md gives the handoff a freeform `Constraints:` slot and tells the worker to flag irreversible steps. A worker filled it with "pushing, tagging, publishing to crates.io or npm, and bumping the Homebrew formula are irreversible or outward-facing and need the user's say-so", which contradicts Decide's "everything else the worker proposes, including publishing, transferring, sending and force-pushing, gets a decision". Neither file said which wins. Does a handoff constraint narrow the advisor's two declines?
**Options considered:** the handoff binds, so a constraint may reserve a step for the user / the manual binds and any narrowing constraint is the worker's framing / a per-pair carve-out for outward-facing acts (Q30's shape, already superseded by Q39 and Q45)
**Chosen:** The manual binds. The two declines are the whole boundary and the handoff cannot narrow it: a constraint reserving a step for the user's say-so *because* it is irreversible or outward-facing is the worker's framing, not a user rule, and is decided anyway without spending the turn researching whether the advisor may. What the handoff reports the user actually said still binds as the goal does, so a faithfully relayed instruction to hold something is unaffected.
**Decided-by:** user
**Justification:** Observed live 2026-09-18 on the `agent-sync` pair (advisor `claude-fable-5-1`, transcript `56bea02b-0b7d-42b5-a78b-903f0faa8ada.jsonl`). The same advisor accepted the ghost suggestion `push it` in 14 s with one line of thinking, then spent **3 m 35 s** on `cut a 1.1.0 release` — two extended-thinking blocks and four tool calls, including a WebFetch of this journal from GitHub to read Q45 and Q52 — because the handoff's constraint contradicted the manual. `push it` was on that same constraint list and slipped through unnoticed, so the conflict was latent and fired on the larger item. The advisor resolved it as the user has now ruled ("the 'user say-so' line in the handoff was the worker framing, not a user rule, and my earlier 'those stay with the user' repeated it before I had read Q45"), then composed a prompt rather than accepting the suggestion, and agent-sync 1.1.0 published to crates.io, npm, PyPI and the Homebrew formula. Confirming the constraint was invented: none of the ten user prompts in the worker's transcript mentions release approval. The carve-out for a relayed instruction was added past the user's wording, because a blanket "handoff constraints do not bind" would also override a real hold the user had asked for.
**Outcome:** applied
**Ref:** herdr-advisor/ADVISOR.md (Decide). Does not supersede Q39 or Q45; it settles a conflict their two-decline boundary did not anticipate.

## Q54 — herdr-advisor/prompt-attribution — gate-resolution

**Question:** SKILL.md tells the worker to journal each call the advisor made with `Decided-by: advisor`, but never says how the worker tells an advisor's prompt from the user's. A worker invented its own test — look for text in the advisor's pane — and journaled its own push as the user's call ("No push instruction in the advisor's pane, so this is your call directly"), because the advisor had accepted the suggestion with the right arrow, which leaves no text behind. What test replaces it?
**Options considered:** keep the pane-text test with a caveat / Claude Code's own transcript fields (`origin.kind`, `promptSource`) / Herdr's `composer.evidence.provenance`, read for its positive values only, with the advisor as the default for an unattributed prompt / have the advisor announce every acceptance instead (an ADVISOR.md change)
**Chosen:** The third. The journal bullet now forbids reading an empty advisor pane as "the user", names `herdr agent get <your-pane-id>` and the two provenance values that prove authorship — `agent_prompt` when the advisor composed the text, `api` when it accepted a suggestion — states that `human` proves nothing, and makes the advisor the default for an unattributed prompt while the pair is live.
**Decided-by:** agent — the user chose the fix and confined it to SKILL.md; the one-directional reading and the default are the agent's, after the field check this list item originally proposed failed verification.
**Justification:** Measured on the `agent-sync` pair, 2026-09-18. Claude Code cannot settle it: `origin.kind` is `human` for all ten prompts in the worker's transcript, including the advisor's composed `herdr agent prompt` (L1537, L1793) and its accepted suggestions (L467, L1734), because the keystrokes arrive through the PTY. `promptSource` separates `typed` from `suggestion_accepted` but not who accepted — `suggestion_accepted` fired at 09:50 for a suggestion the *user* took, 48 minutes before the advisor existed. Herdr does settle it, one way: the composer attempt created at 10:52:40, the instant of the advisor's right arrow, reads `api`, and a `herdr agent prompt` reads `agent_prompt` (`evertranscript-advisor`, 10:49:57). `human` is Herdr's no-evidence fallback, not a detection: at 11:01:39 agent-sync's box spawned a fresh `human` attempt mid-turn with no user input and `cursor`, `region` and `style` all `unavailable` — hence the positive-values-only reading and the default. `composer` describes the live input box, not the submitted prompt: it held the right attempt for the whole 10:52:58–10:55:28 turn and was overwritten later, so it is read at turn start. Having the advisor announce its acceptances was left for a possible ADVISOR.md change; it would not repair a worker whose handoff predates it.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md (Work with the loop, the journal bullet). Commit: 376fdc4.

## Q55 — herdr-advisor/accept-then-correct — gate-resolution

**Question:** Decide step 2 bars composing "a question, a doubt and the probe" while the box holds a suggestion. An advisor that also had a correction to deliver read that list as exhaustive, composed a prompt over the suggestion rather than accepting it, and re-specified the task in the process. Is a correction a fourth forbidden thing, or does step 2 need a path for it?
**Options considered:** name the correction a fourth forbidden item / let a correction justify composing over the suggestion, as the advisor did / accept the suggestion, then send the correction as the next prompt
**Chosen:** The third. Step 2 keeps its bar on composing in the suggestion's place, and adds that anything else the advisor has to say — a correction to the record, a caveat, a constraint — rides the prompt *after* the acceptance, with the reason named: restating the suggestion invites the worker to re-plan it wider than it asked.
**Decided-by:** user
**Justification:** The corrections were legitimate, so forbidding them outright would lose real information; what cost more than a one-turn delay was composing in their place. The suggestion was four words, `cut a 1.1.0 release`; the prompt composed over it specified nine — runbook, version bump, `verify-packaging.sh`, commit, tag, push the tag, watch the workflow, journal, notify the peer — and agent-sync 1.1.0 published to crates.io, npm, PyPI and the Homebrew formula in that one turn. Source 2 already warns that restating a worker's own offer invites re-planning; step 2 now says the same where the text is Claude Code's guess at the user's reply. The delay is cheap in the observed case: the correction concerned the *previous* push's attribution (Q54), not the release, so it lost nothing by arriving a turn later. This is the third and last finding from the 2026-09-18 `agent-sync` pair, with Q53 (the stall) and Q54 (the misattribution it was correcting).
**Outcome:** applied
**Ref:** herdr-advisor/ADVISOR.md (Decide, step 2). Refines Q52, which set step 2 and named the three composed things; it does not disturb the two declines or the source 1 recipe.

## Q56 — herdr-advisor/grill-trigger — gate-resolution

**Question:** Q46 made the skill user-only, with Claude Code's `disable-model-invocation` gate hiding it from the model outright. A grilling session that ends in the user's "confirmed" then starts long work with no advisor, and a pair launched after the work is finished is useless. Does the worker get to invoke the skill itself, and in what case?
**Options considered:** flip the gate and carry one trigger clause in the description / keep the gate and have other visible text (the third-party grilling body, a second skill) tell the worker to read SKILL.md off disk / a `UserPromptSubmit` hook injecting SKILL.md on a confirmation-shaped prompt / a reminder at the end of the grill, leaving invocation to the user
**Chosen:** The first. `disable-model-invocation` deleted from the frontmatter, and the description gains one clause after the original text: the worker invokes the skill itself in one case only, before the first step of the work and whatever the plan's size, when a grilling session has ended with its frontier empty, the user's confirmation has it execute the plan now, no advisor pair is live, and the confirmation did not decline one. The body's opening rule spells the case out (the `grilling` skill however entered; opt-out phrases; a live pair means nothing to do; never during the grill, on a plan-mode approval, or on a "go ahead" after a written plan), scopes the outside-Herdr rule (on the trigger: one line, then proceed alone, as with no eligible model, CLI or quota), tells the handoff that after a grill the goal is one line and never the plan restated, and lets the grill trigger re-create an ended pair. The chooser dialog stays: the user is at the keyboard seconds after typing "confirmed", and Q51's two-question shape is untouched. README line updated to match.
**Decided-by:** user
**Justification:** Grilling session, recommendations accepted with three exceptions: the dialog stays rather than defaults taken silently; the advisor gets no spec, since the template's no-spec branch (state the goal) already covers it and ADVISOR.md's goal-based rules need no edit; and the clause goes after the original description, not before it, accepting that Codex may shorten it away — Codex on mac-mini-m2 does print "Skill descriptions were shortened to fit the skills context budget" with 165 skills installed. The gate is total in Claude Code (description hidden, Skill call blocked with an instruction not to reproduce the steps), so no prose anywhere could reach a hidden skill; and the grilling family is a lock-file install from mattpocock/skills, overwritten on update, so its body cannot carry the trigger. Codex needs no sidecar: its `allow_implicit_invocation` defaults to true and matches on the description, so one clause is the trigger on every harness. Verified twice on 2026-09-18 in a fresh Claude Code session in a Herdr pane, a two-round grill over creating one file. The first run showed the mechanism working and the judgment gap: the worker recognized the moment ("checking whether a Herdr environment is present since the grill just ended with confirmation"), then wrote the file first and skipped the pair because "the plan was a single command" — the incident's failure mode exactly, which is why the clause says "before the first step of the work and whatever the plan's size". The second run, with that wording, went `Skill(herdr-advisor)` → chooser → watchdog → `grilltest-advisor` (codex, gpt-6-astra) → handoff with a one-line goal → the file. The advisor itself then hit Codex's usage limit with a silent downgrade to gpt-5.6-luna, the outage SKILL.md already describes; the worker did not notice it, a pre-existing gap outside this change.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md (frontmatter, opening rule, Roles, Hand off, Stop the advisor); README.md.
**Supersedes:** Q46 — the frontmatter gate and the "user only" description wording only; its no-global-rule and no-`agents/openai.yaml` choices stand. Q25's exclusion stays superseded: the trigger fires after the grill, never during it.

## Q57 — herdr-advisor/dead-advisor — gate-resolution

**Question:** The quota clause named one tell, `You've hit your usage limit`, and said to re-create on the next eligible row, but never said when the worker looks. In Q56's verification the Codex advisor died 13 seconds after the handoff, silently downgraded to gpt-5.6-luna, and the worker reported the pair healthy. Who notices a dead advisor, when, and what replaces it?
**Options considered:** the worker reads the advisor pane at a defined moment / the watchdog greps the pane for the tell and prompts the worker or notifies the user / both; and for the moment: once after the handoff / before ending every turn while the pair is live; and for the replacement: silently on the next row / the chooser dialog again
**Chosen:** The worker, before ending every turn while the pair is live, with one `herdr agent read` of the advisor pane. Four tells, one remedy: a line beginning `You've hit your` and ending in `limit` (Claude Code's weekly, fast and monthly-spend limits; Codex's usage limit), a status line naming a model other than the one launched, a permission dialog (`blocked`), or the pane's agent gone. Stop it and close its pane, re-create on the next eligible row an installed harness can launch, through the harness's alias row when its own login is what ran out, told in the handoff when same-family; wait 20 s and read once more so a dead replacement falls through; never ask; report the swap in one line with the tell and the reset time. The restore-once-the-quota-resets clause is deleted. MODELS.md keeps one pointer to SKILL.md instead of its copy of the tell. The watchdog is untouched. No journal entry for a swap: the one-line report is enough.
**Decided-by:** user
**Justification:** Grilling session, recommendations accepted except journaling each swap. The advisor acts only at the worker's turn ends, so a read there catches every outage that matters, with no code and no new watchdog-to-worker channel (Q38 covers worker and advisor only). The tell was wider than the clause: Claude Code's own strings are "weekly", "fast" and "monthly spend" limits, and Codex's dead advisor left no error in its session log at all, so the pane text is the only signal. The restore clause had no trigger and was dead text; the next `/herdr-advisor` or grill trigger runs the chooser fresh. "Next eligible row" is mostly unlaunchable on the reference host: no CLI or gateway route reaches gemini, and the native Claude login was weekly-limited, so the only working row was `claude-fable-5-1` through the `claude-gw` alias environment, the path Q29 and Q31 took by hand. Verified live on 2026-09-18 with Codex out of quota: a fresh worker, the Q56 grill, Codex chosen in the dialog; at its turn end the worker read the tell, closed the pane, then walked the chain in one turn end — gemini-3-8-flash on Antigravity, which was installed and listed the model but hung on a file-access permission dialog for reading the manual outside the workspace; claude-fable-5-1 native, `You've hit your weekly limit`; claude-fable-5-1 with the gateway environment on the split, alive, its requests confirmed in the gateway log — 7 m 51 s for the turn, three dead panes closed, one live pair. The permission-dialog tell was added after the run because the worker treated the hang as dead on its own; it is the "never ask" rule's observable form, and it is not re-verified.
**Outcome:** applied
**Ref:** herdr-advisor/SKILL.md (Choose the advisor, Work with the loop, Stop the advisor); MODELS.md (Rules).
**Supersedes:** the quota clause's restore sentence; refines the clause Q29 and Q31 applied by hand into a rule.

## Q58 — herdr-advisor/links — interpretation

**Question:** The user asked for a URL per CLI in `HARNESS-CLIS.md` and three URLs in `SKILL.md` (DeepSWE, Claude Code's advisor tool, Codex auto-review). Where does each go, and what of zcode, which is on the list but has no row?
**Options considered:** a Links section at the end of each file / the URL on the table's CLI name and in the sentence that already names the thing / a zcode table row / a zcode note
**Chosen:** On the name: the table's first column links the CLI (markers and parentheticals stay outside the link text), and the three SKILL.md URLs ride the sentences that already name the advisor tool, auto-review and the ranking. zcode is one sentence after the table, not a row: Herdr has no `--kind` for it, and the file defines a row as a CLI Herdr can start.
**Decided-by:** user
**Justification:** A link beside its name is reached where the reader meets the name; a trailing section is a second list to keep in step with the table. Codex auto-review was named only in Q24 until now; it joins the "Unrelated to" paragraph because it and `--advisor` are the same shape, a second model in the user's seat inside the harness, which is what this skill is not. The DeepSWE link duplicates `MODELS.md`'s, at the user's request. All twenty URLs resolved on 2026-09-18 (`x.ai/build` answers 403 to curl only).
**Outcome:** applied
**Ref:** herdr-advisor/HARNESS-CLIS.md (table, zcode note); SKILL.md (Herdr advisor, Choose the advisor).

## Q59 — herdr-advisor/stop-through-worker — gate-resolution

**Question:** The worker's box held the Claude Code suggestion `stop the advisor` after its second flat "nothing left", and the advisor, already in its Ending branch, neither accepted it nor could clear its own name: `herdr agent rename "$HERDR_PANE_ID" --clear` was denied four times under the claude row's `dontAsk` allowlist, the watchdog re-prompted it twice, and it wrote in its own pane that the stop was the user's say-so. The user accepted the suggestion by hand thirteen minutes later. Is a stop suggestion accepted, when, and who ends the advisor?
**Options considered:** accept the stop suggestion whenever the box holds it, as step 2 orders, with a carve-out for a turn that asked a question / accept it only once the end condition is met, typing the probe over it before / never accept it, the advisor ends by its own rename; and for the ending: the advisor clears its own name as a third end / every end goes through the worker, which clears the name, sends Esc and closes the pane / only the suggestion path goes through the worker
**Chosen:** The stop suggestion is taken only at the end condition, the second flat "nothing left" or a user's stop message in the advisor's pane; before that, whatever the advisor would send on an empty box, the probe included, is typed over it. Every end goes through the worker: the advisor accepts the suggestion when the box holds it, otherwise sends the literal `stop the advisor`, then continues its pass with no closing line, and neither counts as sent work. The worker's recipe is always rename `--clear`, Esc, `pane close`, on a stop prompt from anyone or on a dead advisor's tell, and SKILL.md's "on the user's say-so" sentence now names the advisor's prompt in both forms.
**Decided-by:** user
**Justification:** Grilling session, 2026-09-18, on the `affix-x-handle` pair (advisor `claude-fable-5-1`, pane w8Y:p3, transcript `9aadbb73-633d-476f-92a0-0d1e9e2aeeb4.jsonl`). Recommendations accepted except two: the suggestion waits for the end condition rather than being taken on sight, so Q36's one probe still runs; and the advisor never ends itself, because it is read-only, so the worker owns every stop and closes the pane. The deferral was Q53's pattern once more: the advisor quoted the worker file's "on the user's say-so" as reserving the stop. Two earlier pairs the same day (agent-sync w8T, EverTranscript w8J) had accepted the suggestion by right arrow and Enter, the worker cleared the name and sent Esc within about fifteen seconds, and the advisor's turn ended interrupted, which is the shape now written down. Claude Code's interactive-mode documentation confirms Tab or Right arrow places a suggestion and Enter submits it. The Esc stays in the recipe ahead of the close because `herdr pane close` documents no behaviour for a mid-turn agent.
**Outcome:** applied
**Ref:** herdr-advisor/ADVISOR.md (Decide steps 2 and 5, source 1, Ending); SKILL.md (Choose the advisor, Work with the loop, Stop the advisor).
**Supersedes:** Q36 — the clause that the advisor's last message quotes both answers; the probe and the double "nothing left" stand. Refines Q52 and Q55: a stop suggestion is the one suggestion not taken on sight.

## Q60 — herdr-advisor/self-rename-removed — tradeoff

**Question:** The advisor's ending command, `herdr agent rename "$HERDR_PANE_ID" --clear`, is denied under the claude row: Claude Code's permissions documentation lists a command containing a shell variable among those a prefix allow rule such as `Bash(herdr:*)` never matches, and `dontAsk` denies what no rule allows. Fix the command or remove it?
**Options considered:** the advisor takes its pane ID from `herdr pane current --current` and passes it literally / the worker names the advisor's pane in the handoff / delete the command, since Q59 moves every end to the worker
**Chosen:** Deleted. ADVISOR.md no longer names a rename at all, and the watchdog docstring says the worker clears the name.
**Decided-by:** user — the literal-ID fix was accepted first; Q59's answer that the advisor never ends itself then made it moot, and the deletion follows from that answer.
**Justification:** Two advisors hit the denial on 2026-09-18. The one in pane w8R:p2P at 01:51 recovered by passing the literal ID, which the same allowlist accepted, proving the variable was the trigger; `affix-x-handle-advisor` had run the lookup and had `w8Y:p3` in hand but retried the variable form three more times. The same trap sits in every row that allows the shell by prefix (grok, qodercli), so a patched command would have needed a sentence per row. With the worker ending every pair no advisor needs the rename, and the harness rows keep their allowlists. The launch test's own name clear runs from the worker's shell with a literal ID and was never affected.
**Outcome:** applied
**Ref:** herdr-advisor/ADVISOR.md (Ending); watchdog.py (docstring); harness/launch-test.sh (comment).
**Supersedes:** Q47's framing of the end signal as the advisor's own act, carried into Q50's port; the signal itself, the name clear, is unchanged.

## Q61 — herdr-advisor/agy-gap — interpretation

**Question:** The Q59 worker reported one finding outside its confirmed scope: the Antigravity row's Gaps bullet names the `read_url` prompt but not the file-access prompt for a path outside the workspace, which killed the first advisor of that session on its first pass. Record it, or leave the row as it was?
**Options considered:** leave it, the row is launchable and the dead-advisor swap handled it / add one clause to the existing Antigravity Gaps bullet / drop the row
**Chosen:** One clause in the existing bullet: a file read outside the workspace asks too, and the manual's first step, reading the Herdr skill under `~/.agents`, triggers it at once.
**Decided-by:** advisor — it accepted the worker's prompt suggestion (`composer.evidence.provenance` read `api`).
**Justification:** A worker choosing agy from the chooser would otherwise learn the tell only by launching; the Gaps list exists so the worker chooses knowing. The row stays, since the dead-advisor swap recovers the pair in under a minute and a user with non-workspace reads allowed in their own Antigravity settings can still use it.
**Outcome:** applied
**Ref:** herdr-advisor/HARNESS-CLIS.md (Gaps, Antigravity). Commit: 2265ec4.
