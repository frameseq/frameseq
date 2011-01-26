% Utilities for working with the genedb format.

gene_sequence_id(GeneRecord,SequenceId) :-
        GeneRecord =.. [ _PredFunctor, SequenceId,_Left,_Right,_Strand,_Frame,_Extra].

gene_left(GeneRecord,Left) :-
        GeneRecord =.. [ _PredFunctor, _SequenceId,Left,_Right,_Strand,_Frame,_Extra].

gene_right(GeneRecord,Right) :-
        GeneRecord =.. [ _PredFunctor, _SequenceId,_Left,Right,_Strand,_Frame,_Extra].

gene_strand(GeneRecord,Strand) :-
        GeneRecord =.. [ _PredFunctor, _SequenceId,_Left,_Right,Strand,_Frame,_Extra].

gene_frame(GeneRecord,Frame) :-
        GeneRecord =.. [ _PredFunctor, _SequenceId,_Left,_Right,_Strand,Frame,_Extra].
 
gene_extra_field(GeneRecord,Key,Value) :-
        GeneRecord =.. [_,_,_,_,_,_,Extra],
        Matcher =.. [ Key, Value ], 
        member(Matcher,Extra).

genedb_distinct_predictions(_,[],[]).

genedb_distinct_predictions(PredFunctor,[DistinctEnd|RestEnds],[PredictionsForEnd|RestPred]) :-
	genedb_predictions_for_stop_codon(PredFunctor,DistinctEnd,PredictionsForEnd),
	genedb_distinct_predictions(PredFunctor,RestEnds,RestPred).

genedb_distinct_stop_codons(PredFunctor,DistinctStops) :-
	ForwardStrand =.. [ PredFunctor, _id,_,StopCodonEnd,'+',Frame,_],
	ReverseStrand =.. [ PredFunctor, _id,StopCodonEnd,_,'-',Frame,_],
	findall([StopCodonEnd,'+',Frame], ForwardStrand, ForwardStops),
	findall([StopCodonEnd,'-',Frame], ReverseStrand, ReverseStops),
	append(ForwardStops,ReverseStops,AllStops),
	eliminate_duplicate(AllStops,DistinctStops).

genedb_predictions_for_stop_codon(PredFunctor,[StopCodonEnd,'+',Frame],Predictions) :-
	FindGoal =.. [ PredFunctor, _,  Start,StopCodonEnd,'+',Frame,Extra],
	BuildGoal =.. [ PredFunctor, _, Start,StopCodonEnd,'+',Frame,Extra],
	findall(BuildGoal,FindGoal,Predictions).

genedb_predictions_for_stop_codon(PredFunctor,[StopCodonEnd,'-',Frame],Predictions) :-
	FindGoal =.. [ PredFunctor, _, StopCodonEnd,End,'-',Frame,Extra],
	BuildGoal =.. [ PredFunctor, _, StopCodonEnd,End,'-',Frame,Extra],
	findall(BuildGoal,FindGoal,Predictions).

