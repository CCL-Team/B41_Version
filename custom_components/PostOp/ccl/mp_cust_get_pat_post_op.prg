/**************************************************************************
 Program Title:   mp_cust_get_pat_post_op
 
 Object name:     mp_cust_get_pat_post_op
 Source file:     mp_cust_get_pat_post_op.prg
 
 Purpose:         Examines past surg procedures and displays days since 
                  Surgery as well as the procedure name in a component. 
 
 Tables read:     surgical_case      
                  surg_case_procedure
                  procedure
                  encounter
                  nomenclature
                  
 Executed from:   MPage
 
 Special Notes:   
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 08/21/2019 Michael Mayes        216094    Initial release
002 01/29/2020 Michael Mayes        216094    Modifications from prod validations
003 11/05/2020 Michael Mayes        221849    Modification to show year and date
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop   program mp_cust_get_pat_post_op:dba go
create program mp_cust_get_pat_post_op:dba

prompt
    "Output to File/Printer/MINE:" = 'MINE',
    "Person Id:"                   = 0.0
with OUTDEV, per_id



/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record post_op_info
record post_op_info(
    1 cnt = i4
    1 qual[*]
        2 surg_case_id = f8
        2 proc_id      = f8
        2 proc_name    = vc
        2 proc_date    = vc
        2 proc_dt_tm   = vc
        2 post_op_days = vc
)

free record unsort_post_op_info
record unsort_post_op_info(
    1 cnt = i4
    1 qual[*]
        2 sort_date    = dq8
        2 surg_case_id = f8
        2 proc_id      = f8
        2 proc_name    = vc
        2 proc_date    = vc
        2 proc_dt_tm   = vc
        2 post_op_days = vc
)

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare pos           = i4  with protect, noconstant(0)
declare temp_days     = i4  with protect, noconstant(0)

declare powerchart_cd = f8  with protect,   constant(uar_get_code_by('MEANING', 89, 'POWERCHART')) ;002

/**************************************************************
; DVDev Start Coding
**************************************************************/


/**********************************************************************
DESCRIPTION:  Get the Surgeries for the patient
**********************************************************************/
select into 'nl:'
  from surgical_case        sc
     , surg_case_procedure scp
 where sc.person_id         =  $per_id
   and sc.cancel_dt_tm      =  null
   and sc.checkin_dt_tm     != null
   and sc.surg_start_dt_tm  != null
   and sc.surg_stop_dt_tm   != null
   and sc.surg_complete_qty >  0 
   and sc.active_ind        =  1
   and scp.surg_case_id     =  sc.surg_case_id
   and scp.surg_proc_cd     >  0
   and scp.active_ind       =  1    ;002
order by
    sc.surg_start_dt_tm desc
detail
    unsort_post_op_info->cnt = unsort_post_op_info->cnt + 1
    
    pos = unsort_post_op_info->cnt 
    
    if(mod(unsort_post_op_info->cnt, 10) = 1)
        stat = alterlist(unsort_post_op_info->qual, unsort_post_op_info->cnt + 9)
    endif

    unsort_post_op_info->qual[pos]->surg_case_id = sc.surg_case_id
    
    unsort_post_op_info->qual[pos]->proc_name    = uar_get_code_display(scp.surg_proc_cd)
    unsort_post_op_info->qual[pos]->proc_date    = format(sc.surg_start_dt_tm, '@SHORTDATE')
    unsort_post_op_info->qual[pos]->proc_dt_tm   = format(sc.surg_start_dt_tm, 'YYYY-MM-DD;;D') ;JS ISO format
    unsort_post_op_info->qual[pos]->sort_date    = sc.surg_start_dt_tm
    
    ;Shinnanigans here that might need pointing out.  this funct returns days with partial days as decimal.
    ;Since we are casing this to an int, the decimal should always be stripped leaving an implicit floor.
    ;Hopefully this will work.  Might need some testing around UTC dates.
    temp_days = datetimediff(cnvtdatetime(curdate, curtime3), sc.surg_start_dt_tm)
    
    
    if(temp_days = 1)
        unsort_post_op_info->qual[pos]->post_op_days = concat(trim(cnvtstring(temp_days), 3), ' day')
    else
        unsort_post_op_info->qual[pos]->post_op_days = concat(trim(cnvtstring(temp_days), 3), ' days')
    endif
with nocounter


/**********************************************************************
DESCRIPTION:  Get the Procedures for the patient
**********************************************************************/
select into 'nl:'
  from procedure p
     , encounter e
     , nomenclature n
 where e.person_id              =  $per_id
   and e.active_ind             =  1
   and p.encntr_id              =  e.encntr_id
   and p.active_ind             =  1
   ;002->
   ;In prod testing, we found data that the cerner histories component doesn't use.
   ;In my investigations there, I think we need to add the following to this
   and p.suppress_narrative_ind != 1
   and p.contributor_system_cd  in (powerchart_cd, 0.0) ;0.0 for freetext
   ;002<-
   and n.nomenclature_id = p.nomenclature_id
order by
    p.proc_dt_tm desc
detail
    unsort_post_op_info->cnt = unsort_post_op_info->cnt + 1
    
    pos = unsort_post_op_info->cnt 
    
    if(mod(unsort_post_op_info->cnt, 10) = 1)
        stat = alterlist(unsort_post_op_info->qual, unsort_post_op_info->cnt + 9)
    endif

    unsort_post_op_info->qual[pos]->proc_id   = p.procedure_id
    
    if(p.nomenclature_id = 0)
        unsort_post_op_info->qual[pos]->proc_name = trim(p.procedure_note, 3)
    else
        unsort_post_op_info->qual[pos]->proc_name = trim(n.source_string, 3)
    endif
    
    if(p.proc_dt_tm = null)
        unsort_post_op_info->qual[pos]->proc_date = '--'
        
        ;this will be null and should make sorting below behave.
        unsort_post_op_info->qual[pos]->sort_date = p.proc_dt_tm
        
        unsort_post_op_info->qual[pos]->post_op_days = '--'
        
    else
        case(p.proc_dt_tm_prec_flag)
            of 0: ; Date
            of 1: ; Week of
                unsort_post_op_info->qual[pos]->proc_date  = format(p.proc_dt_tm, '@SHORTDATE')
            of 2: ; Month
                unsort_post_op_info->qual[pos]->proc_date  = format(p.proc_dt_tm, "MM/YYYY;;d")
            of 3: ; Year
                unsort_post_op_info->qual[pos]->proc_date  = format(p.proc_dt_tm, "YYYY;;d")
        endcase
        
        unsort_post_op_info->qual[pos]->proc_dt_tm = format(p.proc_dt_tm, 'YYYY-MM-DD;;D') ;JS ISO format
        
        unsort_post_op_info->qual[pos]->sort_date  = p.proc_dt_tm
        
        ;Shinnanigans here that might need pointing out.  this funct returns days with partial days as decimal.
        ;Since we are casing this to an int, the decimal should always be stripped leaving an implicit floor.
        ;Hopefully this will work.  Might need some testing around UTC dates.
        temp_days = datetimediff(cnvtdatetime(curdate, curtime3), p.proc_dt_tm)
        
        
        if(temp_days = 1)
            unsort_post_op_info->qual[pos]->post_op_days = concat(trim(cnvtstring(temp_days), 3), ' day')
        else
            unsort_post_op_info->qual[pos]->post_op_days = concat(trim(cnvtstring(temp_days), 3), ' days')
        endif
    endif
    
    
with nocounter


set stat = alterlist(unsort_post_op_info->qual, unsort_post_op_info->cnt)


;Sort time
select into 'nl:'
    sort_dt = unsort_post_op_info->qual[d.seq]->sort_date
  from (dummyt d with seq = value(unsort_post_op_info->cnt))
plan d
 where unsort_post_op_info->cnt > 0
order by sort_dt desc
head report
    stat = alterlist(post_op_info->qual, unsort_post_op_info->cnt)
detail
    
    post_op_info->cnt = post_op_info->cnt + 1
    
    pos = post_op_info->cnt
    
    post_op_info->qual[pos]->surg_case_id = unsort_post_op_info->qual[d.seq]->surg_case_id
    post_op_info->qual[pos]->proc_id      = unsort_post_op_info->qual[d.seq]->proc_id     
    post_op_info->qual[pos]->proc_name    = unsort_post_op_info->qual[d.seq]->proc_name   
    post_op_info->qual[pos]->proc_date    = unsort_post_op_info->qual[d.seq]->proc_date   
    post_op_info->qual[pos]->proc_dt_tm   = unsort_post_op_info->qual[d.seq]->proc_dt_tm  
    post_op_info->qual[pos]->post_op_days = unsort_post_op_info->qual[d.seq]->post_op_days

with nocounter


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script

call echojson(unsort_post_op_info)
call echojson(post_op_info)

call putRSToFile($OUTDEV, post_op_info)

end
go
 