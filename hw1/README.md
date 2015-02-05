There are two python programs here (`-h` for usage):

-`./align` aligns words.

-`./grade` computes alignment error rate.

The commands work in a pipeline. For instance:

   > ./align -t 0.9 -n 1000 | ./grade -n 5

The `data` directory contains a fragment of the Canadian Hansards,
aligned by Ulrich Germann:

-`hansards.e` is the English side.

-`hansards.f` is the French side.

-`hansards.a` is the alignment of the first 37 sentences. The 
  notation i-j means the word as position i of the French is 
  aligned to the word at position j of the English. Notation 
  i?j means they are probably aligned. Positions are 0-indexed.
  
# Further Code
- `./align-model1`, `./align-model1-dual`, './align-model1-dual-lc' all take the same parameters of `./align`. Running with no parameters gives the run over the full dataset. Dual means there is a round of intersection. `-lc` means we also do lowercasing. There is an extra parameter `-r` for `-lc` to specify how many rounds of EM we're doing

- `./align-model2`, './align-model2-dual', './align-model2-dual-lc' are similar as above without the possibility of specifying EM rounds.

- `./intersector` takes two output files `-1` and `-2` does an intersect on them
 
