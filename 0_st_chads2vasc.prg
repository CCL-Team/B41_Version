/*********************************************************************************************************************************
 Date Written:   April 1, 2020
 Source file:    0_st_chads2vasc
 Directory:      CUST_SCRIPT:
 Purpose:        To retrieve Anticoag powerform results charted on current encounter of a patient.
 Tables updated: NONE
 Executed from:  Office/Clinic Note - Anticoag

 Tables read: clinical_event
              encounter

Special Notes: N/A
**********************************************************************************************************************************
                MODIFICATION CONTROL LOG
**********************************************************************************************************************************

Mod Date       Developer       MCGA   Comment
--- ---------- --------------- ------ --------------------------------------------------------------------------------------------
000 10/09/2020 Monica Isaac    219626 Initial Release (code taken from jdm13_st_meas_enc
001 10/22/2020 Kim Frazier     224149 Break/Fix anticoag upper/lower goals not showing
002 06/30/2021 jwd107                 add anticipated stop date
003 12/08/2021 saa126          229823 Complete rewrite, old prg backed up as
                                      cust_script:0_st_chads2vasc_backup
004 05/12/2023 Michael Mayes   236841 Adding a new DTA Last Telehealth consent signed date
005 07/05/2023 Michael Mayes   238359 Adding INR Assessment to what we pull here.
006 08/05/2023 Michael Mayes   PEND   Correcting DTA label.

007 08/24/2023 Michael Mayes   PEND   SCTASK0041111 And they changed it again.
008 09/06/2023 Michael Mayes   240182 SCTASK0043598 They changed the DTA Display and broke this.
009 09/11/2024 Swetha Srini    SCTASK0113179 Event Code Update from TYPEOFVISIT to VISITTYPEAMB
010 12/2024    Wendy Ltiwinski #347867 Add inr
011 05/30/2025 Michael Mayes   353328 SCTASK0167092 - Now we don't want Telehealth date on here... go figure.
************  END OF ALL MODCONTROL BLOCKS  *************************************************************************************/
  drop program 0_st_chads2vasc:dba go
create program 0_st_chads2vasc:dba


%i cust_script:0_rtf_template_format.inc


free record st_rec
record st_rec(
    1 item[*]
        2 sort_ind = i4
        2 displ    = vc
)


declare rtfStr = vc


set rtfStr = build2(rhead, rtfStr,rtfeof)
;Prep Record Structure
set stat = alterlist(st_rec->item, 18)  ;004 005 011 Manipulating count.

set st_rec->item[1 ].displ    = build2(wb, "Order Physician Anticoag: ")
set st_rec->item[1 ].sort_ind = 1

set st_rec->item[2 ].displ    = build2(wb, "Anticoag Ordering Physician: ")
set st_rec->item[2 ].sort_ind = 2

set st_rec->item[3 ].displ    = build2(wb, "Information Given by: ")
set st_rec->item[3 ].sort_ind = 3

set st_rec->item[4 ].displ    = build2(wb, "Anticoag Source: ")
set st_rec->item[4 ].sort_ind = 4

set st_rec->item[5 ].displ    = build2(wb, "Visit Type AMB: ")
set st_rec->item[5 ].sort_ind = 5

set st_rec->item[6 ].displ    = build2(wb, "Anticoag Indication: ")
set st_rec->item[6 ].sort_ind = 6

set st_rec->item[7 ].displ    = build2(wb, "Anticoag Start: ")
set st_rec->item[7 ].sort_ind = 7

set st_rec->item[8 ].displ    = build2(wb, "Anticoag Anticipated Stop: ")
set st_rec->item[8 ].sort_ind = 8

set st_rec->item[9 ].displ    = build2(wb, "Anticoag duration: ")
set st_rec->item[9 ].sort_ind = 9

;set st_rec->item[10].displ    = build2(wb, "INR - Transcribed: ")
set st_rec->item[10].displ    = build2(wb, "INR: ") ;010
set st_rec->item[10].sort_ind = 10

set st_rec->item[11].displ    = build2(wb, "Anticoag INR Goal Lower: ")
set st_rec->item[11].sort_ind = 11

set st_rec->item[12].displ    = build2(wb, "Anticoag INR Goal Upper: ")
set st_rec->item[12].sort_ind = 12

set st_rec->item[13].displ    = build2(wb, "INR Assessment: ")
set st_rec->item[13].sort_ind = 13

set st_rec->item[14].displ    = build2(wb, "Warfarin Dosage: ")
set st_rec->item[14].sort_ind = 14

set st_rec->item[15].displ    = build2(wb, "Warfarin Dosage: ")
set st_rec->item[15].sort_ind = 15

set st_rec->item[16].displ    = build2(wb, "Patient on Other Anticoagulant: ")
set st_rec->item[16].sort_ind = 16

set st_rec->item[17].displ    = build2(wb, "CHADS2VASC Score: ")
set st_rec->item[17].sort_ind = 17

set st_rec->item[18].displ    = build2(wb, "HAS-BLED Score: ")
set st_rec->item[18].sort_ind = 18

;011 Removing this.
;set st_rec->item[19].displ    = build2(wb, "Last Telehealth Consent Date: ")  ;004 ;006 ;007
;set st_rec->item[19].sort_ind = 19                                            ;004


declare form_activity_id = f8

declare telehealth_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'LASTTELEHEALTHCONSENTDATE'))  ;006
declare inr_ass_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'INRASSESSMENT'            ))  ;005

select max_ref = max(dfa2.dcp_forms_activity_id)
  from  dcp_forms_activity dfa2

 where dfa2.encntr_id        =  request->visit[1]->encntr_id
   and dfa2.dcp_forms_ref_id =  2479777319;d.dcp_forms_ref_id
   and dfa2.active_ind       =  1
   and dfa2.form_status_cd   in (25.00, 35.00)

head report
    form_activity_id = max_ref

with nocounter


if(form_activity_id >= 0)
    select into "nl:"
          d.beg_activity_dt_tm
        , d.dcp_forms_activity_id
        , ce3.event_cd
        , uar_get_code_display(ce3.event_cd)
        , ce3.result_val
        , cdr_date      = format( cdr.result_dt_tm, "MM/DD/YYYY")
        , document_type = D.description
        , encntr_id     = d.encntr_id
        , person_id     = e.person_id
        , activity_id   = dfc.dcp_forms_activity_id
        , form_mod      = format(d.last_activity_dt_tm, "MM/DD/YYYY hh:mm:ss")
        , form_date     = format(d.form_dt_tm, "MM/DD/YYYY hh:mm:ss")
        , format(d.beg_activity_dt_tm, "MM/DD/YYYY hh:mm:ss")

     from dcp_forms_activity   d
        , dcp_forms_activity_comp dfc
        , encounter e
        , clinical_event ce1
        , clinical_event ce2
        , clinical_event ce3
        , ce_date_result cdr
        , ce_blob ceb

     plan d
      where d.encntr_id               =       request->visit[1]->encntr_id
        and d.active_ind              =       1
        and d.dcp_forms_ref_id        =       2479777319.00
        and d.form_status_cd          in      (25.00, 34.00, 35.00)
        and d.dcp_forms_activity_id   =       form_activity_id

     join e
      where e.encntr_id               =       d.encntr_id

     join dfc
      where dfc.dcp_forms_activity_id =       d.dcp_forms_activity_id
        and dfc.parent_entity_name    =       "CLINICAL_EVENT"

     join ce1
      where ce1.parent_event_id       =       dfc.parent_entity_id
        and ce1.valid_until_dt_tm     =       cnvtdatetime("31-DEC-2100 00:00:00.00")

     join ce2
      where ce2.parent_event_id       =       ce1.event_id
        and ce2.valid_until_dt_tm     =       cnvtdatetime("31-DEC-2100 00:00:00.00")
        and ce2.event_end_dt_tm       between cnvtdatetime("01-JAN-1970 0000")
                                          and cnvtdatetime(curdate,curtime3)
        and ce2.result_status_cd      in (25.00,33.00,35.00)

     join ce3
      where ce3.PARENT_EVENT_id   =  ce2.EVENT_id
        and ce3.view_level        =  1
        and ce3.VALID_UNTIL_DT_TM >= cnvtdatetime(curdate,curtime3)
        AND ce3.EVENT_TAG         != "In Error"
        and ce3.event_cd          in ( 1014996745      ;1    ORDERINGPHYSICIANANTICOAG
                                     ,  823630303      ;2    ANTICOAGORDERINGPHYSICIAN
                                     ,     704849      ;3    INFORMATIONGIVENBY
                                     ,  823630343      ;4    ANTICOAGSOURCE
                                     ,  2338710479      ;5    VISITTYPEAMB
                                     ,  823630293      ;6    ANTICOAGINDICATION
                                     ,  823630263      ;7    ANTICOAGSTART
                                     , 1643945171      ;8    ANTICIPATEDSTOPDATE
                                     ,  823630273      ;9    ANTICOAGDURATION
                                      ;,  823772313      ;10   INRTRANSCRIBED
                                     ; ,  5103209.00            ;010
                                     ,  823630323      ;11   ANTICOAGINRGOALLOWER
                                     ,  823630333      ;12   ANTICOAGINRGOALUPPER
                                     ,  inr_ass_cd     ;13   ;005 INRASSESSMENT
                                     ,  823630363      ;14   ANTICOAGWARFARINDOSAGE
                                     ,  823834975      ;15   WARFARINDOSAGE
                                     ,  823630253      ;16   PATIENTONOTHERANTICOAGULANT
                                     ,  823785941      ;17   ANTICOAGULATIONTHERAPY
                                     ,  823785401      ;18   HASBLEDSCORE
                                     ;011 Removing this.
                                     ;,  telehealth_cd  ;19   ;004 LASTTELEHEALTHCONSENTSIGNEDDATETIME
                                     )

     join cdr
      where cdr.event_id          =  outerjoin(ce3.event_id)

     join ceb
         where ceb.event_id       =  outerjoin(ce3.event_id)


    order by d.encntr_id
           , ce3.event_cd
           , d.beg_activity_dt_tm desc


    head d.encntr_id
        null





     head ce3.event_cd

        case(ce3.event_cd)
            of 1014996745: st_rec->item[ 1].displ = build2(st_rec->item[ 1].displ, wr, trim(ce3.result_val                        ))
            of 823630303 : st_rec->item[ 2].displ = build2(st_rec->item[ 2].displ, wr, trim(ce3.result_val                        ))
            of 704849    : st_rec->item[ 3].displ = build2(st_rec->item[ 3].displ, wr, trim(ce3.result_val                        ))
            of 823630343 : st_rec->item[ 4].displ = build2(st_rec->item[ 4].displ, wr, trim(ce3.result_val                        ))
            of 2338710479: st_rec->item[ 5].displ = build2(st_rec->item[ 5].displ, wr, trim(ce3.result_val                        ))
            of 823630293 : st_rec->item[ 6].displ = build2(st_rec->item[ 6].displ, wr, trim(ce3.result_val                        ))
            of 823630263 : st_rec->item[ 7].displ = build2(st_rec->item[ 7].displ, wr, trim(format(cdr.result_dt_tm, "MM/DD/YYYY")))
            of 1643945171: st_rec->item[ 8].displ = build2(st_rec->item[ 8].displ, wr, trim(format(cdr.result_dt_tm, "MM/DD/YYYY")))
            of 823630273 : st_rec->item[ 9].displ = build2(st_rec->item[ 9].displ, wr, trim(ce3.result_val                        ))
            ;of 823772313 : st_rec->item[10].displ = build2(st_rec->item[10].displ, wr, trim(ce3.result_va)) ;010
            of 823630323 : st_rec->item[11].displ = build2(st_rec->item[11].displ, wr, trim(ce3.result_val                        ))
            of 823630333 : st_rec->item[12].displ = build2(st_rec->item[12].displ, wr, trim(ce3.result_val                        ))
            of inr_ass_cd: st_rec->item[13].displ = build2(st_rec->item[13].displ, wr, trim(ce3.result_val                        ))
            of 823630363 : st_rec->item[14].displ = build2(st_rec->item[14].displ, wr, trim(ce3.result_val                        ))
            of 823834975 : st_rec->item[15].displ = build2(st_rec->item[15].displ, wr, trim(ce3.result_val                        ))
            of 823630253 : st_rec->item[16].displ = build2(st_rec->item[16].displ, wr, trim(ce3.result_val                        ))
            of 823785941 : st_rec->item[17].displ = build2(st_rec->item[17].displ, wr, trim(ce3.result_val                        ))
            of 823785401 : st_rec->item[18].displ = build2(st_rec->item[18].displ, wr, trim(ce3.result_val                        ))
            ;011 Removing this
            ;;004->
            ;of telehealth_cd :
            ;    st_rec->item[19].displ = build2(st_rec->item[19].displ, wr, trim(format(cdr.result_dt_tm, "MM/DD/YYYY")))
            ;;004<-
        endcase



    with nocounter


endif




/*********************************************************
grab inr and transcribed 010
**************************************************************/

 select into "nl:"


from
clinical_event ce3
where ce3.ENCNTR_ID =  request->visit[1]->encntr_id;250963757.00
        and ce3.view_level        =  1
        and ce3.VALID_UNTIL_DT_TM >= cnvtdatetime(curdate,curtime3)
        AND ce3.EVENT_TAG         != "In Error"
        and ce3.event_cd          in (
                                   823772313      ;10   INRTRANSCRIBED
                                     ,  5103209.00          ;010

                                     )
order by

ce3.EVENT_END_DT_TM desc

head ce3.EVENT_END_DT_TM
if(st_rec->item[10].displ = build2(wb, "INR: "))
    st_rec->item[10].displ = build2(st_rec->item[10].displ, wr, trim(ce3.result_val                        ))
endif

with nocounter




if(size(st_rec->item, 5) > 0)
    select into "nl:"
        sort_ind = st_rec->item[d.seq].sort_ind

      from (dummyt d with seq = size(st_rec->item, 5))

      plan d


    order by sort_ind

    head report
        rtfStr = build2("\plain \f1 \fs20 \b \ul \cb2 \pard\sl0 ","Overview",reol)

    detail
        rtfStr = build2(rtfStr,st_rec->item[d.seq].displ, reol)

    foot report
        rtfStr = build2(rhead, rtfStr,rtfeof)

    with nocounter

    call echo(rtfStr)
endif

;set rtfStr = tempStr
;set tempStr = concat(rtfStr, rtfeof)
set reply->text = rtfStr

;call echo(tempStr)
call echorecord(st_rec)

end
go