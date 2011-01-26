% 
% Converts a file in the genemark report format to the Prolog 
% format that is required be the framebias model
%

:- ['../lost.pl'].
:- lost_include_api(genemark).

genemark_to_prolog(GenemarkFile, PrologFile) :-
        genemark_ldata_parser_main(GenemarkFile, PrologFile).
