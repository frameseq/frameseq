:- ['../../lost.pl'].

test :- 
        normalize_predictions(['testdata2.pl','NC_000913.ptt.pl'],[iterations(100),learning_rate(0.001),score_functor(start_codon_probability)],'normalized.pl').

/*
merge_predictions(InputFiles, Options, OutputFile) :-
        findall(Predictions,
                (member(F,InputFiles),
                terms_from_file(F,Predictions)),
                AllPredictions),
        get_option(score_functors,Functors),
        normalize_predictions(AllPredictions,Functors,NormPredictions),
        flatten(NormPredictions,FlatNormPredictions),
        terms_to_file(OutputFile,FlatNormPredictions).
*/

normalize_predictions([PredictionsFile,ReferenceGenes],Options,NormPredictionsFile) :-
        get_option(Options,learning_rate,LearnRate),
        get_option(Options,score_functor,ScoreFunctor),
        get_option(Options,iterations,Iterations),
        terms_from_file(PredictionsFile,Predictions),
        terms_from_file(ReferenceGenes,RefGenes),
        classify_predictions(Predictions,RefGenes,TruePositives,FalsePositives),
        length(FalsePositives,NumFalsePositives),
        length(TruePositives,NumTruePositives),
        writeln(true_positives(NumTruePositives)),
        writeln(false_positives(NumFalsePositives)),
        scores_from_predictions(ScoreFunctor,TruePositives,TruePositiveScores),
        scores_from_predictions(ScoreFunctor,FalsePositives,FalsePositiveScores),
        length(TruePositiveScores,TPLEN),
        length(FalsePositiveScores,FPLEN),
        sumlist(TruePositiveScores,TPTotal),
        sumlist(FalsePositiveScores,FPTotal),
        TPMean is TPTotal / TPLEN,
        FPMean is FPTotal / FPLEN,
        writeln(tp_mean(TPMean)),
        writeln(fp_mean(FPMean)),
        as_training_examples(TruePositiveScores,1,TrainingA),
        as_training_examples(FalsePositiveScores,0,TrainingB),
        append(TrainingA,TrainingB,TrainingExamples),
        %writeln(TrainingExamples),
        gradient_descent(Iterations,LearnRate,0,0,TrainingExamples,A,B),!,
        writeln(final_a(A)),
        writeln(final_b(B)),
        open(NormPredictionsFile,write,OutStream),
        write_normalized_predictions(A,B,ScoreFunctor,score,Predictions,OutStream),
        close(OutStream).


write_normalized_predictions(_,_,_,_,[],_).
write_normalized_predictions(A,B,OldScoreFunctor,NewScoreFunctor,[P|Ps],Stream) :-
       P =.. [_,_,Left,Right,Strand,Frame,Extra],
       ScoreMatch =.. [ OldScoreFunctor, OldScore ],
       member(ScoreMatch,Extra),
       logistic_function(A,B,OldScore,NewScore),
       NewP =.. [ prediction, Left, Right, Strand, Frame, [ score(NewScore), old_score(OldScore) ]],
       write(Stream,NewP),
       write(Stream,'.\n'),
       !,
       write_normalized_predictions(A,B,OldScoreFunctor,NewScoreFunctor,Ps,Stream).


as_training_examples([],_,[]).
as_training_examples([S|Ss],Label,[[S,Label]|Ts]) :-
        as_training_examples(Ss,Label,Ts).

scores_from_predictions(_,[],[]).
scores_from_predictions(ScoreFunctor,[P|Ps],[S|Ss]) :-
        P =.. [_,_,_,_,_,_,E],
        ScoreMatch =.. [ ScoreFunctor, S ],
        member(ScoreMatch,E),
        !,
        scores_from_predictions(ScoreFunctor,Ps,Ss).

logistic_function(A,B,X,Y) :-
       Y is 1 / (1 + exp(-(A + B*X))).

cost_function(A,B,X,0,Cost) :-
        logistic_function(A,B,X,H),
        Cost is -log(1-H).
cost_function(A,B,X,1,Cost) :-
        logistic_function(A,B,X,H),
        Cost is -log(H).

example_costs(_A,_B,[],[]).
example_costs(A,B,[[X,Y]|ExRest],[Cost|CostRest]) :-
        cost_function(A,B,X,Y,Cost),
        !,
        example_costs(A,B,ExRest,CostRest).

prediction_errors(_A,_B,[],[]).
prediction_errors(A,B,[[X,Y]|ExRest],[Err|ErrRest]) :-
        logistic_function(A,B,X,Y1),
        Err is Y1 - Y,
        !,
        prediction_errors(A,B,ExRest,ErrRest).

gradient_descent(0,_LearnRate,A,B,_Examples,A,B).
gradient_descent(N,LearnRate,A,B,Examples,A2,B2) :-
        prediction_errors(A,B,Examples,Errors),
        squared_list(Errors,SquaredErrors),
        sumlist(SquaredErrors,SquaredError),
        % Update A
        length(Examples,NumEx),
        ones(NumEx,Ones),
        multiply_lists(Errors,Ones,ProductsA),
        sumlist(ProductsA,ErrorA),
        A1 is A - (LearnRate * ErrorA),
        % Update B
        select_elems(Examples,1,Bs),
        multiply_lists(Errors,Bs,ProductsB),
        sumlist(ProductsB,ErrorB),
        B1 is B - (LearnRate * ErrorB),
        example_costs(A1,B1,Examples,Costs),
        sumlist(Costs,TotalCost),
        writeln(iteration_error(N,SquaredError)),
        %writeln(cost(TotalCost)),
        %writeln(error(SquaredError)),
        %writeln(a(A)),
        %writeln(b(B)),
        N1 is N - 1,
        !,
        gradient_descent(N1,LearnRate,A1,B1,Examples,A2,B2).


ones(0,[]).
ones(N,[1|RestOnes]) :-
        N>0,
        N1 is N - 1,
        ones(N1,RestOnes).

select_elems([],_,[]).
select_elems([X|Xs],N,[S|Ss]) :-
        nth1(N,X,S),
        !,
        select_elems(Xs,N,Ss).

squared_list([],[]).
squared_list([X|Xs],[Y|Ys]) :-
        Y is X * X, 
        !,
        squared_list(Xs,Ys).

multiply_lists([],[],[]).
multiply_lists([X|Xs],[Y|Ys],[Z|Zs]) :-
        Z is X * Y,
        !,
        multiply_lists(Xs,Ys,Zs).


% tag predictions as true positives or false positives

classify_predictions([],_,[],[]).

classify_predictions([P|PredictionsRest],RefGenes,[P|TrueRest],FalseRest) :-
        P =.. [_,_,L,R,S,_,_],
        RefGenes = [Ref1|_],
        Ref1 =.. [ RefFunctor | _ ],
        ((S=='+') ->
        	Match =.. [RefFunctor,_,_,R,S,_,_]
           	;
            Match =.. [RefFunctor,_,L,_,S,_,_]),
        member(Match,RefGenes),
        !,
   	classify_predictions(PredictionsRest,RefGenes,TrueRest,FalseRest).

classify_predictions([P|PredictionsRest],RefGenes,TrueRest,[P|FalseRest]) :-
        !,
        classify_predictions(PredictionsRest,RefGenes,TrueRest,FalseRest).
 
