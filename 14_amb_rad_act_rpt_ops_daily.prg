/*****************************************************************************
 
        Author                      GR Gordon-Ross
        Request Received        November, 2018
        Source file name:           14_amb_rad_activity_rpt_ops.prg
        Object name:                14_amb_rad_activity_rpt_ops_daily
 
        CCL Version:                8.4.1 or higher
 
        Program purpose:        Executes the radiology report on a daily basis and emails the results
                                    to varius email addresses.
 
        Tables read:
 
        Tables updated:             None
        Executing from:             Ops
 
        Prompts:                None
 
******************************************************************************/
 
 
/*****************************************************************************
                      GENERATED MODIFICATION CONTROL LOG                     *
******************************************************************************

Mod Date     Engineer    		Comment
--- -------- ------------		--------------------------
000 11/15/18 RHG106   			Initial Release
001 05/13/21 MMM174     		Adding email (222920)
002 08/19/22 Brian Twardy		MCGA: N/A
								SOM RITM/Task; RITM3052605 / TASK5592774
								Requester: Crystal Pugh - Manager Informatics - MedStar Medical Group Informatics
								CCL script:14_amb_rad_act_rpt_ops_daily.prg     (no name change)
								Added Tyrone.M.Beazer@medstar.net to each of the address lists below.
								NOTE: Another "ask" came from Stephanie McLain - Director of Operations -
									  MedStar Health at Hunt Valley.
									  - Removed Linda Hawes and Silvana Dill
									  - Added Mary Figueroa, Cherries Jobe, Tamika Staton, and Meghan Jack
003 01/09/24 MMM174             Changing emails, SCTASK0067611, request came from an email
004 06/21/24 MMM174             Changing emails, SCTASK0103541, Removing Tim Beckman and Joseph Ugast.
******************************************************************************/
drop program 14_amb_rad_act_rpt_ops_daily:dba go
create program 14_amb_rad_act_rpt_ops_daily:dba
 
declare beg_dt      = dq8 with constant(cnvtlookbehind("1, D")), protect
declare end_dt      = dq8 with constant(cnvtdatetime(curdate, curtime3)), protect
;declare beg_dt         = dq8 with constant(cnvtlookbehind("2, D")), protect
;declare end_dt         = dq8 with constant(cnvtlookbehind("2, D")), protect
declare start_dt_tm     = vc with constant(format(beg_dt, "DD-MMM-YYYY;;D")), protect
declare end_dt_tm       = vc with constant(format(end_dt, "DD-MMM-YYYY;;D")), protect
declare line            = vc
 
 
declare output_file = vc with constant(concat(
                      "/cerner/d_p41/cust_output_2/rad_extract/"
                      ,"radiologyordersfiledaily_"
                      ,format(end_dt, "YYYYMMDDhhmmss;;q")
                      ,".csv"))
 
declare output_file2 = vc with constant(concat(
                      "radiologyordersfiledaily_"
                      ,format(end_dt, "YYYYMMDDhhmmss;;q")
                      ,".csv"))
 
declare output_file_sum = vc with constant(concat(
                      "/cerner/d_p41/cust_output_2/rad_extract/"
                      ,"radiologyorderssumdaily_"
                      ,format(end_dt, "YYYYMMDDhhmmss;;q")
                      ,".csv"))
 
declare output_file2_sum = vc with constant(concat(
                      "radiologyorderssumdaily_"
                      ,format(end_dt, "YYYYMMDDhhmmss;;q")
                      ,".csv"))
 
 
    call echo(start_dt_tm)
    call echo(end_dt_tm)
    call echo(output_file)
 
 
free record fac_codes
record fac_codes (
  1 drec[*]
    2 codes     = f8
)
 
select into "nl:"
from code_value cv1
plan cv1 where cv1.code_set = 220
  and cv1.cdf_meaning = "FACILITY"
  and
    (cv1.display_key in("*LAFAYETTE*","*BRANDYWINE*","*BELAIR*")
      or
    cv1.display_key in("*TIMONIUM*","*CHEVYCHASE*"))
head report
  cnt = 0
detail
  cnt = cnt + 1
  if(size(fac_codes->drec,5) < cnt)
    stat = alterlist(fac_codes->drec,cnt+99)
  endif
  fac_codes->drec[cnt].codes = cv1.code_value
with nocounter
 
free record temp_orders
record temp_orders
(
    1 qual[*]
      2 mnemonic        = vc  ;
      2 ord_phys        = vc  ;
      2 perf_loc            = vc  ;
      2 facility            = vc  ;
)
 
free record drec
record drec
(
  1 fac[*]
    2 facility          = vc
    2 cnt               = i4
    2 phy[*]
      3 physician       = vc
      3 cnt             = i4
      3 loc[*]
        4 loc               = vc
        4 cnt           = i4
        4 exams         = vc
)
 
execute 14_amb_rad_act_orders_rpt2:dba value(output_file), VALUE(START_DT_TM), VALUE(END_DT_TM), "daily", "*"
 
select into "nl:"
  mne = trim(substring(1,250,temp_orders->qual[d.seq].mnemonic)),
  phys = trim(substring(1,250,temp_orders->qual[d.seq].ord_phys)),
  loc = trim(substring(1,250,temp_orders->qual[d.seq].perf_loc)),
  fac = trim(substring(1,250,temp_orders->qual[d.seq].facility))
from
  (dummyt d with seq = value(size(temp_orders->qual,5)))
plan d
order by fac, phys, loc, mne
head report
  fcnt = 0
head fac
  fcnt = fcnt + 1
  if(size(drec->fac,5) < fcnt)
    stat = alterlist(drec->fac, fcnt + 99)
  endif
  drec->fac[fcnt].facility = fac
  drec->fac[fcnt].cnt = 0
  pcnt = 0
head phys
  pcnt = pcnt + 1
  if(size(drec->fac[fcnt].phy,5) < pcnt)
    stat = alterlist(drec->fac[fcnt].phy, pcnt + 99)
  endif
  drec->fac[fcnt].phy[pcnt].physician = phys
  drec->fac[fcnt].phy[pcnt].cnt = 0
  lcnt = 0
head loc
  lcnt = lcnt + 1
  if(size(drec->fac[fcnt].phy[pcnt].loc,5) < lcnt)
    stat = alterlist(drec->fac[fcnt].phy[pcnt].loc, lcnt + 99)
  endif
  drec->fac[fcnt].phy[pcnt].loc[lcnt].loc = loc
  drec->fac[fcnt].phy[pcnt].loc[lcnt].cnt = 0
  mcnt = 0
detail
  mcnt = mcnt + 1
  drec->fac[fcnt].cnt = drec->fac[fcnt].cnt + 1
  drec->fac[fcnt].phy[pcnt].cnt = drec->fac[fcnt].phy[pcnt].cnt + 1
  drec->fac[fcnt].phy[pcnt].loc[lcnt].cnt = drec->fac[fcnt].phy[pcnt].loc[lcnt].cnt + 1
foot phys
  stat = alterlist(drec->fac[fcnt].phy[pcnt].loc, lcnt)
foot fac
  stat = alterlist(drec->fac[fcnt].phy, pcnt)
foot report
  stat = alterlist(drec->fac, fcnt)
with nocounter
 
call echorecord(drec)
 
select into value(output_file_sum)
from
  (dummyt d1 with seq = value(size(drec->fac, 5))),
  (dummyt d2 with seq = 1),
  (dummyt d3 with seq = 1)
plan d1 where maxrec(d2,size(drec->fac[d1.seq].phy,5))
join d2 where maxrec(d3,size(drec->fac[d1.seq].phy[d2.seq].loc,5))
join d3
head report
  line = build2(^"Clinic",^,
                ^"Ordering Physician",^,
                ^"Location",^,
                ^"Count",^)
  col 0 line, row + 1
head d1.seq
  line = build2(^"^,trim(drec->fac[d1.seq].facility),^",^,
                ^"",^,
                ^"",^,
                ^"^,trim(cnvtstring(drec->fac[d1.seq].cnt)),^"^)
  col 0 line, row + 1
head d2.seq
  line = build2(^"",^,
                ^"^,trim(drec->fac[d1.seq].phy[d2.seq].physician),^",^,
                ^"",^,
                ^"^,trim(cnvtstring(drec->fac[d1.seq].phy[d2.seq].cnt)),^"^)
  col 0 line, row + 1
head d3.seq
  line = build2(^"",^,
                ^"",^,
                ^"^,trim(drec->fac[d1.seq].phy[d2.seq].loc[d3.seq].loc),^",^,
                ^"^,trim(cnvtstring(drec->fac[d1.seq].phy[d2.seq].loc[d3.seq].cnt)),^"^)
  col 0 line, row + 1
with
  nocounter,
  nullreport,
  format = variable,
  maxrow = 1,
  maxcol = 8000
 
 
declare email_subject   = vc with constant(concat("Daily Radiology Orders File"))
declare email_subject2  = vc with constant(concat("Daily Radiology Orders File - Summary"))
declare email_address   = vc with constant(concat("andrew.r.canning@medstar.net,mforthman@medstarradiologynetwork.com,"
                                                 ,"bridget.hillman@medstar.net,"
                                                 ,"SWinfield@medstarradiologynetwork.com"))
declare email_address2  = vc with constant(concat("KXBU@gunet.georgetown.edu,stephanie.a.mclain@medstar.net,"
                                                 ,"isaac.d.aziramubera@medstar.net,saumil.s.modi@medstar.net,"
                                                 ,"alexis.b.sriram@medstar.net","meghan.m.jack@medstar.net"))
; 002 08/19/2022 Removed linda.j.hawes@medstar.net
;declare email_address3  = vc with constant(concat("linda.j.hawes@medstar.net,terrell.v.harris@gunet.georgetown.edu,"
declare email_address3  = vc with constant(concat("terrell.v.harris@gunet.georgetown.edu,"
                                                 ,"kevin.p.white@medstar.net"))
; 002 08/19/2022 Removed silvana.a.dill@medstar.net
;declare email_address4  = vc with constant(concat("silvana.a.dill@medstar.net,timothy.r.beckman@medstar.net,"
;004... these are both going away... 
;declare email_address4  = vc with constant(concat("timothy.r.beckman@medstar.net,"							
;                                                 ,"jpu1@gunet.georgetown.edu"))

;003-> Removing and readding with changes
;declare email_address5  = vc with constant(concat("karol.edwards@medstar.net,heather.kratz@medstar.net,"
;                                                 ,"Tyrone.M.Beazer@medstar.net"))							; 002 08/19/2022 T.M.Beazer added
declare email_address5  = vc with constant(concat("Jason.Evans@medstar.net,"
                                                 ,"Tyrone.M.Beazer@medstar.net"))							; 002 08/19/2022 T.M.Beazer added
;003<-


; 002 08/19/2022 email_address6 is totally new. These are 4 new addresses
declare email_address6  = vc with constant(concat("Mary.R.Figueroa@Medstar.net,Cherries.Jobe@Medstar.net,"
                                                 ,"Tamika.C.Staton@medstar.net,Meghan.M.Jack@medstar.net"))	
                                                 
;declare email_address  = vc 
;							 with constant("andrew.r.canning@medstar.net,mforthman@medstarradiologynetwork.com,bridget.hillman@medstar.net")
;declare email_address  = vc with constant("ronald.h.gordan-ross@medstar.net")
declare email_body      = vc with noconstant(" ")
 
/*Create a file for the email_body and them populate it with formatted text*/
set email_body = concat("radiology_orders_file_daily_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                              ".dat")
 
set email_body2 = concat("radiology_orders_file_daily_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                              ".dat")
 
select into (value(email_body))
  build2("Run date and time: ",
  format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
  "Daily Radiology Orders File report for the following date: ", char(13), char(10),
  start_dt_tm, char(13), char(10), char(13), char(10),
  "File ", trim(output_file2), " is attached.", char(13), char(10), char(13), char(10),
  "Report is generated out of MedConnect via Ops - mhgrdcapp2_RadNet: 06:30 Daily MAS Rad Activity Report")
from dummyt
with format, noheading
 
select into (value(email_body2))
  build2("Run date and time: ",
  format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
  "Daily Radiology Orders File (Summary)report for the following date: ", char(13), char(10),
  start_dt_tm, char(13), char(10), char(13), char(10),
  "File ", trim(output_file2_sum), " is attached.", char(13), char(10), char(13), char(10),
  "Report is generated out of MedConnect via Ops - mhgrdcapp2_RadNet: 06:30 Daily MAS Rad Activity Report")
from dummyt
with format, noheading
/*************************************************************************************************/
 
execute 14_medstar_email email_body, email_subject, email_address, output_file
execute 14_medstar_email email_body2, email_subject2, email_address, output_file_sum
 
execute 14_medstar_email email_body, email_subject, email_address2, output_file
execute 14_medstar_email email_body2, email_subject2, email_address2, output_file_sum
 
execute 14_medstar_email email_body, email_subject, email_address3, output_file
execute 14_medstar_email email_body2, email_subject2, email_address3, output_file_sum

;004 no more in here.
;execute 14_medstar_email email_body, email_subject, email_address4, output_file
;execute 14_medstar_email email_body2, email_subject2, email_address4, output_file_sum
 
execute 14_medstar_email email_body, email_subject, email_address5, output_file
execute 14_medstar_email email_body2, email_subject2, email_address5, output_file_sum
 
execute 14_medstar_email email_body, email_subject, email_address6, output_file			; 002 08/19/2022 New Execute for new addresses
execute 14_medstar_email email_body2, email_subject2, email_address6, output_file_sum	; 002 08/19/2022 New Execute for new addresses
 
declare dclcom       = vc with noconstant(" ")
declare dcllen          = i4 with noconstant(0)
declare dclstatus       = i4 with noconstant(0)
 
set dclcom = build2("rm ", output_file)
set dcllen = size(trim(dclcom))
call dcl(dclcom, dcllen, dclstatus)
 
set dclcom = build2("rm ", email_body)
set dcllen = size(trim(dclcom))
call dcl(dclcom, dcllen, dclstatus)
 
set dclcom = build2("rm ", output_file_sum)
set dcllen = size(trim(dclcom))
call dcl(dclcom, dcllen, dclstatus)
 
set dclcom = build2("rm ", email_body2)
set dcllen = size(trim(dclcom))
call dcl(dclcom, dcllen, dclstatus)
 
 
end
go
 
 