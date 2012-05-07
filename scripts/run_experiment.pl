:- ['../lost.pl'].
:- ['../frameseq'].

%% run(Min,Max,Step,Model,GeneFinder,TrainOrganism,PredictOrganism)
% Min: min value for delete probability (usually 0)
% Max: max value for delete probability (usually 1)
% Step: How big increments to measure for delete probability 
%      (e.g. Min=0, Max=1, Step=0.1 will give you 10 measure points)
% Model: The name (filename without .psm) of the prism model to use
% GeneFinder: Genefinder to use (values glimmer,genemark or prodigal).
% TrainOrganism: The organism to train frameseq on
% PredictOrganism: The organism to predict on

run(Min,Max,Step,Model,GeneFinder,TrainOrganism,PredictOrganism) :-
        number_sequence(Min,Max,StepSize,Seq),
	findall((100,P,F), (
                        member(P,S),
                        run_filtering_with_delete_prob(P,Model,GeneFinder,TrainOrganism,PredictOrganism),
                        filtered_predictions_accuracy_file(P,Model,GeneFinder,TrainOrganism,PredictOrganism,F)
                ),AllResults),
	write(AllResults),nl,
	r_data_file(Model,GeneFinder,TrainOrganism,PredictOrganism,RDataFile),
        tell(RDataFile),
	create_r_data_header,
	delete_state_probability_experiment1_report(AllResults),
	told.

% Gene finder settings
genefinder_setting(genemark,prediction_functor,genemark_gene_prediction).
genefinder_setting(genemark,score_functor,start_codon_probability).
genefinder_setting(glimmer,prediction_functor,glimmer3_gene_prediction).
genefinder_setting(glimmer,score_functor,score).
genefinder_setting(prodigal,prediction_functor,prodigal_prediction).
genefinder_setting(prodigal,score_functor,score).

data_file(Basename,Fullname) :-
	lost_data_directory(DataDir),
        atom_concat(DataDir,Basename,Fullname).

%% training_reference_file(+Organism,-File)
training_reference_file(ecoli,F) :-
	data_file('NC_000913.ptt.pl',F).
training_reference_file(salmonella,F) :-
	data_file('salmonella_enterica.ptt.pl',F).
training_reference_file(legionella,F) :-
	data_file('legionella_pneumophila.ptt.pl',F).
training_reference_file(thermoplasma,F) :-
	data_file('thermoplasma_acidophilum.ptt.pl',F).
training_reference_file(bacillus,F) :-
	data_file('bacillus_subtilis.ptt.pl',F).

%% predictions_file(+Genefinder,+Organism,-File)
% Genemark:
predictions_file(genemark,ecoli,F) :-
	data_file('genemark_report_escherichia_coli.pl',F).
predictions_file(genemark,salmonella,F) :-
	data_file('genemark_report_salmonella_enterica.pl',F).
predictions_file(genemark,legionella,F) :-
	data_file('genemark_report_legionella_pneumophila.pl',F).
predictions_file(genemark,thermoplasma,F) :-
	data_file('genemark_report_thermoplasma_acidophilum.pl',F).
predictions_file(genemark,bacillus,F) :-
	data_file('genemark_report_bacillus_subtilis.pl',F).
% Prodigal:
predictions_file(prodigal,ecoli,F) :-
	data_file('NC_000913.Prodigal-2.50.pl',F).
% Glimmer:
predictions_file(glimmer,ecoli,F) :-
	data_file('NC_000913.Glimmer3.pl',F).

% predictions_reference_file(+Organism,-File)
predictions_reference_file(ecoli,F) :-
	data_file('NC_000913.ptt.pl',F).

filtered_predictions_file(Prob,Model,GeneFinder,TrainOrganism,PredictOrganism,F) :-
        lost_base_directory(BaseDir),
        atom_concat(BaseDir,'/results/',DataDir),
	atom_integer(IdAtom,Prob),
	atom_concat_list([DataDir,'predictions_',Model,'_',GeneFinder,'_',TrainOrganism,'_',PredictOrganism,'_',IdAtom,'.pl'],F).

filtered_predictions_accuracy_file(Prob,Model,GeneFinder,TrainOrganism,PredictOrganism,F) :-
        lost_base_directory(BaseDir),
        atom_concat(BaseDir,'/results/',DataDir),
	atom_integer(IdAtom,Prob),
	atom_concat_list([DataDir,'accuracy_',Model,'_',GeneFinder,'_',TrainOrganism,'_',PredictOrganism,'_',IdAtom,'.pl'],F).

r_data_file(Model,GeneFinder,TrainOrganism,PredictOrganism,F) :-
        lost_base_directory(BaseDir),
        atom_concat(BaseDir,'/results/',DataDir),
	atom_concat_list([DataDir,'stats_',Model,'_',GeneFinder,'_',TrainOrganism,'_',PredictOrganism,'.tab'],F).
	
run_filtering_with_delete_prob(P,Model,GeneFinder,TrainOrganism,PredictOrganism) :- 
        writeln(run_filtering_with_delete_prob(P,Model,GeneFinder,TrainOrganism,PredictOrganism)),
        genefinder_setting(GeneFinder,prediction_functor,PredictionFunctor),
        genefinder_setting(GeneFinder,score_functor,ScoreFunctor),
        set_option(score_functor,ScoreFunctor),
        set_option(prediction_functor,PredictionFunctor),
	set_option(override_delete_probability,P),
        set_option(model,Model),
	training_reference_file(TrainOrganism,TrainingReferenceFile),
	predictions_reference_file(PredictOrganism,PredictionsReferenceFile),
	predictions_file(GeneFinder,TrainOrganism,TrainingPredictionsFile),
        predictions_file(GeneFinder,PredictOrganism,PredictionsFile),
	filtered_predictions_file(P,Model,GeneFinder,TrainOrganism,PredictOrganism,FiltPredFile),
	filtered_predictions_accuracy_file(P,Model,GeneFinder,TrainOrganism,PredictOrganism,FiltPredAccFile),
        %writeln(training_predictions_file(TrainingPredictionsFile)),
        %writeln(training_reference_file(TrainingReferenceFile)),
        %writeln(predictions_file(FiltPredFile)),
        %writeln(accuracy_file(FiltPrefAccFile)),
	%writeln(train(TrainingReferenceFile, TrainingPredictionsFile, ModelFile)), 
	train(TrainingReferenceFile, TrainingPredictionsFile, ModelFile), 
	%writeln(filter(ModelFile, PredictionsFile, FiltPredFile)),
	filter(ModelFile, PredictionsFile, FiltPredFile),
	catch(evaluate(PredictionsReferenceFile, FiltPredFile, FiltPredAccFile),_,true). % Last file may not exist, because of no predictions
	

% Creates a list of sequence of numbers... 
number_sequence(Start,End,_,[End]) :- Start >= End.

number_sequence(Start,End,Step,[Start|Rest]) :-
	Start < End,
	Next is Start + Step,
	number_sequence(Next,End,Step,Rest).


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
delete_state_probability_experiment1_report([(_SGs,_P,AccFile)|Rest]) :-
	not(file_exists(AccFile)),
	!,
        delete_state_probability_experiment1_report(Rest).
	

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

