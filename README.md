
Instructions
-------------

Goal: build your own TF-IDF/cosine based search_engine.

1) have a look at the cisi files (see below)
2) read the provided code in search_engine.py
3) complete the code (wherever there is '???') in search_engine.py, from top to bottom. Test at each step:
python3 search_engine.py -c cisi_collection.txt -q cisi_queries.txt -o run1
4) run the evaluation program (see below)




CISI collection
---------------

cisi_collection.txt : The CISI collection, i.e. one file in which documents are concatenated

<document>                                                      <- Balise de début de document / starting tag of a document
<docno>doc_42</docno>                                           <- identifiant du document / id of the document
<title>18 Editions of the Dewey Decimal Classifications</title> <- Titre / Title
<text>
   The present study is a history of the DEWEY Decimal          <- Résumé / Abstract
Classification.  The first edition of the DDC was published
in 1876, the eighteenth edition in 1971, and future editions
will continue to appear as needed.  In spite of the DDC's
long and healthy life, however, its full story has never
been told.  There have been biographies of Dewey
that briefly describe his system, but this is the first
attempt to provide a detailed history of the work that
more than any other has spurred the growth of
librarianship in this country and abroad.
</text>
</document>


The query file has an almost similar format.

The cisi.rel file is the groun-truth used for the evaluation.


Stop_word list
--------------

stop_words.en.txt


evaluation.pl
-------------

evaluation programme for TREC formatted input (relevance file and result file)

Once downloaded, put execution rights 
chmod u+x evaluation.pl

To use it:
```bash
evaluation.pl -results my_result_file.res -relevance cisi.rel
```


Result file format:

num_query   'Q0'   id_document   rank  score  'Exp'

For example:
1 Q0 doc_38 1 23.5217647552 Exp\
1 Q0 doc_52 2 23.1733417511 Exp\
1 Q0 doc_53 3 23.036365509 Exp\
1 Q0 doc_76 4 22.7806720734 Exp\
...




