#!/usr/bin/env python

""" Function for determining the median coverage

"""

import numpy as np
import pandas as pd

import sys

#### INPUT FILES ####

DEPTHFILE = sys.argv[1]

#### BEGIN CALCULATION ####

depth = pd.read_csv(DEPTHFILE,delim_whitespace=True,header=None,names=["chrom","pos","depth"])

med = depth["depth"].median()

print("median depth of coverage")
print(med)

mean_depth = depth["depth"].mean()

print("mean depth of coverage")
print(mean_depth)
