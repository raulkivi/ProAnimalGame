% main.pl — Game loop and entry point
%
% Depends (load order): node.pl, ui.pl, tree.pl, persist.pl
%
% The engine holds no mutable "current root".  Where the Forth build kept a
% game-root VARIABLE and mutated the tree in place, here each round is a pure
% transformation Tree -> NewTree, and the loop simply threads NewTree into the
% next round.  State lives on the stack, not in a global cell.

% save_path(-Path) — where the learned tree is persisted between sessions.
save_path('data/tree.pl').

% init_game(-Tree) — load the saved tree, or the seed tree on first run.
init_game(Tree) :-
    save_path(Path),
    load_tree(Path, Tree).

% play_round(+Tree, -NewTree) — one full round, then persist the result.
play_round(Tree, NewTree) :-
    traverse(Tree, NewTree, _Won),    % _Won already reported by the engine
    save_path(Path),
    save_tree(NewTree, Path).

% game_loop(+Tree) — play rounds until the player declines another.
game_loop(Tree) :-
    play_round(Tree, NewTree),
    ask_yesno('Would you like to play again?', Again),
    ( Again == yes
    -> game_loop(NewTree)
    ;  true
    ).

% run_game — entry point: load, then loop.
run_game :-
    init_game(Tree),
    game_loop(Tree).
