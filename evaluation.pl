#!/usr/bin/perl

###############################################################################
# script:      evaluation.pl
# description: computes mean recall and precision values for the DCVs given in 
#              the @dcvs array, and the MAP for cisi collection. Input 
#              directory must contain only result file named as follows: 
#              queryNumber[.ext] (.ext: free optionnal extension). 
#              Result files must contain only numbers of retrieved documents,
#              one per line.
# parameters:  results: result file
#              relevance: location of the cisi.rel file (relevance judgements)
# created:     01/08/09
# modified:    01/11/12
# author:      P. Tirilly - pierre.tirilly@irisa.fr
###############################################################################

use strict;
use Getopt::Long;

my $resultFile;
my $relevanceFile;
GetOptions("results:s"=>\$resultFile,
	   "relevance:s"=>\$relevanceFile);

my $usage = "USAGE:\n\nevaluation.pl -results my_result_file.txt -relevance my_relevance_file.txt\n";
if (not -f $resultFile or not -f $relevanceFile)
{
    die $usage
}




# DCV used
my @dcvs = (5, 10, 20, 30);

# First: read relevance data
my %relevance;
open(RELFILE, $relevanceFile) or die "Error: cannot open relevance file $relevanceFile: $!";
while(my $line = <RELFILE>) {
  #if($line =~ /^\s*(\d+)\s+(\d+)\s+\d+\s+\d+\.\d+\s*$/) 
  if($line =~ /^([^\t ]+)[\t ]+Q0[\t ]+([^ \t]+)[ \t]1$/) # version TREC
  {
    my $query = $1; my $doc = $2;  
    $relevance{$query}{$doc}++;
  }
}
close(RELFILE);


# Then: compute measures
my @precision;
my @recall;
my $MAP = 0;
my $recallNumber = 0;
my $precisionNumber = 0;

open(FILE, $resultFile) or die "Error while opening result file $resultFile: $!";
my %h_query2did;
while(my $l = <FILE>) 
{
    if ($l =~ /^([^\t ]+)\tQ0\t([^\t]+)\t([^ \t\n]+)/)
    { $h_query2did{$1}{$3}=$2 }
    elsif ($l =~ /^([^ ]+) Q0 ([^ \t]+) ([^ \t\n]+)/)
    { $h_query2did{$1}{$3}=$2 }
}
close FILE;

foreach my $queryId (keys %h_query2did)
{
    my @results = map {$h_query2did{$queryId}{$_}} sort {$a<=>$b} keys %{$h_query2did{$queryId}};

    # compute measures
    # recall: only if there are relevant documents
    if(exists $relevance{$queryId} and scalar(keys %{$relevance{$queryId}}) > 0) 
    {
	for my $i (0..$#dcvs) 
	{ $recall[$i] += &compute_recall(\@results, $queryId, $dcvs[$i]) }
	$recallNumber++;
    }
  
    # precision: only if there are retrieved documents
    if(scalar(@results) > 0) 
    {
	for my $i (0..$#dcvs) 
	{ $precision[$i] += &compute_precision(\@results, $queryId, $dcvs[$i]) }
	$precisionNumber++;
	$MAP += &compute_AP(\@results, $queryId);
    }

    #print $queryId,' ',scalar(keys %{$relevance{$queryId}}), ' ',$precision[0], ' ', $recallNumber, ' ',$precisionNumber,"\n";
    #<STDIN>;

}




#opendir(RESDIR, $resultDir) or die "Error: cannot open result directory $resultDir: $!";
#my $file;
#while($file = readdir(RESDIR)) { #for each result file
#  unless(-f "$resultDir/$file") {next;}
#
#
#  # read the results
#  my @results;
#  open(FILE, "$resultDir/$file") or die "Error while opening result file $resultDir/$file: $!";
#  my $line;
#  while($line = <FILE>) {
#    chomp($line);
#    unless($line =~ /^\s*(\d+)\s*$/) {die "Error: file $file has not the right format. Found: $line";}
#    push(@results, $1);
#  }
#  close(FILE);
#  
#  # get the query ID
#  my $queryId = $file;
#  $queryId =~ /(\d+)(\..*)?$/;
#  $queryId = $1;
#  
#  # compute measures
#  # recall: only if there are relevant documents
#  if(exists $relevance{$queryId} and scalar(keys %{$relevance{$queryId}}) > 0) {
#    for(my $i=0 ; $i<=$#dcvs ; $i++) {
#      $recall[$i] += &compute_recall(\@results, $queryId, $dcvs[$i]);
#    }
#    $recallNumber++;
#  }
#  
#  # precision: only if there are retrieved documents
#  if(scalar(@results) > 0) {
#    for(my $i=0 ; $i<=$#dcvs ; $i++) {
#      #print STDERR "rel = @{$relevance{$queryId}}\n";
#      $precision[$i] += &compute_precision(\@results, $queryId, $dcvs[$i]);
#    }
#    $precisionNumber++;
#    $MAP += &compute_AP(\@results, $queryId);
#  }
#}
#close(RESDIR);

# compute mean values

for my $i (0..$#dcvs) {
  if($precisionNumber != 0) {
    $precision[$i] = $precision[$i]/$precisionNumber;
  }
  if($recallNumber != 0) {
    $recall[$i] = $recall[$i]/$recallNumber;
  }
}
if($precisionNumber != 0) {
  $MAP = $MAP/$precisionNumber;
}

# print results
for(my $i=0 ; $i<=$#dcvs ; $i++) {
  print "DCV = $dcvs[$i]: P=$precision[$i]; R=$recall[$i]\n";
}
print "MAP = $MAP\n";



###############################################################################
###########                     subroutines               #####################
###############################################################################


sub compute_precision{
  my ($resRef,$queryId, $dcv) = @_;
  
  my $precision = 0.0;
  if (exists $relevance{$queryId} and scalar(keys %{$relevance{$queryId}})>0) # s'il y a des reponses dans le fichier relevance
  { 
      my $maxDoc = &min(scalar(@$resRef), $dcv);
      for(my $i=0 ; $i<$maxDoc ; $i++) 
      {
	  if (exists $relevance{$queryId}{$resRef->[$i]})
	  { $precision++ }
      }
      $precision = $precision/$maxDoc;
  }
  return $precision;
}


sub compute_recall{
  my ($resRef, $queryId, $dcv) = @_;
  
  my $recall = 0.0;
  
  for(my $i=0 ; $i<$dcv and $i<scalar(@$resRef); $i++) 
  {
      if (exists $relevance{$queryId}{$resRef->[$i]})
      { $recall++; }
  }
  $recall = $recall/scalar(keys %{$relevance{$queryId}});
  return $recall;
}


sub compute_AP{
  my $resRef = $_[0];
  my $queryId = $_[1];
  
  # Case of a query with no relevant document
  if(not exists $relevance{$queryId} or scalar(keys %{$relevance{$queryId}})==0) {
    if(scalar(@$resRef) == 0) {
      return 1.0;
    } else {
      return 0.0;
    }
  }
  
  my $AP = 0;
  my $relevantFound = 0;
  for(my $i=0 ; $i<scalar(@$resRef) ; $i++) 
  {
      if (exists $relevance{$queryId}{$resRef->[$i]})
      {
	  $relevantFound++;
	  $AP += $relevantFound/($i+1);
      }
  }
  # on prend en compte les docs pertinents non retrouves
  # en divisant par le nb de pertinents au lieu du 
  # nb de pertinents retrouvés, ça revient
  # bien à donner une précision nulle aux docs non ramenés
  #if ($relevantFound > 0) { $AP /= $relevantFound }
  if ($relevantFound > 0) { $AP /= scalar(keys %{$relevance{$queryId}}) } 
  else { $AP = 0 }
  return $AP;
}


sub min{
  my $a = $_[0];
  my $b = $_[1];

  if($a < $b) {
    return $a;
  } else {
    return $b;
  }
}
