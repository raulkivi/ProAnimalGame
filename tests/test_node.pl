% test_node.pl — Unit tests for src/node.pl
%
% Load order (see Makefile): harness.pl, src/node.pl, this file.

% ---------------------------------------------------------------------------
% Animal (leaf) node
% ---------------------------------------------------------------------------

:- initialization(assert_true('animal is a leaf',        is_leaf(animal('Dog')))).
:- initialization(assert_true('animal is not a question', \+ is_question(animal('Dog')))).
:- initialization(assert_true('animal text is its name',  ( node_text(animal('Dog'), T), T == 'Dog' ))).
:- initialization(assert_true('make_animal builds a leaf', ( make_animal('Dog', N), N == animal('Dog') ))).

% ---------------------------------------------------------------------------
% Question (internal) node
% ---------------------------------------------------------------------------

:- initialization(assert_true('question is not a leaf', \+ is_leaf(question('Is it a mammal?', animal('Dog'), animal('Wolf'))))).
:- initialization(assert_true('question is a question', is_question(question('Is it a mammal?', animal('Dog'), animal('Wolf'))))).

:- initialization(assert_true('make_question builds the term',
       ( make_question('Is it a mammal?', animal('Dog'), animal('Wolf'), N),
         N == question('Is it a mammal?', animal('Dog'), animal('Wolf')) ))).

:- initialization(assert_true('question text accessor',
       ( node_text(question('Is it a mammal?', animal('Dog'), animal('Wolf')), T),
         T == 'Is it a mammal?' ))).

:- initialization(assert_true('yes-child accessor',
       ( node_yes(question('Is it a mammal?', animal('Dog'), animal('Wolf')), Y),
         Y == animal('Dog') ))).

:- initialization(assert_true('no-child accessor',
       ( node_no(question('Is it a mammal?', animal('Dog'), animal('Wolf')), No),
         No == animal('Wolf') ))).

:- initialization(end_suite('test_node.pl')).
