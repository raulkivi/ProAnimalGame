% tree.pl — Tree traversal and learning
%
% Depends on: node.pl, ui.pl
%
% Design: traverse/3 relates the current tree to a (possibly) updated tree and
% a won/lost flag.  Where the Forth version threaded the *address of the cell*
% holding each node so that learn could patch the parent pointer in place with
% a single store, Prolog rebuilds the tree functionally: as we recurse down the
% chosen branch we unify the parent's other branch straight through and graft
% the new subtree onto the branch we descended.  The path from the root to the
% changed leaf is rebuilt; every untouched subtree is shared by unification.
% No cell addresses, no mutation, no parent back-pointers.
%
%   traverse(+Tree, -NewTree, -Won)
%   play_guess(+Leaf, -NewNode, -Won)
%   learn(+OldLeaf, -NewTree)              (interactive)
%   build_learned(+OldLeaf, +NewName, +Question, +NewAnimalIsYes, -NewTree)  (pure)

% ---------------------------------------------------------------------------
% traverse( +Tree, -NewTree, -Won )
% ---------------------------------------------------------------------------
% Walk from Tree following the player's yes/no answers.  At a leaf we guess;
% NewTree is Tree with the guessed leaf replaced by a learned question node on
% a wrong guess, or Tree unchanged on a correct one.

traverse(animal(Name), NewNode, Won) :-
    !,                                   % a leaf: make the guess
    play_guess(animal(Name), NewNode, Won).
traverse(question(Q, Yes, No), NewNode, Won) :-
    ask_yesno(Q, Answer),
    ( Answer == yes
    -> traverse(Yes, NewYes, Won),
       NewNode = question(Q, NewYes, No)
    ;  traverse(No, NewNo, Won),
       NewNode = question(Q, Yes, NewNo)
    ).

% ---------------------------------------------------------------------------
% play_guess( +Leaf, -NewNode, -Won )
% ---------------------------------------------------------------------------
% Ask "Is it a <name>?".  On yes we win and the leaf is unchanged.  On no we
% learn: NewNode becomes the question node produced by learn/2.

play_guess(animal(Name), NewNode, Won) :-
    guess_question(Name, GuessQuestion),
    ask_yesno(GuessQuestion, Answer),
    ( Answer == yes
    -> display_msg('I win!'),
       NewNode = animal(Name),
       Won = true
    ;  learn(animal(Name), NewNode),
       Won = false
    ).

% guess_question(+Name, -Question) — build "Is it a <Name>?".
guess_question(Name, Question) :-
    atom_concat('Is it a ', Name, Prefix),
    atom_concat(Prefix, '?', Question).

% ---------------------------------------------------------------------------
% learn( +OldLeaf, -NewTree )      (interactive shell)
% ---------------------------------------------------------------------------
% Collect the three learning inputs from the player, then hand them to the
% pure core build_learned/5.  Keeping I/O collection and tree construction in
% separate predicates is the single-responsibility split that makes the core
% learning rule unit-testable without any I/O (see tests/test_tree.pl).

learn(OldLeaf, NewTree) :-
    display_msg('I give up!  What animal were you thinking of?'),
    prompt_line('Animal name:', NewName),
    display_msg('Give me a yes/no question that tells the new animal from my guess:'),
    prompt_line('Question:', RawQuestion),
    ensure_question_mark(RawQuestion, Question),
    ask_yesno('For the new animal, is the answer to your question YES?', NewAnimalIsYes),
    build_learned(OldLeaf, NewName, Question, NewAnimalIsYes, NewTree).

% ensure_question_mark(+Raw, -Question) — the spec requires question text to
% end with "?"; append one if the player left it off.
ensure_question_mark(Raw, Raw) :-
    atom_codes(Raw, Codes),
    append(_, [0'?], Codes),
    !.
ensure_question_mark(Raw, Question) :-
    atom_concat(Raw, '?', Question).

% ---------------------------------------------------------------------------
% build_learned( +OldLeaf, +NewName, +Question, +NewAnimalIsYes, -NewTree )
% ---------------------------------------------------------------------------
% The pure learning rule.  The old leaf is replaced by a new question node
% whose children are the new animal and the old guess, ordered by which branch
% the player said the new animal is on.  Two clauses, no conditionals.

build_learned(OldLeaf, NewName, Question, yes,
              question(Question, animal(NewName), OldLeaf)).
build_learned(OldLeaf, NewName, Question, no,
              question(Question, OldLeaf, animal(NewName))).
