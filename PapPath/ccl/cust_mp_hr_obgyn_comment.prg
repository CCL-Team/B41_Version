/**************************************************************************
 Program Title:   mPage Cerv Cyto MP Add HR Comment/Followup date
 
 Object name:     cust_mp_hr_obgyn_comment
 Source file:     cust_mp_hr_obgyn_comment.prg
 
 Purpose:         
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   This stuff is borrowed from 14_mp_ref_mgmt_trkr
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 06/23/2022 Michael Mayes        218308    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
  drop program cust_mp_hr_obgyn_comment:dba go
create program cust_mp_hr_obgyn_comment:dba

prompt
      "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Person ID"                   = 0.0
    , "Encounter ID"                = 0.0
    , "Comment"                     = ""
    , "Date"                        = ""
with outdev, person_id, encntr_id, comment, date


/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/

free record reply
record reply(
    1 comment_cnt              = i4
    1 comments[*]
        2 com_event_id         = f8
        2 date_event_id        = f8
        2 comment              = vc
        2 followup_dt          = dq8
        2 followup_dt_txt      = vc
        2 followup_sort_dt_txt = vc
        2 event_end_dt         = dq8
        2 event_end_dt_txt     = vc
        2 prsnl_name           = vc
%i cust_script:mmm_mp_status.inc
)

%i cust_script:cust_ce_rs.inc

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare ce_service_call_txt(type = vc, enc_id = f8, per_id = f8, data = vc, updt_dt = dq8) = null
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare updt_dt_tm  = dq8 with protect,   constant(cnvtdatetime(curdate, curtime3))

declare auth_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     8, 'AUTHVERIFIED'   ))
declare modified_cd = f8  with protect,   constant(uar_get_code_by('MEANING'   ,     8, 'MODIFIED'       ))
declare altered_cd  = f8  with protect,   constant(uar_get_code_by('MEANING'   ,     8, 'ALTERED'        ))

declare perform_cd  = f8  with protect,   constant(uar_get_code_by('MEANING'   ,    21, 'PERFORM'        ))


declare comment_cd  = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    72, 'AMBCERVCYTOCOMMENTMP' ))
declare due_dt_cd   = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    72, 'AMBCERVCYTOFOLLOWUPMP'))

declare pos         = i4  with protect, noconstant(0)



/**************************************************************
; DVDev Start Coding
**************************************************************/

call echo(build('outdev   :', $outdev   ))
call echo(build('encntr_id:', $encntr_id))
call echo(build('person_id:', $person_id))
call echo(build('comment  :', $comment  ))
call echo(build('date     :', $date     ))


call ce_service_call('COMMENT', $encntr_id, $person_id, $comment, updt_dt_tm)
call ce_service_call('DATE'   , $encntr_id, $person_id, $date   , updt_dt_tm)


/***********************************************************************
DESCRIPTION:  Gather Previous Comments and Due Dates
      NOTES:  This is heavily tied to the query and RS in 
              cust_mp_high_risk_obgyn_test.prg.  The structure needs to 
              be roughly the same, as the frontend will use this to redraw.
***********************************************************************/
select into 'nl:'
  from clinical_event   ce
     , ce_event_prsnl   cep
     , prsnl            p 
     , ce_date_result   cdr
     , ce_string_result csr
     ;, (dummyt d with seq = results->cnt)
  ;plan d
  ; where results->cnt                 >  0
  ;   and results->qual[d.seq]->per_id != 0
  ;   
  ;join ce
   plan ce
   where ce.person_id             =  $person_id
     and ce.event_cd              in (comment_cd, due_dt_cd)
     and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
     and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)

  join cep  ;  Multiple here... might not matter.  Each CE has at least a row here.
   where cep.event_id          =  ce.event_id
     and cep.action_type_cd    =  perform_cd
     and cep.valid_until_dt_tm >  sysdate
     
  join p
   where p.person_id           = cep.action_prsnl_id

  join cdr
    where cdr.event_id            =  outerjoin(ce.event_id)
      and cdr.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))
  
  join csr
    where csr.event_id            =  outerjoin(ce.event_id)
      and csr.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))
  
order by ce.event_end_dt_tm desc, ce.event_cd
head ce.event_end_dt_tm
    reply->comment_cnt = reply->comment_cnt + 1
    
    pos = reply->comment_cnt
    
    stat = alterlist(reply->comments, pos)
    
    reply->comments[pos]->event_end_dt     = ce.event_end_dt_tm
    reply->comments[pos]->event_end_dt_txt = format(ce.event_end_dt_tm, "MM-DD-YYYY HH:MM:SS")
    reply->comments[pos]->prsnl_name       = trim(p.name_full_formatted, 3)
    
detail

    if(csr.string_result_text != null)
        reply->comments[pos]->com_event_id    = ce.event_id
        
        reply->comments[pos]->comment         = csr.string_result_text
    endif
    
    if(cdr.result_dt_tm != null)
        reply->comments[pos]->date_event_id   = ce.event_id
        
        reply->comments[pos]->followup_dt          = cdr.result_dt_tm
        reply->comments[pos]->followup_dt_txt      = format(cdr.result_dt_tm, 'MM-DD-YYYY')
        reply->comments[pos]->followup_sort_dt_txt = format(cdr.result_dt_tm, 'YYYY-MM-DD')
    endif


with nocounter

;set _memory_reply_string = trim(cnvtstring(doid), 3)


/**************************************************************
; DVDev Subroutine Definitions
**************************************************************/
/* ce_service_call_txt
   Call the service to write out our CE and info to the tables.
   
   Input:
        type   (vc):  'COMMENT': Store data as text, with the comment_cd created for us
                      'DATE'   : Store data as date, with the date_cd created for us
        enc_id (f8):  Encounter id
        per_id (f8):  Person_id
        data   (vc):  Data that flexes, right now either comment text, or a date time string.
        updt_dt(dq8): Date that we should use for the clinical_events
*/ 
subroutine ce_service_call(type, enc_id, per_id, data, updt_dt)
    ;Our text
    declare comment  = vc  with protect, noconstant('')
    declare date     = dq8 with protect
    declare event_cd = f8  with protect, noconstant(0.0)

    ;call clinical_event server to update/insert ce_blob
    declare app_nbr  = i4  with protect,  constant(1000012)
    declare task_nbr = i4  with protect,  constant(1000012)
    declare req_nbr  = i4  with protect,  constant(1000012)
    
    ;code_values
    declare active_cd     = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",  48, "ACTIVE"      ))
    declare auth_cd       = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",   8, "AUTHVERIFIED"))
    declare verify_cd     = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",  21, "VERIFY"      ))
    declare perform_cd    = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",  21, "PERFORM"     ))
    declare complete_cd   = f8  with protect,   constant(uar_get_code_by(   "MEANING", 103, "COMPLETED"   ))
    declare powerchart_cd = f8  with protect,   constant(uar_get_code_by(   "MEANING",  89, "POWERCHART"  ))

    declare txt_cd        = f8  with protect,   constant(uar_get_code_by(   "MEANING",  53, "TXT"         ))
    declare root_cd       = f8  with protect,   constant(uar_get_code_by(   "MEANING",  24, "R"           ))
    
    
    set stat = initrec(cerequest)
    set stat = initrec(cereply)
    
    
    case(type)
    of 'COMMENT': 
        set event_cd = uar_get_code_by("DISPLAYKEY",  72, "AMBCERVCYTOCOMMENTMP" )
        set comment  = replace(data, "%UP%", "^")
    of 'DATE'   : 
        set event_cd = uar_get_code_by("DISPLAYKEY",  72, "AMBCERVCYTOFOLLOWUPMP")
        set date     = cnvtdatetime(data)
    endcase
    
    
    set cerequest->ensure_type = 1

    set cerequest->clin_event->person_id = per_id
    set cerequest->clin_event->encntr_id = enc_id


    set cerequest->clin_event->event_cd              = event_cd
    set cerequest->clin_event->event_class_cd        = txt_cd
    set cerequest->clin_event->event_reltn_cd        = root_cd
    set cerequest->clin_event->view_level            = 0
    set cerequest->clin_event->publish_flag          = 0
    set cerequest->clin_event->publish_flag_ind      = 1
    set cerequest->clin_event->result_status_cd      = auth_cd
    set cerequest->clin_event->event_end_dt_tm       = cnvtdatetime(updt_dt)
    set cerequest->clin_event->contributor_system_cd = powerchart_cd
    set cerequest->clin_event->record_status_cd      = active_cd
    set cerequest->clin_event->updt_id               = reqinfo->updt_id
        
    set stat = alterlist(cerequest->event_prsnl_list, 2)
    set cerequest->clin_event->event_prsnl_list[1]->action_dt_tm     = cnvtdatetime(updt_dt)
    set cerequest->clin_event->event_prsnl_list[1]->action_type_cd   = verify_cd
    set cerequest->clin_event->event_prsnl_list[1]->action_status_cd = complete_cd
    set cerequest->clin_event->event_prsnl_list[1]->action_dt_tm_ind = 1
    set cerequest->clin_event->event_prsnl_list[1]->person_id        = reqinfo->updt_id
    set cerequest->clin_event->event_prsnl_list[1]->action_prsnl_id  = reqinfo->updt_id
    
    set cerequest->clin_event->event_prsnl_list[2]->action_dt_tm     = cnvtdatetime(updt_dt)
    set cerequest->clin_event->event_prsnl_list[2]->action_type_cd   = perform_cd
    set cerequest->clin_event->event_prsnl_list[2]->action_status_cd = complete_cd
    set cerequest->clin_event->event_prsnl_list[2]->action_dt_tm_ind = 1
    set cerequest->clin_event->event_prsnl_list[2]->person_id        = reqinfo->updt_id
    set cerequest->clin_event->event_prsnl_list[2]->action_prsnl_id  = reqinfo->updt_id

    case(type)
    of 'COMMENT':
        
        set stat = alterlist(cerequest->clin_event->string_result, 1)
        set cerequest->clin_event->string_result[1]->string_result_text      = nullterm(comment)
        set cerequest->clin_event->string_result[1]->string_result_format_cd = uar_get_code_by("DISPLAYKEY", 14113, "ALPHA")
        
    of 'DATE'   :
        set stat = alterlist(cerequest->clin_event->date_result, 1)
        set cerequest->clin_event->date_result[1]->result_dt_tm      = date
    endcase
    
    
    call echorecord(cerequest)
    set stat = tdbexecute(app_nbr, task_nbr, req_nbr, "REC", cerequest, "REC", cereply)
    call echorecord(cereply)


end


#exit_script


call echorecord(reply)


call putRSToFile($outdev, reply)


end
go