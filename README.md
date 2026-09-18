# herdr-advisor

Pair a [Herdr](https://github.com/herdrdev/herdr) worker with one **advisor** — a stronger model,
running in its own pane, that answers the worker's questions on the user's behalf to unblock it and
leads it to its next task.

The worker does all the work and makes every change. The advisor is a **read-only leaf**: it never
edits, it tells the worker what to change. A worker that stops with *"still waiting on your go"*
gets `go` and keeps moving — which is the point. The pair runs while you are away.

Invoked by the user only (`/herdr-advisor`), never on the agent's own judgment.

## Install

### Universal (any skills-compatible agent)

```text
npx skills add OpenSWE/herdr-advisor
```

### Claude Code (plugin)

```text
/plugin marketplace add OpenSWE/herdr-advisor
/plugin install herdr-advisor@herdr-advisor
```

### The install path is load-bearing

Eight places in the skill hardcode `~/.agents/skills/herdr-advisor/` — the watchdog's launch line,
the advisor's handoff prompt, and four harness rows that pass a config file by absolute path. **The
skill only works when it lands at exactly that path, under exactly that name.** Both routes above
produce it, and so does `agent-sync adopt <clone>/skills/herdr-advisor` if you would rather track a
git clone. If you vendor it anywhere else, rewrite those paths.

## Requirements

| | |
|---|---|
| [Herdr](https://github.com/herdrdev/herdr) | The terminal multiplexer this drives. `HERDR_ENV=1` must be set — outside Herdr the skill stops. |
| The `herdr` skill | A **separate** skill this one reads before operating on agents: `npx skills add herdrdev/herdr`. Not bundled here. |
| `python3` | The watchdog and its self-test. Standard library only — no packages to install. |
| macOS | Only for the watchdog log at `~/Library/Logs/herdr-advisor.log`. Everything else is portable. |
| A second CLI, logged in | The advisor runs in its own harness. 16 CLIs are mapped in `HARNESS-CLIS.md`. |

## What's in it

All under [`skills/herdr-advisor/`](skills/herdr-advisor/):

| File | Reader | Purpose |
|---|---|---|
| `SKILL.md` | the **worker** | Choose the advisor, split the pane, plant the watchdog, hand off, stop the pair. |
| `ADVISOR.md` | the **advisor** | Read-only rules, the polling loop, decision precedence, next-task sources, end conditions. |
| `MODELS.md` | worker | 29 models ranked by DeepSWE v1.1 Pass@1, plus who is eligible to advise whom. |
| `HARNESS-CLIS.md` | worker | 16 coding-agent CLIs: Herdr `kind`, effort rung, exact launch arguments, and per-CLI gaps. |
| `watchdog.py` | — | Keeps the advisor's loop alive from *outside* its harness: re-prompts any turn that ends while the pane still holds an advisor name. 8 blocks/hour cap; exits when the name is cleared. |
| `watchdog_selftest.py` | — | 8 offline scenarios against a fake `herdr` on `PATH`. No Herdr needed. |
| `harness/` | — | Per-CLI read-only permission configs (Devin, Kimi, Kiro, oh-my-pi, OpenCode) and `launch-test.sh`. |

## Testing

Offline, no Herdr required — this is the regression gate:

```sh
cd skills/herdr-advisor && python3 watchdog_selftest.py   # prints: ok
```

It takes the path to `watchdog.py` as an optional argument, defaulting to the current directory.

Live, one `HARNESS-CLIS.md` row end to end (needs a running Herdr session and that CLI logged in) —
it splits a pane, plants the watchdog, starts the agent, verifies a re-prompt, clears the name,
verifies the watchdog exits, then closes the pane:

```sh
sh harness/launch-test.sh <root-pane> <kind> [--env K=V ...] -- <native args>
```

A row in `HARNESS-CLIS.md` without a `†` is one this has passed.

## Why the rules are what they are

[`DECISIONS.md`](DECISIONS.md) — 31 entries, Q22 onward, recording every consequential call behind
this skill, kept per the [`log-decisions`](https://github.com/OpenSWE/log-decisions) skill. Start
there before changing a rule; most of them are load-bearing in a way that is not obvious.

## Provenance

Extracted from [`soulmachine/skills`](https://github.com/soulmachine/skills) with its full commit
history. Configs ship with placeholders (`<model-id>`, `<your-devin-org-id>`) — fill them in before
first use.

## License

MIT
