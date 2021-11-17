#!/usr/bin/python3
#coding: utf-8

# Purpose: skeleton for the TextIR project
#
# Comment: parts to be completed or modified are denoted with '???'
#

# Code:

##########################################################################
#                            INITIALIZATION                              #
##########################################################################


import sys
import re
from math import *
from collections import defaultdict


prg = sys.argv[0]
def P(output=''): input(output+"\nDebug point; Press ENTER to continue")
def Info(output='',ending='\n'): #print(output, file=sys.stderr)
        sys.stderr.write(output+ending)


#######################################
# special imports



#######################################
# files


#######################################
# variables



#########################################



#########################################
# USAGE - this part reads the command line

# typical call: search_engine.py -c cisi_collection.txt -q cisi_queries.txt -o run1

import argparse
parser = argparse.ArgumentParser()

parser.add_argument("-c", "--collection", dest="file_coll",
                  help="file containing the docs", metavar="FILE")
parser.add_argument("-q", "--query", dest="file_query",
                  help="FILE contains queries", metavar="FILE")

# ??? update the path to the stop-word list here if needed
parser.add_argument("-s", "--stop", dest="file_stop",
                  default='./stop_words.en.txt',
                  help="FILE contains stop words", metavar="FILE")

parser.add_argument("-o", "--out", dest="prefix",
                  help="PREFIX for output files", metavar="STR")

parser.add_argument("-v", "--verbose",
                  action="store_false", dest="verbose", default=True,
                  help="print status messages to stdout")



args = parser.parse_args()

# command line arguments are named as  args.file_coll   args.file_query ...


################################################################################
################################################################################
##                                                                            ##
##                                 FUNCTIONS                                  ##
##                                                                            ##
################################################################################
################################################################################

def Tokenizer(sequence):
    t_words = []
    # ??? transform a sequence as a list of words (or stems)
    # useful: line.split('...')  or better: re.split('...',line)
    # useful: line.lower()

    cleaned_sequence =  sequence.lower()
    cleaned_sequence = re.sub(r'[^\w\s]', '', cleaned_sequence)
    t_words = re.split(r'\s+', cleaned_sequence)

    # Stemming
    t_words = [w[:-3] if w.endswith('ing') else w for w in t_words]
    t_words = [w[:-1] if w.endswith('nn') else w for w in t_words]
    t_words = [w[:-1] if (len(w) > 2) and w.endswith('s') else w for w in t_words]
    t_words = [w[:-4] if w.endswith('tion') else w for w in t_words]
    t_words = [w[:-1] if w.endswith('e') else w for w in t_words]
    t_words = [w[:-2] if w.endswith('ed') else w for w in t_words]

    #t_words = [w for w in t_words if w]

    print(t_words)

    return t_words


################################################################################
################################################################################
##                                                                            ##
##                                     CODE                                   ##
##                                                                            ##
################################################################################
################################################################################


Info('Reading stop words')

# filename given in the command line is in   args.file_stop
# useful: line = line.rstrip('\r\n') # remove the carriage return
with open(args.file_stop, 'r') as f:
    t_stopwords = [line.rstrip('\r\n') for line in f]


#####################################################################

Info('Reading/indexing the collection file')


# ??? read and process the collection file to build the inverted file
# filename of the collection given in the command line is in   args.file_coll
# and collect any useful information (for TF-IDF/cosine or Okapi BM-25 or other models)

h_inverted_file = defaultdict(lambda: defaultdict(lambda: 0))
n_docs = 0

def update_inverted_file(line, doc_id):
    """Update the inverted file.

    line (str): a line of words while reading collection
    doc_id (str): the document's ID in which line appears. 
    """
    words = Tokenizer(line)
    for word in words:
        h_inverted_file[word][doc_id] += 1


# Algo description !
# Open collection file
# Read it line by line and update inverted file
with open(args.file_coll, 'r') as f:

    for line in f.readlines():
        line = line.rstrip('\r\n')

        match = re.search('<docno>(.*)<', line)
        if match is not None:
            n_docs += 1
            doc_id = match.group(1)
        elif (line.startswith('<document>') or 
            line.startswith('<text>') or 
            line.startswith('</text>') or 
            line.startswith('</document>')):
            pass
        else: # document starts with <line> or is text content
            line = re.sub('</?title>', '', line)
            update_inverted_file(line, doc_id)



#####################################################################

Info('Post-processing the inverted file')

# ??? filter out unwanted tokens in the inverted file
# compute IDF of terms (if TF-IDF is used)...
# useful: log(x)

# stopwords removal
for stopword in t_stopwords:
    if stopword in h_inverted_file:
        del h_inverted_file[stopword]

# IDF 
h_IDF = {}
for word in h_inverted_file:
    h_IDF[word] = log(n_docs/len(h_inverted_file[word]))

# compute norms of documents (if cosine similarity is used)...
#useful: sum([(x*y)**2  for x in t_toto ])
h_norms = defaultdict(lambda: 0)
for word in h_inverted_file:
    for doc_id in h_inverted_file[word]:
        TF = h_inverted_file[word][doc_id]
        IDF = h_IDF[word]
        h_norms[doc_id] += (TF*IDF)**2

h_norms = {doc_id:sqrt(h_norms[doc_id]) for doc_id in h_norms}

#####################################################################


Info('Reading query file')


# dictionary query -> document -> score of document for this query
h_qid2did2score = defaultdict(lambda : defaultdict(lambda : 0))

# ??? read and process the queries and keep the results in the dictionary h_qid2did2score
# filename of the collection given in the command line is in   args.file_query

with open(args.file_query, 'r') as f:
    lines = f.readlines()
    current_query_words = []
    for line in lines:
        line = line.rstrip('\r\n')

        match = re.search('<queryno>query_(.*)<', line)
        if match is not None:
            # Next query
            query_id = match.group(1)
            current_query_words = []
        elif (line.startswith('<text>') or 
            line.startswith('</text>') or 
            line.startswith('<query>') or 
            line.startswith('</query>')):
            pass
        else:
            for word in Tokenizer(line):
                if word in h_inverted_file:
                    for doc_id in h_inverted_file[word]:
                        TF = h_inverted_file[word][doc_id]
                        IDF = h_IDF[word]
                        h_qid2did2score[query_id][doc_id] += ((IDF**2) * TF) / h_norms[doc_id]


################################################################################
# NOTHING TO MODIFY below this line

# output the results with the expected results in a file
resultFile = open(args.prefix+'.res','w')

for qid in sorted(h_qid2did2score, key=int): # tri par numero de requete
    for (rank,(did,s)) in enumerate(sorted(h_qid2did2score[qid].items(), key=lambda t_doc_score:(-t_doc_score[1],t_doc_score[0]) ) ): # tri par score decroissant
        resultFile.write(str(qid)+'\tQ0\t'+str(did)+'\t'+str(rank+1)+'\t'+str(s)+'\tExp\n')

resultFile.close()
