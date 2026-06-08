/*

This file replicates all results of the main paper and allows for sample size restrictions

*/


*Global variables to set up sample definition and output folder
global root "/Users/natalia/Desktop/FutureTech/secret_sauce"

global datapath "/Users/natalia/Desktop/FutureTech/secret_sauce/data"


* Choose one sample definition below.
* Options:
*   default         - baseline sample, no extra restrictions beyond the core rules
* total_token_count - keeps 255 models of full token count
* moe controlls for moe. 
* no_lifearch - drops life architecture models
* math -replicated results with MATH Level 5 benchmark
* reasoning - includes reasoning models (make sure to comment out the drop line)
* hugging face - keeps only hugging face models 
* asym07 - uses a asymmetric logit with parameter 0.7
* asym12 - uses an asymmetric logit with parameter 1.2


global sample_def "default"

global resultspath "/Users/natalia/Desktop/FutureTech/secret_sauce/output/$sample_def"

global figpath "$resultspath/${sample_def}_figs"

cap mkdir "$resultspath"

cap mkdir "$figpath"

use "$datapath/final_for_analysis.dta", clear

*Variable Definitionloc
gen All_token_info = TotalTokenCount
replace All_token_info = BaseModelTokenCount if All_token_info ==. 

bys yq: egen double max_all_score = max(mmlu_pro_acc)
gen math_adj = MATHLvl5Raw 

*Drops that happen in all cases:
drop if yq == .
drop if yq >=tq(2025q2)
drop if yq < tq(2022q4)
drop if reasoning == 1
drop if MATHLvl5Raw == .
keep if All_token_info != . & ParamsB != . 
keep if yq < tq(2025q2)


* Sample-definition switch based on sample_def global
if "$sample_def" == "base_model" {
    keep if inlist(Type, " continuously pretrained", " pretrained")
}

if "$sample_def" == "huggingface" {
    keep if hugging_face_model == 1
}

if "$sample_def" == "no_lifearch" {
	drop if life_arch_model == 1
}

global moe ""
if "$sample_def" == "moe" {
	replace MoE = 1 if model_id == "Gemini-1.5-Pro"
	replace MoE = 1 if model_id == "Gemini-1.5-Flash"
	replace MoE = 0 if model_id == "Gemma-2-27B-it"
	replace MoE = 0 if model_id == "Gemma-2-9B-it"
	replace MoE = 1 if model_id == "Deepseek-V3"
	replace MoE = 1 if model_id == "Gemma-3-27B-it"
	drop if MoE == .
	global moe "MoE"

}

if "$sample_def" == "reasoning" {
	//comment out drop reasoning
}

if "$sample_def" == "total_token_count" {
	keep if TotalTokenCount != .
}



*Variable Definition 
//variable definition
{
gen acc_norm_new = (mmlu_pro_acc - 0.1) / 0.9
gen logit_mmlu = log( (acc_norm_new ) / (1 - (acc_norm_new )) )
generate log_flops = log(6 * ParamsB * All_token_info)
generate log_flops2 = log_flops^2
generate log_flops3 = log_flops^3

gen logit_mmlu2 = log( ((acc_norm_new ) / (1 - (acc_norm_new )))^0.5 )
gen logit_mmlu3 = log( ((acc_norm_new ) / (1 - (acc_norm_new )))^5 )
gen logit_mmlu4 = log( ((acc_norm_new ) / (1 - (acc_norm_new )))^0.1 )



	//size groups 
		
bys model_prefix: egen M_flops = mean(log_flops)



gen size_q = 1 if M_flops <= 12
replace size_q = 2 if M_flops > 12  & M_flops <= 15.5
replace size_q = 3 if M_flops > 15.5

	
	
//gen firm dummies
label def top_ten_comp 0 "Other" 1 "Deepseek" 2 "Qwen" 3 "Meta" 4 "Google" 5 "Microsoft" 6 "Mistral" 7  "OpenAI" 8 "Anthropic" 9 "X-AI" 10 "01-AI" 11 "Nvidia" 12 "IBM" 13 "Other, Small" 14 "Other, Med" 15 "Other, Large"
gen top_ten_comp = 0
replace top_ten_comp = 1 if model_prefix == "deepseek-ai"
replace top_ten_comp = 2 if model_prefix == "Qwen"
replace top_ten_comp = 3 if model_prefix == "meta-llama"
replace top_ten_comp = 4 if model_prefix == "google"
replace top_ten_comp = 5 if model_prefix == "microsoft"
*replace top_ten_comp = 6 if model_prefix == "mistralai"
replace top_ten_comp = 7 if model_prefix == "open_ai"
replace top_ten_comp = 8 if model_prefix == "anthropic"
replace top_ten_comp = 9 if model_prefix == "grok"
replace top_ten_comp = 10 if model_prefix == "01-ai"
replace top_ten_comp = 11 if model_prefix == "nvidia"
*replace top_ten_comp = 12 if model_prefix == "ibm-granite"



//implement baseline cateogires for different size groups
replace top_ten_comp = 13 if top_ten_comp == 0 & size_q ==1 
replace top_ten_comp = 14 if top_ten_comp == 0 & size_q ==2 
replace top_ten_comp = 15 if top_ten_comp == 0 & size_q ==3


label values top_ten_comp top_ten_comp

*creating a grouped time dummy 
gen more_grouped_time = .
replace more_grouped_time = 0 if yq <= tq(2023q3)
replace more_grouped_time = 1 if (yq == tq(2023q4) | yq == tq(2024q1))
replace more_grouped_time = 2 if (yq == tq(2024q2) | yq == tq(2024q3))
replace more_grouped_time = 3 if (yq == tq(2024q4) | yq == tq(2025q1))

label def more_grouped_time 0 "Early" 1 "2023q4-2024q1" 2 "2024q2-3" 3 "2024q4-2025q1" 
label val more_grouped_time more_grouped_time


gen three_time = .
replace three_time = 0 if (yq <= tq(2023q3))
replace three_time = 1 if ( yq == tq(2023q4) | yq == tq(2024q1) | yq == tq(2024q2))
replace three_time = 2 if (yq == tq(2024q3) | yq == tq(2024q4) | yq == tq(2025q1))
label def three_time 0 "2022q4-2023q3" 1 "2023q4-2024q2" 2 "2024q3-2025q1"
label val three_time three_time

cap drop two_time
gen two_time = .
replace two_time = 0 if (yq < tq(2024q1))
replace two_time = 1 if (yq >= tq(2024q1))
cap label def two_time 0 "2022q4-2023q4"  1 "2024q1-2025q1"
label val two_time two_time



}
//close variable def

//converting to base 10 flops for the graphs, need to convert params and dataset from billions
gen double params_raw = ParamsB * 1e9
gen double All_token_info_raw = All_token_info * 1e9

gen double log_10_flops = log10(6 * params_raw * All_token_info_raw)
summarize log_10_flops, detail

	* Calculate M_flops in log10 scale (mean log10 flops by company)
bys model_prefix: egen M_flops_log10 = mean(log_10_flops)


gen logit_math = log(MATHLvl5Raw/(1-MATHLvl5Raw))

if "$sample_def" == "asym07" {
	local a 0.4400166
	local b -6.736999
	local v 0.7

	gen logit_mmlu_asym7 = (log((acc_norm_new^`v') / (1 - acc_norm_new^`v')) - `b') / `a'
	
	replace logit_mmlu = logit_mmlu_asym7
	
}

if "$sample_def" == "asym12" {
	local a 0.4400166
	local b -6.736999
	local v 1.2

	gen logit_mmlu_asym12 = (log((acc_norm_new^`v') / (1 - acc_norm_new^`v')) - `b') / `a'
	
	replace logit_mmlu = logit_mmlu_asym12
}


if "$sample_def" == "math" {
	replace logit_mmlu = logit_math
	replace acc_norm_new = MATHLvl5Raw
}

//keep whats needed
keep acc_norm_new mmlu_pro_acc ym  M_flops size_q  yq logit_mmlu  log_flops log_flops2 log_flops3  model_id two_time  three_time  top_ten_comp  acc_norm_new     ParamsB  All_token_info   log_flops   logit_mmlu  log_10_flops  M_flops_log10 params_raw All_token_info_raw MATHLvl5Raw logit_math model_prefix eval_name BaseModelTokenCount TotalTokenCount MoE reasoning 

*save "$datapath/Data_secret_sauce.dta", replace 
save "$resultspath/help.dta", replace 





*********************************
*Figure 1: Shapley Decomposition
*********************************
tab three_time, gen(threetime_)
tab top_ten_comp, gen(top10_)
drop threetime_1

* Automatically drop the dummy for "Other, Small" (top_ten_comp == 13)
levelsof top_ten_comp, local(levels)
local pos = 1
foreach val of local levels {
    if `val' == 13 {
        drop top10_`pos'
        local other_small_dropped = 1
    }
    local pos = `pos' + 1
}

bysort three_time:  egen median_size = median(log_10_flops) if  top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15


*egen median_size = median(log_10_flops) if  top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15
gen above_med = 1 if log_10_flops >  median_size & log_10_flops !=. & top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15 
gen below_med = 1 if log_10_flops <=  median_size & log_10_flops !=.   & top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15

egen p33 = pctile(log_10_flops) if  top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15 , p(33)
egen p66 = pctile(log_10_flops) if  top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15 , p(66)
gen large = 1 if log_10_flops >  p66 & log_10_flops !=. & top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15 
gen small = 1 if log_10_flops <  p33 & log_10_flops !=.   & top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15


reg logit_mmlu log_10_flops threetime_* top10_* $moe , vce(cluster top_ten_comp)

* Build dynamic group specification for shapley2
unab threetime_vars : threetime_*
local threetime_group : list threetime_vars - threetime_1
unab top10_vars : top10_*

* When sample_def == "moe", $moe expands to "MoE" and we add it as a 4th group in
* the decomposition (between Company Secret Sauce and the residual). Otherwise
* moe_group is empty and the baseline 3-group structure is unchanged.
local moe_group ""
if "$sample_def" == "moe" {
    local moe_group ", $moe"
}

shapley2 log_10_flops threetime_* top10_* $moe, stat(r2) ///
group(log_10_flops, `threetime_group', `top10_vars'`moe_group')

* Dynamically generate Shapley decomposition graph
matrix shap = e(shapley)

local total_explained = 0

* Compute contribution
local compute_contrib = shap[1,1]
local total_explained = `total_explained' + `compute_contrib'

* Time contribution (grouped threetime_2 and threetime_3)
local time_contrib = shap[2,1]
local total_explained = `total_explained' + `time_contrib'

* Company/Model Specific Effects contribution (grouped all top10_*)
local company_contrib = shap[3,1]
local total_explained = `total_explained' + `company_contrib'

* MoE contribution (only present when sample_def == "moe")
local moe_contrib = 0
if "$sample_def" == "moe" {
    local moe_contrib = shap[4,1]
    local total_explained = `total_explained' + `moe_contrib'
}

* Residual (unexplained variation)
local residual = 1 - `total_explained'

* Create dataset for graph (4 bars baseline, 5 bars when moe sample)
preserve
clear
local n_groups = cond("$sample_def" == "moe", 5, 4)
set obs `n_groups'
gen factor = ""
gen shapley_value = .
gen percent = .
replace factor = "Scaling" in 1
replace shapley_value = `compute_contrib' in 1
replace percent = `compute_contrib' * 100 in 1
replace factor = "Shared alg. progress" in 2
replace shapley_value = `time_contrib' in 2
replace percent = `time_contrib' * 100 in 2
replace factor = "Company Secret Sauce" in 3
replace shapley_value = `company_contrib' in 3
replace percent = `company_contrib' * 100 in 3
if "$sample_def" == "moe" {
    replace factor = "MoE" in 4
    replace shapley_value = `moe_contrib' in 4
    replace percent = `moe_contrib' * 100 in 4
    replace factor = "Model Effects" in 5
    replace shapley_value = `residual' in 5
    replace percent = `residual' * 100 in 5
}
else {
    replace factor = "Model Effects" in 4
    replace shapley_value = `residual' in 4
    replace percent = `residual' * 100 in 4
}

gen order = _n
gen xpos = order
gen pct_label = string(round(percent, 0.1)) + "%"
replace pct_label = "0" + pct_label if percent < 1 & percent > 0
gen mid = shapley_value / 2
gen xpos_label = xpos - 0.10

* If shared alg. progress is too small to fit a label inside the bar, place it above the bar instead
replace mid = shapley_value + 0.025 if order == 2 & percent < 3
* Same for the MoE bar (order 4) when running the moe sample — its share is typically tiny
replace mid = shapley_value + 0.025 if order == 4 & percent < 3 & "$sample_def" == "moe"


if "$sample_def" == "moe" {
    * 5-bar layout: Scaling, Shared progress, Company SS, MoE | Model Effects (residual)
    twoway ///
        (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
        (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
        (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
        (bar shapley_value xpos if order==4, barwidth(0.6) color(eltblue%80)) ///
        (bar shapley_value xpos if order==5, barwidth(0.6) color(gs12%80)) ///
        (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==2 & percent >= 3, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==2 & percent <  3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==5, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) , ///
        ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
        yscale(range(0 0.68)) ///
        ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
        xtitle("") ///
        xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 "MoE" 5 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
        title("") ///
        legend(off) ///
        xline(4.5, lpattern(dash) lcolor(black)) ///
        text(0.58 2.5 "Shapley Decomposition", size(5) color(black)) ///
        text(0.62 5 "Regression" "Residual", size(5) color(black)) ///
        xsize(14) ysize(5) ylabel(,format(%3.1f))
}
else {
    twoway ///
        (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
        (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
        (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
        (bar shapley_value xpos if order==4, barwidth(0.6) color(gs12%80)) ///
        (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==2 & percent >= 3, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==2 & percent <  3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
        (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)), ///
        ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
        yscale(range(0 0.68)) ///
        ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
        xtitle("") ///
        xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
        title("") ///
        legend(off) ///
        xline(3.5, lpattern(dash) lcolor(black)) ///
        text(0.58 2 "Shapley Decomposition", size(5) color(black)) ///
        text(0.62 4 "Regression" "Residual", size(5) color(black)) ///
        xsize(11) ysize(5) ylabel(,format(%3.1f))
}
graph export "$figpath/shapley_stacked_bar_baseline.pdf", replace
*graph export "$resultspath/shapley_stacked_bar_baseline.eps", replace
restore

if "$sample_def" == "default" {
	
//exclude other models
preserve
local company_vars top10_1 top10_2 top10_3 top10_4 top10_5 top10_6 top10_7 top10_8 top10_9 top10_10 
reg logit_mmlu log_10_flops threetime_* `company_vars' if top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15, vce(cluster top_ten_comp)
shapley2 log_10_flops threetime_* `company_vars', stat(r2) ///
group(log_10_flops, threetime_2 threetime_3, `company_vars')

matrix shap = e(shapley)
local compute_contrib = shap[1,1]
local time_contrib    = shap[2,1]
local company_contrib = shap[3,1]
local residual        = 1 - `compute_contrib' - `time_contrib' - `company_contrib'

clear
set obs 4
gen factor = ""
gen shapley_value = .
gen percent = .
replace factor = "Scaling" in 1
replace shapley_value = `compute_contrib' in 1
replace percent = `compute_contrib' * 100 in 1
replace factor = "Shared alg. progress" in 2
replace shapley_value = `time_contrib' in 2
replace percent = `time_contrib' * 100 in 2
replace factor = "Company Secret Sauce" in 3
replace shapley_value = `company_contrib' in 3
replace percent = `company_contrib' * 100 in 3
replace factor = "Model Effects" in 4
replace shapley_value = `residual' in 4
replace percent = `residual' * 100 in 4

gen order = _n
gen xpos = order
gen pct_label = string(round(percent, 0.1)) + "%"
replace pct_label = "0" + pct_label if percent < 1 & percent > 0
gen mid = shapley_value / 2
gen xpos_label = xpos - 0.10

* If shared alg. progress is too small to fit a label inside the bar, place it above the bar instead
replace mid = shapley_value + 0.025 if order == 2 & percent < 3

twoway ///
    (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
    (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
    (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
    (bar shapley_value xpos if order==4, barwidth(0.6) color(gs12%80)) ///
    (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2 & percent >= 3, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2 & percent <  3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)), ///
    ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
		yscale(range(0 0.68)) ///
	text(0.58 2 "Shapley Decomposition", size(5) color(black)) ///
    text(0.62 4 "Regression" "Residual", size(5) color(black)) ///
		xline(3.5, lpattern(dash) lcolor(black)) ///
    ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
    xtitle("") ///
    xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
    title("") ///
    legend(off) ///
	xsize(11) ysize(5) ylabel(,format(%3.1f))
graph export "$figpath/shapley_stacked_bar_noOther.pdf", replace
*graph export "$resultspath/shapley_stacked_bar_noOTher.eps", replace
restore




// small
preserve
local company_vars top10_1 top10_2 top10_3 top10_4 top10_5 top10_6 top10_7 top10_8 top10_9 top10_10 
reg logit_mmlu log_10_flops threetime_* `company_vars' if below_med == 1 & top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15, vce(cluster top_ten_comp)
shapley2 log_10_flops threetime_* `company_vars', stat(r2) ///
group(log_10_flops, threetime_2 threetime_3, `company_vars')

matrix shap = e(shapley)
local compute_contrib = shap[1,1]
local time_contrib    = shap[2,1]
local company_contrib = shap[3,1]
local residual        = 1 - `compute_contrib' - `time_contrib' - `company_contrib'

clear
set obs 4
gen factor = ""
gen shapley_value = .
gen percent = .
replace factor = "Scaling" in 1
replace shapley_value = `compute_contrib' in 1
replace percent = `compute_contrib' * 100 in 1
replace factor = "Shared alg. progress" in 2
replace shapley_value = `time_contrib' in 2
replace percent = `time_contrib' * 100 in 2
replace factor = "Company Secret Sauce" in 3
replace shapley_value = `company_contrib' in 3
replace percent = `company_contrib' * 100 in 3
replace factor = "Model Effects" in 4
replace shapley_value = `residual' in 4
replace percent = `residual' * 100 in 4

gen order = _n
gen xpos = order
gen pct_label = string(round(percent, 0.1)) + "%"
replace pct_label = "0" + pct_label if percent < 1 & percent > 0
gen mid = shapley_value / 2
gen xpos_label = xpos - 0.10

* If shared alg. progress is too small to fit a label inside the bar, place it above the bar instead
replace mid = shapley_value + 0.025 if order == 2 & percent < 3

twoway ///
    (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
    (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
    (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
    (bar shapley_value xpos if order==4, barwidth(0.6) color(gs12%80)) ///
    (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2 & percent >= 3, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2 & percent <  3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)), ///
    ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
    ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
		yscale(range(0 0.68)) ///
			xline(3.5, lpattern(dash) lcolor(black)) ///
	text(0.58 2 "Shapley Decomposition", size(5) color(black)) ///
    text(0.62 4 "Regression" "Residual", size(5) color(black)) ///
    xtitle("") ///
    xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
    title("") ///
    legend(off) ///
	xsize(11) ysize(5) ylabel(,format(%3.1f))
graph export "$figpath/shapley_stacked_bar_Small_no_other.pdf", replace
*graph export "$resultspath/shapley_stacked_bar_Small_no_other.eps", replace
restore
	
	
	
	
// large
preserve
local company_vars top10_1 top10_2 top10_3 top10_4 top10_5 top10_6 top10_7 top10_8 top10_9 top10_10 
reg logit_mmlu log_10_flops threetime_* `company_vars' if above_med == 1 & top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15, vce(cluster top_ten_comp)
shapley2 log_10_flops threetime_* `company_vars', stat(r2) ///
group(log_10_flops, threetime_2 threetime_3, `company_vars')

matrix shap = e(shapley)
local compute_contrib = shap[1,1]
local time_contrib    = shap[2,1]
local company_contrib = shap[3,1]
local residual        = 1 - `compute_contrib' - `time_contrib' - `company_contrib'

clear
set obs 4
gen factor = ""
gen shapley_value = .
gen percent = .
replace factor = "Scaling" in 1
replace shapley_value = `compute_contrib' in 1
replace percent = `compute_contrib' * 100 in 1
replace factor = "Shared alg. progress" in 2
replace shapley_value = `time_contrib' in 2
replace percent = `time_contrib' * 100 in 2
replace factor = "Company Secret Sauce" in 3
replace shapley_value = `company_contrib' in 3
replace percent = `company_contrib' * 100 in 3
replace factor = "Model Effects" in 4
replace shapley_value = `residual' in 4
replace percent = `residual' * 100 in 4

gen order = _n
gen xpos = order
gen pct_label = string(round(percent, 0.1)) + "%"
replace pct_label = "0" + pct_label if percent < 1 & percent > 0
gen mid = shapley_value / 2
gen xpos_label = xpos - 0.10

* If shared alg. progress is too small to fit a label inside the bar, place it above the bar instead
replace mid = shapley_value + 0.025 if order == 2 & percent < 3

twoway ///
    (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
    (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
    (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
    (bar shapley_value xpos if order==4, barwidth(0.6) color(gs12%80)) ///
    (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2 & percent >= 3, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2 & percent <  3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)), ///
    ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
    ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
			yscale(range(0 0.68)) ///
			xline(3.5, lpattern(dash) lcolor(black)) ///
	text(0.58 2 "Shapley Decomposition", size(5) color(black)) ///
    text(0.62 4 "Regression" "Residual", size(5) color(black)) ///
    xtitle("") ///
    xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
    title("") ///
    legend(off) ///
	xsize(11) ysize(5) ylabel(,format(%3.1f))
graph export "$figpath/shapley_stacked_bar_large_no_other.pdf", replace
*graph export "$resultspath/shapley_stacked_bar_large_no_other.eps", replace
restore


**Shapley of Robustness Checks over Time:
clear
input str30 factor shapley_value percent
"Scaling" 0.31590 31.590
"Shared algorithmic progress" 0.05587 5.587
"Company Secret Sauce" 0.17351 17.351
"Model-Specific Effects" 0.455 45.5
end

gen order = _n
gen xpos = order
gen pct_label = string(round(percent, 0.1)) + "%"
gen mid = shapley_value / 2
gen xpos_label = xpos - 0.10


twoway ///
    (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
    (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
    (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
    (bar shapley_value xpos if order==4, barwidth(0.6) color(gs12%80)) ///
    (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)), ///
    ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
    ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
			yscale(range(0 0.68)) ///
			xline(3.5, lpattern(dash) lcolor(black)) ///
	text(0.58 2 "Shapley Decomposition", size(5) color(black)) ///
    text(0.62 4 "Regression" "Residual", size(5) color(black)) ///
    xtitle("") ///
    xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
    title("") ///
    legend(off) ///
	xsize(11) ysize(5) ylabel(,format(%3.1f))
graph export "$resultspath/shapley_stacked_bar_yq.pdf", replace
*graph export "$resultspath/shapley_stacked_bar_baseline.eps", replace


clear
input str30 factor shapley_value percent
"Scaling" 0.31834 31.834
"Shared algorithmic progress" 0.03209 3.209
"Company Secret Sauce" 0.17810 17.810
"Model-Specific Effects" 0.47147 47.1
end

gen order = _n
gen xpos = order
gen pct_label = string(round(percent, 0.1)) + "%"
gen mid = shapley_value / 2
gen xpos_label = xpos - 0.10
replace mid = shapley_value + 0.025 if order == 2 & percent < 5


twoway ///
    (bar shapley_value xpos if order==1, barwidth(0.6) color(dknavy%80)) ///
    (bar shapley_value xpos if order==2, barwidth(0.6) color(ebblue%80)) ///
    (bar shapley_value xpos if order==3, barwidth(0.6) color(ltblue%80)) ///
    (bar shapley_value xpos if order==4, barwidth(0.6) color(gs12%80)) ///
    (scatter mid xpos_label if order==1, mlabel(pct_label) mlabcolor(white) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==2, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==3, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)) ///
    (scatter mid xpos_label if order==4, mlabel(pct_label) mlabcolor(black) msymbol(none) mlabsize(4.5)), ///
    ylabel(0(0.1)0.5, angle(0) labsize(4.5)) ///
    ytitle("Share of Benchmark Variation Explained", size(4.5)) ///
			yscale(range(0 0.68)) ///
			xline(3.5, lpattern(dash) lcolor(black)) ///
	text(0.58 2 "Shapley Decomposition", size(5) color(black)) ///
    text(0.62 4 "Regression" "Residual", size(5) color(black)) ///
    xtitle("") ///
    xlabel(1 "Scaling" 2 "Shared alg. progress" 3 "Company Secret Sauce" 4 `""Model Residual" "Efficiency""', noticks labsize(large)) ///
    title("") ///
    legend(off) ///
	xsize(11) ysize(5) ylabel(,format(%3.1f))
graph export "$resultspath/shapley_stacked_bar_ym.pdf", replace
*graph export "$resultspath/shapley_stacked_bar_baseline.eps", replace
	
}




******************************************
*Appendix Tables: Only for Default Sample
******************************************
if "$sample_def" == "default" {
********
*Table with median size
*******
use "$resultspath/help.dta", clear

tab three_time, gen(threetime_)
tab top_ten_comp, gen(top10_)
drop threetime_1
drop top10_13

//bysort three_time:  egen median_size = median(log_10_flops) if  top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15

egen q1_size_h = pctile(log_10_flops), p(20)
egen q2_size_h = pctile(log_10_flops), p(40)
egen q3_size_h = pctile(log_10_flops), p(60)
egen q4_size_h = pctile(log_10_flops), p(80)



bysort three_time: egen median_size2 = median(log_10_flops)


gen M_1 = 1 if log_10_flops >= median_size2 & log_10_flops !=.
replace M_1 = 0 if log_10_flops < median_size2 & log_10_flops !=.

label var M_1 "Above Median"
label var log_10_flops "Log(FLOPs)"
label var logit_mmlu "Logit(MMLU-Pro)"

est clear
eststo: reg logit_mmlu c.log_10_flops##i.M_1 ib0.three_time ib13.top_ten_comp , vce(cluster top_ten_comp)
esttab using "$resultspath/median_size_reg.tex", replace b(%9.4f) se(%9.4f) star(* 0.10 ** 0.05 *** 0.01) label 


*******
*Time checks, quarterly and monthly time
*******
use "$resultspath/help.dta", clear


*****************************************
*Robustness Check: Interacting Compute and Time
*****************************************
est clear
eststo: reg logit_mmlu c.log_10_flops##ib0.three_time ib13.top_ten_comp, vce(cluster top_ten_comp)
esttab using "$resultspath/robust_time_flop_interaction.tex", replace keep(log_10_flops *#*) label 


}





**************************************************************************
*Top Scoring Models over Time + Minimum Params to Model, only for Default
**************************************************************************
if "$sample_def" == "default" {
	**********************************
**Minimum Params to Score Graphs
**********************************
{
use "$resultspath/help.dta", clear
replace mmlu_pro_acc = acc_norm_new
  //10 20 30 40 50 60 70 80 90
 foreach x in  10 20 30 40 50 60 70 80 90 100 {
 foreach y in 	mmlu_pro_acc    {
 	
	local ccc= `x'/100 
	display "`ccc'"
	bys yq: egen MinQ`x'_PH_`y' = min(log_10_flops) if  `y' >= `ccc'  & `y' !=.  
	bys ym: egen MinM`x'_PH_`y' = min(log_10_flops) if  `y' >= `ccc'  & `y' !=.
	
	bys yq: egen MinQ`x'_P_`y' = min(MinQ`x'_PH_`y')   
	bys ym: egen MinM`x'_P_`y' = min(MinM`x'_PH_`y') 
	
	
 }	
 }
 
 //MMLU-pro
  keep if log_flops !=.
  
  su  mmlu_pro_acc ,det
 keep  ym MinM10_PH_mmlu_pro_acc  MinM20_PH_mmlu_pro_acc MinM30_PH_mmlu_pro_acc MinM40_PH_mmlu_pro_acc  MinM50_PH_mmlu_pro_acc  MinM60_PH_mmlu_pro_acc MinM70_PH_mmlu_pro_acc MinM80_PH_mmlu_pro_acc  MinM90_PH_mmlu_pro_acc yq
 duplicates drop 
 sort ym
 
 
 
 foreach xx in  MinM10_PH_mmlu_pro_acc  MinM20_PH_mmlu_pro_acc MinM30_PH_mmlu_pro_acc MinM40_PH_mmlu_pro_acc  MinM50_PH_mmlu_pro_acc  MinM60_PH_mmlu_pro_acc MinM70_PH_mmlu_pro_acc MinM80_PH_mmlu_pro_acc MinM90_PH_mmlu_pro_acc {
	by ym: egen F`xx' = mean(`xx')
    replace F`xx' = F`xx'[_n-1] if  F`xx'[_n-1] <  F`xx' &  F`xx'[_n-1] !=. 
 }
 keep F* ym yq
  duplicates drop
  
    foreach var of varlist F* {
  	
	gen L`var' = log10(`var')
  }

  
scatter FMinM10_PH_mmlu_pro_acc FMinM20_PH_mmlu_pro_acc FMinM30_PH_mmlu_pro_acc FMinM40_PH_mmlu_pro_acc FMinM50_PH_mmlu_pro_acc FMinM60_PH_mmlu_pro_acc FMinM70_PH_mmlu_pro_acc FMinM80_PH_mmlu_pro_acc ym, ///
    connect(l l l l l l l l) ///
    lpattern(solid dash longdash shortdash longdash_dot shortdash_dot dash_dot "--..") ///
    msymbol(S O T D Oh Sh Th Dh) ///
    lwidth(medthick medthick medthick medthick medthick medthick medthick medthick) ///
    msize(1.2 1.2 1.2 1.2 1.2 1.2 1.2 1.2) ///
    lcolor(eltblue ltblue ebblue midblue blue dkmavy navy sand) ///
    mcolor(eltblue ltblue ebblue midblue blue dkmavy navy sand) ///
    legend(off) ///
    xtitle(Year-month) ///
    ytitle(FLOPs, size(4)) ///
    title("", size(5.5)) ///
    name(Mmmlu, replace) ///
	text(`=FMinM10_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  10%", place(e) color(eltblue)) ///
text(`=FMinM20_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  20%", place(e) color(ltblue)) ///
text(`=FMinM30_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  30%", place(e) color(ebblue)) ///
text(`=FMinM40_PH_mmlu_pro_acc[_N] - 0.5' `=ym[_N]' "  40%", place(e) color(midblue)) ///
text(`=FMinM50_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  50%", place(e) color(blue)) ///
text(`=FMinM60_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  60%", place(e) color(dknavy)) ///
text(`=FMinM70_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  70%", place(e) color(navy)) ///
text(`=FMinM80_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  80%", place(e) color(sand)) ///
 graphregion(margin(r = 10)) ///
	ylabel(18 "10{superscript:18}" 20 "10{superscript:20}" 22 "10{superscript:22}" 24 "10{superscript:24}" 26 "10{superscript:26}" 28 "10{superscript:28}", angle(0)) 


	graph export "$figpath/Size_for_given_performance_monthsMMLU_flops.png", replace

	}
		
use "$resultspath/help.dta", clear
bys yq: egen double max_score = max(mmlu_pro_acc)


keep if mmlu_pro_acc == max_score

  by yq: egen Fmax_score = mean(acc_norm_new)
 by yq: egen Fmodel_id = mode(model_id)  
	
	sort yq max_score
 	foreach var in Fmax_score  {
  replace `var' = `var'[_n-1] if `var' < `var'[_n-1] & !missing(`var'[_n-1])
}


replace Fmodel_id= Fmodel_id[_n-1] if  max_score[_n-1] >  max_score &  max_score[_n-1] !=. 
 
	
	replace Fmodel_id = "GPT-J 6B"  if Fmodel_id == "EleutherAI__gpt-j-6b"
replace Fmodel_id = "Flan ul2"  if Fmodel_id ==  "google__flan-ul2" 
replace Fmodel_id = "Flan T5 xxl"  if Fmodel_id ==  "google__flan-t5-xxl" 
replace Fmodel_id = "LLaMA 65b "  if Fmodel_id ==  "huggyllama/llama-65b" 
replace Fmodel_id = "Orca mini v3 70b"  if Fmodel_id == "pankajmathur__orca_mini_v3_70b" 
replace Fmodel_id = "Yi 34B 200K"   if Fmodel_id == "01-ai__Yi-34B-200K" 
replace Fmodel_id =  "Claude 3 Opus"   if Fmodel_id == "Claude-3-Opus" 
replace Fmodel_id = "Gemini 1.5 Pro"  if Fmodel_id == "Gemini-1.5-Pro" 
replace Fmodel_id =  "GPT-o1 mini" if Fmodel_id ==  "GPT-o1-mini"
replace Fmodel_id =  "Orca mini v3 70b" if Fmodel_id ==  "Orca_mini_v3_70b"

replace Fmodel_id = "GPT JT 6B v1"  if Fmodel_id == "togethercomputer__GPT-JT-6B-v1" 
replace Fmodel_id = "Flan ul2"   if Fmodel_id == "google__flan-ul2" 
replace Fmodel_id =  "Falcon 40b"   if Fmodel_id == "tiiuae__falcon-40b" 
replace Fmodel_id = "Llama 2 70b hf"  if Fmodel_id == "meta-llama__Llama-2-70b-hf" 
replace Fmodel_id =  "Yi 34B" if Fmodel_id ==  "01-ai__Yi-34B"
replace Fmodel_id =  "Qwen 2.5 72B" if Fmodel_id ==  "Qwen__Qwen2.5-72B"

replace Fmodel_id =  "Claude 3.5 Sonnet" if Fmodel_id ==  "Claude 3.5 Sonnet"
replace Fmodel_id =  "Qwen 2.5 72B" if Fmodel_id ==  "Qwen__Qwen2.5-72B"

replace Fmodel_id =  "GPT 4.5" if Fmodel_id ==  "GPT-4.5"
replace Fmodel_id =  "CausalLM 34b beta" if Fmodel_id ==  "CausalLM__34b-beta"	

replace Fmax_score = Fmax_score * 100 
	
	tw (line Fmax_score yq, lcolor(dknavy) lwidth(thick)) (scatter Fmax_score yq, mlabel(Fmodel_id) mlabcolor(black) mlabangle(55)  mlabposition(1) msymbol(D) mcolor(dknavy) msize(2))  (, legend(off)  ytitle("Benchmark score (%)", size(4)) ylabel(,labsize(4)) xtitle("Year-quarter")  ylabel( 0(20)100) plotregion(margin(r = 10)) xlabel(252 "2023" 256 "2024" 260 "2025") xtick(251(1)260))
	graph export "$figpath/mmlu_pro_best_models.pdf", replace
	



use "$resultspath/help.dta",  clear 

//raw data (scaling)
nl (acc_norm_new = 1 / (1 + exp(-({alpha=1} * log_flops + {beta=0}))))
	
//local alpha = _b[alpha]
//local beta = _b[beta]


predict acc_predicted
gen acc_fit = 1 / (1 + exp(-acc_predicted))

gen acc_fit_manual = 1 / (1 + exp(-(.4400164  * log_flops + (-6.736996))))

	   

twoway (scatter acc_norm_new log_10_flops if top_ten_comp == 1, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 2, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 3, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 4, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 5, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 6, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 7, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 8, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 9, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 10, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 11, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 12, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 13, msymbol(X) mcolor(blue)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 14, msymbol(X) mcolor(blue)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 15, msymbol(X) mcolor(blue)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 0, mcolor(gs10) msymbol(X)) ///
       (line acc_fit_manual log_10_flops, sort lcolor(dknavy) lwidth(medthick)), ///
       legend(order(1  "Main Developers" 13 "Other Developers" 17 "Fitted (All Developers)") pos(6) row(1)) ///
       title("") ///
       xlabel(17 "10{superscript:17}" 19 "10{superscript:19}" 21 "10{superscript:21}" 23 "10{superscript:23}" 25 "10{superscript:25}" 27 "10{superscript:27}") ///
       ytitle("MMLU-Pro Accuracy (%)") xtitle("FLOPs") ///
       ylabel(0 "0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90")

	   graph export "$figpath/raw_data_scatter_fit.pdf",  replace 

	   }
******************************
*Math Results of top model
******************************
if "$sample_def" == "math" {
	
************************************
*Graphs for MATH benchmark
************************************
//minimum params to a score
{
use "$resultspath/help.dta", clear

replace mmlu_pro_acc = MATHLvl5Raw
  //10 20 30 40 50 60 70 80 90
 foreach x in  10 20 30 40 50 60 70 80 90 100 {
 foreach y in 	mmlu_pro_acc    {
 	
	local ccc= `x'/100 
	display "`ccc'"
	bys yq: egen MinQ`x'_PH_`y' = min(log_10_flops) if  `y' >= `ccc'  & `y' !=.  
	bys ym: egen MinM`x'_PH_`y' = min(log_10_flops) if  `y' >= `ccc'  & `y' !=.
	
	bys yq: egen MinQ`x'_P_`y' = min(MinQ`x'_PH_`y')   
	bys ym: egen MinM`x'_P_`y' = min(MinM`x'_PH_`y') 
	
	
 }	
 }
 
 //MMLU-pro
  keep if log_flops !=.
  
  su  mmlu_pro_acc ,det
 keep  ym MinM10_PH_mmlu_pro_acc  MinM20_PH_mmlu_pro_acc MinM30_PH_mmlu_pro_acc MinM40_PH_mmlu_pro_acc  MinM50_PH_mmlu_pro_acc  MinM60_PH_mmlu_pro_acc MinM70_PH_mmlu_pro_acc MinM80_PH_mmlu_pro_acc  MinM90_PH_mmlu_pro_acc yq
 duplicates drop 
 sort ym
 
 
 
 foreach xx in  MinM10_PH_mmlu_pro_acc  MinM20_PH_mmlu_pro_acc MinM30_PH_mmlu_pro_acc MinM40_PH_mmlu_pro_acc  MinM50_PH_mmlu_pro_acc  MinM60_PH_mmlu_pro_acc MinM70_PH_mmlu_pro_acc MinM80_PH_mmlu_pro_acc MinM90_PH_mmlu_pro_acc {
	by ym: egen F`xx' = mean(`xx')
    replace F`xx' = F`xx'[_n-1] if  F`xx'[_n-1] <  F`xx' &  F`xx'[_n-1] !=. 
 }
 keep F* ym yq
  duplicates drop
  
    foreach var of varlist F* {
  	
	gen L`var' = log10(`var') 
  }

keep if yq>=tq(2024q1)

scatter FMinM10_PH_mmlu_pro_acc FMinM20_PH_mmlu_pro_acc FMinM30_PH_mmlu_pro_acc FMinM40_PH_mmlu_pro_acc FMinM50_PH_mmlu_pro_acc FMinM60_PH_mmlu_pro_acc FMinM70_PH_mmlu_pro_acc FMinM80_PH_mmlu_pro_acc ym, ///
    connect(l l l l l l l l) ///
    lpattern(solid dash longdash shortdash longdash_dot shortdash_dot dash_dot "--..") ///
    msymbol(S O T D Oh Sh Th Dh) ///
    lwidth(medthick medthick medthick medthick medthick medthick medthick medthick) ///
    msize(1.2 1.2 1.2 1.2 1.2 1.2 1.2 1.2) ///
    lcolor(eltblue ltblue ebblue midblue blue dknavy navy sand) ///
    mcolor(eltblue ltblue ebblue midblue blue dknavy navy sand) ///
    legend(off) ///
    xtitle(Year-month) ///
    ytitle(FLOPs, size(4)) ///
    title("", size(5.5)) ///
    name(Mmmlu, replace) ///
    text(`=FMinM10_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  10%", place(e) color(eltblue)) ///
    text(`=FMinM20_PH_mmlu_pro_acc[_N] + 0.5' `=ym[_N]' "  20%", place(e) color(ltblue)) ///
    text(`=FMinM30_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  30%", place(e) color(ebblue)) ///
    text(`=FMinM40_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  40%", place(e) color(midblue)) ///
    text(`=FMinM50_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  50%", place(e) color(blue)) ///
    text(`=FMinM60_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  60%", place(e) color(dknavy)) ///
    text(`=FMinM70_PH_mmlu_pro_acc[_N] + .5' `=ym[_N]' "  70%", place(e) color(navy)) ///
    text(`=FMinM80_PH_mmlu_pro_acc[_N]' `=ym[_N]' "  80%", place(e) color(sand)) graphregion(margin(r = 10)) ///
	ylabel(18 "10{superscript:18}" 20 "10{superscript:20}" 22 "10{superscript:22}" 24 "10{superscript:24}" 26 "10{superscript:26}" 28 "10{superscript:28}", angle(0)) 


	graph export "$resultspath/Size_for_given_performance_monthsmath_flops.png", replace
}


*Best model over time Math
	use "$resultspath/help.dta",  clear 

bys yq: egen double max_score = max(MATHLvl5Raw)


keep if MATHLvl5Raw == max_score

  by yq: egen Fmax_score = mean(max_score)
 by yq: egen Fmodel_id = mode(model_id)  
	
	sort yq max_score
 	foreach var in Fmax_score  {
  replace `var' = `var'[_n-1] if `var' < `var'[_n-1] & !missing(`var'[_n-1])
}


replace Fmodel_id= Fmodel_id[_n-1] if  max_score[_n-1] >  max_score &  max_score[_n-1] !=. 
 
	
replace Fmodel_id = "GPT-SW3-40B"  if Fmodel_id ==  "AI-Sweden-Models__gpt-sw3-40b" 
replace Fmodel_id = "Falcon 40B"  if Fmodel_id ==  "tiiuae__falcon-40b-instruct"

replace Fmodel_id = "GPT JT 6B v1"  if Fmodel_id == "togethercomputer__GPT-JT-6B-v1" 
replace Fmodel_id = "Llama 2 70b hf"  if Fmodel_id == "meta-llama__Llama-2-70b-hf" 
replace Fmodel_id =  "DeepSeek-67B-Chat" if Fmodel_id ==  "deepseek-ai__deepseek-llm-67b-chat"
replace Fmodel_id =  "Qwen 2.5 32B Instruct" if Fmodel_id ==  "Qwen__Qwen2.5-32B-Instruct"

replace Fmodel_id =  "Deepseek V3" if Fmodel_id ==  "Deepseek-V3"
replace Fmodel_id =  "Grok3 Beta" if Fmodel_id ==  "Grok3-Beta"



   
   tw (line Fmax_score yq, lcolor(dknavy) lwidth(thick)) ///
   (scatter Fmax_score yq, mlabel(Fmodel_id) mlabcolor(black) mlabangle(340) mlabposition(11) msymbol(D) mcolor(dknavy) msize(2)) ///
   , legend(off) ytitle("MATH Level 5 Score (%)", size(4)) ylabel(0(0.2)1, labsize(4)) xtitle("Year-quarter") ///
   xlabel(252 "2023" 256 "2024" 260 "2025") ///
   xtick(251(1)260) ylabel(0 "0" .2 "20" .4 "40" .6 "60" .8 "80" 1 "100")
	graph export "$resultspath/math_best_models.pdf", replace



//Raw data fit

use "$resultspath/help.dta", clear

* Fit logit regression on log10 scale
gen logit_MATH = logit(MATHLvl5Raw) if MATHLvl5Raw > 0.001 & MATHLvl5Raw < 0.999
reg logit_MATH log_10_flops

* Store coefficients for starting values
local start_alpha = _b[log_10_flops]
local start_beta = _b[_cons]

di "Starting alpha: " `start_alpha'
di "Starting beta: " `start_beta'

* Fit nonlinear model with better starting values
nl (MATHLvl5Raw = invlogit({alpha=.52987743} * log_10_flops + {beta=-8.3257917}))

* (MATHLvl5Raw = 1 / (1 + exp(-({alpha=1} * log_flops + {beta=-15}))))


* Generate predictions using nl parameter estimates
gen logit_pred = _b[/beta] + _b[/alpha] * log_10_flops  
gen prob_pred = invlogit(logit_pred)
di _b[/beta]
di _b[/alpha]

* Plot
twoway (scatter MATHLvl5Raw log_10_flops, mcolor(eltblue) msymbol(X)) ///
       (line prob_pred log_10_flops, sort lcolor(dkblue)), ///
       legend(order(1 "Observed" 2 "Fitted") pos(6) rows(1)) ///
       xtitle("FLOPs") ytitle("MATH Level 5 Score") ///
	   xlabel(15 "10{superscript:15}" 20 "10{superscript:20}" 25 "10{superscript:25}" 30 "10{superscript:30}") ylabel(0 "0" .2 "20" .4 "40" .6 "60" .8 "80" 1 "100")
	   
	   
	   twoway (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 1, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 2, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 3, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 4, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 5, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 6, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 7, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 8, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 9, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 10, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 11, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 12, msymbol(X) mcolor(red)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 13, msymbol(X) mcolor(blue)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 14, msymbol(X) mcolor(blue)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 15, msymbol(X) mcolor(blue)) ///
       (scatter MATHLvl5Raw log_10_flops if top_ten_comp == 0, mcolor(gs10) msymbol(X)) ///
       (line prob_pred log_10_flops, sort lcolor(dknavy) lwidth(medthick)), ///
       legend(order(1 "Observed Main Developers" 13 "Observed Other Developers" 17 "Fitted") pos(6) row(1)) ///
       title("") ///
       xlabel(17 "10{superscript:17}" 19 "10{superscript:19}" 21 "10{superscript:21}" 23 "10{superscript:23}" 25 "10{superscript:25}" 27 "10{superscript:27}") ///
       ytitle("MATH Level 5 Accuracy (%)") xtitle("FLOPs") ///
       ylabel(0 "0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90")
graph export "$resultspath/raw_data_scatter_fit_math.pdf",  replace 



 reghdfe logit_math log_10_flops  , vce(cluster top_ten_comp) absorb(top_ten_comp three_time)  


 binscatter logit_math log_10_flops, absorb(top_ten_comp) control(i.three_time) n(50) ///
 xtitle("FLOPs", size(medium)) ytitle("Logit(Math Accuracy)", size(medium))  xlabel(21 "10{superscript:21}" 22 "10{superscript:22}" 23 "10{superscript:23}" 24 "10{superscript:24}" 25 "10{superscript:25}") ///
      text( ///
         -3.7 24. ///
        "Coefficient = 0.92***" ///
        "SE = 0.29" ///
		"R{superscript:2} = 0.55", ///
        place(se) ///
        size(medium)) mcolor(eltblue) lcolor(dknavy) xsize(11) ysize(6)
 
graph export "$resultspath/mmlu_binscatter_math.pdf",  replace 

}




************************************
*Scatter Plots for Asymmetric Logits
************************************
if "$sample_def" == "asym07" {
	
 **Raw Data Scatter of ASYM 07
 use "$resultspath/help.dta", clear
 
 
//raw data (scaling)
nl (mmlu_pro_acc = 1 / (1 + exp(-({alpha=1} * log_flops + {beta=0}))))

predict acc_predicted
gen acc_fit = 1 / (1 + exp(-acc_predicted))

gen acc_fit_manual = 1 / (1 + exp(-(.4400164  * log_flops + (-6.736996))))

gen acc_fit_manual_asy07 = (1 / (1 + exp(-(.4400164  * log_flops + (-6.736996)))))^(1/0.7)


twoway (scatter acc_norm_new log_10_flops, mcolor(eltblue%50)) ///
       (line acc_fit_manual_asy07 log_10_flops, sort lcolor(dknavy)) ///
	   (line acc_fit_manual log_10_flops, sort lcolor(ebblue)), ///
       legend(label(1 "Observed") label(2 "Asymmetric") label(3 "Symmetric") pos(6)) ///
       title("") ///
       ytitle("MMLU-Pro Accuracy (%)") xtitle("FLOPs") xlabel(17 "10{superscript:17}" 19 "10{superscript:19}" 21 "10{superscript:21}" 23 "10{superscript:23}" 25 "10{superscript:25}" 27 "10{superscript:27}") ///
	   ylabel(0 "0" .2 "20" .4 "40" .6 "60"  .8 "80" 1 "100" )
	   
	   
	   twoway (scatter acc_norm_new log_10_flops if top_ten_comp == 1, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 2, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 3, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 4, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 5, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 6, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 7, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 8, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 9, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 10, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 11, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 12, msymbol(X) mcolor(red)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 13, msymbol(X) mcolor(blue)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 14, msymbol(X) mcolor(blue)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 15, msymbol(X) mcolor(blue)) ///
       (scatter acc_norm_new log_10_flops if top_ten_comp == 0, mcolor(gs10) msymbol(X)) ///
       (line acc_fit_manual_asy07 log_10_flops, sort lcolor(dknavy)) ///
	   (line acc_fit_manual log_10_flops, sort lcolor(ebblue)), ///
       legend(order(1 "Observed Main Developers" 13 "Observed Other Developers" 17 "Asymmetric" 18 "Symmetric") pos(6) row(2)) ///
       title("") ///
       xlabel(17 "10{superscript:17}" 19 "10{superscript:19}" 21 "10{superscript:21}" 23 "10{superscript:23}" 25 "10{superscript:25}" 27 "10{superscript:27}") ///
       ytitle("MMLU-Pro Accuracy (%)") xtitle("FLOPs") ///
       ylabel(0 "0" .1 "10" .2 "20" .3 "30" .4 "40" .5 "50" .6 "60" .7 "70" .8 "80" .9 "90")

	   
	   
	  
	  graph export "$figpath/asym_logit_07.pdf", as(pdf) replace 

}



if "$sample_def" == "asym12" {
	 **Raw Data Scatter of ASYM 12
 use "$resultspath/help.dta", clear
 
 
//raw data (scaling)
nl (acc_norm_new = 1 / (1 + exp(-({alpha=1} * log_flops + {beta=0}))))

predict acc_predicted
gen acc_fit = 1 / (1 + exp(-acc_predicted))

gen acc_fit_manual = 1 / (1 + exp(-(.4400164  * log_flops + (-6.736996))))

gen acc_fit_manual_asy12 = (1 / (1 + exp(-(.4400164  * log_flops + (-6.736996)))))^(1/1.2)


twoway (scatter acc_norm_new log_10_flops, mcolor(eltblue%50)) ///
       (line acc_fit_manual_asy12 log_10_flops, sort lcolor(dknavy)) ///
	   (line acc_fit_manual log_10_flops, sort lcolor(ebblue)), ///
       legend(label(1 "Observed") label(2 "Asymmetric") label(3 "Symmetric") pos(6)) ///
       title("") ///
       ytitle("MMLU-Pro Accuracy (%)") xtitle("FLOPs") xlabel(17 "10{superscript:17}" 19 "10{superscript:19}" 21 "10{superscript:21}" 23 "10{superscript:23}" 25 "10{superscript:25}" 27 "10{superscript:27}") ///
	   ylabel(0 "0" .2 "20" .4 "40" .6 "60"  .8 "80" 1 "100" )
	  
	  graph export "$figpath/asym_logit_12.pdf", as(pdf) replace 
	
}
******************************
*Table 1A
******************************
preserve
reg logit_mmlu log_flops ib0.three_time ib13.top_ten_comp $moe, vce(cluster top_ten_comp)
gen const = _b[_cons]
di const
gen double scaling = _b[log_flops]*log_flops
gen spillover =  (_b[0.three_time] * (three_time == 0)) + (_b[1.three_time] * (three_time == 1))   + (_b[2.three_time] * (three_time == 2))

* Per-obs MoE contribution (zero unless sample_def == "moe")
gen moe_effect = 0
if "$sample_def" == "moe" {
    replace moe_effect = _b[MoE] * MoE
}

predict omega, res

gen comp_fe = .
levelsof top_ten_comp, local(comps)
foreach c of local comps {
    local vname "`c'.top_ten_comp"
     replace comp_fe = _b[`vname'] if top_ten_comp==`c'
}


//keep if inlist(model_id, "meta-llama__Llama-2-70b-hf", "GPT-4.5") //for full sample
*keep if inlist(model_id, "meta-llama__Llama-2-70b-hf", "Qwen__Qwen2.5-72B") //for HF models + BBH + Base Models
keep if inlist(model_id, "meta-llama__Llama-2-70b-hf", "Deepseek-V3") //for no life arch models + MoE

*keep if inlist(model_id, "google__flan-ul2", "Grok3-Beta") //gpqa diamond
//keep if inlist(model_id, "meta-llama__Llama-2-70b-hf", "GPT-o1") //for reasoning

//keep if inlist(model_id, "GPT-4-Turbo", "Grok3-Beta") //for math


sort three_time
gen n = _n
tsset n

gen d_bench = s.logit_mmlu

 gen d_scaling = s.scaling

  gen d_spillover = s.spillover

   gen d_comp_fe = s.comp_fe

   gen d_moe_effect = s.moe_effect

    gen d_omega = s.omega


 gen test2 = d_scaling + d_spillover +  d_comp_fe + d_moe_effect + d_omega

 foreach xx in  d_scaling  d_spillover   d_comp_fe  d_moe_effect  d_omega  {

gen s_`xx' =  `xx' / test2
 }

 gen actualBMchange = s.acc_norm_new


  foreach xx in  d_scaling  d_spillover   d_comp_fe  d_moe_effect  d_omega  {

gen cont_`xx' =  s_`xx' * actualBMchange * 100
 }

tab d_scaling
tab d_spillover
tab d_comp_fe
tab d_moe_effect
tab d_omega
tab d_bench

restore

preserve
reg logit_mmlu log_flops ib0.three_time ib13.top_ten_comp $moe, vce(cluster top_ten_comp)
gen const = _b[_cons]
di const
gen double scaling = _b[log_flops]*log_flops
gen spillover =  (_b[0.three_time] * (three_time == 0)) + (_b[1.three_time] * (three_time == 1))   + (_b[2.three_time] * (three_time == 2))

* Per-obs MoE contribution (zero unless sample_def == "moe")
gen moe_effect = 0
if "$sample_def" == "moe" {
    replace moe_effect = _b[MoE] * MoE
}

predict omega, res

gen comp_fe = .
levelsof top_ten_comp, local(comps)
foreach c of local comps {
    local vname "`c'.top_ten_comp"
     replace comp_fe = _b[`vname'] if top_ten_comp==`c'
}

*keep if inlist(model_id, "google__flan-ul2", "microsoft__Phi-3.5-mini-instruct") //for BBH

keep if inlist(model_id, "google__flan-ul2", "nvidia__Minitron-4B-Base")
//keep if inlist(model_id, "Qwen__Qwen1.5-14B-Chat", "microsoft__Phi-3.5-mini-instruct") //for math


sort three_time
gen n = _n
tsset n

gen d_bench = s.logit_mmlu

 gen d_scaling = s.scaling

  gen d_spillover = s.spillover

   gen d_comp_fe = s.comp_fe

   gen d_moe_effect = s.moe_effect

    gen d_omega = s.omega


 gen test2 = d_scaling + d_spillover +  d_comp_fe + d_moe_effect + d_omega

 foreach xx in  d_scaling  d_spillover   d_comp_fe  d_moe_effect  d_omega  {

gen s_`xx' =  `xx' / test2
 }

 gen actualBMchange = s.acc_norm_new


  foreach xx in  d_scaling  d_spillover   d_comp_fe  d_moe_effect  d_omega  {

gen cont_`xx' =  s_`xx' * actualBMchange * 100
 }

tab d_scaling
tab d_spillover
tab d_comp_fe
tab d_moe_effect
tab d_omega
tab d_bench

restore

************
*Figure 2D
***********

reg logit_mmlu log_10_flops ib0.three_time ib13.top_ten_comp $moe , vce(cluster top_ten_comp)
cap drop xb_hat
cap drop pred_prob 
cap drop residual 
* Linear predictor
predict xb_hat, xb
predict omega, res
* Compute residuals
gen beta_log_flops = _b[log_10_flops]


* Create company FE variable
cap drop comp_fe

matrix b = e(b)
matrix V = e(V)


gen comp_fe    = .
gen comp_fe_se = .
/*
gen baseline_other_FE = 0 if M_flops <= 12
replace baseline_other_FE = _b[14.top_ten_comp] if M_flops > 12  & M_flops <= 15.5
replace baseline_other_FE = _b[15.top_ten_comp] if M_flops > 15.5
*/

gen baseline_other_FE = 0



levelsof top_ten_comp, local(comps)
foreach c of local comps {
    local vname "`c'.top_ten_comp"
     replace comp_fe = _b[`vname'] if top_ten_comp==`c'
     replace comp_fe_se = _se[`vname'] if top_ten_comp==`c'
}


*global med_comparison = _b[14.top_ten_comp]
*global high_comparison = _b[15.top_ten_comp]

gen comp_fe_rescaled = comp_fe - baseline_other_FE
gen comp_fe_and_res = comp_fe  + omega





//compute the factor equivalent
gen comp_fe_flop_factor =  10^(comp_fe /beta_log_flops)
gen comp_model_fe_flop_factor =  10^(comp_fe_and_res /beta_log_flops)



*gen comp_fe_lo = .
*gen comp_fe_hi = .
* Now build CI
*replace comp_fe_lo = comp_fe + 1.645*comp_fe_se   if top_ten_comp != 14 & top_ten_comp != 15  //comp_fe - 1.96*comp_fe_se
*replace comp_fe_hi = comp_fe - 1.645*comp_fe_se   if top_ten_comp != 14 & top_ten_comp != 15  //comp_fe + 1.96*comp_fe_se




bys top_ten_comp: egen avg_model_comp = mean(log_10_flops)
bys top_ten_comp: egen avg_comp_fe = mean(comp_fe)




//compute factor implied by fe
gen Company_fe_flop_factor =  10^((comp_fe - baseline_other_FE)/ beta_log_flops)
gen model_fe_flop_factor =  10^((comp_fe_and_res - baseline_other_FE)/ beta_log_flops)


tabstat Company_fe_flop_factor , by(top_ten_comp) stat(mean)
tabstat model_fe_flop_factor , by(top_ten_comp) stat(mean p50 p90 p10 max min)


bysort  three_time: egen mean_size_period = mean(log_10_flops)
gen size_dev_period_mean = log_10_flops - mean_size_period

bys top_ten_comp: egen mean_size = mean(size_dev_period_mean)



keep  mean_size  top_ten_comp comp_fe_flop_factor
duplicates drop 


* Run regression and get predictions with CI
reghdfe comp_fe_flop_factor mean_size if top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15

local beta2 = _b[mean_size]
local se2 = _se[mean_size]
local r2_2 = e(r2)
local t2 = `beta2' / `se2'
local p2 = 2*ttail(e(df_r), abs(`t2'))
local stars2 ""
if `p2' < 0.01 local stars2 "***"
else if `p2' < 0.05 local stars2 "**"
else if `p2' < 0.1 local stars2 "*"
local beta2_label = string(`beta2', "%9.2f") + "`stars2'"
local se2_label = string(`se2', "%9.2f")
local r2_2_label = string(`r2_2', "%9.2f")

predict pred_comp_fe if e(sample)
predict pred_se if e(sample), stdp

gen pred_lb = pred_comp_fe - 1.96*pred_se if top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15
gen pred_ub = pred_comp_fe + 1.96*pred_se if top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15

* Save the full dataset with predictions
preserve
keep if top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15
keep mean_size pred_comp_fe pred_lb pred_ub
save "$resultspath/predictions", replace
restore

* Create binscatter data
binscatter comp_fe_flop_factor mean_size if top_ten_comp != 13 & top_ten_comp != 14 & top_ten_comp != 15, ///
    savedata("$resultspath/binned") replace

* Load binned data and merge with predictions
import delimited "$resultspath/binned.csv", clear
merge 1:1 mean_size using "$resultspath/predictions", nogen

* X-axis labels and cap.
* Lifearch samples (no_lifearch, all_lifearch) cover much smaller models, so cap at 10x
* (mean_size <= 1). Other samples cap at 1000x (mean_size <= 3).
* xscale(range()) only sets the axis MINIMUM extent — Stata's auto-fit still extends past
* it to cover any data. The only reliable cap is to drop the out-of-range rows.
local xlab xlabel(1 "10x" -1 "0.1x" 0 "1x")
if "$sample_def" == "default" | "$sample_def" == "all_lifearch" | "$sample_def" == "reasoning" | "$sample_def" == "total_token_count" {
    local xlab xlabel(1 "10x" 2 "100x" 3 "1000x" -1 "0.1x" 0 "1x")
}

* Create the overlay plot
twoway (rarea pred_lb pred_ub mean_size, sort fcolor(ebblue%20) lwidth(none)) ///
       (line pred_comp_fe mean_size, sort lcolor(ebblue) lwidth(medthick)) ///
       (scatter comp_fe_flop_factor mean_size, mcolor(dknavy) msize(medium)), ///
    xtitle("Average Relative Difference in Model Size", size(medium)) ///
    ytitle("Company Secret Sauce (compute scaling factor)", size(medium)) ///
    legend(off) ///
    text(400 2 "Coefficient = `beta2_label'" "SE = `se2_label'" "R{superscript:2} = `r2_2_label'", ///
        place(se) size(medium)) `xlab'

	graph export "$figpath/model_size_binscatter.pdf", replace
	
*************
*Figure 2A
*************

use "$resultspath/help.dta",  clear 


// Run regression and store model results
reghdfe logit_mmlu log_10_flops, vce(cluster top_ten_comp) absorb(top_ten_comp three_time $moe)

local beta = _b[log_10_flops]
local se = _se[log_10_flops]
local r2 = e(r2)
local t = `beta' / `se'
local p = 2*ttail(e(df_r), abs(`t'))
local stars ""
if `p' < 0.01 local stars "***"
else if `p' < 0.05 local stars "**"
else if `p' < 0.1 local stars "*"
local beta_label = string(`beta', "%9.2f") + "`stars'"
local se_label = string(`se', "%9.2f")
local r2_label = string(`r2', "%9.2f")

// Create plot with CI bands
binscatter logit_mmlu log_10_flops, absorb(top_ten_comp) control(i.three_time) n(50) ///
    xtitle("FLOPs", size(medium)) ///
    ytitle("Logit(MMLU-Pro Accuracy)", size(medium)) ///
    xlabel(21 "10{superscript:21}" 22 "10{superscript:22}" 23 "10{superscript:23}" ///
           24 "10{superscript:24}" 25 "10{superscript:25}") ///
    legend(off) mcolor(dknavy) lcolor(ebblue) ///
    text(-3.0 23.5 "Coefficient = `beta_label'" "SE = `se_label'" "R{superscript:2} = `r2_label'", ///
        place(se) size(medium)) xsize(11) ysize(6)
		
		graph export "$figpath/mmlu_binscatter_cont.pdf", replace

 	
***********
*Figure 2B
***********
use "$resultspath/help.dta", clear
	
*need to rescale log flops to have correct x axis in base 10 
drop log_flops
gen log_flops = ln(6 * params_raw * All_token_info_raw)

reg logit_mmlu log_flops ib0.three_time ib13.top_ten_comp $moe , vce(cluster top_ten_comp)
gen beta_time_FE = _b[2.three_time]
gen beta_log_flops = _b[log_flops]

//compute the factor equivalent
gen Time_fe_flop_factor =  exp(beta_time_FE/ beta_log_flops)
su Time_fe_flop_factor

* 95% CI for the time compute factor via the delta method on the log-ratio.
* log(factor) = _b[2.three_time] / _b[log_flops] is approximately normal, so we
* build the CI on the log scale and exponentiate -> asymmetric CI on the factor scale.
nlcom (log_factor: _b[2.three_time] / _b[log_flops])
matrix _b_nl = r(b)
matrix _V_nl = r(V)
local _log_factor    = _b_nl[1,1]
local _log_factor_se = sqrt(_V_nl[1,1])
local factor_lo = exp(`_log_factor' - 1.96 * `_log_factor_se')
local factor_hi = exp(`_log_factor' + 1.96 * `_log_factor_se')

summ log_flops, meanonly
local minln = r(min)
local maxln = r(max)
* Define grid range (adjust min/max to your data)
local npoints = 100
local minflops = 20 * ln(10)
local maxflops = `maxln' + 8


cap drop log_flops_grid
gen log_flops_grid = .
forvalues i = 1/`npoints' {
    replace log_flops_grid = `minflops' + (`i'-1)*((`maxflops'-`minflops')/(`npoints'-1)) in `i'
}
cap drop pred_*
* Loop over each time bin to calculate predicted probability
foreach t of numlist 0/2 {
    local varname pred_`t'
    
    gen `varname' = _b[_cons] + _b[log_flops]*log_flops_grid
    
    * Add time FE if not base
    quietly replace `varname' = `varname' + _b[`t'.three_time] 
    
    * Convert linear predictor to probability
    replace `varname' = exp(`varname')/(1 + exp(`varname'))
}


capture drop xb_hat pred_prob residual
* Predict linear predictor for each observation
predict xb_hat, xb

* Transform to probability
gen pred_prob = exp(xb_hat)/(1 + exp(xb_hat))

if "$sample_def" == "asym07" {
	local a 0.4400166
	local b -6.736999
	local v 1.2

	cap drop pred_*
	* Loop over each time bin to calculate predicted probability
	foreach t of numlist 0/2 {
    local varname pred_`t'
    
    * Get linear predictor in logit space
    gen logit_pred_`t' = _b[_cons] + _b[log_flops]*log_flops_grid
    
    * Add time FE if not base
    quietly replace logit_pred_`t' = logit_pred_`t' + _b[`t'.three_time] 
    
    * Transform from asymmetric logit back to probability
    * Inverse transformation: p = [exp(a*y + b)]^(1/v) / (1 + [exp(a*y + b)]^(1/v))
    gen exp_term_`t' = exp(`a' * logit_pred_`t' + `b')
    gen numerator_`t' = exp_term_`t'^(1/`v')
    gen `varname' = numerator_`t' / (1 + numerator_`t')
    
    drop logit_pred_`t' exp_term_`t' numerator_`t'
	}
	
	drop xb_hat
	* Predict linear predictor for each observation
	predict xb_hat, xb

	* Transform to probability using inverse of asymmetric logit
	gen exp_term = exp(`a' * xb_hat + `b')
	gen pred_prob = exp_term^(1/`v') / (1 + exp_term^(1/`v'))
	drop exp_term
}

if "$sample_def" == "asym12" {
	local a 0.4400166
	local b -6.736999
	local v 1.2

	cap drop pred_*
	* Loop over each time bin to calculate predicted probability
	foreach t of numlist 0/2 {
    local varname pred_`t'
    
    * Get linear predictor in logit space
    gen logit_pred_`t' = _b[_cons] + _b[log_flops]*log_flops_grid
    
    * Add time FE if not base
    quietly replace logit_pred_`t' = logit_pred_`t' + _b[`t'.three_time] 
    
    * Transform from asymmetric logit back to probability
    * Inverse transformation: p = [exp(a*y + b)]^(1/v) / (1 + [exp(a*y + b)]^(1/v))
    gen exp_term_`t' = exp(`a' * logit_pred_`t' + `b')
    gen numerator_`t' = exp_term_`t'^(1/`v')
    gen `varname' = numerator_`t' / (1 + numerator_`t')
    
    drop logit_pred_`t' exp_term_`t' numerator_`t'
	}
	
	drop xb_hat 
	
	* Predict linear predictor for each observation
	predict xb_hat, xb

	* Transform to probability using inverse of asymmetric logit
	gen exp_term = exp(`a' * xb_hat + `b')
	gen pred_prob = exp_term^(1/`v') / (1 + exp_term^(1/`v'))
	drop exp_term
}

if "$sample_def" == "log" {
	* y = log(acc_norm_new); inverse of the log link is exp(.)
	* Log link is unbounded above, so the extrapolated grid can produce values > 1.
	* Cap at 1 (=100%) since accuracies above 1 aren't physically meaningful.
	cap drop pred_*
	foreach t of numlist 0/2 {
	    local varname pred_`t'
	    gen `varname' = _b[_cons] + _b[log_flops]*log_flops_grid
	    quietly replace `varname' = `varname' + _b[`t'.three_time]
	    replace `varname' = exp(`varname')
	    replace `varname' = 1 if `varname' > 1 & `varname' < .
	}

	drop xb_hat
	predict xb_hat, xb
	cap drop pred_prob
	gen pred_prob = exp(xb_hat)
	replace pred_prob = 1 if pred_prob > 1 & pred_prob < .
}

if "$sample_def" == "linear" {
	* y = acc_norm_new; identity link, no back-transform needed.
	* Identity link is also unbounded, so cap at [0, 1] to keep the y-axis sensible.
	cap drop pred_*
	foreach t of numlist 0/2 {
	    local varname pred_`t'
	    gen `varname' = _b[_cons] + _b[log_flops]*log_flops_grid
	    quietly replace `varname' = `varname' + _b[`t'.three_time]
	    replace `varname' = 1 if `varname' > 1 & `varname' < .
	    replace `varname' = 0 if `varname' < 0
	}

	drop xb_hat
	predict xb_hat, xb
	cap drop pred_prob
	gen pred_prob = xb_hat
	replace pred_prob = 1 if pred_prob > 1 & pred_prob < .
	replace pred_prob = 0 if pred_prob < 0
}



* Compute residuals
gen residual = acc_norm_new - pred_prob

*scaling to base 10
replace log_flops_grid = log_flops_grid / ln(10)

replace pred_0 = pred_0 * 100
replace pred_2 = pred_2 * 100


* Get the factor and compute shift in log10 space
summ Time_fe_flop_factor
local factor = r(mean)
local shift = log10(`factor')

* Format the factor label to 1 decimal place (avoids float artefacts in the label)
local factor_label    : display %4.1f `factor'
local factor_lo_label : display %4.1f `factor_lo'
local factor_hi_label : display %4.1f `factor_hi'

* Dynamic arrow/label position: pick a y-value at the midpoint of pred_2's visible
* range, find where pred_2 crosses that y, and shift by `shift' to get pred_0's x.
* This places the horizontal arrow between the two curves regardless of where the
* curves actually sit (logistic vs asym07 vs asym12, etc.).
summ pred_2 if log_flops_grid >= 22 & log_flops_grid <= 30
local arrow_y = (r(min) + r(max)) / 2

cap drop _diff_arrow
gen _diff_arrow = abs(pred_2 - `arrow_y') if log_flops_grid >= 22 & log_flops_grid <= 30
summ _diff_arrow, meanonly
summ log_flops_grid if _diff_arrow == r(min) & log_flops_grid >= 22 & log_flops_grid <= 30, meanonly
local x_pred_2 = r(mean)
drop _diff_arrow

local x_pred_0 = `x_pred_2' + `shift'

* Place the label to the LEFT of both curves. placement(w) makes the text extend west,
* so its right edge sits at the anchor x. Anchor just left of x_pred_2 (the leftmost
* curve at arrow_y) and a few percentage points above the arrow.
local label_x  = `x_pred_2' - 0.3
local label_y  = `arrow_y' + 3

* Dynamic positions for the year labels. Anchor each near its curve, then place
* the text away from the line so the curves do not run through the labels.
local x_yr_2 = 28.75
cap drop _diff_yr_2
gen _diff_yr_2 = abs(log_flops_grid - `x_yr_2') if log_flops_grid >= 22 & log_flops_grid <= 30
summ _diff_yr_2, meanonly
summ pred_2 if _diff_yr_2 == r(min), meanonly
local y_yr_2 = min(r(mean) + 1.5, 97)
drop _diff_yr_2

local x_yr_0 = 28.0
cap drop _diff_yr_0
gen _diff_yr_0 = abs(log_flops_grid - `x_yr_0') if log_flops_grid >= 22 & log_flops_grid <= 30
summ _diff_yr_0, meanonly
summ pred_0 if _diff_yr_0 == r(min), meanonly
local y_yr_0 = max(r(mean) - 1.5, 5)
drop _diff_yr_0

* Now draw the plot with LEFT-pointing arrow + label (no green marker)
graph tw (line pred_0 log_flops_grid if log_flops_grid >= 22 & log_flops_grid <= 30 , lwidth(medthick) lcolor(dknavy)) ///
         (line pred_2 log_flops_grid  if log_flops_grid >= 22 & log_flops_grid <= 30, lwidth(medthick) lcolor(ebblue)) ///
         (pcarrowi `arrow_y' `x_pred_0' `arrow_y' `x_pred_2' , lcolor(black) lwidth(medthick) ///
              mcolor(black) msymbol(none)) ///
         , ///
		 text(`y_yr_2' `x_yr_2' "2024-2025", size(medium) color(ebblue) placement(nw)) ///
         text(`y_yr_0' `x_yr_0' "2022–2023", size(medium) color(dknavy) placement(se)) ///
		 legend(off) ///
         title("") ///
         xtitle("FLOPs", size(medium)) ///
         ytitle("MMLU-Pro benchmark score (%)", size(medium)) ///
		 xlabel( 22 "10{superscript:22}" 24 "10{superscript:24}" ///
                26 "10{superscript:26}" 28 "10{superscript:28}" 30 "10{superscript:30}", angle(0)) ///
         xscale(range(22 30)) ///
         text(`label_y' `label_x' "≈ `factor_label'× compute" "[95% CI: `factor_lo_label'× – `factor_hi_label'×]", ///
              size(large) color(black) placement(w)) xsize(11) ysize(6)

graph export "$figpath/curve_shift_time.pdf", replace


*************************************
**Saving Intermediate Data for Python Data
*************************************
use "$resultspath/help.dta", clear
reg logit_mmlu log_flops ib0.three_time ib13.top_ten_comp $moe , vce(cluster top_ten_comp)
gen const = _b[_cons]
di const
gen double scaling = _b[log_flops]*log_flops
gen spillover =  (_b[0.three_time] * (three_time == 0)) + (_b[1.three_time] * (three_time == 1))   + (_b[2.three_time] * (three_time == 2))

* Per-observation MoE contribution (zero unless running the moe sample, in which
* case it's the model's MoE indicator times the regression coefficient on MoE).
gen moe_effect = 0
if "$sample_def" == "moe" {
    replace moe_effect = _b[MoE] * MoE
}

cap drop xb_hat
cap drop pred_prob
cap drop residual
* Linear predictor
predict xb_hat, xb
predict omega, res
* Compute residuals
gen beta_log_flops = _b[log_flops]

* Create company FE variable
cap drop comp_fe

matrix b = e(b)
matrix V = e(V)


gen comp_fe    = .
gen comp_fe_se = .

gen baseline_other_FE = 0

levelsof top_ten_comp, local(comps)
foreach c of local comps {
    local vname "`c'.top_ten_comp"
     replace comp_fe = _b[`vname'] if top_ten_comp==`c'
     replace comp_fe_se = _se[`vname'] if top_ten_comp==`c'
}

gen Sauce = comp_fe +  omega


gen test =    scaling +  spillover +  comp_fe + moe_effect +  omega + const
su test logit_mmlu

bys three_time: egen double max_score = max(logit_mmlu)

gen total_contr = spillover + scaling + omega + comp_fe + moe_effect

foreach xx in spillover scaling omega comp_fe {
    gen share_`xx' = `xx' / total_contr
}

*global med_comparison = _b[14.top_ten_comp]
*global high_comparison = _b[15.top_ten_comp]

gen comp_fe_rescaled = comp_fe - baseline_other_FE
gen comp_fe_and_res = comp_fe  + omega

//compute the factor equivalent
gen comp_fe_flop_factor =  exp(comp_fe /beta_log_flops)

gen comp_and_res_flop_factor = exp(comp_fe_and_res / beta_log)


gen comp_fe_lo = .
gen comp_fe_hi = .
* Now build CI
replace comp_fe_lo = comp_fe - 1.96*comp_fe_se   if top_ten_comp != 14 & top_ten_comp != 15
replace comp_fe_hi = comp_fe + 1.96*comp_fe_se   if top_ten_comp != 14 & top_ten_comp != 15

gen comp_fe_flop_factor_lo = exp(comp_fe_lo / beta_log_flops)
gen comp_fe_flop_factor_hi = exp(comp_fe_hi / beta_log_flops)

gen Sauce_lo = comp_fe_lo + omega
gen Sauce_hi = comp_fe_hi + omega

gen comp_and_res_flop_factor_lo = exp((comp_fe_lo + omega) / beta_log)
gen comp_and_res_flop_factor_hi = exp((comp_fe_hi + omega) / beta_log)

bys top_ten_comp: egen avg_model_comp = mean(log_10_flops)
bys top_ten_comp: egen avg_comp_fe = mean(comp_fe)

//compute factor implied by fe
gen Company_fe_flop_factor =  exp((comp_fe - baseline_other_FE)/ beta_log_flops)

tabstat Company_fe_flop_factor , by(top_ten_comp) stat(mean)


// Fixed display priority: Nvidia, Microsoft, Qwen, Deepseek, Meta, Google, 01-AI, Anthropic, OpenAI, X-AI.
// `ypos` compacts this priority over whichever companies are present in the current subsample
// (so removing a company shifts the rest up rather than leaving a gap).
cap drop _priority ypos company_name
gen _priority = .
replace _priority = 1  if top_ten_comp == 11  // Nvidia
replace _priority = 2  if top_ten_comp == 5   // Microsoft
replace _priority = 3  if top_ten_comp == 2   // Qwen
replace _priority = 4  if top_ten_comp == 1   // Deepseek
replace _priority = 5  if top_ten_comp == 3   // Meta
replace _priority = 6  if top_ten_comp == 4   // Google
replace _priority = 7  if top_ten_comp == 10  // 01-AI
replace _priority = 8  if top_ten_comp == 8   // Anthropic
replace _priority = 9  if top_ten_comp == 7   // OpenAI
replace _priority = 10 if top_ten_comp == 9   // X-AI

preserve
    keep if !missing(_priority) & !missing(Company_fe_flop_factor)
    bys top_ten_comp: keep if _n == 1
    keep top_ten_comp _priority
    sort _priority
    gen ypos = _n
    decode top_ten_comp, gen(company_name)
    keep top_ten_comp ypos company_name
    tempfile _ypos_map
    save `_ypos_map'
restore
merge m:1 top_ten_comp using `_ypos_map', keepusing(ypos company_name) nogen
drop _priority


// Create min and max compute factors for error bars
bys top_ten_comp: egen min_flop_factor = min(comp_and_res_flop_factor_lo)
bys top_ten_comp: egen max_flop_factor = max(comp_and_res_flop_factor_hi)

save "$resultspath/data_for_python_graphs.dta", replace
			

