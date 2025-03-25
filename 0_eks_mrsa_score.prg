/*************************************************************************
 Program Title: DCed Acute Care Order Check

 Object name:   0_eks_mrsa_score
 Source file:   0_eks_mrsa_score.prg

 Purpose:       There are several risk factors they want me to check
                and come up with a risk score for the rule involved here.
                If the score is above a threshold, the rule will continue
                firing.
                
                As of initial time... it looks like this:
                    Dynamic Groupers active and not discontinued:
                        Documentation of Central Venous Line: Non-Tunneled               = 2 points 
                        Documentation of Central Venous Line: Tunneled                   = 1 point 
                        Documentation of Indwelling Catheter Placement (This is Urinary) = 1 point 
                        Documentation of Intubation or Ventilation                       = 1 point   (This isn't a dyn group)
                        Documentation of Left Ventricular Assistive Device (LVAD) or     = 1 point
                    
                    Dynamic groups... I need to make sure the group is still active... not stopped or removed.
                    And they usually have sub activities with a few that mean that they have been stopped I need to check.
                    
                    PXes/DXes 
                        History of MRSA Infection (Z86.14) is added to problem list or has been added within the last year = 1 point
                        When End Stage Renal Disease (N18.6) or Dependence on Renal Dialysis (Z99.2) is added to Dx List   = 1 point
 
 
 Tables read:   

 Executed from: Rules
                PHY_SZ_MRSA_SCREENING
                
 Special Notes: 

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 01/16/2025 Michael Mayes        349736 Initial release (SCTASK0142305)
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_mrsa_score:dba go
create program 0_eks_mrsa_score:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)

/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare addScoreandMSG(text = vc, score = i4) = null

/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/

free record lines
record lines(
    1 lines_cnt = i4
    1 qual[*]
        2 dynamic_label_id = f8
        2 name             = vc
        2 line             = vc
        2 type             = vc
        
        2 latest_act_id    = f8
        2 latest_act_res   = vc
    
    1 vent_ind             = i2
    1 vent_event_id        = f8
    1 vent_res             = vc
    
    1 px_ind               = i2
    1 px_list              = vc
    1 px_dt                = dq8
    1 px_dt_txt            = vc
                           
    1 dx_ind               = i2
    1 dx_list              = vc
    
    1 score_string         = vc
    1 score_num            = i4
)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'      ))
declare mod_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'    ))
declare auth_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'        ))
declare alt_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'     ))

declare placeholderCd  = f8  with protect,   constant(uar_get_code_by(   "MEANING", 53, "PLACEHOLDER" ))

declare temp_name      = vc  with protect, noconstant('')

declare looper         = i4  with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_mrsa_score failed during execution"



/**********************************************************************
DESCRIPTION:  Fine the current Dynamic groups that are active
      NOTES:  
***********************************************************************/
select into 'nl:'
       cdl.valid_until_dt_tm
     , Label = notrim(build2( trim(replace( dsr.doc_set_name, 'Repeatable Group', ''), 3)
                            , ' ('   , trim(cdl.label_name, 3), ')'))
     , Line = trim(replace( dsr.doc_set_name, 'Repeatable Group', ''), 3)
     , Type = trim(cdl.label_name, 3)
     , cdl.* 

  from CE_DYNAMIC_LABEL       cdl
     , clinical_event         ce
     , DYNAMIC_LABEL_TEMPLATE dlt
     , doc_set_ref            dsr

 where cdl.person_id          =  trigger_personid
   and cdl.valid_from_dt_tm > sysdate - 30 ;DEBUGGING
   and cdl.valid_until_dt_tm  >  cnvtdatetime(curdate, curtime3)
   and cdl.label_status_cd    =  4311835.00 ;ACTIVE it goes inactive if they grey it, and we don't want it.
   
   ;Just to make sure that the label is on this encounter
   and ce.ce_dynamic_label_id =  cdl.ce_dynamic_label_id
   and ce.encntr_id           =  trigger_encntrid
   and ce.result_status_cd    in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm   >  cnvtdatetime(curdate, curtime3)
   
   and dlt.label_template_id  =  cdl.label_template_id
   
   and dsr.doc_set_ref_id     =  dlt.doc_set_ref_id

order by cdl.ce_dynamic_label_id

head cdl.ce_dynamic_label_id
    lines->lines_cnt = lines->lines_cnt + 1
    
    stat = alterlist(lines->qual, lines->lines_cnt)

    lines->qual[lines->lines_cnt]->dynamic_label_id = cdl.ce_dynamic_label_id
    lines->qual[lines->lines_cnt]->name             = Label
    lines->qual[lines->lines_cnt]->line             = Line
    lines->qual[lines->lines_cnt]->type             = Type

with nocounter


/**********************************************************************
DESCRIPTION:  Find most recent activity on each line.
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
     , (dummyt d with seq = lines->lines_cnt)
  
  plan d
   where lines->lines_cnt                     > 0
     and lines->qual[d.seq]->dynamic_label_id > 0
  
  join ce
   where ce.encntr_id           =  trigger_encntrid
     and ce.ce_dynamic_label_id =  lines->qual[d.seq]->dynamic_label_id
     and ce.event_cd            in (    712525.00   ;Urinary Catheter Activity:                 
                                   , 102263361.00   ;CVAD Activity:                             
                                   , 823727507.00   ;HeartMate II Activity:                     
                                   , 823727517.00   ;HeartMate III Activity:                    
                                   , 823727577.00   ;HeartWare Activity:                        
                                   )
     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd    in (act_cd, mod_cd, auth_cd, alt_cd)
     and ce.event_class_cd      != placeholderCd
       
order by ce.ce_dynamic_label_id, ce.event_end_dt_tm desc

head ce.ce_dynamic_label_id

    lines->qual[d.seq]->latest_act_id  = ce.event_id
    lines->qual[d.seq]->latest_act_res = trim(ce.result_val, 3)
    
    
    
with nocounter


/**********************************************************************
DESCRIPTION:  Find if we have a vent
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
  
   where ce.encntr_id           =  trigger_encntrid
     and ce.event_cd            in (    2796635.00  ;Ventilator Mode
                                   )
     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd    in (act_cd, mod_cd, auth_cd, alt_cd)
       
order ce.event_cd, ce.event_end_dt_tm desc

head ce.event_cd

    lines->vent_ind      = 1
    lines->vent_event_id = ce.event_id
    lines->vent_res      = trim(ce.result_val, 3)
    
with nocounter


/**********************************************************************
DESCRIPTION:  Find the problems we are interested in
      NOTES:  
***********************************************************************/
select into 'nl:'

  from problem       p
     , nomenclature  n
     , cmt_cross_map ccm
     , nomenclature  n2

 where p.person_id =  trigger_personid
   and p.active_ind = 1
   and p.life_cycle_status_cd = 3301.000000  ;ACTIVE
   and p.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and p.beg_effective_dt_tm >= cnvtlookbehind('1,Y')

   and n.nomenclature_id = p.nomenclature_id
   and n.nomenclature_id > 0.0
   and n.active_ind = 1
   and n.source_vocabulary_cd in (673967.000,   ; SNOMED
                                  62094639.000) ; IMO

   and ccm.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
   and ccm.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and (   ccm.target_concept_cki = n.concept_cki
        or ccm.concept_cki        = n.concept_cki
       )
   
   and n2.concept_cki = ccm.concept_cki
   and n2.source_identifier = 'Z86.14'
   and n2.source_vocabulary_cd = 73005233.00  ; ICD-10

detail

    lines->px_ind    = 1
    lines->px_list   = notrim(build2(trim(n2.source_string, 3), ' [', trim(n2.source_identifier, 3), ']'))
    lines->px_dt     = p.beg_effective_dt_tm
    lines->px_dt_txt = format(p.beg_effective_dt_tm, '@SHORTDATETIME')

with nocounter


/**********************************************************************
DESCRIPTION:  Find the diagnosis we are interested in
      NOTES:  
***********************************************************************/
select into 'nl:'

  from diagnosis     d
     , nomenclature  n
     , cmt_cross_map ccm
     , nomenclature  n2

 where d.encntr_id =  trigger_encntrid
   and d.active_ind = 1
   and d.life_cycle_status_cd = 3301.000000  ;ACTIVE
   and d.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and d.beg_effective_dt_tm >= cnvtlookbehind('1,Y')

   and n.nomenclature_id = d.nomenclature_id
   and n.nomenclature_id > 0.0
   and n.active_ind = 1
   and n.source_vocabulary_cd in (   673967.000   ; SNOMED
                                 , 62094639.000   ; IMO
                                 , 73005233.000   ; ICD-10
                                 )

   and ccm.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
   and ccm.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and (   ccm.target_concept_cki = n.concept_cki
        or ccm.concept_cki        = n.concept_cki
       )
   
   and n2.concept_cki = ccm.concept_cki
   and n2.source_identifier in ('N18.6', 'Z99.2')
   and n2.source_vocabulary_cd = 73005233.00  ; ICD-10

order by d.diagnosis_id

head d.diagnosis_id

    lines->dx_ind   = 1
    
    if(lines->dx_list = '') lines->dx_list = trim(n2.source_identifier, 3)  
    else                    lines->dx_list = trim(concat(lines->dx_list, '; ', n2.source_identifier), 3)
    endif

with nocounter


;Loop across the bands to figure out if they affect score
for(looper = 1 to lines->lines_cnt)
    ;Filter out the results that say ignore the band.
    if(    lines->qual[looper]->latest_act_res not in( 'Self removed'
                                                     , 'Discontinued'
                                                     , 'Unintentionally removed'
                                                    )
       ;HEART ones are a list, so I need to look in the whole list for discontinue.
       and findstring('Discontinue', lines->qual[looper]->latest_act_res) = 0
      )
    
        ;Now loop over remaining, and score them.
        if  (lines->qual[looper]->line = 'Central Line')
            if  (findstring('Non-Tunneled', lines->qual[looper]->type) > 0)
                
                call addScoreandMSG(lines->qual[looper]->name, 2)
            
            endif
            
            ;We have to take special care here... because Tunneled is within Non-Tunneled.  And it could be multiple.
            set temp_name = replace(lines->qual[looper]->type, 'Non-Tunneled', '')
            
            if  (findstring('Tunneled', temp_name) > 0)
                
                call addScoreandMSG(lines->qual[looper]->name, 1)
            
            endif
            
        
        elseif(lines->qual[looper]->line = 'Indwelling Urinary Catheter')
            
            call addScoreandMSG(lines->qual[looper]->name, 1)
        
        
        elseif(lines->qual[looper]->line in ( 'HeartWare'
                                            , 'HeartMate II'
                                            , 'HeartMate III'
                                            )
              )
              
            ;We only want L VAD here.
            if(lines->qual[looper]->type = 'L VAD')
                call addScoreandMSG(lines->qual[looper]->name, 1)
            endif
            
        endif
    
    endif

endfor


;We have other work to do non-looped
if(lines->vent_ind = 1) call addScoreandMSG(lines->vent_res, 1)
endif


if(lines->px_ind = 1) call addScoreandMSG(lines->px_list, 1)
endif


if(lines->dx_ind = 1) call addScoreandMSG(lines->dx_list, 1)
endif



;Adding the total score
set lines->score_string = notrim(build2('Total Score: ', trim(cnvtstring(lines->score_num, 17, 0), 3)
                                       , '; ', lines->score_string
                                       )
                                )

call echorecord(lines)




;Now let the rule know what we found.

set log_message = lines->score_string
set log_misc1   = trim(cnvtstring(lines->score_num, 17, 0), 3)

if(lines->score_num >= 2) set retval = 100
else                      set retval = 0
endif

    


/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
subroutine addScoreandMSG(text, score)
    
    declare msg = vc with protect,  constant(concat( text, ' [', trim(cnvtstring(score, 17, 0), 3), ']'))


    if(lines->score_string = '') set lines->score_string = msg
    else                         set lines->score_string = concat( lines->score_string, '; '
                                                                 , msg)
    endif

    set lines->score_num = lines->score_num + score
    
    
    call echo(concat('adding:', text, ' [', trim(cnvtstring(score, 17, 0), 3), ']'))

end

#exit_script
;debugging
call echo(build('retval     :', retval     ))
call echo(build('log_message:', log_message    ))


end
go


