# WWW-ARDB House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the force-loaded
skills — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; when uncertain, ask rather than guess.
   Push back when a simpler approach exists; stop when confused and name what is unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
   The API's exact shape is the contract; no fallbacks for fields that don't exist.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match the existing layout.
4. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave
   a regression test behind. The API mapping is the product — a test that can't fail
   when it changes is not a test.
5. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
6. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
   wrong if any were skipped.
7. **A red test is a claim before it is a failure** — Say what it asserts and whether
   your fix keeps that claim or replaces it.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run
  tests, edit non-behavioral docs. Only the `www-ardb-*` agents get their skills
  force-loaded; you get no briefing.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `www-ardb-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `www-ardb-release-manager` |

- **You cannot spawn subagents** (you ARE a `www-ardb-*` agent): The delegation lock
  does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = `lib/`, the tests, the CLI commands, the API mapping, the cache. Docs and `Changes` wording are not.

**Only `www-ardb-release-manager` commits.** A worker leaves a commit-ready tree and
hands its card to `review`; you then dispatch the release-manager to cut the commit.

## The API mapping is the contract — don't regress it silently

This library's whole value is *how an API response is turned into an object*. The
camelCase-to-snake_case mapping, the three resources (items, quests, arc enemies), the
`*_raw` variants that hand back the untouched payload and the `from_hashref` entry
point are what callers depend on. A change to any of them is a user-visible change: it
needs a `Changes` entry and a test. Full contract table: skill `www-ardb-core`. The
sharp edge is the field the library does not know yet — `_raw` is the honest way to
reach it, a speculative attribute is a promise nobody asked for.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job: `karr` is always in scope — use it, don't invoke the skill first.
`karr list --compact` / `karr board` for open work, `karr show ID` for detail,
`karr create --title … --priority … --body …` for a ticket, `karr edit ID -a …`,
`karr move ID in-progress --claim NAME` to start, `karr handoff ID --claim NAME` to
review, `karr sync --pull|--push` for explicit exchange.

Card life cycle: you claim and hand out → the worker notes and ends at `review` → the
release-manager commits and moves it to `done`. **Serialize board mutations when
fanning out:** collect the results and then loop the `karr move`/`handoff`/`sync` calls
sequentially — N of them landing at once is a resource event, not a cheap command. Full
command surface: `kanban-issues-karr-coordination`.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any
CPAN upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if
a plan lists "release" as the next step. Stop and ask. The last CPAN release is 0.002
(2026-01-11); the repo carries 0.003 — the *next* unreleased version.

## Public issues — never act without instruction

`karr` is the internal agent board, churned freely. The GitHub issue tracker carries
real people's reports under the maintainer's account. Never act on a public issue on
your own initiative — not even to read it. No listing, viewing, commenting, closing or
creating unless the user explicitly says so.

## Perl specifics — reference, don't restate

Perl conventions live in the force-loaded skills (`getty-perl-core`, `getty-perl-moo`,
`getty-perl-pod`, `getty-perl-release-author-getty`); the module map, the API mapping
and the cache layout live in skill `www-ardb-core`. Do not duplicate them here.
