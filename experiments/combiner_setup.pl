:- ['../lost.pl'].

:- lost_include_api(prodigal).

prodigal_to_prolog(ProdigalFile, PrologFile) :-
        parse_prodigal_file(ProdigalFile, PrologFile).

setup_prodigal(NormalizedPredictions) :-
        lost_data_directory(Dir),
        atom_concat_list([Dir, 'NC_000913.ptt.pl'],RefSeq),
        prodigal_to_prolog('../data/NC_000913.Prodigal-2.50', '../data/NC_000913.Prodigal-2.50.pl'),
        atom_concat_list([Dir, 'NC_000913.Prodigal-2.50.pl'],ProdigalPredictions),

        run_model(best_prediction_per_stop_codon,
                        annotate([ProdigalPredictions],[score_functor(score)],ProdigalPredictionsBest)),

        run_model(normalize_predictions,
                        normalize_predictions([ProdigalPredictionsBest,RefSeq],
                                              [iterations(1000),learning_rate(0.000001),score_functor(score)],
                                              NormalizedPredictions)),
        writeln(normalized_predictions(NormalizedPredictions)).

setup_glimmer(NormalizedPredictions) :-
        lost_data_directory(Dir),
        atom_concat_list([Dir, 'NC_000913.ptt.pl'],RefSeq),
        atom_concat_list([Dir, 'NC_000913.Glimmer3.pl'],GlimmerPredictions),

        run_model(best_prediction_per_stop_codon,
                        annotate([GlimmerPredictions],[score_functor(score)],GlimmerPredictionsBest)),

        run_model(normalize_predictions,
                        normalize_predictions([GlimmerPredictionsBest,RefSeq],
                                              [iterations(1000),learning_rate(0.0001),score_functor(score)],
                                              NormalizedPredictions)),
        writeln(normalized_predictions(NormalizedPredictions)).

setup_genemark(NormalizedPredictions) :-
        lost_data_directory(Dir),
        atom_concat_list([Dir, 'NC_000913.ptt.pl'],RefSeq),
        atom_concat_list([Dir, 'NC_000913.GeneMark-2.5m.pl'],GlimmerPredictions),

        run_model(best_prediction_per_stop_codon,
                        annotate([GlimmerPredictions],[score_functor(start_codon_probability)],GlimmerPredictionsBest)),

        run_model(normalize_predictions,
                        normalize_predictions([GlimmerPredictionsBest,RefSeq],
                                              [iterations(1000),learning_rate(0.00005),score_functor(start_codon_probability)],
                                              NormalizedPredictions)),
        writeln(normalized_predictions(NormalizedPredictions)).

setup_all :-
        setup_prodigal(F1),
        setup_genemark(F2),
        setup_glimmer(F3),
        run_model(merge_predictions,
                        merge([F1,F2,F3],[],Merged)),
        writeln(Merged),
        terms_from_file(Merged,MergedTerms),
        terms_to_file('../data/all_on_ecoli.pl',MergedTerms).


