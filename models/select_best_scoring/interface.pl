:- ['../../lost.pl'].
:- lost_include_api(interface).
:- lost_include_api(misc_utils).
:- lost_include_api(genedb).
:- lost_include_api(io).

lost_option(annotate,prediction_functor,auto,'The functor of the facts used in the prediction file. The default value \"auto\" means that the model will try to figure it out automatically').

lost_option(annotate,score_functor,auto,'The Extra list functor used to indicate the score of the prediction').
lost_option(annotate,number_of_predictions,auto,'The (maximal) number of predictions to include').
lost_option(annotate,score_threshold,auto,'Predictions with score below this threshold are eliminated').

lost_input_formats(annotate, [text(prolog(ranges(gene)))]).
lost_output_format(annotate, _, text(prolog(ranges(gene)))).

annotate([InputFile],Options,OutputFile) :-
        write(Options),nl,
        get_option(Options,score_functor,ScoreFunctor),
        get_option(Options,number_of_predictions,OptNumPredictions),
        get_option(Options,score_threshold,OptThreshold),
        terms_from_file(InputFile,Predictions), 
        (OptNumPredictions==auto->
                length(Predictions,NumPredictions)
                ;
                NumPredictions=OptNumPredictions),
        (OptThreshold==auto->
                GoodPredictions = Predictions 
                ;
                select_good_predictions(ScoreFunctor,OptThreshold,Predictions,GoodPredictions)),
        length(GoodPredictions,NumGoodPredictions),nl,
        sort_by_score(ScoreFunctor,GoodPredictions,ScoreSortedPredictions),
        % It is probably take again.. hmm..
        ((NumPredictions > NumGoodPredictions) ->
                NumToTake = NumGoodPredictions
                ;
                NumToTake = NumPredictions),
        take(NumToTake,ScoreSortedPredictions,SelectedPredictions),
        sort(SelectedPredictions,PosSortedSelectedPredictions),
        terms_to_file(OutputFile,PosSortedSelectedPredictions).

select_good_predictions(_,_,[],[]).
select_good_predictions(ScoreFunctor,Threshold,[P|Ps],[P|GPs]) :-
        score_wrap(ScoreFunctor,P,[Score,P]), % use score wrap to extract score
        Score > Threshold,
        !,
        select_good_predictions(ScoreFunctor,Threshold,Ps,GPs).
select_good_predictions(ScoreFunctor,Threshold,[_|Ps],GPs) :-
        select_good_predictions(ScoreFunctor,Threshold,Ps,GPs).

sort_by_score(ScoreFunctor,Predictions,ScoreSortedPredictions) :-
        map(score_wrap(ScoreFunctor,input,output),Predictions,ScoreWrappedPredictions),
        keysort(ScoreWrappedPredictions, ScoreWrappedSortedPredictions),
        reverse(ScoreWrappedSortedPredictions,BestFirstPredictions),
        terms_to_file('/tmp/keysorted.pl',ScoreWrappedSortedPredictions),
        map(score_wrap(ScoreFunctor,output,input),BestFirstPredictions,ScoreSortedPredictions).

score_wrap(ScoreFunctor,Prediction,[Score,Prediction]) :-
        Prediction =.. [ _Functor, _Id, _Left, _Right, _Strand, _Frame, Extra ], 
        ScoreMatcher =.. [ ScoreFunctor, Score ],
        member(ScoreMatcher,Extra).

