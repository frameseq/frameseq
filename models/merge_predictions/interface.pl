% Simple model that aggregates multiple files into one.
% Should be fast and with a very low memory footprint.

:- ['../../lost.pl'].

%% merge(+InputFiles,+Options,+OutputFile)
% Merges all InputFiles in the OutputFile.
merge(InputFiles,_Options,OutputFile) :-
	open(OutputFile,write,Stream),
	terms_from_files_to_stream(InputFiles,Stream),
	close(Stream).

terms_from_files_to_stream([],_).
terms_from_files_to_stream([File1|InputFilesRest],OutStream) :-
        open(File1,read,InStream),
        terms_from_stream_to_stream(InStream,OutStream),
	close(InStream),
	!,
        terms_from_files_to_stream(InputFilesRest,OutStream).

terms_from_stream_to_stream(InStream,OutStream) :-
	read(InStream, T),
	((T == end_of_file) ->
	 true
	;
	 writeq(OutStream,T),
	 write(OutStream,'.\n'),
	 !,
	 terms_from_stream_to_stream(InStream,OutStream)
	).

