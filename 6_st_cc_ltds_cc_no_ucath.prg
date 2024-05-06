/*************************************************************************
 Program Title:   CC Tubes Drains Except Urine Cath

 Object name:     6_st_cc_ltds_cc_no_ucath
 Source file:     6_st_cc_ltds_cc_no_ucath.prg

 Purpose:         

 Tables read:     

 Executed from:

 Special Notes:   This has a potential to be a beast... at least that is 
                  what they told me when I picked up Tameka's 
                  6_st_cc_ltds_body_sys, and worked the last bit of it.
                  
                  They wanted to save this one until after that completed.
                  Then it got accidentally canceled a couple of times.
                  
                  In any case here we are.
                  
                  I'm supposed to emulate what we were doing in that 
                  first ST.

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA     Comment
--- ---------- -------------------- -------- -----------------------------
001 04/22/2022 Michael Mayes        229806   Initial release
002 08/06/2023 Michael Mayes        239440   Change to allow Ent Tube of Other.
*************END OF ALL MODCONTROL BLOCKS* *******************************/
drop   program 6_st_cc_ltds_cc_no_ucath:dba go
create program 6_st_cc_ltds_cc_no_ucath:dba


%i cust_script:0_rtf_template_format.inc

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/


record reply(
   1 text = vc
      1 status_data
         2 status               = c1
         2 subeventstatus[1]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)

free record 3208905_request
record 3208905_request(
    1 prsnl_id           = f8
    1 encounter_id       = f8
    1 relationship_cd    = f8
)


free record 3208905_reply
record 3208905_reply(
    1 lines [*]
        2 type                        = vc
        2 type_display                = vc
        2 label_display               = vc
        2 insertion_date_time         = vc
        2 ce_dynamic_label_id         = f8
        2 results [*]
            3 event_end_dt_tm         = vc
            3 event_set_display       = vc
            3 value_display           = vc
            3 unit_of_measure_display = vc
            3 numeric_value           = vc
            3 modified_ind            = i2
            3 comment                 = vc
            3 normalcy                = vc
            3 result_type             = vc
            3 overdue_type            = vc
        2 overdue_check               = vc
    1 tubesAndDrains [*]
        2 type                        = vc
        2 type_display                = vc
        2 label_display               = vc
        2 insertion_date_time         = vc
        2 ce_dynamic_label_id         = f8
        2 results [*]
            3 event_end_dt_tm         = vc
            3 event_set_display       = vc
            3 value_display           = vc
            3 unit_of_measure_display = vc
            3 numeric_value           = vc
            3 modified_ind            = i2
            3 comment                 = vc
            3 normalcy                = vc
            3 result_type             = vc
            3 overdue_type            = vc
        2 overdue_check               = vc
    1 discontinued [*]
        2 type                        = vc
        2 type_display                = vc
        2 label_display               = vc
        2 insertion_date_time         = vc
        2 ce_dynamic_label_id         = f8
        2 results [*]
            3 event_end_dt_tm         = vc
            3 event_set_display       = vc
            3 value_display           = vc
            3 unit_of_measure_display = vc
            3 numeric_value           = vc
            3 modified_ind            = i2
            3 comment                 = vc
            3 normalcy                = vc
            3 result_type             = vc
            3 overdue_type            = vc
        2 overdue_check               = vc
    1 status_data
        2 status                      = c1
        2 subeventstatus [*]
            3 OperationName           = c25
            3 OperationStatus         = c1
            3 TargetObjectName        = c25
            3 TargetObjectValue       = vc
) 


record ltdInfo(
    1 info [*]
        2 sort_pos            = i4
        2 ce_dynamic_label_id = f8
        2 label_name          = vc
        2 cent_dia_loc        = vc
        2 location            = vc
        2 duration            = vc
        2 durationVal         = f8
        2 display             = vc
)

 
free record displayQual
record displayQual(
    1 line_cnt      = i4
    1 display_line  = vc
    1 line_qual [*]
        2 disp_line = vc 
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header              = vc  with protect, noconstant('')
declare tmp_str             = vc  with protect, noconstant('')

declare act_cd              = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'ACTIVE'                           ))
declare mod_cd              = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'MODIFIED'                         ))
declare auth_cd             = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'AUTH'                             ))
declare alt_cd              = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'ALTERED'                          ))

declare modifiedCd               = f8 with protect,   constant(mod_cd ) ;TODO this is to play nice with copy paste code TODO refact
declare authverifyCd             = f8 with protect,   constant(auth_cd) ;TODO this is to play nice with copy paste code TODO refact
declare placeholderCd            = f8 with protect,   constant(uar_get_code_by("MEANING", 53, "PLACEHOLDER" ))

declare resultVal                = vc  with protect, noconstant('')

declare lineIdx                  = i4  with protect, noconstant(0)
declare lineCnt                  = i4  with protect, noconstant(0)
declare tubeIdx                  = i4  with protect, noconstant(0)
declare tubeCnt                  = i4  with protect, noconstant(0)

declare dispCnt                  = i4  with protect, noconstant(0)

declare resultIdx                = i4  with protect, noconstant(0)

declare includeLineInd           = i2  with protect, noconstant(0)
declare includeDuration          = i2  with protect, noconstant(0)

declare etaccessTypeCd           = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Endotracheal Tube Type:"    ))
declare etinsertiondatetimeCd    = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "TIMEOFINTUBATION"           ))

declare trachaccessTypeCd        = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Tracheostomy Type:"         ))
declare trachSizeCd              = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Tracheostomy Tube Size:"    ))
declare trachSizeOtherText       = vc  with protect, noconstant('')
declare trachBlankOtherInd       = i2  with protect, noconstant(0)  ;0 No other;1 - Blank other;2 - Filled other

declare pharaccessTypeCd           = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Pharyngeal Airway Type:"    ))
declare pharactTypeCd              = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Pharyngeal Airway Activity:"))
declare pharinsertiondatetimeCd    = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                                                 , "Pharyngeal Airway Insert Date/Time: "        ))

declare chestTypeCd              = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Chest Tube Type:"           ))
declare chestLatCd               = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Chest Tube Laterality:"     ))
declare chestInstanceCd          = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Chest Tube Instance:"       ))
declare chestLocCd               = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Chest Tube Location:"       ))
declare chestActCd               = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Chest Tube Activity:"       ))


declare drainTypeCd              = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Surgical Drain, Tube Type:"    ))
declare drainLatCd               = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                                               , "Surgical Drain, Tube Laterality:"               ))
declare drainLat2Cd              = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                                               , "Surgical Drain, Tube Laterality"               ))
declare drainInstanceCd          = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Surgical Drain, Tube Instance:"))
declare drainLocCd               = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Surgical Drain Tube Location:" ))
declare drainLocDescCd           = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                                               , "Surgical Drain, Tube Location Desc:"            ))
declare drainActCd               = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Surgical Drain, Tube Activity:"))

declare npwtLocCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "NPWT Location:"))
declare npwtLatCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "NPWT Laterality:"))
declare npwtLocDescCd            = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "NPWT Location Description:"))

declare icptypeCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "ICP Device Type"))
declare icpInsCd                 = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                                               , "ICP Device Insertion Date/Time:"))
declare icpLocCd                 = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "ICP Device Location"))


declare autoLocCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Autotransfusion Drain Location"))
declare autoLatCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                                               , "Autotransfusion Drain Laterality"))
declare autoActCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Autotransfusion Activity"))

declare entInstanceCd            = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Enteral Tube Instance:"))
declare entTypeCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Enteral Tube Type::"))
declare inst_holder              = vc  with protect, noconstant('')

declare giTypeCd                 = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "GI Ostomy Type:"))
declare giInstanceCd             = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "GI Ostomy Instance:"))

declare fmsTypeCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "FMS Type:"))
declare fmsActCd                 = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "FMS Activity"))
declare fmsInsCd                 = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72
                                                               , "FMS Initial Insertion Date THIS tube"))
declare fmsDCCd                  = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "FMS Discontinue Date/Time"))
declare fmsDCInd                 = i2  with protect, noconstant(0)
declare fmsDur                   = i4  with protect, noconstant(0)
declare fmdDurTxt                = vc  with protect, noconstant('')

declare uroTypeCd                = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Urostomy/Nephrostomy Type:"))
declare uroInstanceCd            = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Urostomy/Nephrostomy Instance:"))

declare pos = i4 with protect, noconstant(0)  ;002
declare idx = i4 with protect, noconstant(0)  ;002

/**************************************************************
; DVDev Start Coding
**************************************************************/
;First, Tameka was using a service for the gathering of all this stuff... I should try and do that as well.

;populate reqeust sent to request 3208905
set 3208905_request->encounter_id    = e_id

set 3208905_request->prsnl_id        = reqinfo->updt_id
set 3208905_request->relationship_cd = 441.00  ;wowie... she just did that eh.

set stat = tdbexecute(600005, 3202004, 3208905, "REC", 3208905_request, "REC", 3208905_reply)


set lineCnt    = size(3208905_reply->lines,5)
set newLineCnt = 0
set tubeCnt    = size(3208905_reply->tubesAndDrains,5)
set newTubeCnt = 0


for(lineIdx = 1 to lineCnt)
    if(3208905_reply->lines[lineIdx].type = 'LINE')
        set includeLineInd  = 1
        set resultVal = ''

        if(3208905_reply->lines[lineIdx].type_display in ('Intracranial/Lumbar Pressure Devices'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results,5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in( 'Discontinued'
                                                                                    , 'Self removed'
                                                                                    , 'Unintentionally removed'
                                                                                    )
                   or
                   3208905_reply->lines[lineIdx].results[resultIdx].event_set_display in ( 
                                                        'ICP Device Discontinuation Date/Time:')
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 1
 
                ;set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].LABEL_DISPLAY
                
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (icptypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ;This other shouldn't happen, but leaving it... it's the same as the bulk of the rest of the code.
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                        
                    ltdInfo->info[newLineCnt].label_name = trim(resultVal,3)
                    

                with nocounter
 
                ;obtain duration documented as event_end_dt_tm
                select into 'nl:'
                  from clinical_event ce
                     , ce_date_result cdr
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( icpInsCd
                                                   )
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                  join cdr
                   where cdr.event_id = outerjoin(ce.event_id)
                     and (   cdr.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
                          or cdr.valid_until_dt_tm is null
                         )
                order by ce.event_cd, ce.event_start_dt_tm desc
                head report
                    duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,1))
                    duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,3))
                    duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,4))
                    
                    hours_diff = (duration_hours - (duration_days * 24 ))
                    mins_diff  = (duration_mins  - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
 
                    ltdInfo->info[newLineCnt].durationVal = duration_days
                    if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                    elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                    else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                    endif
 
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0)
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
            endif
        
        endif
        
        if(newLineCnt > 0)
            ;obtain location information
            select into 'nl:'
                   sortOrder = if(
                                      ce.event_cd in ( icpLocCd
                                                     )
                                     )
                                   2
                               endif
              from clinical_event ce
                 , ce_date_result cdr
              plan ce
               where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                 and ce.event_cd            in (icpLocCd
                                               )
                 and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                 and ce.result_status_cd    in (modifiedCd, authverifyCd)
                 and ce.event_class_cd      != placeholderCd
            join cdr
                where cdr.event_id = outerjoin(ce.event_id)
                  and (cdr.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
                       or
                       cdr.valid_until_dt_tm is null
                      )
            order by sortOrder, ce.event_cd
            head report
                locCnt = 0
            
            head ce.event_cd
                locCnt    = locCnt + 1
                ;TODO the space after other fixes PIV, but might break others?
                resultVal = replace(trim(ce.result_val,3),'Other: ','')
            
                
                ;002: Adding the check to see if location is filled.  It shouldn't be except for my changes to dialysis and central
                ;lines above to move the left rights into it.
                if(locCnt = 1)
                    ltdInfo->info[newLineCnt].location = trim(resultVal, 3)
                else
                    ltdInfo->info[newLineCnt].location = concat(ltdInfo->info[newLineCnt].location, ' ', trim(resultVal, 3))
                endif
            
            with nocounter
        
        
            if(findstring(':',ltdInfo->info[newLineCnt].label_name,1));don't need the extra :
                
                if(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0)
                    set ltdInfo->info[newLineCnt].display = build2( ltdInfo->info[newLineCnt].label_name       , " "
                                                                  , trim(ltdInfo->info[newLineCnt].location,3) , "  "
                                                                  , trim(ltdInfo->info[newLineCnt].duration,3))
                else
                    set ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, " "
                                                                  , trim(ltdInfo->info[newLineCnt].duration,3))
                endif
            else
                if(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0
                   and
                   textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0)
                    set ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, ": ",
                                                trim(ltdInfo->info[newLineCnt].location,3)
                                                ,"  ",trim(ltdInfo->info[newLineCnt].duration,3))
                
                elseif(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0 and
                                                textlen(trim(ltdInfo->info[newLineCnt].duration,3)) = 0)
                    set ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, ": ",
                                                trim(ltdInfo->info[newLineCnt].location,3))
        
                
                elseif(textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0)
                    set ltdInfo->info[newLineCnt].display = build2( ltdInfo->info[newLineCnt].label_name       , ":  "
                                                                  , trim(ltdInfo->info[newLineCnt].duration,3))
                
                else
                    set ltdInfo->info[newLineCnt].display = ltdInfo->info[newLineCnt].label_name
                endif
            endif
        endif
        
    endif
endfor


for(tubeIdx = 1 to tubeCnt)
    if(3208905_reply->tubesAndDrains[tubeIdx].type = 'TUBEDRAIN')
        set includeLineInd  = 1
        set resultVal = ''
        set includeDuration = 1


        if(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Endotracheal Tube'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( '*Extubated*'
                                                                                    )
                   or
                   3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].event_set_display in ( 
                                                        'Endotracheal Extubation Date/Time:')
                  )
                    set includeLineInd  = 0
                endif
                
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in('*Present on arrival to hospital*'))
                    set includeDuration  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 2
 
                ;if(3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Central Line:')
                ;    set 3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Central Line'
                ;endif
 
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
 
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (etaccessTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ;This other shouldn't happen, but leaving it... it's the same as the bulk of the rest of the code.
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other but
                    ;notput contents in
                    if(trim(resultVal,3) = 'Laryngeal Mask Airway (LMA)')
                        
                        ltdInfo->info[newLineCnt].label_name = replace(trim(resultVal,3), ' (LMA)', '')
                        
                    elseif(textlen(resultVal) > 0)
                        
                        ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (',trim(resultVal,3),') ')
                    
                    else
                        
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    
                    endif
                
                with nocounter
 
                ;obtain duration documented as event_end_dt_tm
                select into 'nl:'
                  from clinical_event ce
                     , ce_date_result cdr
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( etinsertiondatetimeCd
                                                   )
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                  join cdr
                   where cdr.event_id = outerjoin(ce.event_id)
                     and (   cdr.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
                          or cdr.valid_until_dt_tm is null
                         )
                order by ce.event_cd, ce.event_start_dt_tm desc
                head report
                    if(includeDuration = 1)
                        duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,1))
                        duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,3))
                        duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,4))
                        
                        hours_diff = (duration_hours - (duration_days * 24 ))
                        mins_diff  = (duration_mins  - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
     
                        ltdInfo->info[newLineCnt].durationVal = duration_days
                        if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                        elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                        else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                        endif
     
                        if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0
                           and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0)
                            ;only add : when duration exists
                            ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                        endif
                    endif
                with nocounter
            endif
        
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Tracheostomy'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Tube removed'
                                                                                             , 'Tube self removed'
                                                                                             , 'Tube unintentionally removed'
                                                                                             ) 
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            ;This is a weird one... we just want the type... no duration... no specific value to let us in...
            ;Just Tracheostomy and the type.  Handling this much differently than others.
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 3
 
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
 
                ; this does some funny stuff if size isn't documented...  it places the other text
                ; in the size ce... so I am trying something clever.
                set trachBlankOtherInd = 0
                set trachSizeOtherText = ''
                
                select into 'nl:'
                from clinical_event ce
                   , ce_string_result csr
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (trachaccessTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                join csr
                    where csr.event_id           =  ce.event_id
                      and csr.valid_until_dt_tm  >  cnvtdatetime(curdate, curtime3)
                order by ce.event_cd
                detail
                    trachSizeOtherText = trim(replace(trim(csr.string_result_text,3),'Other:',''),3)
                    
                    if(textlen(trachSizeOtherText) > 0)
                        trachBlankOtherInd = 2
                    else
                        trachBlankOtherInd = 1
                    endif
                    
                    call echo(build("'", trachSizeOtherText, "'"))
                with nocounter
                
                
                if(trachBlankOtherInd = 1)
                    ;Find the size text... it's actually the other text.
                    select into 'nl:'
                    from clinical_event ce
                    plan ce
                        where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                            and ce.event_cd          in (trachSizeCd)
                            and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                            and ce.result_status_cd  in (modifiedCd, authverifyCd)
                            and ce.event_class_cd    != placeholderCd
                    order by ce.event_cd
                    head report
                        trachSizeOtherText = trim(ce.result_val,3)
                    
                    with nocounter
                endif
                
                
                ;obtain access type ... weird stuff above.
                ;We did work to determine if we had text in an other... if so... we want to replace the other text with it instead.
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (trachaccessTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    case(trachBlankOtherInd)
                    of 0:  resultVal = trim(ce.result_val,3)
                    of 1:  resultVal = trim(replace(trim(ce.result_val,3),'Other:', trachSizeOtherText),3)
                    of 2:  resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    endcase
                    
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other but
                    ;notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (',trim(resultVal,3),') ')
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                
                with nocounter
 
            endif
            
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Pharyngeal Airway'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Tube removed'
                                                                                             , 'Tube self removed'
                                                                                             , 'Unplanned removal'
                                                                                             ) 
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 4
 
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
 
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (pharaccessTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ;This other shouldn't happen, but leaving it... it's the same as the bulk of the rest of the code.
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other but
                    ;notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (',trim(resultVal,3),') ')
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                
                with nocounter
 
                ;obtain duration documented as event_end_dt_tm
                select into 'nl:'
                  from clinical_event ce
                     , ce_date_result cdr
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( pharinsertiondatetimeCd
                                                   )
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                  join cdr
                   where cdr.event_id = outerjoin(ce.event_id)
                     and (   cdr.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
                          or cdr.valid_until_dt_tm is null
                         )
                order by ce.event_cd, ce.event_start_dt_tm desc
                head report
                    duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,1))
                    duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,3))
                    duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,4))
                    
                    hours_diff = (duration_hours - (duration_days * 24 ))
                    mins_diff  = (duration_mins  - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
 
                    ltdInfo->info[newLineCnt].durationVal = duration_days
                    if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                    elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                    else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                    endif
 
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0)
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
                
                ;This is unique to this one... if we didn't find a documented date... we use the documentation date
                if(textlen(trim(ltdInfo->info[newLineCnt].duration,3)) = 0)
                    ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                    select into 'nl:'
                      from clinical_event ce
                      plan ce
                       where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                         and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                         and ce.result_status_cd    in (modifiedCd, authverifyCd)
                         and ce.event_class_cd      != placeholderCd
                         ;Even more different... I have to to use earliest insertion event to show a duration.  
                         ;Going to try and be dumb
                         and ce.event_cd            =  pharactTypeCd
                         and ce.result_val          in ( 'Continued/Assessed'
                                                       , 'Tube inserted'
                                                       , 'Repositioned'
                                                       )
                    order by ce.event_end_dt_tm
                    head report
                        duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,1))
                        duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,3))
                        duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,4))
                        hours_diff     = (duration_hours - (duration_days * 24 ))
                        mins_diff      = (duration_mins - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
                    
                        ltdInfo->info[newLineCnt].durationVal = duration_days
                        if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                        elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                        else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                        endif
                    
                        if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                           and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                          )
                            ;only add : when duration exists
                            ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                        endif
                    with nocounter
                endif
            endif
        
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Chest Tubes'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Discontinued'
                                                                                             , 'Self removed'
                                                                                             , 'Unintentionally removed'
                                                                                             )

                  )
                    set includeLineInd  = 0
                endif

            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 5
 
                if(3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Chest Tubes')
                    set 3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Chest Tube'
                endif
 
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
 
                ;obtain instance 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (chestInstanceCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3), ' '
                                                                 , trim(ce.result_val,3))

                
                with nocounter
 
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (chestTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ;This other shouldn't happen, but leaving it... it's the same as the bulk of the rest of the code.
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other but
                    ;notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (',trim(resultVal,3),') ')
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                
                with nocounter
 
                ;obtain duration documented as documentation date time
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                     and ce.event_cd            =  chestActCd
                     and ce.result_val          not in ( 'Discontinued'
                                                       , 'Self removed'
                                                       , 'Unintentionally removed'
                                                       )
                order by ce.event_end_dt_tm
                head report
                    duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,1))
                    duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,3))
                    duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,4))
                    hours_diff     = (duration_hours - (duration_days * 24 ))
                    mins_diff      = (duration_mins - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
                
                    ltdInfo->info[newLineCnt].durationVal = duration_days
                    if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                    elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                    else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                    endif
                
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                      )
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
            endif
            
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Surgical Drains/Tubes'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Discontinued'
                                                                                             , 'Self removed'
                                                                                             , 'Unintentionally removed'
                                                                                             )
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 6
 
                if(3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Surgical Drains/Tubes')
                    set 3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Surgical Drain'
                endif
 
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
 
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (drainTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ;This other shouldn't happen, but leaving it... it's the same as the bulk of the rest of the code.
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other but
                    ;notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (',trim(resultVal,3),') ')
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                
                with nocounter
                
                ;obtain instance 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (drainInstanceCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3), ' '
                                                                 , trim(ce.result_val,3))

                
                with nocounter
 
                ;obtain duration documented as documentation date time
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                     ;Even more different... I have to to use earliest insertion event to show a duration.  Going to try and be dumb
                     and ce.event_cd            =  drainActCd
                     and ce.result_val          in ( 'Inserted'
                                                   , 'Assessed'
                                                   , 'Flushed'
                                                   )
                     

                order by ce.event_end_dt_tm
                head report
                    duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,1))
                    duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,3))
                    duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,4))
                    hours_diff     = (duration_hours - (duration_days * 24 ))
                    mins_diff      = (duration_mins - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
                
                    ltdInfo->info[newLineCnt].durationVal = duration_days
                    if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                    elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                    else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                    endif
                
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                      )
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
            endif
        
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Autotransfusion/Drain Re-infusion'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( '*Drain Removed*'
                                                                                             )
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 8
 
                if(3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Autotransfusion/Drain Re-infusion')
                    set 3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Autotransfusion Drain'
                endif
 
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
 
                ;obtain duration documented as documentation date time
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                     ;Even more different... I have to to use earliest insertion event to show a duration.  Going to try and be dumb
                     and ce.event_cd            =  autoActCd
                     and ce.result_val          not in ( '*Drain Removed*'
                                                       )
                     

                order by ce.event_end_dt_tm
                head report
                    duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,1))
                    duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,3))
                    duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,4))
                    hours_diff     = (duration_hours - (duration_days * 24 ))
                    mins_diff      = (duration_mins - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
                
                    ltdInfo->info[newLineCnt].durationVal = duration_days
                    if(duration_days < 1)     ltdInfo->info[newLineCnt].duration = '< 1 Day'
                    elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                    else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                    endif
                
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                      )
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
            endif
            
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Enteral Tube'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Discontinued'
                                                                                             , 'Stoma Take Down'
                                                                                             )
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 9
 
                ;if(3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Surgical Drains/Tubes')
                ;    set 3208905_reply->tubesAndDrains[tubeIdx].type_display = 'Surgical Drain'
                ;endif
                
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
                
                ;We got funny stuff going on here... 
                ;We don't want to show Enternal Tube... we want to show the type as the name.
                ;But we want them sorted together...
                ;So I'm going to act like that is the name for now... 
                ;Then at display time, replace out that text.
 
 
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (entTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    resultVal = trim(ce.result_val,3)
                    
                    ;We have some goofy renaming we want to do too.
                    resultVal = trim(replace(resultVal,'Blakemore'                    ,'Blakemore Tube'         ),3)
                    resultVal = trim(replace(resultVal,'Gastro-Jejunostomy Tube (GJT)','Gastro-Jejunostomy Tube'),3)
                    resultVal = trim(replace(resultVal,'Gastrostomy Tube (GT)'        ,'Gastrostomy Tube'       ),3)
                    resultVal = trim(replace(resultVal,'Jejunostomy Tube (JT)'        ,'Jejunostomy Tube'       ),3)
                    resultVal = trim(replace(resultVal,'Mickey Button (GT)'           ,'Mickey Button'          ),3)
                    resultVal = trim(replace(resultVal,'Minnesota'                    ,'Minnesota Tube'         ),3)
                    resultVal = trim(replace(resultVal,'Nasoduodenal (ND)'            ,'Nasoduodenal Tube'      ),3)
                    resultVal = trim(replace(resultVal,'Nasogastric (NG)'             ,'Nasogastric Tube'       ),3)
                    resultVal = trim(replace(resultVal,'Nasojejunal (NJ)'             ,'Nasojejunal Tube'       ),3)
                    resultVal = trim(replace(resultVal,'Oroduodenal (OD)'             ,'Oroduodenal Tube'       ),3)
                    resultVal = trim(replace(resultVal,'Orogastric (OG)'              ,'Orogastric Tube'        ),3)
                    resultVal = trim(replace(resultVal,'Rectal'                       ,'Rectal Tube'            ),3)
                    
                    
                    
                    
                    ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                 , ' ',trim(resultVal,3),' ')
                    
                    
                    ;if(findstring('Other:', trim(ltdInfo->info[newLineCnt].label_name,3)) > 
                    ;                       size(trim(ltdInfo->info[newLineCnt].label_name,3), 3) - 6)
                    ;    ltdInfo->info[newLineCnt].label_name = replace(ltdInfo->info[newLineCnt].label_name
                    ;                                                  , 'Other:'
                    ;                                                  , 'Other'
                    ;                                                  )
                    ;elseif(findstring('Other:', trim(ltdInfo->info[newLineCnt].label_name,3)) > 0)
                    ;    ltdInfo->info[newLineCnt].label_name = replace(ltdInfo->info[newLineCnt].label_name
                    ;                                                  , 'Other:'
                    ;                                                  , ''
                    ;                                                  )
                    ;
                    ;endif
                    
                with nocounter
                
                ;obtain instance 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (entInstanceCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3), ' '
                                                                 , trim(ce.result_val,3))

                
                with nocounter

            endif
            
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('GI Ostomy'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Take-down/Reversal'
                                                                                             )
                  )
                    set includeLineInd  = 0
                endif
            endfor
 
            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 10
 
                
                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->tubesAndDrains[tubeIdx].type_display
                
 
                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (giTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ;This other shouldn't happen, but leaving it... it's the same as the bulk of the rest of the code.
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other but
                    ;notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (',trim(resultVal,3),') ')
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                    
                with nocounter
                
                ;obtain instance 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (giInstanceCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3), ' '
                                                                 , trim(ce.result_val,3))

                
                with nocounter

            endif
        
        elseif(3208905_reply->tubesAndDrains[tubeIdx].type_display in ('Urostomy/Nephrostomy:'))
            ;check to see if result of 'Extubated' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->tubesAndDrains[tubeIdx].results,5))
                if(3208905_reply->tubesAndDrains[tubeIdx].results[resultIdx].value_display in( 'Discontinued'
                                                                                             , 'Self removed'
                                                                                             , 'Unintentionally removed'
                                                                                             )
                  )
                    set includeLineInd  = 0
                endif
            endfor

            if(includeLineInd  = 1)
 
                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->tubesAndDrains[tubeIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 12

                ;obtain access type 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (uroTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report

                    ltdInfo->info[newLineCnt].label_name = trim(ce.result_val,3)
                with nocounter
                
                ;obtain instance 
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (uroInstanceCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
                    ltdInfo->info[newLineCnt].label_name = build2( trim(ltdInfo->info[newLineCnt].label_name,3), ' '
                                                                 , trim(ce.result_val,3))

                
                with nocounter
 
                
            endif
        endif
        
        if(newLineCnt > 0)
            ;obtain location information
            select into 'nl:'
                   sortOrder = ;laterality
                               if(ce.event_cd in ( chestLatCd
                                                 , drainLatCd
                                                 , drainLat2Cd
                                                 , autoLatCd
                                                 )
                                 )
                                   0
                               ;loc desc
                               elseif(ce.event_cd in ( drainLocDescCd
                                                     )
                                     )
                                   1
                               ;site
                               elseif(ce.event_cd in ( chestLocCd
                                                     , drainLocCd
                                                     , autoLocCd
                                                     )
                                     )
                                   2
                               endif
              from clinical_event ce
                 , ce_date_result cdr
              plan ce
               where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                 and ce.event_cd            in ( chestLatCd
                                               , drainLatCd
                                               , drainLat2Cd
                                               , autoLatCd
                                               
                                               , drainLocDescCd
                                               
                                               , chestLocCd
                                               , drainLocCd
                                               , autoLocCd
                                               )
                 and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                 and ce.result_status_cd    in (modifiedCd, authverifyCd)
                 and ce.event_class_cd      != placeholderCd
            join cdr
                where cdr.event_id = outerjoin(ce.event_id)
                  and (cdr.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
                       or
                       cdr.valid_until_dt_tm is null
                      )
            order by sortOrder, ce.event_cd
            head report
                locCnt = 0
            
            head ce.event_cd
                locCnt    = locCnt + 1
                ;TODO the space after other fixes PIV, but might break others?
                resultVal = replace(trim(ce.result_val,3),'Other:','')
            
                call echo(trim(resultVal, 3))
                
                ;002: Adding the check to see if location is filled.  It shouldn't be except for my changes to dialysis and central
                ;lines above to move the left rights into it.
                if(locCnt = 1)
                    ltdInfo->info[newLineCnt].location = trim(resultVal, 3)
                else
                    ltdInfo->info[newLineCnt].location = concat(ltdInfo->info[newLineCnt].location, ' ', trim(resultVal, 3))
                endif
            
            with nocounter
 

            if(findstring(':',ltdInfo->info[newLineCnt].label_name,1));don't need the extra :
                
                if(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0)
                    set ltdInfo->info[newLineCnt].display = build2( ltdInfo->info[newLineCnt].label_name       , " "
                                                                  , trim(ltdInfo->info[newLineCnt].location,3) , "  "
                                                                  , trim(ltdInfo->info[newLineCnt].duration,3))
                else
                    set ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, " "
                                                                  , trim(ltdInfo->info[newLineCnt].duration,3))
                endif
            else
                if(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0
                   and
                   textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0)
                    set ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, ": ",
                                                trim(ltdInfo->info[newLineCnt].location,3)
                                                ,"  ",trim(ltdInfo->info[newLineCnt].duration,3))
                
                elseif(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0 and
                                                textlen(trim(ltdInfo->info[newLineCnt].duration,3)) = 0)
                    set ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, ": ",
                                                trim(ltdInfo->info[newLineCnt].location,3))
 
                
                elseif(textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0)
                    set ltdInfo->info[newLineCnt].display = build2( ltdInfo->info[newLineCnt].label_name       , ":  "
                                                                  , trim(ltdInfo->info[newLineCnt].duration,3))
                
                else
                    set ltdInfo->info[newLineCnt].display = ltdInfo->info[newLineCnt].label_name
                endif
            endif
        endif
        
    endif
endfor




;  Oh boy... we have a band that isn't part of lines tubes and drains request/reply at all...
;  Negative Pressure Wound Therapy... Meaning... I need to do this manually for that sucker.
;  Here is my attempt.  Pray for me.
select into 'nl:'
       sortOrder = if    (ce.event_cd = npwtLatCd    )  0  ;laterality
                   elseif(ce.event_cd = npwtLocDescCd)  1  ;loc desc
                   elseif(ce.event_cd = npwtLocCd    )  2  ;site
                   endif
  from clinical_event   ce
     , ce_date_result   cdr
     , ce_dynamic_label cdl
  plan ce
   where ce.encntr_id           =  e_id
     and ce.event_cd            in ( npwtLatCd
                                   
                                   , npwtLocDescCd
                                   
                                   , npwtLocCd
                                   )
     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd    in (modifiedCd, authverifyCd)
     and ce.event_class_cd      != placeholderCd
     and exists(select 'x'
                  from clinical_event ce2
                 where ce2.ce_dynamic_label_id =  ce.ce_dynamic_label_id
                   and ce2.event_cd            in (   5111351.00   ;Wound Vac Output
                                                  , 102279056.00   ;Wound Vac Input
                                                  ;, 573538117.00)  ;Wound Vac Desc 
                                                  , 514182479.00)  ;Wound Vac Desc This is the correct one.
                   and ce2.event_end_dt_tm     >  cnvtlookbehind('24,H')
                   and ce2.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                   and ce2.result_status_cd    in (modifiedCd, authverifyCd)
               )
join cdr
    where cdr.event_id = outerjoin(ce.event_id)
      and (cdr.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
           or
           cdr.valid_until_dt_tm is null
          )
join cdl
    where cdl.ce_dynamic_label_id =  ce.ce_dynamic_label_id
      and cdl.label_status_cd     != 4311836.00  ;Inactive
order by ce.ce_dynamic_label_id, sortOrder
head ce.ce_dynamic_label_id
    locCnt = 0
    
    newLineCnt                                    = newLineCnt + 1
    stat                                          = alterlist(ltdInfo->info,newLineCnt)
    ltdInfo->info[newLineCnt].ce_dynamic_label_id = ce.ce_dynamic_label_id


    ;Adding sorting stuff here now:
    ltdInfo->info[newLineCnt].sort_pos = 7
    
    ltdInfo->info[newLineCnt].label_name          = 'NPWT'

head ce.event_cd
    locCnt    = locCnt + 1
    ;TODO the space after other fixes PIV, but might break others?
    resultVal = replace(trim(ce.result_val,3),'Other:','')

    
    ;002: Adding the check to see if location is filled.  It shouldn't be except for my changes to dialysis and central
    ;lines above to move the left rights into it.
    if(locCnt = 1)
        ltdInfo->info[newLineCnt].location = trim(resultVal, 3)
    else
        ltdInfo->info[newLineCnt].location = concat(ltdInfo->info[newLineCnt].location, ' ', trim(resultVal, 3))
    endif

foot ce.ce_dynamic_label_id
    if(findstring(':',ltdInfo->info[newLineCnt].label_name,1));don't need the extra :
        
        if(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0)
            ltdInfo->info[newLineCnt].display = build2( ltdInfo->info[newLineCnt].label_name       , " "
                                                          , trim(ltdInfo->info[newLineCnt].location,3) , "  "
                                                          , trim(ltdInfo->info[newLineCnt].duration,3))
        else
            ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, " "
                                                          , trim(ltdInfo->info[newLineCnt].duration,3))
        endif
    else
        if(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0
           and
           textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0)
            ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, ": ",
                                        trim(ltdInfo->info[newLineCnt].location,3)
                                        ,"  ",trim(ltdInfo->info[newLineCnt].duration,3))
        
        elseif(textlen(trim(ltdInfo->info[newLineCnt].location,3)) > 0 and
                                        textlen(trim(ltdInfo->info[newLineCnt].duration,3)) = 0)
            ltdInfo->info[newLineCnt].display = build2(ltdInfo->info[newLineCnt].label_name, ": ",
                                        trim(ltdInfo->info[newLineCnt].location,3))

        
        elseif(textlen(trim(ltdInfo->info[newLineCnt].duration,3)) > 0)
            ltdInfo->info[newLineCnt].display = build2( ltdInfo->info[newLineCnt].label_name       , ":  "
                                                      , trim(ltdInfo->info[newLineCnt].duration,3))
        
        else
            ltdInfo->info[newLineCnt].display = ltdInfo->info[newLineCnt].label_name
        endif
    endif

with nocounter


;  Second boy-o that isn't part of the request reply.... Internal Fecal Management System
;  Trying it manually.   Also this is way different than most these guys above.
select into 'nl:'
  from clinical_event   ce
     , ce_date_result   cdr
     , ce_dynamic_label cdl
  plan ce
   where ce.encntr_id           =  e_id
     ;We can't do this... if the band is active... we want to pull it in.  I think I need to 
     ;open this up... then add a filter on ce_dynamic_label
     ;and ce.event_cd            in ( fmsActCd
     ;                              
     ;                              , fmsInsCd
     ;                              
     ;                              , fmsDCCd
     ;                              )
     ;Okay that failed me and I got in trouble next round of validation.  The BAND itself drops a CE.
     ;We only want to show if we have a real doc in the band... not having a band itself.  So we have to
     ;ignore that one.
     and ce.event_cd            != fmsTypeCd 
     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd    in (modifiedCd, authverifyCd)
     and ce.event_class_cd      != placeholderCd
join cdr
    where cdr.event_id = outerjoin(ce.event_id)
      and (cdr.valid_until_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3))
           or
           cdr.valid_until_dt_tm = outerjoin(null)
          )
join cdl
    where cdl.ce_dynamic_label_id =  ce.ce_dynamic_label_id
      and cdl.label_name          = 'FMS'
      and cdl.label_status_cd     != 4311836.00  ;Inactive

order by ce.ce_dynamic_label_id, ce.event_cd, ce.event_end_dt_tm desc
head ce.ce_dynamic_label_id

    fmsDCInd  = 0
    fmsDurTxt = ''

head ce.event_cd

    case(ce.event_cd)
    of fmsActCd:
        ;if the most recent activity has Discontinue, we don't want this.
        if(ce.result_val = '*Discontinue*')
            fmsDCInd = 1
        endif
    
    of fmsDCCd :
        ;If we have a dc date... we don't want this.
        fmsDCInd = 1
    
    of fmsInsCd:    
        ;Calc duration with most recent date we got.
        duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,1))
        duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,3))
        duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,4))
        
        hours_diff = (duration_hours - (duration_days * 24 ))
        mins_diff  = (duration_mins  - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))
                
                
        call echo(format(cnvtdatetime(cdr.result_dt_tm), '@SHORTDATETIME'))
        call echo(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(cdr.result_dt_tm) ,1))
        call echo(duration_days)
        fmsDur = duration_days
        
        if(duration_days < 1)     fmdDurTxt = '< 1 Day'
        elseif(duration_days = 1) fmdDurTxt = '1 Day'
        else                      fmdDurTxt = trim(build2(duration_days,' Days'),3)
        endif

    endcase

foot ce.ce_dynamic_label_id
        
    if(fmsDCInd = 0)
        newLineCnt = newLineCnt + 1
        stat       = alterlist(ltdInfo->info,newLineCnt)
        ltdInfo->info[newLineCnt].ce_dynamic_label_id = ce.ce_dynamic_label_id
        
        ;Adding sorting stuff here now:
        ltdInfo->info[newLineCnt].sort_pos = 11
        
        ltdInfo->info[newLineCnt].label_name          = 'Internal Fecal Management System'
        ltdInfo->info[newLineCnt].durationVal         = fmsDur
        
        
        if(fmdDurTxt != '')
            ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ', fmdDurTxt)
            
        else
            ltdInfo->info[newLineCnt].label_name = ltdInfo->info[newLineCnt].label_name
            
        endif
        
        ltdInfo->info[newLineCnt].display             = ltdInfo->info[newLineCnt].label_name
    endif
with nocounter



;debugging
call echorecord(3208905_reply)

call echorecord(ltdInfo)

;Presentation?
if(size(ltdInfo->info,5) > 0)
    
    select into "nl:"
             sort     = ltdInfo->info[d.seq].sort_pos
           , display  = cnvtupper(replace(substring(1,350,ltdInfo->info[d.seq].label_name), ':', '', 0))
           , location = cnvtupper(substring(1,100,ltdInfo->info[d.seq].location))
           , duration = ltdInfo->info[d.seq].durationVal
      from (dummyt d with seq = size(ltdInfo->info,5))
      plan d
    order by sort,display,location,duration,d.seq
    head report
        dispCnt = 1
        
        stat = alterlist(displayQual->line_qual,dispCnt)
        
        displayqual->line_qual[dispCnt].disp_line = build2(rhead, rh2bu ,'Tubes/Drains' , rh2r)
        
    head d.seq
        dispCnt = dispCnt + 1

        stat = alterlist(displayQual->line_qual,dispCnt)

        ;Funny stuff for Enteral Tube sorting.
        ;We have Enteral Tube in the name... but we don't want it.  We left it there so it'd sort right here... but we want to
        ;replace it out now.
        if(findstring('Enteral Tube ', ltdInfo->info[d.seq].display))
            ;002->
            ;More funny stuff now.  We left Ent Tube in the name, and _usually_ want to replace it out.
            ;But if we have the new other type.  We want to display Enteral Tube (OTHER TEXT)
            
            call echo(ltdInfo->info[d.seq].display)
            
            if(ltdInfo->info[d.seq].display = 'Enteral Tube Other:*')
                ;Somethings we want to test:
                ;A couple of numbers.
                ;ltdInfo->info[d.seq].display = 'Enteral Tube Other: This is a freggin test #4'
                ;ltdInfo->info[d.seq].display = 'Enteral Tube Other: Testing #6'
                
                ;No location
                ;ltdInfo->info[d.seq].display = 'Enteral Tube Other: Test'
                
                ;a #10.
                ;ltdInfo->info[d.seq].display = 'Enteral Tube Other: Big Test #10'
                
                ;A # in the test text. with a location
                ;ltdInfo->info[d.seq].display = 'Enteral Tube Other: Test # Test #6'
                
                ;a # in the test text. without a location
                ;ltdInfo->info[d.seq].display = 'Enteral Tube Other: Test # With more text'
                
                ;We forgot the no text case.
                if(ltdInfo->info[d.seq].display = 'Enteral Tube Other:')
                    displayqual->line_qual[dispCnt].disp_line = build2(reol, 'Enteral Tube ')
                
                
                else
                
                    ;Pull the other out for now.
                    displayqual->line_qual[dispCnt].disp_line = replace( ltdInfo->info[d.seq].display
                                                                       , 'Enteral Tube Other: ', '')
                    
                    
                    ;Now we have to check for the instance.  This should be at the end... but we want to be hyper careful, because
                    ;in theory they can have a # in the other text.
                    pos = findstring( '#', displayqual->line_qual[dispCnt].disp_line
                                    , size(displayqual->line_qual[dispCnt].disp_line, 3) - 3
                                    , 1)
                    
                    if(pos > 0)
                        inst_holder = substring(pos, 3, displayqual->line_qual[dispCnt].disp_line)
                    
                        displayqual->line_qual[dispCnt].disp_line = replace( displayqual->line_qual[dispCnt].disp_line
                                                                           , inst_holder
                                                                           , ''
                                                                           , 2)
                        
                        displayqual->line_qual[dispCnt].disp_line = build2(reol, 'Enteral Tube ('
                                                                               , displayqual->line_qual[dispCnt].disp_line
                                                                               , ') '
                                                                               , inst_holder
                                                                      )
                        
                        
                    else
                        displayqual->line_qual[dispCnt].disp_line = build2(reol, 'Enteral Tube ('
                                                                               , displayqual->line_qual[dispCnt].disp_line
                                                                               , ')'
                                                                      )
                    endif
                endif
                
            else
            ;002<-
                displayqual->line_qual[dispCnt].disp_line = build2(reol, replace( ltdInfo->info[d.seq].display
                                                                                , 'Enteral Tube '
                                                                                , ''
                                                                                )
                                                                  )
            endif ;002
        else
            displayqual->line_qual[dispCnt].disp_line = build2(reol      ,ltdInfo->info[d.seq].display)
        endif

    foot report
        for (dispIdx = 1 to dispCnt)
            reply->text = build2(reply->text,displayQual->line_qual[dispIdx].disp_line)
        endfor
    with nocounter

else
    set reply->text = rhead

endif

 
set reply->status_data->status = "S"
 
set reply->text = concat(reply->text, rtfeof)
 
 
call echojson(ltdInfo,'6_st_cc_ltds_cc_no_ucath.dat')

/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

call echorecord(reply)

call echo(reply->text)


end
go
