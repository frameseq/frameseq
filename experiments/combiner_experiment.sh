#!/bin/sh

MIN=0
MAX=1
STEP=0.01

prism -g "[run_experiment], run($MIN,$MAX,$STEP,model,combiner,ecoli,ecoli)."
