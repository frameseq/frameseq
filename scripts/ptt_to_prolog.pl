% 
% Converts a file in GeneBank PTT format to the Prolog 
% format that is required be the framebias model
%

:- ['../lost.pl'].
:- lost_include_api(ptt).
:- lost_include_api(io).

ptt_to_prolog(PTTFile, PrologFile) :-
        parse_ptt(unknown,PTTFile,PrologTerms),
        terms_to_file(PrologFile,PrologTerms).
