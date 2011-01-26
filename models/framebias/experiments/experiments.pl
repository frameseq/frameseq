:- ['../../../lost.pl'].
:- lost_include_api(misc_utils).

% This is the file that contains the "golden standard" genes
%verified_file(GeneFileProlog) :-
%        lost_data_file('nc000913_2_vecocyc_ptt',PttFile),
%        run_model(parser_ptt,annotate([PttFile],[],GeneFileProlog)).

% This is the list of predictions
%predictions_file(PredictionsFile) :-
%        lost_data_file('nc000913_2_all_urfs_for_real.pl',PredictionsFile).


%% Genemark filter:

genemark_filter(DeleteProbability,ScoreGroups,SplitAtTerminus) :- 
        % Genbank PTT file for "golden standard"
        lost_data_file('U00096_ptt',PttFile),
        run_model(parser_ptt,annotate([PttFile],[],GoldenStandardFile)),
        % Results from genemark with lowest possible threshold. Lots of
        % false positives.
        lost_data_file('genemark_lowest_threshold',ReportFile),
        run_model(genemark, parse([ReportFile],[],AllPredictionsFile)),
        run_model(best_prediction_per_stop_codon, annotate([AllPredictionsFile],[score_functor(start_codon_probability)],PredictionsFile)),
	run_filter(SplitAtTerminus,ScoreGroups,DeleteProbability,start_codon_probability,GoldenStandardFile,PredictionsFile,AccuracyFile),
        % This output is used to generate a list for use in generating
        % ROC curves 
	writeq(experiment_result_index(ScoreGroups,DeleteProbability,AccuracyFile)),write('.'),nl,
	write(AccuracyFile),nl.

soer_predict_filter(DeleteProbability,ScoreGroups,SplitAtTerminus) :- 
        % Genbank PTT file for "golden standard"
        lost_data_file('nc000913_2_vecocyc_ptt',PttFile),
        run_model(parser_ptt,annotate([PttFile],[],GoldenStandardFile)),
        % Results from genemark with lowest possible threshold. Lots of
        % false positives.
        lost_data_file('nc000913_2_all_urfs_for_real.pl',AllPredictionsFile),
        run_model(best_prediction_per_stop_codon, annotate([AllPredictionsFile],[score_functor(score)],PredictionsFile)),
	run_filter(SplitAtTerminus,ScoreGroups,DeleteProbability,start_codon_probability,GoldenStandardFile,PredictionsFile,AccuracyFile),
        % This output is used to generate a list for use in generating
        % ROC curves 
	writeq(experiment_result_index(ScoreGroups,DeleteProbability,AccuracyFile)),write('.'),nl,
	write(AccuracyFile),nl.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run_filter is an "easy" way of running the frame-bias model 
% It runs the model with a number of settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% In the case where we do not want to override estimated delete
% probability (this is usually the case, but not when generating 
% data for ROC curves).
run_filter(SplitGenome,Categories,ScoreFunctor,GF,PF,OutFile) :-
	run_filter(SplitGenome,Categories,false,ScoreFunctor,GF,PF,OutFile).
	        
run_filter(SplitGenome,Categories,DeleteProb,ScoreFunctor,GF,PF,AccuracyFile) :- 
        % Run the genome filter:
	((SplitGenome==true) ->
		run_model(genome_filter,
       		split_annotate([GF,PF],[terminus(1588800),origin(3923500),debug(true),score_categories(Categories),score_functor(ScoreFunctor),override_delete_probability(DeleteProb)],SelectedPredictionsFile))
		% Note, ter and ori is hardcoded for e-coli here
		;
		run_model(genome_filter,
       		annotate([GF,PF],[debug(true),score_categories(Categories),score_functor(score),override_delete_probability(DeleteProb)],SelectedPredictionsFile))
	),
        write('Wrote selected predictions to: '),
        write(SelectedPredictionsFile),nl,
        run_model(accuracy_report, annotate([GF,SelectedPredictionsFile],[start(1),end(max)],AccuracyFile)),
        write('Accuracy report is : '), write(AccuracyFile), nl,
	readFile(AccuracyFile,Contents),
	atom_codes(Atom,Contents),
	write(Atom),nl.
		

