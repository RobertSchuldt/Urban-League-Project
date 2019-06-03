/* Rural Urban League project investigating the impact of medicaid expansion on preventable hospitalization rates among
younger arkansans. 

Code: Robert Schuldt
Email: rschuldt@uams.edu

*/

libname ar 'Z:\DATA\Urban League Project\Data';

/*initial pull in of the data*/

data inpatient;
	set ar.young_inv;
	run;

proc contents position out = var_list;
run;
/* Check if arkansas data has all variables we need

make a small report on the data, age, etc, descriptive data

*/
proc 
