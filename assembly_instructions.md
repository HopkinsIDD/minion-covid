### SARS-CoV-2 Referenced-Based Genome Assembly from Oxford Nanopore Data

This is a guide for taking reads generated on a Oxford Nanopore sequencer and assembly by aligning reads to a reference. Note that this guide is not optimized for reads generated with short amplicons.

##### Table of Contents

* [Setting up your working directory](#setting-up-your-working-directory)
* [Installation](#installation)
* [Basecalling](#basecalling)
* [Visualizing run metrics](#visualizing-run-metrics)
* [Demultiplexing](#demultiplexing)
* [Assembly](#assembly)

##### Setting up your working directory

Before you start, you will need to clone this repository. Cloning the repository will ensure you have all the necessary scripts and folders to run the analysis.

First, let's create a project directory to store all the analyses for this sequencing run. This will be your **working directory** for the rest of this process. Open up a terminal window and type the following command:

```
mkdir my-project
```
Where **my-project** can be any name you chose to represent this sequencing run.

To enter this directory, type:

```
cd my-project
```

To get the full path to this directory, now type:

```
pwd
```

The output, which might look something like `/home/username/my-project/`, will be your **working directory** for this analysis. Anytime you are asked to provide the path to your working directory, copy in this information.

From inside your **working directory**, type the following commands to copy this github repository onto your computer

```
apt update
apt install git
```

Now you can use git to clone the repository:

```
git clone https://github.com/HopkinsIDD/minion-covid.git .
```

###### Finding your raw data


##### Installation

If you have not installed the software needed for assembly, run the following installation script:

```
bash
```



##### Basecalling

##### Visualizing run metrics

##### Demultiplexing

##### Assembly