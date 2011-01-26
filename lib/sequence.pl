% This is the place for various predicates for manipulating
% biological sequences.

% Require genecode for translation
:- lost_include_api(genecode).

% dna_seq_complement(++NucleotideSequence,--ReverseComplementedNucleotideSequence)
dna_seq_complement([],[]).

dna_seq_complement([N|NucleotidesRest],[NC|NCRest]) :-
	dna_complement(N,NC),
	dna_seq_complement(NucleotidesRest,NCRest).

dna_complement(a,t).
dna_complement(t,a).
dna_complement(g,c).
dna_complement(c,g).

% Translates a DNA sequence to a sequence of amino acids
% or vice versa: Produce all possible DNA sequences for
% a given amino acids sequence
dna_translate(_, [],[]).
dna_translate(Genecode, [C1,C2,C3|_], []) :-
	genecode(Genecode,[C1,C2,C3],'*'),
        !.
dna_translate(Genecode, [C1,C2,C3|DNARest], [AA|AARest]) :-
	genecode(Genecode,[C1,C2,C3],AA),
	dna_translate(Genecode,DNARest,AARest).

	
	
