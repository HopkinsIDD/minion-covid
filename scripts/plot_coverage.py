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

    # calculate and print the mean and median coverage based on samtools depth
    med_depth = cov["depth"].median()
    print("median depth of coverage:")
    print(med_depth)

    mean_depth = cov["depth"].mean()
    print("mean depth of coverage:")
    print(mean_depth)

    # create plot
    fig = plt.figure(figsize=(12,4),frameon=False)
    ax1 = fig.add_subplot(111)

    ax1.plot(cov["pos"],cov["depth"],color='lightgray')
    #ax1.plot(cov["pos"],cov["depth"],linestyle="None",marker='o',markerfacecolor='white',markeredgecolor='gray')

    ax1.set_xlim(0,len(cov.index))

    ymax = cov["depth"].max()
    ax1.set_ylim(0,ymax)

    ax1.set_ylabel("Read depth",rotation="vertical")
    ax1.set_xlabel("Position along genome")

    ax1.yaxis.set_label_coords(-0.06,0.5)

    apply_plot_settings(ax1)

    plt.savefig(OUTPLOT,format="pdf")
