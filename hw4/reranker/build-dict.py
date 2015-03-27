import re

dictionary = {}
with open("data/train.ru-en.align", "r") as f:
  for line in f:
    src, dst, align = tuple(line.strip().split("|||"))
    srcwords = src.strip().split(" ")
    dstwords = dst.strip().split(" ")
    alignments = [tuple([int(item) for item in alignment.split("-")]) for alignment in align.strip().split(" ")]
    for (s, d) in alignments:
      if srcwords[s] in dictionary:
         dictionary[srcwords[s]].add(dstwords[d])
      else:
         dictionary[srcwords[s]] = set()
         dictionary[srcwords[s]].add(dstwords[d])

# finished dictionary
for cyrillic in dictionary:
  print cyrillic + "|||" + "|".join([engl for engl in dictionary[cyrillic]] )
