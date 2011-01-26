%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Misc. small utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List manipulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% atom_concat_list(++List, --Atom)
% Concatenates all atoms in List in the order they appear
% to form a concatenation, Atom
atom_concat_list([Atom],Atom).
atom_concat_list([Elem1,Elem2|Rest], CompositeAtom) :-
	atom_concat(Elem1,Elem2,Elem3),
	atom_concat_list([Elem3|Rest], CompositeAtom).

% Assumes each atom to be exactly one character
atom_list_code_list([],[]).
atom_list_code_list([Atom|AtomsRest],[Code|CodesRest]) :-
	atom_codes(Atom, [Code]),
	atom_list_code_list(AtomsRest,CodesRest).

inlists_nth0([], _, []).
inlists_nth0([List|RestLists], N, [Elem|RestElems]) :-
	nth0(N,List,Elem),
	inlists_nth0(RestLists,RestElems).

% Append variant which permit atom elements as first/second argument
flexible_append(A,B,[A,B]) :- atom(A), atom(B).
flexible_append(A,B,[A|B]) :- atom(A).
flexible_append(A,B,C) :- atom(B), append(A,[B],C).

% Merge list of lists into one long list, e.g.
% flatten_once([[a,b],[c,d],[e,f]],E) => E = [a, b, c, d, e, f].
flatten_once([],[]).
flatten_once([[]|Rest],OutRest) :-
        !,
        flatten_once(Rest,OutRest). 
flatten_once([A|Rest],[A|OutRest]) :-
	atom(A),
        !,
	flatten_once(Rest,OutRest).
flatten_once([E1|Rest],Out) :-
	is_list(E1),
	append(E1,FlatRest,Out),
        !,
	flatten_once(Rest,FlatRest).



map(F,InList,OutList) :-
	F =.. [ _ ],
	map_unary(F,InList,OutList).

map(F,InList,OutList) :-
	F =.. [ _ | ArgList ],
	ArgList \= [],
	map_with_arglist(F, InList, OutList).

% map applies to rule F(-,+) to each element of list
map_unary(_,[],[]).
map_unary(F, [L|Lists], [Out|OutRest]) :-
	Goal =.. [ F, L, Out], 
	call(Goal),
	map_unary(F,Lists,OutRest).


% Advanced map utility
map_with_arglist(_,[],[]).
map_with_arglist(F, [L|Lists], [Out|OutRest]) :-
	F =.. FList1,
	replace(input,L,FList1,FList2),
	replace(output,Out,FList2,FList3),
	NewF =.. FList3,
	call(NewF),
	map_with_arglist(F,Lists,OutRest).

list_head(List,Head) :- List = [ Head | _ ].
list_tail(List,Tail) :- List = [ _ | Tail ].

rotate_list_vector(ListOfEmptyLists,[]) :-
       forall(member(Elem, ListOfEmptyLists),Elem == []).

% e.g. rotate_list_vector([[1,1,1],[2,2,2],[3,3,3]],[[1,2,3],[1,2,3],[1,2,3]]).
rotate_list_vector(ListOfLists, [HeadsList|RotateTailsList]) :-
	map(list_head,ListOfLists,HeadsList),
	map(list_tail,ListOfLists,TailsList),
	rotate_list_vector(TailsList,RotateTailsList).


% replace(++Symbol,++Replacement,++Inlist,--Outlist)
% Outlist is a replicate of Inlist which has all instances
% of Symbol replaced with Replacement 
replace(_,_,[],[]).
replace(Symbol, Replacement, [Symbol|InListRest], [Replacement|OutListRest]) :-
	replace(Symbol,Replacement, InListRest,OutListRest).
replace(Symbol, Replacement, [Elem|InListRest], [Elem|OutListRest]) :-
	Symbol \= Elem,
	replace(Symbol,Replacement,InListRest,OutListRest).

% match_tail(++InputList,--HeadOfInputList,++TailOfInputList)
% true if InputList ends with TailOfInputList
match_tail(Match,[],Match).
match_tail([H|T],[H|Hr],Match) :- match_tail(T,Hr,Match).



% not_member(++Elt,++List)
% true is Elt is not a member of List
% Note: well-behaved for Elt and List ground

not_member(Elt,List) :-
        member(Elt,List),
        !,
        false.

not_member(_Elt,_List).

% Intersperse a list with a particular separator
% e.g. intersperse(',', ['a','b','c'], ['a',',','b,',','c'])
intersperse(_,[],[]).
intersperse(_,[One],[One]).
intersperse(Separator,[One,Two|Rest],[One,Separator|NewRest]) :-
        intersperse(Separator,[Two|Rest],NewRest).

% take(+N,+ListIn,-ListOut). 
% true if ListOut is the first N elements of ListIn
take(0, _, []).
take(N, [E|R1],[E|R2]) :-
        N1 is N - 1,
        !,
        take(N1,R1,R2).


% split_list(+N,+List,-FirstPart,-LastPart)
% FirstPart is the first N elements of List
% LastPart is the remaining
split_list(_, [], [], []).
split_list(N, [E|List], [E|ListHead], ListTail) :-
        N > 0,
        N1 is N - 1,
        !,
        split_list(N1,List,ListHead,ListTail).
split_list(N, [E|List], [], [E|ListTail]) :-
        N =< 0,
        N1 is N - 1,
        !,
        split_list(N1,List,[],ListTail).

%% zip(+List1,+List2,ZippedList)
% Combines two lists into one
zip([],_,[]).
zip(_,[],[]).
zip([E1|L1],[E2|L2],[[E1,E2]|ZipRest]) :-
        zip(L1,L2,ZipRest).
       

% FIXME: A predicate like this allready exist in b-prolog 
% and is called eliminate_duplicate/2
%
% remove_dups(++List,--Pruned)
% Remove duplicate values of List
% Note: sort is used because the precidate already to do that

remove_dups(List,Pruned) :-
        sort(List,Pruned).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Term manipulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% terms_has_rule_with_head(++Terms,++Functor,++Arity)
% True if the list Terms has a rule with a given Functor and Arity
terms_has_rule_with_head(Terms,Functor,Arity) :-
	member(Rule, Terms),
	Rule =.. [ (:-), Head, _ ],
	functor(Head, Functor, Arity).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Arithmetics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Absolute value
abs(A,A) :-
	A >= 0.
abs(A,B) :-
	A < 0,
	B is A * -1.

% Find minimum element
min(A,A,A).
min(A,B,A) :- A < B.
min(A,B,B) :- B < A.

% Find maximum of two elements
max(A,A,A).
max(A,B,A) :- B < A.
max(A,B,B) :- A < B.

% Find maximum of list
list_max([E],E).
list_max([E|R],Max) :-
	list_max(R,MR),
	((E > MR) -> Max = E ; Max = MR).

% Find minimum of list
list_min([E],E).
list_min([E|R],Min) :-
	list_min(R,MR),
	((E < MR) -> Min = E ; Min = MR).


% atom_integer(??Atom,??Integer)
% Converts and atom representing an integer number to an
% Integer usuable in arithmetic operationes and vice versa

atom2integer(Atom,Integer) :-
        atom_integer(Atom,Integer).

atom_integer(Atom,Integer) :-
        ground(Atom),
        atom_chars(Atom, Chars),
        number_chars(Integer, Chars).

atom_integer(Atom,Integer) :-
        ground(Integer),
        number_chars(Integer,Chars),
        atom_chars(Atom,Chars).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Error checking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check_or_fail(Goal,Error):
% call Goal and throw and exception with error if Goal fails.
% Also, never backtrack beyond this point.
check_or_fail(Check,_Error) :-
	call(Check),
	!.

check_or_fail(_File,Error) :-
	throw(Error).

% check_or_warn(Goal,Error):
% call Goal and warn with error if Goal fails.
% Also, never backtrack beyond this point.
check_or_warn(Check,_Error) :-
	call(Check),
	!.

check_or_warn(_File,Error) :-
        write('!!! '),
	writeq(warning(Error)),
        nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File system
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Separate out the directory part of a filename
dirname(Filename,DirPartAtom) :-
	% everything before last '/'=47 is dirname:
	atom_codes(Filename, CharCodes),
	append(DirPart, FilePart, CharCodes),
	append(_,[47],DirPart), % DirPart should end with a '/'
	not(member(47,FilePart)), 
	atom_codes(DirPartAtom,DirPart).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ranges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% overlaps(++Start1,++End1,++Start2,++End2)
% Determine if two ranges overlap
overlaps(Start1,End1, Start2,_) :-
        Start1 =< Start2,
        End1 >= Start2.
overlaps(Start1,_, Start2,End2) :-
        Start2 =< Start1,
        End2 >= Start1.

% Sums the number of positions in a list of ranges
sum_range_list([],0).
sum_range_list([[From,To]|Rest],Sum) :-
	LocalSum is To - From + 1,
	sum_range_list(Rest, RestSum),
	Sum is LocalSum + RestSum.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conversion between upper case and lower case
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

upper_lower(Upper,Lower) :-
	ground(Upper),
	is_upper_case_alphanumeric(Upper),
	!,
	Lower is Upper + 32.

upper_lower(Upper,Lower) :-
	ground(Lower),
	is_lower_case_alphanumeric(Lower),
	!,
	Upper is Lower - 32.

% For everything non-alphanumeric
upper_lower(UpperLower,UpperLower) :-
	ground(UpperLower),
	not(is_upper_case_alphanumeric(UpperLower)),
	not(is_lower_case_alphanumeric(UpperLower)).

is_upper_case_alphanumeric(Code) :-
	Code >= 65,
	Code =< 90.

is_lower_case_alphanumeric(Code) :-
	Code >= 97,
	Code =< 122.
