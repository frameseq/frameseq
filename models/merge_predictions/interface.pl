:- ['../../lost.pl'].

%% merge(+InputFiles,+Options,+OutputFile)
% Merges all InputFiles in the OutputFile such that terms in output file
% are sorted.
merge(InputFiles,_Options,OutputFile) :-
	terms_from_files(InputFiles,FilesTerms),
        flatten(FilesTerms,FlatTerms),
        sort(FlatTerms,SortedTerms),
        terms_to_file(OutputFile,SortedTerms).

terms_from_files([],[]).
terms_from_files([File1|InputFilesRest],[Terms1|TermsRest]) :-
        terms_from_file(File1,Terms1),
        terms_from_files(InputFilesRest,TermsRest).
