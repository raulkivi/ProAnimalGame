# CLAUDE.md — Animal Game (GNU Prolog)

A "20 questions" animal-guessing game. The knowledge base is a binary decision
tree (`animal(Name)` leaves, `question(Text, Yes, No)` nodes) that grows as the
program learns and is persisted to `data/tree.pl`.

## Commands

- `make run`   — play the game
- `make test`  — run all four unit suites (node, ui, tree, persist)
- `make clean` — delete the saved tree (`data/tree.pl`)

Run everything from the project root: the save path is resolved relative to the
working directory. Requires GNU Prolog (`gprolog`, tested against 1.5.0).

## Layout

- `src/node.pl`    — node terms + accessors (`is_leaf/1`, `make_question/4`, …)
- `src/ui.pl`      — I/O with a swappable backend (`set_io_backend/1`)
- `src/tree.pl`    — traversal + learning (`traverse/3`, `build_learned/5`)
- `src/persist.pl` — save/load with a swappable repository (`set_repository/1`)
- `src/main.pl`    — `run_game/0` entry point
- `tests/`         — one suite per source module, plus `harness.pl` and the
  `scripted_io.pl` test double

## GNU Prolog constraints (important)

- **No module system.** Sources are consulted in dependency order; the Makefile
  encodes that order. Keep predicate names globally unambiguous.
- **Only declaration directives and `initialization/1` goals run at load time.**
  A bare `:- Goal.` (e.g. `:- assert_true(...)`) is reported as an unknown
  directive and silently ignored. All behavioral test checks are therefore
  wrapped: `:- initialization(assert_true('desc', Goal)).` A suite ends with
  `:- initialization(end_suite('file.pl')).`, which prints the summary and
  `halt/1`s with the right exit status.
- Persistence uses the native reader/writer (`writeq` / `read`); a corrupt or
  missing file simply fails to read and falls back to the seed tree
  `animal('Dog')`.

## Conventions

- **TDD.** Add or update the matching `tests/test_*.pl` suite alongside any
  source change, and keep `make test` green (expected: 10 + 8 + 6 + 6 checks).
- Swappable backends (I/O, repository) are the seams for testing — use
  `scripted_io.pl` / a stub repository rather than real terminal or disk I/O.
- Learning rebuilds the tree functionally (sharing untouched subtrees), never
  by mutation.

See [`docs/AnimalGame.md`](docs/AnimalGame.md) for the full design spec and
predicate-level API.
