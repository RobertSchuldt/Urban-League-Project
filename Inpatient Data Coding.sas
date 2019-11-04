/* Rural Urban League project investigating the impact of medicaid expansion on preventable hospitalization rates among
younger arkansans. 

Code: Robert Schuldt
Email: rschuldt@uams.edu

*/

libname ar '**************ct\Data';

proc import datafile = "Z:\DATA\Urban League Project\Data\arfips.xlsx"
dbms = xlsx out = counties replace;
run;

data counties_prep;
	set counties;
		MAILCNTY = upcase(county);
run;

proc sort data = counties_prep;
by MAILCNTY;
run;
%include '**********************s\infile macros\sort.sas';
/*initial pull in of the data and generate a random Key for each of the records*/




data inpatient;
	set ar.young_inv_all_ages;
	where ADMTDATE ne "00000000";
		adms_dt = input(ADMTDATE, yymmdd8.);
		rename DRG = DRG1;
		drg4 = substr(hdrg, 2, 3);
		
	test = substr(ADMTDATE, 1, 4);

		if _AGE lt 18 then delete;
		if _Age gt 34 then delete;
		/*change for splitting pop*/

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
	do NOBS = 1 to 7000000;
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

proc freq data = ar.young_inv;
table SRCEPAY1 SRCEADMT TYPEADMT;
run;
/*We only have 9 observations that are miscoded so no big deal*/


proc contents data = inpatient_county position out = var_list;
run;
/* Check if arkansas data has all variables we need

make a small report on the data, age, etc, descriptive data

Must seperate ICD9 and ICD10 coding
*/

proc import datafile = '*******************\Poster B\DRG MDC CROSSWALK'
dbms = xlsx out = mdc replace;
run;

data mdc_crosswalk;
	set mdc;

	drg = ms_drg;
run;
%sort(mdc_crosswalk, DRG)

data split;
merge key (keep= newid) inpatient_county;
if (ADMTDATE = .) then delete;
run;
/*Prepare the data for the PQI programs*/
%macro icd(setdata, value, year);
data &setdata;
	set split;
	where adms_dt &value '01OCT2015'd and test = "&year";
	
	drop county;


		idl = lag(newid);
			retain key 1;
				key = key + 1;

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
	if SRCEPAY1 = "C" or  SRCEPAY1 = "1" then PAY1 = 1;
	if SRCEPAY1 = "D" or  SRCEPAY1 = "2" then PAY1 = 2;		
	if SRCEPAY1 = "F" or SRCEPAY1 = "5" or  SRCEPAY1 ="Q" or SRCEPAY1 = "7" or SRCEPAY1 = "6" then PAY1 = 3;
	if SRCEPAY1 = "S" or SRCEPAY1 = "8" then PAY1 = 4;
	if SRCEPAY1 = "A" then PAY1 = 5;
	
	Pay2 = .;
/*Patient locations*/
	PSTCO = fips;

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

   if TYPEADMT = '1' then  ATYPE = 1 ;
   if TYPEADMT = '2'  then ATYPE = 2 ;
   if TYPEADMT = '3'  then ATYPE = 3 ;
   if TYPEADMT = '4'  then ATYPE = 4 ;
   if TYPEADMT = '5'  then ATYPE = 5 ;
   if TYPEADMT = '9'  then ATYPE = 6 ;
/* Admission Source*/

   if SRCEADMT = '1' then ASOURCE = 5;
   if SRCEADMT = 'E' then asource = 1;
   if SRCEADMT = '4' then asource = 2;
   if SRCEADMT = '2' or SRCEADMT= '5' or SRCEADMT= '6' or SRCEADMT = 'D' or SRCEADMT= 'F' then asource = 3;
   if SRCEADMT = '8' then asource = 4;
   if SRCEADMT = '3' or SRCEADMT = '9' or SRCEADMT= '7' then asource = 5;

/*Length of stay*/

   LOS = _LOS;
 	if _LOS = . then LOS = _LOS_;

/* DRG*/
	  length drg  3;

   if DRG1 ne " " and substr(DRG1, 1, 1) ne 'S' then drg = DRG1;
   if DRG3 ne " " and substr(DRG3, 1, 1) ne 'S' then drg = DRG3;
   if DRG4 ne ' ' and substr(DRG4, 1, 1) ne 'S' then drg = DRG4;
	
   DRGVER = 25;
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

/*Procedure codes */

	array pr (*)  PROC1 PROC2 PROC3 PROC4 PROC5 PROC6 PROC7 PROC8 PROC9 PROC10 PROC11 PROC12
					PROC13 PROC14 PROC15 PROC16 PROC17 PROC18 PROC19 PROC20 PROC21;
	array pk (*) $ PR1 - PR21;
		do k = 1 to 21;
			if pr(k) ne " " then pk(k) = pr(k);
		end;

	array pc (*) PROC1 PROC2 PROC3 PROC4 PROC5 PROC6 PROC7 PROC8 PROC9 PROC10 PROC11 PROC12
					PROC13 PROC14 PROC15 PROC16 PROC17 PROC18 PROC19 PROC20 PROC21;
	array pcc (*) prc1 - prc21;
		do y = 1 to 21;
			if pc(y) ne " " then pcc(y) = 1;
		end;


NPR = sum( of prc1-prc21);


if SRCEADMT = '4' then POINTOFORIGINUB04 = 1;
if SRCEADMT = '5' then POINTOFORIGINUB04 = 1;
if atype = 4 then POINTOFORIGINUB04 = 1;
if SRCEADMT = '6' then POINTOFORIGINUB04= 1;

/* Year of admission*/

YEAR = 	&year;
DQTR = qtr(adms_dt);

run;

%sort(&setdata ,drg)


data &setdata;
	merge &setdata (in = a) mdc_crosswalk (in = b);
	by drg;
	if a;
	run;
run;
%mend icd;

%icd(ar.icd92007, lt, 2007)
%icd(ar.icd92008, lt, 2008)
%icd(ar.icd92009, lt, 2009)
%icd(ar.icd92010, lt, 2010)
%icd(ar.icd92011, lt, 2011)
%icd(ar.icd92012, lt, 2012)
%icd(ar.icd92013, lt, 2013)
%icd(ar.icd92014, lt, 2014)
%icd(ar.icd92015, lt, 2015)
%icd(ar.icd102015, gt, 2015)
%icd(ar.icd102016, gt, 2016)
%icd(ar.icd102017, gt, 2017)

/*Now that I have split the dates of ICD 9 and ICD10 codes I can start to run the PQI
software that I using from AHRQ to generate preventable hospitalizations and must initialize the controls*/

/*NOW I HAVE RUN PQI ON ALL THE FILES*/

data check_insurance;
	set ar.icd92007
	ar.icd92011
	ar.icd92012
	ar.icd92013
	ar.icd92014
	ar.icd92015
	ar.icd102015
	ar.icd102016
	ar.icd102017;
run;
proc format;
value insur
1 = "Medicare"
2 = "Medicaid"
3 = "Private"
4 = "Self Pay"
5 = "No Charge"
6 = "Other"
;
run;


proc freq data = check_insurance;
title 'Insurance Type';
table pay1;
format pay1 insur.;
run;



libname final 'Z:\DATA\Urban League Project\All pop pqi';
%macro addyr(data, year);
data final.all&data;
	set final.all&data;
	year = &year;
	run;

%mend addyr;
%addyr(2007, 2007)
%addyr(2008, 2008)
%addyr(2009, 2009)
%addyr(2010, 2010)
%addyr(2011, 2011)
%addyr(2012, 2012)
%addyr(2013, 2013)
%addyr(2014, 2014)
%addyr(2015pt, 2015)
%addyr(2015pt2, 2015)
%addyr(2016, 2016)
%addyr(2017, 2017)

data pqi_data;
	set 

	final.all2011
	final.all2012
	final.all2013
	final.all2014
	final.all2015pt
	final.all2015pt2
	final.all2016
	final.all2017;

	array op(13) OAPQ05	OAPQ07	OAPQ08	OAPQ10	OAPQ11	OAPQ12	OAPQ14	OAPQ15	OAPQ16	OAPQ90	OAPQ91	OAPQ92	OAPQ93;
	do i = 1 to 13;
		op(i) = round((op(i)*10000), 0.01);
		
	end;
	run;



%macro addyr(data, year);
data final.age&data;
	set final.age&data;
	year = &year;
	run;

%mend addyr;

%addyr(2011, 2011)
%addyr(2012, 2012)
%addyr(2013, 2013)
%addyr(2014, 2014)
%addyr(2015, 2015)
%addyr(2015v2, 2015)
%addyr(2016, 2016)


data pqi_data;
	set 
	final.age2011
	final.age2012
	final.age2013
	final.age2014
	final.age2015
	final.age2015v2
	final.age2016;
	where AGECAT = 1;
	run;

	
%macro addyr(data, year);
data final.race&data;
	set final.race&data;
	year = &year;
	run;

%mend addyr;

%addyr(2011, 2011)
%addyr(2012, 2012)
%addyr(2013, 2013)
%addyr(2014, 2014)
%addyr(2015, 2015)
%addyr(2015v2, 2015)
%addyr(2016, 2016)
%addyr(2017, 2017)



data pqi_data;
	set 
	final.race2011
	final.race2012
	final.race2013
	final.race2014
	final.race2015
	final.race2015v2
	final.race2016
	final.race2017;
	where RACECAT = 1 or RACECAT = 2 or RACECAT = 3;
	if AGECAT ne 1 then delete;
	run;

	
%macro addyr(data, year);
data final.sex&data;
	set final.sex&data;
	year = &year;
	run;

%mend addyr;

%addyr(2011, 2011)
%addyr(2012, 2012)
%addyr(2013, 2013)
%addyr(2014, 2014)
%addyr(2015, 2015)
%addyr(2015v2, 2015)
%addyr(2016, 2016)
%addyr(2017, 2017)


data pqi_data;
	set 
	final.sex2011
	final.sex2012
	final.sex2013
	final.sex2014
	final.sex2015
	final.sex2015v2
	final.sex2016
		final.sex2017;
	where AGECAT = 1;
	if  RACECAT = 4 then delete;
	if  RACECAT = 5 then delete;
	if  RACECAT = 6 then delete;
run;

libname split 'Z:\DATA\Urban League Project\PQI\PQI Software\Split Data';
	
%macro addyr(pre, data, year);
data split.&pre&data;
	set split.&pre&data;
	year = &year;
	run;

%mend addyr;

%addyr(over, 2011, 2011)
%addyr(over,2012, 2012)
%addyr(over,2013, 2013)
%addyr(over,2014, 2014)
%addyr(over,2015pt1, 2015)
%addyr(over,2015pt2, 2015)
%addyr(over,2016, 2016)
%addyr(over,2017, 2017)

%addyr(under, 2011, 2011)
%addyr(under,2012, 2012)
%addyr(under,2013, 2013)
%addyr(under,2014, 2014)
%addyr(under,2015pt1, 2015)
%addyr(under,2015pt2, 2015)
%addyr(under,2016, 2016)
%addyr(under,2017, 2017)


libname map 'Z:\DATA\Urban League Project\Maps';

data mapping2011;
	set map.maps2011;
		array op(13) OAPQ05	OAPQ07	OAPQ08	OAPQ10	OAPQ11	OAPQ12	OAPQ14	OAPQ15	OAPQ16	OAPQ90	OAPQ91	OAPQ92	OAPQ93;
	do i = 1 to 13;
			op(i) = round((op(i)*10000), 0.01);
	end;
run;

data mapping2016;
	set map.maps2016;
		array op(13) OAPQ05	OAPQ07	OAPQ08	OAPQ10	OAPQ11	OAPQ12	OAPQ14	OAPQ15	OAPQ16	OAPQ90	OAPQ91	OAPQ92	OAPQ93;
	do i = 1 to 13;
			op(i) = round((op(i)*10000), 0.01);
	end;
run;

data mapping2017;
	set map.maps2017;
		array op(13) OAPQ05	OAPQ07	OAPQ08	OAPQ10	OAPQ11	OAPQ12	OAPQ14	OAPQ15	OAPQ16	OAPQ90	OAPQ91	OAPQ92	OAPQ93;
	do i = 1 to 13;
			op(i) = round((op(i)*10000), 0.01);
	end;
run;

data over_data;
	set 
	split.over2011
	split.over2012
	split.over2013
	split.over2014
	split.over2015pt1
	split.over2015pt2
	split.over2016
	split.over2017;
		if agecat = 3 or agecat = 4 then delete;
			if racecat = 1 then race = "white";
	if racecat = 2 then race = "black";

	array op(13) OAPQ05	OAPQ07	OAPQ08	OAPQ10	OAPQ11	OAPQ12	OAPQ14	OAPQ15	OAPQ16	OAPQ90	OAPQ91	OAPQ92	OAPQ93;
	do i = 1 to 13;
			op(i) = round((op(i)*10000), 0.01);
	end;

run;


data under_data;
	set 
	split.under2011
	split.under2012
	split.under2013
	split.under2014
	split.under2015pt1
	split.under2015pt2
	split.under2016
	split.under2017;
		if agecat = 3 or agecat = 4 then delete;
			if racecat = 1 then race = "white";
	if racecat = 2 then race = "black";
	
	array op(13) OAPQ05	OAPQ07	OAPQ08	OAPQ10	OAPQ11	OAPQ12	OAPQ14	OAPQ15	OAPQ16	OAPQ90	OAPQ91	OAPQ92	OAPQ93;
	do i = 1 to 13;
		op(i) = round((op(i)*10000), 0.01);
		
	end;

run;

