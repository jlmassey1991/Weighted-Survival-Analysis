

********************

* Importing Data   *

*******************;


*Libraries;
libname SVH "\\cdc.gov\project\CCID_NCPDCID_NHSN_SAS\Data\work\_Projects\LTC\COVID-19\SAS datasets";
libname vax "\\cdc.gov\project\CCID_NCPDCID_NHSN_SAS\Data\work\_Projects\Vaccination\Datasets\Current\";
libname covid "\\cdc.gov\project\CCID_NCPDCID_NHSN_SAS\Data\work\_Projects\LTC\COVID-19\SAS datasets\Weekly";


*Import Org IDs Data ;
data org_id;
set SVH.covid19_ltc_facility;
run;

*Limit to SVH Facilities ; 
data svh_facilities;
set org_id;
where factype = "LTC-SVHALF" or factype = "LTC-SVHSNF" ;
run;
***********************************************************************;
/*Mary add: generate a list of distinct org_id*/
proc sql;
create table orglist as
select distinct orgID from svh_facilities;
run;
***************************************************************************;
*Import Vacc Event Data ;
data vacc_event;
set vax.ltccovid19_c19_res_vacc_event;
run;

*Import Covid Event Data ;
data covid_event;
set covid.ltccovid19_svh_event;
run;

********************

* Cleaning Vaccination Datasets    *

*******************;


data vacc_event2;
set vacc_event;

*Removing illogical submission and modifcations from vaccination data ;
if SubmitDateEvent = . then delete;

*Creating Age Variable ;

age = INT(YRDIF(datepart(dob),today(),'ACTUAL')); 

*Creating Race Variable ;
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="Y" and resraceUNK="N" then race="Declined, only";
if resraceAAB="Y" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="Black, only";
if resraceAAB="N" and resraceAMIN="Y" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="AI, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="Y" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="Asian, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="Y" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="NH_PI, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="Y" and resraceDEC="N" and resraceUNK="N" then race="White, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="Y" then race="Unknown, only";
if race= " " then race="Multiracial";

run;

/*test Jason's dataset */
proc sort data=orglist;
by orgid;
run; 

proc sort data=vacc_event2;
by orgid;
run; 

data svhvaccine;
merge vacc_event2 orglist (in=in2);
by orgid;
if in2;
run;

data joined1 (keep=orgID resrecID gender dob ethnicity resadmitdate resdischdate 
dose1date dose1mfg dose2date dose2mfg dose3date dose3dosemfg dose4date dose4dosemfg dose5date dose5dosemfg dose6date dose6dosemfg dose7date dose7dosemfg age race );
set svhvaccine;
where resrecID ne .;
run;

/*select distinct rows so that we have admission and discharge date*/
proc sql;
create table finalwithaddis as 
select distinct * 
from joined1;
quit;

/*get the most recent record*/
proc sort data=finalwithaddis;
   by resrecid resadmitdate ;
run;

/*get the last row most recent record as the base*/
data base additional;
    set finalwithaddis;
    by resrecid resadmitdate;
    if last.resrecid then output base;
	else output additional;
run;

data additional_attempt;
   set additional;
   by resrecid resadmitdate ;
   retain attempt;
   if first.resrecid then attempt=1;
   else attempt+1;
run; 

proc freq data=additional_attempt;
tables attempt;
run;

*************************Seperating different years evaluation***********************;
%macro create(howmany);
%do i=1 %to &howmany;
   data adm_dis&i;
   set additional_attempt (keep=orgid resrecid resadmitdate resdischdate attempt);
   where attempt=&i;
   run;
 %end;
%mend create;
%create(2)

data attemp12;
 merge adm_dis1 adm_dis2 (rename=(resadmitdate=resadmitdate2 resdischdate=resdischdate2));
 by resrecid;
run; 

data final_vac;
merge base attemp12 (rename=(resadmitdate=resadmitdate1 resdischdate=resdischdate1));
by resrecid;
run;

/*final vaccination dataset has 5606 participants' dose records and admission&discharge records*/



*************************
*Cleaning COVID Data
************************;

*Import Covid Event Data ;
data covid_event;
set covid.ltccovid19_svh_event;
run;

data covid_event2;
set covid_event;

*Create Age Variable;
  age = INT(YRDIF(datepart(dob),today(),'ACTUAL')); 

*Create Race Variable;
if resrecid = . then delete;
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="Y" and resraceUNK="N" then race="Declined, only";
if resraceAAB="Y" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="Black, only";
if resraceAAB="N" and resraceAMIN="Y" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="AI, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="Y" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="Asian, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="Y" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="N" then race="NH_PI, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="Y" and resraceDEC="N" and resraceUNK="N" then race="White, only";
if resraceAAB="N" and resraceAMIN="N" and resraceASIAN="N" and resraceNH_PI="N" and resraceWHITE="N" and resraceDEC="N" and resraceUNK="Y" then race="Unknown, only";
if race= " " then race="Multiracial";
keep orgid resrecid eventid eventdate symptomatic c19death c19deathdate dob gender ethnicity age race ;
run;

proc sort data=covid_event2;
   by resrecid eventdate;
run;
/*get the first event as base dataset */
data baseevent;
   set covid_event2;
   by resrecid eventdate;
   retain attempt;
   if first.resrecid then output baseevent;
run; 
/*add attempt variable*/
data covid_event3 ;
   set covid_event2;
   by resrecid eventdate;
   retain attempt;
 if first.resrecid then attempt=1;
   else attempt+1;
run; 

proc freq data=covid_event3;
tables attempt;
run;
/**/
/*up to five event */
********This code is for adding prefix to the variable name, to merge it to a wide format;
*****************************************************************************************
*make a list of names and lables;
proc transpose data=covid_event3 (obs=0)  out=varnames;
var _all_;
run;

data varnames;
set varnames;
where _name_ in ('eventID', 'eventDate', 'symptomatic', 'C19Death', 'C19DeathDate');
run;

*************************Seperating different years evaluation***********************;
%macro create(howmany);
%do i=1 %to &howmany;
   data event&i;
   set work.covid_event3 (keep=resrecid eventid eventdate symptomatic C19Death c19deathdate attempt);
   where attempt=&i;
   run;
 %end;
%mend create;
%create(5)

*Gen the name=newname value pairs;
%macro change(dataset,prefix);
proc sql noprint;
   select catx('=',nliteral(_name_),nliteral(cats("&prefix",_name_))) 
      into :renamelist separated by ' '
      from varnames;
   quit;
/*%put NOTE: &=renamelist;*/
proc datasets;
   modify combinedset;
   rename &renamelist;
   run;
%mend change;
%change(event1,E1_)
%change(event2,E2_)
%change(event3,E3_)
%change(event4,E4_)
%change(event5,E5_)

*************************Merge baseevent and event2-5******************;
data wide;
merge baseevent event2-event5;
by resrecid;
run;

/*In total 13971 participants have event*/

/*merge event and vaccination dataset*/

proc sql;
create table vac_covid_final as
select coalesce (x.resrecid,y.resrecid) as resrecID, coalesce (x.orgid,y.orgid) as orgid,y.dob as vac_dob, y.ethnicity as vac_ethnicity,*
from wide as x full join final_vac as y
on wide.resrecid = final_vac.resrecid;
quit;


/* JM EDIT - try to coalesce our covariates DOB GENDER RACE */
proc sql;
create table vac_covid_final as
select coalesce (x.resrecid,y.resrecid) as resrecID, coalesce (x.orgid,y.orgid) as orgid,coalesce (x.age,y.age) as age,
coalesce (x.gender,y.gender) as gender, coalesce (x.race,y.race) as race, y.ethnicity as vac_ethnicity,
* from wide as x full join final_vac as y
on wide.resrecid = final_vac.resrecid;
quit;

proc sql;
create table vac_covid_leftfinal as
select coalesce (x.resrecid,y.resrecid) as resrecID, coalesce (x.orgid,y.orgid) as orgid,coalesce (x.age,y.age) as age,
coalesce (x.gender,y.gender) as gender, coalesce (x.race,y.race) as race, y.ethnicity as vac_ethnicity,
* from wide as x left join final_vac as y
on wide.resrecid = final_vac.resrecid;
quit;

proc sql;
create table vac_covid_innerfinal as
select coalesce (x.resrecid,y.resrecid) as resrecID, coalesce (x.orgid,y.orgid) as orgid,coalesce (x.age,y.age) as age,
coalesce (x.gender,y.gender) as gender, coalesce (x.race,y.race) as race, y.ethnicity as vac_ethnicity,
* from wide as x inner join final_vac as y
on wide.resrecid = final_vac.resrecid;
quit;

/* END JM EDIT */


/*can insert Jason's covid day logic */


/*fits the survival criteria--test how many in total*/
data survival;
set vac_covid_final;
if (dose1date <= '15NOV2022:00:00:00.000'DT and Dose1Mfg in ("BIMODERNA","BIPFIZBION"))
or (dose2date <= '15NOV2022:00:00:00.000'DT and Dose2Mfg in ("BIMODERNA","BIPFIZBION"))
or (dose3date <= '15NOV2022:00:00:00.000'DT and Dose3doseMfg in ("BIMODERNA","BIPFIZBION")) 
or (dose4date <= '15NOV2022:00:00:00.000'DT and Dose4doseMfg in ("BIMODERNA","BIPFIZBION")) 
or (dose5date <= '15NOV2022:00:00:00.000'DT and Dose5doseMfg in ("BIMODERNA","BIPFIZBION")) 
or (dose6date <= '15NOV2022:00:00:00.000'DT and Dose6doseMfg in ("BIMODERNA","BIPFIZBION")) 
or (dose7date <= '15NOV2022:00:00:00.000'DT and Dose7doseMfg in ("BIMODERNA","BIPFIZBION"));
run;

/*seperate the dose in each dataset*/
data dose1 dose2 dose3 dose4 dose5 dose6 dose7;
set vac_covid_final;
if dose1date <= '23NOV2022:00:00:00.000'DT and Dose1Mfg in ("BIMODERNA","BIPFIZBION") then output dose1; 
if dose2date <= '23NOV2022:00:00:00.000'DT and Dose2Mfg in ("BIMODERNA","BIPFIZBION") then output dose2; 
if dose3date <= '23NOV2022:00:00:00.000'DT and Dose3doseMfg in ("BIMODERNA","BIPFIZBION") then output dose3;  
if dose4date <= '23NOV2022:00:00:00.000'DT and Dose4doseMfg in ("BIMODERNA","BIPFIZBION") then output dose4;  
if dose5date <= '23NOV2022:00:00:00.000'DT and Dose5doseMfg in ("BIMODERNA","BIPFIZBION") then output dose5;  
if dose6date <= '23NOV2022:00:00:00.000'DT and Dose6doseMfg in ("BIMODERNA","BIPFIZBION") then output dose6;  
if dose7date <= '23NOV2022:00:00:00.000'DT and Dose7doseMfg in ("BIMODERNA","BIPFIZBION") then output dose7;  
run;
/*merge together and change names to bivdate and bivmfg*/
proc sql; 
CREATE TABLE bivdose as
    SELECT bivdoseall.* 
    FROM (SELECT dose3.dose3date as bivdate, dose3.dose3dosemfg as bivmfg, * FROM dose3
          UNION ALL
          SELECT dose4.dose4date as bivdate, dose4.dose4dosemfg as bivmfg, * FROM dose4
          UNION ALL
          SELECT dose5.dose5date as bivdate, dose5.dose5dosemfg as bivmfg, * FROM dose5
		  UNION ALL
          SELECT dose6.dose6date as bivdate, dose6.dose6dosemfg as bivmfg, * FROM dose6
         ) bivdoseall;
quit;

/*Need Jason's help on deleting the duplicates of people getting two boosters*/

/*JM Edit*/
proc sort data = bivdose;
by resrecid;
run;

/*get the first row most recent record as the base*/
data biv_dup additional_2;
    set bivdose;
    by resrecid ;
    if first.resrecid then output biv_dup;
	else output additional_2;
run;
/*JM Edit*/


data bivdose_f;
set bivdose;

/*JM Edit*/
*delete duplicate bivalent boosters;
if resrecid in (271983, 1505573, 1536489, 1538193, 1581016, 1581627)
then delete ;

/*  6 total resrecids excluded */
/*JM Edit*/


format bivdate datetime7.
eventdate datetime7. E2_EVENTdate datetime7. E3_EVENTdate datetime7. E4_EVENTdate datetime7.;
run;

proc freq data=bivdose_f;
tables eventid E2_EVENTID E3_EVENTID E4_EVENTID;
run;

/*no event4*/
data test1 nonevent;
set bivdose_f;
if (datepart(bivdate) < datepart(eventdate) < datepart(bivdate) + 183) or 
(datepart(bivdate) < datepart(e2_eventdate) < datepart(bivdate) + 183) or
(datepart(bivdate) < datepart(e3_eventdate) < datepart(bivdate) + 183) or
(datepart(bivdate) < datepart(e4_eventdate) < datepart(bivdate) + 183) then output test1; 
else output nonevent;
run;


data event1 event2 event3 event4;
set bivdose_f;
if datepart(bivdate) < datepart(eventdate) < datepart(bivdate) + 183 then output event1; 
if datepart(bivdate) < datepart(e2_eventdate) < datepart(bivdate) + 183 then output event2; 
if datepart(bivdate) < datepart(e3_eventdate) < datepart(bivdate) + 183 then output event3; 
if datepart(bivdate) < datepart(e4_eventdate) < datepart(bivdate) + 183 then output event4; 
run;

/*merge together and change names to ceventdate*/
proc sql; 
CREATE TABLE breakthrough as
    SELECT bivcovall.* 
    FROM (SELECT event1.eventdate as ceventdate, * FROM event1
          UNION ALL
          SELECT event2.e2_eventdate as ceventdate, * FROM event2
          UNION ALL
          SELECT event3.e3_eventdate as ceventdate, * FROM event3
         ) bivcovall;
quit;

/*Need Jason's help on selecting the first event when people getting COVID more than 1 time*/


/*JM Edit*/
proc sort data = breakthrough;
by resrecid;
run;

/*get the first row most recent record as the base*/
data case_dup additional_3;
    set breakthrough;
    by resrecid ;
    if first.resrecid then output case_dup;
	else output additional_3;
run;

data breakthrough2;
set breakthrough;
*delete duplicate bivalent boosters;
if resrecid in (308024, 483720, 988604, 1315078, 1477477, 1539704, 1543831, 1549539)
then delete ;

/*  8 total resrecids deleted */
/*JM Edit*/


/*458 participants have breakthrough 2498 no breakthrough vaccinated participants*/

data survival_bt;
set breakthrough2;
format ceventdate datetime7.;
days= datepart(ceventdate) -datepart(bivdate); 
status=1;
biv=1;
run;

data nonevent_nbt;
set nonevent;
status=0;
biv=1;
days=183;
run;

/*merge all bivalent vaccinated participants*/

data survival_bivax;
set survival_bt nonevent_nbt;
run;


/*JM Edit*/

data survival_bivax2;
set survival_bivax;
*Censoring/excluding those who didn't have case of COVID infection, but were discharged before study period 
ends - they COULD HAVE gotten COVID or not - we don't know. 
*Case 1: Those who didn't get covid, were dicharged once, and not admitted a second time within period;
*Case 2: Those who didn't get covid and were discharged twice within period (no one was readmitted a third time);
if status = 0 and resdischdate1 ne . and datepart(bivdate) < datepart(resdischdate1) < datepart(bivdate) + 183 and 
resadmitdate2 = . 
then days = datepart(resdischdate1) - datepart(bivdate) ;
else if status = 0 and resdischdate2 ne . and datepart(bivdate) < datepart(resdischdate2) < datepart(bivdate) + 183 
then days = datepart(resdischdate2) - datepart(bivdate);
run;

data surv_TEST_JM;
set survival_bivax;
*flagging and checking the censoring changes;
if (status = 0 and resdischdate1 ne . and datepart(bivdate) < datepart(resdischdate1) < datepart(bivdate) + 183 and 
resadmitdate2 = . ) 
or (status = 0 and resdischdate2 ne . and datepart(bivdate) < datepart(resdischdate2) < datepart(bivdate) + 183)
then flag = 1 ;
else flag = 0 ;
run;

*sum flags / changes from censoring admit/discharge date ;
proc sql;
create table flag1 as
    select flag,
        sum(flag) as flag_sum
    from surv_TEST_JM;
quit;

*Check to see average change in survival time;
proc means data = survival_bivax2 ;
var days ; 
run;

proc means data = survival_bivax ;
var days ; 
run;

/*JM Edit*/





**************************************************************************************;
/*create an easy control group among not vaccinated*/
/*only return rows from first dataset that are not in second dataset*/
proc sql;
create table novaxdataid as 
select resrecid from wide
except 
select resrecid from final_vac;
quit;

data novaxdata;
merge vac_covid_leftfinal  novaxdataid (in=in2);
by resrecid;
if in2;
run;

data test novnonevent;
set novaxdata;
if  (('15Nov2022:00:00:00.000'DT <= eventdate<= '15May2023:00:00:00.000'DT)  or  
('15Nov2022:00:00:00.000'DT <= e2_eventdate<= '15May2023:00:00:00.000'DT) or
('15Nov2022:00:00:00.000'DT <= e3_eventdate<= '15May2023:00:00:00.000'DT) or
('15Nov2022:00:00:00.000'DT <= e4_eventdate<= '15May2023:00:00:00.000'DT)) then output test;
else output novnonevent;
run;

data novevent1 novevent2 novevent3 novevent4;
set novaxdata;
if  '15Nov2022:00:00:00.000'DT <= eventdate<= '15May2023:00:00:00.000'DT  then output novevent1; 
if  '15Nov2022:00:00:00.000'DT <= e2_eventdate<= '15May2023:00:00:00.000'DT then output novevent2; 
if  '15Nov2022:00:00:00.000'DT <= e3_eventdate<= '15May2023:00:00:00.000'DT then output novevent3; 
if  '15Nov2022:00:00:00.000'DT <= e4_eventdate<= '15May2023:00:00:00.000'DT then output novevent4; 
run;

proc sql; 
CREATE TABLE novdataevent as
    SELECT bivcovall.* 
    FROM (SELECT novevent1.eventdate as novceventdate, * FROM novevent1
          UNION ALL
          SELECT novevent2.e2_eventdate as novceventdate, * FROM novevent2
          UNION ALL
          SELECT novevent3.e3_eventdate as novceventdate, * FROM novevent3
         ) bivcovall;
quit;

/*Need Jason's help on selecting the first event when people getting COVID more than 1 time*/

/*JM Edit*/
proc sort data = novdataevent;
by resrecid;
run;

/*get the first row most recent record as the base*/
data novdataevent2 additional_4;
    set novdataevent;
    by resrecid ;
    if first.resrecid then output novdataevent2;
	else output additional_4;
run;

/* excluding 40 observations*/
/*JM Edit*/



data _null_;
   SASDate='15Nov22'D;
   n=input(put(SASDate, datetime7.), 8.);
   put n=;
run;

data survival_novevnt;
set novdataevent;
format novceventdate datetime7.;
days= datepart(novceventdate)-22964; 
status=1;
biv=0;
run;

data novnonevent_ncov;
set novnonevent;
status=0;
days=183;
biv=0;
run;

data novaxdata_st;
set  survival_novevnt novnonevent_ncov;
run;


/*JM Edit*/

data novaxdata_st2;
set novaxdata_st;
*Censoring/excluding those who didn't have case of COVID infection, but were discharged before study period 
ends - they COULD HAVE gotten COVID or not - we don't know. 
*Case 1: Those who didn't get covid, were dicharged once, and not admitted a second time;
*Case 2: Those who didn't get covid and were discharged twice (no one was readmitted a third time);
if status = 0 and resdischdate1 ne . and resadmitdate2 = . 
then days = datepart(resdischdate1) - datepart('15Nov2022:00:00:00.000'DT) ;
else if status = 0 and resdischdate2 ne . 
then days = datepart(resdischdate2) - datepart('15Nov2022:00:00:00.000'DT);
run;

data novax_TEST_JM;
set novaxdata_st;
*flagging and checking the censoring changes;
if (status = 0 and resdischdate1 ne . and resadmitdate2 = . ) 
or (status = 0 and resdischdate2 ne . )
then flag = 1 ;
else flag = 0 ;
run;

*sum flags / changes from censoring admit/discharge date ;
proc sql;
create table flag2 as
    select flag,
        sum(flag) as flag_sum
    from novax_TEST_JM;
quit;

*Check to see average change in survival time;
proc means data = novaxdata_st2 ;
var days ; 
run;

proc means data = novaxdata_st ;
var days ; 
run;

/*JM Edit*/



*Combining biv and novax group datasets;

data combined;
set survival_bivax2 novaxdata_st2;
run;

proc lifetest data=combined  plots=survival(cb) plots=hazard(bw=100);;
strata biv ;
time days*status(0);
run; 

proc phreg data = combined  ;
class biv ;
model days*status(0) = biv  ;
run;

/*get the final observations to fill the crosstab*/
proc freq data=combined;
tables biv*status;
run;

proc univariate data = combined(where=(status=1));
class biv;
var days;
histogram days / kernel;
run;

proc univariate data = combined(where=(status=1));
class biv;
var days;
cdfplot days;
run;

var lenfol;
cdfplot lenfol;
run;

proc univariate data = combined(where=(status=1));
var days;
histogram days / kernel;
run;



/*Edit - JM */

**************************

Propensity Score Analysis

**************************;

*Excluding ages > 40 and recoding race;
data combined2;
set combined;
if age < 40 then delete;

if race = "White, only" then race = "white" ;
else if race = "Black, only" then race = "black" ;
else if race = "Unknown, only" then race = "unknown";
else race = "other" ;

run;


*Exclude those who revieve bivalent booster after November;
data dose1 dose2 dose3 dose4 dose5 dose6 dose7;
set COMBINED2;
if '23MAY2023:00:00:00.000'DT >= dose1date > '23NOV2022:00:00:00.000'DT and Dose1Mfg in ("BIMODERNA","BIPFIZBION") then output dose1; 
if '23MAY2023:00:00:00.000'DT >= dose2date > '23NOV2022:00:00:00.000'DT and Dose2Mfg in ("BIMODERNA","BIPFIZBION") then output dose2; 
if '23MAY2023:00:00:00.000'DT >=  dose3date > '23NOV2022:00:00:00.000'DT and Dose3doseMfg in ("BIMODERNA","BIPFIZBION") then output dose3;  
if '23MAY2023:00:00:00.000'DT >=  dose4date > '23NOV2022:00:00:00.000'DT and Dose4doseMfg in ("BIMODERNA","BIPFIZBION") then output dose4;  
if '23MAY2023:00:00:00.000'DT >= dose5date > '23NOV2022:00:00:00.000'DT and Dose5doseMfg in ("BIMODERNA","BIPFIZBION") then output dose5;  
if '23MAY2023:00:00:00.000'DT >= dose6date > '23NOV2022:00:00:00.000'DT and Dose6doseMfg in ("BIMODERNA","BIPFIZBION") then output dose6;  
if '23MAY2023:00:00:00.000'DT >= dose7date > '23NOV2022:00:00:00.000'DT and Dose7doseMfg in ("BIMODERNA","BIPFIZBION") then output dose7;  
run;


proc sql; 
CREATE TABLE bivdose1 as
    SELECT bivdoseall.* 
    FROM (SELECT dose3.dose3date as bivdate1, dose3.dose3dosemfg as bivmfg1, * FROM dose3
          UNION ALL
          SELECT dose4.dose4date as bivdate1, dose4.dose4dosemfg as bivmfg1, * FROM dose4
          UNION ALL
          SELECT dose5.dose5date as bivdate1, dose5.dose5dosemfg as bivmfg1, * FROM dose5
      UNION ALL
          SELECT dose6.dose6date as bivdate1, dose6.dose6dosemfg as bivmfg1, * FROM dose6
         ) bivdoseall;
quit;

data bivdose_t;
set bivdose1;
format bivdate1 datetime7.
eventdate datetime7. E2_EVENTdate datetime7. E3_EVENTdate datetime7. E4_EVENTdate datetime7.;
run;

proc sql;
create table combined_final as
select *from combined2
where combined2.resrecID not in (select resrecID from bivdose_t);
quit;




/* Before PS */

*Survival Curves;
proc lifetest data=combined_final  plots=survival(cb) plots=hazard(bw=100);;
strata biv ;
time days*status(0);
run; 

*Crude Hazard;
proc phreg data = combined_final  ;
class biv ;
model days*status(0) = biv ;
run;

*Adjusted Hazard; 
proc phreg data = combined_final  ;
class biv gender race ;
model days*status(0) = biv age gender race ;
run;

*Adjusted Hazard (race);
/*Hazard is much higher for black individuals compared to white */ 
proc phreg data = combined_final  ;
class biv gender race ;
model days*status(0) = biv age gender  ;
where race = "white";
run;

proc phreg data = combined_final  ;
class biv gender race ;
model days*status(0) = biv age gender  ;
where race = "black" ;
run;


/*Exporting to excel file to compute IPTW in R 

proc export data=combinedfinal
    outfile="\\cdc.gov\project\CCID_NCPDCID_NHSN_SAS\Data\work\_Projects\LTC\COVID-19\Codes\Jason\Mary_Projects\SVH_survival\propensity.csv"
    dbms=csv
    replace;
run;

*/




