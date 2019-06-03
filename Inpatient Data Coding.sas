/* Rural Urban League project investigating the impact of medicaid expansion on preventable hospitalization rates among
younger arkansans. 

Code: Robert Schuldt
Email: rschuldt@uams.edu

*/

libname ar '****Data';

proc import datafile = "******ips.xlsx"
dbms = xlsx out = counties replace;
run;

data counties_prep;
	set counties;
		MAILCNTY = upcase(county);
run;

proc sort data = counties_prep;
by MAILCNTY;
run;

/*initial pull in of the data and generate a random Key for each of the records*/

data inpatient;
	set ar.young_inv;
	where ADMTDATE ne "00000000";
		adms_dt = input(ADMTDATE, yymmdd8.);

		


	run;

proc sort data = inpatient;
by MAILCNTY;
run;

data inpatient_county;
merge inpatient (in = a) counties_prep (in = b);
by MAILCNTY;
if a;

run;
/* We only lose about 9 observations with missing county information*/

data key;
	do NOBS = 1 to 700000;
		newid = '        ';
		do i = 1 to 8;
			rannum = int(uniform(0)*36);
			if (0 <= rannum <= 0) then ranch = byte(rannum+48);
			if (10 <= rannum <= 36) then ranch = byte(rannum + 55);
		substr(newid, i, 1) = ranch;
	end;

	ranord = uniform(0);
	output;
end;
keep newid ranord;
run;

/*Check to make sure I didn't generate any duplicate random numbers*/
TITLE 'Check for Random Number Key Duplicates';
PROC FREQ;
 TABLES newid / noprint out=keylist;
RUN;
PROC PRINT;
 WHERE count ge 2;
RUN; 

proc sort data = key nodupkey;
by newid;
run;

proc sort data = key;
by ranord;
run;

/*We are missing some admission dates that are miscoded as "0000000" so I am eliminating these observations*/
	title "Miscoded Admission Dates Check";
proc freq data = ar.young_inv;
table admtdate;
where admtdate = '00000000';
run;
/*We only have 9 observations that are miscoded so no big deal*/


proc contents data = inpatient_county position out = var_list;
run;
/* Check if arkansas data has all variables we need

make a small report on the data, age, etc, descriptive data

Must seperate ICD9 and ICD10 coding
*/

data split;
merge key (keep= newid) inpatient_county;
if (ADMTDATE = .) then delete;
run;
/*Prepare the data for the PQI programs*/
%macro icd(setdata, value);
data &setdata;
	set split;
	where adms_dt &value '01OCT2015'd;
	drop county;

	KEY = newid;
	AGE = _AGE;

/* Recoding the Race variable to match what we need*/
race1 = race;
race = .;	
	%let r1 = RACE1;
	%let r = race;
	if &r1= 4 and ETHNICTY ne 1 then &r = 1;
	if &r1 = 3 then &r = 2;
	if ETHNICTY = 1 and &r1 = 1 then &r = 3;
	if &r1 = 2 then &r = 4;
	if &r1 = 1 then &r = 5;
	if &r1 = 5 or &r1 = 6 then &r = 6;

/*Now must code for Sex of patient*/

	if GENDER = "M" then SEX = 1;
		else SEX = 2;

/*Payor*/
	PAY1 = 6;
	if SRCEPAY1 = "C" then PAY1 = 1;
	if SRCEPAY1 = "D" then PAY1 = 2;		
	if SRCEPAY1 = "F" or SRCEPAY1 ="Q" then PAY1 = 3;
	if SRCEPAY1 = "S" then PAY1 = 4;
	if SRCEPAY1 = "A" then PAY1 = 5;
	
/*Patient locations*/
	PTSCO = fips;

/* I do no thave hosp ID*/
HOSPID = .;
/* Used this freq to check our discharges

proc freq data = inpatient;
table _Status;
run;

*/

/*Patient disposition*/
	
	DISP = 5;	

	if _STATUS= 1 then DISP = 1;
	if _Status = 2 then DIS = 2;
	if _Status = 3 then DISP = 3;
	if _status = 4 then DISP = 4; 
	if _status = 6 then DISP = 6;
	if _status = 7 then DISP = 7;
	if _status = 20 then DISP = 20;

/* MISSING vars that are required to be added to program, but not neccesary */
   MORT30 = .;

   DNR = .;

   DISCWT = .;
/* Admission type*/

   ATYPE = .;

/* Admission Source*/

   ASOURCE =. ;

/*Length of stay*/

   LOS = _LOS;

/* Diagnosis*/

   array d (9) ADMTDIAG DIAG1 DIAG2 DIAG3 DIAG4 DIAG5 DIAG6 DIAG7 DIAG8;
   array d2 (9) $ DX1 DX2 DX3 DX4 DX5 DX6 DX7 DX8 DX9;

   	do s = 1 to 9;
		ds = '     ';
		d2(s) = d(s);
		
	end;


DXPOA1 = '1';

array dp (8) $ DXPOA2-DXPOA9;
	do i = 1 to 8; 
		dp(i) = '0';
	end;


array d3 (9) ADMTDIAG DIAG1 DIAG2 DIAG3 DIAG4 DIAG5 DIAG6 DIAG7 DIAG8 ;
array c (9) count1-count9;
	do h = 1 to 9;
		if d3(h) ne " " then c(h) = 1;
	end;

NDX = sum(of count1-count9);

/* Year of admission*/

YEAR = 	year(adms_dt);
DQTR = qtr(adms_dt);

		
run;

%mend icd;

%icd(ar.icd9, lt)
%icd(ar.icd10, gt)

/*Now that I have split the dates of ICD 9 and ICD10 codes I can start to run the PQI
software that I using from AHRQ to generate preventable hospitalizations and must initialize the controls*/


/*ICD10*/
%let filename = icd10;
%let version = icd10;

%include "******************ms\PQI_ALL_CONTROL.sas";
run;
/*ICD9*/

%let filename = icd9;
%let version = icd9;

%include "*************************"

/*Now I Must run the measures program. Formats are already saved and prepped*/

