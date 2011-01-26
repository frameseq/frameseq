:- ['../../../lost.pl'].

:- lost_include_api(io).

create_data_file(ResultIndexFile,ResultsFile) :-
	tell(ResultsFile),
    terms_from_file(ResultIndexFile,ETerms),
	write('ScoreGroups\tDeleteProbability\tTotalPredicted\tStopsCorrect\tStopWrong\tStopSensitivity\sStopSpecificity\n'),
	delete_state_probability_experiment1_report(ETerms),
	told.

delete_state_probability_experiment1_report([]).
delete_state_probability_experiment1_report([experiment_result_index(SGs,P,AccFile)|Rest]) :-

	terms_from_file(AccFile,Terms),
	member(accuracy_report(genes_predicted,TotalPredicted),Terms),	
	member(accuracy_report(gene_stops_correct,CorrectStops),Terms),
	member(accuracy_report(gene_stops_wrong,WrongStops),Terms),
	member(accuracy_report(gene_stop_sensitivity,SN),Terms),
	member(accuracy_report(gene_stop_specificity,SP),Terms),
	write(SGs),	write('\t'),
	write(P), write('\t'),
	write(TotalPredicted), write('\t'),
	write(CorrectStops),write('\t'),
	write(WrongStops),write('\t'),
	write(SN), write('\t'),
	write(SP),write('\n'),
	delete_state_probability_experiment1_report(Rest).


