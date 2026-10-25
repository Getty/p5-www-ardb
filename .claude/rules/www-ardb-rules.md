# WWW-ARDB House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Perl client for the ARC Raiders Database API (ardb.app). The repo carries 0.003, the next
unreleased version after the last CPAN release 0.002.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `www-ardb-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `www-ardb-release-manager` |
| Read-only research, audit, gap analysis | `www-ardb-worker` ("read-only, change nothing") |

Behavior-relevant = `lib/`, the tests, the CLI commands, the API mapping, the cache. Docs and
`Changes` wording are not.

## Hazards — the API mapping is the contract

- **Don't regress it silently.** This library's whole value is *how an API response is turned
  into an object*. The camelCase-to-snake_case mapping, the three resources (items, quests,
  arc enemies), the `*_raw` variants that hand back the untouched payload and the
  `from_hashref` entry point are what callers depend on. A change to any of them is a
  user-visible change: it needs a `Changes` entry and a test — a test that can't fail when
  the mapping changes is not a test. Full contract table: skill `www-ardb-core`.
- **No fallbacks for fields that don't exist.** The API's exact shape is the contract. For a
  field the library does not know yet, `_raw` is the honest way to reach it — a speculative
  attribute is a promise nobody asked for.

## Perl specifics — reference, don't restate

Perl conventions live in the force-loaded skills (`getty-perl-core`, `getty-perl-moo`,
`getty-perl-pod`, `getty-perl-release-author-getty`); the module map, the API mapping and the
cache layout live in skill `www-ardb-core`.
