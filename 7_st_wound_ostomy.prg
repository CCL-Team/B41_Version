/*****************************************************************************
        Source file name:       7_ST_WOUND_OSTOMY.PRG
        Object name:            7_ST_WOUND_OSTOMY
        Cloned from:            7_ST_THERAPY_ORDERS.prg

        MCGA:                   MCGA17955
        OPAS Request Task:      R2:000014298182/R2:000024009610
        Key Requester:          Lunar Song  (NRH)
        Application Analyst:    Brian Twardy

        Program purpose:        **** Smart Template ****
        Notes:                  Pull the following documented information from IView bands > section:
                                    o   Adult Skin-ADL-Nutrition > Skin Abnormalities
                        06/10/2015  o   Adult Skin-ADL-Nutrition > Negative Pressure Wound Therapy
                                    o   Adult Lines Tubes Drains > GI Ostomy
                                    o   Adult Lines Tubes Drains > Surgical Drains/Tubes
                                    o   Adult Lines Tubes Drains > Urinary Ostomy  (006 04/14/2016  Updated to Urostomy/Nephrostomy)
                        12/15/2014  o   Adult Education > Learning Assessmeny  (just... 'Learners Present' and 'Barriers')
                                    o   Adult Education > Nutrition
                                    o   Adult Education > Ostomy
                                    o   Adult Education > Pressure Ulcer
                                    o   Adult Education > Skin & Wounds
                        06/20/2018  o   Adult Systems Assessment > Internal Fecal Management System
                                Only select charted data from clinical_event that was charted by the person using this Smart Template.
                                Only include documentation that was charted for as of the last 24 hours.

        Tables updated:         none

*************************************************************************************************
*                         GENERATED MODIFICATION CONTROL LOG
*************************************************************************************************
Modification History
-------------------------
#000 06/25/2014 Brian Twardy
OPAS Request/Task: R2:00001429818 / R2:000024009610
CCL source: cust_script:7_st_wound_ostomy
FYI... Cloned from: cust_scrip:7_ST_THERAPY_ORDERS.PRG
Initial installation
-------------------------
#001 08/20/2014 Brian Twardy
OPAS Request/Task: n/a
CCL source: cust_script:7_st_wound_ostomy.prg  (it has not changed.)
The result field for some of the charted results was set too small with the substring function. It was
200 characters. I have increased it to 800 characters.
-------------------------
#002 09/15/2014 Brian Twardy
OPAS Request/Task: R2:000014849848/R2:000025168473
CCL source: cust_script:7_st_wound_ostomy.prg  (the name has stayed the same)
The result comments have been requested.  There are lots of iView Bands, and lots of fields associated within
each band.
-------------------------
#003 12/15/2014 Brian Twardy
OPAS Request/Task: R2:000015339399/R2:000026170699    (Key users:  Michelle Pitt-GSH & Lunar Song-NRH)
CCL source: cust_script:7_st_wound_ostomy.prg  (the name has stayed the same)
Two new DTAs/Event Codes have been requested for this template: Learner(s) present for Session --and--
Bariers to Learning.
-------------------------
#004 05/14/2015 Brian Twardy
OPAS Incident: R2:000044765042    (Key users:  Carla Zahradka-FSH & Lunar Song-NRH)
CCL source: cust_script:7_st_wound_ostomy.prg  (the name has stayed the same)
Ms Zahradka noticed one 'skin abnormality' field that was not being picked up by this smart template, but
there were 4 fields that were being missed. They were being missed because these 4 fields were all new or
were updated within the hierarchy of the working view - section - item. For some reason, these fields were
in place as the other 50 fields in P41, so the CCL select that looked for them did not find them. This
has been the case since MCGA19495 (Multiple changes to the Skin Abnormalities IView section) was implemented
on March 24th. This has been corrected. The Select in this program is broader now.
-------------------------
#005 06/10/2015 Brian Twardy
OPAS Request/Task:  R2:000061180819/R2:000082554042    (Key users:  Lunar Song-NRH)
MCGA: 200864
CCL source: cust_script:7_st_wound_ostomy.prg  (the name has stayed the same)
Wound Ostomy smart template enhanced to include a new grouper called Negative Pressure Wound Therapy. This request
was logged after this new grouper was added to productuon and an incident came in. That incident became a
request.
-------------------------
#006 04/13/2016 Brian Twardy
OPAS Incident:  R2:000049112388    (Key users:  Lunar Song from NRH --and-- Dorothy Goodman and Margaret Hiler from GUH)
CCL source: cust_script:7_st_wound_ostomy.prg  (the name has stayed the same)
The Event Set Hierarchy was copied from B41 into P41, and that has messed up the Urinary Ostomy section. It is now
called the Urostomy/Nephrostomy section.  A change was required here.
-------------------------
#007 06/20/2018 Brian Twardy   (really 07/18/2018)
MCGA: 208702
SOM RIM/Request/Task: RITM0999936/REQ0971257/TASK1787887
Key users: Ian Dominguez and the WOCN work group
CCL source: cust_script:7_st_wound_ostomy.prg  (no name change)
Data from the 'Internal Fecal Management System' iView band is now included in this smart template.
-------------------------
#008 11/16/2020 Brian Twardy
MCGA: n/a
SOM incident: INC11096950
Key users: Ian Dominguez, Leslie Donohue of UMH, and the WOCN work group
CCL source: cust_script:7_st_wound_ostomy.prg  (no name change)
A symptom of an iView reshuffling was that 'Skin Abnormalities' was being duplicated
under 'Internal Fecal Management System'.  That was the incident that was reported to the Help Desk.
The cause...
'Internal Fecal Management System' was moved to these sections several days ago.
    - Adult ICU Lines Tubes Drains
    - Adult Lines Tubes Drains
It had been under these sections:
    - Adult ICU Systems Assessment
    - Adult Systems Assessment
    - CIR System Assessment
This script has been revised to recognize that move now.
----------------------------
#008 11/5/2021 Asha Patil
MCGA: n/a
SOM incident: INC13160194,INC13153644,INC13164820,INC13151401,INC13161151
Multiple incidents were reported due to band name change

Band name : adult systems assessment

#009 12/7/2021
MCGA # 230515 Break-fix for Wound Ostomy ST
"Date on dressing" format was wrong

-------------------------

#010 03/13/2024 - Chris Grobbel - Oracle
MCGA
Modify working views from Nursing Documentation Efficiency effort

-------------------------

#011 04/13/2024 - Chris Grobbel - Oracle
MCGA # 347111
Modify the Negative Pressure Wound Therapy to use the 'sn periop systems assessment' working view

-------------------------

#012 07/28/2024 - Michael Mayes - Not Oracle
MCGA # 355154
Urostomy*Nephrostomy* build changed, and they needed a breakfix to pull it in again.


*******************************************************************************************************/

drop program 7_st_wound_ostomy go
create program 7_st_wound_ostomy
; This is to test that MOD 10 is beging executed after servers cycled
select into "cjg_mod_11_ostomy_st.dat"
from (dummyt d with seq=1)
head report
col 0 "we are in mod 11!"
row+1
with nocounter

%i cust_script:0_rtf_template_format.inc

free record rec
record rec
(   1 skin_cnt = i4                             ; Skin Abnormalities
    1 skin[*]
        2 event_disp = vc
        2 result     = vc

    ; 005 06/10/2015  'Negative Pressure Wound Therapy' is new.
    1 neg_cnt = i4                              ; Negative Pressure Wound Therapy
    1 neg[*]
        2 event_disp = vc
        2 result     = vc

    1 gi_cnt = i4                               ; GI Ostomy
    1 gi[*]
        2 event_disp = vc
        2 result     = vc

    1 surg_cnt = i4                             ; Surgical Drains/Tubes
    1 surg[*]
        2 event_disp = vc
        2 result     = vc

    1 uri_cnt = i4                              ; Urinary Ostomy      006 04/14/2016  renamed to Urostomy/Nephrostomy later
    1 uri[*]
        2 dyn_lab_id = f8                       ;012
        2 event_disp = vc
        2 event_id   = f8                       ;012
        2 event_cd   = f8                       ;012
        2 result     = vc

    1 learn_cnt = i4                            ; Learning Assessment           ; 003 12/15/2014 added at this time.
    1 learn_event_end_dt_tm = dq8
    1 learn[*]
        2 event_disp = vc
        2 result     = vc

    1 ned_cnt = i4                              ; Nutrition Education
    1 ned_event_end_dt_tm = dq8
    1 ned[*]
        2 event_disp = vc
        2 result     = vc

    1 oed_cnt = i4                              ; Ostomy Education
    1 oed_event_end_dt_tm = dq8
    1 oed[*]
        2 event_disp = vc
        2 result     = vc

    1 pued_cnt = i4                             ; Pressure Ulcer Education
    1 pued_event_end_dt_tm = dq8
    1 pued[*]
        2 event_disp = vc
        2 result     = vc

    1 swed_cnt = i4                             ; Skin and Wounds Education
    1 swed_event_end_dt_tm = dq8
    1 swed[*]
        2 event_disp = vc
        2 result     = vc

    1 fecal_cnt = i4                            ; Internal Fecal Management System          ; 007 06/20/2018 added at this time
    1 fecal_event_end_dt_tm = dq8
    1 fecal[*]
        2 event_disp = vc
        2 result     = vc
)


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; The below record structure will be used to help with sorting the working view items. We are starting out by using this
; on the skin abnormalities.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
record wv
(   01 qual [*]
        02 working_view_item_id = f8
        02 working_view_section_id = f8
        02 PARENT_EVENT_SET_CD = f8
        02 EVENT_SET_COLLATING_SEQ = i2         ; <<<<< Whoa.  This is the field from v500_event_set_canon that is used to....
        02 event_end_dt_tm = dq8                ;               ...  order iView items in Powerchart
        02 event_cd = f8
        02 event = vc
)


declare details_line = c120
declare status = vc
declare tmp_str = vc

declare cnt = i4
declare idx = i4
declare idx1 = i4

DECLARE AUTH_CD                 = F8 WITH CONSTANT (UAR_GET_CODE_BY ("MEANING" ,8 ,"AUTH" ) )           ; 25.00
DECLARE MOD_CD                  = F8 WITH CONSTANT (UAR_GET_CODE_BY ("MEANING" ,8 ,"MODIFIED" ) )       ; 35.00
DECLARE ALTERED_CD              = F8 WITH CONSTANT (UAR_GET_CODE_BY ("MEANING" ,8 ,"ALTERED" ) )        ; 34.00 ; 002 09/15/2014

declare most_recent_ce_ind = i2 with noconstant(0)

declare event_disp = vc
declare result     = vc

;  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 002  09/15/2014  These variables are used with the result comments. These were added today, in P41.
;  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

declare ocfcomp_cd = f8 with Constant(uar_get_code_by("MEANING",120,"OCFCOMP")),protect
declare nocomp_cd = f8 with Constant(uar_get_code_by("MEANING",120,"NOCOMP")),protect
declare blobout = vc with protect, noconstant(" ")
declare blobnortf = vc with protect, noconstant(" ")
declare lb_seg = vc with protect, noconstant(" ")
declare bsize = i4
declare uncompsize = i4
declare blob_un = f8
;  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

;  Used to store the user's name and person_id... the user being the person using the smart template.

record prsnl_user (
    1 person_id             = f8
    1 name_full_formatted   = vc
    1 name_first_key        = vc
    1 name_last_key         = vc
)

;--------------------------------------------------------------------------------------------------------------------------
;  Select and store the user who is using this Smart Template. Only his/hers charted data will be selected by this template.

select into "nl:"
from prsnl p
where p.person_id = reqinfo->updt_id
detail
    prsnl_user->person_id           = p.person_id
    prsnl_user->name_full_formatted = p.name_full_formatted
    prsnl_user->name_first_key      = p.name_first_key
    prsnl_user->name_last_key       = p.name_last_key

with nocounter


;--------------------------------------------------------------------------------------------------
; *** Skin Abnormalities ***
; Skin Abnormalities are being selected and loaded into the Record Structure.
;--------------------------------------------------------------------------------------------------

; Start off by loading the skin abnormality event_cds into the wv record structure

select distinct  into "nl:"
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_set_canon vcanon,            ; We want this table so that we can order the iView items as Powerchart does.
        v500_event_code v5c


plan  wv
    where cnvtlower(wv.display_name) in('adult systems assessment') and ;008 'adult skin*', 'ed adult skin*', 'sn adult*skin*') and
          wv.active_ind = 1

join wvs
    where wvs.working_view_id = wv.working_view_id and
          wvs.event_set_name = "Integumentary." ;     ; MOD 010 - was "Skin Abno*"  ; Skin Abnormalities

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  vcanon                                    ; We want this table so that we can order the iView items as Powerchart does.
    where vcanon.event_set_cd = exp.event_set_cd        and
          vcanon.parent_event_set_cd  =        114297247.00  ; Skin Abnormalities

JOIN  v5c
    where v5c.event_cd = exp.event_cd

order by  exp.event_cd

head report
    cnt = 0

head exp.event_cd
    cnt = cnt + 1
    stat = alterlist(wv->qual, cnt)
    wv->qual[cnt].working_view_section_id = wvi.working_view_section_id
    wv->qual[cnt].working_view_item_id = wvi.working_view_item_id
    wv->qual[cnt].PARENT_EVENT_SET_CD = vcanon.PARENT_EVENT_SET_CD
    wv->qual[cnt].EVENT_SET_COLLATING_SEQ = vcanon.EVENT_SET_COLLATING_SEQ  ;to order the iView items as Powerchart does.
    wv->qual[cnt].event_cd = v5c.event_cd
    wv->qual[cnt].event = trim(substring(1,200,uar_get_code_display(v5c.event_cd)))

with format, separator = " ", time = 10, maxcol = 1000

select distinct  into "nl:"
        lenblob              = size(lb.long_blob),
        working_view_item_id = wv->qual[d.seq].working_view_item_id,
        EVENT_SET_COLLATING_SEQ = wv->qual[d.seq].EVENT_SET_COLLATING_SEQ

from    clinical_event c,
       (dummyt d with seq = size(wv->qual,5)),
        prsnl p,
        dummyt d_cedl,                              ; 002 09/15/2014  New
        ce_dynamic_label CEDL,
        dummyt d_ce,                                ; 009
        ce_date_result ce,                          ; 009
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan d

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          c.event_cd = wv->qual[d.seq].event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3);      and         ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cedl
;
join cedl
;   where cedl.ce_dynamic_label_id = outerjoin(c.ce_dynamic_label_id)
    where cedl.ce_dynamic_label_id = (c.ce_dynamic_label_id)

join d_ce  ;009
join ce    ;009
    where ce.event_id=(c.event_id) and
           ce.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))


join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)


;order c.event_end_dt_tm desc, c.ce_dynamic_label_id, wvi.working_view_item_id

order by c.ce_dynamic_label_id, c.event_end_dt_tm desc,
         EVENT_SET_COLLATING_SEQ


head report
    cnt = 0
    most_recent_ce_ind = 1          ; Used to indicate that only the most recent clinical_event column in Power Chart (as
                                    ; you know, columns are headed with the event_end_dt_tm) will be selected with this
                                    ; Select command. That is, the most recent one for each of the skin abnornalities.

head c.ce_dynamic_label_id
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    if (most_recent_ce_ind = 1)
        cnt = cnt + 1
        stat = alterlist(rec->skin,cnt)
        rec->skin[cnt].event_disp = trim(cedl.label_name)
        ;rec->skin[cnt].result = build2("(as of: ",format(c.event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")")
        rec->skin[cnt].result = if (ce.event_id != 0.00)
                                                format(ce.result_dt_tm, "MM/DD/YYYY hh:mm;;Q")
                                else
                                                    (if (C.EVENT_CLASS_CD = 223.00) ; 223.00 is a Date result
                                                        ;"test1"
                                                        trim(substring( 1,50, format(ce.result_dt_tm, "MM/DD/YYYY hh:mm;;Q")))
                                                        elseif (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)

                                                        trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                                                    else
                                                        build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
                                                    endif)
                                                endif
    endif


detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->skin,cnt)
          ;; Below, we are erasing the words "Skin Abnormality" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->skin[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "Skin Abnormality ", ""))

        rec->skin[cnt].result = if (ce.event_id != 0.00)
                                                format(ce.result_dt_tm, "MM/DD/YYYY hh:mm;;Q")
                                else
                                                    (if (C.EVENT_CLASS_CD = 223.00) ; 223.00 is a Date result ;009
                                                            trim(substring( 1,50, format(ce.result_dt_tm, "MM/DD/YYYY hh:mm;;Q")))

                                                        elseif (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)

                                                        trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                                                    else
                                                        build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
                                                    endif)
                                                endif

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->skin[cnt].result = trim(substring(1,800,Build2(rec->skin[cnt].result, " (", blobnortf, ")")))
            endif

       endif

    endif

;foot  c.event_cd
;   null
;
;foot vcanon.event_set_collating_seq
;   null
;

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot c.ce_dynamic_label_id
    null

foot report
    rec->skin_cnt = cnt

with format, separator = " ", time = 10, maxcol = 1000, outerjoin = d_cn, outerjoin = d_cedl, outerjoin = d_lb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;005 06/10/2015 Negative Pressure Wound Therapy is new, as of today
;--------------------------------------------------------------------------------------------------
; *** Negative Pressure Wound Therapy ***
; Negative Pressure Wound Therapy is being selected and loaded into the Record Structure.
;--------------------------------------------------------------------------------------------------

; Start off by loading the Negative Pressure Wound Therapy event_cds into the wv record structure

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_set_canon vcanon,            ; MOD 010 - Order the iView items as Powerchart does.
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cedl,                              ; 002 09/15/2014  New
        ce_dynamic_label CEDL,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
         ;MOD 011 cnvtlower(wv.display_name) = 'adult systems assessment' ;'adult skin*' 008 replaced adult skin with adult systems assessment      ;--BAND NAME
       cnvtlower(wv.display_name) = 'sn periop systems assessment' ; MOD 011

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "Integumentary."      ; MOD 010 - was "Neg*Pre*Ther*" ; Negative Pressure Wound Therapy

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd
; Begin MOD 10
JOIN  vcanon                                    ; We want this table so that we can order the iView items as Powerchart does.
    where vcanon.event_set_cd = exp.event_set_cd        and
          vcanon.parent_event_set_cd  =        573554685.00  ; Negative Pressure Wound Therapy
; END MOD 10
JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Skin - ADL - Nutrition" and
    ;;;;; section/sub-band 'Negative Pressure Wound Therapy'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cedl
;
join cedl
;   where cedl.ce_dynamic_label_id = outerjoin(c.ce_dynamic_label_id)
    where cedl.ce_dynamic_label_id = (c.ce_dynamic_label_id)

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))

join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order  c.ce_dynamic_label_id, c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1          ; Used to indicate that only the most recent clinical_event column in Power Chart (as
                                    ; you know, columns are headed with the event_end_dt_tm) will be selected with this
                                    ; Select command. That is, the most recent one for each of the GI Ostomies.

head c.ce_dynamic_label_id
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    if (most_recent_ce_ind = 1)
        cnt = cnt + 1
        stat = alterlist(rec->neg,cnt)
        rec->neg[cnt].event_disp = trim(cedl.label_name)
        rec->neg[cnt].result = build2("(as of: ",format(c.event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")")
    endif

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->neg,cnt)
          ;; Below, we are erasing the words "Negative Pressure Wound Therapy" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        ;rec->neg[cnt].event_disp = build2 ("      ",
        ;                                 replace (trim (substring(1, 800, uar_get_code_display(c.event_cd))),
        ;                                          "Negative Pressure Wound Therapy ", ""))
        rec->neg[cnt].event_disp = build2 ("      ",replace (trim (substring(1, 800, uar_get_code_display(c.event_cd))),
                                                   "NPWT-", ""))  ;;MOD 011

        rec->neg[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->neg[cnt].result = trim(substring(1,800,Build2(rec->neg[cnt].result, " (", blobnortf, ")")))
            endif

        endif

   endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot c.ce_dynamic_label_id
    null

foot report
    rec->neg_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000, outerjoin = d_cn, outerjoin = d_cedl, outerjoin = d_lb



;--------------------------------------------------------------------------------------------------
; *** GI OSTOMY ***
; Adult Lines Tubes Drains > GI Ostomy is being selected and loaded into the Record Structure.
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cedl,                              ; 002 09/15/2014  New
        ce_dynamic_label CEDL,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult lines*'       ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "GI Ost*"                    ; GI Ostomy

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Lines Tubes Drains" and
    ;;;;; section/sub-band 'GI Ostomy'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cedl
;
join cedl
;   where cedl.ce_dynamic_label_id = outerjoin(c.ce_dynamic_label_id)
    where cedl.ce_dynamic_label_id = (c.ce_dynamic_label_id)

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))

join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order  c.ce_dynamic_label_id, c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1          ; Used to indicate that only the most recent clinical_event column in Power Chart (as
                                    ; you know, columns are headed with the event_end_dt_tm) will be selected with this
                                    ; Select command. That is, the most recent one for each of the GI Ostomies.

head c.ce_dynamic_label_id
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    if (most_recent_ce_ind = 1)
        cnt = cnt + 1
        stat = alterlist(rec->gi,cnt)
        rec->gi[cnt].event_disp = trim(cedl.label_name)
        rec->gi[cnt].result = build2("(as of: ",format(c.event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")")
    endif

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->gi,cnt)
          ;; Below, we are erasing the words "GI Ostomy" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->gi[cnt].event_disp = build2 ("      ",
                                          replace (trim (substring(1, 800, uar_get_code_display(c.event_cd))),
                                                   "GI Ostomy ", ""))

        rec->gi[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->gi[cnt].result = trim(substring(1,800,Build2(rec->gi[cnt].result, " (", blobnortf, ")")))
            endif

        endif

   endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot c.ce_dynamic_label_id
    null

foot report
    rec->gi_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000, outerjoin = d_cn, outerjoin = d_cedl, outerjoin = d_lb


;--------------------------------------------------------------------------------------------------
; *** SURGICAL DRAINS/TUBES ***
; 'Adult Lines Tubes Drains' -> 'Surgical Drains/Tubes' is being selected and loaded into the Record Structure
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cedl,                              ; 002 09/15/2014  New
        ce_dynamic_label CEDL,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult lines*'       ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "Surgical Drains*"           ; Surgical Drains/Tubes

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Lines Tubes Drains" and
    ;;;; section/sub-band 'Surgical Drains/Tubes'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cedl
;
join cedl
;   where cedl.ce_dynamic_label_id = outerjoin(c.ce_dynamic_label_id)
    where cedl.ce_dynamic_label_id = (c.ce_dynamic_label_id)

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))


join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order c.ce_dynamic_label_id, c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1          ; Used to indicate that only the most recent clinical_event column in Power Chart (as
                                    ; you know, columns are headed with the event_end_dt_tm) will be selected with this
                                    ; Select command. That is, the most recent one for each of the surgical drains/tubes.

head c.ce_dynamic_label_id
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    if (most_recent_ce_ind = 1)
        cnt = cnt + 1
        stat = alterlist(rec->surg,cnt)
        rec->surg[cnt].event_disp = trim(cedl.label_name)
        rec->surg[cnt].result = build2("(as of: ",format(c.event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")")
    endif

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->surg,cnt)
          ;; Below, we are erasing the words "Surgical Drain, Tube" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->surg[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "Surgical Drain, Tube ", ""))

        rec->surg[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->surg[cnt].result = trim(substring(1,800,Build2(rec->surg[cnt].result, " (", blobnortf, ")")))
            endif

        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot c.ce_dynamic_label_id
    null

foot report
    rec->surg_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000, outerjoin = d_cn, outerjoin = d_cedl, outerjoin = d_lb


;--------------------------------------------------------------------------------------------------
; *** Urostomy/Nephrostomy ***          was *** URINARY OSTOMY *** until 04/14/2016
;
; 'Adult Lines Tubes Drains' -> 'Urinary Ostomy' is being selected and                                          ; 006 04/14/2016  See below
;                                   loaded into the Record Structure                                            ; 006 04/14/2016  See below
; 'Adult Lines Tubes Drains' -> 'Urostomy/Nephrostomy' is being selected and                                    ; 006 04/14/2016  Replacement
;                                   loaded into the Record Structure                                            ; 006 04/14/2016  Replacement
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cedl,                              ; 002 09/15/2014  New
        ce_dynamic_label CEDL,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                             ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult lines*'   ;--BAND NAME

join wvs
;   where wv.working_view_id = wvs.working_view_id and
;;        wvs.event_set_name = "Urinary Ost*"           ; Urinary Ostomy            ; 006 04/14/2016  Replaced. See below.
;         wvs.event_set_name = "Urostomy*Nephrostomy*"  ;Urostomy/Nephrostomy*"     ; 006 04/14/2016  Replacement.
;
    where wv.working_view_id = wvs.working_view_id
      and (   wvs.event_set_name = "Urostomy*Nephrostomy*"  ;Urostomy/Nephrostomy*"     ; 006 04/14/2016  Replacement.
           or wvs.event_set_name = "Ostomy*"  ;Urostomy/Nephrostomy*"       ; 012
          )


JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Lines Tubes Drains" and
    ;;;; section/sub-band 'Urinary Ostomy'.... rather...   "Urostomy*Nephrostomy*" , as of 04/14/2016.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cedl

;
join cedl
;   where cedl.ce_dynamic_label_id = outerjoin(c.ce_dynamic_label_id)
    where cedl.ce_dynamic_label_id = (c.ce_dynamic_label_id)


join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))


join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order  c.ce_dynamic_label_id, c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1          ; Used to indicate that only the most recent clinical_event column in Power Chart (as
                                    ; you know, columns are headed with the event_end_dt_tm) will be selected with this
                                    ; Select command. That is, the most recent one for each of the GI Ostomies.

head c.ce_dynamic_label_id
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    if (most_recent_ce_ind = 1)
        cnt = cnt + 1
        stat = alterlist(rec->uri,cnt)
        rec->uri[cnt].event_disp = trim(cedl.label_name)
        rec->uri[cnt].result = build2("(as of: ",format(c.event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")")
        
        rec->uri[cnt].event_id   = c.event_id              ;012
        rec->uri[cnt].event_cd   = c.event_cd              ;012
        rec->uri[cnt].dyn_lab_id = c.ce_dynamic_label_id   ;012
    endif

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->uri,cnt)

          ;;  006 04/13/2016  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          ;;  This was the old 'replace'... old until this day
          ;; Below, we are erasing the words "Urinary Ostomy" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
;;      rec->uri[cnt].event_disp = build2 ("      ",
;;                                         replace (trim (substring(1, 800, uar_get_code_display(c.event_cd))),
;;                                                  "Urinary Ostomy ", ""))
          ;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

          ;;  006 04/13/2016  This is the new 'replace'... new today
          ;; Below, we are erasing the words "Urostomy", "Nephrostomy", and "Urostomy/Nephrostomy"
          ;; from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.

        rec->uri[cnt].event_disp = build2 ("      ",
                                           replace (
                                                   replace (
                                                            replace (trim (substring(1, 800, uar_get_code_display(c.event_cd))),
                                                                     "Urostomy/Nephrostomy ", ""),
                                                            "Urostomy ",""),
                                                    "Nephrostomy ",""))

        rec->uri[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        rec->uri[cnt].event_id   = c.event_id             ;012
        rec->uri[cnt].event_cd   = c.event_cd             ;012
        rec->uri[cnt].dyn_lab_id = c.ce_dynamic_label_id  ;012

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->uri[cnt].result = trim(substring(1,800,Build2(rec->uri[cnt].result, " (", blobnortf, ")")))
            endif

        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot c.ce_dynamic_label_id
    null

foot report
    rec->uri_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000,  outerjoin = d_cn, outerjoin = d_cedl, outerjoin = d_lb


;--------------------------------------------------------------------------------------------------
; *** Learning Assessment***
; 003 12/15/2014   Added today.
; 'Adult Education' ->  'Learning Assessment' is being selected and loaded into the Record Structure
; There are no dynamic groupers for the Education sections, like this one.
;
; Two Learning Assessment DTAs/event codes are being selected and loaded into the Record Structure.
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult educ*'        ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
;         wvs.event_set_name = "Learning*Assess*"       ; display name=Learning Assessment    event_set_name="Restraint Learning Assessment"
          wvs.display_name = "Learning*Assess*"         ; display name=Learning Assessment    event_set_name="Restraint Learning Assessment"

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Education" and
    ;;;; section/sub-band 'Learning Assessment'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cn

join cn
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))


join d_lb

join lb
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    null


detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->learn,cnt)
          ;; Below, we are erasing the words "EDUC" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->learn[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "EDUC ", ""))

        rec->learn[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        rec->learn_event_end_dt_tm = c.event_end_dt_tm              ; 07/29/2014  This was left out of the earlier CCL.

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->learn[cnt].result = trim(substring(1,800,Build2(rec->learn[cnt].result, " (", blobnortf, ")")))
            endif

        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot report
    rec->learn_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000,  outerjoin = d_cn, outerjoin = d_lb

;--------------------------------------------------------------------------------------------------
; *** NUTRITION EDUCATION ***
; 'Adult Education' ->  'Nutrition Education' is being selected and loaded into the Record Structure
;  There are no dynamic groupers for the Education sections, like this one.
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult educ*'        ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "Nutrition Educ*"            ; Nutrition Education

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Education" and
    ;;;; section/sub-band 'Nutrition Education'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))


join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    null


detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->ned,cnt)
          ;; Below, we are erasing the words "EDUC" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->ned[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "EDUC ", ""))

        rec->ned[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        rec->ned_event_end_dt_tm = c.event_end_dt_tm                ; 07/29/2014  This was left out of the earlier CCL.

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->ned[cnt].result = trim(substring(1,800,Build2(rec->ned[cnt].result, " (", blobnortf, ")")))
            endif

        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot report
    rec->ned_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000,  outerjoin = d_cn, outerjoin = d_lb

;--------------------------------------------------------------------------------------------------
; *** OSTOMY EDUCATION ***
; 'Adult Education' ->  'Ostomy Education' is being selected and loaded into the Record Structure
;  There are no dynamic groupers for the Education sections, like this one.
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult educ*'        ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "Ostom*"                 ; Ostomy Education

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Education" and
    ;;;; section/sub-band 'Ostomy Education'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.
join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))

join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)

order c.event_end_dt_tm desc, wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    null

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->oed,cnt)
          ;; Below, we are erasing the words "EDUC" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->oed[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "EDUC ", ""))

        rec->oed[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        rec->oed_event_end_dt_tm = c.event_end_dt_tm

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->oed[cnt].result = trim(substring(1,800,Build2(rec->oed[cnt].result, " (", blobnortf, ")")))
            endif
        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot report
    rec->oed_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000,  outerjoin = d_cn, outerjoin = d_lb


;--------------------------------------------------------------------------------------------------
; *** PRESSURE ULCER EDUCATION ***
; 'Adult Education' ->  'Pressure Ulcer Education' is being selected and loaded into the Record Structure
;  There are no dynamic groupers for the Education sections, like this one.
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult educ*'        ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "Pres*Ul*"                   ; Pressure Ulcer Education

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Education" and
    ;;;; section/sub-band 'Pressure Ulcer Education'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.
join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))


join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)


order c.event_end_dt_tm desc,  wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    null

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->pued,cnt)
          ;; Below, we are erasing the words "EDUC" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->pued[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "EDUC ", ""))

        rec->pued[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        rec->pued_event_end_dt_tm = c.event_end_dt_tm

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->pued[cnt].result = trim(substring(1,800,Build2(rec->pued[cnt].result, " (", blobnortf, ")")))
            endif

        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot report
    rec->pued_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000,  outerjoin = d_cn, outerjoin = d_lb

;--------------------------------------------------------------------------------------------------
; *** SKIN AND WOUNDS EDUCATION ***
; 'Adult Education' ->  'Skin and Wounds Education' is being selected and loaded into the Record Structure
;  There are no dynamic groupers for the Education sections, like this one.
;--------------------------------------------------------------------------------------------------

select  into "nl:"
        lenblob                         = size(lb.long_blob)                    ; 002 09/15/2014  New.
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_code v5c,
        clinical_event c,
        prsnl p,
        dummyt d_cn,                                ; 002 09/15/2014  New
        ce_event_note   CN,                         ; 002 09/15/2014  New
        dummyt d_lb,                                ; 002 09/15/2014  New
        long_blob   LB                              ; 002 09/15/2014  New

plan  wv
    where wv.active_ind = 1 and
          cnvtlower(wv.display_name) = 'adult educ*'        ;--BAND NAME

join wvs
    where wv.working_view_id = wvs.working_view_id and
          wvs.event_set_name = "Skin*Wou*"                  ; Skin and Wounds Education

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

    ;;;; Everything above is selecting the event codes associated with working view/band "Adult Education" and
    ;;;; section/sub-band 'Skin and Wounds Education'.

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.
join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          v5c.event_cd = c.event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)                   ; 07/29/2014   New

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cn

join cn                                                     ; 002 09/15/2014   New.
    where cn.event_id = (c.event_id) and
          cn.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))

join d_lb

join lb                                                     ; 002 09/15/2014   New.
    where lb.parent_entity_id = (cn.ce_event_note_id) and
          lb.active_ind = (1)


order c.event_end_dt_tm desc,  wvi.working_view_item_id

head report
    cnt = 0
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    null

detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->swed,cnt)
          ;; Below, we are erasing the words "EDUC" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->swed[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "EDUC ", ""))

        rec->swed[cnt].result =
            (if (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
;               trim (substring( 1, 200, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
                trim (substring( 1, 800, c.result_val))     ; #001 08/20/2014 200 out.. 800 in.
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

        rec->swed_event_end_dt_tm = c.event_end_dt_tm

        if(cn.compression_cd = ocfcomp_cd)
            com_cnt = 0
            blobout = " "
            blobnortf = " "
            lb_seg = " "
            bsize = 0
            blobout = notrim(fillstring(32767," "))
            blobnortf = notrim(fillstring(32767," "))
            uncompsize = 0
     ;  002 09/15/2014   lenblob has been added to the select list. Look at the line below...
            blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, lenblob, BLOBOUT, SIZE(BLOBOUT), uncompsize)
            stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
            blobnortf = substring(1,bsize,blobnortf)

            if(textlen(blobnortf) > 0)
                rec->swed[cnt].result = trim(substring(1,800,Build2(rec->swed[cnt].result, " (", blobnortf, ")")))
            endif

        endif

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot report
    rec->swed_cnt = cnt

with format, separator = " ", time = 20, maxcol = 1000,  outerjoin = d_cn, outerjoin = d_lb


;--------------------------------------------------------------------------------------------------
; 007 06/20/2018   Added today
; *** Internal Fecal Management System ***
; Internal Fecal Management System data is now being selected and loaded into the Record Structure.
;--------------------------------------------------------------------------------------------------

; Start off by loading the Internal Fecal Management System event_cds into the wv record structure

select distinct  into "nl:"
from    working_view wv,
        working_view_section wvs,
        working_view_item wvi,
        v500_event_set_code v5esc,
        v500_event_set_explode exp,
        v500_event_set_canon vcanon,            ; We want this table so that we can order the iView items as Powerchart does.
        v500_event_code v5c


plan  wv

; 008 11/16/2020 'Internal Fecal Management System' was moved several days ago. This caused an issue.
;                It has been fixed, as shown in the next few lines.
;   where wv.display_name in                                                                            ; 008 11/16/2020 Out
;;           ('Adult ICU Systems Assessment', 'Adult Systems Assessment', 'CIR System Assessment') and  ; 008 11/16/2020 Out
    where wv.display_name in                                                                            ; 008 11/16/2020 New
            ('Adult ICU Lines Tubes Drains', 'Adult Lines Tubes Drains') and                            ; 008 11/16/2020 New
          wv.active_ind = 1

join wvs
    where wvs.working_view_id = wv.working_view_id and
          wvs.event_set_name = "Internal Fecal*"    ;                       ; Internal Fecal Management System

JOIN  wvi
    where wvi.working_view_section_id = wvs.working_view_section_id

JOIN  v5esc
    where v5esc.event_set_name = wvi.primitive_event_set_name

JOIN  exp
    where exp.event_set_cd = v5esc.event_set_cd

JOIN  vcanon                                    ; We want this table so that we can order the iView items as Powerchart does.
    where vcanon.event_set_cd = exp.event_set_cd

JOIN  v5c
    where v5c.event_cd = exp.event_cd

order by  exp.event_cd

head report
    cnt = 0

head exp.event_cd
    cnt = cnt + 1
    stat = alterlist(wv->qual, cnt)
    wv->qual[cnt].working_view_section_id = wvi.working_view_section_id
    wv->qual[cnt].working_view_item_id = wvi.working_view_item_id
    wv->qual[cnt].PARENT_EVENT_SET_CD = vcanon.PARENT_EVENT_SET_CD
    wv->qual[cnt].EVENT_SET_COLLATING_SEQ = vcanon.EVENT_SET_COLLATING_SEQ  ;to order the iView items as Powerchart does.
    wv->qual[cnt].event_cd = v5c.event_cd
    wv->qual[cnt].event = trim(substring(1,200,uar_get_code_display(v5c.event_cd)))

with format, separator = " ", time = 10, maxcol = 1000


; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
select distinct  into "nl:"
        working_view_item_id = wv->qual[d.seq].working_view_item_id,
        EVENT_SET_COLLATING_SEQ = wv->qual[d.seq].EVENT_SET_COLLATING_SEQ

from    clinical_event c,
       (dummyt d with seq = size(wv->qual,5)),
        prsnl p,
        dummyt d_cedl,
        ce_dynamic_label CEDL,
        dummyt d_cedr,
        ce_date_result   CEDR

plan d

    ;;;; Below, we are going to use the above event codes and search for them in clinical_event for the requested patient/encounter.

join c
    where c.person_id =  p_id and           ; Look in cust_script:0_rtf_template_format.inc for "p_id"
          c.event_cd = wv->qual[d.seq].event_cd and
          c.encntr_id + 1 - 1 = e_id and    ; Look in cust_script:0_rtf_template_format.inc for "e_id"
          c.result_status_cd in (MOD_CD, AUTH_CD, ALTERED_CD) and
          c.event_end_dt_tm between cnvtlookbehind("1,D") and cnvtdatetime (curdate, curtime3) and
          c.valid_until_dt_tm + 1 - 1 >= cnvtdatetime (curdate, curtime3)

join p
    where p.person_id = c.performed_prsnl_id  and
          p.name_first_key = prsnl_user->name_first_key and
          p.name_last_key = prsnl_user->name_last_key

join d_cedl

join cedl
    where cedl.ce_dynamic_label_id = (c.ce_dynamic_label_id)

join d_cedr

join cedr
    where cedr.event_id = (c.event_id) and
          cedr.valid_until_dt_tm + 1 - 1 >= (cnvtdatetime (curdate, curtime3))

order by c.ce_dynamic_label_id, c.event_end_dt_tm desc,
         EVENT_SET_COLLATING_SEQ


head report
    cnt = 0
    most_recent_ce_ind = 1          ; Used to indicate that only the most recent clinical_event column in Power Chart (as
                                    ; you know, columns are headed with the event_end_dt_tm) will be selected with this
                                    ; Select command. That is, the most recent one for each of the skin abnornalities.

head c.ce_dynamic_label_id
    most_recent_ce_ind = 1

head c.event_end_dt_tm
    if (most_recent_ce_ind = 1)
        cnt = cnt + 1
        stat = alterlist(rec->fecal,cnt)
        rec->fecal[cnt].event_disp = trim(cedl.label_name)
        rec->fecal[cnt].result = build2("(as of: ",format(c.event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")")
    endif


detail
    if (most_recent_ce_ind = 1)
        cnt= cnt + 1
        stat = alterlist(rec->fecal,cnt)
          ;; Below, we are erasing the words "FMS" from the front of each display value of the event codes.
          ;; We are also indenting each line with a few blanks/spaces.
        rec->fecal[cnt].event_disp = build2 ("      ",
                                            replace (trim(substring(1, 800, uar_get_code_display(c.event_cd))),
                                                     "FMS ", ""))
        rec->fecal[cnt].result =
            (if (C.EVENT_CLASS_CD = 223.00) ; 223.00 is a Date result
                trim(substring( 1,50, format(cedr.result_dt_tm, "MM/DD/YYYY hh:mm;;Q")))
             elseif (C.RESULT_UNITS_CD = 0.00 or C.RESULT_UNITS_CD = NULL)
                trim (substring( 1, 800, c.result_val))
             else
                build2(trim (substring( 1, 800, c.result_val)), " ", UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD))
             endif)

    endif

foot c.event_end_dt_tm
    most_recent_ce_ind = 0

foot c.ce_dynamic_label_id
    null

foot report
    rec->fecal_cnt = cnt

with format, separator = " ", time = 10, maxcol = 1000, outerjoin = d_cedl, outerjoin = d_cedr


;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------
;
;  For each of the working views/iViews, the contents of their individual record structures
;  will be copied into the string field, tmp_str.  At the end, that field will be copied to
;  the REPLY record structure and outputted.
;
;------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------


;------------------------------------------------------------------------------------------
; Copying Skin Abnormalities into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->skin_cnt > 0)      ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    set tmp_str = notrim(build2(RHEAD, WBBU, "Skin Abnormalities", WRR, REOL))
    if(rec->skin_cnt > 0)
        for(cnt = 1 to rec->skin_cnt)
            set event_disp  = rec->skin[cnt].event_disp
            set result      = rec->skin[cnt].result
    ;       set status = rec->pat_act[cnt]->status
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Skin Abnormalities were documented. ", REOL)
    endif

else                                    ;07/29/2014  New

    set tmp_str = notrim(build2(RHEAD)) ;07/29/2014  New

endif                                   ;07/29/2014  New

;------------------------------------------------------------------------------------------
; 005 06/10/2015  'Negative Pressure Wound Therapy' has been added today
;------------------------------------------------------------------------------------------
; Copying Negative Pressure Wound Therapy into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->neg_cnt > 0)       ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    set tmp_str = notrim(build2(tmp_str, WBBU, "Negative Pressure Wound Therapy", WRR, REOL))
    if(rec->neg_cnt > 0)
        for(cnt = 1 to rec->neg_cnt)
            set event_disp  = rec->neg[cnt].event_disp
            set result      = rec->neg[cnt].result
    ;       set status = rec->pat_act[cnt]->status
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Negative Pressure Wound Therapy was documented. ", REOL)
    endif

endif

;------------------------------------------------------------------------------------------
; Copying GI Ostomy into tmp_str. Later... this will be outputted using the REPLY record structure


if (rec->gi_cnt > 0)        ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    set tmp_str = notrim(build2(tmp_str, WBBU, "GI Ostomy", WRR, REOL))
    if(rec->gi_cnt > 0)
        for(cnt = 1 to rec->gi_cnt)
            set event_disp  = rec->gi[cnt].event_disp
            set result      = rec->gi[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No GI Ostomies were documented. ", REOL)
    endif

endif

;------------------------------------------------------------------------------------------
; Copying Surgical Drains/Tubes into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->surg_cnt > 0)      ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    set tmp_str = notrim(build2(tmp_str, WBBU, "Surgical Drains/Tubes", WRR, REOL))
    if(rec->surg_cnt > 0)
        for(cnt = 1 to rec->surg_cnt)
            set event_disp  = rec->surg[cnt].event_disp
            set result      = rec->surg[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Surgical Drains/Tubes were documented. ", REOL)
    endif

endif

;------------------------------------------------------------------------------------------
; Copying Urinary Ostomy into tmp_str.       Later... this will be outputted using the                      ; 006 04/14/2016  replaced
;                                                     REPLY record structure                                ; 006 04/14/2016  replaced
; Copying Urostomy/Nephrostomy into tmp_str. Later... this will be outputted using the                      ; 006 04/14/2016  replacement
;                                                     REPLY record structure                                ; 006 04/14/2016  replacement

if (rec->uri_cnt > 0)       ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

;   set tmp_str = notrim(build2(tmp_str, WBBU, "Urinary Ostomy", WRR, REOL))                                ; 006 04/14/2016  replaced
    s;et tmp_str = notrim(build2(tmp_str, WBBU, "Urostomy/Nephrostomy", WRR, REOL))                         ; 006 04/14/2016  replacement
    set tmp_str = notrim(build2(tmp_str, WBBU, "Ostomy", WRR, REOL))                            ; 012

    if(rec->uri_cnt > 0)
        for(cnt = 1 to rec->uri_cnt)
            set event_disp  = rec->uri[cnt].event_disp
            set result      = rec->uri[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
;       set tmp_str = build2(tmp_str, "      No Urinary Ostomies were documented. ", REOL)                  ; 006 04/14/2016  replaced
        ;set tmp_str = build2(tmp_str, "      No Urostomies/Nephrostomies were documented. ", REOL)         ; 006 04/14/2016  replacement
        set tmp_str = build2(tmp_str, "      No Ostomy were documented. ", REOL)            ; 012 

    endif

endif

;------------------------------------------------------------------------------------------
; Copying Learning Assessment into tmp_str. Later... this will be outputted using the REPLY record structure

;if (rec->learn_cnt > 0)        ; Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    if (rec->learn_event_end_dt_tm = NULL)      ; Look first to see if there is a last document date/time to display.
        set tmp_str = notrim(build2(tmp_str, WBBU, "Learning Assessment", WRR, REOL))
    else
        set tmp_str = notrim(build2(tmp_str, WBBU, "Learning Assessment", WRR,
                                    "   (as of: ", format(rec->learn_event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")",  REOL))
    endif

    if(rec->learn_cnt > 0)
        for(cnt = 1 to rec->learn_cnt)
            set event_disp  = rec->learn[cnt].event_disp
            set result      = rec->learn[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Learning Assessment was documented. ", REOL)
    endif

;endif

;------------------------------------------------------------------------------------------
; Copying Nutrition Education into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->ned_cnt > 0)       ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    if (rec->ned_event_end_dt_tm = NULL)        ; Look first to see if there is a last document date/time to display.
        set tmp_str = notrim(build2(tmp_str, WBBU, "Nutrition Education", WRR, REOL))
    else
        set tmp_str = notrim(build2(tmp_str, WBBU, "Nutrition Education", WRR,
                                    "   (as of: ", format(rec->ned_event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")",  REOL))
    endif

    if(rec->ned_cnt > 0)
        for(cnt = 1 to rec->ned_cnt)
            set event_disp  = rec->ned[cnt].event_disp
            set result      = rec->ned[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Nutrition Education was documented. ", REOL)
    endif

endif

;------------------------------------------------------------------------------------------
; Copying Ostomy Education into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->oed_cnt > 0)       ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    if (rec->oed_event_end_dt_tm = NULL)        ; Look first to see if there is a last document date/time to display.
        set tmp_str = notrim(build2(tmp_str, WBBU, "Ostomy Education", WRR, REOL))
    else
        set tmp_str = notrim(build2(tmp_str, WBBU, "Ostomy Education", WRR,
                                    "   (as of: ", format(rec->oed_event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")",  REOL))
    endif

    if(rec->oed_cnt > 0)
        for(cnt = 1 to rec->oed_cnt)
            set event_disp  = rec->oed[cnt].event_disp
            set result      = rec->oed[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Ostomy Education was documented. ", REOL)
    endif

endif

;------------------------------------------------------------------------------------------
; Copying Pressure Ulcer Education into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->pued_cnt > 0)      ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    if (rec->pued_event_end_dt_tm = NULL)       ; Look first to see if there is a last document date/time to display.
        set tmp_str = notrim(build2(tmp_str, WBBU, "Pressure Ulcer Education", WRR, REOL))
    else
        set tmp_str = notrim(build2(tmp_str, WBBU, "Pressure Ulcer Education", WRR,
                                    "   (as of: ", format(rec->pued_event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")",  REOL))
    endif

    if(rec->pued_cnt > 0)
        for(cnt = 1 to rec->pued_cnt)
            set event_disp  = rec->pued[cnt].event_disp
            set result      = rec->pued[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Pressure Ulcer Education was documented. ", REOL)
    endif

endif

;------------------------------------------------------------------------------------------
; Copying Skin and Wounds Education into tmp_str. Later... this will be outputted using the REPLY record structure


if (rec->swed_cnt > 0)      ; 07/29/2014  Still in TST41, Lunar Song wanted to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    if (rec->swed_event_end_dt_tm = NULL)       ; Look first to see if there is a last document date/time to display.
        set tmp_str = notrim(build2(tmp_str, WBBU, "Skin and Wounds Education", WRR, REOL))
    else
        set tmp_str = notrim(build2(tmp_str, WBBU, "Skin and Wounds Education", WRR,
                                    "   (as of: ", format(rec->swed_event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")",  REOL))
    endif

    if(rec->swed_cnt > 0)
        for(cnt = 1 to rec->swed_cnt)
            set event_disp  = rec->swed[cnt].event_disp
            set result      = rec->swed[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "      No Skin and Wounds Education was documented. ", REOL)
    endif

endif


;------------------------------------------------------------------------------------------
; 007 06/20/2018   New
; Copying Internal Fecal Management System into tmp_str. Later... this will be outputted using the REPLY record structure

if (rec->fecal_cnt > 0)     ; We want to suppress sections when nothing was documented so,
                            ;             this "if" was added.  There are 8 sections like this one.

    if (rec->fecal_event_end_dt_tm = NULL)                  ; Look first to see if there is a last document date/time to display.
        set tmp_str = notrim(build2(tmp_str, WBBU, "Internal Fecal Management System", WRR, REOL))
    else
        set tmp_str = notrim(build2(tmp_str, WBBU, "Internal Fecal Management System", WRR,
                       "   (as of: ", format(rec->fecal_event_end_dt_tm,"MM/DD/YYYY hh:mm;;Q"), ")",  REOL))
    endif

    if(rec->fecal_cnt > 0)
        for(cnt = 1 to rec->fecal_cnt)
            set event_disp  = rec->fecal[cnt].event_disp
            set result      = rec->fecal[cnt].result
            set tmp_str = notrim(build2(tmp_str, WBB, event_disp, WRR, "   ", result, REOL))
        endfor
    else
        set tmp_str = build2(tmp_str, "       No Internal Fecal Management System data was documented. ", REOL)
    endif

endif



;----------------------------------------------------------------------------------------------
;  Add end-of-file and place everything into REPLY -> TEXT, then end the program.
;----------------------------------------------------------------------------------------------

call include_line(build2(tmp_str, RTFEOF))  ; include_line is in cust_script:0_rtf_template_format.inc

FOR (CNT = 1 TO DREC->LINE_COUNT)           ; DREC is in cust_script:0_rtf_template_format.inc

    SET  REPLY -> TEXT  =  concat ( REPLY -> TEXT, DREC -> LINE_QUAL [ CNT ]-> DISP_LINE )

ENDFOR

set drec->status_data->status = "S"

call echorecord(drec)
call echo(REPLY -> TEXT )
call echorecord(rec)  ;012
free record rec




end
go
