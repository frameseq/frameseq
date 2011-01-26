/** <module> Module accuracy.pl

 This is a tool to calculate the accuracy of gene finder predictions
 against a reference annotation. It expects to find facts representing
 the predictions and the reference annation. These facts are expected
 to be on the form functor(From, To, Strand, ReadingFrame, Name).

 @author Christian Theil Have
 @date dec. 2009.

*/

:- lost_include_api(misc_utils).

%% Tabling declarations:

:- table count_genes(+,+,+,-).
:- table nucleotide_level_accuracy_counts(+,+,+,+,-,-,-,-).
:- table correct_genes(+,+,+,+,-).
:- table correct_gene_ends(+,+,+,+,-).
:- table annotations_as_lists(+,+,+,-).
:- table annotations_as_detailed_list(+,+,+,-).
		
report_type(Type) :-
	member(Type,[
		genes_predicted,
		genes_actual,
		genes_correct,
		genes_wrong,
		gene_stops_correct,
		gene_stops_wrong,
		gene_sensitivity,
		gene_specificity,
		gene_stop_sensitivity,
		gene_stop_specificity,
		genes_wrong_ratio,
		genes_missing_ratio,
		nucleotide_true_positives,
		nucleotide_false_positives,
		nucleotide_true_negatives,
		nucleotide_false_negatives,
		nucleotide_sensitivity,
		nucleotide_specificity,
		nucleotide_specificity_traditional,
		nucleotide_correlation_coefficient,
		nucleotide_simple_matching_coefficient,
		nucleotide_average_conditional_probability,
		nucleotide_approximate_correlation	]).

% Types of reports
genes_predicted(_RefFunctor,PredFunctor,Start,End,Result) :- 
	count_genes(PredFunctor,Start,End,Result).
	
genes_actual(RefFunctor,_PredFunctor,Start,End,Result) :-
	count_genes(RefFunctor,Start,End,Result).
	
genes_correct(RefFunctor,PredFunctor,Start,End,Result) :-
	number_of_correct_genes(RefFunctor, PredFunctor,Start,End,Result).

genes_wrong(RefFunctor,PredFunctor,Start,End,Result) :-
	number_of_wrong_genes(RefFunctor, PredFunctor, Start, End, Result).

gene_stops_correct(RefFunctor,PredFunctor,Start,End,Result) :-
	number_of_correct_gene_ends(RefFunctor, PredFunctor,Start,End,Result).

gene_stops_wrong(RefFunctor,PredFunctor,Start,End,Result) :-
	number_of_wrong_gene_ends(RefFunctor, PredFunctor,Start,End,Result).
	
gene_sensitivity(RefFunctor,PredFunctor,Start,End,Result) :-
	gene_level_sensitivity(RefFunctor,PredFunctor,Start,End,Result).

gene_specificity(RefFunctor,PredFunctor,Start,End,Result) :-
	gene_level_specificity(RefFunctor,PredFunctor,Start,End,Result).
	
gene_specificity(RefFunctor,PredFunctor,Start,End,Result) :-
	gene_level_specificity(RefFunctor,PredFunctor,Start,End,Result).	
	
gene_stop_sensitivity(RefFunctor,PredFunctor,Start,End,Result) :-
	gene_level_stop_sensitivity(RefFunctor,PredFunctor,Start,End,Result).

gene_stop_specificity(RefFunctor,PredFunctor,Start,End,Result) :-
	gene_level_stop_specificity(RefFunctor,PredFunctor,Start,End,Result).	

genes_wrong_ratio(RefFunctor,PredFunctor,Start,End,Result) :-
	wrong_genes(RefFunctor,PredFunctor,Start,End,Result).

genes_missing_ratio(RefFunctor,PredFunctor,Start,End,Result) :-
	missing_genes(RefFunctor,PredFunctor,Start,End,Result).
	
% Note that (in the following) nucleotide_level_accuracy_counts is tabled, so multiple
% calls from each of the individual report types does not result in any major overhead.
nucleotide_true_positives(RefFunctor,PredFunctor,Start,End,TP) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor, PredFunctor, TP,_FP,_TN,_FN).
		
nucleotide_false_positives(RefFunctor,PredFunctor,Start,End,FP) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor, PredFunctor, _TP,FP,_TN,_FN).
		
nucleotide_true_negatives(RefFunctor,PredFunctor,Start,End,TN) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor, PredFunctor, _TP,_FP,TN,_FN).
		
nucleotide_false_negatives(RefFunctor,PredFunctor,Start,End,FN) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor, PredFunctor, _TP,_FP,_TN,FN).
		
nucleotide_specificity(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,TP,FP,_TN,_FN),
	specificity(TP,FP,Result).
	
nucleotide_specificity_traditional(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,_TP,FP,TN,_FN),
	specificity_traditional(TN,FP,Result).	
	
nucleotide_sensitivity(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,TP,_FP,TN,_FN),
	sensitivity(TP,TN,Result).

nucleotide_correlation_coefficient(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,TP,FP,TN,FN),
	correlation_coefficient(TP,FP,TN,FN,Result).

nucleotide_simple_matching_coefficient(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,TP,FP,TN,FN),
	simple_matching_coefficient(TP,FP,TN,FN,Result).

nucleotide_average_conditional_probability(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,TP,FP,TN,FN),
	average_conditional_probability(TP,FP,TN,FN,Result).

nucleotide_approximate_correlation(RefFunctor,PredFunctor,Start,End,Result) :-
	nucleotide_level_accuracy_counts(Start,End, RefFunctor,PredFunctor,TP,FP,TN,FN),
	aproximate_correlation(TP,FP,TN,FN,Result).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% accuracy measures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

%% sensivity(+TP,+TN,-SN)
%
% Computation of the sensity
% ==
% SN is TP/(TP+FN) or undefined
% ==
sensivitity(0,0,undefined) :- !.
sensitivity(TP, FN, SN) :-
	SN is TP / (TP + FN).

%% specificity(+TP,+FP,-SP)
%
% Computation of the specificity
% ==
% SP is TP/(TP+FN) or undefined
% ==
specificity(0,0,undefined) :- !.
specificity(TP,FP,SP) :-
	SP is TP / (TP + FP).

%% specificity_traditional(+TN,+FP,-SP)
%
% Computation of the tradional specificity
% ==
% SP is TN / (TN + FP)
% ==

specificity_traditional(0,0,undefined) :- !.
specificity_traditional(TN,FP,SP) :-
	SP is TN / (TN + FP).

%% correlation_coefficient(+TP,+FP,+TN,+FN,-CC)
%
% Computation of correlation coefficient
%
% Note: 0.0 is add to make numbers floats instead of ints. 
% Ints are not allowed to be larger than 268435455 in bprolog which
% would otherwise cause this predicate to overflow for realistic data sizes
correlation_coefficient(TP,FP,TN,FN,CC) :-
	Numerator is (TP*TN) - (FN*FP) + 0.0,
	A is TP+FN+0.0, 
	B is TN+FP+0.0, 
	C is TP+FP+0.0, 
	D is TN+FN+0.0,
	DenominatorSquared is A*B*C*D,
		((DenominatorSquared > 0.0) ->
			Denominator is sqrt(DenominatorSquared),
			CC is Numerator / Denominator
				;
				CC=undefined).
				
%% simple_matching_coefficient(+TP,+FP,+TN,+FN,-SMC)
%
% Computation of the simple matching coefficient
% ==
% SMC is (TP + TN) / (TP + FN + FP + TN)
% ==
simple_matching_coefficient(0,0,0,0,undefined) :- !.
simple_matching_coefficient(TP,FP,TN,FN,SMC) :-
	SMC is (TP + TN) / (TP + FN + FP + TN).

%% average_conditional_probability(+TP,+FP,+TN,+FN,-ACP)
%
% Computation of the average condtional probability

average_conditional_probability(0,_,_,0,undefined) :- !.
average_conditional_probability(0,0,_,_,undefined) :- !.
average_conditional_probability(_,0,0,_,undefined) :- !.
average_conditional_probability(_,_,0,0,undefined) :- !.

average_conditional_probability(TP,FP,TN,FN,ACP) :-
	A is TP / (TP+FN),
	B is TP / (TP+FP),
	C is TN / (TN+FP),
	D is TN / (TN+FN),
	ACP is (A+B+C+D)/4.

%% approximate_correlation(+TP,+FP,+TN,+FN,-AC)
%
% Computation of the average correlation

aproximate_correlation(TP,FP,TN,FN,undefined) :-
	average_conditional_probability(TP,FP,TN,FN,undefined),
		!.
aproximate_correlation(TP,FP,TN,FN,AC) :-
	average_conditional_probability(TP,FP,TN,FN,ACP),
	AC is (ACP - 0.5) * 2.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate gene level accuracy counts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

count_genes(Functor,Start,End,Count) :-
	annotations_as_lists(Functor,Start,End,PredAnnot),
		% predannot is a list of six lists. one for each reading frame
		% flatten_once merges all these in one list.. 
	flatten_once(PredAnnot,Flat),
	length(Flat,Count).

correct_gene_ends(RefFunctor,PredFunctor,Start,End,Correct) :-
	annotations_as_detailed_list(RefFunctor,Start,End,RefAnnot),
	annotations_as_detailed_list(PredFunctor,Start,End,PredAnnot),
		findall(Stop,
				(member([coding,_,Stop,'+',Frame],PredAnnot),
				member([coding,_,Stop,'+',Frame],RefAnnot)),
				StopsForward),
		findall(Stop,
				(member([coding,Stop,_,'-',Frame],PredAnnot),
				member([coding,Stop,_,'-',Frame],RefAnnot)),
				StopsReverse),
		union(StopsForward,StopsReverse,Correct).

correct_genes(RefFunctor, PredFunctor, Start, End, Correct) :-
	annotations_as_detailed_list(RefFunctor,Start,End,RefAnnot),
	annotations_as_detailed_list(PredFunctor,Start,End,PredAnnot),
	intersection(RefAnnot,PredAnnot,Correct).
	
number_of_correct_genes(RefFunctor, PredFunctor, Start, End, NoCorrect) :-
	correct_genes(RefFunctor, PredFunctor, Start, End, Correct),
	length(Correct,NoCorrect).

number_of_correct_gene_ends(RefFunctor, PredFunctor, Start, End, NoCorrect) :-
	correct_gene_ends(RefFunctor, PredFunctor, Start, End, Correct),
	length(Correct,NoCorrect).

	
number_of_wrong_genes(RefFunctor, PredFunctor, Start, End, Wrong) :-
	number_of_correct_genes(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(PredFunctor,Start,End,Predicted),
	Wrong is Predicted - Correct.

number_of_wrong_gene_ends(RefFunctor, PredFunctor, Start, End, Wrong) :-
	number_of_correct_gene_ends(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(PredFunctor,Start,End,Predicted),
	Wrong is Predicted - Correct.

number_of_missing_genes(RefFunctor, PredFunctor, Start, End, Missing) :-
	number_of_correct_genes(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(RefFunctor,Start,End,Actual),
	Missing is Actual - Correct.

number_of_missing_gene_ends(RefFunctor, PredFunctor, Start, End, Missing) :-
	number_of_correct_gene_ends(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(RefFunctor,Start,End,Actual),
	Missing is Actual - Correct.


% EN = #correct / #actual
gene_level_sensitivity(RefFunctor,PredFunctor,Start,End,SN) :-
	number_of_correct_genes(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(RefFunctor,Start,End,Actual),
	SN is Correct / Actual.
	
% SP = #correct / #predicted
gene_level_specificity(RefFunctor,PredFunctor,Start,End,SP) :-
	number_of_correct_genes(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(PredFunctor,Start,End,Predicted),
	write(Correct),nl,
	write(Predicted),nl,
	SP is Correct / Predicted.
	
gene_level_stop_sensitivity(RefFunctor,PredFunctor,Start,End,SN) :-
	number_of_correct_gene_ends(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(RefFunctor,Start,End,Actual),
	SN is Correct / Actual.
	
% SP = #correct / #predicted
gene_level_stop_specificity(RefFunctor,PredFunctor,Start,End,SP) :-
	number_of_correct_gene_ends(RefFunctor,PredFunctor,Start,End,Correct),
	count_genes(PredFunctor,Start,End,Predicted),
	SP is Correct / Predicted.

% MG = #missing / #actual
missing_genes(RefFunctor,PredFunctor,Start,End,MG)	:-
	number_of_missing_genes(RefFunctor,PredFunctor,Start,End,Missing),
	count_genes(RefFunctor,Start,End,Actual),
	MG is Missing / Actual.
	
% WG = #wrong / #predicted
wrong_genes(RefFunctor,PredFunctor,Start,End,WG) :-
	number_of_wrong_genes(RefFunctor,PredFunctor,Start,End,Wrong),
	count_genes(PredFunctor,Start,End,Predicted),
	WG is Wrong / Predicted.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hard to find genes list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%gene_finding_difficulty_report(+RefFunctor,+PredictionFunctors,+RangeMin,+RangeMax,+MatchCriteria,-GenePredictionDifficultyList)
%
% Predicates that computes a report on the difficulty to find a gene
%

gene_finding_difficulty_report(RefFunctor,PredictionFunctors,RangeMin,RangeMax,MatchCriteria,GenePredictionDifficultyList) :-
	annotations_as_detailed_list(RefFunctor,RangeMin,RangeMax,ReferenceGenes),
	map(annotations_as_detailed_list(input,RangeMin,RangeMax,output),PredictionFunctors,PredictionGenes),
	gene_score_list_all(MatchCriteria,ReferenceGenes,PredictionGenes,GeneScoreLists),
	rotate_list_vector(GeneScoreLists,OneListPerGeneScores),
	combine_gene_scores(RefFunctor,ReferenceGenes,OneListPerGeneScores,GenePredictionDifficultyList).

combine_gene_scores(_,[],[],[]).
combine_gene_scores(RefFunctor,
			[[coding,From,To,Strand,Frame]|RefGenesRest],
			[GeneScoreList|GeneScoresRest],
			[gene(From,To,Strand,Frame,ExtraList)|CombinedRest]) :-
	annotation(RefFunctor,From,To,Strand,Frame,ExtraOrig),
	append(ExtraOrig,[found_by_genefinders(GeneScoreList),gene_finding_difficulty_score(CombinedScore)],ExtraList),
	length(GeneScoreList,NumGeneFinders),
	sumlist(GeneScoreList,NumFoundGene),
	gene_difficulty_score(NumGeneFinders,NumFoundGene,CombinedScore),
	combine_gene_scores(RefFunctor,RefGenesRest,GeneScoresRest,CombinedRest).

%% gene_difficulty_score(+NumGeneFinders, +NumFoundGene, -DifficultyScore)
%
% DifficultyScore is computed given the following formula
% ==
% DifficultyScore is 1 - ( NumFoundGene / NumGeneFinders)
% ==

gene_difficulty_score(NumGeneFinders, NumFoundGene, DifficultyScore) :-
	NumFoundGene =< NumGeneFinders,
	ScorePerGeneFinder is 1 / NumGeneFinders,
	DifficultyScore is 1 - (ScorePerGeneFinder * NumFoundGene).

% FIXME:
% It would be better?? if the difficulty score could also be weighted by the false positive
% percentage of each gene finder, which would give a more "accurate" score

gene_score_list_all(_,_,[],[]).

gene_score_list_all(MatchCriteria,RefGenes, [PredSet|PredSetRest], [GeneScoreList1|GeneScoreListRest]) :-
	gene_score_list(MatchCriteria,RefGenes,PredSet,GeneScoreList1),
	gene_score_list_all(MatchCriteria,RefGenes,PredSetRest,GeneScoreListRest).

% Given a list of all genes and a list of correctly predicted genes
% produce a list which has a one if the gene is corrrectly predicted
% zero otherwise

gene_score_list(_,[],_,[]).

gene_score_list(MatchCriteria, [Gene|GenesRest], PredictedGenes, [1|RestScores]) :-
	((MatchCriteria == start_and_stop) -> % Match start and stop codon
	 GeneMatcher = Gene
	; % Match only stop codon
	 Gene =.. [ coding, From, To, Strand, Frame ],
	 ((Frame = '+') ->
	  GeneMatcher =.. [ coding, _, From, Strand, Frame ]
	 ;
	  GeneMatcher =.. [ coding, To, _, Strand, Frame ]
	  )
	),
	member(GeneMatcher,PredictedGenes),
	subtract(PredictedGenes,[GeneMatcher],PredictedGenesRest),
	!,
	gene_score_list(MatchCriteria,GenesRest,PredictedGenesRest,RestScores).

gene_score_list(MatchCriteria,[_|GenesRest], PredictedGenes, [0|RestScores]) :-
	gene_score_list(MatchCriteria,GenesRest,PredictedGenes,RestScores).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate nucleotide level accuracy counts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% report_nstats(+ReferenceAnnotFunctor,+PredictionAnnotFunctor,+Start,+End)
%
% This predicate computes and prints in the standart output: True Positive, 
% True Negative, False Positive, False Negative
% If I am right, Start and End specified a sub-part of the genome where this
% computation is performed

report_nstats(ReferenceAnnotFunctor,PredictionAnnotFunctor,Start,End) :-
	annotations_as_lists(PredictionAnnotFunctor,Start,End,PredAnnot),nl,
	annotations_as_lists(ReferenceAnnotFunctor,Start,End,RefAnnot),nl,
	nucleotide_level_accuracy_counts(Start,End, RefAnnot, PredAnnot, TP,FP,TN,FN),
	write('Nucleotide Level TP: '), write(TP), nl,
	write('Nucleotide Level FP: '), write(FP), nl,
	write('Nucleotide Level TN: '), write(TN), nl,
	write('Nucleotide Level FN: '), write(FN), nl.


%% nucleotide_level_accuracy_counts(+Begin,+End,+RefAnnot,+PredAnnot,-TP,-FP,-TN,-FN)
%
% Compute some statistics at the nucleotide level.

nucleotide_level_accuracy_counts(Begin,End, RefFunctor, PredFunctor, TP,FP,TN,FN) :-
	annotations_as_lists(PredFunctor,Begin,End,PredAnnot),!,
	annotations_as_lists(RefFunctor,Begin,End,RefAnnot),!,
	map(sort, RefAnnot, RefAnnotSorted),
	map(fill_range_gaps(input,output,Begin,End,partial), RefAnnotSorted, RefAnnotFilled), !,
	map(sort, PredAnnot, PredAnnotSorted),!,
	map(fill_range_gaps(input,output,Begin,End,partial), PredAnnotSorted,PredAnnotFilled), !,
	map(rm_seq_elems,PredAnnotFilled,PredAnnotSimple),!,
	map(rm_seq_elems,RefAnnotFilled,RefAnnotSimple),!,
	distinct_intervals(RefAnnotSimple, RefAnnotDistinct),!,
	distinct_intervals(PredAnnotSimple, PredAnnotDistinct),!,
	all_frames_coding_intervals(RefAnnotDistinct,RefAnnotDistinctCoding),!,
	all_frames_coding_intervals(PredAnnotDistinct,PredAnnotDistinctCoding),!,
	binary_distinct_intervals(RefAnnotDistinctCoding,PredAnnotDistinctCoding,CombinedDistinct),!,
	nucleotide_level_intervals(CombinedDistinct,TPL,FPL,TNL,FNL),!,
	sum_range_list(TPL,TP),!,
	sum_range_list(FPL,FP),!,
	sum_range_list(TNL,TN),!,
	sum_range_list(FNL,FN),!,
	true.
	
all_frames_coding_intervals([],[]).
	
all_frames_coding_intervals([[Types,From,To]|Rest1],[[coding,From,To]|Rest2]) :-
	member(coding,Types),
	all_frames_coding_intervals(Rest1,Rest2).
	
all_frames_coding_intervals([[Types,From,To]|Rest1],[[noncoding,From,To]|Rest2]) :-
	not(member(coding,Types)),
	all_frames_coding_intervals(Rest1,Rest2).

% Nucleotide level accuracy annotation of a reference list and 
% prediction lists, which are expected to be collapsed summary 
% lists of all reading frames

nucleotide_level_intervals([],[],[],[],[]).

nucleotide_level_intervals([[[coding,coding],To,From]|Rest],[[To,From]|TP],FP,TN,FN) :-
	nucleotide_level_intervals(Rest,TP,FP,TN,FN).
nucleotide_level_intervals([[[coding,noncoding],To,From]|Rest],TP,FP,TN,[[To,From]|FN]) :-
	nucleotide_level_intervals(Rest,TP,FP,TN,FN).
nucleotide_level_intervals([[[noncoding,noncoding],To,From]|Rest],TP,FP,[[To,From]|TN],FN) :-
	nucleotide_level_intervals(Rest,TP,FP,TN,FN).
nucleotide_level_intervals([[[noncoding,coding],To,From]|Rest],TP, [[To,From]|FP],TN,FN) :-
	nucleotide_level_intervals(Rest,TP,FP,TN,FN).
nucleotide_level_intervals([[[noncoding,coding],To,From]|Rest],TP, [[To,From]|FP],TN,FN) :-
	nucleotide_level_intervals(Rest,TP,FP,TN,FN).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create  distinct intervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

distinct_intervals([IntervalRange],[IntervalRange]).

distinct_intervals([IntervalRange1,IntervalRange2], DistinctIntervals) :-
	binary_distinct_intervals(IntervalRange1,IntervalRange2,DistinctIntervals).

distinct_intervals([IntervalRange1,IntervalRange2|Rest], DistinctIntervals) :-
	binary_distinct_intervals(IntervalRange1,IntervalRange2,DistinctIntervals12),
	distinct_intervals([DistinctIntervals12|Rest],DistinctIntervals).

% Termination
binary_distinct_intervals([], [], []).

binary_distinct_intervals([[Rtype,Rstart,Rend]|Rrest], [[Ptype,Pstart,Pend]|Prest], [[CombinedType,Istart,Iend]|Irest]) :-
	Rstart \= Pstart,
	min(Rstart,Pstart,Istart),
	max(Rstart,Pstart,Iend),
	flexible_append(Rtype,Ptype,CombinedType),	
	binary_distinct_intervals([[Rtype,Iend,Rend]|Rrest], [[Ptype,Iend,Pend]|Prest], Irest).

% In the cases where the two annotations start and end at the same position.
binary_distinct_intervals([[Rtype,START,END]|Rrest], [[Ptype,START,END]|Prest], [[CombinedType,START,END]|Irest]) :-
	flexible_append(Rtype,Ptype,CombinedType),
	binary_distinct_intervals(Rrest, Prest, Irest).
		
binary_distinct_intervals([[Rtype,START,Rend]|Rrest], [[Ptype,START,Pend]|Prest], [[CombinedType,START,Iend]|Irest]) :-
	Rend < Pend,
	min(Rend,Pend,Iend),
	PstartNew is Iend + 1,
	flexible_append(Rtype,Ptype,CombinedType),	
	binary_distinct_intervals(Rrest, [[Ptype,PstartNew,Pend]|Prest], Irest).

binary_distinct_intervals([[Rtype,START,Rend]|Rrest], [[Ptype,START,Pend]|Prest], [[CombinedType,START,Iend]|Irest]) :-
	Pend < Rend,
	min(Rend,Pend,Iend),
	RstartNew is Iend + 1,
	flexible_append(Rtype,Ptype,CombinedType),	
	binary_distinct_intervals([[Rtype,RstartNew,Rend]|Rrest], Prest,Irest).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Unfold overlapping range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

unfold_overlap_range([],[]).

unfold_overlap_range([[_,_,_,[]]|R1],R2) :-
	unfold_overlap_range(R1,R2).
	
unfold_overlap_range([[AT,S,E,[[S1,E2]|Re]]|R1],[[AT,S1,E2]|R2]) :-
	unfold_overlap_range([[AT,S,E,Re]|R1],R2).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Coding list to extended range list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converts lists with elements of type [To,From] to a list of 
% elements [AnnotType, Start, End, []]. In the case of overlapping
% Examples:
% Simple genes: 
% [[coding,1,20],[coding,21,30]] -> [coding,1,20,[[1,20]]], [coding,21,30,[[21,30]]]
% Overlapping genes:
% [[coding,1,20],[coding,10,30]] -> [coding,1,30,[[1,20],[10,30]]]


add_element_to_ext_range(	[AnnotType,Start1,End1],
				[[AnnotType,Start2,End2,Elem2]|Rest2],
				[[AnnotType,Start,End,[[Start1,End1]|Elem2]]|Rest2]) :-
	overlaps(Start1,End1,Start2,End2),
	min(Start1,Start2,Start),
	max(End1,End2,End).

add_element_to_ext_range([AnnotType1,Start1,End1],
			[[AnnotType2,Start2,End2,Elem2]|Rest2],
			[[AnnotType1,Start1,End1,[[Start1,End1]]],
			 [AnnotType2,Start2,End2,Elem2]|Rest2]) :-
	AnnotType1 \== AnnotType2 ;
	not(overlaps(Start1,End1,Start2,End2)).

clist_to_ext_range_list([],[]).

clist_to_ext_range_list([[AnnotType,To,From]],[[AnnotType,To,From,[[To,From]]]]).

clist_to_ext_range_list([Part1|Part2],OutputList) :-
	clist_to_ext_range_list(Part2,ExtRange2),
	add_element_to_ext_range(Part1,ExtRange2,OutputList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fill_range_gaps: Add gaps to ranges,
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Document: what is difference between partial/complete

fill_range_gaps([],[],Curpos,Endpos,_Mode) :-
	   Curpos >= Endpos.

fill_range_gaps([],[[noncoding,Curpos,Endpos,[[Curpos,Endpos]]]],Curpos,Endpos,_).

fill_range_gaps([[AnnotType,IS,IE,Elems]|_],[[AnnotType,IS,Endpos,Elems]],_,Endpos,partial) :-
	IE > Endpos.

% If the input is longer than the range then cut it off
% FIXME: If it is a combined element of overlapping elements, one (or more) of 
% these may be shorter than the cutoff.
fill_range_gaps([[AnnotType,_,IE,Elems]|R],Filled,Curpos,Endpos,complete) :-
	IE > Endpos,
	findall([A,B],(member([A,B],Elems), B =< Endpos), ShortElems),
	ShortElems \= [],
	inlists_nth0(AllShorterElems,ShortEnds),
	inlists_nth0(AllShorterElems,ShortBegins),
	list_max(ShortEnds,End),
	list_min(ShortBegins,Begin),
	fill_range_gaps([[AnnotType,Begin,End,ShortElems]|R],Filled,Curpos,End,complete ).

% Past end of range
fill_range_gaps([[_,_,IE,_]|_],[],_,Endpos,complete) :-
	   IE > Endpos.

% If the last input doesnt reach end of range
fill_range_gaps([[AnnotType,IS,IE,Elems]],[[AnnotType,IS,IE,Elems], [noncoding,GS,Endpos,[[GS,Endpos]]]], IS, Endpos,_) :- 
	   IE < Endpos,
	   GS is IE + 1.

fill_range_gaps([[AnnotType,IS,IE,Elems]|Rest],[[noncoding,Curpos,GE,[[Curpos,GE]]]|GRest], Curpos, Endpos, Mode) :-
	   IS > Curpos,
	   GE is IS - 1,
	   fill_range_gaps([[AnnotType,IS,IE,Elems]|Rest],GRest,IS,Endpos,Mode).

fill_range_gaps([[AnnotType,Curpos,End,Elems]|IRest],[[AnnotType,Curpos,End,Elems]|GRest], Curpos, Endpos,Mode) :-
	NextCurpos is End + 1,
	fill_range_gaps(IRest,GRest,NextCurpos,Endpos,Mode).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Conversion from fact db format to lists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert annotation Prolog db format to a plain list consisting 
% of entries with coordinates for coding regions.

% FIXME: if goal has more arguments then we have a problem!
% Temporary hack to deal with database format

%annotation(Type, From, To, Strand, ReadingFrame, Extra) :-
%	Goal =.. [ Type, From, To, Strand, ReadingFrame, Extra ],
%	catch(call(Goal),_,fail).

%annotation(Type, From, To, Strand, ReadingFrame, Extra) :-
%	Goal =.. [ Type, From, To, Strand, ReadingFrame, Extra ],
%	catch(call(Goal),_,fail).

annotation(Type, From, To, Strand, ReadingFrame, Extra) :-
	Goal =.. [ Type,_, From, To, Strand, ReadingFrame, Extra ],
        write(Goal),nl,
	catch(call(Goal),_,fail).

annotations_in_range(Type, From, To, Strand, ReadingFrame, Name, RangeMin, RangeMax) :-
	annotation(Type,From,To,Strand,ReadingFrame,Name),
	From >= RangeMin,
	To =< RangeMax.

frame_annotation_to_list(AnnotType, From, To, Strand, ReadingFrame, ResultList) :-
	findall([coding,IncludeFrom, IncludeTo],
		annotations_in_range(AnnotType,IncludeFrom,IncludeTo,Strand,ReadingFrame,_,From,To),
		ResultListTmp),
	clist_to_ext_range_list(ResultListTmp,ResultList).

annotations_as_detailed_list(AnnotType, From, To, ResultList) :-
	findall([coding,IncludeFrom, IncludeTo,Strand,ReadingFrame],
		annotations_in_range(AnnotType,IncludeFrom,IncludeTo,Strand,ReadingFrame,_,From,To),
		ResultList).

annotations_as_lists(AnnotType,Start,End,List) :-
	strand_reading_frame_combinations(Combinations),
	annotations_as_lists(AnnotType,Start,End,Combinations,List).

annotations_as_lists(_,_,_,[],[]).

annotations_as_lists(AnnotType,Start,End,[[Strand,ReadingFrame]|Rest],[L|LR]) :-
	frame_annotation_to_list(AnnotType,Start,End,Strand,ReadingFrame,L),
	annotations_as_lists(AnnotType,Start,End,Rest,LR).

% Find the end of the range of an annotation
db_annotation_max(AnnotType, Strand,ReadingFrame,Max) :-
	Goal =.. [ AnnotType, _, _left, IncludeRight, Strand, ReadingFrame, _ ],
	findall(IncludeRight,Goal, ResultList),
	list_max(ResultList,Max).

% Find the beginning of the range of an annotation
db_annotation_min(AnnotType, Strand,ReadingFrame,Max) :-
	Goal =.. [ AnnotType, _, IncludeLeft, _right, Strand, ReadingFrame, _ ],
	findall(IncludeLeft,Goal, ResultList),
	list_min(ResultList,Max).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Various minor utility rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Possible strand and reading frame combinations

%% strand(+Strand)
%
% Strand in {+,-}
strand(+).
strand(-).

%% reading_frame(+Frame)
%
% Frame in {1,2,3}
reading_frame(1).
reading_frame(2).
reading_frame(3).

strand_reading_frame_combinations(Combinations) :-
	findall([S,R], (strand(S),reading_frame(R)), Combinations).

rm_seq_elems([],[]).
rm_seq_elems([[AnnotType,From,To,_]|Rest1],[[AnnotType,From,To]|Rest2]) :-
	rm_seq_elems(Rest1,Rest2).
