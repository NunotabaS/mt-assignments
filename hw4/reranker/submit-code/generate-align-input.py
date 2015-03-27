import sys

with open(sys.argv[1], "r") as f:
  for line in f:
      #for i in xrange(0, 100):
      sid, sent, feat = line.strip().split("|||")
      print sent.strip()
