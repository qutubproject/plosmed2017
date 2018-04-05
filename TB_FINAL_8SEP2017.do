/*-----------------------------------------------------------				
*	Goal:			Description and analysis of TB SP visit

*	Input Data:		1) TB_analysis.dta;	
					2) tb_spv_system.dta;
					3) TB_know_do_gap.dta;
					4) TB_sort.dta
					
*	Output Data:	1) TB_FINAL_8SEP2017.do
										
*   Author(s):      Hao Xue  
*	Created: 		2017-03-24
*   Last Modified: 	2017-09-08 Hao
-----------------------------------------------------------*/

/*-----------------------------------------------------------
 Note: primary steps of this do file
 
	Step 1: Table  1. Main outcomes of interactions with standardized patients
	Step 2: Figure 2. Main Outcomes of Interactions with Standardized Patients
	Step 3: Figure 3. Correlation between Provider Certification and Standardized Patient Outcomes
	Step 4: Figure 4. Know-Do Gap: comparison of data from vignettes versus SP interaction among the same providers 
	Step 5: Table  2. Simulation of System-level Management Outcomes with and without Managed Referrals
			Figure 5: Estimated Patient Pathways Under Status Quo (Patients Freely Selecting into Tiers)
	Step 6: S1 Table. Provider Characteristics
	Step 7: S2 Table. Completion of Checklist Items
	Step 8: S3 Table. Correlates of Correct Management, CXR, Referral, and Antibiotic Prescription of Standardized Patients among Village and Township Providers
	Step 9: S4 Table. Additional Statistics Comparing Vignettes and SP Visits.	
	Step10: S5 Table. Appendix Table 6: Patient Selection into Health System Tiers with Symptoms of TB
	Step11: S6 Table. Simulation of System-level Management Outcomes with and without Managed Referrals (All Health Systems)
	Step 12: S7 Table. Simulation of Out-of-Pocket Costs with and without Managed Referrals
	
	* Figure 1 is not generated automatically.
----------------------------------------------------------*/

clear all
capture log close
set maxvar  30000
set more off

	global adodir "/Users/xuehao/Dropbox (REAP)/Standardized_Patients_II/Std_Patient_2/Papers/2_TB_Detection/Das et al Lancet ID"
	global directory "/Users/xuehao/Dropbox (REAP)/Standardized_Patients_II/Std_Patient_2/Papers/2_TB_Detection/Dofile/Figures from Ben/"

* Load adofiles

	* These files are created by the authors for the purposes of this study and are not publicly available for general use.
	* These files are not guaranteed to produce appropriate statistics other than those contained in this replication file.
		qui do "$adodir/adofiles/chartable.ado"
		qui do "${directory}/adofiles/labelcollapse/labelcollapse.ado"
		qui do "${directory}/adofiles/freereshape/freeshape.ado"
		
	* In addition, this dofile relies on two other publicly available STATA extensions: 
		* estadd, in package st0085_2 from http://www.stata-journal.com/software/sj14-2
		* xml_tab, in package dm0037 from http://www.stata-journal.com/software/sj8-3
		
global datadir "/Users/xuehao//Dropbox (REAP)/Standardized_Patients_II/Std_Patient_2/Papers/2_TB_Detection/Data"
global outdir "/Users/xuehao//Dropbox (REAP)/Standardized_Patients_II/Std_Patient_2/Papers/2_TB_Detection/Tables and Figures"
	
/*-------
Step 1: Table 1: Main outcomes of interactions with standardized patients
--------*/	
	use "$datadir/TB_analysis.dta", clear

	cap mat drop results
	
	local 	binaries   " tb_m_corr tb_m_1 tb_m_2 tb_m_3 return refercdc refercity refercounty refertown antisteriod antibiotic iv fluoroq steroid corrdiag "
			
	qui foreach var of varlist ///
		tb_m_corr tb_m_1 tb_m_2 tb_m_3 refercdc refercity refercounty refertown return ///
		antisteriod antibiotic fluoroq steroid ///
		intertime_min nrqe arqe chi_nrqe chi_arqe aeq totfee totfee_us  ///
		corrdiag  {
	  
		cap mat drop var 
			
			foreach caselogic in !="" =="Village" =="Township" =="County" {  
			
				if regexm("`binaries'"," `var' ") count if `var'  == 1 & level `caselogic'
				if regexm("`binaries'"," `var' ") local n = `r(N)' 
						else local n = .
				
				sum `var' if level `caselogic'
					if regexm("`binaries'"," `var' ") local mean = `r(mean)'
						else local mean = `r(mean)'
			
				if regexm("`binaries'"," `var' ") ci proportions `var' if level `caselogic', wilson 
					else ci means `var' if level `caselogic'
						
					local lower = `r(lb)'
						if regexm("`binaries'"," `var' ") local lower = `lower'
					local upper = `r(ub)'
						if regexm("`binaries'"," `var' ") local upper = `upper'
						
				mat var = nullmat(var) , [`n',`mean',`lower',`upper']
				
				}
					
			mat results = nullmat(results) \ var
			
			}
		

		local columns `" "Number" "Percentage or Mean" "Lower 95% CI" "Upper 95% CI" "'
		
		#delimit ;
		local rows `" 
		"Correctly managed the case"
		"Ordered a chest radiograph"
		"Ordered a sputum smear test"
		"Referred to other provider"
		"Referred to CDC or DOTs, if referral"
		"Referred to city provider, if referral"
		"Referred to county provider, if referral"
		"Referred to town provider, if referral"
		"Asked patient to return"
		"Gave antibiotics and steriods"
		"Gave any antibiotic"
		"Gave any fluoroquinolone"
		"Gave any steroid"
		"Time with provider (min)"
		"Number of questions and examinations (ISTC Standard)"
		"% of questions and examinations (ISTC Standard)"
		"Number of questions and examinations (China Standard)"
		"% of questions and examinations (China Standard)"
		"% of essential history checklist asked by provider (Both Standards)"
		"Cost of consultation and medicines combined (Chinese Yuan)"
		"Cost of consultation and medicines combined (US dollars)"
		"Mentioned tuberculosis"
			"' ;
		#delimit cr
			
		xml_tab ///
			results ///
			using "$outdir/TB_tables_08SEP2017.xls" ///
			, replace ///
			title("Table 1. Main outcomes of interactions with standardized patients") sheet("Table 1") ///
			rnames(`rows') ///
			showeq ceq("Full" "Full" "Full" "Full" ///
			"Village Clinics" "Village Clinics" "Village Clinics" "Village Clinics" ///
			"Township Health Centers" "Township Health Centers" "Township Health Centers" "Township Health Centers" ///
			"County Hospitals" "County Hospitals" "County Hospitals" "County Hospitals") /// 
			cnames(`columns' `columns' ) ///
			lines(COL_NAMES 3 LAST_ROW 3)  format((SCLB0) (SCCB0 NCRR2))
				
	* Balance test for different levels of clinics
	* VC vs THC
	eststo clear
	set more off	
	local 	binaries   " tb_m_corr tb_m_1 tb_m_2 tb_m_3 refercdc refercity refercounty refertown return antisteriod antibiotic iv fluoroq steroid corrdiag"
	qui foreach var of varlist ///
		tb_m_corr tb_m_1 tb_m_2 tb_m_3 refercdc refercity refercounty refertown return ///
		antisteriod antibiotic fluoroq steroid ///
		intertime_min nrqe arqe chi_nrqe chi_arqe aeq totfee totfee_us  ///
		corrdiag  {
		  
		cap mat drop var 

		if regexm("`binaries'"," `var' ") eststo: logit `var' VC i.countycode if CH==0
						else eststo: reg `var' VC i.countycode if CH==0 
		}
		esttab ///
			using "$outdir/balance_08SEP2017.csv", ///
			nolabel b(2) p(3) obslast ///
			nogap noeqlines nonote nolines ///
			keep (VC) ///
			replace noparentheses ///
			wide

	prtest tb_m_2 if CH==0, by(VC)	
	prtest refertown if CH==0, by(VC)	
	prtest steroid if CH==0, by(VC)
	prtest antisteriod if CH==0, by(VC)

			
	* CH vs THC
	eststo clear
	set more off	
	local 	binaries   " tb_m_corr tb_m_1 tb_m_2 tb_m_3 return refercdc refercity refercounty antisteriod antibiotic iv fluoroq steroid corrdiag"
	qui foreach var of varlist ///
		tb_m_corr tb_m_1 tb_m_2 tb_m_3 refercdc refercity refercounty return ///
		antisteriod antibiotic fluoroq steroid ///
		intertime_min nrqe arqe chi_nrqe chi_arqe aeq totfee totfee_us  ///
		corrdiag  {
		  
		cap mat drop var 

		if regexm("`binaries'"," `var' ") eststo: logit `var' THC i.countycode if VC==0
						else eststo: reg `var' THC i.countycode if VC==0 	
		}
		esttab ///
			using "$outdir/balance_08SEP2017.csv", ///
			nolabel b(2) p(3) obslast ///
			nogap noeqlines nonote nolines ///
			keep (THC) ///
			append noparentheses ///
			wide

		replace refercdc=0 if refercdc==. & referral==0 & VC==0
		prtest refercdc if VC==0 , by(THC)	
		replace refercity=0 if refercity==. & referral==0 & VC==0
		prtest refercity if VC==0 , by(THC)	
		replace refercounty=0 if refercounty==. & referral==0 & VC==0
		prtest refercounty if VC==0 , by(THC)	
		prtest antisteriod if CH==0, by(VC)
		prtest fluoroq if VC==0, by(THC)	
		prtest steroid if VC==0, by(THC)	


	
	* CH vs VC
	eststo clear
	set more off	

	local 	binaries   " tb_m_corr tb_m_1 tb_m_3 return refercounty antibiotic iv fluoroq corrdiag"
	qui foreach var of varlist ///
		tb_m_corr tb_m_1 tb_m_3 refercounty return ///
		antibiotic fluoroq ///
		intertime_min nrqe arqe chi_nrqe chi_arqe aeq totfee totfee_us  ///
		corrdiag  {
		  
	cap mat drop var 

		if regexm("`binaries'"," `var' ") eststo: logit `var' VC i.countycode if THC==0
						else eststo: reg `var' VC i.countycode if THC==0 	
		}

		esttab ///
			using "$outdir/balance_08SEP2017.csv", ///
			nolabel b(2) p(3) obslast ///
			nogap noeqlines nonote nolines ///
			keep (VC) ///
			append noparentheses ///
			wide

		
		prtest tb_m_2 if THC==0, by(VC)	
		replace refercdc=0 if refercdc==. & referral==0 & THC==0
		prtest refercdc if THC==0, by(VC)	
		replace refercity=0 if refercity==. & referral==0 & THC==0
		prtest refercity if THC==0 , by(VC)	
		replace refertown=0 if refertown==. & referral==0 & THC==0
		prtest refertown if THC==0 , by(VC)
		prtest antisteriod if CH==0, by(VC)
		prtest antibiotic if THC==0, by(VC)	
		prtest fluoroq if THC==0, by(VC)	
		
	* Table 1 is not generated automatically.
					

/*-------
Step 2: Figure 2: Main Outcomes of Interactions with Standardized Patients
--------*/	
	
	use "$datadir/TB_analysis.dta", clear
		
	global stats arqe chi_arqe aeq tb_m_corr tb_m_1 tb_m_2 tb_m_3 noantibio nofluoroq nosteroid
		
	cap mat drop results
	local 	binaries   " tb_m_corr tb_m_1 tb_m_2 tb_m_3 noantibio nofluoroq nosteroid"
	qui foreach var of varlist $stats {
		cap mat drop var 
			foreach caselogic in =="Village" =="Township" =="County" {  
				if regexm("`binaries'"," `var' ") ci proportions `var' if level `caselogic', wilson 
					else ci means `var' if level `caselogic'
						if regexm("`binaries'"," `var' ") local mean = `r(proportion)'
							else local mean = `r(mean)'
						if regexm("`binaries'"," `var' ") local lower = `r(lb)'
							else local lower = `r(lb)'
						if regexm("`binaries'"," `var' ") local upper = `r(ub)'
							else local upper = `r(ub)'
				mat var = nullmat(var) , [`mean',`lower',`upper']
				}
			mat results = nullmat(results) \ var
			}
		local columns `" "mean" "Lower 95% CI" "Upper 95% CI" "'
		#delimit ;
		local rows `" 
		"% of questions and examinations (ISTC Standard)"
		"% of questions and examinations (China Standard)"
		"% of essential history checklist"
		"Correctly managed the case"
		"Ordered a chest radiograph"
		"Ordered a sputum smear test"
		"Referred to other provider"
		"No Antibiotics"
		"No Fluoroquinolones"
		"No Steroids"
		"' ;
		#delimit cr
			
		xml_tab ///
			results ///
			using "$outdir/TB_Fig1_data.xls" ///
			, replace ///
			showeq ceq("Village Clinics" "Village Clinics" "Village Clinics" ///
			"Township Health Centers" "Township Health Centers" "Township Health Centers"  ///
			"County Hospitals" "County Hospitals" "County Hospitals") /// 
			cnames(`columns' `columns' `columns') ///
			rnames(`rows') ///
			lines(COL_NAMES 3 LAST_ROW 3)  format((SCLB0) (SCCB0 NCRR2))
			
	clear 
	import excel using "$outdir/TB_Fig1_data_fmt.xlsx", clear first

	rename A item
	rename mean mean_vc
	rename Lower95CI lb_vc
	rename Upper95CI ub_vc
	rename E mean_thc
	rename F lb_thc
	rename G ub_thc
	rename H mean_ch
	rename I lb_ch
	rename J ub_ch
	
	g index=22-_n*2-0.4
	g index1=index+0.4
	g index2=index+0.8
	

	twoway ///
		(scatter index mean_vc  ,	sort(index) msymbol(O) mcolor(green) msize(large) mlc(black)) ///
		(rcap lb_vc ub_vc index,	sort lc(black) lp(solid) msize(small) lw(medium) hor ) ///
		(scatter index1 mean_thc  , sort msymbol(T) mcolor(maroon) msize(large) mlc(black)) ///
		(rcap lb_thc ub_thc index1, sort lc(black) lp(solid) msize(small) lw(medium) hor) ///
		(scatter index2 mean_ch , 	sort msymbol(S) mcolor(navy) msize(large) mlc(black)) ///
		(rcap lb_ch ub_ch index2, 	sort lc(black) lp(solid) msize(small) lw(medium) hor) ///	
		,ylabel(20 "% of Checklist (ISTC Standard)" 18 "% of Checklist (China Standard)" ///
			16 "% of Essential History Checklist" 14 "Correct Case Management" 12 "CXR Ordered" ///
			10 "Sputum Test Ordered"  8 "Referral"  6 "No Antibiotics" 4 "No Fluoroquinolones" ///
			2 "No Steroids" 1.6 " " 2.4 " " 3.6 " " 4.4 " " 5.6 " " 6.4 " " 7.6 " " 8.4 " " 9.6 " " 10.4 " " ///
			11.6 " " 12.4 " " 13.6 " " 14.4 " " 15.6 " " 16.4 " " 17.6 " " 18.4 " " 19.6 " " 20.4 " " ///
			, angle(horizontal) labsize(medium) labgap(*2)) ///
		legend( pos(1) ring(0) col(1) ///
		rows(3) ///
		order(1 3 5) ///
		label(1 "Village") ///
		label(3 "Township") ///
		label(5 "County") ///
		hole(2 4 6) symy(*2)) ///
		xlabel(0(0.25)1.0) ///
		xlabel(0"0" 0.25"25%" 0.5"50% "0.75"75%" 1"100%") ///
		scale(0.7) graphregion(color(white)) 
		
	* Figure 2 is not generated automatically.
	
	
/*--------
Step 3: Figure 3: Correlation between Provider Certification and Standardized Patient Outcomes
--------*/	

		
use "$datadir/TB_analysis.dta", clear

	label var tb_m_corr "Correctly Managed Case"
	label var tb_m_1 "Chest Radiograph"
	label var tb_m_3 "Referral"
	label var noantibio "No Antibiotics"

	* Output
	
		chartable tb_m_corr tb_m_1 tb_m_3 noantibio ///
		using "$outdir/Fig_3.xlsx" if CH==0 ///
		, c(xi: logit) rhs(pracdoc usecxr rewarddocyes age male hiedu income patientload traintbyes VC i.countycode i.groupcode) ///
		regopts(vce(robust)) or pstars case1(" "No Practicing Cert.) case2(" "Practicing Cert.)
			
		graph save   "$outdir/Fig_3_08SEP2017.gph" , replace
		graph export "$outdir/Fig_3_08SEP2017.png" , width(4000) replace			
	
	* Figure 2 is not generated automatically.
			
/*--------
Step 4: Figure 4. Know-Do Gap: comparison of data from vignettes versus SP interaction among the same providers 
--------*/	

	use "$datadir/tb_know_do_gap.dta", clear
	
	recode vignette (1=0) (0=1), gen(newvignette)
	
	cap mat drop results
	
	local binaries " corrdiag tb_m_corr antibiotic tb_m_3 tb_m_1 tb_m_2 tb_m_12 tb_m_1_2 re5_tb re4_tb re1_tb re8_tb re9_tb re10_tb rq1_tb rq2_tb rq3_tb rq4_tb rq5_tb rq6_tb rq9_tb rq10_tb rq13_tb" 

	qui foreach var of varlist ///
		corrdiag tb_m_corr numofdrug antibiotic tb_m_3 ///
		tb_m_1 tb_m_2 tb_m_12 tb_m_1_2 re5_tb re4_tb re1_tb re8_tb re9_tb re10_tb ///
		rq1_tb rq2_tb rq3_tb rq4_tb rq5_tb rq6_tb rq9_tb rq10_tb rq13_tb { 

		sum `var' if vignette == 1
		if regexm("`binaries'","`var'") local a = `r(mean)'
			else local a = `r(mean)'
		
		sum `var' if vignette == 0
		if regexm("`binaries'","`var'") local b = `r(mean)'
			else local b = `r(mean)'
						
		reg `var' newvignette i.countycode
			mat reg = r(table)
			matlist reg
			local c = reg[1,1]
			local d = reg[4,1]
					
	
		cap logit `var' newvignette i.countycode, or 
			mat reg = r(table)
			matlist reg
			if regexm("`binaries'","`var'") local e = reg[1,1]
				else local e = .
			if regexm("`binaries'","`var'") local f = reg[4,1]
				else local f = .

			mat results = nullmat(results) \ [`a',`b',`c',`d',`e',`f' ]
			
		}
		
		local columns `" "Vignette" "SP Visit" "Difference" "P Value" "Odd" "Odd P Value" "'
		
		#delimit ;
		local rows `" 
		"Percentage Mentioning TB"
		"Correct Management"
		"Mean # Medicines Given or Prescribed"
		"Percentage Giving Any Antibiotic"
		"Percentage Referring Case"
		"E - Chest X-Ray"
		"E - Sputum AFB Test"
		"E - X-ray and Sputum Test"
		"E - X-ray or Sputum Test"
		"E - Auscultation"
		"E - Temperature"
		"E - Weight"
		"E - HIV Test"
		"E - Diabetes Test"
		"E - Mantoux Test"
		"Q - Cough Duration"
		"Q - Producing Sputum"
		"Q - Past TB"
		"Q - Family TB"
		"Q - Blood in Sputum"
		"Q - Fever Duration"
		"Q - Loss of Appetite"
		"Q - Weight Loss"
		"Q - Taken Any Medicine"
			"' ;
		#delimit cr
		
		
		xml_tab ///
			results ///
			using "$outdir/TB_tables_08SEP2017.xls" ///
			, replace ///
			title("Know do gap") ///
			sheet("Fig 4") ///
			rnames(`rows') ///
			cnames(`columns') ///
			lines(COL_NAMES 3 LAST_ROW 3)  format((SCLB0) (SCCB0 NCRR3))			
	
	* Figure 4 is not generated automatically.
	
	
/*-------
Step 5: Table 2: Simulation of System-level Management Outcomes with and without Managed Referrals
--------*/	

	use "$datadir/tb_spv_system.dta", clear
	
	set more off

	log using "$outdir/system_bootstrap_45" , replace
	
	// 45 sample
	keep if system == 1 //keep only system sample
	
	foreach var of varlist vcout1 vcout2 thcout1 thcout2 {
		ci proportion `var' 
		bootstrap r(mean) 	,reps(500) seed(19901018): ci proportion `var' 
		bootstrap r(lb) 	,reps(500) seed(19901018): ci proportion `var' 
		bootstrap r(ub) 	,reps(500) seed(19901018): ci proportion `var' 
	}
	
	foreach var of varlist patient1 patient2 {
		ci means `var' 
		bootstrap r(mean) 	,reps(500) seed(19901018): ci means `var' 
		bootstrap r(lb) 	,reps(500) seed(19901018): ci means `var' 
		bootstrap r(ub) 	,reps(500) seed(19901018): ci means `var' 
	}
	
	log close _all
	
	* Table 2 is not generated automatically.
	* Figure 5 is not generated automatically.
			
			
			
			
/**********************			
Supporting Information
***********************/

/*-------
Step 6: S1 Table. Provider Characteristics
--------*/

use "$datadir/TB_analysis.dta", clear
		
	foreach var of varlist CXR usecxr sputum usesputum fulltime parttime {
		replace `var'=0 if level=="Village" & `var'==.
	} 
	* note: Village Clinics do not have those variables, need to be delete them in the table
	
	cap mat drop results
	
	local binaries " CXR usecxr sputum usesputum stethoscope thermometer managetb fulltime parttime susrefer_town susrefer_county susrefer_city susrefer_cdc rewardclinyes rewarddocyes clitraintbyes pracdoc assipracdoc ruraldoc male hiedu traintbyes "
			
	qui foreach var of varlist ///
		totpat numdoc CXR usecxr sputum usesputum stethoscope thermometer ///
		managetb fulltime parttime numcough nummanage numsuspect ///
		susrefer_town susrefer_county susrefer_city susrefer_cdc ///
		rewardclinyes rewardclin rewarddocyes rewarddoc clitraintbyes clitraintb ///
		pracdoc assipracdoc ruraldoc age male hiedu income traintbyes traintb {
	  
		cap mat drop var
			
			foreach caselogic in =="Village" =="Township" {  
			
				if regexm("`binaries'"," `var' ") count if `var'  == 1 & level `caselogic'
				if regexm("`binaries'"," `var' ") local n = `r(N)' 
						else local n = .
				
				sum `var' if level `caselogic'
					if regexm("`binaries'"," `var' ") local mean = 100 * `r(mean)'
						else local mean = `r(mean)'
			
				if regexm("`binaries'"," `var' ") ci proportions `var' if level `caselogic', wilson 
					else ci means `var' if level `caselogic'
						
					local lower = `r(lb)'
						if regexm("`binaries'"," `var' ") local lower = 100 * `lower'
					local upper = `r(ub)'
						if regexm("`binaries'"," `var' ") local upper = 100 * `upper'
						
				mat var = nullmat(var) , [`n',`mean',`lower',`upper']
				
				}
					
			mat results = nullmat(results) \ var
			
			}
		

		local columns `" "Number" "Percentage or Mean" "Lower 95% CI" "Upper 95% CI" "'
		
		#delimit ;
		local rows `" 
			"Number of patients in catchment area" 
			"Number of physicians working full time at the acility"
			"Facility has X-Ray machine"
			"Facility has profesional staff to use X-ray machine"
			"Facility has sputum smear test equipment"
			"Facility has profesional staff to use sputum smear test equipment"
			"Facility has stethoscope"
			"Facility has thermometer"
			"Facility manages care of diagnosed TB patients"
			"Facility has full-time doctors charged with management of TB patients"
			"Facility has part-time doctors charged with management of TB patients"
			"Patients with persistent cough in past two weeks"
			"Number of TB patients being managed at end of calendar year 2014"
			"Number of suspected TB patients in calender year 2014"
			"Township Health Center"
			"County Hospital"
			"City Hospital"
			"CDC"
			"Facility receives reward"
			"If yes, facility reward amount (yuan)"
			"Doctor receives reward"
			"If yes, doctor reward amount (yuan)"
			"Physicians have received Tuberculosis-specific training in 2014"
			"If yes, times"
			"Practicing Physician Certificate"
			"Assistant Practicing Physician Certificate"
			"Rural Physician Certificate"
			"Provider age (years)"
			"Male provider"
			"Provider education, upper secondary or higher"
			"Provider monthly salary (1,000 yuan)"
			"Received Tuberculosis-specific training in 2014"
			"If yes, times"
			"' ;
		#delimit cr
			
		xml_tab ///
			results ///
			using "$outdir/TB_tables_s1_11JUL2017.xls" ///
			, replace ///
			rnames(`rows') ///
			showeq ceq("Village Clinics" "Village Clinics" "Village Clinics" "Village Clinics" "Township Health Centers" "Township Health Centers" "Township Health Centers" "Township Health Centers") /// 
			cnames(`columns' `columns' ) ///
			lines(COL_NAMES 3 LAST_ROW 3)  format((SCLB0) (SCCB0 NCRR2))
			
	* S1 Table is not generated automatically.			
			
/*--------
Step 7: S2 Table. Completion of Checklist Items
--------*/	

use "$datadir/TB_analysis.dta", clear

	global checklist "rq1_tb-re11_tb"
	set more off
	
	*Questions and Exams
	eststo clear
	qui estpost tabstat $checklist, by(level) statistics(mean sem) columns(statistics) 
	esttab using "$outdir/TB_checklist_11JUL2017.csv", ///
		main(mean %9.2f) aux(semean %9.2f) ///
		nostar nonote nomtitle nonumber unstack ///
		nogap noobs wide label replace onecell

	* S2 Table is not generated automatically.			
			
	
/*--------
Step 8: S3 Table. Correlates of Correct Management, CXR, Referral, and Antibiotic Prescription of Standardized Patients among Village and Township Providers
--------*/

use "$datadir/TB_analysis.dta",replace
	 
	 cap mat drop results
		
		qui foreach var of varlist tb_m_corr tb_m_1 tb_m_3 antibiotic {
			preserve
			keep if 1 $`var'
			
*				xi: logit `var' pracdoc rewarddocyes age male hiedu income patientload traintbyes VC i.countycode i.groupcode if CH==0 , vce(robust) or 
				xi: logit `var' pracdoc usecxr rewarddocyes age male hiedu income patientload traintbyes VC i.countycode i.groupcode if CH==0 , vce(robust) or 
				est sto `var'
				local lab : var label `var'
				local theCols `"`theCols' "`lab'""'
				
				sum `var' if CH==0
					local mu = `r(mean)'
					estadd scalar mean = `mu' : `var'
					
				local outlist "`outlist' `var'(, or) "
					
			restore	
			}
			
	* Output
	
		xml_tab `outlist' using "$outdir/TB_table_s3_11July2017.xls", append below p note("note: p-values reported in parentheses under odds ratios.") ///
			lines(COL_NAMES 3 LAST_ROW 3) format((SCLB0) (SCCB0 NCRR2)) cnames(`theCols') c("Constant") stats(N mean) ///
			title("S3 Table. Correlates of Correct Management, CXR, Referral, and Antibiotic Prescription of Standardized Patients among Village and Township Providers") ///
			sheet("S3 Table")  ///
			keep(pracdoc usecxr rewarddocyes age male hiedu income patientload traintbyes VC) drop (o.*)


/*-------
Step 9: S4 Table. Additional Statistics Comparing Vignettes and SP Visits.
--------*/	
	
	use "$datadir/tb_know_do_gap.dta", clear
	
	recode vignette (1=0) (0=1), gen(newvignette)
	
	cap mat drop results
	
	local binaries " corrdiag tb_m_corr antibiotic tb_m_3 tb_m_1 tb_m_2 tb_m_12 tb_m_1_2 re5_tb re4_tb re1_tb re8_tb re9_tb re10_tb rq1_tb rq2_tb rq3_tb rq4_tb rq5_tb rq6_tb rq9_tb rq10_tb rq13_tb" 

	qui foreach var of varlist ///
		corrdiag tb_m_corr numofdrug antibiotic tb_m_3 ///
		tb_m_1 tb_m_2 tb_m_12 tb_m_1_2 re5_tb re4_tb re1_tb re8_tb re9_tb re10_tb ///
		rq1_tb rq2_tb rq3_tb rq4_tb rq5_tb rq6_tb rq9_tb rq10_tb rq13_tb { 

		sum `var' if vignette == 1
		if regexm("`binaries'","`var'") local a = `r(mean)'
			else local a = `r(mean)'
		
		sum `var' if vignette == 0
		if regexm("`binaries'","`var'") local b = `r(mean)'
			else local b = `r(mean)'
						
		reg `var' newvignette i.countycode
			mat reg = r(table)
			matlist reg
			local c = reg[1,1]
			local d = reg[4,1]
			local e = reg[5,1]
			local f = reg[6,1]
					
	
		cap logit `var' newvignette i.countycode, or 
			mat reg = r(table)
			matlist reg
			if regexm("`binaries'","`var'") local g = reg[1,1]
				else local g = .
			if regexm("`binaries'","`var'") local h = reg[4,1]
				else local h = .
			if regexm("`binaries'","`var'") local i = reg[5,1]
				else local i = .
			if regexm("`binaries'","`var'") local j = reg[6,1]
				else local j = .

			mat results = nullmat(results) \ [`a',`b',`c',`d',`e',`f',`g',`h' ,`i',`j' ]
			
		}
		
		local columns `" "Vignette" "SP Visit" "Difference" "P Value" "95%CI lower" "95%CI Upper" "Odd" "Odd P Value" "Odd 95%CI lower" "Odd 95%CI Upper" "'
		
		#delimit ;
		local rows `" 
		"Percentage Mentioning TB"
		"Correct Management"
		"Mean # Medicines Given or Prescribed"
		"Percentage Giving Any Antibiotic"
		"Percentage Referring Case"
		"E - Chest X-Ray"
		"E - Sputum AFB Test"
		"E - X-ray and Sputum Test"
		"E - X-ray or Sputum Test"
		"E - Auscultation"
		"E - Temperature"
		"E - Weight"
		"E - HIV Test"
		"E - Diabetes Test"
		"E - Mantoux Test"
		"Q - Cough Duration"
		"Q - Producing Sputum"
		"Q - Past TB"
		"Q - Family TB"
		"Q - Blood in Sputum"
		"Q - Fever Duration"
		"Q - Loss of Appetite"
		"Q - Weight Loss"
		"Q - Taken Any Medicine"
			"' ;
		#delimit cr
		
		
		xml_tab ///
			results ///
			using "$outdir/TB_tables_s4_11JUL2017.xls" ///
			, replace ///
			title("S4 Table. Additional Statistics Comparing Vignettes and SP Visits") ///
			sheet("S4 Table") ///
			rnames(`rows') ///
			cnames(`columns') ///
			lines(COL_NAMES 3 LAST_ROW 3)  format((SCLB0) (SCCB0 NCRR3))			
	
	* S4 Table is not generated automatically.	
			
/*--------
Step 10: S5 Table. Patient Selection into Health System Tiers with Symptoms of TB
--------*/	

	use "$datadir/TB_sort.dta", clear
	tabstat hypoill realill realdoc
	ta hypolevel
	ta reallevel
	
	* S5 Table is not generated automatically.	
	

	
/*-------
Step 11: S6 Table. Simulation of System-level Management Outcomes with and without Managed Referrals (All Health Systems)
--------*/	

	use "$datadir/tb_spv_system.dta", clear
	
	set more off

	log using "$outdir/system_bootstrap_207" , replace
	
	// 207 sample
	foreach var of varlist vcout1 vcout2 patient1 patient2 {
		ci means `var' 
		bootstrap r(mean) 	,reps(500) seed(19901018): ci means `var'
		bootstrap r(lb) 	,reps(500) seed(19901018): ci means `var'
		bootstrap r(ub) 	,reps(500) seed(19901018): ci means `var'
	}

	foreach var of varlist thcout1 thcout2 {
		ci means `var' 
		bootstrap r(mean) 	,reps(500) seed(19901018): ci proportion `var'
		bootstrap r(lb) 	,reps(500) seed(19901018): ci proportion `var'
		bootstrap r(ub) 	,reps(500) seed(19901018): ci proportion `var'
	}
	

	log close _all
	
	* S6 Table is not generated automatically.
	
	
/*-------
Step 12: S7 Table. Simulation of Out-of-Pocket Costs with and without Managed Referrals
--------*/	
	
	use "$datadir/tb_spv_system.dta", clear
	
	set more off

	log using "$outdir/system_bootstrap_45_fee" , replace
	
	// 45 sample
	keep if system == 1 //keep only system sample
	
	foreach var of varlist vcfee1 thcfee1 vcfee2 thcfee2 patientfee1 patientfee2 {
		ci means `var' 
		bootstrap r(mean) 	,reps(500) seed(19901018): ci means `var' 
		bootstrap r(lb) 	,reps(500) seed(19901018): ci means `var' 
		bootstrap r(ub) 	,reps(500) seed(19901018): ci means `var' 
	}
	
	
	log close _all
		
	* S7 Table is not generated automatically.
	
	* Have a lovely day!
