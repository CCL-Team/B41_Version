/*************************************************************************
 Program Title: GUH Bilirubin Testing Report
 
 Object name:   14_peds_bilirubin_report
 Source file:   14_peds_bilirubin_report.prg
 
 Purpose:       Optimize the workflow in order to find the right
                population of testing the new transcutaneous bilirubin monitor 
                tool.
 
 Tables read:   
 
 Executed from: 
 
 Special Notes: They called it testing, this is not a test report.
                
                
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 05/23/2024 Michael Mayes        346731 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_peds_bilirubin_report:dba go
create program 14_peds_bilirubin_report:dba
 
prompt 
	  "Output to File/Printer/MINE" = "MINE"
	, "Start Date"                  = "SYSDATE"
	, "End Date"                    = "SYSDATE"
	, "Location"                    = VALUE(0.0) 

with OUTDEV, BEG_DT_TM, END_DT_TM, ORG_ID
 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt                    = i4
    1 qual[*]
        2 person_id          = f8
        2 encntr_id          = f8
        2 visit_dt_tm        = dq8
        2 visit_dt_txt       = vc
        2 name               = vc
        2 dob                = vc
        2 cur_age            = vc
        2 order_age          = vc
        2 mrn                = vc
        2 fin                = vc
        2 location           = vc
        2 birth_gest_age     = i4
        2 birth_gest_age_str = vc
        2 weight             = vc
        2 birth_weight       = vc
        2 res_name           = vc
        2 res                = vc
        2 res_dt_tm          = dq8
        2 res_dt_txt         = vc
        
)


record orgs(
    1 cnt        = i4
    1 qual[*]
        2 org_id = f8
        2 name   = vc
        
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare act_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'                    ))
declare mod_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'                  ))
declare auth_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'                      ))
declare altr_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'                   ))
                      
declare weight_cd       = f8  with protect, noconstant(uar_get_code_by('DISPLAYKEY', 72, 'WEIGHTDOSING'              ))
declare birth_weight_cd = f8  with protect, noconstant(uar_get_code_by('DISPLAYKEY', 72, 'BIRTHWEIGHTNONDOSING'      ))



/*
declare looper             = i4  with protect, noconstant(0)
*/

declare pos                = i4  with protect, noconstant(0)
declare idx                = i4  with protect, noconstant(0)

declare gest_weeks         = i4  with protect, noconstant(0)
declare gest_days          = i4  with protect, noconstant(0)
declare gest_temp          = vc  with protect, noconstant('')

 
/*************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('act_cd        :', act_cd        ))
call echo(build('mod_cd        :', mod_cd        ))
call echo(build('auth_cd       :', auth_cd       ))
call echo(build('altr_cd       :', altr_cd       ))
              
call echo(build('weight_cd     :', weight_cd     ))


 
/**********************************************************************
DESCRIPTION:  Gather Locations we are running for
      NOTES:  
***********************************************************************/
select into 'nl:'
       o.organization_id
     , cv.display
  
  from code_value   cv
     , location     l 
     , organization o
 
 where cv.cdf_meaning         =  'FACILITY'
   and cv.active_ind          =  1
   and cv.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and cv.display             in ( 'MGUH Peds Derm at Tenleytown'
                                 , 'MGUH Pediatric Development at Tenleytown'
                                 , 'MGUH Peds Endo at Tenleytown'
                                 , 'MGUH Peds GI at Tenleytown'
                                 , 'MGUH Peds ID at Tenleytown'
                                 , 'MGUH Peds Kids Mobile Van'
                                 , 'MedStar GUH Neonatal Followup Tenleytown'
                                 , 'MGUH Peds Nephrology at Tenleytown'
                                 , 'MGUH Peds Neurology at Tenleytown'
                                 , 'MGUH Peds Pulm at Potomac'
                                 , 'MGUH Peds Pulm at Tenleytown'
                                 , 'MGUH Peds at Tenleytown'
                                 )
                                 
   and l.location_cd          =  cv.code_value
   and l.end_effective_dt_tm  >= cnvtdatetime(curdate, curtime3)
   and l.active_ind           =  1 
   
   and o.organization_id      =  l.organization_id
   and o.end_effective_dt_tm  >= cnvtdatetime(curdate, curtime3)
   and o.active_ind           =  1
   and (   0                 in ($org_id)
        or o.organization_id in ($org_id)
       )
order by cv.display

detail
    pos       = orgs->cnt + 1
    orgs->cnt = pos
    stat = alterlist(orgs->qual, pos)
    
    orgs->qual[pos]->org_id = o.organization_id
    orgs->qual[pos]->name   = cv.display


with nocounter

call echorecord(orgs)


/**********************************************************************
DESCRIPTION:  Gather distinct patients using filters
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
     , orders       o
     , encounter    e
     , person       p
     , organization org
     , encntr_alias fin
     , encntr_alias mrn
     
 where ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   ;No time... being dumb.
   ;List may not be exhaustive, which spooks me a bit.
   and ce.event_cd          in (  823805555.00 ; AJCCV7 Liver-Bilirubin                  
                               , 2178273873.00 ; AJCCV8 HEP-LIV Bilirubin Level          
                               ,    5952261.00 ; Bili Direct Ped                         
                               ,    5952265.00 ; Bili Indirect Ped                       
                               ,    5101521.00 ; Bili Tot Ped                            
                               ,   30070757.00 ; Bilirubin Direct                        
                               , 1283459581.00 ; Bilirubin Direct - Transcribed          
                               ,   30070761.00 ; Bilirubin Direct Fluid                  
                               , 1283462207.00 ; Bilirubin Direct Ref Range - Transcribed
                               , 1157715767.00 ; Bilirubin Done at Discharge             
                               ,   30070765.00 ; Bilirubin Indirect                      
                               ,   30070769.00 ; Bilirubin Neonatal Panel                
                               ,  823591965.00 ; Bilirubin POC Test Comments             
                               , 3917250435.00 ; Bilirubin Score (mg/dl)                 
                               ,  823669537.00 ; Bilirubin Urine Dipstick                
                               , 1817428345.00 ; Bilirubin monitoring as ordered         
                               , 1817516723.00 ; Bilirubin within specified parameters   
                               , 2240598125.00 ; Calculi, Ur Bilirubin                   
                               , 2240598753.00 ; Calculi, Ur Calcium Bilirubinate        
                               ,   30071658.00 ; Cord Bilirubin                          
                               ,   75072601.00 ; Direct Bilirubin                        
                               ,   75072793.00 ; Indirect Bilirubin                      
                               , 1809604753.00 ; Neonatal Hyperbilirubinemia Plan of Care
                               ,  823591585.00 ; POC Bilirubin Test Comments             
                               ,  823591595.00 ; POC Bilirubin Total                     
                               ,  104260561.00 ; POC Transcutaneous Bilirubin            
                               ,    3006515.00 ; POC Urinalysis Bilirubin                
                               , 2213615647.00 ; TRANSCUTANEOUS BILIRUBIN CHG            
                               ,   74938269.00 ; Total Bilirubin                         
                               ,  101876203.00 ; Transcutaneous Bilirubin at Bedside     
                               ,  196546673.00 ; UA. Bilirubin                           
                               ,   30070769.00 ; Bilirubin Neonatal Panel
                               )
   
   and o.order_id           =  ce.order_id
   
   and e.reg_dt_tm              >= cnvtdatetime($beg_dt_tm)
   and e.reg_dt_tm              <= cnvtdatetime($end_dt_tm)
   and e.active_ind             =  1
   and (   (o.originating_encntr_id > 0 and e.encntr_id = o.originating_encntr_id)
        or (o.originating_encntr_id = 0 and e.encntr_id = o.encntr_id)
       )
   and expand(idx, 1, orgs->cnt, e.organization_id, orgs->qual[idx]->org_id)
   
   and p.person_id              =  e.person_id
   and p.active_ind             =  1
   and datetimediff(o.orig_order_dt_tm, p.birth_dt_tm) < 31
 
   and org.organization_id        =  e.organization_id
   and org.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)
   and org.active_ind             =  1
  
   and fin.encntr_id            =  e.encntr_id
   and fin.encntr_alias_type_cd =  1077.000000
   and fin.active_ind           =  1
   and fin.beg_effective_dt_tm  <  cnvtdatetime(curdate, curtime3)
   and fin.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)
 
   and mrn.encntr_id            =  e.encntr_id
   and mrn.encntr_alias_type_cd =  1079.000000
   and mrn.active_ind           =  1
   and mrn.beg_effective_dt_tm  <  cnvtdatetime(curdate, curtime3)
   and mrn.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)
    
order by e.reg_dt_tm, p.name_last_key, p.person_id, ce.event_end_dt_tm desc, ce.event_cd

detail
    pos                           = data->cnt + 1
    data->cnt                     = pos
    stat                          = alterlist(data->qual, pos)
    
    data->qual[pos]->person_id    = p.person_id
    data->qual[pos]->encntr_id    = e.encntr_id    
    
    data->qual[pos]->visit_dt_tm  = e.reg_dt_tm
    data->qual[pos]->visit_dt_txt = format(e.reg_dt_tm, '@SHORTDATE')

    data->qual[pos]->name         = trim(p.name_full_formatted, 3)
    data->qual[pos]->dob          = format(p.birth_dt_tm, '@SHORTDATE')
    data->qual[pos]->cur_age      = trim(cnvtage(p.birth_dt_tm), 3)
    data->qual[pos]->order_age    = trim(cnvtage(p.birth_dt_tm, o.orig_order_dt_tm, 0), 3)

    data->qual[pos]->location     = trim(org.org_name, 3)

    data->qual[pos]->mrn          = trim(mrn.alias, 3)
    data->qual[pos]->fin          = trim(fin.alias, 3)
    
    data->qual[pos]->res_name     = trim(uar_get_code_display(ce.event_cd, 3))
    data->qual[pos]->res_dt_tm    = ce.event_end_dt_tm
    data->qual[pos]->res_dt_txt   = format(ce.event_end_dt_tm, '@SHORTDATETIME')
    data->qual[pos]->res          = notrim(build2( trim(ce.result_val, 3)
                                             , nullcheck( build2(' '
                                                                ,trim(uar_get_code_display(ce.result_units_cd), 3)
                                                                )
                                                        , ' '
                                                        , nullind(ce.result_units_cd)
                                                        )
                                             )
                                      )
    
with nocounter 



/**********************************************************************
DESCRIPTION:  Find Gest Ages
      NOTES:  Borrowing ideas from 1_ops_nb_birth_calc_04
***********************************************************************/
select into 'nl:'

  from person_patient pp
     , (dummyt d with seq = data->cnt)
     
  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->person_id >  0
     
  join pp
   where pp.person_id                 =  data->qual[d.seq]->person_id
     and pp.gest_age_at_birth         >  0

detail

    gest_days  = mod(pp.gest_age_at_birth, 7)
    gest_weeks = floor(pp.gest_age_at_birth / 7)
    
    data->qual[d.seq]->birth_gest_age     = pp.gest_age_at_birth
    
    ; I know we are doing wonky stuff with spaces here... trying to aim for easy logic below, and
    ; clean it up with a trim later.
    gest_temp = ' '

    if    (gest_weeks = 1) gest_temp = concat(gest_temp, trim(cnvtstring(gest_weeks), 3), ' week')
    elseif(gest_weeks > 1) gest_temp = concat(gest_temp, trim(cnvtstring(gest_weeks), 3), ' weeks')
    endif

    if    (gest_days  = 1) gest_temp = concat(gest_temp, ' ', trim(cnvtstring(gest_days), 3), ' day')
    elseif(gest_days  > 1) gest_temp = concat(gest_temp, ' ', trim(cnvtstring(gest_days), 3), ' days')
    endif

    data->qual[d.seq]->birth_gest_age_str = trim(gest_temp, 3)
    

with nocounter


/**********************************************************************
DESCRIPTION:  Find Weight
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->encntr_id >  0
  
  join ce
   where ce.encntr_id         =  data->qual[d.seq]->encntr_id
     and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
     and ce.event_cd          =  weight_cd 
order by ce.encntr_id, ce.event_end_dt_tm desc

head ce.encntr_id
    
    data->qual[d.seq]->weight = notrim(build2( trim(ce.result_val, 3)
                                             , nullcheck( build2(' '
                                                                ,trim(uar_get_code_display(ce.result_units_cd), 3)
                                                                )
                                                        , ' '
                                                        , nullind(ce.result_units_cd)
                                                        )
                                             )
                                      )

    
with nocounter


/**********************************************************************
DESCRIPTION:  Find Birth Weight
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
     , (dummyt d with seq = data->cnt)
  
  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->person_id >  0
  
  join ce
   where ce.person_id         =  data->qual[d.seq]->person_id
     and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
     and ce.event_cd          in ( 823822529.00  ; BIRTHWEIGHT
                                 , 2207845141.00 ; BIRTHWEIGHT
                                 , 712070.00     ; BIRTHWEIGHTNONDOSING
                                 , 2243753041.00 ; BIRTHWEIGHTNONDOSING
                                 )
order by ce.encntr_id, ce.event_end_dt_tm desc

head ce.encntr_id
    
    data->qual[d.seq]->birth_weight = notrim(build2( trim(ce.result_val, 3)
                                                   , nullcheck( build2(' '
                                                                      ,trim(uar_get_code_display(ce.result_units_cd), 3)
                                                                      )
                                                              , ' '
                                                              , nullind(ce.result_units_cd)
                                                              )
                                                   )
                                            )

    
with nocounter


 
 
 
;Presentation time
if (data->cnt > 0)
    
    select into $outdev
           LOCATION          = trim(substring(1,  75, data->qual[d.seq].location           ))
         , VISIT_DT          = trim(substring(1,  15, data->qual[d.seq].visit_dt_txt       ))
         , MRN               = trim(substring(1,  15, data->qual[d.seq].mrn                ))
         , FIN               = trim(substring(1,  15, data->qual[d.seq].fin                ))
         , NAME              = trim(substring(1, 100, data->qual[d.seq].name               ))
         , DOB               = trim(substring(1,  10, data->qual[d.seq].dob                ))
         , CUR_AGE           = trim(substring(1,  10, data->qual[d.seq].cur_age            ))
         , AGE_AT_ORD        = trim(substring(1,  10, data->qual[d.seq].order_age          ))
         , ORD_WEIGHT        = trim(substring(1,  25, data->qual[d.seq].weight             ))
         , GEST_AGE_AT_BIRTH = trim(substring(1,  25, data->qual[d.seq].birth_gest_age_str ))
         , BIRTH_WEIGHT      = trim(substring(1,  25, data->qual[d.seq].birth_weight       ))
         , LAB_NAME          = trim(substring(1,  50, data->qual[d.seq].res_name           ))
         , RESULT            = trim(substring(1,  20, data->qual[d.seq].res                ))
         , RESULT_DT         = trim(substring(1,  20, data->qual[d.seq].res_dt_txt         ))
         
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
 
 

