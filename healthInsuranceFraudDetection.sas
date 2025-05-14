proc import datafile="/home/u64235198/sasuser.v94/Healthcare Fraud/enhanced_health_insurance_claims.csv"
    out=claims_raw
    dbms=csv
    replace;
    getnames=yes;
run;

data claims_trimmed;
    set claims_raw;
    keep ClaimID ProviderID ClaimAmount ProcedureCode DiagnosisCode PatientAge PatientGender ProviderSpecialty 
         ClaimStatus PatientIncome PatientMaritalStatus PatientEmploymentStatus ProviderLocation;
run;

proc sort data=claims_trimmed nodupkey out=claims_nodup;
    by ClaimID;
run;


data claims_clean;
    set claims_nodup;
    if missing(ClaimID) or missing(ClaimAmount) or missing(ProcedureCode) then delete;
run;

data claims_clean;
    set claims_clean;
    ClaimAmountNum = input(compress(ClaimAmount, ',$'), best12.);
    PatientIncomeNum = input(compress(PatientIncome, ',$'), best12.);
    drop ClaimAmount PatientIncome;
    rename ClaimAmountNum = ClaimAmount PatientIncomeNum = PatientIncome;
run;

proc means data=claims_clean min max mean std n;
    var ClaimAmount PatientAge PatientIncome;
run;

data claims_clean;
    set claims_clean;
    if PatientAge <= 0 or PatientAge > 110 then delete;
    if ClaimAmount <= 0 then delete;
run;

data claims_clean;
    set claims_raw;
    
    /* Remove bad ages (e.g., 0 or over 120) */
    if PatientAge < 0 or PatientAge > 110 then delete;

    /* Remove zero or negative claim amounts */
    if ClaimAmount <= 0 then delete;

    /* Drop missing essential fields */
    if missing(ClaimID) or missing(ClaimAmount) or missing(ProcedureCode) then delete;
run;

data claims_clean;
    set claims_clean;

    /* Claim-to-Income Ratio */
    claim_to_income = ClaimAmount / PatientIncome;

    /* Age Bucket */
    length age_group $15;
    if PatientAge < 18 then age_group = "Child";
    else if PatientAge < 40 then age_group = "Young Adult";
    else if PatientAge < 65 then age_group = "Adult";
    else age_group = "Senior";
run;

proc means data=claims_clean n mean std min max;
    var ClaimAmount PatientAge PatientIncome claim_to_income;
run;

proc freq data=claims_clean;
    tables age_group PatientGender PatientEmploymentStatus ClaimStatus;
run;

proc format;
    value $gender_fmt 'M' = 'Male' 'F' = 'Female';
    value $emp_fmt
        'Employed' = 'Working'
        'Student'  = 'Student'
        'Retired'  = 'Retired'
        'Unknown'  = 'Unknown';
run;

data claims_clean;
    set claims_clean;
    format PatientGender $gender_fmt. PatientEmploymentStatus $emp_fmt.;
run;


proc means data=claims_clean noprint;
    var ClaimAmount;
    output out=claim_stats mean=mean_amt std=std_amt;
run;



proc univariate data=claims_clean;
    var ClaimAmount;
    histogram ClaimAmount / normal;
    inset mean std min max / format=8.2;
run;


proc univariate data=claims_clean noprint;
    var ClaimAmount;
    output out=iqr_stats p25=q1 p75=q3;
run;

data claims_flagged;
    if _N_ = 1 then set iqr_stats;
    set claims_clean;

    /* Calculate IQR and bounds */
    iqr = q3 - q1;
    upper_bound = q3 + 0.5 * iqr;
    lower_bound = q1 - 0.5 * iqr;

    /* Compute claim_to_income ratio */
    claim_to_income = ClaimAmount / PatientIncome;

    /* Rule-based flagging */
    if ClaimAmount > upper_bound or 
       ClaimAmount < lower_bound or 
       claim_to_income > 0.5 then fraud_flag = 1;
    else fraud_flag = 0;
run;

proc freq data=claims_flagged;
    tables fraud_flag;
run;

proc print data=claims_flagged;
    where fraud_flag = 1;
run;

/* Descriptive statistics */
proc means data=claims_flagged mean std min max maxdec=2;
    class fraud_flag;
    var ClaimAmount PatientIncome claim_to_income;
run;


proc sgplot data=claims_flagged;
    vbar PatientEmploymentStatus / group=fraud_flag groupdisplay=cluster datalabel;
    title "Fraud Flags by Employment Status";
run;

proc sgplot data=claims_flagged;
    vbox ClaimAmount / category=fraud_flag;
    title "Claim Amounts for Fraud vs Non-Fraud";
run;

proc freq data=claims_flagged;
    tables age_group*fraud_flag / nocol nopercent;
run;

proc corr data=claims_flagged;
    var ClaimAmount PatientIncome claim_to_income;
run;

proc freq data=claims_flagged;
    tables fraud_flag*PatientGender / norow nocol nopercent;
    tables fraud_flag*PatientEmploymentStatus;
    tables fraud_flag*age_group;
run;

proc standard data=claims_flagged mean=0 std=1 out=claims_scaled;
    var ClaimAmount PatientIncome claim_to_income;
run;

proc fastclus data=claims_scaled maxclusters=4 out=clustered;
    var ClaimAmount PatientIncome claim_to_income;
run;

proc freq data=clustered;
    tables cluster*fraud_flag;
run;

proc sgplot data=claims_flagged;
    vbox ClaimAmount / category=fraud_flag;
run;

proc sgplot data=claims_flagged;
    scatter x=PatientIncome y=ClaimAmount / group=fraud_flag;
run;


data claims_scored;
    set claims_flagged;
    risk_score = (ClaimAmount > 8000) +
                 (claim_to_income > 0.1) +
                 (PatientIncome < 30000) +
                 (PatientAge < 18 and ClaimAmount > 7000) +
                 (PatientEmploymentStatus in ('Unemployed', 'Student') and ClaimAmount > 7000);
run;

/* Review risk score by fraud_flag */
proc freq data=claims_scored;
    tables risk_score*fraud_flag;
run;


proc sgplot data=claims_scored;
    vbox ClaimAmount / category=risk_score;
    title "Claim Amount Distribution by Risk Score";
run;

proc print data=claims_scored;
    where risk_score >= 3 and fraud_flag = 0;
run;

data claims_final;
    set claims_scored;
    length risk_category $10;
    if risk_score = 0 then risk_category = "Low";
    else if risk_score in (1, 2) then risk_category = "Medium";
    else risk_category = "High";
run;

proc freq data=claims_final;
    tables risk_category*fraud_flag;
run;


proc freq data=claims_final;
    tables PatientEmploymentStatus;
run;
