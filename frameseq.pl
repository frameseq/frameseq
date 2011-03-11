:- catch(lost_api_loaded(interface),_,consult('lost.pl')).

version(0.2).

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

:- write('Attempting to load options from file: '),
   lost_config(lost_base_directory,BaseDir),
   atom_concat(BaseDir,'options.pl',OptionsFile),
   write(OptionsFile), 
   terms_from_file(OptionsFile,Options),
   forall(member(Opt,Options),assert(Opt)),
   write('\tdone.').

% Setting options dynamically
set_option(Key,Value) :-
	retractall(option(Key,_)),
	assert(option(Key,Value)).

h :-
    readFile('README.markdown',ContentBytes),
    atom_codes(ContentStr,ContentBytes),
    write(ContentStr).

train(ReferenceFile,PredictionsFile,ParameterFile) :-
		(var(ParameterFile) ->
			true ;
			write('ModelFile will be determined by the system, please supply a variable instead.'),nl,fail),
       	findall([K,V],option(K,V),OptsList),
        write(OptsList),nl,
        maplist(OptL,Opt,('=..'(Opt,OptL)),OptsList,Options),

		
    
        member(prediction_functor(PredictionFunctor), Options),
        member(score_functor(ScoreFunctor), Options),

        run_model(best_prediction_per_stop_codon,
                  annotate([PredictionsFile],
                           [prediction_functor(PredictionFunctor),
                           score_functor(ScoreFunctor)],
                           TrimmedPredictionsFile)),

        run_model(framebias,
                  learn([ReferenceFile,TrimmedPredictionsFile],
                         Options,
                         ParameterFile)).

filter(ParameterFile,PredictionsFile,FilteredPredictionsFile) :-
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
        
        run_model(framebias,
                  annotate([ParameterFile,TrimmedPredictions],
                            Options,
                            TmpResultsFile)),

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
		writeFile(OutputFile,ContentBytes),
        write(Contents),
        nl.
