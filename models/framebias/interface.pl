:- ['../../lost.pl'].
:- lost_include_api(misc_utils).
:- lost_include_api(viterbi_learn).

lost_option(annotate,score_functor,score,'A functor that specifies a member of the Extra list in each prediction which has score').
lost_option(annotate,score_categories,50,'An integer specifying how many discrete groups to divide scores into').
lost_option(annotate,learn_method,prism,'Species which routine to use for learning. Options are prism and custom.').
lost_option(annotate,debug,false,'Whether to report debugging information.').
lost_option(annotate,override_delete_probability,false,'Lets the user manually override the delete probability').
lost_option(annotate,split_annotate,true,'Used to specify that the 


% Inherit options from annotate:
lost_option(split_annotate,Name,Default,Description) :-	lost_option(annotate,Name,Default,Description).
lost_option(split_annotate,terminus,0,'Specifies location of terminus on the genome.').
lost_option(split_annotate,terminus,0,'Specifies location of origin on the genome.').

lost_input_formats(annotate, [text(prolog(ranges(gene))), text(prolog(ranges(gene)))]).
lost_input_formats(split_annotate, [text(prolog(ranges(gene))), text(prolog(ranges(gene)))]).

lost_output_format(annotate, _,text(prolog(ranges(gene)))).
lost_output_format(split_annotate, _,text(prolog(ranges(gene)))).

set_debug(Options) :-
	get_option(Options,debug,DebugEnabled),
	% Set/unset debug mod
	((DebugEnabled==true) ->
		assert(debug_enabled(true))
		;
		assert(debug_enabled(false))).
		
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% annotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
%% annotate([GoldStdFile,PredictionsFile],Options,OutputFile)
% Annotate first initializes the model parameters.
% Then
% - converts input file to a sequence
% - runs viterbi on the sequence
% - Extract the sequence of visited states from the viterbi tree
% - Create a set of predictions from the sequence of visited states
% - write the set of predictions to OutputFile
annotate([GenbankFile,PredictionsFile],Options,OutputFile) :-
        write('annotate called'),nl,
        % Learn is always invoked before annotate (it's fast, so no worries)
        run_model(genome_filter,
                  learn([GenbankFile,PredictionsFile],Options,ParametersFile)),

        % Options hadling:
        get_option(Options,score_categories,NumScoreGroups),
        get_option(Options,score_functor,ScoreFunctor),
		get_option(Options,override_delete_probability,OverrideDelete),
		set_debug(Options),
		
        % Load model
        prism(genome_finder_nolist),
        assert(learn_mode(false)), % Tell model that we want to do predictions now
       % Load gene finder predictions
        terms_from_file(PredictionsFile,GeneFinderPredictionsUnsorted),
        % Make sure prediction are sorted
        sort(GeneFinderPredictionsUnsorted,GeneFinderPredictions),
        % Devise a score thresholding scheme and assign predictions a symbol based on their score
        frame_score_list_from_predictions(ScoreFunctor,GeneFinderPredictions,FrameScorePairs),
        scores_from_terms(ScoreFunctor,GeneFinderPredictions,Scores),
        threshold_list_from_scores(Scores,NumScoreGroups,ThresholdList),
        write('Created thresholding scheme: '), nl,
        write(ThresholdList),nl,
        threshold_discrete_frame_score_pairs(ThresholdList,FrameScorePairs,FrameScorePairsDiscrete),
        groups_from_count(NumScoreGroups,ScoreCategories),
        retractall(score_categories(_)),
        assert(score_categories(ScoreCategories)), % Tell prism how many score categories
        % Restore model parameters
        restore_sw(ParametersFile),
		% Override delete probability if requested
		((OverrideDelete==false) ->
			true
			;
			write('overriding delete probability: '),
			NotGotoDelete is 1 - OverrideDelete,
			set_sw(goto_delete,[OverrideDelete,NotGotoDelete])
		),
        show_sw,
        % Write model inputs to file:
        write('- writing model inputs file:'),
        lost_tmp_directory(TmpDir),
        atom_concat(TmpDir, 'genome_filter_model_inputs.pl', InputsFile),
        write(InputsFile),nl,
        terms_to_file(InputsFile,[input_sequence(FrameScorePairsDiscrete)]),
        %% Run viterbi on teh (frame,score) sequence of the sorted predictions
        write('- Runnning viterbi on prediction sequence:'),nl,
        viterbif(model(FrameScorePairsDiscrete),_,Expl),
        write('!! Done running viterbi'),nl,
        viterbi_switches(Expl,ExplSwitches),
        findall(X,member(msw(emit(X),_),ExplSwitches),AllStates),
        atom_concat(TmpDir,'genome_filter_model_states.pl',StatesFile),
        write('Writing model state sequence to file: '), write(StatesFile), nl,
        terms_to_file(StatesFile, [states(AllStates)]),nl,
        write('- Extracting predictions from state sequence to file: '),nl,
        write(OutputFile),nl,
        predictions_from_state_sequence(GeneFinderPredictions,AllStates,SelectedPredictions),
        terms_to_file(OutputFile,SelectedPredictions).

split_annotate([GenbankFile,PredictionsFile],Options,OutputFile) :-
	get_option(Options,origin,Origin),
	get_option(Options,terminus,Terminus),
	terms_from_file(GenbankFile,GBTerms),
	terminus_origin_split(Origin,Terminus,GBTerms,RefOriTer,RefTerOri),

	% Split predictions in two sets according to leading strand
	lost_tmp_directory(Tmp),
	atom_concat(Tmp, 'frame_bias_ref_ori_ter.pl',RefOriTerFile),
	write('RefOriTerFile: '), write(RefOriTerFile),nl,
	terms_to_file(RefOriTerFile,RefOriTer),
	atom_concat(Tmp, 'frame_bias_ref_ter_ori.pl',RefTerOriFile),
	write('RefTerOriFile: '), write(RefTerOriFile),nl,
	terms_to_file(RefTerOriFile,RefTerOri),

	% Split predictions in two sets according to leading strand
	terms_from_file(PredictionsFile,PredTerms),
	terminus_origin_split(Origin,Terminus,PredTerms,PredOriTer,PredTerOri),
	atom_concat(Tmp, 'frame_bias_pred_ori_ter.pl',PredOriTerFile),
	write('PredOriTerFile: '), write(PredOriTerFile),nl,
	terms_to_file(PredOriTerFile,PredOriTer),
	atom_concat(Tmp, 'frame_bias_pred_ter_ori.pl',PredTerOriFile),
	terms_to_file(PredTerOriFile,PredTerOri),
	write('PredTerOriFile: '), write(PredTerOriFile),nl,	

	delete(Options,terminus(_),Options1),
	delete(Options1,origin(_),Options2),
	
	write(run_model(genome_filter,annotate([RefOriTerFile,PredOriTerFile],Options2,OriTerResultFile))),nl,
	run_model(genome_filter,annotate([RefOriTerFile,PredOriTerFile],Options2,OriTerResultFile)),
	write(run_model(genome_filter,annotate([RefTerOriFile,PredTerOriFile],Options2,TerOriResultFile))),nl,
	run_model(genome_filter,annotate([RefTerOriFile,PredTerOriFile],Options2,TerOriResultFile)),
	
	terms_from_file(OriTerResultFile,OriTerResults),
	terms_from_file(TerOriResultFile,TerOriResults),

	append(OriTerResults,TerOriResults,AllResults),
	sort(AllResults,SortedResults),
	terms_to_file(OutputFile,SortedResults).
	
	
list_from_genbank_file(File,List) :-
        open(File,read,Stream),
        read(Stream,model(List)),
        close(Stream).

list_from_prediction_file(File,List) :-
        open(File,read,Stream),
        file_functor(File,Functor),
        list_from_stream(Functor,Stream,List),
        close(Stream).

%% Reads a file with predictions and produces them as a list
% Fixme: make functor configurable
% We need a functor name if the file contains multiple types of facts
list_from_stream(Functor,Stream,List) :-
        read(Stream,Term),
        ((Term == end_of_file) ->
                List = []
                ;
                functor(Term,F,_),
                ((F==Functor) ->
                    Term =.. [F,_id,_start,_end,Strand,Frame,_],
                    ((Strand == '+') ->
                        Frame6 = Frame
                        ;
                        Frame6 is 3 + Frame),
                    List = [Frame6|ListRest]
                    ;
                    List = ListRest),
                !,
                list_from_stream(Functor,Stream,ListRest)).


%% predictions_from_state_sequence(P,S,M).
% Given a set of predicitions P and corresponding 
% state sequence S generated by the model, M is
% the predictions except the ones generated in a delete state
predictions_from_state_sequence([],[],[]).

predictions_from_state_sequence([_|Ps],[delete|Ss],Ms) :-
       !,
       predictions_from_state_sequence(Ps,Ss,Ms). 

predictions_from_state_sequence([P|Ps],[S|Ss],[P|Ms]) :-
        S \= delete,
        !,
        predictions_from_state_sequence(Ps,Ss,Ms).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% learning of different probability distributions for the model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Decide which learning method to use
learn([GenbankFile,PredictionsFile],Options,OutputFile) :-
	get_option(Options,learn_method,LearnMethod),
	((LearnMethod==prism) ->
		learn_prism([GenbankFile,PredictionsFile],Options,OutputFile)
		;
		learn_custom([GenbankFile,PredictionsFile],Options,OutputFile)
	).

learn_prism([GenbankFile,PredictionsFile],Options,OutputFile) :-
       prism(genome_finder_nolist),
       assert(learn_mode(true)),
       get_option(Options, score_functor, ScoreFunctor),
       get_option(Options,score_categories,NumScoreGroups),
        set_debug(Options),
       terms_from_file(GenbankFile,RefGenesUnsorted),
       write('::: sorting genes in golden standard file'),nl,
       sort(RefGenesUnsorted,RefGenes),
       terms_from_file(PredictionsFile,Predictions),
       length(Predictions,PredictionCount),
       write('::: Determing thresholds for '), 
       write(PredictionCount),
       write(' genes.'),nl,
       scores_from_terms(ScoreFunctor,Predictions,Scores),
       threshold_list_from_scores(Scores,NumScoreGroups,ThresholdList),
	write('ThresholdList: '), nl,
	write(ThresholdList),nl,
        write('Classifying predictions into true and false positives.'),nl,
        classify_predictions(Predictions,RefGenes,ClassifiedPredictions),
        write('Create frame/score input list for model.'),nl,
        frame_score_list_from_predictions(ScoreFunctor,ClassifiedPredictions,PredictionScorePairs),
        write('Discretizing scores from gene finder.'),nl,
        threshold_discrete_frame_score_pairs(ThresholdList,PredictionScorePairs,PredictionScorePairsDiscrete),
        write('Determining number of score categories'),nl,
        groups_from_count(NumScoreGroups,ScoreCategories),
        assert(score_categories(ScoreCategories)),
        terms_to_file('test.file',PredictionScorePairsDiscrete),
        write('before learning: '),nl,
        assert(learn_mode(true)),
        learn([model(PredictionScorePairsDiscrete)]),
        show_sw,
        write('Saving parameters to file: '), write(OutputFile), nl,
        save_sw(OutputFile),nl,
        retractall(learn_mode(_)).

learn_custom([GenbankFile,PredictionsFile],Options,OutputFile) :-
       prism(genome_finder),
       get_option(Options, score_functor, ScoreFunctor),
       get_option(Options,score_categories,NumScoreGroups),
       terms_from_file(GenbankFile,RefGenesUnsorted),
       write('::: sorting genes in golden standard file'),nl,
       sort(RefGenesUnsorted,RefGenes),
       terms_from_file(PredictionsFile,Predictions),
       write('::: learning frame transitions...'),nl,
       learn_frame_transitions(RefGenes),
       write('::: learning delete transition probability...'),nl,
       learn_delete_transition_probability(RefGenes,Predictions),
       write('::: learning terminate transition probability...'),nl,
       learn_terminate_probability(Predictions),
       write('::: learning emission probabilities...'),nl,
       learn_emission_probabilities(ScoreFunctor,RefGenes,NumScoreGroups,Predictions),
       show_sw,
       write('Saving parameters to file: '), write(OutputFile), nl,
       save_sw(OutputFile),nl,
       retractall(learn_mode(_)).

learn_delete_transition_probability(RefGenes,Predictions) :-
        length(RefGenes,RefGenesLen),
        length(Predictions,PredictionsLen),
        split_predictions(Predictions,RefGenes,Correct,Incorrect),
        length(Incorrect,IncorrectLen),
        P_incorrect is IncorrectLen /  PredictionsLen,
        write(P_incorrect),nl,
        NoDeleteProb is 1 - P_incorrect,
%        NoDeleteProb is (RefGenesLen / PredictionsLen),
        DeleteProb is 1-NoDeleteProb,
        set_sw(goto_delete,[DeleteProb,NoDeleteProb]).

%%
% Initialize the probability of termination to be 1 / #predictions
% Is this really a good way of doing it?
% For viterbi it does not really matter much...  
learn_terminate_probability(Predictions) :-
       length(Predictions,PredictionsLength),
       TerminateProb is 1 / PredictionsLength,
       NoTerminateProb is 1 - TerminateProb,
       set_sw(terminate,[TerminateProb,NoTerminateProb]).

learn_frame_transitions(GenbankTerms) :-
        % first, fix delete prob and score categories probs to zero 
        % in order to learn transition probabilities only
        toggle_disable_delete(yes),
        %fix_sw(goto_delete, [0,1]),
  %      terms_from_file(GenbankFile,GenbankTerms),
        frame_list_from_genbank_terms(GenbankTerms,FrameList),
        assert(score_categories([0])),

        map(add_unit_score,FrameList,ObservationList),
        learn([model(ObservationList)]),
        retract(score_categories(_)).
        toggle_disable_delete(no).
% where:
        add_unit_score(E,(E,0)).

% Learning the emission probabilities
learn_emission_probabilities(ScoreFunctor,RefGenes,Predictions) :-
        retractall(score_categories(_)),
       % Discretize scores:
        number_of_score_categories(NumScoreGroups),
        scores_from_terms(ScoreFunctor,Predictions,Scores),
        threshold_list_from_scores(Scores,NumScoreGroups,ThresholdList),
		write('ThresholdList: '), nl,
		write(ThresholdList),nl,
        split_predictions(Predictions,RefGenes,Correct,Incorrect),
        frame_score_list_from_predictions(ScoreFunctor,Correct,CorrectFrameScorePairs),
        frame_score_list_from_predictions(ScoreFunctor,Incorrect,IncorrectFrameScorePairs),
        threshold_discrete_frame_score_pairs(ThresholdList,CorrectFrameScorePairs,CorrectFrameScorePairsDiscrete),
        threshold_discrete_frame_score_pairs(ThresholdList,IncorrectFrameScorePairs,IncorrectFrameScorePairsDiscrete),
        groups_from_count(NumScoreGroups,ScoreCategories),
        assert(score_categories(ScoreCategories)),
        listing(score_categories/1),
        write('learning frame emission probabilities'),nl,
        learn_frame_emit_probs(CorrectFrameScorePairsDiscrete),
        write('learning delete emission probabilities'),nl,
        learn_delete_emit_probs(IncorrectFrameScorePairsDiscrete).

learn_frame_emit_probs(FrameScorePairs) :-
        as_frame_emit_goals(FrameScorePairs, PGoals),
        learn(PGoals).
% where:       
  as_frame_emit_goals([],[]).
  as_frame_emit_goals([(F,S)|R1],[dummy_pgoal(emit(F),S)|R2]) :-
        as_frame_emit_goals(R1,R2).

learn_delete_emit_probs(FrameScorePairs) :-
        as_dummy_pgoals(emit(delete),FrameScorePairs, PGoals),
        learn(PGoals).
% where: 
  as_dummy_pgoals(_,[],[]).
  as_dummy_pgoals(SwName,[O|R1],[dummy_pgoal(SwName,O)|R2]) :-
      as_dummy_pgoals(SwName,R1,R2).

% Create a list of frames from genbank terms
frame_list_from_genbank_terms([],[]).
frame_list_from_genbank_terms([T|Ts],[F|Fs]) :-
        T =.. [ _gb, _identifier, _start, _stop, Strand, Frame, _ ], 
        ((Strand == '+') ->
                F = Frame
                ;
                F is Frame + 3),
        !,
        frame_list_from_genbank_terms(Ts,Fs).


% create a list of (frame,score) pairs from a list of predictions
frame_score_list_from_predictions(_, [],[]).

frame_score_list_from_predictions(ScoreFunctor,[true_positive(T)|Ts],[true_positive(F,Score)|Fs]) :-
        frame_score_list_from_predictions(ScoreFunctor,[T|Ts],[(F,Score)|Fs]).

frame_score_list_from_predictions(ScoreFunctor,[false_positive(T)|Ts],[false_positive(F,Score)|Fs]) :-
        frame_score_list_from_predictions(ScoreFunctor,[T|Ts],[(F,Score)|Fs]).

frame_score_list_from_predictions(ScoreFunctor,[T|Ts],[(F,Score)|Fs]) :-
        T =.. [ _ftor,_id, _left, _right, Strand, Frame, Extra ], 
        MatchScore =.. [ ScoreFunctor, Score ],
        member(MatchScore,Extra),
        ((Strand == '+') ->
                F = Frame
                ;
                F is Frame + 3),
        !,
        frame_score_list_from_predictions(ScoreFunctor,Ts,Fs).


% tag predictions as true positives or false positives

classify_predictions([],_,[]).

classify_predictions([P|PredictionsRest],RefGenes,[true_positive(P)|TaggedRest]) :-
        P =.. [_,_,L,R,S,_,_],
        RefGenes = [Ref1|_],
        Ref1 =.. [ RefFunctor | _ ],
        ((S=='+') ->
        	Match =.. [RefFunctor,_,_,R,S,_,_]
           	;
                Match =.. [RefFunctor,_,L,_,S,_,_]),
        member(Match,RefGenes),
        !,
   	classify_predictions(PredictionsRest,RefGenes,TaggedRest).

classify_predictions([P|PredictionsRest],RefGenes,[false_positive(P)|TaggedRest]) :-
        !,
        classify_predictions(PredictionsRest,RefGenes,TaggedRest).
 

% split predictions into a correct set and a wrong set
% Correct means that the prediction have a correct stop codon
% An entry in the list RefGenes is expected to look something like: gb(U00096,190,255,+,1,[...])
split_predictions([],_,[],[]).

split_predictions([P|PredictionsRest],RefGenes,[P|CorrectRest],Incorrect) :-
        P =.. [_,_,L,R,S,_,_],
        RefGenes = [Ref1|_],
        Ref1 =.. [ RefFunctor | _ ],
        ((S=='+') ->
        	Match =.. [RefFunctor,_,_,R,S,_,_]
           	;
            Match =.. [RefFunctor,_,L,_,S,_,_]),
   		member(Match,RefGenes),
   		!,
   		split_predictions(PredictionsRest,RefGenes,CorrectRest,Incorrect).

split_predictions([P|PredictionsRest],RefGenes,Correct,[P|IncorrectRest]) :-
        !,
        split_predictions(PredictionsRest,RefGenes,Correct,IncorrectRest).
        
         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Discretizing scores
% Each range of scores is converted into a symbolic value
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 
% 
threshold_discrete_frame_score_pairs(_,[],[]).

% These two rules are used with annotated (learning) data
threshold_discrete_frame_score_pairs(Thresholds,[true_positive(F,S)|R1],[true_positive(F,DS)|R2]) :-
        threshold_discrete_frame_score_pairs(Thresholds,[(F,S)|R1],[(F,DS)|R2]).
threshold_discrete_frame_score_pairs(Thresholds,[false_positive(F,S)|R1],[false_positive(F,DS)|R2]) :-
        threshold_discrete_frame_score_pairs(Thresholds,[(F,S)|R1],[(F,DS)|R2]).

threshold_discrete_frame_score_pairs(Thresholds,[(F,S)|R1],[(F,DS)|R2]) :-
       threshold_group(Thresholds,S,DS),
       !,
       threshold_discrete_frame_score_pairs(Thresholds,R1,R2).

threshold_group(Thresholds,Score,Group) :-
        threshold_group_rec(1,Thresholds,Score,Group).

threshold_group_rec(N,[],_,N).
threshold_group_rec(N,[T|TR],Score,Group) :-
        Score > T,
        !,
        N1 is N + 1,
        threshold_group_rec(N1,TR,Score,Group).
threshold_group_rec(N,[T|_],Score,N) :-
        Score =< T.

groups_from_count(Count,GroupsList) :-
        rev_groups_from_count(Count,GroupsListRev),
        reverse(GroupsListRev,GroupsList).

rev_groups_from_count(0,[]).
rev_groups_from_count(Count,[Count|GroupsRest]) :-
        NewCount is Count - 1,
        rev_groups_from_count(NewCount,GroupsRest).

threshold_list_from_scores(Scores,NumGroups,ThresholdsList) :-
        sort('=<',Scores,SortedScores),
        NumThresholds is NumGroups - 1,
        length(Scores,NumScores),
        GroupSize is round(0.5 + (NumScores / NumGroups)),
        write('group size is '), write(GroupSize),nl,
        mk_threshold_list(GroupSize,SortedScores,ThresholdsList).

mk_threshold_list(GroupSize,SortedScores,[ThresholdScore|TSRest]) :-
       length(SortedScores,SortedScoresLength),
       SortedScoresLength > GroupSize,
       !,
       split_list(GroupSize,SortedScores,_,Tail),
       Tail = [ThresholdScore|_],
       mk_threshold_list(GroupSize,Tail,TSRest).

mk_threshold_list(_,_,[]).

% Extract scores from genemark prediction terms
scores_from_terms(_,[],[]).
scores_from_terms(ScoreFunctor,[T|Ts],[S|Ss]) :-
        score_from_prediction_term(ScoreFunctor,T,S),
        !,
        scores_from_terms(ScoreFunctor,Ts,Ss).
scores_from_terms(ScoreFunctor,[_|Ts],Ss) :-
        scores_from_terms(ScoreFunctor,Ts,Ss).

score_from_prediction_term(ScoreFunctor,T,S) :-
        T =.. [ _functor, _id, _left, _right, _strand, _frame, Extra],
		ScoreMatcher =.. [ ScoreFunctor, S ],
        member(ScoreMatcher,Extra).

%%%%%%%%%%%%% Maximal dist between TPs  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

max_tp_distance(_TPs, [], _, 0).

% Case 1: prediction matches a true positive
max_tp_distance([FirstTP|TPs], [Prediction|PredictionsRest] , CurrentDist, MaxDist) :-  
    Prediction =.. [ _ftor, _id, L, R, Strand,Frame, _extra], 
    FirstTP =.. [ _, _, L, R, Strand, Frame, _],
    !,
    max_tp_distance(TPs,PredictionsRest,0,MaxDistRest),
    max(CurrentDist,MaxDistRest,MaxDist).

% Case 3: A missed true positive
max_tp_distance([FirstTP|TPs], [Prediction|PredictionsRest] , CurrentDist, MaxDist) :-  
    Prediction =.. [_,_,L1, _,_,_,_], 
    FirstTP =.. [_,_,L2,_,_,_,_],
    L1 >= L2,
    max_tp_distance(TPs,[Prediction|PredictionsRest], CurrentDist, MaxDist).

% Case 3: Prediction does not match a true positive
max_tp_distance(TPs, [_|PredictionsRest], CurrentDist, MaxDist) :-
        NextCurrentDist is CurrentDist + 1,
        max_tp_distance(TPs,PredictionsRest, NextCurrentDist, MaxDist).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Separate data into ter-ori list and ori-ter list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% terminus_origin_split(+Origin,+Terminus,+GeneList,-OriginTerminusList,-TerminusOriginList)
% Splits a list of gene-(s/-predictions) into two lists:
% one with genes starting after/on and before Origin and Terminus: 
% One with genes staring after/on terminus and before Origin

terminus_origin_split(_,_,[],[],[]).

terminus_origin_split(Origin,Terminus,Genes,OriTer,TerOri) :-
	Origin > Terminus,
	terminus_origin_split(Terminus,Origin,Genes,TerOri,OriTer).

% Case 1: Forward strand, gene between origin and terminus
terminus_origin_split(Origin,Terminus,[Gene|GenesRest],[Gene|OriTerRest],TerOri) :-
	Gene =.. [ GeneFunctor, _identifier, Left, Right, '+', _Frame, _Extra],
	Left >= Origin,
	Left < Terminus,
	%write([1,Left,Right,Origin,Terminus]),nl,	
	terminus_origin_split(Origin,Terminus,GenesRest,OriTerRest,TerOri).
	
terminus_origin_split(Origin,Terminus,[Gene|GenesRest],[Gene|OriTerRest],TerOri) :-
	Gene =.. [ GeneFunctor, _identifier, Left, Right, '-', _Frame, _Extra],
	Right >= Origin,
	Right < Terminus,
	%write([2,Left,Right,Origin,Terminus]),nl,
	terminus_origin_split(Origin,Terminus,GenesRest,OriTerRest,TerOri).

terminus_origin_split(Origin,Terminus,[Gene|GenesRest],OriTer,[Gene|TerOriRest]) :-
	Gene =.. [ GeneFunctor, _identifier, Left, Right, _, _Frame, _Extra],
	%write([3,Left,Right,Origin,Terminus]),nl,
	terminus_origin_split(Origin,Terminus,GenesRest,OriTer,TerOriRest).
	
elements_with_functor(_,[],[]).
	elements_with_functor(F,[E|ERest],[E|CRest]) :-
	E =.. [ F | _ ],
	!,
	elements_with_functor(F,ERest,CRest).

elements_with_functor(F,[_|ERest],CRest) :-
	!,
	elements_with_functor(F,ERest,CRest).
