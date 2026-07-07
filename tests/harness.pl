% harness.pl — a tiny unit-test harness
%
% The Forth build used gforth's T{ ... -> ... }T assertion words.  This is the
% Prolog counterpart: each check is an initialization goal
%
%   :- initialization(assert_true('description', Goal)).
%
% that runs Goal once and records a pass if it succeeds, a fail if it fails or
% throws.  A suite ends with
%
%   :- initialization(end_suite('test_foo.pl')).
%
% which prints a summary and halts with exit status 0 (all passed) or 1 (any
% failed), so `make test` reflects the result.  Each suite runs in its own
% gprolog process, mirroring the Forth per-file test targets.
%
% NOTE: the initialization/1 wrapper is required.  GNU Prolog's byte-code
% loader (used by --consult-file) executes only declaration directives and
% initialization/1 goals; a bare `:- assert_true(...)` is reported as an
% "unknown directive" and silently ignored, so no checks would run.

:- dynamic(pass_total/1).
:- dynamic(fail_total/1).

pass_total(0).
fail_total(0).

% assert_true(+Desc, +Goal) — record a pass iff Goal succeeds once.
% Always succeeds itself, so a failing check never aborts the consult.
assert_true(Desc, Goal) :-
    catch(
        ( once(Goal) -> note_pass ; note_fail(Desc, 'goal failed') ),
        Error,
        note_fail(Desc, Error)
    ).

note_pass :-
    retract(pass_total(N)),
    N1 is N + 1,
    assertz(pass_total(N1)).

note_fail(Desc, Why) :-
    format('  FAIL: ~w  (~w)~n', [Desc, Why]),
    retract(fail_total(N)),
    N1 is N + 1,
    assertz(fail_total(N1)).

% end_suite(+SuiteName) — print the summary and halt with a status code.
end_suite(SuiteName) :-
    pass_total(P),
    fail_total(F),
    ( F =:= 0
    -> format('~w: all tests passed (~w checks)~n', [SuiteName, P]),
       halt(0)
    ;  format('~w: ~w FAILED, ~w passed~n', [SuiteName, F, P]),
       halt(1)
    ).
