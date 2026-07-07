% test_tree.pl — Unit tests for src/tree.pl
%
% Load order (see Makefile):
%   harness.pl, src/node.pl, src/ui.pl, tests/scripted_io.pl, src/tree.pl, this file
%
% scripted_io.pl has already switched the UI backend to `scripted`, so the
% traversal/learning code below runs against queued answers with no real I/O.

% Small fixture tree:
%
%   Is it a mammal?
%   +-- YES -> Wolf
%   +-- NO  -> Parrot
%
% tr_root(-Tree)
tr_root(question('Is it a mammal?', animal('Wolf'), animal('Parrot'))).

% ---------------------------------------------------------------------------
% Test 1: traversal reaches the correct leaf on the YES branch and wins
% ---------------------------------------------------------------------------

:- initialization(( reset_scripts,
     push_yn(yes),        % "Is it a mammal?"  -> yes
     push_yn(yes),        % "Is it a Wolf?"    -> yes (correct guess)
     tr_root(Root),
     assert_true('YES branch, correct guess wins',
         ( traverse(Root, NewTree, Won),
           Won == true,
           NewTree == Root )) )).       % correct guess leaves the tree unchanged

% ---------------------------------------------------------------------------
% Test 2: traversal reaches the correct leaf on the NO branch and wins
% ---------------------------------------------------------------------------

:- initialization(( reset_scripts,
     push_yn(no),         % "Is it a mammal?"  -> no
     push_yn(yes),        % "Is it a Parrot?"  -> yes (correct guess)
     tr_root(Root),
     assert_true('NO branch, correct guess wins',
         ( traverse(Root, NewTree, Won),
           Won == true,
           NewTree == Root )) )).

% ---------------------------------------------------------------------------
% Test 3: a wrong guess triggers learning and rebuilds the tree
%
%   Before: animal('Dog')
%   Player thinks of Wolf; question "Does it live in the wild?"; Wolf = YES
%   After:  question('Does it live in the wild?', animal('Wolf'), animal('Dog'))
% ---------------------------------------------------------------------------

:- initialization(( reset_scripts,
     push_yn(no),                                   % "Is it a Dog?" -> no (wrong)
     push_str('Wolf'),                              % new animal name
     push_str('Does it live in the wild?'),         % distinguishing question
     push_yn(yes),                                  % new animal answers YES
     assert_true('wrong guess learns a new question node',
         ( traverse(animal('Dog'), NewTree, Won),
           Won == false,
           NewTree == question('Does it live in the wild?',
                               animal('Wolf'), animal('Dog')) )) )).

% ---------------------------------------------------------------------------
% Test 4: the pure learning rule, both branch orderings (no I/O involved)
% ---------------------------------------------------------------------------

:- initialization(assert_true('build_learned: new animal on YES branch',
       ( build_learned(animal('Dog'), 'Wolf', 'Does it live in the wild?', yes, T),
         T == question('Does it live in the wild?', animal('Wolf'), animal('Dog')) ))).

:- initialization(assert_true('build_learned: new animal on NO branch',
       ( build_learned(animal('Dog'), 'Wolf', 'Does it live in the wild?', no, T),
         T == question('Does it live in the wild?', animal('Dog'), animal('Wolf')) ))).

% ---------------------------------------------------------------------------
% Test 5: an untouched sibling subtree is preserved through a deep learn
%
% Descend YES into the mammal branch, guess Wolf wrong, learn — the Parrot
% (NO) subtree must be carried through unchanged.
% ---------------------------------------------------------------------------

:- initialization(( reset_scripts,
     push_yn(yes),                                  % "Is it a mammal?" -> yes
     push_yn(no),                                   % "Is it a Wolf?"   -> no (wrong)
     push_str('Dog'),
     push_str('Does it live in the wild?'),
     push_yn(no),                                   % new animal (Dog) answers NO
     tr_root(Root),
     assert_true('sibling subtree preserved after deep learn',
         ( traverse(Root, NewTree, _Won),
           NewTree == question('Is it a mammal?',
                               question('Does it live in the wild?',
                                        animal('Wolf'), animal('Dog')),
                               animal('Parrot')) )) )).

:- initialization(end_suite('test_tree.pl')).
