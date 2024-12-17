/*************************************************************************
 Program Title: Entity General Consent Form Tasks
 
 Object name:   14_entity_tasks_rpt.prg
 Source file:   14_entity_tasks_rpt.prg.prg
 
 Purpose:       Find Entity General Consent Form tasks (maybe just the uncomplete ones for now)
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 11/08/2024 Michael Mayes               Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_entity_tasks_rpt:dba go
create program 14_entity_tasks_rpt:dba
 
 
prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Form Start Date"           = "SYSDATE"
	, "Form End Date"             = "SYSDATE"
	, "Organization"              = ""
	;<<hidden>>"Search"           = 0
	, "Organization"              = VALUE(0.0)
	, "Uncomplete Tasks Only"     = 0 

with OUTDEV, START_DT, END_DT, ORG_SEARCH, ORG_ID, NON_COMP_IND
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 p_id        = f8
        2 e_id        = f8 
        2 pat_name    = vc
        2 mrn         = vc
        2 fin         = vc
        2 org_id      = f8
        2 serv_loc    = vc
        2 serv_dt_tm  = dq8
        2 serv_dt_txt = vc
        2 task_id     = f8
        2 task_name   = vc
        2 task_dt_tm  = dq8
        2 task_dt_txt = vc
        2 task_status = vc
)

 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
/* 
declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))
*/
/*
declare pos                = i4  with protect, noconstant(0)
declare idx                = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)
*/

declare fin_cd                 = f8 with protect, constant(uar_get_code_by ('DISPLAY_KEY', 319, 'FINNBR'))
declare mrn_cd                 = f8 with protect, constant(uar_get_code_by (    'MEANING', 319, 'MRN'   ))   
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
 
 
/**********************************************************************
DESCRIPTION:  
 
      NOTES:  
***********************************************************************/
select into 'nl:'

  from task_activity ta
     , order_task    ot
     , encounter     e
     , person        p 
     , organization  o
     , encntr_alias  fin
     , encntr_alias  mrn
     
 where ot.task_description      = 'Entity General Consent Form Received'
   and ot.active_ind            = 1
                                
   and ta.reference_task_id     = ot.reference_task_id
   and (   $NON_COMP_IND = 0
        or ta.task_status_cd != 419.00   ;Complete
       )
   and ta.task_dt_tm >= cnvtdatetime($START_DT)
   and ta.task_dt_tm <= cnvtdatetime($END_DT)
                                
   and p.person_id              = ta.person_id
                                
   and e.encntr_id              = ta.encntr_id
   and (   0                    in ($ORG_ID)
        or e.organization_id    in ($ORG_ID)
       )
       
   and o.organization_id        =  e.organization_id
   
   and fin.encntr_id            = outerjoin(e.encntr_id)
   and fin.encntr_alias_type_cd = outerjoin(fin_cd)
   and fin.active_ind           = outerjoin(1)
   
   and mrn.encntr_id            = outerjoin(e.encntr_id)
   and mrn.encntr_alias_type_cd = outerjoin(mrn_cd)
   and mrn.active_ind           = outerjoin(1)

order by ta.task_dt_tm

head ta.task_id
    data->cnt = data->cnt + 1
    
    if(mod(data->cnt, 10) = 1)
        stat = alterlist(data->qual, data->cnt + 9)
    endif
    
    data->qual[data->cnt]->p_id        = p.person_id
    data->qual[data->cnt]->e_id        = e.encntr_id
    data->qual[data->cnt]->org_id      = e.organization_id
    
    data->qual[data->cnt]->pat_name    = trim(p.name_full_formatted, 3)
    data->qual[data->cnt]->mrn         = trim(cnvtalias(mrn.alias, mrn.alias_pool_cd), 3)
    data->qual[data->cnt]->fin         = trim(cnvtalias(fin.alias, fin.alias_pool_cd), 3)
    
    data->qual[data->cnt]->serv_loc    = trim(o.org_name, 3)
    data->qual[data->cnt]->serv_dt_tm  = e.reg_dt_tm
    data->qual[data->cnt]->serv_dt_txt = format(e.reg_dt_tm, '@SHORTDATE')
    
    data->qual[data->cnt]->task_id     = ta.task_id
    data->qual[data->cnt]->task_name   = trim(ot.task_description, 3)
    data->qual[data->cnt]->task_dt_tm  = ta.task_dt_tm
    data->qual[data->cnt]->task_dt_txt = format(ta.task_dt_tm, '@SHORTDATETIME')
    data->qual[data->cnt]->task_status = uar_get_code_display(ta.task_status_cd)
    
foot report
    stat = alterlist(data->qual, data->cnt)
with nocounter, uar_code(D)
   

 
;Presentation time
if (data->cnt > 0)
    
    select into $outdev
           NAME        = trim(substring(1, 100, data->qual[d.seq].pat_name   ))
         , MRN         = trim(substring(1,  20, data->qual[d.seq].mrn        ))
         , FIN         = trim(substring(1,  20, data->qual[d.seq].fin        ))
         , SERV_LOC    = trim(substring(1, 100, data->qual[d.seq].serv_loc   ))
         , SERV_DT     = trim(substring(1,  10, data->qual[d.seq].serv_dt_txt))
         , TASK        = trim(substring(1,  50, data->qual[d.seq].task_name  ))
         , TASK_DT     = trim(substring(1,  20, data->qual[d.seq].task_dt_txt))
         , TASK_STATUS = trim(substring(1,  25, data->qual[d.seq].task_status))

      from (dummyt d with SEQ = data->cnt)
    with format, separator = " ", time = 300

else
   select into $OUTDEV
     from dummyt
    detail
        row + 1
        col 1 "There were no results for your filter selections.."
        col 25
        row + 1
        col 1  "Please Try Your Search Again"
        row + 1
    with format, separator = " "
endif
 
 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script
;DEBUGGING
call echorecord(data)

end
go
 
 

