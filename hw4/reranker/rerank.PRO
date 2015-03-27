#!/usr/bin/env python
import optparse
import sys
import bleu
import heapq
import math, random, re
from operator import itemgetter
import os.path as path
import nltk
import pickle

def log (string):
  sys.stderr.write(string + "\n")
  
# Calculates a smoothed value for bleu
# Reference : SFU NLP Class
# 
# A modification of BLEU that returns a positive value even when some 
# higher-order precisions are zero. From Liang et al. 2006 (Footnote 5):
# http://aclweb.org/anthology-new/P/P06/P06-1096.pdf
def compute_bleu(sent, ref):
  stats = [stat for stat in bleu.bleu_stats(sent, ref)]
  return sum([bleu.bleu(stats[:2+2*i])/math.pow(2,4-i+1) for i in xrange(1,5)])

# creates bigrams from a list
def couple(l):
  # creates a coupling of a list
  for i in xrange(0, len(l) - 1):
    yield (l[i], l[i + 1])

# Matches cryllic words
def is_untranslated(word):
  return not re.match(r"^[a-zA-Z0-9\-_,.'\"$]+$", word);

def find_untranslated (sent):
  count = 0
  for word in sent:
    if is_untranslated(word) :
      count += 1
  return count

def find_matched_paren(sent):
  o, matched = 0, 0
  for word in sent:
    if word.strip() == "(":
      o += 1;
    elif word.strip() == ")":
      o -= 1;
      if o >= 0:
        matched += 1
  return matched
  
# extracts a feature vector
def extract_features(nbest):
  (hyp, bleu, feats) = nbest
  features = { 'NULL': 1.0 }
  for feat in feats.split(' '):
    (k, v) = feat.split('=')
    features[k] = float(v)
  if (opts.postag):
    tags = nltk.pos_tag(hyp.decode("utf-8"))
    features['t:NN'] = sum(1 for tag in tags if tag[1].startswith('NN'))
    features['t:JJ'] = sum(1 for tag in tags if tag[1].startswith('JJ'))
    features['t:VB'] = sum(1 for tag in tags if tag[1].startswith('VB'))
    features['t:RB'] = sum(1 for tag in tags if tag[1].startswith('RB'))
    features['t:FW'] = sum(1 for tag in tags if tag[1].startswith('FW'))
  sw = hyp.strip().split(" ")
  features['len(s)'] = len(sw)
  features['x:untrans'] = find_untranslated(sw)
  features['x:paren'] = find_matched_paren(sw)
  # Create unigram features
  #  We use small feature vectors to make sure that only nonzero features are
  #  included so speed is greatly increased!
  if opts.unigrams:
    for unigram in sw:
      if unigram in all_unigrams:
        if not unigram in features:
          features["u:" + unigram] = 1
        #else:
        #  features["u:" + unigram] += 1
  if opts.bigrams:
    coupled = [" ".join(c) for c in couple(sw)]
    for bigram in coupled:
      if bigram in all_bigrams:
        if not bigram in features:
          features["b:" + bigram] = 1
        #else:
        #  features["b:" + bigram] += 1

  # Reweight
  #for feat in features:
  #  if not feat in ['NULL', 'len(s)', 'x:untrans', 'x:paren']:
  #    features[feat] = 1
  return features

optparser = optparse.OptionParser()
optparser.add_option("-k", "--kbest-list", dest="input", default="data/dev+test.m1.100best", help="100-best translation lists")
optparser.add_option("-t", "--tau", dest="tau", default=5000, type="int", help="Sample count (default 5000)")
optparser.add_option("-i", "--xi", dest="xi", default=100, type="int", help="Training data kept from samples (def 100)")
optparser.add_option("-a", "--alpha", dest="alpha", default=0.1, type="float", help="Sampler acceptance cutoff")
optparser.add_option("-e", "--eta", dest="eta", default=0.1, type="float", help="Perceptron learn rate")
optparser.add_option("-m", "--rounds", dest="rounds", default=5, type="int", help="Perceptron training rounds")
optparser.add_option("-r", "--reference", dest="reference", default="data/train.ref", help="Target language reference sentences")
optparser.add_option("-x", "--train", dest="train", default="data/train.100best", help="Target language training sentences")
optparser.add_option("-p", "--pickle", dest="pickle", default=False, help="Use pickle?")
optparser.add_option("-b", "--bigrams", dest="bigrams", action="store_true", help="Use bigrams?")
optparser.add_option("-c", "--cryllic", dest="cryllic", action="store_true", help="Cryllic only")
optparser.add_option("-u", "--unigrams", dest="unigrams", action="store_true", help="Use unigrams?")
optparser.add_option("-g", "--postag", dest="postag", action="store_true", help="Add pos tagging features")

(opts, _) = optparser.parse_args()

train_refs = [line.strip().split() for line in open(opts.reference)]
train_sents = [pair.split(' ||| ') for pair in open(opts.train)]
num_train = len(train_sents) / 100

all_hyps = [pair.split(' ||| ') for pair in open(opts.input)]
num_sents = len(all_hyps) / 100

# load unigram bigram features if necessary
if opts.unigrams:
  log("[+] Working with unigram features!")
  all_unigrams = set(word for s in xrange(0, num_sents) for (num, hyp, feats) in all_hyps[s * 100:s * 100 + 100] for word in hyp.strip().split(" "))
  if opts.cryllic:
    log("[.] Only translated!")
    all_unigrams = set(word for word in all_unigrams if not is_untranslated(word))
  log("[.] %i unigram features loaded" % len(all_unigrams))
if opts.bigrams:
  log("[+] Working with bigram features!")
  all_bigrams = set(" ".join(bigram) for s in xrange(0, num_sents) for (num, hyp, feats) in all_hyps[s * 100:s * 100 + 100] for bigram in couple(hyp.strip().split(" ")))
  if opts.cryllic:
    log("[.] Only translated!")
    all_bigrams = set(gram for gram in all_bigrams if all(not is_untranslated(word) for word in gram.split()))
  log("[.] %i bigram features loaded" % len(all_bigrams))

if path.isfile("PRO.training.bleu.pickle") and opts.pickle:
  nbests = pickle.load(open("PRO.training.bleu.pickle"))
  log("[-] Pickle Loaded")
else:
  # collect nbests
  nbests = []
  hypnum = 0
  for s in xrange(0, num_train):
    hyps_for_one_sent = train_sents[s * 100:s * 100 + 100]
    nbests.append([])
    for (num, hyp, feats) in hyps_for_one_sent:
      nbests[s].append((hyp, compute_bleu(hyp.strip().split(), train_refs[s]), feats))
  # create the pickle
  pickle.dump(nbests, open("PRO.training.bleu.pickle", "w"))
  log("[+] Pickle Generated")

def gen_sample(size, nbest):
  for i in xrange(0, size):
    a = random.choice(nbest)
    b = random.choice(nbest)
    if math.fabs(a[1] - b[1]) > opts.alpha:
      # only pick ones with a good difference in bleu
      if a[1] > b[1]:
        yield (a, b, a[1] - b[1])
      else:
        yield (b, a, b[1] - a[1])
    else: 
      continue

# learn the weights
weights = {'NULL'       : 0.0,
           'p(e)'       : 0.0,
           'p(e|f)'     : 0.0,
           'p_lex(f|e)' : 0.0,
           'model1'     : 0.0,
           'len(s)'     : 0.0,
           'x:untrans'  : 0.0,
           'x:paren'    : 0.0
           }
# Augment with postag
if opts.postag:
  log("[!] Use POS-TAGGING features")
  weights['t:NN'] = 0.0
  weights['t:JJ'] = 0.0
  weights['t:VB'] = 0.0
  weights['t:RB'] = 0.0
  weights['t:FW'] = 0.0
# Augment weights with unigrams /bigrams if necessary
if opts.unigrams:
  for unigram in all_unigrams:
    weights["u:" + unigram] = 0.0
if opts.bigrams:
  for bigram in all_bigrams:
    weights["b:" + bigram] = 0.0

cached_weights = {}
for key in weights:
  cached_weights[key] = weights[key]

count = 0
for i in xrange(0, opts.rounds):
  log("[.] Round %i" % i)  
  for nbest in nbests:
    sys.stderr.write(".")
    samples_top = heapq.nlargest(opts.xi, gen_sample(opts.tau, nbest), key=itemgetter(2))
    # perceptron updates
    for (s1, s2, _) in samples_top:
      # calculate
      count += 1
      feats1 = extract_features(s1)
      feats2 = extract_features(s2)
      score1 = sum(feats1[w] * weights[w] for w in weights if w in feats1)
      score2 = sum(feats2[w] * weights[w] for w in weights if w in feats2)
      if score1 <= score2:
        # perceptron mistake
        featureCollection = set(feat for feat in feats1)
        for feat in feats2:
          featureCollection.add(feat)
        # this makes things much faster. We only recalculate the nonzero features
        for w in featureCollection:
          if w in feats1 and w in feats2:
            weights[w] = weights[w] + opts.eta * (feats1[w] - feats2[w])
            cached_weights[key] = cached_weights[key] + weights[w]
          elif w in feats1:
             weights[w] = weights[w] + opts.eta * feats1[w]
             cached_weights[key] = cached_weights[key] + weights[w]
          elif w in feats2:
             weights[w] = weights[w] - opts.eta * feats2[w]
             cached_weights[key] = cached_weights[key] - weights[w]
  sys.stderr.write("\n") 
  log("[+] Weights: %s" % " ".join([k + ": " + str(weights[k]) for k in weights]))

# Adjust weights
#for w in weights:
#  weights[w] = cached_weights[w] / count

log ("[+] Outputting %i sentences" % num_sents)
for s in xrange(0, num_sents):  
  hyps_for_one_sent = all_hyps[s * 100:s * 100 + 100]
  (best_score, best) = (-1e300, '')
  for (num, hyp, feats) in hyps_for_one_sent:
    score = 0.0
    feats = extract_features((hyp, None, feats))
    score = sum(feats[w] * weights[w] for w in weights if w in feats)
   
    if score > best_score:
      (best_score, best) = (score, hyp)
  try: 
    sys.stdout.write("%s\n" % best)
  except (Exception):
    sys.exit(1)

