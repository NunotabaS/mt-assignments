# Model 1 scores.

To generate model-1 input, run:

    generate-align-input.py data/....100best > somefile.f
    generate-align-input.py data/....src > somefile.e

(Note: Need to comment out the last parmeter in expansion, when expanding from src)
(Since This implementation uses dual intersection, e,f ordering does not matter)

To generate model-1 alignments, run:

    ./align-model1-dual-lc > data/dev+train.align

The e-f data is generated from the dev+train src and dev+train 100best by 
duplicating the source 100 times to match with each sentence in the 100best

# Augment the features

    python augment.py data/dev+train.100best data/dev+train.align > data/dev+train.m1.100best
    
This adds the model1=?? scores into the original input after the p(e) etc probs.
Make sure to do this for both the training and test sets (otherwise test will not have the features!)

# MegaM 
I use MegaM from the NLTK library. To use, you need to dowload a copy and compile 
locally. Modify the top lines of rerank.PRO.megam to point to the correct  install
directory.

Requires OCaml.

When running a pipeline, MegaM outputs 1 extra line in the beginning. Pipe to ./megam-filter to get
rid of this initial debug line before piping to ./compute-bleu

# sklearn.LogisticRegression

Needs to have the sklearn library installed. 


## Below are the original readme contents

There are three Python programs here (`-h` for usage):

 - `./rerank` chooses the best candidate translations from a k-best list using a linear model.
 - `./oracle` computes a lower bound of BLEU on the development data.
 - `./compute-bleu` computes the BLEU score of a set of translations.

The commands are designed to work in a pipeline. For instance, these are valid invocations:

    python rerank | python compute-bleu

    python oracle | python compute-bleu

The `data/` directory contains training, devlopment, and test data.

 - `train.src`: Russian source sentences.
 - `train.ref`: English reference sentences.
 - `train.100best`: Candidate translations of `train.src` from a machine translation system.
 - `dev+test.src`: Russian source sentences.
 - `dev.ref`: English references sentences for the first half of `dev+test.src`.
 - `dev+test.100best`: Candidate translations of `dev+test.src`.


