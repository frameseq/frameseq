:- ['../lost.pl'].
:- ['../frameseq'].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

reference_file('NC_000913.ptt.pl').
predictions_file('NC_000913.Glimmer3.pl').

score_functor(score).

data_points(100).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main goal: generate_roc_curve_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

generate_roc_curve_data :-
	data_points(DataPoints),
	reference_file(RefFileName),
	predictions_file(PredFileName),
	abs_file(RefFileName,RefFile),
	abs_file(PredFileName,PredictionsFile),
    terms_from_file(PredictionsFile,Predictions),
    % Extract all unique scores:
	score_functor(ScoreFunc),
    findall(Score,(member(P,Predictions),score_wrap(ScoreFunc,P,[Score,P])),Scores),
	list_max(Scores,MaxScore),
	list_min(Scores,MinScore),
	write(create_data_points(MinScore,MaxScore,DataPoints,DataPointsList)),nl,
	create_data_points(MinScore,MaxScore,DataPoints,DataPointsList),
	write(DataPointsList),nl,!,
	% Do cut-offs at each reported score and report accuracy for that cutoff
	select_and_report(RefFile,PredictionsFile,DataPointsList,Results),!,
	lost_data_directory(DataDir),
	atom_concat_list([DataDir,'threshold_select_',PredFileName],ResultsFile),!,
	write('Writing results file: '),write(ResultsFile), nl,
	open(ResultsFile,write,OStream),
	create_r_data_header(OStream),
	report_results_as_tabsep(OStream,Results),
	close(OStream).
	
	
create_r_data_header(S) :-
	write(S,'DeleteProbability'),
	write(S,'\t'),
	write(S,'StopsCorrect'),
	write(S,'\t'),
	write(S,'StopWrong'),
	write(S,'\t'),
	write(S,'StopSensitivity'),
	write(S,'\t'),
	write(S,'StopSpecificity'),
	write(S,'\n').

report_results_as_tabsep(_,[]).
report_results_as_tabsep(Stream,[[Score,AccReport]|Rest]) :-
	write(Stream,Score),
	write(Stream,'\t'),
	member(accuracy_report(gene_stops_correct,GeneStopsCorrect),AccReport),
	write(Stream,GeneStopsCorrect),
	write(Stream,'\t'),
	member(accuracy_report(gene_stops_wrong,GeneStopsWrong),AccReport),
	write(Stream,GeneStopsWrong),
	write(Stream,'\t'),
	member(accuracy_report(gene_stop_sensitivity,GeneStopSensitivity),AccReport),
	write(Stream,GeneStopSensitivity),
	write(Stream,'\t'),
	member(accuracy_report(gene_stop_specificity,GeneStopSpecificity),AccReport),
	write(Stream,GeneStopSpecificity),
	write(Stream,'\n'),
	report_results_as_tabsep(Stream,Rest).

create_data_points(_,_,0,[]).
create_data_points(Min,Max,DataPoints,[Min|DPs]) :-
	write('range:'),write(Range),nl,
	write('min:'), write(Min), nl,
	write('max:'), write(Max), nl,
	Range is Max - Min,
	Interval is Range / DataPoints,
	NextMin is Min + Interval,
	NextDataPoints  is DataPoints - 1,
	create_data_points(NextMin,Max,NextDataPoints,DPs).

select_and_report(_,_,[],[]).
select_and_report(GeneFileProlog,PredictionsFile,[Score|ScoresRest],[[Score,AccuracyReport]|AccRest]) :-
	write('Score cutoff: '),
	write(Score), 
	nl,
	score_functor(ScoreFunc),
    run_model(select_best_scoring, annotate([PredictionsFile], [score_threshold(Score),score_functor(ScoreFunc)], SelectedPredictionsFile)),
    run_model(accuracy_report, annotate([GeneFileProlog,SelectedPredictionsFile],[start(1),end(max),reports([gene_stops_correct,gene_stops_wrong,gene_stop_sensitivity,gene_stop_specificity])],AccuracyReportFile)),
	terms_from_file(AccuracyReportFile,AccuracyReport),
	select_and_report(GeneFileProlog,PredictionsFile,ScoresRest,AccRest).

score_wrap(ScoreFunctor,Prediction,[Score,Prediction]) :-
    Prediction =.. [ _Functor, _Id, _Left, _Right, _Strand, _Frame, Extra ], 
    ScoreMatcher =.. [ ScoreFunctor, Score ],
    member(ScoreMatcher,Extra).

abs_file(F,AF) :-
	lost_data_directory(D),
	atom_concat(D,F,AF).
