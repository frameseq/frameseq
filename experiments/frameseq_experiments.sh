#!/bin/sh

MIN=0
MAX=1
STEP=0.1

# example training on E. coli.
for model in model mm_model ho_model homm_model
do
prism -g "[run_experiment], run($MIN,$MAX,$STEP,$model,genemark,ecoli,ecoli)."
done
