/** <module> Genecode Table
 genecode.pl
table 11 : bacterial
*/

%% genecode(+TableNum,?Codon,?AA)
%
% This predicate defines the relationship between amino acids and codon with respect
% to TableNum

genecode(11,[t,t,t],f).
genecode(11,[t,c,t],s).
genecode(11,[t,a,t],y).
genecode(11,[t,g,t],c).
genecode(11,[t,t,c],f).
genecode(11,[t,c,c],s).
genecode(11,[t,a,c],y).
genecode(11,[t,g,c],c).
genecode(11,[t,t,a],l).
genecode(11,[t,c,a],s).
genecode(11,[t,a,a],'*').
genecode(11,[t,g,a],'*').
genecode(11,[t,t,g],l).
genecode(11,[t,c,g],s).
genecode(11,[t,a,g],'*').
genecode(11,[t,g,g],w).
genecode(11,[c,t,t],l).
genecode(11,[c,c,t],p).
genecode(11,[c,a,t],h).
genecode(11,[c,g,t],r).
genecode(11,[c,t,c],l).
genecode(11,[c,c,c],p).
genecode(11,[c,a,c],h).
genecode(11,[c,g,c],r).
genecode(11,[c,t,a],l).
genecode(11,[c,c,a],p).
genecode(11,[c,a,a],q).
genecode(11,[c,g,a],r).
genecode(11,[c,t,g],l).
genecode(11,[c,c,g],p).
genecode(11,[c,a,g],q).
genecode(11,[c,g,g],r).
genecode(11,[a,t,t],i).
genecode(11,[a,c,t],t).
genecode(11,[a,a,t],n).
genecode(11,[a,g,t],s).
genecode(11,[a,t,c],i).
genecode(11,[a,c,c],t).
genecode(11,[a,a,c],n).
genecode(11,[a,g,c],s).
genecode(11,[a,t,a],i).
genecode(11,[a,c,a],t).
genecode(11,[a,a,a],k).
genecode(11,[a,g,a],r).
genecode(11,[a,t,g],m).
genecode(11,[a,c,g],t).
genecode(11,[a,a,g],k).
genecode(11,[a,g,g],r).
genecode(11,[g,t,t],v).
genecode(11,[g,c,t],a).
genecode(11,[g,a,t],d).
genecode(11,[g,g,t],g).
genecode(11,[g,t,c],v).
genecode(11,[g,c,c],a).
genecode(11,[g,a,c],d).
genecode(11,[g,g,c],g).
genecode(11,[g,t,a],v).
genecode(11,[g,c,a],a).
genecode(11,[g,a,a],e).
genecode(11,[g,g,a],g).
genecode(11,[g,t,g],v).
genecode(11,[g,c,g],a).
genecode(11,[g,a,g],e).
genecode(11,[g,g,g],g).

%% genecode_start_codon(+TableNum,-StartCodon)
%
% This predicate specifies StartCodon given a TableNum

genecode_start_codon(11,[t,t,g]).
genecode_start_codon(11,[c,t,g]).
genecode_start_codon(11,[a,t,t]).
genecode_start_codon(11,[a,t,c]).
genecode_start_codon(11,[a,t,a]).
genecode_start_codon(11,[a,t,g]).
genecode_start_codon(11,[g,t,g]).


%% genecode_start_codons(+TableNum,-StartCodons)
%
% This predicate computes a list of start codon given a TableNum
	
genecode_start_codons(GeneCode,StartCodons) :-
	findall(Codon,genecode_start_codon(GeneCode,Codon),StartCodons).


%% genecode_stop_codon(+TableNum,-StopCodon)
%
% This predicate specifies Stop codon given a TableNum
genecode_stop_codon(N,Codon) :-
	genecode(N,Codon,'*').

%% genecode_stop_codons(+TableNum,-StopCodons)
%
% This predicate computes the list of stop codon given a TableNum
genecode_stop_codons(GeneCode,StopCodons) :-
	findall(Codon,genecode(GeneCode,Codon,'*'),StopCodons).


