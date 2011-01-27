:- ['lost'].

version(0.1).

:- 
   write('*****************************************************'),nl,
   write('* This is the frameseq model '),
   version(V), 
   write('version '), 
   write(V), 
   write('.           *'), nl,
   write('*                                                   *'),nl,
   write('* type h. to display information about this program *'),nl,
   write('*****************************************************'),
   nl.

:- write('Attempting to load options from file: options.pl ... '),nl,
   [options].

h :-
    readFile('README.markdown',ContentBytes),
    atom_codes(ContentStr,ContentBytes),
    write(ContentStr).

filter(TrainingDataFile,PredictionsFile,FilteredPredictionsFile) :-
        findall([K,V],option(K,V),OptsList),
        write(OptsList),nl,
        maplist(OptL,Opt,('=..'(Opt,OptL)),OptsList,Options),
    
        member(prediction_functor(PredictionFunctor), Options),
        member(score_functor(ScoreFunctor), Options),
    
        run_model(best_prediction_per_stop_codon,
                  annotate([PredictionsFile],
                           [prediction_functor(PredictionFunctor),
                            score_functor(ScoreFunctor)],
                           TrimmedPredictions)),
        
        (member(divide_genome(true),Options) ->
            run_model(framebias, 
                    split_annotate([TrainingDataFile,TrimmedPredictions],
                            Options,
                            TmpResultsFile))
            ;
            run_model(framebias,
                    annotate([TrainingDataFile,TrimmedPredictions],
                            Options,
                            TmpResultsFile))
        ),
        terms_from_file(TmpResultsFile,Predictions),
        write('Writing filtered predictions to file: '), write(FilteredPredictionsFile),nl,
        terms_to_file(FilteredPredictionsFile,Predictions).

evaluate(GoldenStandardFile,PredictionsFile,OutputFile) :-
        run_model(accuracy_report,
                  annotate([GoldenStandardFile,PredictionsFile], 
                           [],
                           AccuracyReport)),
        write('--------------- ACCURACY REPORT -----------------------'),nl,
        readFile(AccuracyReport,ContentBytes),
        atom_codes(Contents,ContentBytes),
        write(Contents),
        nl.
