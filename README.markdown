frameseq
========

This is the _frameseq_ model for improved selection of gene finder predictions (stops).

It is a probabilistic model which selects/ranks a sequence of gene predictions
from some gene finder based on the score given by the gene finder and the general
tendency that genes are picky about the reading frames of the neighbor genes.

This work is supported by the
project ``Logic-statistic modelling and analysis of biological sequence data''
funded by the NABIIT program under the Danish Strategic Research Council.

See: [LoSt website](http://lost.ruc.dk)

Thanks to:

- The LoSt group for valuable discussions
- The developers of PRISM (We love PRISM)
- The anynomous reviewers of the article who provided excellent feedback

Setting up the software
-----------------------

First, a few things must be done to setup the system. 

1. Download and install [PRISM](http://sato-www.cs.titech.ac.jp/prism/). 
   frameseq was tested to work with version 2.0 of PRISM.
2. Setup paths in lost.pl

There are three facts which you will probably need to change:

	lost_config(prism_command,'prism').

This one is OK if you have set up PRISM to be in your binary path. Otherwise you should 
provide the extended, full path to the prism binary.

	lost_config(lost_base_directory,'/change/to/your/local/lost/directory').

This should just be updated to the directory this README file resides.

	lost_config(platform,'to specify unix or windows').

This should be either 'unix' (which covers most unix derivates such as BSD, Linux or OSX) or 'windows'. 

Running the software
--------------------

The program can be started through the PRISM system. When you start up the PRISM system you will 
be greeted by a message followed by an interactive prompt, that looks like this:

	| ?-

At this prompt, you can load the Frame Bias Model by typing (disregarding the prompt characters): 

	| ?- [frameseq].

After this you can run a particular inference using the model. This is described in detailed in the following three sections. 

Alternatively, you can use an example script which simplifies the process, see section *Using a pre-made script*.

### Training a model

A model must first be trained on some training data: A *GoldenStandardFile* which contains the set of true protein genes
for some genome  and a predictions file which contains predictions from a gene-finder for the _same_ genome. The trained model
may subsequently be used to filter predictions from the same or other (preferably similar) organisms. 

Training is performed by calling the goal:


	| ?- train(GoldenStandardFile,PredictionsFile,ParametersFile).

where,


- *GoldenStandardFile* points to a file with training data. Typically, this is derived from a GenBank/Refseq PTT file or similar.
  In the scripts directory there is a Prolog file, ptt_to_prolog.pl, which can be used to convert a PTT file to a 
  Prolog file of the right format.
- *PredictionsFile* points to a file in Prolog format, which contains all of the predictions from the 
  gene finder. In scripts, you will found genemark_to_prolog which converts a report in the format
  producted by genemark to the expected Prolog format.


This produces *ParametersFile* which includes the probabilistic parameters of the model and which in later used in the prediction step.

For instance, to run the filter on the supplied sample data (E-coli K12, MG1665), you would type:

	| ?- train('$FRAMESEQ/data/genemark.report.pl','$FRAMESEQ/frameseq/data/U00095.ptt.pl','$FRAMESEQ/data/model_params.pl').

You should replace the text *$FRAMESEQ* with the _absolute_ path the the directory where the frameseq repository resides.


### Filtering using the model

For instance, you may want to filter predictions from a gene finder to remove potential 
false positives. To do this, you type:


	| ?- filter(ParametersFile,PredictionsFile,FilteredPredictionsFile).

where,

- *ParametersFile* is the file obtained in the training step.
- *PredictionsFile* points to a file in Prolog format, which contains all of the predictions from the 
  gene finder. In scripts, you will found genemark_to_prolog which converts a report in the format
  producted by genemark to the expected Prolog format. 
- *FilteredPredictionsFile* points to a filename where the results of running the model (a subset of the originally
  predicted genes) will be written to.

Having done the training step first, you can for instanc to run the filter on a the E-coli genome by typing:

	| ?- filter('$FRAMESEQ/data/model_params.pl','$FRAMESEQ/frameseq/data/genemark.report.pl','$FRAMESEQ/data/filter_results.pl').

You should replace the text *$FRAMESEQ* with the _absolute_ path the the directory where the frameseq repository resides.

### Evaluating the results:

The program allows you to evaluate how good a set of predictions is: 

	| ?- evaluate(GoldenStandardFile, PredictionsFile, AccuracyFile).

where,

- *GoldenStandardFile* is a file containing a list of verified genes in the Prolog format.
- *PredictionsFile* Is a file containing a list of predicted genes in the Prolog format.
- *AccuracyFile* is a file there the evaluation results are written to.

Running this query will output a various evaluation metrics such as sensitivity and specificity.

Note that  _all file names should should be absolute and should be inclosed in single quotes_.

### Using a pre-made script

Perhaps, a more convenient starting point is to use one of the supplied scripts for the model
organisms in the scripts/ directory. These include:

- *bacillus.pl*: which trains using Bacillus and predicts on E.Coli.
- *escherischia.pl*: which trains using E.Coli. and predicts on E.Coli.
- *legionella.pl*: which trains on Legionella and predicts on E.Coli.
- *salmonella.pl*: which trains on Salmonella and predicts on E.Coli.
- *thermoplasma.pl*which trains on Thermoplasma and predicts on E.Coli.

You will need to change filenames accordingly in the beginning of the script. These scripts run 
the filtering multiple times to produce various trade-offs between sensitivity and specificity 
(by varying the delete probability). They produce a file (in the data directory) for each of these trade-offs.

These scripts are run by entering the scripts, starting prism, and typing the name of the file enclosed in
brackets and run (disregarding the prompt characters): 

	| ?- [bacillus], run.


### Running with detailed options

In some cases, you might want to meddle a bit with the *options.pl* file to run the program on your own data.
The options are facts of the form:

	option(Key,Value).
	
You can change the default options in *options.pl* or dynamically change the value of an option by calling the goal:

	set_option(Key,NewValue).

In the following is a list describing the purpose of each option is presented. The _Value_ given in the
syntax of the option should be understand as the _default_ value.


#### score_functor
##### Syntax
	option(prediction_functor,genemark_gene_prediction).
##### Description
This is the name of the functor which is used in the format of the predictions.

#### score_functor
##### Syntax
	option(score_functor,start_codon_probability).
##### Description
This is the name of the functor which is used to read the probability of a prediction. For instance, with a genemark predictions, e.g.

	genemark_gene_prediction(na,909370,909462,'+',1,[average_probability(0.13),start_codon_probability(0.87)]).

You will only need to change this if the score functor of your format is different from the defaul value *'start_codon_probability'*.

#### score_categories
##### Syntax
	option(score_categories,100).
##### Description
This is used in the discretization phase. It dictates how many
symbolic values, that will be used to represent the numeric values of
the scores of predictions

#### learn_method 
##### Syntax
	option(learn_method,prism).
##### Description
This option specifies the method that is used to derive the
probability parameters of the model. Usually the setting 
'prism' is the best option, since this method uses pseudo counts
to deal with sparse data. The value 'custom' can be used if
'prism' takes too long.. 

#### divide_genome
##### Syntax
	option(divide_genome,true).	
##### Description
This option indicates that the genome should be divided into two
parts (origin -> terminus) and (terminus -> origin) and separate
analysis will be run on each part

#### origin
##### Syntax
	option(origin, 12345). 
##### Description	
This option specifies the position of the origin in the genome.
This is only relevant it the option split_annotate has the value true
(which it has by default).

#### terminus 
##### Syntax
	option(terminus, 12345). 
##### Description
This option specifies the position of the origin in the genome.
This is only relevant it the option split_annotate has the value true
(which it has by default).

#### override_delete_probability
##### Syntax
	option(override_delete_probability,false).	
##### Description
This is option can be used to enforce a particular probability of 
deleting a prediction. This can be used to control the false
positive rate.  
To set a particular delete probability of 0.5 you would have

	option(override_delete_probability, 0.5).
	
The default setting is 'false', which means that the program
will automatically infer the delete probability based on the
the size of the given training data.
