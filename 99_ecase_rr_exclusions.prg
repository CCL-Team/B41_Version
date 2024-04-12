/*************************************************************************
 Program Title: eCase Reportability Response Exclusions, with result
 
 Object name:   99_ecase_rr_exclusions
 Source file:   99_ecase_rr_exclusions.prg
 
 Purpose:       
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: 
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 04/02/2024 Michael Mayes               Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 99_ecase_rr_exclusions:dba go
create program 99_ecase_rr_exclusions:dba
 
prompt 
	  "Output to File/Printer/MINE" = "MINE"
    , "Begin Datetime"              = sysdate
    , "End Datetime"                = sysdate

with OUTDEV, beg_dt_tm, end_dt_tm
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt                      = i4
    1 qual[*]
        2 per_id               = f8 
        2 enc_id               = f8
        2 name                 = vc
        2 fin                  = vc
        2 result_date          = dq8
        2 reg_date             = dq8
        2 disch_date           = dq8
        2 encntr_type          = vc
        2 loc                  = vc
        2 prob_id              = f8
        2 prob                 = vc
        2 prob_life_cycle      = vc
        2 prob_life_cycle_date = dq8
        2 prob_onset           = dq8
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
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
 

 
/**********************************************************************
DESCRIPTION:  Find the cases that have RR event on them.  AND also have
              an active problem with the nomens he gave me.
      NOTES:  

              These were the nomens he showed me.  these were the 
              two "covid ruled out" codes... IMO code 1492827026
              53461718.00
              76655306.00 
            
              But really it lands as snomed nomen here.
              Nomen_id 71849973.00
***********************************************************************/
select into "nl:"   
        
  from clinical_event ce  
     , person         p    
     , encounter      e 
     , encntr_alias   ea 
     , organization   o 
     , problem        prob
     , nomenclature   n 

 where ce.event_cd               =  3713631297.00    ;Reportability Response - Public Health
   and ce.view_level             =  1     
   and ce.event_end_dt_tm        between cnvtdatetime($beg_dt_tm) and cnvtdatetime($end_dt_tm)  
                                 
   and p.person_id               =  ce.person_id
                                 
   and e.encntr_id               =  ce.encntr_id 
                                 
   and ea.encntr_id              =  outerjoin(ce.encntr_id)
   and ea.encntr_alias_type_cd   =  outerjoin(1077)
                                 
   and o.organization_id         =  e.organization_id
                                 
   and prob.person_id            =  ce.person_id
   and prob.nomenclature_id      =  71849973  ;  Disease caused by severe acute respiratory syndrome coronavirus 2 absent
   
   and n.nomenclature_id         =  prob.nomenclature_id

order by ce.event_id
       , e.organization_id  
       , p.person_id    
       , ce.event_start_dt_tm desc   
       , e.reg_dt_tm          desc 
        
head report
    data->cnt = 0
 
head ce.event_id
    data->cnt = data->cnt + 1
    stat=alterlist(data->qual, data->cnt)
  
    data->qual[data->cnt]->per_id                = p.person_id
    data->qual[data->cnt]->enc_id                = e.encntr_id
    
    data->qual[data->cnt]->name                  = p.name_full_formatted
    data->qual[data->cnt]->fin                   = ea.alias
    data->qual[data->cnt]->result_date           = ce.event_end_dt_tm
    data->qual[data->cnt]->reg_date              = e.reg_dt_tm
    data->qual[data->cnt]->disch_date            = e.disch_dt_tm
    data->qual[data->cnt]->encntr_type           = uar_get_code_display(e.encntr_type_class_cd)
    data->qual[data->cnt]->loc                   = o.org_name
    
    
    data->qual[data->cnt]->prob_id               = prob.problem_id
    data->qual[data->cnt]->prob                  = trim(n.source_string, 3)
    data->qual[data->cnt]->prob_onset            = prob.onset_dt_tm
    data->qual[data->cnt]->prob_life_cycle       = uar_get_code_display(prob.life_cycle_status_cd)
    data->qual[data->cnt]->prob_life_cycle_date  = prob.life_cycle_dt_tm

with nocounter


;Presentation time
if (data->cnt > 0)
    
    select into $outdev
           PER_ID               =                           data->qual[d.seq].per_id
         , ENC_ID               =                           data->qual[d.seq].enc_id
         , PAT_NAME             = trim(substring(1,  150,   data->qual[d.seq].name                                  ))
         , FIN                  = trim(substring(1,   30,   data->qual[d.seq].fin                                   ))
         , RR_RES_DATE          = format(                   data->qual[d.seq].result_date, '@SHORTDATETIME'         )
         , REG_DATE             = format(                   data->qual[d.seq].reg_date   , '@SHORTDATETIME'         )
         , DISCHARGE_DATE       = format(                   data->qual[d.seq].disch_date , '@SHORTDATETIME'         )
         , ENCNTR_TYPE          = trim(substring(1,   30,   data->qual[d.seq].encntr_type                           ))
         , LOC                  = trim(substring(1,   50,   data->qual[d.seq].loc                                   ))
         , PROB_ONSET           = format(                   data->qual[d.seq].prob_onset , '@SHORTDATETIME'         )
         , PROB_LIFE_CYCLE      = trim(substring(1,   10,   data->qual[d.seq].prob_life_cycle                       ))
         , PROB_LIFE_CYCLE_DATE = format(                   data->qual[d.seq].prob_life_cycle_date, '@SHORTDATETIME')
         , PROB                 = trim(substring(1,  100,   data->qual[d.seq].prob                                  ))
         

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
 
 

