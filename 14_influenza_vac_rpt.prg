/*************************************************************************
 Program Title: PromptCare Rapid Influenza - Weekly

 Object name:   14_influenza_vac_rpt
 Source file:   14_influenza_vac_rpt.prg

 Purpose:       Coming in late for this... but looks like gathers information
                tied to influenza vaccinations to display.

                Somehow uses tracking groups for this.

 Tables read:   person
                orders
                encounter
                encntr_loc_hist
                encntr_alias
                dcp_forms_activity_comp
                dcp_forms_activity
                clinical_event

 Executed from: This is in explorer menu at Published Reports->Ambulatory->Ambulatory Reports->PromptCare->
                                            PromptCare Rapid Influenza - Weekly

                                            Doesn't seem hooked into an ops?

 Special Notes:

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 ???        ???                  ???    No mod block here when I made my adjustment (mmm174)
                                           CCLPROT says Simeon last touch at 2020-05-20
002 2021-08-04 Michael Mayes        228575 Locations need to be adjusted for name.  Simeon
                                           suggests dropping tracking group... moving to
                                           facility.
003 2021-08-20 Michael Mayes               (TASK4720066) The summary by itself is missing
                                                         substrings...causing data truncaation.
                                                         Going to accountfor that in this task.
004 2024-03-18 Michael Mayes        346549 (SCTASK0079417) There were results the report was missing after workflow changes
                                           at the UC locations.  These workflow adjustments are in flight, but what was needed here
                                           was to look for different forms and results, still after influ a and b... but
                                           they were different events and forms.  Added those.
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/

  drop program 14_influenza_vac_rpt go
create program 14_influenza_vac_rpt

prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Prompt Care Facility"      = 0
	, "Start Date"                = "SYSDATE"
	, "End Date"                  = "SYSDATE"
	, "Output Type"               = "1"

with OUTDEV, facility_cd, STARTDATE, ENDDATE, outType


;---------------------------------------------------------------------------------------------------------------------------------
;  Includes Files
;---------------------------------------------------------------------------------------------------------------------------------
%i cust_script:sc_cps_parse_date_subs.inc


;---------------------------------------------------------------------------------------------------------------------------------
; Variable Declaration
;---------------------------------------------------------------------------------------------------------------------------------
declare index         = i4
declare index2        = i4
declare num           = i4  with public ,   noconstant(0)
declare start         = i4  with public ,   noconstant(1)
declare 200_inf_order = f8  with protect,     constant(uar_get_code_by("DISPLAYKEY", 200, "BILLFORAMBPOCRAPIDINFLUENZA87804" ))
declare 72_infA_cd    = f8  with protect,     constant(uar_get_code_by("DISPLAYKEY",  72, "INFLUENZAAPOC"                    ))
declare 72_infB_cd    = f8  with protect,     constant(uar_get_code_by("DISPLAYKEY",  72, "INFLUENZABPOC"                    ))
declare EA_MRN_CD     = f8  with protect,     constant(uar_get_code_by(   'DISPLAY', 319, 'MRN'                              ))
declare EA_FIN_CD     = f8  with protect,     constant(uar_get_code_by(   'DISPLAY', 319, 'FIN NBR'                          ))
declare auth_cd       = f8  with protect,     constant(uar_get_code_by(   "MEANING",   8, "AUTH"                             ))
declare mod_cd        = f8  with protect,     constant(uar_get_code_by(   "MEANING",   8, "MODIFIED"                         ))
declare alter_cd      = f8  with protect,     constant(uar_get_code_by(   "MEANING",   8, "ALTERED"                          ))
declare startdate     = dq8 with protect,     constant(ParseDatePrompt($startDate, curdate, 000000                           ))
declare enddate       = dq8 with protect,     constant(ParseDatePrompt($endDate, curdate, 235959                             ))
declare ARRIVE_ID     = f8  WITH PROTECTED, NOCONSTANT(0.0)

;003 This should be 9?  Not 8?
declare dateRange     = vc with protect,constant(build2( substring(1, textlen($startdate)-9, $startdate)
                                                       , " TO "
                                                       , substring(1, textlen($enddate)-9, $enddate)))

call echo(build2( "Date Range: "
                , format(cnvtdatetime($startdate), "@SHORTDATETIME")
                , " - "
                , format(cnvtdatetime($enddate), "@SHORTDATETIME")))


;---------------------------------------------------------------------------------------------------------------------------------
; Record structures
;---------------------------------------------------------------------------------------------------------------------------------
record finalList(
    1 summqual[*]
        2 facility_cd           = f8  ;002 Changing name here.
        2 facility_nm           = vc  ;002 Changing name here.
        2 vac_Cnt               = f8
        2 vac_postv_cnt         = f8
        2 vac_a_cnt             = f8
        2 vac_b_cnt             = f8
        2 vac_perct             = vc
    1 qual[*]
        2 facility_cd           = f8  ;002 Changing name here.
        2 form_nm               = vc
        2 event_Date            = dq8
        2 event_dtm             = vc
        2 dcp_forms_activity_id = f8
        2 person_id             = f8
        2 encntr_id             = f8
        2 admn_location         = vc
        2 patient_name          = vc
        2 patient_mrn           = vc
        2 patient_fin           = vc
        2 order_id              = f8
        2 ordername             = vc
        2 orderdate             = vc
        2 influ_a_result        = vc
        2 influ_b_result        = vc
    1 outputqual[*]
        2 field1                = vc
        2 field2                = vc
        2 field3                = vc
        2 field4                = vc
        2 field5                = vc
        2 field6                = vc
        2 field7                = vc
        2 field8                = vc
        2 field9                = vc
        2 field10               = vc
        2 field11               = vc
)


;---------------------------------------------------------------------------------------------------------------------------------
; Main
;---------------------------------------------------------------------------------------------------------------------------------
SELECT  INTO "nl:"
;002 Removing these
;  FROM TRACKING_CHECKIN   TC
;     , TRACKING_ITEM      TI
;;     , TRACKING_EVENT     TE
  FROM ENCOUNTER          E
     , ENCNTR_LOC_HIST    ELH
     , PERSON             P
     , encntr_alias       ea
     , encntr_alias       ea2
     , orders             o
     , dcp_forms_activity dfa
/* 002 This is the old join plan.
  PLAN TC
   where TC.CHECKIN_DT_TM         >= CNVTDATETIME($startdate)
     AND TC.CHECKIN_DT_TM         <= CNVTDATETIME($enddate)
     AND TC.TRACKING_GROUP_CD     =  $trackGroupCd

     AND TC.ACTIVE_IND + 0        =  1

  JOIN TI
   WHERE TI.TRACKING_ID           =  TC.TRACKING_ID
     AND TI.ACTIVE_IND            =  1

; JOIN TE
;   WHERE TE.TRACKING_ID = TI.TRACKING_ID
;   AND TE.TRACK_EVENT_ID = ARRIVE_cd
;   AND TE.complete_dt_tm != NULL
;   AND TE.COMPLETE_DT_TM BETWEEN cnvtdatetime($startDate) AND CNVTDATETIME ($enddate)

  JOIN P
   WHERE P.PERSON_ID              =  TI.PERSON_ID
     AND P.ACTIVE_IND             =  1
     and (     (p.name_last_key not in ("ZZ*","CERNER*"))
           and (p.name_first_key not in ("CERNER*"))
         )
*/
;002-> New plan here.
  PLAN E
   WHERE E.REG_DT_TM              >= CNVTDATETIME($startdate)
     AND E.REG_DT_TM              <= CNVTDATETIME($enddate)
     AND E.LOC_FACILITY_CD        =  $facility_cd

     AND E.ACTIVE_IND             =  1

  JOIN P
   WHERE P.PERSON_ID              =  E.PERSON_ID
     AND P.ACTIVE_IND             =  1
     and (     (p.name_last_key not in ("ZZ*","CERNER*"))
           and (p.name_first_key not in ("CERNER*"))
         )
;002<-
  JOIN ELH
   WHERE ELH.encntr_id            =  E.encntr_id
     AND ELH.encntr_loc_hist_id   =  (select MIN(ELH2.encntr_loc_hist_id)
                                        FROM ENCNTR_LOC_HIST ELH2
                                       WHERE ELH2.encntr_id = E.ENCNTR_ID
                                         ;and ELH2.med_service_cd != 5042122.00
                                     )
     AND ELH.med_service_cd       != 5042122.00

  join ea
   where ea.encntr_id             =  e.encntr_id
     and ea.active_ind            =  1
     and ea.end_effective_dt_tm   >  sysdate
     and ea.encntr_alias_type_cd  =  1077

  join ea2
   where ea2.encntr_id            =  e.encntr_id
     and ea2.encntr_alias_type_cd =  1079.00
     and ea2.end_effective_dt_tm  >  cnvtdatetime(curdate,curtime3)
     and ea2.active_ind           =  1

  join o
   where o.encntr_id              =  e.encntr_id  ;002 Had to move columns due to removed tables.
     and o.catalog_cd             in (832860811.00, 4991176399.00)    ;004 adding Bill For AMB POC COVID/ Influenza PCR

  join dfa
   where dfa.dcp_forms_ref_id     in (2686638749.00, 26680640329.00)  ;004 adding Covid Infl Form.
     and dfa.person_id            =  p.person_id  ;002 Had to move columns due to removed tables.
     and dfa.encntr_id            =  e.encntr_id  ;002 Had to move columns due to removed tables.
     and dfa.active_ind           =  1
     and dfa.form_status_cd       in (25.00, 35.00)
ORDER BY E.LOC_FACILITY_CD, p.person_id, e.reg_dt_tm desc  ;002 Had to move columns due to removed tables.

head report
    index = 0
    index2 = 0

head E.LOC_FACILITY_CD  ;002 Had to move columns due to removed tables.
    index2 = index2 + 1

    stat = alterlist(finalList->summqual, index2)

    finalList->summqual[index2].facility_cd = E.LOC_FACILITY_CD  ;002 var name change, and column change due to table adjust.
    finalList->summqual[index2].facility_nm = uar_get_code_display(E.LOC_FACILITY_CD)  ;002 var name change, and column change

head p.person_id  ;002 var name change, and column change due to table adjust.
    index = index + 1

    if (mod(index, 50) = 1)
        stat = alterlist(finalList->qual, index + 49)
    endif

    finalList->summqual[index2].vac_Cnt = finalList->summqual[index2].vac_Cnt + 1

    call echo(p.person_id)  ;002 var name change, and column change due to table adjust.

    finalList->qual[index].facility_cd           = e.loc_facility_cd  ;002 var name change, and column change due to table adjust.
    finalList->qual[index].person_id             = p.person_id        ;002 var name change, and column change due to table adjust.
    finalList->qual[index].encntr_id             = e.encntr_id        ;002 var name change, and column change due to table adjust.
    finalList->qual[index].patient_name          = p.name_full_formatted
    finalList->qual[index].order_id              = o.order_id
    finalList->qual[index].ordername             = uar_get_code_display(o.catalog_cd)
    finalList->qual[index].orderdate             = format(o.orig_order_dt_tm, "MM/DD/YYYY HH:MM;;Q")
    finalList->qual[index].admn_location         = trim(uar_get_code_display(e.loc_facility_cd),3)
    finalList->qual[index].form_nm               = dfa.description
    finalList->qual[index].event_Date            = dfa.beg_activity_dt_tm
    finalList->qual[index].event_dtm             = format(dfa.beg_activity_dt_tm,"MM/DD/YYYY HH:MM;;")
    finalList->qual[index].dcp_forms_activity_id = dfa.dcp_forms_activity_id
    finalList->qual[index].patient_fin           = cnvtalias(ea.alias, ea.alias_pool_cd)
    finalList->qual[index].patient_mrn           = cnvtalias(ea2.alias, ea2.alias_pool_cd)

foot report
    stat = alterlist(finalList->qual, index)
with nocounter, time=600

if(size(finalList->qual[index],5)<1)
    go to no_result
endif


;---------------------------------------------------------------------------------------------------------------------------------
; Get Result
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
      ce3.person_id
    , format(ce3.event_end_dt_tm,"MM/DD/YYYY HH:MM;;")
    , event_name = build2(trim(uar_get_Code_display(ce3.event_cd),3),":",ce3.result_val)
  FROM (dummyt d with seq = size(finalList->qual,5))
     , dcp_forms_activity_comp dfac
     , clinical_event          ce
     , clinical_event          ce1
     , clinical_event          ce2
     , clinical_event          ce3
  plan d
  join dfac
   where dfac.dcp_forms_activity_id = finalList->qual[d.seq].dcp_forms_activity_id
  join ce
   where ce.EVENT_ID                =  dfac.parent_entity_id
     and ce.valid_until_dt_tm       >  CNVTDATETIME(CURDATE, CURTIME3)
     and ce.result_status_cd        in (auth_cd, mod_cd, alter_cd)
  join ce1
   where ce1.parent_event_id        =  ce.event_id
     and ce1.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)
     and ce1.result_status_cd       in (auth_cd, mod_cd, alter_cd)
     and ce1.person_id              =  ce.person_id
     and ce1.encntr_id              =  ce.encntr_id
  join ce2
   where ce2.parent_event_id        =  ce1.event_id
     and ce2.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)
     and ce2.result_status_cd       in (auth_cd, mod_cd, alter_cd)
  join ce3
   where ce3.parent_event_id        =  ce2.event_id
     and ce3.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)
     and ce3.result_status_cd       in (auth_cd, mod_cd, alter_cd)
     and ce3.event_cd               in ( 823593677.00  , 823593687.00
                                       , 5015961323.00 , 5015962387.00)   ;004 Adding POC Influenza A PCR and POC Influenza B PCR
order by ce3.person_id, ce3.event_cd
head ce3.person_id
    null

    call echo(build2(cnvtstring(ce3.person_id), " ",trim(ce3.result_val,3)))

head ce3.event_cd
    pos = locateval(num, start, size(finalList->summqual,5), finalList->qual[d.seq].facility_cd
                              , finalList->summqual[num].facility_cd)  ;002 Var name changes here.

    call echo(build2("position:",cnvtstring(pos)))

    case (ce3.event_cd)
    of 823593677.00:
    of 5015961323.00:
        call echo(build2(cnvtstring(ce3.person_id), " ",trim(ce3.result_val,3)))

        finalList->qual[d.seq].influ_a_result = trim(ce3.result_val,3)

        if(cnvtlower(trim(ce3.result_val,3)) ="positive")
            finalList->summqual[pos].vac_postv_cnt = finalList->summqual[pos].vac_postv_cnt + 1
            finalList->summqual[pos].vac_a_cnt     = finalList->summqual[pos].vac_a_cnt + 1
        endif
    of 823593687:
    of 5015962387:
        call echo(build2(cnvtstring(ce3.person_id), " ",trim(ce3.result_val,3)))

        finalList->qual[d.seq].influ_b_result = trim(ce3.result_val,3)

        if(cnvtlower(trim(ce3.result_val,3)) ="positive")
            finalList->summqual[pos].vac_postv_cnt = finalList->summqual[pos].vac_postv_cnt + 1
            finalList->summqual[pos].vac_b_cnt     = finalList->summqual[pos].vac_b_cnt + 1
        endif
    endcase

with nocounter


;---------------------------------------------------------------------------------------------------------------------------------
; Output
;---------------------------------------------------------------------------------------------------------------------------------

if($outType = "1")
    if(size(finalList->qual,5) > 0)
        select into $OUTDEV
              PATIENT_NAME       = substring(1, 500, finalList->qual[d.seq].patient_name  )
            , FIN                = substring(1,  15, finalList->qual[d.seq].patient_fin   )
            , MRN                = substring(1,  15, finalList->qual[d.seq].patient_mrn   )
            , LOCATION           = substring(1, 200, finalList->qual[d.seq].admn_location )
            , ORDER_NAME         = substring(1, 500, finalList->qual[d.seq].ordername     )
            , DATE_DOCUMENTED    = substring(1, 500, finalList->qual[d.seq].event_dtm     )
            , INFLUENZA_A_RESULT = substring(1, 500, finalList->qual[d.seq].influ_a_result)
            , INFLUENZA_B_RESULT = substring(1, 500, finalList->qual[d.seq].influ_b_result)
        from (dummyt d with seq = size(finalList->qual,5))
        with FORMAT, SEPARATOR = " "
    endif

elseif($outType = "2")
    if(size(finalList->summqual,5) > 0)
        ;003-> adding substrings to all this jazz
        select into $OUTDEV
              LOCATION            = substring(1, 50, trim(finalList->summqual[d.seq].facility_nm, 3 ))  ;002 var name change.
            , DATE_RANGE          = substring(1, 30, trim(dateRange, 3                              ))
            , TOTAL_#             = substring(1,  5, cnvtstring(finalList->summqual[d.seq].vac_Cnt  ))
            , COUNT_OF_POSITIVE_A = substring(1, 20, cnvtstring(finalList->summqual[d.seq].vac_a_cnt))
            , COUNT_OF_POSITIVE_B = substring(1, 20, cnvtstring(finalList->summqual[d.seq].vac_b_cnt))
            , PERCENT_VE          = substring(1, 15, build2(trim(cnvtstring(round(100*(finalList->summqual[d.seq].vac_postv_cnt/
                                                                            finalList->summqual[d.seq].vac_Cnt),2)),3)
                                                                 ,"%"))
        from
            (dummyt d with seq = size(finalList->summqual,5))
        with FORMAT, SEPARATOR = " "
        ;003<-
    endif

elseif($outType = "3")
    if(size(finalList->summqual,5) > 0)
        set stat = alterlist(finalList->outputqual,size(finalList->summqual,5)+6)

        set finalList->outputqual[1].field1 = "SUMMARY"
        set finalList->outputqual[2].field1 = "LOCATION"
        set finalList->outputqual[2].field2 = "DATE RANGE"
        set finalList->outputqual[2].field3 = "TOTAL #"
        set finalList->outputqual[2].field4 = "COUNT_OF_POSITIVE_A"
        set finalList->outputqual[2].field5 = "COUNT_OF_POSITIVE_B"
        set finalList->outputqual[2].field6 = "PERCENT +VE"

        for(index =1 to size(finalList->summqual,5))
            set index2 = index + 2
            set finalList->summqual[index].vac_perct = build2(trim(cnvtstring(round(100*(finalList->summqual[index].vac_postv_cnt/
                                                                                         finalList->summqual[index].vac_Cnt),2)),3)
                                                             ,"%")
            set finalList->outputqual[index2].field1 = trim(finalList->summqual[index].facility_nm,3)  ;002 var name change.
            set finalList->outputqual[index2].field2 = trim(dateRange                             ,3)
            set finalList->outputqual[index2].field3 = cnvtstring(finalList->summqual[index].vac_Cnt  )
            set finalList->outputqual[index2].field4 = cnvtstring(finalList->summqual[index].vac_a_cnt)
            set finalList->outputqual[index2].field5 = cnvtstring(finalList->summqual[index].vac_b_cnt)
            set finalList->outputqual[index2].field6 = finalList->summqual[index].vac_perct
        endfor
        set index2 = size(finalList->outputqual,5)
    endif

    if(size(finalList->qual,5) > 0)
        set finalList->outputqual[index2 -1].field1 = "DETAIL"
        set finalList->outputqual[index2].field1    = "PATIENT NAME"
        set finalList->outputqual[index2].field2    = "FIN"
        set finalList->outputqual[index2].field3    = "MRN"
        set finalList->outputqual[index2].field4    = "LOCATION"
        set finalList->outputqual[index2].field5    = "ORDER NAME"
        set finalList->outputqual[index2].field6    = "DATE DOCUMENTED"
        set finalList->outputqual[index2].field7    = "INFLUENZA A RESULT"
        set finalList->outputqual[index2].field8    = "INFLUENZA B RESULT"

        set stat = alterlist(finalList->outputqual,size(finalList->qual,5)+index2)

        for(index =1 to size(finalList->qual,5))
            set index2 = index2 + 1

            set finalList->outputqual[index2].field1 = substring(1, 500,finalList->qual[index].patient_name  )
            set finalList->outputqual[index2].field2 = substring(1,  15, finalList->qual[index].patient_fin  )
            set finalList->outputqual[index2].field3 = substring(1,  15, finalList->qual[index].patient_mrn  )
            set finalList->outputqual[index2].field4 = substring(1, 200,finalList->qual[index].admn_location )
            set finalList->outputqual[index2].field5 = substring(1, 500,finalList->qual[index].ordername     )
            set finalList->outputqual[index2].field6 = substring(1, 500,finalList->qual[index].event_dtm     )
            set finalList->outputqual[index2].field7 = substring(1, 500,finalList->qual[index].influ_a_result)
            set finalList->outputqual[index2].field8 = substring(1, 500,finalList->qual[index].influ_b_result)
        endfor
    endif

    call echo(build2("Index 2:",index2))
    call echorecord(finalList)


    ;-------------------------------------------------------------------------------------------------------------------------------
    ; GENERATE THE REPORT ERROR MESSAGE TO STandARD OUTPUT
    ;-------------------------------------------------------------------------------------------------------------------------------
    select into $OUTDEV
          field1 = substring(1,500,finalList->outputqual[d.seq].Field1)
        , field2 = substring(1,500,finalList->outputqual[d.seq].Field2)
        , field3 = substring(1,500,finalList->outputqual[d.seq].Field3)
        , field4 = substring(1,500,finalList->outputqual[d.seq].Field4)
        , field5 = substring(1,500,finalList->outputqual[d.seq].Field5)
        , field6 = substring(1,500,finalList->outputqual[d.seq].Field6)
        , field7 = substring(1,500,finalList->outputqual[d.seq].Field7)
        , field8 = substring(1,500,finalList->outputqual[d.seq].Field8)
    from
        (dummyt d with seq = size(finalList->outputqual, 5))
    WITH FORMAT, SEPARATOR = " "
endif



;select into $OUTDEV
;     PatientName        = substring(1, 500,finalList->qual[d1.seq].patient_name   )
;   , FIN                = substring(1,  15, finalList->qual[d1.seq].patient_fin   )
;   , MRN                = substring(1,  15, finalList->qual[d1.seq].patient_mrn   )
;   , Location           = substring(1, 200,finalList->qual[d1.seq].admn_location  )
;   , ORDER_Name         = substring(1, 500,finalList->qual[d1.seq].ordername      )
;   , Date_documented    = substring(1, 500,finalList->qual[d1.seq].event_dtm      )
;   , INFLUENZA_A_RESULT = substring(1, 500,finalList->qual[d1.seq].influ_a_result )
;   , INFLUENZA_B_RESULT = substring(1, 500,finalList->qual[d1.seq].influ_b_result )
;   , form_id            = cnvtstring(finalList->qual[d1.seq].dcp_forms_activity_id)
;   from (dummyt d1 with seq = size(finalList->qual, 5))
;   plan d1
;   order by finalList->qual[d1.seq].event_dtm
;   WITH NOCOUNTER, SEPARATOR=" ", FORMAT
;
#no_result


end
go

