% 
% Converts a file in the Prodigal report format to the Prolog 
% format that is required be the framebias model
%

:- ['../lost.pl'].
:- lost_include_api(prodigal).

prodigal_to_prolog(ProdigalFile, PrologFile) :-
        parse_prodigal_file(ProdigalFile, PrologFile).
