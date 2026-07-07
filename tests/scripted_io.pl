% scripted_io.pl — a test double for the ui.pl backend
%
% Depends on: src/ui.pl (for set_io_backend/1 and the backend_*/N contract)
%
% This is the Prolog counterpart of the Forth tests' scripted-ask-yesno /
% scripted-prompt-line words: it registers a `scripted` I/O backend that
% answers from FIFO queues instead of the terminal, and switches ui.pl to it.
% Tests fill the queues with reset_scripts/0 + push_yn/1 + push_str/1, then run
% game logic; the engine consumes the scripted answers unaware it is not a
% real player.

:- dynamic(yn_queue/1).
:- dynamic(str_queue/1).

% reset_scripts — empty both answer queues.
reset_scripts :-
    retractall(yn_queue(_)),
    retractall(str_queue(_)).

% push_yn(+Answer) — enqueue a yes/no answer (the atom yes or no).
push_yn(Answer) :-
    assertz(yn_queue(Answer)).

% push_str(+Text) — enqueue a line of text (an atom) for prompt_line.
push_str(Text) :-
    assertz(str_queue(Text)).

% The scripted backend consumes the oldest queued answer (assertz + retract of
% the first clause gives FIFO order, so answers come back in push order).
:- multifile(backend_ask_yesno/3).
:- multifile(backend_prompt_line/3).
:- multifile(backend_display/2).

backend_ask_yesno(scripted, _Prompt, Answer) :-
    retract(yn_queue(Answer)),
    !.

backend_prompt_line(scripted, _Prompt, Line) :-
    retract(str_queue(Line)),
    !.

backend_display(scripted, _Message).   % tests do not inspect display output

:- initialization(set_io_backend(scripted)).
