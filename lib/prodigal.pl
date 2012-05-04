% Parser for the Prodigal file format

:- lost_include_api(misc_utils).
:- lost_include_api(io).
% A DCG parser for prodigal result files

parse_prodigal_file(ProdigalFile,PredictionsFile) :-
	readFile(ProdigalFile,Contents),
	prodigal_parse(Predictions,Contents,[]), 
	terms_to_file(PredictionsFile,Predictions).
	
prodigal_parse(Predictions) -->
	definition_line,
	features_line,
	cds_entries(Predictions),
	dcg_codes('//'),
	end_of_line.

cds_entries([]) --> [].
cds_entries([P|Ps]) -->
	cds_entry(P),
	cds_entries(Ps).

cds_entry(prodigal_prediction(na,Left,Right,Strand,Frame,Extra)) -->
	cds_first_line(Left,Right,Strand,Frame),
	end_of_line,
	cds_second_line(Extra),
	end_of_line.
	
definition_line -->
	dcg_codes('DEFINITION'),
	match_characters_except([10,13]),
	end_of_line.
	
features_line -->
	dcg_codes('FEATURES'),
	match_characters_except([10,13]),
	end_of_line.

cds_first_line(Left,Right,'+',Frame) -->
	spaces,
	cds,
	spaces,
	left_right(Left,Right),
	spaces,
	{ Frame1 is 1 + (Left mod 3), rotate_left(Frame1,Frame) }.

cds_first_line(Left,Right,'-',Frame) -->
	spaces,
	cds,
	spaces,
	complement_left_right(Left,Right),
	spaces,
	{ Frame1 is 1 + (Left mod 3), rotate_left(Frame1,Frame) }.

rotate_left(1,3).
rotate_left(2,1).
rotate_left(3,2).


cds_second_line(Extra) -->
	spaces,
	dcg_codes('/note="'),	
	note_entries(Extra),
	dcg_codes('"').

note_entries([]) --> [].
note_entries([Entry]) -->
	note_entry(Entry).
note_entries([Entry|Rest]) -->
	note_entry(Entry),
	dcg_codes(';'),{!},
	note_entries(Rest).

note_entry(Entry) -->
	{atom_codes('=',Ex1)},
	match_characters_except(Ex1,Key),
	dcg_codes('='),{!},
	{atom_codes(';"',Ex2)},
	match_characters_except(Ex2,Value),
	{
		atom_codes(KeyAtom,Key),
		catch(number_codes(Number,Value),_,Number=no),
		((Number \= no) ->
			Entry =.. [ KeyAtom, Number ]
			;
			atom_codes(ValueAtom,Value),
			Entry =.. [ KeyAtom,ValueAtom ] % Might need quoting
		)
	}.

left_right(Left,Right) -->
	integer(Left),
	dcg_codes('..'),
	integer(Right).

% special case in E.coli first predicted gene..
left_right(Left,Right) -->
	dcg_codes('<'),
	integer(Left),
	dcg_codes('..'),
	integer(Right).

complement_left_right(Left,Right) -->
	dcg_codes('complement('),
	left_right(Left,Right),
	dcg_codes(')').


dcg_codes(X) -->
	{ atom_codes(X,Y) },
	Y.

cds -->   
	{ atom_codes('CDS',Codes) },
	Codes.


spaces --> [].
spaces --> space, spaces.

match_characters_except(Exceptions) --> 
	match_characters_except(Exceptions,_).

match_characters_except(_Exceptions,[]) --> [].
match_characters_except(Exceptions,[C|Cs]) -->
	match_character_except(Exceptions,C),
	match_characters_except(Exceptions,Cs).

match_character_except(Exceptions,C) -->
	[ C ],
	{ not(member(C, Exceptions)) }.
	
non_end_of_lines([Code|Rest]) --> non_end_of_line(Code), non_end_of_lines(Rest).
non_end_of_lines([Code]) --> non_end_of_line(Code).

non_end_of_line(Code) --> [ Code ], { not(member(Code, [10,13])) }.

end_of_line --> end_of_line(_).
end_of_line(windows)--> [10,13].                        % windows end of line
end_of_line(unix) --> [10].    % unix end of line

space --> [ 9 ]. % tab character
space --> [ 32 ]. % normal space character

integer(Integer) -->
	digits(Digits),
	{
		Digits \= [],
		atom_codes(Atom,Digits),
		atom_integer(Atom,Integer)
	}.
	
digits([]) --> [].
digits([D|Ds]) -->
	digit(D),
	digits(Ds).

digit(D) --> [D], { atom_codes('0123456789',Digits), member(D,Digits) }.


%%%%%%%%%
% Tests

% Match definition line
test_match_def_line :-
	Line = 'DEFINITION  seqnum=1;seqlen=4639675;seqhdr="gi|49175990|ref|NC_000913.2| Escherichia coli str. K-12 substr. MG1655 chromosome, complete genome";version=Prodigal.v2.50;run_type=Single;model="Ab initio";gc_cont=50.79;transl_table=11;uses_sd=1',
	atom_codes(Line,LineCodes),
	append(LineCodes,[10],LineCodes2),
	definition_line(LineCodes2,[]).
	
% Match features line
test_match_features_line :-
	Line = 'FEATURES             Location/Qualifiers',
	atom_codes(Line,LineCodes),
	append(LineCodes,[10],LineCodes2),
	features_line(LineCodes2,[]).
	
test_integer :-
	atom_codes('123',X), integer(I,X,[]), integer(I).
	
test_cds_first_line :-
	Line = 'CDS             <3..98',
	atom_codes(Line,LineCodes),
	cds_first_line(3,98,+,0,LineCodes,[]).
	
test_note_entry :-
	Line = 'ID=1_9',
	atom_codes(Line,LineCodes),
	note_entry(Entry,LineCodes,[]),
	writeq(Entry),nl.

test_note_entries :-
	Line = 'ID=1_9;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;score=75.05;cscore=64.87;sscore=10.18;rscore=2.98;uscore=3.25;tscore=3.95',
	atom_codes(Line,LineCodes),
	note_entries(Extra,LineCodes,[]),
	writeln(Extra).
	
test_cds_second_line :-
	Line = '/note="ID=1_9;partial=00;start_type=ATG;rbs_motif=GGA/GAG/AGG;rbs_spacer=5-10bp;score=75.05;cscore=64.87;sscore=10.18;rscore=2.98;uscore=3.25;tscore=3.95"',
	atom_codes(Line,LineCodes),
	cds_second_line(Extra,LineCodes,[]),
	write(Extra).
	
test_parse_prodigal_file :-
	parse_prodigal_file('output.gbk','predictions.pl').
