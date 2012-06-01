:- ['../../lost.pl'].

test :- 
        normalize_predictions(['testdata2.pl','NC_000913.ptt.pl'],_,_).

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
        terms_from_file(PredictionsFile,Predictions),
        terms_from_file(ReferenceGenes,RefGenes),
        classify_predictions(Predictions,RefGenes,TruePositives,FalsePositives),
        length(FalsePositives,NumFalsePositives),
        length(TruePositives,NumTruePositives),
        writeln(true_positives(NumTruePositives)),
        writeln(false_positives(NumFalsePositives)),
        scores_from_predictions(start_codon_probability,TruePositives,TruePositiveScores),
        scores_from_predictions(start_codon_probability,FalsePositives,FalsePositiveScores),
        as_training_examples(TruePositiveScores,1,TrainingA),
        as_training_examples(FalsePositiveScores,0,TrainingB),
        append(TrainingA,TrainingB,TrainingExamples),
        writeln(TrainingExamples),
        gradient_descent(1000,0.5,1,1,TrainingExamples,A,B),
        writeln(final_a(A)),
        writeln(final_b(B)).

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
        sumlist(Errors,TotalError),
        % Update A 
        select_elems(Examples,1,As),   
        multiply_lists(Errors,As,ProductsA),
        sumlist(ProductsA,ErrorA),
        A1 is A - LearnRate * ErrorA,
        % Update B
        select_elems(Examples,2,Bs),
        multiply_lists(Errors,Bs,ProductsB),
        sumlist(ProductsB,ErrorB),
        B1 is B - LearnRate * ErrorB,
        example_costs(A1,B1,Examples,Costs),
        sumlist(Costs,TotalCost),
        writeln(iteration(N)),
        writeln(cost(TotalCost)),
        writeln(error(TotalError)),
        writeln(a(A)),
        writeln(b(B)),
        N1 is N - 1,
        !,
        gradient_descent(N1,LearnRate,A1,B1,Examples,A2,B2).

select_elems([],_,[]).
select_elems([X|Xs],N,[S|Ss]) :-
        nth1(N,X,S),
        !,
        select_elems(Xs,N,Ss).

multiply_lists([],[],[]).
multiply_lists([X|Xs],[Y|Ys],[Z|Zs]) :-
        Z is X * Y,
        !,
        multiply_lists(Xs,Ys,Zs).

/* probably will not need this:
min_and_max(ScoreFunc,[],Min,Max,Min,Max).
min_and_max(ScoreFunc,[P|Ps],MinIn,MaxIn,MinOut,MaxOut) :-
        P =.. [ _pred_functor, _genome, _left, _right, _strand, _frame, Extra ],
        ScoreMatch =.. [ ScoreFunc, Score ],
        member(ScoreMatch,Extra),
        ((Score =< MinIn) ->
                MinNext = Score
                ;
                MinNext = MinIn
        ),
        ((Score >= MaxOut) ->
                MaxNext = Score
                ;
                MaxNext = MaxIn),
        min_and_max(ScoreFunc,Ps,MinNext,MaxNext,MinOut,MaxOut).
*/


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
 
