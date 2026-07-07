% test_ui.pl — Unit tests for src/ui.pl input classification
%
% Load order (see Makefile): harness.pl, src/ui.pl, this file.
%
% classify_yn(+Text, -Answer, -Valid):
%   Valid == true  when the first non-blank char is y/Y or n/N
%   Answer == yes  for y/Y, no otherwise

:- initialization(assert_true('yes -> yes/true',   ( classify_yn('yes',   A, V), A == yes, V == true ))).
:- initialization(assert_true('Y   -> yes/true',   ( classify_yn('Y',     A, V), A == yes, V == true ))).   % case-insensitive
:- initialization(assert_true('no  -> no/true',    ( classify_yn('no',    A, V), A == no,  V == true ))).
:- initialization(assert_true('N   -> no/true',    ( classify_yn('N',     A, V), A == no,  V == true ))).
:- initialization(assert_true('leading blanks skipped', ( classify_yn('  yes', A, V), A == yes, V == true ))).
:- initialization(assert_true('maybe -> invalid',  ( classify_yn('maybe', _A, V), V == false ))).   % not y/n
:- initialization(assert_true('empty -> invalid',  ( classify_yn('',      _A, V), V == false ))).
:- initialization(assert_true('all blanks -> invalid', ( classify_yn('   ', _A, V), V == false ))).

:- initialization(end_suite('test_ui.pl')).
