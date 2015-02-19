#!/bin/sh
# Script to do parallel processing
STACKCOUNT=10000
THINKDEPTH=200
./decode_stack_cost -i data/input-01 -s $STACKCOUNT -k $THINKDEPTH > output.txt.01 &
./decode_stack_cost -i data/input-02 -s $STACKCOUNT -k $THINKDEPTH > output.txt.02 &
./decode_stack_cost -i data/input-03 -s $STACKCOUNT -k $THINKDEPTH > output.txt.03 &
./decode_stack_cost -i data/input-04 -s $STACKCOUNT -k $THINKDEPTH > output.txt.04 &
./decode_stack_cost -i data/input-05 -s $STACKCOUNT -k $THINKDEPTH > output.txt.05 &
./decode_stack_cost -i data/input-06 -s $STACKCOUNT -k $THINKDEPTH > output.txt.06 &
./decode_stack_cost -i data/input-07 -s $STACKCOUNT -k $THINKDEPTH > output.txt.07 &
./decode_stack_cost -i data/input-08 -s $STACKCOUNT -k $THINKDEPTH > output.txt.08 &
./decode_stack_cost -i data/input-09 -s $STACKCOUNT -k $THINKDEPTH > output.txt.09 &
./decode_stack_cost -i data/input-10 -s $STACKCOUNT -k $THINKDEPTH > output.txt.10 &
./decode_stack_cost -i data/input-11 -s $STACKCOUNT -k $THINKDEPTH > output.txt.11 &
./decode_stack_cost -i data/input-12 -s $STACKCOUNT -k $THINKDEPTH > output.txt.12 &
./decode_stack_cost -i data/input-13 -s $STACKCOUNT -k $THINKDEPTH > output.txt.13 &
./decode_stack_cost -i data/input-14 -s $STACKCOUNT -k $THINKDEPTH > output.txt.14 &
./decode_stack_cost -i data/input-15 -s $STACKCOUNT -k $THINKDEPTH > output.txt.15 &
./decode_stack_cost -i data/input-16 -s $STACKCOUNT -k $THINKDEPTH > output.txt.16 &
echo "Enables the power of parallel processing..."
