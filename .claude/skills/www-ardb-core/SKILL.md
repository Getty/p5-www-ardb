---
name: www-ardb-core
description: "Load before editing WWW-ARDb — the Perl client for the ardb.app API: module map, the camelCase-to-snake_case mapping contract of the result classes, request/cache layer, CLI conventions and the rough edges of this repository."
---

# WWW::ARDB — core

A client library for the **ardb.app** API (the ARC Raiders Database) plus a small
command line client on top of it. The library turns API responses into Moo objects
for three resources — **items**, **quests** and **ARC enemies** — and caches raw
responses on disk.

The distribution has **13 modules and one binary**:

| File | Role |
|---|---|
| `lib/WWW/ARDB.pm` | the client: `items`/`item`/`quests`/`quest`/`arc_enemies`/`arc_enemy` plus the `*_raw` variants, the finders and `_fetch` |
| `lib/WWW/ARDB/Request.pm` | builds the `HTTP::Request` objects — endpoint path, query parameters, `Accept: application/json` |
| `lib/WWW/ARDB/Cache.pm` | file cache: key, path, read/write/clear |
| `lib/WWW/ARDB/Result/Item.pm` | result class for items, `from_hashref`, `icon_url` |
| `lib/WWW/ARDB/Result/Quest.pm` | result class for quests, `from_hashref`, `trader_name`, `trader_type`, `map_names` |
| `lib/WWW/ARDB/Result/ArcEnemy.pm` | result class for ARC enemies, `from_hashref`, `icon_url`, `image_url`, `drops` |
| `lib/WWW/ARDB/CLI.pm` | the `ardb` command class: global flags, `api` accessor, `execute` help text |
| `lib/WWW/ARDB/CLI/Cmd/*.pm` | one class per subcommand (6 of them) |
| `bin/ardb` | the executable: builds `WWW::ARDB::CLI` and runs it |

## The layering and its direction

```
bin/ardb  →  WWW::ARDB::CLI  →  WWW::ARDB::CLI::Cmd::*  →  WWW::ARDB  →  Request / Cache
                                                 ↘  WWW::ARDB::Result::{Item,Quest,ArcEnemy}
```

Dependencies point **left to right, one way only**. The CLI never talks to
`Request` or `Cache` directly, and `WWW::ARDB` never formats output. A change
belongs to the layer that owns it:

- a new API field → the **result class** (attribute + `from_hashref` mapping + POD)
- a URL, a query parameter, a header → **Request**
- HTTP, error handling, cache read/write → **`WWW::ARDB::_fetch`**
- output format, flags → **the CLI command class**

## The mapping is the contract

The API speaks camelCase, the library speaks snake_case. The translation happens
in exactly one place per class — `from_hashref` — and it runs **one way**:

| API field | Attribute |
|---|---|
| `stackSize` | `stack_size` |
| `foundIn` | `found_in` |
| `updatedAt` | `updated_at` |
| `requiredItems` | `required_items` |
| `xpReward` | `xp_reward` |
| `dropTable` | `drop_table` |
| `relatedMaps` | `related_maps` |

Fields the API may send in camelCase that the library does not map yet stay
reachable through **`_raw`**, which holds the untouched API hash. `_raw` is the
honest way to look at an unmapped field — a speculative attribute is a promise
nobody asked for. When a field gets an attribute, the attribute, the `from_hashref`
mapping and the POD entry belong to **one edit**.

Array-valued fields default to `[]` (`found_in`, `maps`, `breakdown`, `crafting`,
`steps`, `required_items`, `rewards`, `drop_table`, `related_maps`); scalar fields
default to `undef` and are typed `Maybe[...]`.

Each result class pairs its raw counterpart with an `*_raw` method on the client:
`items()` vs `items_raw()`, `item($id)` vs `item_raw($id)`. The `*_raw` methods
return the decoded API structure — the cache stores exactly this.

## The finders

`find_item_by_name`, `find_item_by_id`, `find_quest_by_title` and
`find_arc_enemy_by_name` work **on the already fetched collection** and return the
first match (case-insensitive for the name variants). They are conveniences, not
a second API surface — they do not fetch anything the caller has not fetched.

## The request layer

`Request` owns `BASE_URL` (`https://ardb.app/api`), the endpoint path and the query
parameters. One request object per API call; the client passes it to
`$self->ua->request(...)`. A failing HTTP response becomes
`croak "API request failed: " . $response->status_line` — there is no error object
and no retry. `WWW::ARDB` has no `ua` injection point of its own: the attribute is
`is => 'lazy'` with a builder, so a test replaces it (`$api->ua($mock)`).

## The cache layer

- Directory: `~/.cache/ardb` on Linux, `%LOCALAPPDATA%\ardb` elsewhere, overridable
  via the `cache_dir` attribute.
- Key: `<namespace>_<endpoint>` plus `_` plus `md5_hex` of the JSON-encoded
  parameters. `namespace` defaults to `default`.
- File: `<key>.json`, containing `{timestamp, endpoint, data}`.
- **There is no TTL.** The timestamp is written but never evaluated — a cached
  response is returned forever until `clear_cache` is called. This is a known
  rough edge, not an oversight to be silently "fixed"; changing it changes what
  callers see.
- `use_cache` can be switched off per client (`WWW_ARDB_NO_CACHE`), and the CLI
  exposes it as `--no-cache`.

## The CLI

`WWW::ARDB::CLI` is a `MooX::Cmd` application. The subcommand classes follow
MooX::Cmd's package-tree convention: **`WWW::ARDB::CLI::Cmd::Items` becomes
`ardb items`**. A new subcommand is a new class under `lib/WWW/ARDB/CLI/Cmd/`,
never a branch inside an `execute`.

The six commands are `items`, `item`, `quests`, `quest`, `enemies`, `enemy`. The
list commands (`items`, `quests`, `enemies`) fetch the **whole** collection and
filter **client-side**: `--search` is a case-insensitive substring match on the
name, `--type`/`--rarity` are case-insensitive exact matches. Moving a filter to
the server changes what a caller sees and needs a test that pins the new
behaviour.

Global flags are parsed in `around BUILDARGS` with `Getopt::Long` in
`pass_through` mode, so `ardb items --search guitar` reaches the subcommand
instead of being swallowed by the application class.

## Rough edges in this repository

Known, recorded, not to be "cleaned up" as a side effect of unrelated work:

- The `cpanfile` names **`Type::Tiny`**, but the code imports **`Types::Standard`**
  (`Cache.pm`, `Result/Item.pm`, `Result/Quest.pm`, `Result/ArcEnemy.pm`). The
  declared runtime dependency is wrong.
- `dist.ini` has no `copyright_year` and there is no committed `LICENSE`.
- `WWW::ARDB::CLI::_build_api` creates a **fresh** `WWW::ARDB` — the CLI offers no
  way to inject a client, so the CLI cannot be tested against a mock without
  changing that.
- `WWW::ARDB::Request` builds query parameters via `query_form`; a parameter the
  API does not know is sent anyway.
- The `bin/ardb` POD documents only `WWW_ARDB_DEBUG`; `WWW_ARDB_NO_CACHE` and
  `WWW_ARDB_JSON` are read by the code but undocumented.

## Vocabulary

- **client** — a `WWW::ARDB` instance; the only thing that talks to the API.
- **request** — the `HTTP::Request` built by `WWW::ARDB::Request`.
- **endpoint** — the API path: `items`, `items/<id>`, `quests`, `quests/<id>`,
  `arc-enemies`, `arc-enemies/<id>`.
- **result class** — one of the three `WWW::ARDB::Result::*` classes.
- **raw** — the decoded API structure, without object mapping; `*_raw` on the
  client, `_raw` on the object.
- **namespace** — the cache key prefix, so two parameter sets do not collide.

## Tests

`t/` holds ten files: `00-load.t`, `01-cache.t`, `02-request.t`, one file per
result class (`03`–`05`), `10-api.t`, `11-api-fixtures.t`,
`12-cache-integration.t` and `20-cli.t`. `t/fixtures/` holds the API payloads the
tests read; `t/lib/` holds the test helpers.

```bash
prove -lr t/
```

The suite is offline: the API is never contacted, the client gets a mock user
agent. A behavioural change — a new attribute, a changed mapping, a changed
filter, a changed cache key — needs a test that pins it.

## Distribution conventions

`dist.ini` uses `[@Author::GETTY]`, `bin/`, `lib/`, `t/` and a `Changes` file in
CPAN format with a `{{$NEXT}}` section. Every module carries its own
`our $VERSION` — the *next unreleased* version, currently `0.003` after the
`0.002` release. Dependencies live in `cpanfile`, not in `dist.ini`.
