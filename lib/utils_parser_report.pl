%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NAME :
%      utils_db.pl -- LOST tool v0.0
%
%FUNCTION :
%        Utils for db building
%
%HISTORY :
%      M.P 14/01/2010: Creation 
%      M.P 14/01/2010: Add of Reader predicates (author: OTL)
%  
%DESCRIPTION : n/a
%          
%REMARK : n/a
%          
%NOTE : n/a
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Command module not avalaible in B-Prolog
%:- module(utils_db,[
%                    readline/2,
%                    read_tab/2,
%                    read_token/2
%                   ]).





%---------
% Parser predicates
%---------


%%%%%%%
% parser_line(++List_Codes,--List_Tokens)
% Description: Translate a list of ASCII code into a list of tokens. Parsing is based on the
% grammar: Tokens ::= Token | Token Ignore_Characters Tokens
% Default: Ignore Caracters = [9,32] (space and tab)
% parser_line(++List_Codes,++Ignore_Character,--List_Tokens)
%%%%%%%


% Default: parser_line/2 

parser_line([],[]) :-
        !.

parser_line(Entry_Codes,Entry_Token) :-
        var(Token),
        parser_line_rec(Entry_Codes,Token-Token,[9,32],Entry_Token).
        


% Definition of the characters to ignore parser_line/3

parser_line([],_Ignored_Chars,[]) :-
        !.

parser_line(Entry_Codes,Ignored_Chars,Entry_Token) :-
        var(Token),
        parser_line_rec(Entry_Codes,Token-Token,Ignored_Chars,Entry_Token).

% End of the line
parser_line_rec([],[]-[],_Ignored_Chars,[]) :- !.

parser_line_rec([],Token-[],_Ignored_Chars,[Token_Res]) :-
        !,
        (is_number(Token) ->
            number_codes(Token_Res,Token)
        ;
            atom_codes(Token_Res,Token)
        ).

% Before Token
parser_line_rec([Code|Rest_Codes],Token-Token,Ignored_Chars,List_Tokens) :-
        member(Code,Ignored_Chars),
        var(Token),
        !,
        parser_line_rec(Rest_Codes,Token-Token,Ignored_Chars,List_Tokens).


% End of a token
parser_line_rec([Code|Rest_Codes],Token-[],Ignored_Chars,[Token_Res|Rest_Tokens]) :-
        member(Code,Ignored_Chars),
        nonvar(Token),
        !,
        (is_number(Token) ->
            number_codes(Token_Res,Token)
        ;
            atom_codes(Token_Res,Token)
        ),
        var(Token1),
        parser_line_rec(Rest_Codes,Token1-Token1,Ignored_Chars,Rest_Tokens).

% Inside a Token
parser_line_rec([Code|Rest_Codes],Token1-Token2,Ignored_Chars,List_Tokens) :-
        Token2 = [Code|Token3],
        parser_line_rec(Rest_Codes,Token1-Token3,Ignored_Chars,List_Tokens).


%%%%%%%
% is_number(++List_Codes)
%%%%%%
% Description: predicate is true iff List_Codes can be parsed by the following grammar
% Numbers :== Number | Number . Rest Numbers | Number Numbers 
% Rest Numbers :== Number | Number Rest Numbers
% Number :== 0|1|2|3|4|5|6|7|8|9 (Ascci 48..57) 
%%%%%%

% Parse of Numbers

is_number([Code]) :-
        47 < Code,
        58 > Code,
        !.
% 46 = .
is_number([Code,46|Rest_Number]) :-
        47 < Code,
        58 > Code,
        !,
        rest_number(Rest_Number).

is_number([Code|Rest]) :-
        47 < Code,
        58 > Code,
        is_number(Rest).


% Parse of rest number
rest_number([Code]) :-
        47 < Code,
        58 > Code,
        !.

rest_number([Code|Rest_Number]) :-
        47 < Code,
        58 > Code,
        rest_number(Rest_Number).


%--------------------
% Reader predicates 
%--------------------
% readline/2, read_tab/2, read_token/2
%---------------------

%%%%%%%%%%%%%%%%%%%
% readline(++Stream,--CodeList)
% Description: reads in a line or a tab or a token with no spaces of data from specified input-stream 
% and represents it as a list of character codes..
%%%%%%%%%%%%%%%%%%%

readline(Stream,CodeList):-
          at_end_of_stream(Stream),
          !,
          CodeList = [-1].

readline(Stream,CodeList):-
          get_code(Stream,Code),
          (member(Code,[10,13]) ->
              CodeList=[]
          ;
              read_rest_of_line(Stream,List),
             CodeList = [Code|List]
         ).

% Recursiv call

read_rest_of_line(Stream,CodeList):-
          at_end_of_stream(Stream),
          !,
          CodeList = [].

read_rest_of_line(Stream,CodeList):-
        get_code(Stream,Code),
	(member(Code,[10]) ->
            CodeList=[]
	;
            read_rest_of_line(Stream,RestOfCodes),
            CodeList=[Code|RestOfCodes]
	).

%%%%%%%%%%%%%%
% read_tab(++Stream,--Codelist)
% Description: n/a
%%%%%%%%%%%%%%

read_tab(File,CodeList):-
	get_code(File,Code),
	Code = -1 -> CodeList = [eof]
	;
	(
	read_rest_of_tab(File,RestOfCodes),
	CodeList=[Code|RestOfCodes]
	).

read_rest_of_tab(File,CodeList):-
	get_code(File,Code),
	Code = -1 -> CodeList = [eof]
	;
	(
	member(Code,[9,10]),!,
	CodeList=[]
	;
	read_rest_of_tab(File,RestOfCodes),
	CodeList=[Code|RestOfCodes]
	).

%%%%%%%%%%%%%%%%%%
% read_token(++Stream,--N_Spaces,--CodeList)
% Description: reads next nonspace-initiated token, terminated by a some whitespace
% counts number of spaces encounterd before first nonspace
%%%%%%%%%%%%%%%%%%%

read_token(File,N_spaces,CodeList):-
	next_nonspace(File,N_spaces,Code),
	(
	Code = -1 -> CodeList = [eof]
	;
	(
	member(Code,[9,10,32,13]),!,
	CodeList=[]
	;
	read_rest_of_token(File,RestOfCodes),
	CodeList=[Code|RestOfCodes]
	)
	).

read_rest_of_token(File,CodeList):-
	
	get_code(File,Code),
	(
	Code = -1 -> CodeList = [eof]
	;
	(
	member(Code,[9,10,32,13]),!,
	CodeList=[]
	;
	read_rest_of_token(File,RestOfCodes),
	CodeList=[Code|RestOfCodes]
	)
	).
	
next_nonspace(File,N,Code):-
	get_code(File,C),
	(
	C = 32 -> next_nonspace(File,M,Code),	N is M+1
	;
	Code = C,	N is 0
	).
		
read_n_spaces(_,0).
read_n_spaces(File,N):-
	get_code(File,32),
	M is N-1,
	read_n_spaces(File,M).	









