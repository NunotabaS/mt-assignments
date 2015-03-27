import sys

with open(sys.argv[1], "r") as f:
  with open(sys.argv[2], "r") as g:
    for line in f:
      m1scores = len(g.readline().strip().split(" "))
      print line.strip() + " model1=" + str(m1scores)
