#!/bin/sh

exec &> ../results/$1_$2_$3_$4.stats

mkdir ../results/1$_$2_$3_$4

cp ../scripts/

(prism -g "[../scripts/tmp],test." > ../results/$1_$2_$3_$4.report &)


