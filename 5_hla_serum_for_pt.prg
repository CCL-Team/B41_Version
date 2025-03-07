/*********************************************************************************************************************************
 Program Title:     HLA Serum Storage History
 Create Date:       03/02/2011
 Object name:       5_HLA_SERUM_STOR_HIST
 Source file:       5_HLA_SERUM_STOR_HIST.prg
 Purpose:           Display HLA Serum Storage order history for transplant candidate patients
 Tables read:       person_transplant_candidate, container, accession_order_r, orders, order_container_r
                    , person_alias, encntr_alis, person, order_action, prsnl
 Tables updated:    N/A
 Executed from:     Explorer Menu
 Programs Executed: N/A

 Special Notes:
************************************************************************
                                  MODIFICATION CONTROL LOG
************************************************************************
 Mod  Date        Analyst               OPAS           Comment
 ---  ----------  --------------------  ------         --------------------------------------------------------------------------
 001 02/14/2011   bpb01        OPAS#          Initial
 002 03/28/2011   Tameka Overton        OPAS#9659870   Add Transplant Center Prompt and DOB
 003 02/20/2012   Siddharth Shetty      OPAS#28923159  Converted Patient Name to uppercase
 004 03.26.2014   Kathleen R Entwistle  OPAS#12059588  Added Program Information.
 005 10.15.2015   Kathleen R Entwistle  R2:000046847501  Added distinct to output select statement to eliminate issue with
                                                        patient duplication.
 006 03/07/2025   Michael Mayes         352886         Change in format of DOB, to account for possible TZ entry and issues there.

*********************************END OF ALL MODCONTROL BLOCKS********************************************************************/

drop program 5_HLA_SERUM_FOR_PT go
create program 5_HLA_SERUM_FOR_PT

prompt
    "File/Printer/MINE" = "MINE"                    ;* Enter or select the printer or file name to send this report to.
    , "Patient Status" = VALUE(-1            )
    , "Organ" = VALUE(*             )
    , "Transplant Center" = VALUE(-1            )
    , "Drawn Base Date/Time" = "SYSDATE"
    , "Look back Qty" = "1"
    , "Units" = "Months"
    , "Report Type" = ""
    , "Most Recent Serum Drawn Date Only" = 0

with OUTDEV, PT_STATUS, ORGAN_TYPE, TRANS_LOC, BASE_DT, LOOK_BACK_QTY,
    LOOK_BACK_UNIT, RPT_TYPE, RECENT_ONLY


;Assoc. Layout prep
execute reportrtl
%i cust_script:5_HLA_SERUM_FOR_PT.dvl

record output
(
    1 cnt = i4
    1 pts[*]
        2 pt_name = vc
        2 ssn = vc
        2 dob = vc
        2 mrn = vc
        2 person_id = f8
        2 organ = vc
        2 status = vc
        2 xplant_cntr = vc
        2 cur_drug_thrpy = vc
        2 cont[*]
            3 accession = c20
            3 drawn_dt_tm = dq8
            3 ord_prov = vc
)

declare ANY = i1 with constant(-1), protect
declare lookback = vc with constant(concat($LOOK_BACK_QTY,',',$LOOK_BACK_UNIT)), protect
declare end_dt = dq8 with constant(cnvtdatetime($BASE_DT)), protect
declare beg_dt = dq8 with constant(cnvtlookbehind(lookback, cnvtdatetime(end_dt))), protect
declare HLA_SERUM_STOR_CD = f8 with constant(uar_get_code_by('DISPLAY', 200, 'HLA Serum Storage')), protect
declare ORD_COMP_CD = f8 with constant(uar_get_code_by('DISPLAY', 6004, 'Completed')), protect
declare PA_SSN_CD = f8 with constant(uar_get_code_by('DISPLAY', 4, 'SSN')), protect
declare EA_MRN_CD = f8 with constant(uar_get_code_by('DISPLAY', 319, 'MRN')), protect
declare GVC_PRSNL_NAME = vc with noconstant(' '), public
DECLARE GVC_RPT_TITLE_DISP = VC with constant('HLA Serum Storage History')
declare pt_status_disp = vc with noconstant(' '),protect
declare organ_type_disp = vc with noconstant(' '),protect
DECLARE MVC_TRANS_LOC = VC WITH NOCONSTANT(' '),PROTECT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Retrieve transplant patients with order HLA Serum Storage
;   and draw time was within lookback time frame
;   fill record structure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT INTO 'nl:'
    p.name_full_formatted
    , SSN = format(pa.alias, '###-##-####')
    , MRN = cnvtalias(ea_mrn.alias, ea_mrn.alias_pool_cd)
    , p.birth_dt_tm
    , status = uar_get_code_display(ptc.priority_cd)
    , organ = uar_get_code_display(ptc.organ_type_cd)
    , trans = uar_get_code_display(ptc.transplant_center_cd)
    , cur_drug_thrpy = check(ptc.current_drug_therapy)
    , aor.accession
    , c.drawn_dt_tm '@SHORTDATETIME'
    , draw_date = cnvtdate(c.drawn_dt_tm)
    , ordering_provider = pl.name_full_formatted
    ;006-> Changing the format call to prevent TZ issue here
    ;, DOB = format(p.birth_dt_tm, "MM/DD/YY ;;D")
    , DOB = datebirthformat(p.birth_dt_tm, p.birth_tz, 0, "MM/DD/YY ;;D")
    ;006<-
FROM
    person_transplant_candidate   ptc   ;List of patients
    , person   p                ;Person / patient info
    , person_alias   pa         ;SSN
    , orders   o                ;the HLA Serum Storage order using XIE3ORDERS
    , encntr_alias   ea_mrn     ;encounter MRN
    , order_container_r   ocr   ;link between order and the drawn blood container
    , accession_order_r   aor   ;link to accession
    , container   c             ;drawn blood container
    , order_action   oa         ;orig order action for ordering provider id
    , prsnl   pl                ;ordering provider

plan ptc
    where
        ptc.active_ind = 1
    and
    (
        ANY in ($PT_STATUS)
    or
        ptc.priority_cd in ($PT_STATUS)
    )
    and
    (
        ANY in ($ORGAN_TYPE)
    or
        ptc.organ_type_cd in ($ORGAN_TYPE)
    )

    and;002
    (
        ANY in ($TRANS_LOC)
    or
        ptc.transplant_center_cd in ($TRANS_LOC)
    )
join p
    where
        p.person_id = ptc.person_id
    and
        p.active_ind = 1
join o
    where
        o.person_id = p.person_id
    and
        o.catalog_cd = HLA_SERUM_STOR_CD
    and
        o.order_status_cd+0 = ORD_COMP_CD
join oa
    where
        oa.order_id = o.order_id
    and
        oa.action_sequence = 1  ;should always be the order action
join aor
    where
        aor.order_id = o.order_id
join ocr
    where
        ocr.order_id = o.order_id
join c
    where
        c.container_id = ocr.container_id
    and
        c.drawn_dt_tm+0 between cnvtdatetime(beg_dt) and cnvtdatetime(end_dt)
join ea_mrn
    where
        ea_mrn.encntr_id = outerjoin(o.encntr_id)
    and
        ea_mrn.active_ind = outerjoin(1)
    and
        ea_mrn.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))
    and
        ea_mrn.encntr_alias_type_cd = outerjoin(EA_MRN_CD)
join pa
    where
        pa.person_id = outerjoin(p.person_id)
    and
        pa.active_ind = outerjoin(1)
    and
        pa.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))
    and
        pa.person_alias_type_cd = outerjoin(PA_SSN_CD)
join pl
    where
        pl.person_id = outerjoin(oa.order_provider_id)

ORDER BY
    p.name_full_formatted
    , ptc.person_id
    , ptc.person_transplant_id
    , draw_date desc
    , c.container_id


head report
    pcnt = 0
head ptc.person_transplant_id
    pcnt = pcnt + 1
    stat = alterlist(output->pts, pcnt)
    output->pts[pcnt].pt_name = cnvtupper(p.name_full_formatted);003
    output->pts[pcnt].ssn = ssn
    output->pts[pcnt].mrn = mrn
    output->pts[pcnt].dob = dob
    output->pts[pcnt].person_id = p.person_id
    output->pts[pcnt].organ = organ
    output->pts[pcnt].status = status
    output->pts[pcnt].cur_drug_thrpy = cur_drug_thrpy
    output->pts[pcnt].xplant_cntr = uar_get_code_display(ptc.transplant_center_cd)
    ccnt = 0

    ddate = draw_date
head draw_date
    if ($RECENT_ONLY = 0)
        ddate = draw_date
    endif
head c.container_id
    if (draw_date = ddate)
        ccnt = ccnt + 1
        stat = alterlist(output->pts[pcnt].cont, ccnt)
        output->pts[pcnt].cont[ccnt].accession = aor.accession
        output->pts[pcnt].cont[ccnt].drawn_dt_tm = c.drawn_dt_tm
        output->pts[pcnt].cont[ccnt].ord_prov = ordering_provider
    endif
foot c.container_id
    output->cnt = output->cnt + ccnt
WITH time = 600, separator = " ", format

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Final Output
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if ($RPT_TYPE = 'S')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Final Output - Spreadsheet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELECT distinct INTO $OUTDEV
;select into $outdev
    PT_NAME = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].pt_name)
    , TRANSPLANT_CENTER = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].xplant_cntr)
    , DOB = SUBSTRING(1, 10, OUTPUT->pts[D1.SEQ].dob)
    , SSN = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].ssn)
    , MRN = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].mrn)
    , DRAWN_DT_TM = format(OUTPUT->pts[D1.SEQ].cont[D2.SEQ].drawn_dt_tm, 'MM/DD/YYYY HH:MM;;D')
    , ACCESSION = OUTPUT->pts[D1.SEQ].cont[D2.SEQ].accession
    , ORGAN = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].organ)
    , STATUS = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].status)
    , UNACCEPTABLE_ANTIGENS = SUBSTRING(1, 300, OUTPUT->pts[D1.SEQ].cur_drug_thrpy)
    , ORD_PROV = SUBSTRING(1, 30, OUTPUT->pts[D1.SEQ].cont[D2.SEQ].ord_prov)

FROM
    (DUMMYT   D1  WITH SEQ = VALUE(SIZE(OUTPUT->pts, 5)))
    , (DUMMYT   D2  WITH SEQ = 1)

PLAN D1 WHERE MAXREC(D2, SIZE(OUTPUT->pts[D1.SEQ].cont, 5))
JOIN D2

ORDER BY
    PT_NAME
    , MRN
    , ORGAN
    , DRAWN_DT_TM desc

WITH NOCOUNTER, SEPARATOR=" ", FORMAT

elseif ($RPT_TYPE = 'R')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Assign name to id running report
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
select
    pl.username
from
    prsnl pl
where
    pl.person_id = reqinfo->updt_id
detail
    GVC_PRSNL_NAME = pl.username
with nocounter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Retrieve Patient Status Param. Display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (ANY in ($PT_STATUS))
    set pt_status_disp = 'Any Patient Status'
else
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Retrieve Patient Status Param. Display when not ANY
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    select into 'nl:'
        cv.display
    from
        code_value cv
    where
        cv.code_value in ($PT_STATUS)
    detail
        if (trim(pt_status_disp) > ' ')
            pt_status_disp = concat(pt_status_disp, ', ', cv.display)
        else
            pt_status_disp = cv.display
        endif
    with nocounter
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Retrieve Organ Type Param. Display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (ANY in ($ORGAN_TYPE))
    set organ_type_disp = 'Any Organ Type'
else
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Retrieve Organ Type Param. Display when not ANY
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    select into 'nl:'
        cv.display
    from
        code_value cv
    where
        cv.code_value in ($ORGAN_TYPE)
    detail
        if (trim(pt_status_disp) > ' ')
            organ_type_disp = concat(organ_type_disp, ', ', cv.display)
        else
            organ_type_disp = cv.display
        endif
    with nocounter
endif
;002
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Retrieve Transplan center Param. Display
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (ANY in ($TRANS_LOC))
    set MVC_TRANS_LOC = 'Any Transplant Center'
else
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Retrieve Organ Type Param. Display when not ANY
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    select into 'nl:'
        cv.display
    from
        code_value cv
    where
        cv.code_value in ($TRANS_LOC)
    detail
        if (trim(MVC_TRANS_LOC) > ' ')
            MVC_TRANS_LOC = concat(MVC_TRANS_LOC, ', ', cv.display)
        else
            MVC_TRANS_LOC = cv.display
        endif
    with nocounter
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Final Output to assoc. layout
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SET _SendTo = $OUTDEV
CALL LayoutQuery(0)

endif


end
go
