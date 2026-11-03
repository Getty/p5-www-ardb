# CLAUDE.md

## Project Overview

Perl client library for [ardb.app](https://ardb.app) ARC Raiders Database API.

## Modules

- **WWW::ARDB** - Main API client (items, quests, arc-enemies)
- **WWW::ARDB::CLI** - Command-line interface

## Key API Endpoints

```
https://ardb.app/api/items
https://ardb.app/api/items/{id}
https://ardb.app/api/quests
https://ardb.app/api/quests/{id}
https://ardb.app/api/arc-enemies
https://ardb.app/api/arc-enemies/{id}
```

## Testing

```bash
prove -l t/                    # Run with MockUA fixtures
USE_LIVE_API=1 prove -l t/     # Run against live API
```

Fixtures in `t/fixtures/` must match exact API response format.

## CLI

Binary: `bin/ardb`

Commands use MooX::Cmd + MooX::Options in `lib/WWW/ARDB/CLI/Cmd/`.

## Code Style

- Moo for OOP
- Result classes parse API responses via `from_hashref()`
- Request classes build HTTP::Request objects
- Support ONLY exact API format - no speculative fallbacks

The conventions above are the short list; the binding ones live in the skills and
are force-loaded into the agents below. Do not restate them here.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the principle is a shared house rule (skilletor bundle `getty-cpan-dist@getty`); lanes
and hazards are in `.claude/rules/www-ardb-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-ardb-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-ardb-release-manager` |

Only the release-manager commits; a worker leaves a commit-ready tree and a report.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The shared skills under `.claude/skills/`
are **installed** from the Getty library by skilletor — they are not edited here.
`www-ardb-core` is the one skill this repo owns: module map, the camelCase →
snake_case mapping contract, request/cache layout, CLI conventions, vocabulary and
the known rough edges.

## State of the code

- The library, the result classes and the six CLI commands are implemented —
  `prove -lr t/` runs offline against `t/fixtures/`.
- Cached responses expire after `max_age` seconds (default 86400); an entry
  without a usable timestamp counts as expired. `cache_max_age` on the client
  chooses the age, `0` always fetches fresh.
- The `cpanfile` declares `Types::Standard`, which the code imports; `dist.ini`
  carries `copyright_year` and `LICENSE` is committed.
- The list commands filter client-side; the API is not asked to filter.
