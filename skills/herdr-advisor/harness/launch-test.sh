#!/bin/sh
# Live test of one HARNESS-CLIS.md row, the check behind a row without `†`:
# split a pane under ROOT, plant the watchdog exactly as SKILL.md says, start
# the agent, send one four-step probe (an out-of-workspace read, herdr, a
# non-herdr command, a write: the advisor's first pass and every prompt seen
# on a live row), let the watchdog re-prompt the ended turn, clear the name,
# confirm the watchdog exits, close the pane. Needs Herdr and the CLI's login.
# One summary line per row on stdout: reply=blocked is a prompt that hung,
# wrote=yes a write the row approved. Run it from a scratch directory, since
# the probe writes into the cwd.
# Usage: sh harness/launch-test.sh <root-pane> <kind> [--env K=V ...] -- <native args>
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.kimi-code/bin:$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/local/bin:$PATH"
ROOT=$1; KIND=$2; shift 2
# Values may hold spaces (JSON); single-quote them for the eval below.
ENVS=""; while [ "$1" != "--" ]; do ENVS="$ENVS $1 '$2'"; shift 2; done; shift
LOG=$HOME/Library/Logs/herdr-advisor.log
strip() { sed 's/\x1b\][^\x07]*\x07//g'; }
field() { strip | grep -oE "\"$1\":(\"[^\"]*\"|[0-9]+)" | head -1 | cut -d: -f2- | tr -d '"'; }
state() { herdr agent get "$P" 2>&1 | strip | python3 -c '
import json,sys
t=sys.stdin.read()
try:
    a=json.loads(t[t.index("{"):])["result"]["agent"]; print(a.get("agent"), a.get("name"), a.get("agent_status"), a.get("turn"))
except Exception: print("- - gone -1")'; }
note() { printf '%s\n' "$*" >&2; }

P=$(eval herdr pane split --pane "$ROOT" --direction down --cwd "$PWD" --no-focus $ENVS 2>&1 | field pane_id)
[ -n "$P" ] || { echo "$KIND: FAIL pane split"; exit 1; }
finish() {
    case "$*" in FAIL*|*no-reply*|*reply=blocked*) note "--- screen $KIND:"; herdr pane read "$P" --source visible 2>&1 | strip | grep -v '^\s*$' | tail -18 >&2 ;; esac
    herdr pane close "$P" >/dev/null 2>&1; echo "$KIND: $*"; }

herdr pane run "$P" "python3 ~/.agents/skills/herdr-advisor/watchdog.py $P &" >/dev/null 2>&1
sleep 3
NAME="t-$KIND-advisor"
tries=0
while :; do
    out=$(herdr agent start "$NAME" --kind "$KIND" --pane "$P" --timeout 90000 -- "$@" 2>&1 | strip)
    case "$out" in *agent_pane_busy*) tries=$((tries+1)); [ $tries -lt 15 ] && { sleep 2; continue; } ;; esac
    break
done
note "$KIND: start after $tries busy retries"
case "$out" in *'"error"'*) finish "FAIL start: $(printf '%s' "$out" | grep -oE '"code":"[^"]*"' | head -1) $(printf '%s' "$out" | grep -oE '"message":"[^"]{0,120}' | head -1)"; exit 1 ;; esac
set -- $(state); started="kind=$1 name=$2 status=$3"
pgrep -f "watchdog.py $P" >/dev/null || { finish "FAIL watchdog died before start ($started)"; exit 1; }

# One prompt, the probe; its turn end is what the watchdog must catch. A
# prompt that leaves the agent idle at turn 0 never landed (seen on agy):
# send it once more.
F=advisor-probe-$$.txt   # per run, so parallel runs in one directory do not clobber each other's check
rm -f "$F"
PROBE="Do these four steps in order, each with the tool named, then say in one line which were refused: 1. read the first line of ~/.agents/skills/herdr-advisor/ADVISOR.md with your file-reading tool; 2. run the shell command \`herdr agent list\`; 3. run the shell command \`date\`; 4. create a file named $F in the current directory containing the word probe, with your file-editing tool. Finish with exactly the word ADVISOR-OK on its own line."
herdr agent prompt "$P" "$PROBE" --wait --timeout 300000 >/dev/null 2>&1
set -- $(state); t1=$4; s1=$3
if [ "$t1" = 0 ] && [ "$s1" = idle ]; then
    note "$KIND: probe did not land; resending once"
    herdr agent prompt "$P" "$PROBE" --wait --timeout 300000 >/dev/null 2>&1
    set -- $(state); t1=$4; s1=$3
fi
screen=$(herdr agent read "$P" --source visible 2>&1 | strip)
recent=$(herdr agent read "$P" --source recent-unwrapped --lines 120 2>&1 | strip)
case "$s1:$recent" in blocked:*) reply=blocked; note "--- dialog $KIND:"; printf '%s\n' "$screen" | grep -v '^\s*$' | tail -12 >&2 ;; *ADVISOR-OK*) reply=ok; note "--- reply $KIND:"; printf '%s\n' "$recent" | grep -v '^\s*$' | tail -8 >&2 ;; *) reply="no-reply(status=$s1)" ;; esac
if [ -f "$F" ]; then wrote=yes; rm -f "$F"; else wrote=no; fi

# Grace is 10 s; give the re-prompt 25 s to land, then clear the name.
sleep 25
n_blocked=$(grep -c "\"pane\":\"$P\",\"action\":\"blocked\"" "$LOG" 2>/dev/null)
set -- $(state); t2=$4; s2=$3
# SKILL.md's stop recipe minus the close, which finish does: clear the name, then Esc the running turn.
herdr agent rename "$P" --clear >/dev/null 2>&1
herdr agent send-keys "$P" esc >/dev/null 2>&1
herdr agent wait "$P" --timeout 60000 >/dev/null 2>&1
# The watchdog's waits time out at 60 s, so an idle advisor's name clear shows within 65 s.
i=0; while pgrep -f "watchdog.py $P" >/dev/null && [ $i -lt 70 ]; do sleep 1; i=$((i+1)); done
wd=$(pgrep -f "watchdog.py $P" >/dev/null && echo alive || echo exited)
end=$(grep "\"pane\":\"$P\"" "$LOG" 2>/dev/null | tail -1 | grep -oE '"action":"[^"]*"' | cut -d'"' -f4)
finish "$started reply=$reply wrote=$wrote turn=$t1-$t2 reprompts=$n_blocked watchdog=$wd last-log=$end"
