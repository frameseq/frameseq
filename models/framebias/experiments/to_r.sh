#!/bin/sh

#ruby run_exp.rb | grep experiment_result > experiment_result_index.pl
cat nohup.out | grep experiment_result > experiment_result_index.pl

prism -g "[create_r_data], create_data_file('experiment_result_index.pl', 'results.tab')" 


