% persist.pl — Save and load the decision tree
%
% Depends on: node.pl
%
% Because a node is already an ordinary Prolog term, persistence needs no
% bespoke format or parser: we write the tree with the standard term writer and
% read it back with the standard reader.  The save file is a single readable
% clause:
%
%   tree(question('Can it catch mice?',
%                 animal('Cat'),
%                 animal('Dog'))).
%
% This is the Prolog counterpart of the Forth build's pre-order "Q ... / A ..."
% text format — still human-readable, diffable, and hand-editable, but the
% reader is Prolog's own, so there is nothing to hand-roll and nothing to keep
% in sync with the data structure.
%
% Like the Forth repository (its save-tree / load-tree DEFER words), the store
% is swappable: current_repository/1 selects the backend, defaulting to the
% file backend below.  Tests bind a fake repository to exercise callers without
% the filesystem.

:- dynamic(repository/1).

default_repository(file).

current_repository(Repo) :-
    ( repository(Repo) -> true ; default_repository(Repo) ).

% set_repository(+Repo) — install Repo as the active tree store.
set_repository(Repo) :-
    retractall(repository(_)),
    assertz(repository(Repo)).

% --- public API (dispatches to the active repository) -----------------------

% save_tree(+Tree, +Path)
save_tree(Tree, Path) :-
    current_repository(Repo),
    backend_save(Repo, Tree, Path).

% load_tree(+Path, -Tree)
load_tree(Path, Tree) :-
    current_repository(Repo),
    backend_load(Repo, Path, Tree).

:- discontiguous(backend_save/3).
:- discontiguous(backend_load/3).
:- multifile(backend_save/3).
:- multifile(backend_load/3).

% --- default seed tree ------------------------------------------------------

% default_tree(-Tree) — the single-leaf tree used before anything is learned
% and whenever the save file is missing, empty, or unusable.
default_tree(animal('Dog')).

% --- structural validation --------------------------------------------------
%
% A file may parse as a valid Prolog term yet not be a valid tree (e.g.
% tree(garbage)).  valid_tree/1 rejects those so load falls back to the seed
% instead of handing malformed data to the engine.

valid_tree(animal(Name)) :-
    atom(Name).
valid_tree(question(Text, Yes, No)) :-
    atom(Text),
    valid_tree(Yes),
    valid_tree(No).

% --- file backend -----------------------------------------------------------

% backend_save(file, +Tree, +Path)
% Writes to "<Path>.tmp" then renames onto <Path> for atomicity, so a crash
% mid-write can never leave a half-written save file.
backend_save(file, Tree, Path) :-
    atom_concat(Path, '.tmp', TmpPath),
    open(TmpPath, write, Stream),
    catch(write_tree_term(Stream, tree(Tree)),
          Error,
          ( close(Stream), throw(Error) )),
    close(Stream),
    atomic_rename(TmpPath, Path).

% write_tree_term(+Stream, +Term) — emit Term as a readable clause ("Term.").
% Prefer portray_clause (pretty, indented); fall back to writeq for portability.
write_tree_term(Stream, Term) :-
    ( catch(portray_clause(Stream, Term), _, fail)
    -> true
    ;  writeq(Stream, Term), write(Stream, '.'), nl(Stream)
    ).

% atomic_rename(+From, +To) — rename From onto To.  Uses rename_file/2 when the
% Prolog provides it, otherwise shells out to mv (POSIX rename is atomic on the
% same filesystem, which .tmp and its target always are).
atomic_rename(From, To) :-
    ( catch(rename_file(From, To), _, fail)
    -> true
    ;  atom_concat('mv ', From, C0),
       atom_concat(C0, ' ', C1),
       atom_concat(C1, To, Command),
       system(Command)
    ).

% backend_load(file, +Path, -Tree)
% Reads the tree from Path.  Falls back to the seed tree when the file is
% missing, empty, syntactically corrupt, or structurally invalid — matching the
% Forth build's "graceful degradation" guarantee.
backend_load(file, Path, Tree) :-
    ( catch(read_tree_file(Path, Loaded), _, fail),
      valid_tree(Loaded)
    -> Tree = Loaded
    ;  default_tree(Tree)
    ).

% read_tree_file(+Path, -Tree) — read one tree/1 clause; fails/throws otherwise.
read_tree_file(Path, Tree) :-
    open(Path, read, Stream),
    catch(read(Stream, Term), Error, ( close(Stream), throw(Error) )),
    close(Stream),
    Term = tree(Tree).
