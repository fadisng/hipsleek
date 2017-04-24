#!/usr/bin/env swipl
:- module(orders, [event/2,hb/4,cb/4,snot/1]).
:- use_module(library(chr)).

:- initialization main.
:- chr_constraint event/2,hb/4,cb/4,snot/1.


% disable singleton warning
:- style_check(-singleton).


% %% HOW TO USE
% Events are pairs of role x label:
% e.g.  event(A,1), event(B2,a)

% Happens-before relations are tuples of (event x event):
% e.g.  hb(A,1,B2,a)

% Communicates-before relations are pairs of (event x event):
% e.g.  cb(A,a,B2,a)

%% SAMPLE QUERIES
%Q: hb(X,1,Y,2),hb(X,0,Y,2),hb(Y,2,Z,3),hb(Z,3,Y,2).
%A: false

%Q: hb(X,1,Y,2),hb(X,0,Y,2),hb(Y,2,Z,3).
%A: true


%%%%%%%%%%
%%%% RULES
%%%%%%%%%%

dual   @ snot(hb(A,L1,B,L2)) ==> hb(B,L2,A,L1).
dual   @ snot(A;B) ==> snot(A),snot(B).
dual   @ snot((A,B)) ==> snot(A);snot(B).
% false when contradiction is detected : (a <_HB b && b <_HB a)
asym   @ hb(A,L1,B,L2), hb(B,L2,A,L1) ==> false.
% HB transitivity 
hbhb   @ hb(A,L1,B,L2), hb(B,L2,C,L4) ==> hb(A,L1,C,L4).
% CB transitivity 
cbhb   @ cb(A,L1,B,L1), hb(B,L1,C,L4) ==> hb(A,L1,C,L4).

%%%%%%%%%%
%%%% UTILS
%%%%%%%%%%
writeln(T) :- write(T), nl.

% read query from file, and detect end of file
read_goals(Stream,[]):-
        at_end_of_stream(Stream).
read_goals(Stream,[X|L]):-
        \+ at_end_of_stream(Stream),
        read(Stream,Gl),
        % writeln(Gl),
        once((Gl)).

checkff :-
        current_prolog_flag(argv, [File]),
        catch(open(File,read,Str), E,
              ( print_message(error, E),
                halt
              ) ),
        read_goals(Str,Gl),
        close(Str).

main :-
        ((checkff,writeln(true)) ; (\+(checkff),writeln(false))),
        halt.
