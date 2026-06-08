This repository holds the data collected and code to reproduce the paper: "Is there a Secret Sauce in LLM Development?" by Natalia Fischl-Lanzoni, Matthias Merterns, and Neil Thompson (MIT CSAIL). 

Data is collected following the detailed description in appendix A in the paper, linked here: https://arxiv.org/abs/2602.07238

To reproduce the results of the main paper, set the global variable "sample_def" to "default". This will create a subfolder in /results with all of the figures from the main text, as well as a .dta file that is the input to python_graphs_final notebook. Each split of the data (set by sample_def) will create a corresponding folder in results and .dta file for the python script. 
