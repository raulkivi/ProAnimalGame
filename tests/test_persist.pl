% test_persist.pl — Unit tests for src/persist.pl
%
% Load order (see Makefile): harness.pl, src/node.pl, src/persist.pl, this file.

% A fake repository (the DEFER-swap analogue) for Test 6.  Declared multifile so
% it joins persist.pl's backend_load/3 clauses.
:- multifile(backend_load/3).
backend_load(stub, _Path, animal('Stub')).

% write_file(+Path, +Text) — helper to lay down raw file contents for the
% corrupt-input tests.
write_file(Path, Text) :-
    open(Path, write, Stream),
    write(Stream, Text),
    nl(Stream),
    close(Stream).

% ---------------------------------------------------------------------------
% Test 1: save then load round-trips a 3-node tree
% ---------------------------------------------------------------------------

:- initialization(assert_true('save/load round-trip',
       ( TreeIn = question('Is it a mammal?', animal('Wolf'), animal('Parrot')),
         save_tree(TreeIn, '/tmp/animal_test_tree.pl'),
         load_tree('/tmp/animal_test_tree.pl', TreeOut),
         TreeOut == TreeIn ))).

% ---------------------------------------------------------------------------
% Test 2: loading a missing file yields the default seed tree
% ---------------------------------------------------------------------------

:- initialization(assert_true('missing file -> default seed',
       ( load_tree('/tmp/no-such-animal-file-xyz.pl', T),
         T == animal('Dog') ))).

% ---------------------------------------------------------------------------
% Test 3: a syntactically corrupt file falls back to the default
% ---------------------------------------------------------------------------

:- initialization(assert_true('corrupt file -> default seed',
       ( write_file('/tmp/animal_corrupt.pl', 'X this is not a valid prolog term'),
         load_tree('/tmp/animal_corrupt.pl', T),
         T == animal('Dog') ))).

% ---------------------------------------------------------------------------
% Test 4: a well-formed term that is not a valid tree falls back to the default
% ---------------------------------------------------------------------------

:- initialization(assert_true('structurally invalid term -> default seed',
       ( write_file('/tmp/animal_invalid.pl', 'tree(garbage).'),
         load_tree('/tmp/animal_invalid.pl', T),
         T == animal('Dog') ))).

% ---------------------------------------------------------------------------
% Test 5: an empty file falls back to the default
% ---------------------------------------------------------------------------

:- initialization(assert_true('empty file -> default seed',
       ( open('/tmp/animal_empty.pl', write, S), close(S),
         load_tree('/tmp/animal_empty.pl', T),
         T == animal('Dog') ))).

% ---------------------------------------------------------------------------
% Test 6: the repository is a swappable interface (DEFER analogue)
% ---------------------------------------------------------------------------

:- initialization(assert_true('repository is swappable',
       ( set_repository(stub),
         load_tree('ignored-path', T),
         T == animal('Stub') ))).

:- initialization(set_repository(file)).   % restore the real repository

:- initialization(end_suite('test_persist.pl')).
