% ui.pl — Abstract I/O layer (a swappable backend)
%
% All user interaction goes through three predicates so that the game engine
% (tree.pl, main.pl) has zero dependency on concrete I/O:
%
%   ask_yesno(+Prompt, -Answer)   Answer is the atom yes or no
%   prompt_line(+Prompt, -Line)   Line is the typed text as an atom
%   display_msg(+Message)         print a message followed by a newline
%
% The Forth version made these DEFER words and let tests rebind them.  The
% Prolog analogue is a strategy selected by a dynamic fact: current_io_backend/1
% names the active backend, and each public predicate dispatches to a
% backend_*/N clause for that backend.  ui.pl ships the `console` backend;
% tests load a `scripted` backend (tests/scripted_io.pl) and switch to it with
% set_io_backend/1 — no game logic is touched.

:- dynamic(io_backend/1).

% default_io_backend(-Backend) — used until set_io_backend/1 chooses otherwise.
default_io_backend(console).

% current_io_backend(-Backend) — the active backend.
current_io_backend(Backend) :-
    ( io_backend(Backend) -> true ; default_io_backend(Backend) ).

% set_io_backend(+Backend) — install Backend as the active I/O strategy.
set_io_backend(Backend) :-
    retractall(io_backend(_)),
    assertz(io_backend(Backend)).

% --- public API (dispatches to the active backend) --------------------------

ask_yesno(Prompt, Answer) :-
    current_io_backend(Backend),
    backend_ask_yesno(Backend, Prompt, Answer).

prompt_line(Prompt, Line) :-
    current_io_backend(Backend),
    backend_prompt_line(Backend, Prompt, Line).

display_msg(Message) :-
    current_io_backend(Backend),
    backend_display(Backend, Message).

% The backend predicates are multifile so alternative backends (e.g. the test
% double in tests/scripted_io.pl) can add their own clauses in other files.
:- discontiguous(backend_ask_yesno/3).
:- discontiguous(backend_prompt_line/3).
:- discontiguous(backend_display/2).
:- multifile(backend_ask_yesno/3).
:- multifile(backend_prompt_line/3).
:- multifile(backend_display/2).

% --- input classification ---------------------------------------------------

% first_nonblank(+Codes, -Char) — first non-space code, or 0 if none.
first_nonblank([], 0).
first_nonblank([C | Cs], Char) :-
    ( C =:= 32 -> first_nonblank(Cs, Char) ; Char = C ).

% classify_yn(+Text, -Answer, -Valid)
% Classify a typed answer by its first non-blank character (case-insensitive):
%   y/Y -> (yes, true)   n/N -> (no, true)   anything else -> (no, false)
classify_yn(Text, Answer, Valid) :-
    atom_codes(Text, Codes),
    first_nonblank(Codes, Char),
    classify_char(Char, Answer, Valid).

classify_char(Char, yes, true) :- Lower is (Char \/ 32), Lower =:= 0'y, !.
classify_char(Char, no,  true) :- Lower is (Char \/ 32), Lower =:= 0'n, !.
classify_char(_,    no,  false).

% --- console backend --------------------------------------------------------
%
% GNU Prolog has no read_line/1, so read_line_atom/1 reads characters up to a
% newline (or end of file) itself.

% read_line_atom(-Atom) — read one line of input as an atom (newline dropped).
read_line_atom(Atom) :-
    read_line_codes(Codes),
    atom_codes(Atom, Codes).

read_line_codes(Codes) :-
    get_char(Char),
    ( Char == end_of_file -> Codes = []
    ; Char == '\n'        -> Codes = []
    ; char_code(Char, Code),
      Codes = [Code | Rest],
      read_line_codes(Rest)
    ).

% The default ask re-prompts until the answer is a valid yes/no.
backend_ask_yesno(console, Prompt, Answer) :-
    write(Prompt), write(' (yes/no): '), flush_output,
    read_line_atom(Line),
    ( classify_yn(Line, YesNo, true)
    -> Answer = YesNo
    ;  backend_ask_yesno(console, Prompt, Answer)   % invalid — ask again
    ).

backend_prompt_line(console, Prompt, Line) :-
    write(Prompt), write(' '), flush_output,
    read_line_atom(Line).

backend_display(console, Message) :-
    write(Message), nl.
