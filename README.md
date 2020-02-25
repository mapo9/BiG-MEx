# BiG-MEx
BiG-MEx: a tool for the mining of Biosynthetic Gene Cluster (BGC) domains and classes in metagenomic data. It consists of the following modules:
1. run_bgc_dom_annot: fast identification of BGC protein domains.  
2. run_bgc_dom_div: BGC domain-based diversity analysis.  
3. run_bgc_class_pred: BGC class abundance predictions.  

## Citation
Pereira-Flores, E., Buttigieg, P. L., Medema, M. H., Meinicke, P., Glöckner, F. O. and Fernandez-Guerra, A.. (2018+). _Mining metagenomes for natural product biosynthetic gene clusters: unlocking new potential with ultrafast techniques_. Under review.

## Installation
BiG-MEx consists of five docker images: 
1. epereira/bgc_dom_annot  
2. epereira/bgc_dom_amp_div  
3. epereira/bgc_dom_meta_div  
4. epereira/bgc_dom_merge_div  
5. epereira/bgc_class_pred  

Before running BiG-MEx it is necessary to install [docker](https://www.docker.com/).

Then just clone the GitHub repository:
```
git clone git@github.com:pereiramemo/BiG-MEx.git
```

All four images are in [dockerhub](https://hub.docker.com/). These will be downloaded automatically the first time you run the scripts.

## Documentation

The run_bgc_\*.bash scripts run the docker images, which include all the code, dependencies and data used in the analysis. Given that we are using [docker](https://www.docker.com/), if your user is not in the [docker group](https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user) in Linux or Mac OS, the run_bgc_\*.bash scripts have to be executed with sudo.

### 1. bgc_dom_annot
This first module runs [UProC](http://uproc.gobics.de/) using a BGC domain profile database. It takes as an input metagenomic unassembled data and outputs a BGC domain abundance profile table.

See help
```
./run_bgc_dom_annot.bash . . --help
```

### 2. bgc_dom_div

The **bgc_dom_div** has three different modes: amplicon (amp), metagenome (meta), and merge. The first two modes have the objective of analyzing the BGC domain diversity in amplicon and metagenomic samples. The diversity analysis consists of estimating the operational domain unit (ODU) diversity, blasting the domain sequences against a reference database, and placing the domain sequences onto reference trees.
The merge mode integrates the amplicon or metagenome diversity results of different samples to provide a comparative analysis.

See help
```
./run_bgc_dom_div.bash amp . . --help

./run_bgc_dom_div.bash meta . . . --help

./run_bgc_dom_div.bash merge . .  --help
```

### 3. bgc_class_pred
This module is based on the [bgcpred](https://github.com/pereiramemo/bgcpred) R package, which includes a library of BGC class abundance models. Based on the domain profile generated by bgc_dom_annot, this module computes the BGC class abundance profile.

See help
```
./run_bgc_class_pred.bash . . --help
```

### See the [wiki](https://github.com/pereiramemo/BiG-MEx/wiki) for further documentation.
