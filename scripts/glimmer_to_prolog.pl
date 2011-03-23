:- ['../lost.pl'].
:- lost_include_api(misc_utils).
:- lost_include_api(utils_parser_report).

glimmer_to_prolog(GlimmerFile,PrologFile) :-
	glimmer3_parse_prediction_file(GlimmerFile,PrologFile).

test :-
	glimmer_to_prolog('../data/NC_000913.Glimmer3','../data/NC_000913.Glimmer3.pl').

glimmer3_parse_prediction_file(InputFile,OutputFile) :-
	open(InputFile,read,InputStream2),
	open(OutputFile,write,OStream),
       	(glimmer3_prediction_parser(InputStream2,OStream) ; true),
	close(OStream),
	close(InputStream2).

glimmer3_prediction_parser(IS,OS) :-
        readline(IS,NextLine),
        glimmer3_prediction_parser_rec(IS,OS,NextLine).

% End of file:
glimmer3_prediction_parser_rec(_,_,[-1]) :- !.

% Empty lines:
glimmer3_prediction_parser_rec(IS,OS,[]) :-
        !,
        glimmer3_prediction_parser(IS,OS).

% Comment lines, e.g. the prediction file will start with something like
% >gi|48994873|gb|U00096.2| Escherichia coli str. K-12 substr. MG1655, complete genome
glimmer3_prediction_parser_rec(IS,OS,[62|Rest]) :-
        !,
        atom_codes(Comment_Atom,[37,62|Rest]),
        write(OS,Comment_Atom),
	write(OS,'\n'),
        glimmer3_prediction_parser(IS,OS).

glimmer3_prediction_parser_rec(IS, OS, Line) :-
	!,
        parser_line(Line,LineTokens),
        glimmer3_prediction_line(Term,LineTokens,[]),
        write(OS,Term), write(OS,'.'), write(OS,'\n'),
        glimmer3_prediction_parser(IS,OS).

glimmer3_prediction_line(glimmer3_gene_prediction(unknown,CorrectedStart,CorrectedEnd,Strand,Frame,[score(Score)])) -->
	[ _OrfId, Start, End],
	strand_frame_token(Strand,Frame),
	[ Score ],
	{ integer(Start), integer(End), integer(Frame), float(Score),
		((Start > End) ->
			CorrectedStart = End, CorrectedEnd = Start
			;
			CorrectedStart = Start, CorrectedEnd = End)
	}.


strand_frame_token(Strand,Frame) -->
	[ StrandFrameToken ],
	{
	   atom_codes(StrandFrameToken, [StrandCode,FrameCode]),
	   atom_codes(Strand,[StrandCode]),
	   atom_codes(FrameAtom,[FrameCode]),
	   atom2integer(FrameAtom,Frame)
	}.
	

