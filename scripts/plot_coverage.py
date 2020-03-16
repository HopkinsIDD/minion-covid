#!/usr/bin/env python

import numpy as np
import pandas as pd
import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

DEPTH_FILE = sys.argv[1]
OUTPLOT = sys.argv[2]

def apply_plot_settings(ax):

    """Removes unwanted axis and grid lines
       Must be applied to an existing plot axis"""

    #tick mark and axes settings
    ax.tick_params(axis='x',       #changes apply to the x-axis
                which='both',      #both major and minor ticks are affected
                bottom=True,       #ticks along the bottom edge are on
                top=False,         #ticks along the top edge are off
                labelbottom=True)  #labels along the bottom edge are on

    ax.tick_params(axis='y',       #changes apply to the y-axis
                which='both',      #both major and minor ticks are affected
                left=True,         #ticks along the left edge are on
                right=False,       #ticks along the right edge are off
                labelleft=True)    #labels along the left edge are on

    ax.xaxis.grid(False)
    ax.spines['right'].set_visible(False)
    ax.spines['top'].set_visible(False)


if __name__ == "__main__":

    # load samtools depth output as dataframe
    cov = pd.read_csv(DEPTH_FILE,sep='\t',header=None,names=["ref","pos","depth"])

    # separate chromosomes
    chrom1 = cov[cov["pos"]<2961182]
    chrom2 = cov[cov["pos"]>2961181]
    chrom2["pos"] = df["pos"].apply(lambda x: x - 2961181)

    # create plot
    fig = plt.figure(figsize=(12,4),frameon=False)
    ax1 = fig.add_subplot(211)
    ax2 = fig.add_subplot(212)

    ax1.plot(chrom1["pos"],chrom1["depth"],color='lightgray')
    ax2.plot(chrom2["pos"],chrom2["depth"],color='lightgray')

    ax1.set_xlim(0,len(chrom1.index))
    ax2.set_xlim(0,len(chrom1.index))

    ymax = max(chrom1["depth"].max(),chrom2["depth"].max())
    ax1.set_ylim(-25,ymax)
    ax2.set_ylim(-25,ymax)

    ax1.set_ylabel("chrom1",rotation="horizontal")
    ax2.set_ylabel("chrom2",rotation="horizontal")

    ax1.yaxis.set_label_coords(-0.09,0.5)
    ax2.yaxis.set_label_coords(-0.09,0.5)

    apply_plot_settings(ax1)
    apply_plot_settings(ax2)

    plt.savefig(OUTPLOT,format="pdf")
