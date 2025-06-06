  
 /*****************************************************************************
        Source file name:       7_st_hunger_vitals_pf
        Object name:            7_st_hunger_vitals_pf
 
      	Application Analyst:	Kim Frazier
 
		NOTES: 					Smart Template to show last 2 Hunger Vital Signs PF data
______________________________________________________________________________________________ 
****************************************************************************************************
                                  MODIFICATION CONTROL LOG
****************************************************************************************************
Mod    Date             Analyst                 MCGA          	Comment
---    ----------       --------------------    ------        	------------------------------------
000    8/28/2024 (live)	Kim Frazizer       		SCTASK0098925	Initial Release 
modifications from Virgie 7/26/2024
The lookback should be the last 2 instances of documentation from any/all encounters.
The message should be "No Screen Found" if no results are found.
001    06/04/2025       Michael Mayes           352510          Removing role... and copying Simeons changes... I'm finalizing this 
                                                                for him.
****************************************************************************************************/
drop program   7_st_hunger_vitals_pf go
create program 7_st_hunger_vitals_pf

prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to. 

with OUTDEV

RECORD reply (
   1 text = vc
   1 status_data
     2 status = c1
     2 subeventstatus [1 ]
       3 operationname = c25
       3 operationstatus = c1
       3 targetobjectname = c25
       3 targetobjectvalue = vc
)
declare rhead = vc with protect, constant(concat("{\rtf1\ansi \deff0",
                                                 "{\fonttbl",
                                                 "{\f0\fmodern\Courier New;}{\f1 Arial;}}",
                                                 "{\colortbl;",
                                                 "\red0\green0\blue0;",
                                                 "\red255\green255\blue255;",
                                                 "\red0\green0\blue255;",
                                                 "\red0\green255\blue0;",
                                                 "\red255\green0\blue0;}\deftab2520 "))
/*The end of line embedded RTF command */
set Reol = "\par "
/*The tab embedded RTF command */
set Reop = "\pard "
set Rtab = "\tab "
/*The end/beginning of paragraph RTF command and sets tabs*/
set Rbopt = "\pard \tx1200\tx1900\tx2650\tx3325\tx3800\tx4400\tx5050\tx5750\tx6500 "
/*the embedded RTF commands for normal word(s) */
set wr = "\plain \f0 \fs18 \cb2 "
/*the embedded RTF commands for normal,courier word(s) */
set wrc = "\plain \f1 \fs18 \cb2 "
/*the embedded RTF commands for bold word(s) */
set wb = "\plain \f0 \fs18 \b \cb2 "
/*the embedded RTF command for bold & underlining*/
set wu = "\plain \f0 \fs18 \ul \b \cb2 "
/*the embedded RTF commands for Italicized Bold words */
set wbi = "\plain \f0 \fs18 \b \i \cb2 "
/*the embedded RTF commands for stike-thru word(s) */
set ws = "\plain \f0 \fs18 \strike \cb2"
/*the embedded RTF command for hanging indent */
set hi = "\pard\fi-2340\li2340 "
/* the embedded rtf commands to set text to bold red */
set wred = "  \cf5 "
set wblack = "  \cf1 "
/*the embedded RTF commands to end the document*/
set rtfeof = "}"

declare pid = f8 with public,protect
if (validate( request->person[1]->person_id))
	set pid = request->person[1]->person_id
else
	set pid =    38434857.00
endif

declare this_date = c16 with public,protect
declare this_prsnl_name = vc with public,protect ;who verified form
declare this_role = vc with public,protect

record data(
1 form[*]
	2 this_date = vc
	2 this_prsnl_name = vc
	2 this_role = vc
	2 qual[*]
		3 event = vc
		3 result = vc
)



select into "NL:"
from
clinical_event ce
, clinical_event cechild
,clinical_event cebabies

, prsnl p
, dummyt d
, encntr_prsnl_reltn epr
plan ce
where ce.person_id = pid
and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime)
and ce.result_status_cd in (25,34,35)
and   ce.event_tag != "In Error"
and ce.event_title_text not = "Date\Time Correction"
;any form 
;and ce.event_title_text = "Hunger Vital Signs"
;and ce.event_end_dt_tm >= cnvtlookbehind("90,D");within 90 days
join cechild
where ce.event_id = cechild.parent_event_id
join cebabies
where cebabies.parent_event_id = cechild.event_id
and cebabies.valid_until_dt_tm > cnvtdatetime(curdate,curtime)
and cebabies.result_status_cd in (25,34,35)
and cebabies.event_cd in ( 2874236761.00,
 2874253861.00,
 2915558719.00 
)
join p
where p.person_id = ce.verified_prsnl_id
join d
join epr
where epr.encntr_id = ce.encntr_id
and epr.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
and epr.active_ind = 1

order by ce.event_end_dt_tm desc ;most recent form
, cebabies.event_cd ;for each dta
, epr.beg_effective_dt_tm desc ;most recent relation
head report
cnt = 0
fcnt = 0
head ce.event_end_dt_tm
cnt = 0
fcnt += 1
stat = alterlist(data->form,fcnt)
data->form[fcnt].this_date = format(ce.event_end_dt_tm,"mm/dd/yyyy hh:mm;;d")
;this_person= ce.verified_prsnl_id
data->form[fcnt].this_prsnl_name = trim(p.name_full_formatted)
data->form[fcnt].this_role = trim(uar_get_code_display(epr.encntr_prsnl_r_cd))
this_parent = cechild.event_id

head cebabies.event_cd
if(cebabies.parent_event_id = this_parent)

cnt += 1
stat = alterlist(data->form[fcnt].qual[cnt],cnt)
 data->form[fcnt].qual[cnt].event = trim(uar_get_code_display(cebabies.event_cd))
 data->form[fcnt].qual[cnt].result = trim(cebabies.result_val)

endif 
detail
NULL
with nocounter, outerjoin(d)


call echorecord(data)


; output
declare fm = i2 with public,protect
declare maxsize = i2 with public,protect
set maxsize = size(data->form,5)
if(maxsize > 2)
	set maxsize = 2
endif
call echo("maxsize")
call echo(maxsize)
SET reply->text = concat (rhead )
if(size(data->form,5) > 0)
	for (fm = 1 to maxsize)
		;001--> Replacing this with the removal and some code beautification.
		;set reply->text = build2(notrim( reply->text),wr,"Form Created: ",data->form[fm].this_date,reol, " Verified by: ", data->form[fm].this_prsnl_name,reol,wr," Role: ", data->form[fm].this_role)
		;
		;for(x = 1 to size(data->form[fm].qual,5))
		;set reply->text = build2(trim( reply->text),reol,wb, trim(data->form[fm].qual[x].event), ": ",wr,trim(data->form[fm].qual[x].result))
		;
		;endfor
		;set reply->text = build2(trim( reply->text),reol, reol)
        
        set reply->text = build2( notrim(reply->text)
                                , wr, "Form Created: ", data->form[fm].this_date      , reol
                                ,     " Verified by: ", data->form[fm].this_prsnl_name, reol
                                )
		
		for(x = 1 to size(data->form[fm].qual,5))
            set reply->text = build2( trim(reply->text), reol
                                    , wb, trim(data->form[fm].qual[x].event), ": ", wr, trim(data->form[fm].qual[x].result)
                                    )
		
		endfor
        
		set reply->text = build2(trim(reply->text),reol, reol)
        ;001<--
	endfor	
else
	set reply->text = build2(trim( reply->text),"No Screen found")
endif

set reply->status_data->status = "S"
SET reply->text = concat (reply->text,rtfeof )
 
CALL echo (reply->text )


end go