:- ['../lost.pl'].
:- ['../frameseq'].

% The salmonella test
% To avoid overfitting we train on a salmonella genome and 
% use the trained model to filter the predictions for an
% E. Coli. genome

delete_probability_step_size(0.2).

delete_probability_min(0.2).

delete_probability_max(1.0).

training_reference_file(F) :-
	predictions_reference_file(F).

training_predictions_file(F) :-
	predictions_file(F).

predictions_reference_file(F) :-
	lost_data_directory(DataDir),
	atom_concat(DataDir,'U00096.ptt.pl',F).

predictions_file(F) :-
	lost_data_directory(DataDir),
	atom_concat(DataDir,'genemark_report_ecoli.pl',F).

filtered_predictions_file(F,Id) :-
	lost_data_directory(DataDir),
	atom_integer(IdAtom,Id),
	atom_concat_list([DataDir,'ecoli_trained_predictions_',IdAtom,'.pl'],F).

filtered_predictions_accuracy_file(F,Id) :-
	lost_data_directory(DataDir),
	atom_integer(IdAtom,Id),
	atom_concat_list([DataDir,'ecoli_trained_accuracy_',IdAtom,'.pl'],F).

r_data_file(F) :-
	lost_data_directory(DataDir),
	atom_concat_list([DataDir,'r_data_ecoli_trained.tab'],F).
	
	test1 :-
		DelProb = 0.5,
		run_filtering_with_delete_prob(DelProb).

	run_filtering_with_delete_prob(P) :-
		set_option(override_delete_probability,P),
		training_reference_file(TrainingReferenceFile),
		training_predictions_file(TrainingPredictionsFile),
		predictions_reference_file(PredictionsReferenceFile),
		predictions_file(PredictionsFile),
		filtered_predictions_file(FiltPredFile,P),
		filtered_predictions_accuracy_file(FiltPredAccFile,P),
		train(TrainingReferenceFile, TrainingPredictionsFile, ModelFile), 
		filter(ModelFile, PredictionsFile, FiltPredFile),
		catch(evaluate(PredictionsReferenceFile, FiltPredFile, FiltPredAccFile),_,true). % Last file may not exist, because of no predictions

	run_filter_delete_prob_sequence :-
		delete_probability_sequence(S),
		forall(member(P,S),run_filtering_with_delete_prob(P)).

	delete_probability_sequence(Seq) :-
		delete_probability_min(Min),
		delete_probability_max(Max),
		delete_probability_step_size(StepSize),
		number_sequence(Min,Max,StepSize,Seq).

	% Creates a list of sequence of numbers... 
	number_sequence(Start,End,_,[End]) :- Start >= End.

	number_sequence(Start,End,Step,[Start|Rest]) :-
		Start < End,
		Next is Start + Step,
		number_sequence(Next,End,Step,Rest).

	create_r_data_file :-
		delete_probability_sequence(S),
		findall((100,P,F), (member(P,S), filtered_predictions_accuracy_file(F,P)),AllResults),
		write(AllResults),nl,
		r_data_file(RDataFile),
	        tell(RDataFile),
		create_r_data_header,
		delete_state_probability_experiment1_report(AllResults),
		told.

	create_r_data_header :-
		write('ScoreGroups'),
		write('\t'),
		write('DeleteProbability'),
		write('\t'),
		write('TotalPredicted'),
		write('\t'),
		write('StopsCorrect'),
		write('\t'),
		write('StopWrong'),
		write('\t'),
		write('StopSensitivity'),
		write('\t'),
		write('StopSpecificity'),
		write('\n').


	delete_state_probability_experiment1_report([]).

	% Some times the last file contains no predictions at all
	delete_state_probability_experiment1_report([(SGs,P,AccFile)|Rest]) :-
		not(file_exists(AccFile)),
		!.


	delete_state_probability_experiment1_report([(SGs,P,AccFile)|Rest]) :-
	        terms_from_file(AccFile,Terms),
	        member(accuracy_report(genes_predicted,TotalPredicted),Terms),
	        member(accuracy_report(gene_stops_correct,CorrectStops),Terms),
	        member(accuracy_report(gene_stops_wrong,WrongStops),Terms),
	        member(accuracy_report(gene_stop_sensitivity,SN),Terms),
	        member(accuracy_report(gene_stop_specificity,SP),Terms),
	        write(SGs),     write('\t'),
	        write(P), write('\t'),
	        write(TotalPredicted), write('\t'),
	        write(CorrectStops),write('\t'),
	        write(WrongStops),write('\t'),
	        write(SN), write('\t'),
	        write(SP),write('\n'),
	        delete_state_probability_experiment1_report(Rest).
