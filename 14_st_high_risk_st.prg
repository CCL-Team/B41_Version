/*************************************************************************
 Program Title: High Risk Problems ST

 Object name:   14_st_high_risk_st
 Source file:   14_st_high_risk_st.prg

 Purpose:       Using a McAlduff script, identify high risk problems
                the patient has, and then display in a table like
                view.
                
 Tables read:

 Executed from: 

 Special Notes: This request was paired with a component that will
                do the same sort of logic.  Coming into this, I don't
                think the two will be related at all, but if you need it
                the component I think I'm going to drop in something called
                HighRiskComp in the static content directory.

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA     Comment
--- ---------- -------------------- -------- -----------------------------
001 12/03/2024 Michael Mayes        349669   Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_high_risk_st:dba go
create program 14_st_high_risk_st:dba

%i cust_script:0_rtf_template_format.inc

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/


free record data
record data(
    1 cnt = i4
    1 qual[*]
        2 problem_id  = i4
        2 problem_txt = vc
)


record reply(
   1 text = vc
      1 status_data
         2 status = c1
         2 subeventstatus[1]
            3 OperationName = c25
            3 OperationStatus = c1
            3 TargetObjectName = c25
            3 TargetObjectValue = vc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header               = vc  with protect, noconstant(' ')
declare tmp_str              = vc  with protect, noconstant(' ')

declare _MEMORY_REPLY_STRING = vc  with protect, noconstant('')

declare looper               = i4  with protect, noconstant(0)


/**************************************************************
; DVDev Start Coding
**************************************************************/

call echo(cnvtstring(p_id, 17, 2))

; We are just going to attempt to call the McAlduff script and see if we can get that RS from him.
; Going for the json... mainly because I don't want to redefine his RS in case it changes.
execute jdm13_mp_high_risk_dx_jx 'MINE', cnvtstring(p_id, 17, 2), 0   

call echo(_MEMORY_REPLY_STRING)

;Looks like that works... now let's see if we can get a RS out of it.
set stat = cnvtjsontorec(_MEMORY_REPLY_STRING)

; We did it friends.
call echorecord(rec)

/*  This RS should look like this at time of writing:
        FREE RECORD REC
        RECORD REC(
            1 PERSON_ID = f8
            1 PATIENT = vc
            1 RCNT = i4
            1 RLIST [*]
                2 SNOMED_CD = vc
                2 SNOMED = vc
                2 ANNOTATED_DISPLAY = vc
                2 PERSISTENCE = vc
        )
*/

;Presentation Time

;RTF header
set header = notrim(build2(rhead))

;We don't want a header.
;set tmp_str = notrim(build2(wbu, 'High Risk Problem List', wr, reol))

if(rec->rcnt = 0) set tmp_str = notrim(build2('No high risk problems found.', reol))
else
    
    for(looper = 1 to rec->rcnt)
        if(tmp_str = '')  set tmp_str = notrim(build2(rec->rlist[looper]->annotated_display, reol))
        else              set tmp_str = notrim(build2(tmp_str, rec->rlist[looper]->annotated_display, reol))
        endif
    endfor
    
endif

call include_line(build2(header, tmp_str, RTFEOF))


;build reply text
for (cnt = 1 to drec->line_count)
    set  reply -> text  =  concat ( reply -> text, drec -> line_qual [ cnt ]-> disp_line )
endfor


set drec->status_data->status  = "S"
set reply->status_data->status = "S"


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/



call echorecord(reply)
call echorecord(drec)

call echorecord(data)

call echo(reply->text)

end
go

