% A DCG for parsing Genebank PTT files
% Christian Theil Have, 2010.

parse_ptt(SourceGenome, PTTFile, GeneFacts) :-
        readFile(PTTFile,FileContents),
        ptt_format(SourceGenome,_eoltype, GeneFacts, FileContents, []),
        true.

ptt_format(SourceGenome, EolType, Entries) -->
       lines(SourceGenome,EolType,Entries).  

% Parse all the lines of the file
lines(_,_,[]) --> [].

lines(SourceGenome,EolType,[Entry|Entries]) -->
        ptt_line(SourceGenome,EolType,Entry),
        lines(SourceGenome,EolType,Entries).
lines(SourceGenome,EolType,Entries) -->
        comment_line(EolType),
        lines(SourceGenome,EolType,Entries).

ptt_line(SourceGenome,EolType,CDS) -->
        integer(Start),
        dot,
        dot,
        integer(Stop),
        spaces,
        strand(Strand),
        spaces,
        length(Length),
        spaces,
        pid(PID),
        spaces,
        gene(Gene),
        spaces,
        synonym(Synonym),
        spaces,
        code(Code),
        spaces,
        cog(COG),
        spaces,
        product(Product),
        end_of_line(EolType),
        { Temp is Start mod 3, (Temp = 0 -> Frame = 3 ; Frame = Temp) },
	{ CDS =.. [cds,SourceGenome,Start,Stop,Strand,Frame,[gene_name(Gene),length(Length),pid(PID),synonym(Synonym),code(Code),cog(COG),product(Product)]] }.


strand(CA) --> [C],{ member(C,[43,45]), atom_codes(CA, [C]) }.

length(L) -->
        integer(L).


pid(PIDATOM) -->
        integer(PID),
        { number_codes(PID,PIDCODES),atom_codes(PIDATOM,PIDCODES) }.

gene(Gene) -->
        non_spaces(GeneCodes),
        { atom_codes(Gene,GeneCodes) }.

synonym(Syn) -->
        non_spaces(SynCodes),
        { atom_codes(Syn,SynCodes) }.

code(Code) -->
       non_spaces(CodeCodes),
       { atom_codes(Code,CodeCodes) }.

cog(COG) -->
        non_spaces(COGCodes),
        { atom_codes(COG,COGCodes) }.

product(Product) -->
        non_end_of_lines(ProductCodes),
        { atom_codes(Product,ProductCodes) }.

integer(Integer) -->
       digits(Digits),
       { reverse(Digits,DigitsRev), reverse_digits_to_integer(DigitsRev,Integer) }.

digits([D|Ds]) -->
        digit(D),
        digits(Ds).
digits([D]) --> digit(D).

digit(Digit) -->
	[ S ],
	{ S >= 48, S =< 67, Digit is S - 48 }.

reverse_digits_to_integer([],0).
reverse_digits_to_integer([D|Ds],Int) :-
        reverse_digits_to_integer(Ds,ResultRest),
        Int is (10 * ResultRest) + D.

comment_line(EolType)-->
        non_end_of_lines(Line),
        {write('parsing comment line:'),
        atom_codes(Atom,Line),
        writeq(Atom),
        nl},
        end_of_line(EolType).

spaces --> space, spaces.
spaces --> space.

space --> [ 9 ]. % tab character
space --> [ 32 ]. % normal space character

non_spaces([Code|Rest]) --> non_space(Code), non_spaces(Rest).
non_spaces([Code]) --> non_space(Code).

non_space(Code) --> 
        [ Code ],
        { atom_codes('\t ',Spaces),
          not(member(Code,Spaces)) }.

non_end_of_lines([Code|Rest]) --> non_end_of_line(Code), non_end_of_lines(Rest).
non_end_of_lines([Code]) --> non_end_of_line(Code).
		     
non_end_of_line(Code) --> [ Code ], { not(member(Code, [10,13])) }.


end_of_line(windows)--> [10,13].			% windows end of line
end_of_line(unix) --> [10].                             % unix end of line

dot --> 
        [ Code ],
        { atom_codes('.',[Code]) }.
