# ufBGCtoolbox
ufBGCtoolbox consists of three modules designed for the mining of BGC domains 
and classes in metagenomic data.  
1. bgc_dom_annot: fast identification of BGC protein domains.  
2. bgc_dom_shannon: BGC domain-specific diversity estimation.  
3. bgc_model_class: BGC class relative count predictions.  

## Install

ufBGCtoolbox consists of four dokcer images: 
1. epereira/ufBGCtolbox:bgc_dom_annot 
2. epereira/ufBGCtolbox:bgc_dom_shannon 
3. epereira/ufBGCtolbox:bgc_dom_merged_shannon 
4. epereira/ufBGCtolbox:bgc_class_models

Before running ufBGCtoolbox it is necessary to install [docker](https://www.docker.com/).

Then just clone the github repository:
```
git clone git@github.com:pereiramemo/ufBGCtoolbox.git
```

All four images are in [dockerhub](https://hub.docker.com/). These will be downloaded automatically the first time you run the scripts.

## Documentation

### 1. bgc_dom_annot
This first module runs uproc using a BGC domain profile database. It takes as an input metagenomic unassembled data and outputs an abundance BGC domain profile table.

### 2. bgc_dom_shannon
This module has two different modes: sample and merge. The sample mode also takes as an input metagenomic unassembled data and generates a targeted assembly of the domains. Subsequently, it clusters these sequences and computes the Shannon diversity index and places the assembled sequences on a pre-computed reference trees. The merge mode integrates the sample mode results and computes the diversity based on rarefied subsamples.

### 3. bgc_class_models
This module is based on the bgcpred R package, which includes a library of BGC class abundance models. Based on the domain profiles generated by bgc_dom_annot, this module computes the BGC class abundance.


## ufBGCtoolbox example workflow 

### bgc_dom_annot

See help
```
sudo ./run_bgc_dom_annot.bash . . --help
```

In this example we will analize three different simulated metagenimc samples: sim_meta_oms-1, sim_meta_oms-2 and sim_meta_oms-3.

Run
```
for i in $( seq -s" " 1  3); do

  sudo ./run_bgc_dom_annot.bash \
  example/sim_meta_oms-"${i}"_redu_r1.fasta.gz\
  example/sim_meta_oms-"${i}"_redu_r1.fasta.gz \
  example/out_dom_annot"${i}" \
  --intype dna \
  --nslots 2
  
done

```

### ufBGCtoolbox: bgc_dom_shannon

See help
```
sudo ./run_bgc_dom_shannon.bash sample . . . --help
sudo ./run_bgc_dom_shannon.bash merge . . --help

```

With Docker, all input files have to be in the same directory

```
for i in $( seq -s" " 1  3); do
  sudo mv example/out_dom_annot"${i}"/pe_bgc_dom.gz example/pe_bgc_dom"${i}".gz
done
  
```
Run bgc_dom_shannon in sample mode
```
for i in $( seq -s" " 1  3); do

  sudo ./run_bgc_dom_shannon.bash sample \
  example/pe_bgc_dom"${i}".gz \
  example/sim_meta_oms-"${i}"_redu_r1.fasta.gz \
  example/sim_meta_oms-"${i}"_redu_r2.fasta.gz \
  example/out_dom_shannon"${i}" \
  --blast \
  --place_tree \
  --coverage \
  --nslots 4 \
  --domains PKS_KS,Condensation
  
done  
```

Estimated diversities:

Sample | PKS_KS | Condensation
---|---|---
sim_meta_oms-1 | 3.299 | 4.672
sim_meta_oms-2 | 2.435 | 3.928
sim_meta_oms-3 | 2.408 | 3.712

To visualize the sequence placements the Condensation_placements_tree.pdf and PKS_KS_placements_tree.pdf images are generated:

Placed Condensation sequences from sample sim_meta_oms-1
![tree PKS_KS](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/Condensation_placements_tree.png)

Placed PKS_KS sequences from sample sim_meta_oms-1
![tree PKS_KS](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_KS_placements_tree.png)

Run bgc_dom_shannon in merge mode for Condensation

```
sudo ./run_bgc_dom_shannon.bash merge \
example/out_dom_shannon1,example/out_dom_shannon2,example/out_dom_shannon3 \
example/out_dom_merged_shannon_Condensation \
--domain Condensation \
--num_iter 50 \
--sample_increment 20 \
--plot

```
Run bgc_dom_shannon in merge mode for PKS_KS
```
sudo ./run_bgc_dom_shannon.bash merge \
example/out_dom_shannon1,example/out_dom_shannon2,example/out_dom_shannon3 \
example/out_dom_merged_shannon_PKS_KS \
--domain PKS_KS \
--num_iter 50 \
--sample_increment 20 \
--plot

```

The figures Condensation_rare_div_est.pdf and PKS_KS_rare_div_est.pdf are generated showing a comparison of the Condensation and PKS_KS domain diversity between samples, respectively.

Condensation rarefaction

![rare Condensation](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/Condensation_rare_div_est.png)

PKS_KS rarefaction

![rare PKS_KS](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/PKS_KS_rare_div_est.png)

### ufBGCtoolbox: bgc_model_class	

See help
```
sudo ./run_bgc_class_models.bash . . --help
```

Run 
```

for i in $( seq -s" " 1  3); do
sudo ./run_bgc_class_models.bash \
  example/out_dom_annot"${i}"/counts.tbl \
  example/out_class_models"${i}"
done

```

Predicted abundances :

sim_meta_oms-1

![barplot1](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred1.png)

sim_meta_oms-2

![barplot2](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred2.png)

sim_meta_oms-3

![barplot3](https://github.com/pereiramemo/ufBGCtoolbox/blob/master/example/bgc_class_pred3.png)