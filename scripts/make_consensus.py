#!/usr/bin/env python

""" Function for converting nanopolish VCFs to genomes:
    calls only variants of type "SNP"
    and imposes a minimum depth for calling a non-'N' base

    Adapted from: https://github.com/blab/zika-seq/blob/master/pipeline/scripts/margin_cons.py

    MUST BE RUN WITH PYTHON3

"""

import numpy as np
import pandas as pd

import sys
import vcf

from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

from datetime import datetime


SAMPLENAME = sys.argv[1]
DIR = sys.argv[2] # directory with data for the sample

DEPTH_THRESHOLD = 3
REFERENCE = "/home/minion/sars-cov2-1/artic-ncov2019/primer_schemes/nCoV-2019/V1/nCoV-2019.reference.fasta"

vcffile = DIR+"/nanopolish/"+SAMPLENAME+".nanopolish.filt.rename.vcf.gz"
depthfile = DIR+"/nanopolish/"+SAMPLENAME+".ref.depth.txt"
outdir = DIR+"/nanopolish/"+SAMPLENAME+".ref.fasta"

print("output file for sample")
print(SAMPLENAME)

# load the depth file
depth = pd.read_csv(depthfile,delim_whitespace=True,header=None,names=["chrom","pos","depth"])
chr1 = depth

# store as dictionary to make indexing faster
chr1_keys = list(chr1["pos"])
chr1_values = list(chr1["depth"])
chr1 = dict(zip(chr1_keys,chr1_values))

# load the reference sequence
cons = ''

seq = list(SeqIO.parse(open(REFERENCE),"fasta"))[0]
cons = list(seq.seq.upper())

# iterate through positions in the reference sequence
# determine depth of the sample at this position

for n, c in enumerate(cons):

    pos = n+1 # adjust for 0-indexing

    # assume coverage is zero unless we can find the position in the depth file
    cov = 0

    if pos in chr1.keys():
        cov = chr1[pos]

    # determine if the coverage is above the threshold
    # change base to 'N' if below threshold
    if cov < DEPTH_THRESHOLD:
        cons[n] = 'N'

# save the modified reference genome to a temp file
seq = ''.join(cons)
new_record = SeqRecord(Seq(seq),id=SAMPLENAME,description="")
filepath = DIR + "/tmp/" + SAMPLENAME + ".modified.ref.fasta"
SeqIO.write(new_record, filepath, "fasta")


# open the vcf for this sample
vcf = vcf.Reader(filename=vcffile)

# initialize lists to store VCF information
# this is necessary to deal with duplicates in VCF
poslist = []
reflist=[]
altlist=[]

for record in vcf:

    if record.ALT[0] != '.':
        # variant call

        # ignore indels
        if len(record.REF)>1 or len(record.ALT[0])>1:
            continue

        # input VCF is already filtered on support values
        # so do not include code to filter on these values here

        CHROM=record.CHROM
        POS=record.POS
        ALT=record.ALT[0]
        REF=record.REF

        # confirm that the reference allele matches the current consensus
        # skip position if the consensus has already been changed to 'N'
        if cons[POS-1] != str(REF):
            
            # this should only happen if consensus is 'N'
            # unless this position is a duplicate
            if cons[POS-1]=='N':
                continue
            
            else:
                assert (POS in poslist)
                
                # also confirm the REF and ALT alleles are correct
                idx = poslist.index(POS)
                assert reflist[idx]==REF
                assert altlist[idx]==ALT
                
                # if this is a true duplicate SNP, do nothing
                continue

        # after ruling out all other issues
        # assign alternate allele to the consensus genome
        cons[POS-1] = str(ALT)

        # save information to lists
        poslist.append(POS)
        reflist.append(REF)
        altlist.append(ALT)

m=0
for base in cons:
    if base=='N':
        m = m+1

# save high quality genomes
if float((29903-m)/29903)>0.8:

    print("high quality genome, coverage = ",float((29903-m)/29903))

    # save the genome to file
    seq = ''.join(cons)
    new_record = SeqRecord(Seq(seq),id=SAMPLENAME,description="")
    SeqIO.write(new_record, outdir, "fasta")

# save lower quality genomes with warning
else:
    print("low quality genome, coverage = ",float((29903-m)/29903))

    # save the genome to file
    seq = ''.join(cons)
    new_record = SeqRecord(Seq(seq),id=SAMPLENAME,description="")
    SeqIO.write(new_record, outdir, "fasta")
