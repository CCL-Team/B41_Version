/*************************************************************************
 Program Title: 
 
 Object name:   99_mmm_test_result_order
 Source file:   99_mmm_test_result_order.prg
 
 Purpose:       
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 04/03/2024 Michael Mayes               Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 99_mmm_test_result_order:dba go
create program 99_mmm_test_result_order:dba
 
prompt 
	  "PERSON_ID" = 0.0
    , "ENCNTR_ID" = 0.0
    , "EVENT_CD"  = 0.0
    , "ORDER_ID"  = 0.0
    , "RESULT"    = ''

with p_id, e_id, event_cd, ord_id, result
 

 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
%i cust_script:cust_ce_rs.inc
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare updt_dt_tm  = dq8 with protect,   constant(cnvtdatetime(curdate, curtime3))

declare auth_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     8, 'AUTHVERIFIED'   ))
declare perform_cd  = f8  with protect,   constant(uar_get_code_by('MEANING'   ,    21, 'PERFORM'        ))


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
declare verify_cd     = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",  21, "VERIFY"      ))
declare complete_cd   = f8  with protect,   constant(uar_get_code_by(   "MEANING", 103, "COMPLETED"   ))
declare powerchart_cd = f8  with protect,   constant(uar_get_code_by(   "MEANING",  89, "POWERCHART"  ))

declare txt_cd        = f8  with protect,   constant(uar_get_code_by(   "MEANING",  53, "TXT"         ))
declare root_cd       = f8  with protect,   constant(uar_get_code_by(   "MEANING",  24, "R"           ))
 
 
/*************************************************************
; DVDev Start Coding
**************************************************************/

set stat = initrec(cerequest)
set stat = initrec(cereply)
    
    
set cerequest->ensure_type = 1

set cerequest->clin_event->person_id = $p_id
set cerequest->clin_event->encntr_id = $e_id


set cerequest->clin_event->event_cd              = $event_cd
set cerequest->clin_event->order_id              = $ord_id
set cerequest->clin_event->event_class_cd        = txt_cd
set cerequest->clin_event->event_reltn_cd        = root_cd
set cerequest->clin_event->view_level            = 1  ;Is this important... trying 1.  uCern says rules only will do > 0
set cerequest->clin_event->publish_flag          = 1  ;Is this important... trying 1.  uCern says rules only will do > 1
set cerequest->clin_event->publish_flag_ind      = 1
set cerequest->clin_event->result_status_cd      = auth_cd
set cerequest->clin_event->event_end_dt_tm       = cnvtdatetime(updt_dt_tm)
set cerequest->clin_event->contributor_system_cd = powerchart_cd
set cerequest->clin_event->record_status_cd      = active_cd
set cerequest->clin_event->updt_id               = reqinfo->updt_id
    
set stat = alterlist(cerequest->event_prsnl_list, 2)
set cerequest->clin_event->event_prsnl_list[1]->action_dt_tm     = cnvtdatetime(updt_dt_tm)
set cerequest->clin_event->event_prsnl_list[1]->action_type_cd   = verify_cd
set cerequest->clin_event->event_prsnl_list[1]->action_status_cd = complete_cd
set cerequest->clin_event->event_prsnl_list[1]->action_dt_tm_ind = 1
set cerequest->clin_event->event_prsnl_list[1]->person_id        = reqinfo->updt_id
set cerequest->clin_event->event_prsnl_list[1]->action_prsnl_id  = reqinfo->updt_id

set cerequest->clin_event->event_prsnl_list[2]->action_dt_tm     = cnvtdatetime(updt_dt_tm)
set cerequest->clin_event->event_prsnl_list[2]->action_type_cd   = perform_cd
set cerequest->clin_event->event_prsnl_list[2]->action_status_cd = complete_cd
set cerequest->clin_event->event_prsnl_list[2]->action_dt_tm_ind = 1
set cerequest->clin_event->event_prsnl_list[2]->person_id        = reqinfo->updt_id
set cerequest->clin_event->event_prsnl_list[2]->action_prsnl_id  = reqinfo->updt_id

    
set stat = alterlist(cerequest->clin_event->string_result, 1)
set cerequest->clin_event->string_result[1]->string_result_text      = nullterm($result)
set cerequest->clin_event->string_result[1]->string_result_format_cd = uar_get_code_by("DISPLAYKEY", 14113, "ALPHA")


call echorecord(cerequest)
set stat = tdbexecute(app_nbr, task_nbr, req_nbr, "REC", cerequest, "REC", cereply)
call echorecord(cereply)



 
 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script
;DEBUGGING
end
go
 
 

