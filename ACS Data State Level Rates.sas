/* Urban League State level insurance trends and changes among the millenial population project

Code: RObert Schuldt
Email rschuldt@uams.edu
*/

proc import datafile = "*************\insurancedata.csv"
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

proc sql;
create table totals as
select *,
sum(&bu.19_25) as total_bu_19 ,
sum(&bu.26_34) as total_bu_26,
sum(Total_AA_19_25) as totalaa1,
sum(Total_AA_26_34) as totalaa2,
sum(&wu.19_25) as total_wu_19 ,
sum(&wu.26_34) as total_wu_26,
sum(Total_white_19_25) as totalw1,
sum(Total_white_26_34) as totalw2
from percents
where VAR21 ne 5
group by year;
quit;

data total_per;
	set totals;

		other_states_aa_uninsured =((total_bu_19+ total_bu_26)/(totalaa1+totalaa2))*100;
		other_states_white_uninsured =((total_wu_19+ total_wu_26)/(totalw1+totalw2))*100;

	run;
proc sort data = total_per;
by var21;run;

proc freq;
table State;
run;

data part_two;
	set total_per;

	total_unin = total_bu_19 + total_bu_26 + total_wu_26 + total_wu_19;
	total_pop = totalaa1 + totalaa2 + totalw1 + totalw2;

	total_rate = (total_unin/total_pop)*100;
	run;

proc sort data = part_two;
by  year;
run;

proc export data = part_two
dbms = CSV outfile = "************\national_uninsured.csv" replace;
run;

proc import datafile = "**********\arkansas pop.csv"
dbms=csv out=arkansas replace;
run;

data total_ark;
	set arkansas;

	total_pop = Total_White_19_25 + Total_White_26_34 + Total_AA_19_25 + Total_AA_26_34;
	total_unin = Total_White_UnInsur_19_25 + Total_White_UnInsur_26_34 + Total_AA_UnInsur_19_25 + Total_AA_UnInsur_19_25;
	total_rate = (total_unin/total_pop)* 100;

run;

proc export data = total_ark
dbms = CSV outfile = "************\ark_uninsured.csv" replace;
run;
