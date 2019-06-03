/* Urban League State level insurance trends and changes among the millenial population project

Code: RObert Schuldt
Email rschuldt@uams.edu
*/

proc import datafile = "Z:\DATA\Urban League Project\Data\insurancedata.csv"
dbms=csv out=insurace replace;
run;

%let wi = total_white_insur_;
%let wu = total_white_uninsur_;

data calculate;
	set insurace;
	where state ne "Puerto Rico";

	tw = &wi.19_25 + &wu.19_25;
	dif = total_white_19_25 - tw;
	run;

/*The data does match the way it should*/
%let bi = Total_AA_Insur_;
%let bu = Total_AA_UnInsur_;
data percents;
	set calculate;

	%let aa = Per_AA_;
	%let w = Per_white_;

	millenial_aa_un_19_34 = (&bu.19_25 + &bu.26_34/Total_AA_19_25 + Total_AA_26_34)*100;
	millenial_white_un_19_34 = (&wu.19_25 + &wu.26_34/Total_white_19_25 + Total_white_26_34)*100;

	


run;

proc sort data = percents;
by State Year;
run;
