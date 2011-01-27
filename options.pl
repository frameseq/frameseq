% Options. 
% You might want to meddle a bit with this file to run the program
% on your own data. 
% The options are facts of the form: option(Key,Value).
% You might want to change value to fit your needs. 


%% OPTION: prediction_functor
% This is the name of the functor which is used in the format of the predictions.
option(prediction_functor,genemark_gene_prediction).

%% OPTION: score_functor
% This is the name of the functor which is used to read the probability
% of a prediction. For instance, with a genemark predictions, e.g.
% genemark_gene_prediction(na,909370,909462,'+',1,[average_probability(0.13),start_codon_probability(0.87)]).
% we use the value 'start_codon_probability':
option(score_functor,start_codon_probability).


%% OPTION: score_categories
% This is used in the discretization phase. It dictates how many
% symbolic values, that will be used to represent the numeric values of
% the scores of predictions
option(score_categories,100).


%% OPTION: learn_method 
% This option specifies the method that is used to derive the
% probability parameters of the model. Usually the setting 
% 'prism' is the best option, since this method uses pseudo counts
% to deal with sparse data. The value 'custom' can be used if
% 'prism' takes too long.. 
option(learn_method,prism).

%% OPTION: origin
% This option specifies the position of the origin in the genome.
% This is only relevant it the option split_annotate has the value true
% (default).
option(origin,3923500). 

%% OPTION: terminus 
% This option specifies the position of the origin in the genome.
% This is only relevant it the option split_annotate has the value true
% (default).
option(terminus,1588800). 

%% OPTION: divide_genome
% This option indicates that the genome should be divided into two
% parts (origin -> terminus) and (terminus -> origin) and separate
% analysis will be run on each part
option(divide_genome,false).


%% OPTION: override_delete_probability
% This is option can be used to enforce a particular probability of 
% deleting a prediction. This can be used to control the false
% positive rate.  
% To set a particular delete probability of , you would have
% option(override_delete_probability, 0.5).
% The default setting is 'false', which means that the program
% will automatically infer the delete probability based on the
% the size of the given training data.
option(override_delete_probability,false).

