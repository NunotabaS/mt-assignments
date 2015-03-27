import sys

documents = []

for m in xrange(1, len(sys.argv)):
  documents.append([line.strip() for line in open(sys.argv[m], 'r')])

# Vote
for i in xrange(0, 800):
  choices = {}
  for document in documents:
    if document[i] in choices:
      choices[document[i]] += 1
    else:
      choices[document[i]] = 1
  best, bs = '', -1
  for choice in choices:
    if choices[choice] > bs:
      best = choice
      bs = choices[choice]
  if bs == 1:
    print documents[0][i]
  else:
    print best
