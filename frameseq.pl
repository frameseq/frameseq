:- ['lost'].

version(0.1).

:- 
   write('*****************************************************'),nl,
   write('* This is the frameseq model '),
   version(V), 
   write('version '), 
   write(V), 
   write('.          *'), nl,
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


filter(PredictionsFile,TrainingDataFile,FilteredPredictionsFile) :-
        run_model(framebias, 
                  annotate([PredictionsFile,TrainingDataFile], 
                           [], 
                           TmpResultsFile)),
        terms_from_file(TmpResultsFile,Predictions),
        terms_to_file(FilteredPredictionsFile,Predictions).

evaluate(GoldenStandardFile,PredictionsFile) :-
        run_model(accuracy_report, 
                  annotate([GoldenStandardFile,PredictionsFile], 
                           [],
                           AccuracyReport)),
                           readFile(AccuracyReport,Contents),
                           write(Contents),
                           nl.
