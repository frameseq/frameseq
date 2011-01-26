/** <module> Module of Input/Output manipulation
%  NAME :
%      io.pl
%
% VERSION :
%     0
%
% AUTHORS: Lost Members
%
% FUNCTION:
%      Manipulation of files: loading information from file, saving file from information
% 
% HISTORIC:
%  09/03: creation of file                                   MP
%  26/04: modification of the load_annotation_from_file
%         predicate name options modfied. Old version kept   MP
% REMARKS: any problem, contact {cth,otl,petit}@(without advertissement)ruc.dk
%
% MODULS USED: misc_utils.pl
%
% NOTE TO THE USER : 
*/

:- lost_include_api(utils_parser_report).
:- lost_include_api(misc_utils).


%---------------
% get data or annotation from a file
%----------------


%% get_data_from_file(+File,+Options,-Data)
%
% Description: given of file composed of prolog facts,
% this predicate generates a list of data given some options
% By default, data predicate is in the form:
% Functor(Key,LeftPosition,RightPosition,Data,...)
% Type of Data is a list
%
% Options: - data_position(Pos) specified in which Pos Data is
%          - left_position(Left) specified in which Pos Leftposition is
%          - right_position(Righ) specified in which Pos Rightposition is
%          - left_position(none) = no left position in the term
%          - right_position(none) = no right position in the term
%          - range(Min,Max): extract a range of data
%          - ranges(List_Ranges): extract a list of data given a list of Range
%

                                

get_data_from_file(File,Options,Data) :-
        terms_from_file(File,Terms),  % An other way could be to consult the file (other option for later)
        % Technically not necessary since they will be sorted if this
	% interface is used
        sort('=<',Terms,SortedTerms),
        get_data_from_terms(SortedTerms,Options,Data).



%%%%%%%
% get_data_from_terms(++Terms,++Options,--Data)
%%%%%%%


get_data_from_terms([],_,[]) :-
        !.

% Complete computation of data
get_data_from_terms([Term|Rest_Terms],Options,Data) :-
        not_member(range(_,_),Options),
        not_member(ranges(_),Options),
        !,
        Term =.. [_Functor|Parameters],
        (member(data_position(Pos),Options) ->
            nth1(Pos,Parameters,Sequence_Data)
        ;
            nth1(4,Parameters,Sequence_Data)  % Default position
        ),
        get_data_from_terms(Rest_Terms,Options,Rest_Data),
        append(Sequence_Data,Rest_Data,Data).


% Range Management
get_data_from_terms(Terms,Options,Data) :-
        member(range(Min,Max),Options),
        !,
        Sequence_Data = [],
        Ranges = [[Min,Max]],
        Current_Position = 1,
        Current_Data = [],
        %Term =.. [_Functor|Parameters],
        (member(data_position(Pos),Options) ->
            true
        ;
            Pos = 4
        ),
        range_info_position(Options,Range_Info_Position),
        (Range_Info_Position = 'none' ->
            get_data_from_terms_rec(Sequence_Data,Ranges,Terms,Current_Position,Current_Data,Pos,Data) % Could be dangerous called with one parameter removed Range_Info_Position
        ;
            get_data_from_terms_rec(Sequence_Data,Ranges,Terms,Current_Position,Current_Data,Pos,Range_Info_Position,Data)
        ).



% Ranges Management
get_data_from_terms(Terms,Options,Data) :-
        member(ranges(Ranges),Options),
        Sequence_Data = [],
        Current_Position = 1,
        Current_Data = [],
        (member(data_position(Pos),Options) ->
            true
        ;
            Pos = 4
        ),
        range_info_position(Options,Range_Info_Position),
        (Range_Info_Position = 'none' ->
            get_data_from_terms_rec(Sequence_Data,Ranges,Terms,Current_Position,Current_Data,Pos,Data) % Could be dangerous called with one parameter removed Range_Info_Position
        ;
            get_data_from_terms_rec(Sequence_Data,Ranges,Terms,Current_Position,Current_Data,Pos,Range_Info_Position,Data)
        ).




%%%%
% get_data_from_terms_rec(++Sequence_Data,++Ranges,++Terms,++Current_Position,++Current_Data,++Pos,++Range_Info_Position,--Data)
% Description: this predicated built the wanted data given all the parameters
%%%%

% Termination case: Sequence Data = [] and Terms = []
get_data_from_terms_rec([],_Ranges,[],_Current_Position,Current_Data,_Pos,_Range_Info_Position,[]) :-
        empty_lists(Current_Data),
        !.


% Termination case: Ranges = empty
get_data_from_terms_rec(_Sequence_Data,[],_Terms,_Current_Position,Current_Data,_Pos,_Range_Info_Position,[]) :-
        empty_lists(Current_Data),
        !.

% Case: Sequence data empty => we look for a new one 
get_data_from_terms_rec([],[[Min,Max]|Ranges],[Term|Rest_Terms],Current_Position,Current_Data,Pos,(_Left,Right),Data) :-
        !,
        Term =.. [_Functor|Parameters],
        nth1(Right,Parameters,RightPos),
        (RightPos < Min ->      % Test to skip the term
            Current_Position2 is RightPos+1,
            get_data_from_terms_rec([],[[Min,Max]|Ranges],Rest_Terms,Current_Position2,Current_Data,Pos,(_Left,Right),Data)
        ;
            Current_Position = Current_Position2,
            nth1(Pos,Parameters,Sequence_Data),
            get_data_from_terms_rec(Sequence_Data,[[Min,Max]|Ranges],Rest_Terms,Current_Position2,Current_Data,Pos,(_Left,Right),Data)
        ).



% Case: Current Position < Minimal bound of the first Range
get_data_from_terms_rec([_Val|Rest_Sequence],[[Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Range_Info_Position,Data) :-
       Current_Position < Min,
       !,
       Current_Position1 is Current_Position+1,
       get_data_from_terms_rec(Rest_Sequence,[[Min,Max]|Ranges],Terms,Current_Position1,Current_Data,Pos,Range_Info_Position,Data).



% Case: Minimal bound = Current_Position => Start Data building.
% Inv: Current_Data is empty as the first Range of Ranges has Min as minimal bound.
get_data_from_terms_rec([Val|Rest_Sequence],[[Min,Max]|Ranges],Terms,Current_Position,[],Pos,Range_Info_Position,[[Val|Rest_Range_Data]|Rest_Data]) :-
       Current_Position = Min,
       !,
       check_ranges_and_update_data(Val,Ranges,Current_Position,Rest_Range_Data,[],Current_Data_Update,Rest_Data,Rest_Data_Update),
       Current_Position1 is Current_Position+1,
       get_data_from_terms_rec(Rest_Sequence,[[Min,Max]|Ranges],Terms,Current_Position1,Current_Data_Update,Pos,Range_Info_Position,Rest_Data_Update).



% Case: Minimal bound =< Current_Position =< Maximal Bound: update Current Data range and look for overlap
get_data_from_terms_rec([Val|Rest_Sequence],[[Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Range_Info_Position,Data) :-
       Min < Current_Position,
       Current_Position < Max,
       !,
       Current_Position1 is Current_Position+1,
       Current_Data = [T|Rest_Current_Data],
       T = [Val|T_Rest],
       check_ranges_and_update_data(Val,Ranges,Current_Position,T_Rest,Rest_Current_Data,Current_Data_Update,Data,Data_Update),
       get_data_from_terms_rec(Rest_Sequence,[[Min,Max]|Ranges],Terms,Current_Position1,Current_Data_Update,Pos,Range_Info_Position,Data_Update).


% Case: Maximal bound = Current_Position
% End of Range data buiding
get_data_from_terms_rec([Val|Rest_Sequence],[[_Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Range_Info_Position,Data) :-
       Current_Position = Max,
       !,
       Current_Position1 is Current_Position+1,
       Current_Data = [T|Rest_Current_Data],
       T = [Val],
       check_ranges_and_update_data(Val,Ranges,Current_Position,[],Rest_Current_Data,Current_Data_Update,Data,Data_Update),
       get_data_from_terms_rec(Rest_Sequence,Ranges,Terms,Current_Position1,Current_Data_Update,Pos,Range_Info_Position,Data_Update).

% Case: Data Collection finished but Range not yet removed (overlap inside between Range1 Range2 = Min1 < Min2 but Max2 =< Max1)


get_data_from_terms_rec(Sequence_Data,[[_Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Range_Info_Position,Data) :-
       Current_Position > Max,
       !,
       Current_Data = [[]|Rest_Current_Data],
       get_data_from_terms_rec(Sequence_Data,Ranges,Terms,Current_Position,Rest_Current_Data,Pos,Range_Info_Position,Data).




%%%%
% get_data_from_terms_rec(++Sequence_Data,++Ranges,++Terms,++Current_Position,++Current_Data,++Pos,--Data)
% Description: same predicate than below but without jump thanks to left_position or right_position
%%%%


% Termination case: Sequence Data = [] and Terms = []
get_data_from_terms_rec([],_Ranges,[],_Current_Position,Current_Data,_Pos,[]) :-
        empty_lists(Current_Data),
        !.


% Termination case: Ranges = empty
get_data_from_terms_rec(_Sequence_Data,[],_Terms,_Current_Position,Current_Data,_Pos,[]) :-
        empty_lists(Current_Data),
        !.

% Case: Sequence data empty => we look for a new one 
get_data_from_terms_rec([],[[Min,Max]|Ranges],[Term|Rest_Terms],Current_Position,Current_Data,Pos,Data) :-
        !,
        Term =.. [_Functor|Parameters],
        nth1(Pos,Parameters,Sequence_Data),
        get_data_from_terms_rec(Sequence_Data,[[Min,Max]|Ranges],Rest_Terms,Current_Position,Current_Data,Pos,Data).



% Case: Current Position < Minimal bound of the first Range
get_data_from_terms_rec([_Val|Rest_Sequence],[[Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Data) :-
       Current_Position < Min,
       !,
       Current_Position1 is Current_Position+1,
       get_data_from_terms_rec(Rest_Sequence,[[Min,Max]|Ranges],Terms,Current_Position1,Current_Data,Pos,Data).



% Case: Minimal bound = Current_Position => Start Data building.
% Inv: Current_Data is empty as the first Range of Ranges has Min as minimal bound.
get_data_from_terms_rec([Val|Rest_Sequence],[[Min,Max]|Ranges],Terms,Current_Position,[],Pos,[[Val|Rest_Range_Data]|Rest_Data]) :-
       Current_Position = Min,
       !,
       Current_Data = [Rest_Range_Data],
       Current_Position1 is Current_Position+1,
       get_data_from_terms_rec(Rest_Sequence,[[Min,Max]|Ranges],Terms,Current_Position1,Current_Data,Pos,Rest_Data).



% Case: Minimal bound =< Current_Position =< Maximal Bound: update Current Data range and look for overlap
get_data_from_terms_rec([Val|Rest_Sequence],[[Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Data) :-
       Min < Current_Position,
       Current_Position < Max,
       !,
       Current_Position1 is Current_Position+1,
       Current_Data = [T|Rest_Current_Data],
       T = [Val|T_Rest],
       check_ranges_and_update_data(Val,Ranges,Current_Position,T_Rest,Rest_Current_Data,Current_Data_Update,Data,Data_Update),
       get_data_from_terms_rec(Rest_Sequence,[[Min,Max]|Ranges],Terms,Current_Position1,Current_Data_Update,Pos,Data_Update).


% Case: Maximal bound = Current_Position
% End of Range data buiding
get_data_from_terms_rec([Val|Rest_Sequence],[[_Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Data) :-
       Current_Position = Max,
       !,
       Current_Position1 is Current_Position+1,
       Current_Data = [T|Rest_Current_Data],
       T = [Val],
       check_ranges_and_update_data(Val,Ranges,Current_Position,[],Rest_Current_Data,Current_Data_Update,Data,Data_Update),
       get_data_from_terms_rec(Rest_Sequence,Ranges,Terms,Current_Position1,Current_Data_Update,Pos,Data_Update).

% Case: Data Collection finished but Range not yet removed (overlap inside between Range1 Range2 = Min1 < Min2 but Max2 =< Max1)


get_data_from_terms_rec(Sequence_Data,[[_Min,Max]|Ranges],Terms,Current_Position,Current_Data,Pos,Data) :-
       Current_Position > Max,
       !,
       Current_Data = [[]|Rest_Current_Data],
       get_data_from_terms_rec(Sequence_Data,Ranges,Terms,Current_Position,Rest_Current_Data,Pos,Data).



%%%
% utils get_data_from_terms_rec
%%%

empty_lists([]) :-
        !.

empty_lists([A|Rest]) :-
        A = [],
        empty_lists(Rest).



% range_info_position(++Options,--Range_info_Position)

range_info_position(Options,Range_Position) :-
        member(left_position(Left),Options),
        Left = 'none',
        !,
        Range_Position = 'none'.

range_info_position(Options,Range_Position) :-
        member(right_position(Right),Options),
        Right = 'none',
        !,
        Range_Position = 'none'.


range_info_position(Options,Range_Position) :-
        member(left_position(Left),Options),
        member(right_position(Right),Options),
        Left \= 'none',
        Right \= 'none',
        !,
        Range_Position = (Left,Right).


range_info_position(Options,Range_Position) :-
        not_member(left_position(_Left),Options),
        not_member(right_position(_Right),Options),
        !,
        Range_Position = (2,3).

range_info_position(Options,Range_Position) :-
        not_member(left_position(_Left),Options),
        member(right_position(Right),Options),
        Right \= 'none',
        !,
        Range_Position = (2,Right).

range_info_position(Options,Range_Position) :-
        member(left_position(Left),Options),
        not_member(right_position(_Right),Options),
        Left \= 'none',
        !,
        Range_Position = (Left,3).



% check_ranges_and_update_data(++Val,++Ranges,++Current_Position,++T_Rest,++Current_Data,--Current_Data_Update,++Data,--Data_Update)

% Case: no more range, data range under construction
check_ranges_and_update_data(_Val,[],_Current_Position,T_Rest,_Current_Data,Current_Data_Update,Data,Data) :-
        var(T_Rest),
        !,
        Current_Data_Update = [T_Rest].

% Case: no more range, data range under construction finished
check_ranges_and_update_data(_Val,[],_Current_Position,[],_Current_Data,Current_Data_Update,Data,Data) :-
        !,
        Current_Data_Update = [].

% Case: Ranges avalaible, Data range under construction
check_ranges_and_update_data(Val,Ranges,Current_Position,T_Rest,Current_Data,[T_Rest|Current_Data_Update],Data,Data_Update) :-
        var(T_Rest),
        !,
        check_ranges_and_update_data_rec(Val,Ranges,Current_Position,Current_Data,Current_Data_Update,Data,Data_Update).

% Case: Ranges avalaible, Data range finished
check_ranges_and_update_data(Val,Ranges,Current_Position,[],Current_Data,Current_Data_Update,Data,Data_Update) :-
        !,
        check_ranges_and_update_data_rec(Val,Ranges,Current_Position,Current_Data,Current_Data_Update,Data,Data_Update).


% Recurisve call
% No more Range = end iteration
check_ranges_and_update_data_rec(_Val,[],_Current_Position,[],[],Data,Data).



% Case: Current Data empty + no new start of data
check_ranges_and_update_data_rec(_Val,[[Min,_Max]|_Rest_Ranges],Current_Position,[],[],Data,Data) :-
        Current_Position < Min,
        !.
        

% Case: Current Data empty + new start of data range
check_ranges_and_update_data_rec(Val,[[Min,_Max]|Rest_Ranges],Current_Position,[],[Rest_Range|Rest_Data_Update],[[Val|Rest_Range]|Rest_Data],Data_Update) :-
        Current_Position = Min,
        !,
        check_ranges_and_update_data_rec(Val,Rest_Ranges,Current_Position,[],Rest_Data_Update,Rest_Data,Data_Update).
        

% Case: Current Data not empty + Current Position in Min Max => Update
check_ranges_and_update_data_rec(Val,[[Min,Max]|Rest_Ranges],Current_Position,[Range_Data|Rest_Current_Data],Current_Data_Update,Data,Data_Update) :-
        Min < Current_Position,
        Current_Position =< Max,
        !,
        Range_Data = [Val|Range_Data2],
        Current_Data_Update = [Range_Data2|Current_Data_Update2],
        check_ranges_and_update_data_rec(Val,Rest_Ranges,Current_Position,Rest_Current_Data,Current_Data_Update2,Data,Data_Update).
        

% Case: overlap, Range data terminated and look for an other overlap
check_ranges_and_update_data_rec(Val,[[_Min,Max]|Rest_Ranges],Current_Position,[Range_Data|Rest_Current_Data],Current_Data_Update,Data,Data_Update) :-
        Current_Position > Max,
        !,
        Current_Data_Update = [Range_Data|Current_Data_Update2],
        check_ranges_and_update_data_rec(Val,Rest_Ranges,Current_Position,Rest_Current_Data,Current_Data_Update2,Data,Data_Update).



%% load_annotation_from_file(+Type_Info,+Options,+File,-Annotation)
%
% Description: given some Options, generate an Annotation from a set of terms contained into File
%
%
% Type_Info: sequence
% Terms in File are composed of List of data.
% Annotation is a list
% Options available: Options = [data_position(Position),
%                               all_lists,range(Min,Max),
%                               range(Range)
%                               consult]
% all_lists does not support a range option
%
% Type: db
% Terms in File are composed of Range that delimites a specific region.
% Options available: Options = [in_db(Letter),not_in_db(Letter),
%                               range_position(Position),range(Min,Max)]
% Note: assumption is done on the format of the database. Information is extracted from a list
% of terms that have a parameter Range to describe a specific region of the genome.
% By defaut, annotation of the specific region is 1 and 0 when the region is not specific.
%



% Type sequence
%%%%%%%%%
load_annotation_from_file(sequence,Options,File,Annotation) :-
        (\+ member(consult)),
        !,
        terms_from_file(File,Terms),
        % Technically not necessary since they will be sorted if this
	% interface is used
	sort('=<',Terms,SortedTerms), 
        sequence_terms_to_annotations(Options,SortedTerms,Annotation).





% Type db
%%%%%%%
load_annotation_from_file(db,Options,File,Annotation) :-
        member(term(Terms),Options),
        !,
        (var(Terms) ->
            terms_from_file(File,Terms),
            sort('=<',Terms,SortedTerms)
        ;        
            SortedTerms = Terms
        ),
                                % Technically not necessary since they will be sorted if this
                                % interface is used
        db_terms_to_annotations(Options,SortedTerms,Annotation).

% TO FI
load_annotation_from_file(db,Options,File,Annotation) :-
        terms_from_file(File,Terms),
        sort('=<',Terms,SortedTerms),
        % Technically not necessary since they will be sorted if this
	% interface is used

        db_terms_to_annotations(Options,SortedTerms,Annotation).


% Utils for load_annotation_from_file(sequence,....)

%%%
% sequence_terms_annotations(++Options,++List_Terms,--Annotation)
%%%
% Default: Functor(1,Data),Functor(2,Data) ....
sequence_terms_to_annotations([],[],[]) :-
        !.


sequence_terms_to_annotations([],[Data|Rest_Data],Annotation) :-
        !,
        sequence_terms_to_annotations([],Rest_Data,Rest_Annotation),
        Data =.. [_Functor,_,Sequence_Data|_], 
        append(Sequence_Data,Rest_Annotation,Annotation).


% Options Range and Data Position
sequence_terms_to_annotations(_Options,[],[]) :-
        !.

% Options all_lists (Note: note Range option not support)
% Options Data Position
sequence_terms_to_annotations(Options,[Data|Data_Terms],[Sequence_Data|Annotation]) :-
        member(all_lists,Options),
        member(data_position(Data_Position),Options),
        !,
        Data =.. [_Functor|Rest_Data],
        nth1(Data_Position,Rest_Data,Sequence_Data),
        sequence_terms_to_annotations(Options,Data_Terms,Annotation).

% Options all_lists (Note: note Range option not support)
% Options Data Position
sequence_terms_to_annotations(Options,[Data|Data_Terms],[Sequence_Data|Annotation]) :-
        member(all_lists,Options),
        !,
        Data =.. [_Functor,_,Sequence_Data|_Rest_Data],
        sequence_terms_to_annotations(Options,Data_Terms,Annotation).



% Options Range and Data Position
sequence_terms_to_annotations(Options,[Data|Data_Terms],Annotation) :-
        member(range(Min,Max),Options),
        member(data_position(Data_Position),Options),
        !,
        Data =.. [_Functor|Rest_Data],
        nth1(Data_Position,Rest_Data,Sequence_Data),
        sequence_terms_to_annotations_rec(Sequence_Data,range(Min,Max),1,Data_Position,Data_Terms,Annotation).


% Options Range only
sequence_terms_to_annotations(Options,[Data|Data_Terms],Annotation) :-
        member(range(Min,Max),Options),
        !,
        Data =.. [_Functor,_,Sequence_Data|_],  % Default functor(Num,Sequence_Data,...)
        sequence_terms_to_annotations_rec(Sequence_Data,range(Min,Max),1,2,Data_Terms,Annotation).



% Options Data Position only
sequence_terms_to_annotations(Options,[Data|Data_Terms],Annotation) :-
        member(data_position(Data_Position),Options),
        !,
        Data =.. [_Functor|Rest_Data],
        nth1(Data_Position,Rest_Data,Sequence_Data),   
        sequence_terms_to_annotations(Options,Data_Terms,Rest_Annotation),
        append(Sequence_Data,Rest_Annotation,Annotation).


% Data_Terms empty = end of the annotation generation
sequence_terms_to_annotations_rec([],range(_Min,_Max),_Position,_Data_Position,[],[]) :-
        !.


% Recursive call used when range option is asked

% End of the annotation
sequence_terms_to_annotations_rec(_Sequence_Data,range(_Min,Max),Position,_Data_Position,_Data_Terms,[]) :-
        Position > Max,
        !.

% Sequence_Data Empty
sequence_terms_to_annotations_rec([],range(Min,Max),Position,Data_Position,[Data|Data_Terms],Annotation) :-
      Position =< Max,
      !,
      Data =.. [_Functor|Rest_Data], 
      nth1(Data_Position,Rest_Data,Sequence_Data),
      sequence_terms_to_annotations_rec(Sequence_Data,range(Min,Max),Position,Data_Position,Data_Terms,Annotation).

% Parse of Min data      
sequence_terms_to_annotations_rec([_|Rest_Sequence_Data],range(Min,Max),Position,Data_Position,Data_Terms,Annotation) :-
      Position < Min,
      !,
      Position1 is Position+1,
      sequence_terms_to_annotations_rec(Rest_Sequence_Data,range(Min,Max),Position1,Data_Position,Data_Terms,Annotation).


sequence_terms_to_annotations_rec([Annot|Rest_Sequence_Data],range(Min,Max),Position,Data_Position,Data_Terms,[Annot|Annotation]) :-
      Position >= Min,
      Position =< Max,
      !,
      Position1 is Position+1,
      sequence_terms_to_annotations_rec(Rest_Sequence_Data,range(Min,Max),Position1,Data_Position,Data_Terms,Annotation).



% Utils for load_annotation_from_file(db)

%%%
% db_terms_annotations(++Options,++List_Terms,--Annotation)
%%%
%Options = [in_db(Letter),out_db(Letter),range_position(Param_Start,Param_End),range(Min,Max)]


db_terms_to_annotations(_Options,[],[]) :-
        !.


db_terms_to_annotations(Options,[DB|List_Terms],Annotation) :-
        member(range(Min,Max),Options),
        !,
        init_db_terms(Options,Annot_Format,Range_Position),
        get_next_range(Range_Position,DB,Range),
        db_terms_to_annotations_rec(1,range(Min,Max),Range,Annot_Format,Range_Position,List_Terms,Annotation).



db_terms_to_annotations(Options,[DB|List_Terms],Annotation) :-
        init_db_terms(Options,Annot_Format,Range_Position),
        get_next_range(Range_Position,DB,Range),
        db_terms_to_annotations_rec(1,not_range,Range,Annot_Format,Range_Position,List_Terms,Annotation).


% Recursive call
% Options: No range(Min,Max) 

% When no range is specificied, annotation stops when the last Position = Max for the last Range of the db
db_terms_to_annotations_rec(Position,not_range,(_,Max),_Annot_Format,_Range_Position,[],[]) :-
        Position > Max,
        !.

% End of a Range, 
db_terms_to_annotations_rec(Position,not_range,(_Min,Max),Annot_Format,Range_Position,[DB|List_Terms],Annotations) :-
        Position > Max,
        !,
        get_next_range(Range_Position,DB,New_Range),
        db_terms_to_annotations_rec(Position,not_range,New_Range,Annot_Format,Range_Position,List_Terms,Annotations).

% Outside a specific Region 
db_terms_to_annotations_rec(Position,not_range,(Min,Max),(Letter_Out,Letter_In),Range_Position,List_Terms,[Letter_Out|Annotations]) :-
        Position < Min,
        !,
        Next_Position is Position+1,
        db_terms_to_annotations_rec(Next_Position,not_range,(Min,Max),(Letter_Out,Letter_In),Range_Position,List_Terms,Annotations).


% Inside a specific Region 
db_terms_to_annotations_rec(Position,not_range,(Min,Max),(Letter_Out,Letter_In),Range_Position,List_Terms,[Letter_In|Annotations]) :-
        Position >= Min,
        Position =< Max,
        !,
        Next_Position is Position+1,
        db_terms_to_annotations_rec(Next_Position,not_range,(Min,Max),(Letter_Out,Letter_In),Range_Position,List_Terms,Annotations).


% Recursive call
% Options: range(Range_Min,Range_Max) 

% Ends when Position = Max_Range
db_terms_to_annotations_rec(Position,range(_Range_Min,Range_Max),_Range,_Annot_Format,_Range_Position,_List_Terms,[]) :-
        Position > Range_Max,
        !.


% End of the list of terms, but outside the specified range
db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),(_Min,Max),(Letter_Out,Letter_In),_Range_Position,[],Annotations) :-
        Position > Max,
        Position < Range_Min,
        !,
        New_Position = Range_Min,
        db_terms_to_annotations_rec(New_Position,range(Range_Min,Range_Max),(_Min,Max),(Letter_Out,Letter_In),_Range_Position,[],Annotations).


% End of the list of terms, but inside the specified range
db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),(_Min,Max),(Letter_Out,_Letter_In),_Range_Position,[],[Letter_Out|Annotations]) :-
        Position > Max,
        Position >= Range_Min,
        Position =< Range_Max,
        !,
        New_Position is Position+1,
        db_terms_to_annotations_rec(New_Position,range(Range_Min,Range_Max),(_Min,Max),(Letter_Out,_Letter_In),_Range_Position,[],Annotations).



% End of a DB range update by a new one
db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),(_Min,Max),Annot_Format,Range_Position,[DB|List_Terms],Annotations) :-
        Position > Max,
        !,
        get_next_range(Range_Position,DB,New_Range),
        db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),New_Range,Annot_Format,Range_Position,List_Terms,Annotations).


% No generation: outside the specified range + update of the new DB range
db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),(Min,Max),_Annot_Format,_Range_Position,_List_Terms,Annotations) :-
        Position < Range_Min,
        !,
        update_position_jump(Range_Min,(Min,Max),New_Position),
        db_terms_to_annotations_rec(New_Position,range(Range_Min,Range_Max),(Min,Max),_Annot_Format,_Range_Position,_List_Terms,Annotations).


% Inside the specified range but outside a specific region
db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),(Min,_Max),(Letter_Out,_Letter_In),_Range_Position,_List_Terms,[Letter_Out|Annotations]) :-
        Position >= Range_Min,
        Position =< Range_Max,
        Position < Min,
        !,
        New_Position is Position+1,
        db_terms_to_annotations_rec(New_Position,range(Range_Min,Range_Max),(Min,_Max),(Letter_Out,_Letter_In),_Range_Position,_List_Terms,Annotations).


% Inside the specified range AND inside a specific region
db_terms_to_annotations_rec(Position,range(Range_Min,Range_Max),(Min,Max),(Letter_Out,Letter_In),Range_Position,List_Terms,[Letter_In|Annotations]) :-
        Position >= Range_Min,
        Position =< Range_Max,
        Position >= Min,
        Position =< Max,
        !,
        New_Position is Position+1,
        db_terms_to_annotations_rec(New_Position,range(Range_Min,Range_Max),(Min,Max),(Letter_Out,Letter_In),Range_Position,List_Terms,Annotations).


%%%
% Utils db_terms_to_annotations
%%%

% Setting of Annot_Format and Range_Position
% Default(when non member) Annot_Format = (0,1), Range_Position = (1,2)
init_db_terms(Options,Annot_Format,Range_Position) :-
        (member(in_db(Letter_In),Options) ->
            (member(out_db(Letter_Out),Options) ->
                Annot_Format = (Letter_Out,Letter_In)
            ;
                Annot_Format = (0,Letter_In)
            )
        ;
            (member(out_db(Letter_Out),Options) ->
                Annot_Format = (Letter_Out,1)
            ;
                Annot_Format = (0,1)
            )
        ),
        (member(range_position(Param_Start,Param_End),Options) ->
            Range_Position = (Param_Start,Param_End)
        ;
            Range_Position = (1,2)
        ).



% get_next_range(++Range_Position,++DB,--Range)
get_next_range((Param_Start,Param_End),DB,(Min,Max)) :-
        DB =.. [_|List_Params],
        nth1(Param_Start,List_Params,Min),
        nth1(Param_End,List_Params,Max).


% update_position_jump(++Range_Min,(++Min,++Max),-Position)
update_position_jump(Range_Min,(_Min,Max),New_Position) :-
        Range_Min < Max,
        !,
        New_Position = Range_Min.


% update_position_jump(++Range_Min,(++Min,++Max),-Position)
update_position_jump(_Range_Min,(_Min,Max),New_Position) :-
        New_Position is Max+1.




%--------------------------------
% Saving information to file  %
%--------------------------------

% save_sequence_list_to_file(++File,--Sequence)

save_annotation_to_sequence_file(KeyIndex,ChunkSize,Annotation,File) :-
	split_list_in_chunks(ChunkSize,Annotation,DataChunks),
	create_sequence_terms(KeyIndex,1,DataChunks,Terms),
	terms_to_file(File,Terms).

create_sequence_terms(_,_,[],[]).

create_sequence_terms(KeyIndex,StartPos,[Chunk|ChunksRest],[Term|TermsRest]) :-
	length(Chunk,ChunkLen),
	EndPos is StartPos + ChunkLen - 1,
	NextStartPos is EndPos + 1,
	Term =.. [ data, KeyIndex, StartPos, EndPos, Chunk ],
	create_sequence_terms(KeyIndex,NextStartPos,ChunksRest,TermsRest).

split_list_in_chunks(_,[],[]).

split_list_in_chunks(ChunkSize, List, [Chunk|ChunksRest]) :-
	nfirst_list(ChunkSize,List,Chunk,RestList),
	!,
	split_list_in_chunks(ChunkSize,RestList,ChunksRest).

split_list_in_chunks(ChunkSize, List, [List]) :-
	length(List,ListLength),
	ListLength < ChunkSize.

nfirst_list(0,L,[],L).

nfirst_list(N,[E|List],[E|NFirstList],RestList) :-
	N1 is N - 1,
	nfirst_list(N1,List,NFirstList,RestList).

save_sequence_list_to_file(File,Sequence) :-
	data_elements_to_sequence_terms(Sequence,Terms),
	terms_to_file(File,Terms).

data_elements_to_sequence_terms(Data,Terms) :-
	data_elements_to_sequence_terms(1,Data,Terms).

data_elements_to_sequence_terms(_,[],[]).
data_elements_to_sequence_terms(Pos,[Data|R1],[elem(Pos,Data)|R2]) :-
	NextPos is Pos + 1,
	data_elements_to_sequence_terms(NextPos,R1,R2).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading a sequence into memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load_sequence(SeqId, Filename) :-
	terms_from_file(Filename,Terms),
	Terms = [ FirstTerm | _ ],
	FirstTerm =.. [_functor,_id,Begin,End,_],
	BlockLen is (End - Begin) + 1,
	length(Terms,NumBlocks),
	assert(sequence_block_length(SeqId,BlockLen)),
	assert(sequence_blocks(SeqId,NumBlocks)),
	assert_sequence_terms(SeqId,Terms,0,NumBlocks).

unload_sequence(SeqId) :-
	retractall(sequence_block_length(SeqId,_)),
	retractall(sequence_blocks(SeqId,_)),
	retractall(sequence(SeqId,_,_)).

assert_sequence_terms(_,[],NumBlocks,NumBlocks).
assert_sequence_terms(Id, [Term|TRest], BlockNo, NumBlocks) :-
	assert(sequence(Id,BlockNo,Term)),
	NextBlockNo is BlockNo + 1,
	assert_sequence_terms(Id,TRest,NextBlockNo,NumBlocks).

get_sequence_range(SeqId, Min, Max, Data) :-
	sequence_block_length(SeqId,BlockLen),
	% The smallest block number in this sequence range:
	MinBlockNumber is (Min-1) // BlockLen,
	% The position at which the smallest block in this sequence range starts
	MinBlockStart is MinBlockNumber*BlockLen+1,
	% The relative position of Min in the first block 
	StartInBlock is Min-MinBlockStart + 1,
	% The number of block that includes Max:
	MaxBlockNumber is (Max-1) // BlockLen,
	((MinBlockNumber == MaxBlockNumber) -> % Min and Max are in same block
	 EndInBlock is Max-MinBlockStart + 1,
	 get_block_part(SeqId,MinBlockNumber,StartInBlock,EndInBlock,Data)
	;
	 get_block_part(SeqId,MinBlockNumber,StartInBlock,BlockLen,Part),
	 NextMin is Min + (BlockLen-StartInBlock) + 1,
	 get_sequence_range(SeqId,NextMin,Max,PartsRest),
	 append(Part,PartsRest,Data)
	).

get_block_part(SeqId,BlockNumber,StartInBlock, EndInBlock, PartData) :-
	sequence(SeqId,BlockNumber,Term),
	Term =.. [ _functor, _id, _start, _end, BlockData ],
	get_block_part_rec(BlockData,1,StartInBlock,EndInBlock,PartData).

get_block_part_rec([DataItem|_],Pos,_, EndInBlock, [DataItem]) :-
	Pos == EndInBlock.

get_block_part_rec([_|BlockData],Pos,StartInBlock, EndInBlock, PartData) :-
	Pos < StartInBlock,
	NextPos is Pos + 1,
	get_block_part_rec(BlockData,NextPos,StartInBlock,EndInBlock,PartData).

get_block_part_rec([DataItem|BlockData],Pos,StartInBlock, EndInBlock, [DataItem|PartData]) :-
	Pos >= StartInBlock,
	NextPos is Pos + 1,
	get_block_part_rec(BlockData,NextPos,StartInBlock,EndInBlock,PartData).


% A CP approach to do that (small test) not finished, data file should be consulted.
%test(Nb_Nuc,Range_Min,Range_Max,Result) :-
%        lost_sequence_file('U00096',Sequence_File),
%        open(Sequence_File,read,Stream),
%        findall([Min,Max,Data],(data(_Key,Min,Nax,Data),)Min+Nb_Nuc #>=Range_Min,Min #=< Range_Max,Range_Min#=<Max,Max-Nb_Nuc#=<Range_Max),Result).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Basic reading/writing of terms to/from file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% terms_from_file(++File,--Terms)
% Reads all Terms from named file File
terms_from_file(File, Terms) :-
	open(File, read, Stream),
	ground(Stream),
	collect_stream_terms(Stream,Terms),
	close(Stream).

terms_from_file_map(File,Goal) :-
	open(File, read, Stream),
	ground(Stream),
	map_stream_terms(Stream,Goal),
	close(Stream).

% terms_to_file(++File,++Terms)
% Writes all Terms to named file File
terms_to_file(File,Terms) :-
	open(File,write,Stream),
	ground(Stream),
	write_terms_to_stream(Stream,Terms),
	close(Stream).

% Writes terms to a Stream
write_terms_to_stream(_,[]).
write_terms_to_stream(Stream,[Term|Rest]) :-
	writeq(Stream,Term),
	write(Stream,'.\n'),
	write_terms_to_stream(Stream,Rest).

% Create list of Rules found in Stream
collect_stream_terms(Stream, Rules) :- 
	read(Stream, T),
	((T == end_of_file) ->
	 Rules = []
	;
	 collect_stream_terms(Stream,Rest),
	append([T],Rest,Rules)
	).

check_term(File,Term) :-
        open(File,read,Stream),
        ground(Stream),
        read(Stream,T),
        (T == end_of_file ->
            throw("Empy File, no annotation to extract")
            ;
            T = Term
        ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Utility for finding the functor in a text(prolog(_)) format
% Eg. the file is expected to have only one functor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

file_functor(Filename, Functor) :-
	terms_from_file(Filename,Terms),
	findall( F,((member(X,Terms), X =.. [ F |_ ])), Functors),
	eliminate_duplicate(Functors,[Functor]).

%% split_file(+Filename,+ChunkSize,+OutputFilePrefix,+OutputFileSuffix)
%
% Split a file of terms into multiple files
split_file(Filename,ChunkSize,OutputFilePrefix, OutputFileSuffix) :-
        split_file(Filename,ChunkSize,OutputFilePrefix, OutputFileSuffix,_).
split_file(Filename,ChunkSize,OutputFilePrefix, OutputFileSuffix,ResultingFiles) :-
       open(Filename,read,Stream),
       split_file_loop(Stream,ChunkSize,1,OutputFilePrefix, OutputFileSuffix,ResultingFiles),
       close(Stream).

split_file_loop(IStream, ChunkSize, FileNo, OutputFilePrefix,OutputFileSuffix,ResultingFiles) :-
	atom_integer(FileNoAtom,FileNo),
	atom_concat_list([OutputFilePrefix,'_',FileNoAtom,OutputFileSuffix], OutputFile),
	write('creating split file:'), write(OutputFile),nl,
	read_next_n_terms(ChunkSize,IStream,Terms),
	((Terms == []) ->
         ResultingFiles = []
	;
	 terms_to_file(OutputFile,Terms),
	 NextFileNo is FileNo + 1,
	 length(Terms,NumTerms),
	 
	 ((NumTerms < ChunkSize) ->									% if so, don't scan further
          ResultingFiles = [OutputFile]
	 ;																					% else, go again
	        ResultingFiles = [OutputFile|RestResultingFiles],
	  			split_file_loop(IStream,ChunkSize,NextFileNo,OutputFilePrefix,OutputFileSuffix,RestResultingFiles)
	 )	 
	).
% Utils split_file
read_next_n_terms(0,_,[]).
read_next_n_terms(N,Stream,Terms) :-
	read(Stream,Term),
        ((Term == end_of_file) ->
	 Terms = []
	;
	 Terms = [Term|RestTerms],
	 !,
	 N1 is N - 1,
	 read_next_n_terms(N1,Stream,RestTerms)
	).


%% concat_files(+SmallFiles_List,+BiggerFile_Name)
%
% concatenates the contents of a list of files into one
concat_files(SmallFiles_List, BiggerFile_Name):-
	open(BiggerFile_Name,write, OutStream),
	concat_files_rec(SmallFiles_List,OutStream),
	close(OutStream).
	
concat_files_rec([],_OutStream):-!.
concat_files_rec([File|Files],OutStream):-
	terms_from_file(File,Terms),
	write_terms_to_stream(OutStream,Terms),
	writeln(File),
	writeln(Files), % (Prolog bug !!!) Files seems to interpreted as an atom rather than a list here ??? 
	concat_files_rec(Files,OutStream).



%% split_file_fasta(+Filename,+ChunkSize,+OutputFilePrefix,+OutputFileSuffix,-ResultFiles)
%
% Split a FASTA composed of several header (> ...) into multiple files. We consider that a chunk
% has been seen each time that the symbol > appears at the beginning of a line

split_file_fasta(_Filename,ChunkSize,_OutputFilePrefix,_OutputFileSuffix,[]) :-
        ChunkSize =< 0,
        !,
        write("ChunkSize should be a non-negative number"),
        nl.

split_file_fasta(Filename,ChunkSize,OutputFilePrefix,OutputFileSuffix,ResultingFiles) :-
        open(Filename,read,IStream),
        readline(IStream,Firsline),
        split_file_fasta_rec(IStream,ChunkSize,1,OutputFilePrefix,OutputFileSuffix,Firsline,ResultingFiles),
        close(IStream).
		


split_file_fasta_rec(IStream, ChunkSize, FileNo, OutputFilePrefix,OutputFileSuffix,Firstline,ResultingFiles) :-
        number_codes(FileNo,Code),
        atom_codes(FileNo_Atom,Code),
        lost_tmp_directory(Tmp),
	atom_concat_list([Tmp,OutputFilePrefix,'_',FileNo_Atom,'.',OutputFileSuffix], OutputFile),
	write('creating split file:'), write(OutputFile),nl,
        open(OutputFile,write,OStream),
	read_next_n_chunk(Firstline,ChunkSize,IStream,OStream,EOF,LastLine),
        close(OStream),
	((EOF == yes) ->
            true,
            ResultingFiles = [OutputFile]
	;
            ResultingFiles = [OutputFile|RestResultingFiles],
            NextFileNo is FileNo+1,
            split_file_fasta_rec(IStream,ChunkSize,NextFileNo,OutputFilePrefix,OutputFileSuffix,LastLine,RestResultingFiles)
	).


% Read and write N chunk in FASTA format

% EOF reachs
read_next_n_chunk([-1],ChunkSize,_IStream,_OStream,yes,[-1]) :-
        ChunkSize >=0,
        !.

% Case: Line starts with > and N chunk already read
read_next_n_chunk([62|Rest],0,_IStream,_OStream,no,[62|Rest]) :-
        !.

% Case: Line starts with > and less than N chunk has been already read
read_next_n_chunk([62|Rest],ChunkSize,IStream,OStream,EOF,LastLine) :-
        ChunkSize > 0,
        !,
        atom_codes(Atom,[62|Rest]),
        write(OStream,Atom),
        nl(OStream),
        readline(IStream,CodeList),
        ChunkSize1 is ChunkSize-1,
        read_next_n_chunk(CodeList,ChunkSize1,IStream,OStream,EOF,LastLine).

% Default Case
read_next_n_chunk(CodeList,ChunkSize,IStream,OStream,EOF,LastLine) :-
        ChunkSize >= 0,
        !,
        atom_codes(Atom,CodeList),
        write(OStream,Atom),
        nl(OStream),
        readline(IStream,New_CodeList),
        read_next_n_chunk(New_CodeList,ChunkSize,IStream,OStream,EOF,LastLine).


        
        

