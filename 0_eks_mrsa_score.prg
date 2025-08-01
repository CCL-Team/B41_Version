/*************************************************************************
 Program Title: MRSA Risk Score

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
                
                ;002->
                Here is the scope creep:
                    Dialysis Patient (Z99.2)             = 1 point  (actually this might be old... checking.)
                    IVAD (F19.10)                        = 1 point
                    ICU patient (prob accommodation)     = 1 point
                    Burn patient (Medical service)       = 1 point
                    Transplant patient (Medical Service) = 1 point
                    Long-term care resident (DTAs)       = 1 point
                ;002<-
                
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
002 06/24/2025 Michael Mayes        349736 And... scope creep
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
    
    1 mrsa_hx_ind          = i2
    1 mrsa_hx_list         = vc
    1 mrsa_hx_dt           = dq8
    1 mrsa_hx_dt_txt       = vc
                           
    1 renal_dx_ind         = i2
    1 renal_dx_list        = vc
                           
    1 ivad_dx_ind          = i2
    1 ivad_dx_list         = vc
    
    1 icu_ind              = i2
    1 icu_txt              = vc
    
    1 burn_ind             = i2
    1 burn_txt             = vc
    
    1 transplant_ind       = i2
    1 transplant_txt       = vc
    
    1 long_term_ind        = i2
    1 long_term_txt        = vc
    
    1 antineo_ind          = i2
    1 antineo_txt          = vc
    
    1 score_string         = vc
    1 score_num            = i4
)


;antineoplastics
record antineo_codes(
    1 cnt = i4
    1 code[*]
        2 multm_category_id    = f8
        2 multm_category       = vc
        
        2 multm_subcategory_id = f8
        2 multm_subcategory    = vc
        
        2 drug_ident           = vc
        
        2 catalog_cd           = f8
        2 catalog_disp         = vc 
)




/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'          ))
declare mod_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'        ))
declare auth_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'            ))
declare alt_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'         ))

declare discon_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'DISCONTINUED' ))
declare cancel_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'CANCELED'     ))
declare voided_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'DELETED'      ))
declare comp_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'COMPLETED'    ))
                                                                                                             
declare placeholderCd     = f8  with protect,   constant(uar_get_code_by(   "MEANING", 53, "PLACEHOLDER"     ))

declare arrive_from_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ARRIVEDFROM'     ))
declare arrive_from_ed_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'ARRIVEDFROMFORED'))


declare temp_name      = vc  with protect, noconstant('')

declare looper         = i4  with protect, noconstant(0)
declare idx            = i4  with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_mrsa_score failed during execution"


/***********************************************************************
DESCRIPTION:  Retrieve catalog_cds we are interested in
      NOTES:  This is multm category 20... although no meds under it
              instead they are under sub categories which is new to me. 
              So modifying my opioid stuff for that.
      
***********************************************************************/
select into 'nl:'
       category    = substring(1, 20, mdc.CATEGORY_NAME)
     , subcategory = substring(1, 50, mdc2.CATEGORY_NAME)
     , medication  = uar_get_code_display(oc.catalog_cd)

  from mltm_drug_categories    mdc
     , MLTM_CATEGORY_SUB_XREF  mcsx
     , mltm_drug_categories    mdc2
     , mltm_category_drug_xref mcdx
     , order_catalog           oc

 where mdc.multum_category_id in (20)
   
   and mcsx.multum_category_id = mdc.multum_category_id
   
   and mdc2.multum_category_id = mcsx.sub_category_id
   
   and mcdx.multum_category_id = mdc2.multum_category_id

   and oc.cki                 =  concat("MUL.ORD!", mcdx.drug_identifier)
   and oc.active_ind          =  1

order by category, subcategory, medication

;The way I have this setup, a med can be in multiple categories, but I don't think it matters in practice.
detail

    antineo_codes->cnt = antineo_codes->cnt + 1

    if(mod(antineo_codes->cnt, 10) = 1)
        stat = alterlist(antineo_codes->code, antineo_codes->cnt + 9)
    endif
    
    
    antineo_codes->code[antineo_codes->cnt]->multm_category_id    = mdc.multum_category_id
    antineo_codes->code[antineo_codes->cnt]->multm_category       = mdc.category_name
    
    antineo_codes->code[antineo_codes->cnt]->multm_subcategory_id = mdc2.multum_category_id
    antineo_codes->code[antineo_codes->cnt]->multm_subcategory    = mdc2.category_name

    antineo_codes->code[antineo_codes->cnt]->drug_ident           = mcdx.drug_identifier
                                                                  
    antineo_codes->code[antineo_codes->cnt]->catalog_cd           = oc.catalog_cd
    antineo_codes->code[antineo_codes->cnt]->catalog_disp         = uar_get_code_display(oc.catalog_cd)

foot report
    stat = alterlist(antineo_codes->code, antineo_codes->cnt)

with nocounter



call echorecord(antineo_codes)




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

    lines->mrsa_hx_ind    = 1
    if(lines->mrsa_hx_list = '')
        lines->mrsa_hx_list   = notrim(build2('MRSA PX: ',trim(n2.source_string, 3), ' [', trim(n2.source_identifier, 3), ']'))
    else
        lines->mrsa_hx_list   = notrim(build2( lines->mrsa_hx_list
                                             , '; '       ,trim(n2.source_string, 3), ' [', trim(n2.source_identifier, 3), ']'
                                             )
                                      )
    endif
    lines->mrsa_hx_dt     = p.beg_effective_dt_tm
    lines->mrsa_hx_dt_txt = format(p.beg_effective_dt_tm, '@SHORTDATETIME')

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
   and (   n2.source_identifier in ('N18.6', 'Z99.2')  ;Renal
        or n2.source_identifier in ('F19.10')          ;IVAD
       )
   and n2.source_vocabulary_cd = 73005233.00  ; ICD-10

order by d.diagnosis_id

head d.diagnosis_id
    
    case(n2.source_identifier)
    of 'N18.6':
    of 'Z99.2':

        lines->renal_dx_ind   = 1
        
        if(lines->renal_dx_list = '') lines->renal_dx_list = notrim(build2('Renal DX: ', trim(n2.source_identifier, 3)))
        else                          lines->renal_dx_list = trim(concat(lines->renal_dx_list, '; ', n2.source_identifier), 3)
        endif

    of 'F19.10':

        lines->ivad_dx_ind   = 1
        
        if(lines->ivad_dx_list = '') lines->ivad_dx_list = notrim(build2('IVAD DX: ', trim(n2.source_identifier, 3)))
        else                         lines->ivad_dx_list = trim(concat(lines->ivad_dx_list, '; ', n2.source_identifier), 3)
        endif
        
    endcase


with nocounter



/**********************************************************************
DESCRIPTION:  Find encounter based information
      NOTES:  
***********************************************************************/
select into 'nl:'

  from encounter e
     , code_value acc_cv
     , code_value med_cv
  
 where e.encntr_id        = trigger_encntrid
 
   and acc_cv.code_value  = e.accommodation_cd
 
   and med_cv.code_value  = e.med_service_cd

detail
    if(acc_cv.display_key in ('*ICU*'))
        lines->icu_ind   = 1
        lines->icu_txt   = notrim(build2('ICU accommodation: ', acc_cv.display))
    endif
    
    if(cnvtupper(med_cv.display) in ('*BURN *', 'BURN'))
        lines->burn_ind   = 1
        lines->burn_txt   = notrim(build2('Burn med service: ', med_cv.display))
    endif
    
    if(med_cv.display_key in ('*TRANSPLANT*'))
        lines->transplant_ind   = 1
        lines->transplant_txt  = notrim(build2('Transplant med service: ', med_cv.display))
    endif

with nocounter


/***********************************************************************
DESCRIPTION: Find most recent results we are after
***********************************************************************/
select into 'nl:'
  from clinical_event ce
 where ce.encntr_id         =  trigger_encntrid
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   and ce.event_cd          in ( arrive_from_cd   , arrive_from_ed_cd)
order by ce.event_cd, ce.event_end_dt_tm desc
head ce.event_cd
    if(ce.result_val in ('Nursing home', 'Rehab Facility'))
        lines->long_term_ind = 1
        lines->long_term_txt = notrim(build2('Admit Source: ', uar_get_code_display(ce.event_cd)))
    endif

with nocounter


/***********************************************************************
DESCRIPTION: Looking for active inpatient meds
***********************************************************************/
select into 'nl:'
  from orders           o
     , order_ingredient oi

 where o.person_id           =  trigger_personid
   and o.template_order_flag in (0, 1)        ;Not sure if this is right.
   and o.orig_ord_as_flag    in (0)           ;from uCern:
                                              ; 0: InPatient Order
                                              ; 1: Prescription/Discharge Order
                                              ; 2: Recorded / Home Meds
                                              ; 3: Patient Owns Meds
                                              ; 4: Pharmacy Charge Only
                                              ; 5: Satellite (Super Bill) Meds.
   and o.catalog_type_cd     =  2516.00       ;Pharmacy
   and o.order_status_cd     not in (discon_cd, cancel_cd, voided_cd, comp_cd)
   and o.discontinue_ind     != 1
   
   and oi.order_id           = o.order_id
   and oi.action_sequence in (select max(oi1.action_sequence) 
                                from order_ingredient oi1 
                               where oi1.order_id=oi.order_id
                             )
   ;I probably need a with expand here, it is 330ish meds I think.
   and expand(idx, 1, antineo_codes->cnt, oi.catalog_cd, antineo_codes->code[idx]->catalog_cd)

order by o.hna_order_mnemonic

detail
    ;I think getting here is good enough to mark our ind... but we need to set up the message too...
    
    lines->antineo_ind = 1
    
    if(lines->antineo_txt = '') 
        lines->antineo_txt = notrim(build2('Antineo Med: '        , trim(uar_get_code_display(o.catalog_cd))))
    else                        
        lines->antineo_txt = notrim(build2(lines->antineo_txt, ';', trim(uar_get_code_display(o.catalog_cd))))
    endif
    
    
with nocounter, expand = 2





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
if(lines->vent_ind       = 1) call addScoreandMSG(lines->vent_res      , 1)
endif                                                                  
                                                                       
if(lines->mrsa_hx_ind    = 1) call addScoreandMSG(lines->mrsa_hx_list  , 1)
endif                                                                  
                                                                       
if(lines->renal_dx_ind   = 1) call addScoreandMSG(lines->renal_dx_list , 1)
endif                                                                  
                                                                       
if(lines->ivad_dx_ind    = 1) call addScoreandMSG(lines->ivad_dx_list  , 1)
endif                                                                  
                                                                       
if(lines->icu_ind        = 1) call addScoreandMSG(lines->icu_txt       , 1)
endif                                                                  
                                                                       
if(lines->burn_ind       = 1) call addScoreandMSG(lines->burn_txt      , 1)
endif

if(lines->transplant_ind = 1) call addScoreandMSG(lines->transplant_txt, 1)
endif

if(lines->long_term_ind  = 1) call addScoreandMSG(lines->long_term_txt , 1)
endif

if(lines->antineo_ind    = 1) call addScoreandMSG(lines->antineo_txt   , 1)
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


