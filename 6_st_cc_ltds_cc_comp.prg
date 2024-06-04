/*************************************************************************
 Program Title:   CC Lines Complete

 Object name:     6_st_cc_ltds_cc_comp
 Source file:     6_st_cc_ltds_cc_comp.prg

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

                  But since I hated that script... I think I'm going to
                  heavily refactor wherever it is safe.

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA     Comment
--- ---------- -------------------- -------- -----------------------------
001 02/10/2022 Michael Mayes        229806   Initial release
002 08/06/2022 Michael Mayes        237056   Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
drop   program 6_st_cc_ltds_cc_comp:dba go
create program 6_st_cc_ltds_cc_comp:dba

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
            2 status                = c1
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
declare header                   = vc  with protect, noconstant('')
declare tmp_str                  = vc  with protect, noconstant('')

declare act_cd                   = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'ACTIVE'  ))
declare mod_cd                   = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'MODIFIED'))
declare auth_cd                  = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'AUTH'    ))
declare alt_cd                   = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'ALTERED' ))

declare modifiedCd               = f8 with protect,   constant(mod_cd ) ;TODO this is to play nice with copy paste code TODO refact
declare authverifyCd             = f8 with protect,   constant(auth_cd) ;TODO this is to play nice with copy paste code TODO refact
declare placeholderCd            = f8 with protect,   constant(uar_get_code_by("MEANING", 53, "PLACEHOLDER" ))

declare resultVal                = vc  with protect, noconstant('')

declare lineIdx                  = i4  with protect, noconstant(0)
declare lineCnt                  = i4  with protect, noconstant(0)
declare tubeCnt                  = i4  with protect, noconstant(0)
declare resultIdx                = i4  with protect, noconstant(0)

declare includeLineInd           = i2  with protect, noconstant(0)

declare dialysisaccessactivityCd = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "DIALYSISACCESSACTIVITY"     ))
declare dialysisaccessTypeCd     = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Dialysis Access Type"       ))
declare dialysislatcd            = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Dialysis Laterality:"       ))
declare sheathactivityCd         = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "SHEATHACTIVITY"             ))
declare palineactivityCd         = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "PALINEACTIVITY"             ))
declare peripheralivactivityCd   = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Peripheral IV Activity:"    ))
declare sheathdeviceAssocCd      = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "Sheath Device Association:" ))
declare pacathTypeCd             = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "PA Catheter Type:"          ))
declare cvadaccessTypeCd         = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "CVAD Access Type:"          ))
declare cvadaccessLatCd          = f8  with protect,   constant(uar_get_code_by("DISPLAY"   , 72, "CVAD Laterality:"           ))
declare cvadinsertiondatetimeCd  = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "CVADINSERTIONDATETIME"      ))
declare ioinsertiondatetimeCd    = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "IOINSERTIONDATETIME"        ))
declare centrailLInedatetimeCd   = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 72, "CVADDISCONTINUATIONDATETIME"))
declare dialysisaccessLocCd      = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "Dialysis Access Location:"  ))
declare arteriallinelateralityCd = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "ARTERIALLINELATERALITY"     ))
declare arteriallnesiteCd        = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "Arterial Line Site:"        ))
declare sheathsiteCd             = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "Sheath Site:"               ))
declare sheathLatCd              = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "Sheath Laterality:"         ))
declare paLineSiteCd             = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "PA Line Site:"              ))
declare cvadsiteCd               = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "CVAD Site:"                 ))
declare iositeCd                 = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "IOSITE"                     ))
declare iolateralityCd           = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "IOLATERALITY"               ))

declare midlineSiteCd            = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "MIDLINEIVSITE"              ))
declare midlineTypeCd            = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "MIDLINEIVACCESSTYPE"        ))
declare midlineLatCd             = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "MIDLINEIVLATERALITY"        ))
declare midlineInsDtCd           = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "MIDLINEIVINSERTIONDATETIME" ))

declare periIVSiteCd             = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "Peripheral IV Site:"        ))
declare periIVTypeCd             = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "PERIPHERALIVCATHETERTYPE"   ))
declare periIVLatCd              = f8 with protect,    constant(uar_get_code_by("DISPLAY"   , 72, "Peripheral IV Laterality:"  ))

declare subQSiteCd               = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "SUBQCATHETERSITE"           ))
declare subQTypeCd               = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "SUBQCATHETERTYPE"           ))
declare subQActCd                = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "SUBQCATHETERACTIVITY"       ))

declare intSpinActCd             = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72
                                                                               , "INTRASPINALACTIVITY"                         ))
declare intSpinPeriSiteCd        = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72
                                                                               , "INTRASPINALPERINEURALCATHLOCATION"           ))
declare intSpinPeriTypeCd        = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72
                                                                               , "INTRASPINALPERINEURALCATHTYPE"               ))
declare intSpinPeriLatCd         = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72
                                                                               , "INTRASPINALPERINEURALCATHLATERALITY"         ))

declare intraosseousiteCd        = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "IOSITE"                     ))
declare intraosseouslatCd        = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "IOLATERALITY"               ))
declare intraosseousInsCd        = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "IOINSERTIONDATETIME"        ))
declare intraosseousDCCd         = f8 with protect,    constant(uar_get_code_by("DISPLAYKEY", 72, "IODISCONTINUATIONDATETIME"  ))


declare artierialLInedatetimeCd         = f8  with protect
                                                 , constant(uar_get_code_by("DISPLAYKEY", 72, "ARTERIALLINEDISCONTINUATIONDATETIME"
                                                                           )
                                                           )
declare arteriallineinsertiondatetimeCd = f8  with protect
                                                 , constant(uar_get_code_by("DISPLAYKEY", 72, "ARTERIALLINEINSERTIONDATETIME"))



/**************************************************************
; DVDev Start Coding
**************************************************************/
;First, Tameka was using a service for the gathering of all this stuff... I should try and do that as well.

;populate reqeust sent to request 3208905
set 3208905_request->encounter_id    = e_id

set 3208905_request->prsnl_id        = reqinfo->updt_id
set 3208905_request->relationship_cd = 441.00  ;wowie... she just did that eh.

set stat = tdbexecute(600005, 3202004, 3208905, "REC", 3208905_request, "REC", 3208905_reply)


;debugging
call echorecord(3208905_reply)

set lineCnt    = size(3208905_reply->lines,5)
set newLineCnt = 0
set tubeCnt    = size(3208905_reply->tubesAndDrains,5)
set newTubeCnt = 0


; Stealing most this from 6_st_cc_ltds_body_sys (and I hate it)
for(lineIdx = 1 to lineCnt)
    if(3208905_reply->lines[lineIdx].type = 'LINE')
        set includeLineInd  = 1
        set resultVal = ''

        if(3208905_reply->lines[lineIdx].type_display in ('Dialysis Access','Arterial and Venous Sheath','Pulmonary Artery Line'))

            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results, 5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in ( 'Discontinued/Out'
                                                                                     , 'Surgically removed Port'
                                                                                     , 'Self removed'
                                                                                     , 'Discontinued'
                                                                                     , 'Unintentionally removed'
                                                                                     )
                   or
                   3208905_reply->lines[lineIdx].results[resultIdx].event_set_display in ('Sheath Removal Date/Time:')
                  )
                    set includeLineInd  = 0
                endif
            endfor

            if(includeLineInd = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info, newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                case(3208905_reply->lines[lineIdx].type_display)
                of 'Dialysis Access'           : set ltdInfo->info[newLineCnt].sort_pos = 5
                of 'Arterial and Venous Sheath': set ltdInfo->info[newLineCnt].sort_pos = 3
                of 'Pulmonary Artery Line'     : set ltdInfo->info[newLineCnt].sort_pos = 2
                endcase


                if(3208905_reply->lines[lineIdx].type_display = 'Arterial and Venous Sheath')
                    set 3208905_reply->lines[lineIdx].type_display = 'Arterial/Venous Sheath'
                endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display

                ;obtain dialysis access type, PA Catheter Type
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( pacathTypeCd
                                                   , dialysisaccessTypeCd
                                                   , sheathdeviceAssocCd
                                                   )
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                order by ce.event_cd
                head report
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other
                    ;but notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2(trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (', trim(resultVal,3), ') '
                                                                     )
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                with nocounter

                ;obtain central lines laterality
                if(3208905_reply->lines[lineIdx].type_display = 'Dialysis Access')
                    select into 'nl:'
                      from clinical_event ce
                      plan ce
                       where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                         and ce.event_cd            =  dialysisLatCd
                         and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                         and ce.result_status_cd    in (modifiedCd, authverifyCd)
                         and ce.event_class_cd      != placeholderCd
                    order by ce.event_cd
                    head report
                        resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)

                        ;002: okay, having these lefts/rights in the label is messing with sorting... but just for central line and
                        ;dialysis.  I'm hoping to avoid that by packing into a new val, and handling it below where we mess with
                        ;location.
                        if(textlen(resultVal) > 0)
                            ltdInfo->info[newLineCnt].cent_dia_loc = trim(resultVal,3)
                        endif
                    with nocounter
                endif


                ;obtain duration documented as event_end_dt_tm
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( sheathactivityCd
                                                   , dialysisaccessactivityCd
                                                   , peripheralivactivityCd
                                                   , palineactivityCd
                                                   )
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                order by ce.event_cd, ce.event_end_dt_tm
                head report
                    duration_days  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm) ,1))
                    duration_hours = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm),3))
                    duration_mins  = floor(datetimediff(cnvtdatetime(curdate,curtime3),cnvtdatetime(ce.event_end_dt_tm ) ,4))
                    hours_diff     = (duration_hours - (duration_days * 24 ))
                    mins_diff      = (duration_mins - ((hours_diff * 60 ) + ((duration_days * 24 ) * 60 )))

                    ltdInfo->info[newLineCnt].durationVal = duration_days

                    if(3208905_reply->lines[lineIdx].type_display != 'Dialysis Access');dialysis should not display duration
                        if    (duration_days < 1) ltdInfo->info[newLineCnt].duration = '< 1 Day'
                        elseif(duration_days = 1) ltdInfo->info[newLineCnt].duration = '1 Day'
                        else                      ltdInfo->info[newLineCnt].duration = trim(build2(duration_days,' Days'),3)
                        endif
                    else
                        if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                           and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                          )
                            ;only add : when duration exists
                            ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                        endif
                    endif
                with nocounter
            endif

        elseif(3208905_reply->lines[lineIdx].type_display in ('Arterial Line','Central Line:'))
            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results,5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in( 'Discontinued/Out'
                                                                                    , 'Surgically removed Port'
                                                                                    , 'Surgically Removed Port'
                                                                                    , 'Self removed'
                                                                                    , 'Discontinued'
                                                                                    , 'Unintentionally removed'
                                                                                    )
                   or
                   3208905_reply->lines[lineIdx].results[resultIdx].event_set_display in( 'Arterial Line Discontinuation Date/Time:'
                                                                                        , 'CVAD Discontinuation Date/Time:')
                  )
                    set includeLineInd  = 0
                endif

                ;do not include lines w/ a d/c date/time
                if(includeLineInd  = 1)
                    select into 'nl:'
                      from clinical_event ce
                      plan ce
                       where ce.ce_dynamic_label_id =  3208905_reply->lines[lineIdx].ce_dynamic_label_id
                                                       ;ltdInfo->info[newLineCnt].ce_dynamic_label_id
                         and ce.event_cd            in ( centrailLInedatetimeCd
                                                       , artierialLInedatetimeCd)
                         and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                         and ce.result_status_cd    in (modifiedCd, authverifyCd)
                         and ce.event_class_cd      != placeholderCd
                    head report
                        includeLineInd  = 0
                    with nocounter
                endif
            endfor

            if(includeLineInd  = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info,newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                case(3208905_reply->lines[lineIdx].type_display)
                of 'Arterial Line': set ltdInfo->info[newLineCnt].sort_pos = 1
                of 'Central Line:': set ltdInfo->info[newLineCnt].sort_pos = 4
                endcase

                if(3208905_reply->lines[lineIdx].type_display = 'Central Line:')
                    set 3208905_reply->lines[lineIdx].type_display = 'Central Line'
                endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display

                ;obtain cvad access type and Sheath Device Association:
                select into 'nl:'
                from clinical_event ce
                plan ce
                    where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                        and ce.event_cd          in (cvadaccessTypeCd)
                        and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (modifiedCd, authverifyCd)
                        and ce.event_class_cd    != placeholderCd
                order by ce.event_cd
                head report
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

                ;obtain cvad lines laterality
                if(3208905_reply->lines[lineIdx].type_display = 'Central Line')
                    select into 'nl:'
                      from clinical_event ce
                      plan ce
                       where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                         and ce.event_cd            =  cvadaccessLatCd
                         and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                         and ce.result_status_cd    in (modifiedCd, authverifyCd)
                         and ce.event_class_cd      !=  placeholderCd
                    order by ce.event_cd
                    head report
                        resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)

                        ;002: okay, having these lefts/rights in the label is messing with sorting... but just for central line and
                        ;dialysis.  I'm hoping to avoid that by packing into a new val, and handling it below where we mess with
                        ;location.
                        if(textlen(resultVal) > 0)
                            ltdInfo->info[newLineCnt].cent_dia_loc = trim(resultVal, 3)
                        endif
                    with nocounter
                endif

                ;obtain duration documented as event_end_dt_tm
                select into 'nl:'
                  from clinical_event ce
                     , ce_date_result cdr
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( arteriallineinsertiondatetimeCd
                                                   , cvadinsertiondatetimeCd
                                                   , ioinsertiondatetimeCd
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

        elseif(3208905_reply->lines[lineIdx].type_display in ('Midline IV:'))

            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results, 5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in ( 'Self removed'
                                                                                     , 'Discontinued'
                                                                                     , 'Unintentionally removed'
                                                                                     )
                  )
                    set includeLineInd  = 0
                endif
            endfor

            ;TODO do we need this, prolly
            ;do not include lines w/ a d/c date/time

            if(includeLineInd = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info, newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 6


                if(3208905_reply->lines[lineIdx].type_display = 'Midline IV:')
                    set 3208905_reply->lines[lineIdx].type_display = 'Midline IV'
                endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display

                ;obtain midline type
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in (midlineTypeCd)
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate, curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                order by ce.event_cd
                head report
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other
                    ;but notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2(trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (', trim(resultVal,3), ') '
                                                                     )
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                with nocounter


                ;obtain duration documented as event_end_dt_tm
                select into 'nl:'
                  from clinical_event ce
                     , ce_date_result cdr
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( midlineInsDtCd
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
                
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                      )
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
            endif

        elseif(3208905_reply->lines[lineIdx].type_display in ('Peripheral IVs'))

            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results, 5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in ( 'Self removed'
                                                                                     , 'Discontinued'
                                                                                     , 'Unintentionally removed'
                                                                                     )
                  )
                    set includeLineInd  = 0
                endif
            endfor

            ;TODO do we need this, prolly
            ;do not include lines w/ a d/c date/time

            if(includeLineInd = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info, newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 7


                if(3208905_reply->lines[lineIdx].type_display = 'Peripheral IVs')
                    set 3208905_reply->lines[lineIdx].type_display = 'PIV'
                endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display

                ;obtain Peri IV type
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in (periIVTypeCd)
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate, curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                order by ce.event_cd
                head report
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other
                    ;but notput contents in
                    if(textlen(resultVal) > 0)
                        ;Special stuff here... if we have PIV as the type... we don't want to display it.
                        ; I think doing nothing is in order.
                        if(resultVal != 'PIV')
                            ltdInfo->info[newLineCnt].label_name = build2(trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                         , ' (', trim(resultVal,3), ') '
                                                                         )
                        endif
                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                with nocounter


                ;obtain duration documented as event_end_dt_tm
                ; This is different than above...
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                     and ce.event_cd            =  peripheralivactivityCd
                     and ce.result_val          in ( 'Inserted'
                                                   , 'Inserted - Ultrasound guided'
                                                   , 'Inserted - Vein finder device'
                                                   , 'Assessed'
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

        elseif(3208905_reply->lines[lineIdx].type_display in ('Subcutaneous Catheter'))

            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results, 5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in ( 'Self removed'
                                                                                     , 'Discontinued'
                                                                                     , 'Unintentionally removed'
                                                                                     )
                  )
                    set includeLineInd  = 0
                endif
            endfor


            if(includeLineInd = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info, newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 8

                ;if(3208905_reply->lines[lineIdx].type_display = 'Peripheral IVs')
                ;    set 3208905_reply->lines[lineIdx].type_display = 'PIV'
                ;endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display

                ;obtain SubQ IV type
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in (subQTypeCd)
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate, curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                order by ce.event_cd
                head report
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other
                    ;but notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2(trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (', trim(resultVal,3), ') '
                                                                     )

                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                with nocounter


                ;obtain duration documented as event_end_dt_tm
                ; This is different than above...
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                     ;Even more different... I have to have an insertion event to show a duration.  Going to try and be dumb
                     and exists( select 'X'
                                   from clinical_event ce2
                                  where ce2.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                                    and ce2.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                                    and ce2.result_status_cd    in (modifiedCd, authverifyCd)
                                    and ce2.event_class_cd      != placeholderCd
                                    and ce2.event_cd            =  subQActCd
                                    and ce2.result_val          =  'Inserted'

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

        elseif(3208905_reply->lines[lineIdx].type_display in ('Intraspinal/Perineural Catheter:'))

            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results, 5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in ( 'Self removed'
                                                                                     , 'Discontinued'
                                                                                     , 'Unintentionally removed'
                                                                                     )
                  )
                    set includeLineInd  = 0
                endif
            endfor

            ;TODO do we need this, prolly
            ;do not include lines w/ a d/c date/time

            if(includeLineInd = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info, newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 11

                if(3208905_reply->lines[lineIdx].type_display = 'Intraspinal/Perineural Catheter:')
                    set 3208905_reply->lines[lineIdx].type_display = 'Intraspinal/Perineural Catheter'
                endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display

                ;obtain Intraspinal IV type
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in (intSpinPeriTypeCd)
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate, curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                order by ce.event_cd
                head report
                    resultVal = trim(replace(trim(ce.result_val,3),'Other:',''),3)
                    ;do not display '()' when there are no contents. since we strip 'Other:' it's possible to select other
                    ;but notput contents in
                    if(textlen(resultVal) > 0)
                        ltdInfo->info[newLineCnt].label_name = build2(trim(ltdInfo->info[newLineCnt].label_name,3)
                                                                     , ' (', trim(resultVal,3), ') '
                                                                     )

                    else
                        ltdInfo->info[newLineCnt].label_name = trim(ltdInfo->info[newLineCnt].label_name,3)
                    endif
                with nocounter


                ;obtain duration documented as event_end_dt_tm
                ; This is different than above...
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                     and ce.event_cd            =  intSpinActCd
                     and ce.result_val          in ( 'Inserted'
                                                   , 'Assessed'
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

        elseif(3208905_reply->lines[lineIdx].type_display in ('Intraosseous'))

            ;check to see if result of 'discontinued' and if so, do not add
            for(resultIdx = 1 to size(3208905_reply->lines[lineIdx].results, 5))
                if(3208905_reply->lines[lineIdx].results[resultIdx].value_display in ( 'Self removed'
                                                                                     , 'Discontinued'
                                                                                     , 'Unintentionally removed'
                                                                                     )
                  )
                    set includeLineInd  = 0
                endif
            endfor

            ;do not include lines w/ a d/c date/time
            if(includeLineInd  = 1)
                select into 'nl:'
                  from clinical_event ce
                  plan ce
                   where ce.ce_dynamic_label_id =  3208905_reply->lines[lineIdx].ce_dynamic_label_id
                                                   ;ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( intraosseousDCCd)
                     and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
                     and ce.result_status_cd    in (modifiedCd, authverifyCd)
                     and ce.event_class_cd      != placeholderCd
                head report
                    includeLineInd  = 0
                with nocounter
            endif

            if(includeLineInd = 1)

                set newLineCnt                                    = newLineCnt + 1
                set stat                                          = alterlist(ltdInfo->info, newLineCnt)
                set ltdInfo->info[newLineCnt].ce_dynamic_label_id = 3208905_reply->lines[lineIdx].ce_dynamic_label_id


                ;Adding sorting stuff here now:
                set ltdInfo->info[newLineCnt].sort_pos = 12

                ;if(3208905_reply->lines[lineIdx].type_display = 'Intraspinal/Perineural Catheter:')
                ;    set 3208905_reply->lines[lineIdx].type_display = 'Intraspinal/Perineural Catheter'
                ;endif

                set ltdInfo->info[newLineCnt].label_name = 3208905_reply->lines[lineIdx].type_display


                ;obtain duration documented as event_end_dt_tm
                ; This is different than above...
                ; There is no date to guide us, and we are supposed to take the earliest doc we can find for the begin
                select into 'nl:'
                  from clinical_event ce
                     , ce_date_result cdr
                  plan ce
                   where ce.ce_dynamic_label_id = ltdInfo->info[newLineCnt].ce_dynamic_label_id
                     and ce.event_cd            in ( intraosseousInsCd
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
                
                    if(    textlen(trim(ltdInfo->info[newLineCnt].duration,3))    > 0
                       and findstring(':',ltdInfo->info[newLineCnt].label_name,1) = 0
                      )
                        ;only add : when duration exists
                        ltdInfo->info[newLineCnt].label_name = build2(ltdInfo->info[newLineCnt].label_name,':  ')
                    endif
                with nocounter
            endif

        endif

        if(newLineCnt > 0)
            ;obtain location information
            select into 'nl:'
                   sortOrder = ;laterality
                               if(ce.event_cd in ( dialysisaccessLocCd
                                                  , arteriallinelateralityCd
                                                  , iolateralityCd
                                                  , sheathLatCd
                                                  , midlineLatCd
                                                  , periIVLatCd
                                                  , intSpinPeriLatCd
                                                  , intraosseouslatCd
                                                  )
                                 )
                                   0
                               ;site
                               elseif(ce.event_cd in ( arteriallnesiteCd
                                                     , cvadsiteCd
                                                     , paLineSiteCd
                                                     , sheathsiteCd
                                                     , midlineSiteCd
                                                     , periIVSiteCd
                                                     , subQSiteCd
                                                     , intSpinPeriSiteCd
                                                     , intraosseousiteCd
                                                     )
                                     )
                                   1
                               endif
              from clinical_event ce
                 , ce_date_result cdr
              plan ce
               where ce.ce_dynamic_label_id =  ltdInfo->info[newLineCnt].ce_dynamic_label_id
                 and ce.event_cd            in (dialysisaccessLocCd
                                               , arteriallinelateralityCd
                                               , iolateralityCd
                                               , sheathLatCd
                                               , midlineLatCd
                                               , periIVLatCd
                                               , intSpinPeriLatCd
                                               , intraosseouslatCd

                                               , arteriallnesiteCd
                                               , cvadsiteCd
                                               , paLineSiteCd
                                               , sheathsiteCd
                                               , midlineSiteCd
                                               , periIVSiteCd
                                               , subQSiteCd
                                               , intSpinPeriSiteCd
                                               , intraosseousiteCd
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

                ;Pulmonary ARt do not have a sepearte DTA for laterliaty and the laterliaty is stored in the stie
                ;dta.
                if(ce.event_cd in (paLineSiteCd))
                    if(findstring('Left',resultVal,1))
                        resultVal = replace(resultVal,'Left','')
                        resultVal = build2('Left ',resultVal)
                    endif

                    if(findstring('Right',resultVal,1))
                        resultVal = replace(resultVal,'Right','')
                        resultVal = build2('Right ',resultVal)
                    endif

                endif

                ;since the initial value will have ',' used to separate the 'Left/Right' we need to strip it off as it will
                ;002: Wow... sometimes there are multiple commas, changing this to a while.
                resultVal = trim(resultVal)
                while(substring(size(resultVal), 1, resultVal) = ',')
                    resultVal = trim(substring(1, size(resultVal) - 1, resultVal))
                endwhile


                ;002: Adding the check to see if location is filled.  It shouldn't be except for my changes to dialysis and central
                ;lines above to move the left rights into it.
                if(locCnt = 1)
                    if(textlen(trim(ltdInfo->info[newLineCnt].cent_dia_loc,3)) != 0)
                        call echo(ltdInfo->info[newLineCnt].cent_dia_loc)
                        call echo(trim(resultVal, 3))
                        call echo(uar_get_code_display(ce.event_cd))
                        ;002: resultVal sometimes had leading spaces.
                        ltdInfo->info[newLineCnt].location = concat(ltdInfo->info[newLineCnt].cent_dia_loc, ' ',
                                                                        trim(resultVal, 3))
                    else
                        ;002: resultVal sometimes had leading spaces.
                        ltdInfo->info[newLineCnt].location = trim(resultVal, 3)
                    endif
                else
                    ltdInfo->info[newLineCnt].location = concat(ltdInfo->info[newLineCnt].location, ' ', trim(resultVal, 3))
                endif

            with nocounter

            ;002 I think we have another special case here... if there is no location... the query above failed us if we had a
            ;    lat saved off in the cent_diag_loc.
            ;  This should just be for dialysis... maybe central lines
            if(    ltdInfo->info[newLineCnt].location = ''
               and ltdInfo->info[newLineCnt].cent_dia_loc > ' ')
               set ltdInfo->info[newLineCnt].location = ltdInfo->info[newLineCnt].cent_dia_loc
            endif


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


;002->
;Special cases
;They took something that used to be packed into a dynamic grouper, and pulled it out so it is no longer that.
;That means we have our first special cases in this script, because it won't come back in the TDB call that we made.

;Subcutaneous Insulin Pump
declare cg_act_cd    = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'CGMACTIVITY'))
declare cg_site_cd   = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'CGMSITE'))

declare cg_temp_site = vc with protect, noconstant('')

set includeLineInd = 0

select into 'nl:'
  
  from clinical_event ce
     , ce_date_result cdr
     
 where ce.encntr_id           =  e_id
   and ce.event_cd            in (cg_act_cd)
   and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd    in (modifiedCd, authverifyCd)
   and ce.event_class_cd      != placeholderCd
   
   and cdr.event_id = outerjoin(ce.event_id)
   and (   cdr.valid_until_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3))
        or cdr.valid_until_dt_tm = outerjoin(null)
       )
       
order by ce.event_cd, ce.event_end_dt_tm desc
head report
    
    if(trim(ce.result_val, 3) in ( 'Nurse Removed'
                                 , 'Self removed'
                                 , 'Unintentionally removed'
                                 ))
                                 
        includeLineInd = 0

    else
        includeLineInd = 1
    endif
with nocounter


if(includeLineInd = 1)
    set newLineCnt                                    = newLineCnt + 1
    set stat                                          = alterlist(ltdInfo->info, newLineCnt)
    set ltdInfo->info[newLineCnt].label_name          = 'Continuous Glucose Monitor (CGM)'
    
    set ltdInfo->info[newLineCnt].sort_pos = 10        

    ;No duration for this one actually
    
    
    ;Okay... so no duration... but we get the colon if there is a site... and we don't if we don't...
    
    select into 'nl:'
      from clinical_event ce
    
     where ce.encntr_id           =  e_id
       and ce.event_cd            in (cg_site_cd)
       and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
       and ce.result_status_cd    in (modifiedCd, authverifyCd)
       and ce.event_class_cd      != placeholderCd
    
    order by ce.event_cd, ce.event_start_dt_tm desc
    
    head report
        cg_temp_site = trim(replace(ce.result_val, 'Other:', ''), 3)
        
        if(cg_temp_site > ' ')
            ltdInfo->info[newLineCnt].label_name = notrim(build2( ltdInfo->info[newLineCnt].label_name, ':  '
                                                                , cg_temp_site, '  '
                                                                )
                                                         )
        endif
    with nocounter

    set ltdInfo->info[newLineCnt].display = ltdInfo->info[newLineCnt].label_name
endif

;Subcutaneous Insulin Pump
declare ip_act_cd    = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'INSULINPUMPACTIVITY'))
declare ip_site_cd   = f8 with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'INSULINPUMPSITE'))

declare ip_temp_site = vc with protect, noconstant('')

set includeLineInd = 0

select into 'nl:'
  
  from clinical_event ce
     , ce_date_result cdr
     
 where ce.encntr_id           =  e_id
   and ce.event_cd            in (ip_act_cd)
   and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd    in (modifiedCd, authverifyCd)
   and ce.event_class_cd      != placeholderCd
   
   and cdr.event_id = outerjoin(ce.event_id)
   and (   cdr.valid_until_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3))
        or cdr.valid_until_dt_tm = outerjoin(null)
       )
       
order by ce.event_cd, ce.event_end_dt_tm desc
head report
    
    if(trim(ce.result_val, 3) in ( 'Nurse Removed'
                                 , 'Self removed'
                                 , 'Unintentionally removed'
                                 ))
                                 
        includeLineInd = 0

    else
        includeLineInd = 1
    endif
    
with nocounter


if(includeLineInd = 1)
    set newLineCnt                                    = newLineCnt + 1
    set stat                                          = alterlist(ltdInfo->info, newLineCnt)
    set ltdInfo->info[newLineCnt].label_name          = 'Subcutaneous Insulin Pump'
    
    set ltdInfo->info[newLineCnt].sort_pos = 9        

    ;No duration for this one actually
    
    
    ;Okay... so no duration... but we get the colon if there is a site... and we don't if we don't...
    
    select into 'nl:'
      from clinical_event ce
    
     where ce.encntr_id           =  e_id
       and ce.event_cd            in (ip_site_cd)
       and ce.valid_until_dt_tm   >  cnvtdatetime(curdate,curtime3)
       and ce.result_status_cd    in (modifiedCd, authverifyCd)
       and ce.event_class_cd      != placeholderCd
    
    order by ce.event_cd, ce.event_start_dt_tm desc
    
    head report
        temp_site = trim(replace(ce.result_val, 'Other:', ''), 3)
        
        if(temp_site > ' ')
            ltdInfo->info[newLineCnt].label_name = notrim(build2( ltdInfo->info[newLineCnt].label_name, ':  '
                                                                , temp_site, '  '
                                                                )
                                                         )
        endif
    with nocounter

    set ltdInfo->info[newLineCnt].display = ltdInfo->info[newLineCnt].label_name
endif



;002<-


;Presentation?
if(size(ltdInfo->info,5) > 0)
    ;002: we don't want to have uppercases/lowercase messing with sorting.  So I'm cnvtuppering it.
    ;002: for a hot second I was trimming location leading spaces too... but I think my work above when setting location fixed this.
    ;002: I hope this is right... but we shouldn't use the colon for sorting either...

    call echorecord(ltdInfo)
    select into "nl:"
             sort     = ltdInfo->info[d.seq].sort_pos
           , display  = cnvtupper(replace(substring(1,350,ltdInfo->info[d.seq].label_name), ':', '', 0))
           , location = cnvtupper(substring(1,100,ltdInfo->info[d.seq].location))
           , duration = ltdInfo->info[d.seq].durationVal
      from (dummyt d with seq = size(ltdInfo->info,5))
      plan d
    order by sort,display,location,duration,d.seq
    head report
        lineCnt = 1

        stat = alterlist(displayQual->line_qual,lineCnt)

        displayqual->line_qual[lineCnt].disp_line = build2(rhead, rh2bu ,'Lines' , rh2r)

    head d.seq
        lineCnt = lineCnt + 1

        stat = alterlist(displayQual->line_qual,lineCnt)

        displayqual->line_qual[lineCnt].disp_line = build2(reol,ltdInfo->info[d.seq].display)


    foot report
        ;They now want a footer on this guy, only when we have data:
        lineCnt = lineCnt + 1

        stat = alterlist(displayQual->line_qual,lineCnt)

        displayqual->line_qual[lineCnt].disp_line = build2(reol, wb ,'Indications/Plans for Lines:' , rh2r)


        for (dispIdx = 1 to lineCnt)
            reply->text = build2(reply->text,displayQual->line_qual[dispIdx].disp_line)
        endfor
    with nocounter

else
    set reply->text = rhead

endif

set reply->status_data->status = "S"

set reply->text = concat(reply->text, rtfeof)


call echojson(ltdInfo,'6_st_cc_ltds_cc_comp.dat')


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


call echorecord(reply)

call echo(reply->text)

end
go
