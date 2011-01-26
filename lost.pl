%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%% lost_config(+Key,+Information)
%
% Configure  basic Information for the framaework
%
% Key = prism_command: Command to use prism
% Key = lost_base_directory: Specify the repertory where lost project is
% Key = platform: Specify the platform used to run the framework (unix or windows)
% Key = concurrent_processes: the number of processes used for parallel computation

% Make changes to these three lines:
lost_config(prism_command,'prism').
lost_config(lost_base_directory,'/home/ctheilhave/code/framebias/').
lost_config(platform,'unix').

% Do not change below this line

%% lost_include_api(+Name)
%
% Consult Name, on of the library defined in $LOST/lib/
lost_include_api(_) :-
        lost_config(lost_base_directory,'/change/to/your/local/lost/directory'),
        throw('Please set lost_base_directory!!!').
lost_include_api(_) :-
        lost_config(platform,'to specify unix or windows'),
        throw('Please set your plateform!!!').

% Basic rule to glue in other APIs

lost_include_api(Name) :-
	catch(lost_api_loaded(Name),_,fail), !.

lost_include_api(Name) :-
	lost_config(lost_base_directory, Basedir),
	atom_concat(Basedir,'lib/',SharedDir),
	atom_concat(SharedDir,Name,DirAndName),
	atom_concat(DirAndName,'.pl',FullName),
	consult(FullName),
	assert(lost_api_loaded(Name)).

%% lost_reload_api
%% lost_reload_api(+Name)
%
% Reload all libraries allready loaded
% If Name is specified, reload only the library named Name
lost_reload_api :-
        findall(Name,lost_api_loaded(Name),Api_Loaded),
        forall(member(Name,Api_Loaded),(lost_config(lost_base_directory, Basedir),
                                        atom_concat(Basedir,'lib/',SharedDir),
                                        atom_concat(SharedDir,Name,DirAndName),
                                        atom_concat(DirAndName,'.pl',FullName),
                                        consult(FullName)
                                       )
              ).

lost_reload_api(_) :-
        lost_config(lost_base_directory,'/change/to/your/local/lost/directory'),
        throw('Please set lost_base_directory!!!').
lost_reload_api(_) :-
        lost_config(platform,'to specify unix or windows'),
        throw('Please set your plateform!!!').

% Basic rule to glue in other APIs
lost_reload_api(Name) :-
	lost_config(lost_base_directory, Basedir),
	atom_concat(Basedir,'lib/',SharedDir),
	atom_concat(SharedDir,Name,DirAndName),
	atom_concat(DirAndName,'.pl',FullName),
	consult(FullName).

%% lost_include_script(+Name)
%
% Consult Name, on of the script defined in $LOST/scripts/
lost_include_script(Name) :-
	lost_config(lost_base_directory, Basedir),
	atom_concat(Basedir,'scripts/',ScriptDir),
	atom_concat(ScriptDir,Name,DirAndName),
	atom_concat(DirAndName,'.pl',FullName),
	consult(FullName).


:- lost_include_api(interface).
