%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A simple regular expression engine written in pure Prolog
%
% Author: Christian Theil Have
%
% Basic usage:
% re_compile(+RegexAtom,-Regex):
% Compiles an atom representing a regular expression to a
% prolog list representation.
%
% re_match(+Regex,+Atom,-Matches):
% Tries to match Atom with the regular expression Regex.
%
% The implementation supports basic regular expression
% operators such as ?, +, *, | and bracketed ranges and match groups
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Regular expression compilation
% A simple DCG for parsing regular expressions:
% A parameter is used to build the parsetree
% of the regular expression as an s-expression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We table re_compile/2 to avoid compiling the same regular expression
% twice
:- table re_compile/2.

re_compile(RegexAtom,Regexp) :-
	atom(RegexAtom),
	atom_codes(RegexAtom,RegexCodes),
	re_compile(RegexCodes,Regexp).

re_compile(RegexpCodes,Regexp) :-
	% Does the regular start with start-of-line character '^' ?
	% Else add a little something match anything in the beginning of the string
	atom_codes('.*',MatchAnyCodes),
	RegexpCodes = [StartCode|RestCodes1],
	((StartCode = 94) -> Codes2 = RestCodes1 ;  append(MatchAnyCodes,RegexpCodes,Codes2)),
	% Similarly, does the regular end with end-of-line character '$' ?
	% Else add a little something match anything in the end of the string
	reverse(Codes2,RevCodes2),
	RevCodes2 = [EndCode|RevRestCodes2],
	((EndCode = 36) -> reverse(RevRestCodes2,FinalCodes) ; append(Codes2,MatchAnyCodes,FinalCodes)),
	match_groups(Regexp,FinalCodes,[]).

control_character(C) :-
	atom_codes('()|?*+[]\\.$^',ControlCharacters),
	member(C,ControlCharacters).

non_control_character(C) :-
	not(control_character(C)).

match_groups([R]) --> match_group(R).
match_groups([R1|R2]) --> match_group(R1), match_groups(R2).

match_group(grouped(R)) --> lparen, regexp(R), rparen.
match_group(ungrouped(R)) --> regexp(R).

regexp(R) --> alternation(R).
regexp(R) --> repetition(R).
regexp(R) --> concatenation(R).


alternation([or,R1,R2]) --> alternation_primitive(R1), or, alternation(R2).
alternation([or,R1,R2]) --> alternation_primitive(R1), or, alternation_primitive(R2).

alternation_primitive(R) --> repetition(R).
alternation_primitive(R) --> concatenation(R).

repetition([star, R]) --> repetition_primitive(R), star.
repetition([concat, R, [star, R]]) --> repetition_primitive(R), plus.
repetition([or,R,[]]) --> repetition_primitive(R), question_mark.

repetition_primitive([concat, R, []]) --> symbol(R). % Note, single symbols are concatenated with empty list
repetition_primitive(R) --> bracket_expression(R).
repetition_primitive(R) --> lparen, concatenation(R), rparen.
repetition_primitive(R) --> lparen, alternation(R), rparen.

concatenation([concat,R1,R2]) --> concatenation_primitive(R1), concatenation(R2).
concatenation([concat,R,[]]) --> concatenation_primitive(R).

concatenation_primitive(R) --> symbol(R).
concatenation_primitive(R) --> repetition(R).
concatenation_primitive(R) --> lparen, alternation(R), rparen.
concatenation_primitive(R) --> bracket_expression(R).

% A ranges group is something like [Xa-zA-F].
bracket_expression(R) -->
	[91], % '['
	bracket_expression_elements(R),
	[93]. % ']'

bracket_expression_elements(R) -->
	bracket_expr_elem(R).

bracket_expression_elements([or,R1,R2]) -->
	bracket_expr_elem(R1),
	bracket_expression_elements(R2).

bracket_expr_elem(R) -->
	single_range(R).

bracket_expr_elem(R) -->
	alphanumeric_symbol(_,R).

% Base case for single range - really just one symbol
single_range(S) -->
	alphanumeric_symbol(T,S),
	[45], % Hyphen
	alphanumeric_symbol(T,S).

% Match a single range e.g. "a-z" : Note that single_range is called recursively,
% to build an "or" sequence.
single_range([or,S1,RangeRest]) -->
	alphanumeric_symbol(T,S1),
	[45], % Hyphen
	alphanumeric_symbol(T,S2),
	{
	 S1 < S2, % Make sure the range is valid
	 S1Next is S1 + 1,
	 single_range(RangeRest,[S1Next,45,S2],[]) % Call DCG predicate recursively
	}.

or --> [124]. % '|'
question_mark --> [63]. % '?'
star --> [42]. % '*'
plus --> [43]. % '+'
lparen --> [40]. % '('
rparen --> [41]. % ')'

symbol(S) --> escaped_control_character(S).
symbol(S) --> simple_symbol(S).
symbol(S) --> any_symbol(S).

escaped_control_character(S) -->
	[92, S], % 92 is backslash
	{ control_character(S) }.

simple_symbol(S) --> [S], { non_control_character(S) }.

any_symbol(any) --> [46]. % Dot '.'

alphanumeric_symbol(Type,S) -->
	digit(Type,S).

alphanumeric_symbol(Type,S) -->
	character(Type,S).

digit(digit,S) -->
	[ S ],
	{ S >= 48, S =< 67 }.

% Lower case characters
character(lower_case_char,S) -->
	[ S ],
	{ S >= 97, S =< 122 }.

% Upper case characters
character(upper_case_char,S) -->
	[ S ],
	{ S >= 65, S =< 90 }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Regular expression matching
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% re_match for input as atom
re_match(Regex,String,MatchesAtoms) :-
	atom(String),
	atom_codes(String,StringCodes),
	re_match(Regex,Matches,StringCodes,[]),
	list_atom_codes(Matches,MatchesAtoms).

% re_match for input as list of codes
re_match(Regex,StringCodes,Matches) :-
	is_list(StringCodes),
	re_match(Regex,Matches,StringCodes,[]).

list_atom_codes([],[]).
list_atom_codes([CodeList|CodeListRest],[Atom|AtomsRest]) :-
	atom_codes(Atom,CodeList),
	list_atom_codes(CodeListRest,AtomsRest).

re_match([],[]) --> [].

re_match([grouped(R)|Rest],[Match|MatchRest]) -->
	re_match(R,MatchNested),
	{ flatten(MatchNested,Match) },
	re_match(Rest,MatchRest).

re_match([ungrouped(R)|Rest],MatchRest) -->
	re_match(R,_),
	re_match(Rest,MatchRest).
	 
re_match([group,Left],[group(Match)]) -->
	re_match(Left,Match).

re_match([or, Left, _Right],Match) -->
	re_match(Left,Match).

re_match([or, _Left, Right],Match) -->
	re_match(Right,Match).

re_match([concat,Left,[]],Match) -->
	re_match(Left,Match).

re_match([concat,Left,[R1|RightRest]],[Match1|MatchRest]) -->
	re_match(Left,Match1),
	re_match([R1|RightRest],MatchRest).

% Match repetition
re_match([star,Left],[Match|MatchRest]) -->
	re_match(Left,Match),
	re_match([star,Left],MatchRest).

re_match([star,_],[]) --> [].

re_match(SymbolCode,[SymbolCode]) -->
	{ integer(SymbolCode) },
	[ SymbolCode ].

re_match(any,[SymbolCode]) -->
	[ SymbolCode ].
