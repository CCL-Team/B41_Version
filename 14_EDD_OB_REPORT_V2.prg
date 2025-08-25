/*******************************************************************************************************************************
 Program Title:     EDD OB report
 Object name:       14_edd_ob_report
 Purpose:           Ambulatory EDD OB report
 Special Notes:     no header existed for the program. It was added on 05-31-2017 during a change to the CCL.


********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
********************************************************************************************************************************
 Mod  Date        Analyst               OPAS             Comment
 ---  ----------  --------------------  ------           ----------------------------------------------------------------------
 001  05-31-2017  David Anastasio       R2:000056032242  fix estimated gestation age issues
 002  09-2024     WXL168                MCGA:349518      email to client add column for mrn,empi
 003  08-20-2025  Michael Mayes         352664           They want to add a FIN and MRN to this, actually we had MRN, but it wasn't
                                                         tied to the location a visit came from.  They didn't really give guidance
                                                         on which visit, but we are doing a last encntr at org thing below, so
                                                         I think I'm just going to use that.
*********************************END OF ALL MODCONTROL BLOCKS******************************************************************/
drop program 14_edd_ob_report_v2 go
create program 14_edd_ob_report_v2
prompt
    "Output to File/Printer/MINE" = "MINE"                      ;* Enter or select the printer or file name to send this report to
    , "Select Ambulatory Facilities:" = VALUE(-9999999999.0 )
    , "Select Ambulatory Location(s):" = 0
    , "Pregnancy Status:" = 0
    , "EDD Range Start Date:" = "SYSDATE"
    , "EDD Range End Date:" = "SYSDATE"

with OUTDEV, FAC_LIST, LOC_LIST, STATUS, STARTDATE, ENDDATE

/*
;14_edd_ob_report_v2 "OPS",VALUE(-9999999999.0),VALUE(6271131.00,6220688.00,6628941.00,6220724.00,16337887.00)
,value(0) go


*/

declare debug_ind = i2 with protect, noconstant(0)


declare phhome = f8 with constant(uar_get_code_by("DISPLAYKEY", 43, "HOME"))
declare phbusiness = f8 with constant(uar_get_code_by("DISPLAYKEY", 43, "BUSINESS"))
declare phalternate = f8 with constant(uar_get_code_by("DISPLAYKEY", 43, "ALTERNATE"))
declare phmobile = f8 with constant(uar_get_code_by("DISPLAYKEY", 43, "MOBILE"))
declare var_primaryteam = f8 with constant(uar_get_code_by("DISPLAYKEY", 333, "PRIMARYTEAM"))
declare var_attending = f8 with constant(uar_get_code_by("DISPLAYKEY", 333, "ATTENDINGPHYSICIAN"))
declare var_admitting = f8 with constant(uar_get_code_by("DISPLAYKEY", 333, "ADMITTINGPHYSICIAN"))
declare var_lmp = f8 with constant(uar_get_code_by("DISPLAYKEY", 4002113, "LASTMENSTRUALPERIOD"))
declare var_us = f8 with constant(uar_get_code_by("DISPLAYKEY", 4002113, "ULTRASOUND"))
declare pb_active = f8 with constant(uar_get_code_by("DISPLAYKEY", 12030, "ACTIVE"))
declare pb_resolved = f8 with constant(uar_get_code_by("DISPLAYKEY", 12030, "RESOLVED"))
declare mvc_err_msg = vc with protect, noconstant("")
declare fac_msg = vc with noconstant("")
declare ndx = i4 with noconstant(0)
declare nx = i4 with noconstant(0)
declare pos = i4 with noconstant(0)
declare p_weeks = vc with noconstant("")
declare p_days = vc with noconstant("")
declare homex = vc with noconstant("")
declare businessx = vc with noconstant("")
declare alternatex = vc with noconstant("")
declare mobilex = vc with noconstant("")
declare attendx = vc with noconstant("")
declare admitx = vc with noconstant("")
declare primaryteamx = vc with noconstant("")
declare lmp_dt = dq8
declare us_dt = dq8
declare earliestpregnancydt = dq8
set earliestpregnancydt = null
declare home_addr = f8 with constant(uar_get_code_by("DISPLAYKEY", 212, "HOME"))






; 001 - restrict address to home address
free record facilitylist
record facilitylist(
    1 qual_cnt = i4
    1 qual[*]
        2 location_cd = f8
)

free record locationlist
record locationlist(
    1 qual_cnt = i4
    1 name = vc
    1 qual[*]
        2 location_cd = f8
;2 organization_id = f8
)

free record ob
record ob(
    1 earliestpregnancydt = dq8
    1 pt[*]
        2 person_id = f8
        2 mrn       = VC ;002
        2 fin     = vc  ;003
        2 new_mrn = vc  ;003
        2 EMPI    = VC ;002
        2 last_name = vc
        2 first_name = vc
        2 dob = dq8
        2 address_1 = vc
        2 address_2 = vc
        2 city = vc
        2 state = vc
        2 zip = vc
        2 primary_phone = vc
        2 primary_insurance = vc
        2 policy_nbr = f8
        2 encntr_id = f8
        2 del_encntr_id = f8   ;003
        2 pregnancy_estimate_id = f8
        2 pregnancy_id = f8
        2 status_flag = i2; flag (none=0, initial=1, auth=2, final=4)
        2 preg_onset_dt_tm = dq8
        2 method_cd = f8
        2 method_disp = c40
        2 method_desc = vc
        2 method_mean = c12
        2 method_dt_tm = dq8
        2 descriptor_cd = f8
        2 descriptor_disp = c40
        2 descriptor_desc = vc
        2 descriptor_mean = c12
        2 descriptor_txt = vc
        2 descriptor_flag = i2
        2 edd_comment = vc
        2 author_id = f8
        2 crown_rump_length = f8
        2 biparietal_diameter = f8
        2 head_circumference = f8
        2 est_gest_age = i4
        2 ega_format = vc
        2 est_delivery_date = dq8
        2 confirmation_cd = f8
        2 confirmation_disp = c40
        2 confirmation_desc = vc
        2 confirmation_mean = c12
        2 life_cycle_status_cd = f8
        2 life_cycle_status = vc
        2 prev_edd_id = f8
        2 active_ind = i2
        2 entered_dt_tm = dq8
        2 updt_id = f8
        2 updt_dt_tm = dq8
        2 gest_age_at_delivery = f8
        2 delivery_date = dq8
        2 delivered_ind = i4
        2 current_gest_age = i4
        2 edd_ega = i4
        2 est_delivery_dt_tm = dq8
        2 prior_menses_dt_tm = dq8
        2 preg_end_dt_tm = dq8;ONLY IF RESOLVED!!
        2 details[*]
            3 lmp_symptoms_txt = vc
            3 pregnancy_test_dt_tm = dq8
            3 contraception_ind = i2
            3 contraception_duration = i4
            3 breastfeeding_ind = i2
            3 menarche_age = i4
            3 menstrual_freq = i4
            3 prior_menses_dt_tm = dq8
        2 prev_edds[*]
            3 pregnancy_estimate_id = f8
            3 pregnancy_id = f8
            3 status_flag = i2
            3 method_cd = f8
            3 method_disp = c40
            3 method_desc = vc
            3 method_mean = c12
            3 method_dt_tm = dq8
            3 descriptor_cd = f8
            3 descriptor_disp = c40
            3 descriptor_desc = vc
            3 descriptor_mean = c12
            3 descriptor_txt = vc
            3 descriptor_flag = i2
            3 edd_comment = vc
            3 crown_rump_length = f8
            3 biparietal_diameter = f8
            3 head_circumference = f8
            3 est_gest_age = i4
            3 est_delivery_date = dq8
            3 confirmation_cd = f8
            3 confirmation_disp = c40
            3 confirmation_desc = vc
            3 confirmation_mean = c12
            3 active_ind = i2
            3 author_id = f8
            3 entered_dt_tm = dq8
            3 details[*]
                4 lmp_symptoms_txt = vc
                4 pregnancy_test_dt_tm = dq8
                4 contraception_ind = i2
                4 contraception_duration = i4
                4 breastfeeding_ind = i2
                4 menarche_age = i4
                4 menstrual_freq = i4
                4 prior_menses_dt_tm = dq8
            3 method_tz = i4
            3 est_delivery_tz = i4
        2 creator_id = f8; to hold original creator of a modified edd
        2 original_entered_dttm = dq8; to hold original entered dttm of a modified edd
        2 org_id = f8
        2 method_tz = i4
        2 est_delivery_tz = i4
        2 most_recent_encntr_id = f8
        2 most_recent_reg_dt_tm = dq8
        2 most_recent_facility = vc
        2 attendx = vc
        2 admitx = vc
        2 primaryteamx = vc
        2 ambx[*]
            3 encntr_id = f8
            3 reg_dt_tm = dq8
            3 disch_dt_tm = dq8
            3 los = f8
            3 encounter_type = vc
            3 facility = vc
)

free record active_preg_list
record active_preg_list(
    1 pregnancy_list[*]
        2 pregnancy_id = f8
        2 org_id = f8
)

declare failure_ind = i2 with protect, noconstant(false)
declare zero_ind = i2 with protect, noconstant(false)
declare error_msg = vc with protect, noconstant("")
declare error_code = i2 with protect, noconstant(false)
declare select_mode = i4 with protect, noconstant(0)
; { 0= Person, 1= Pregnancy, 2= EDD List }
declare chunksize = i2 with protect, constant(20)
declare stat = i2 with protect, noconstant(0)
declare idx = i4 with protect, noconstant(0)
declare eddlistidx = i4 with protect, noconstant(0)
declare multiple_orgs = i2 with protect, noconstant(0)

;;;;;;;;;002 start
declare output_file = vc with noconstant(" "), protect
declare email_subject = vc
declare email_body = vc
declare send_to = vc with noconstant(" "), protect
 declare bdate = dq8
 declare edate = dq8
declare dateRange = vc

if ($OUTDEV = "OPS")


set output_file =
build2(trim(logical("ccluserdir")),"/eddobrpt",format(cnvtdatetime(curdate,curtime3),"YYYYMMDD;;Q"), ".csv")
set email_subject = "EDD OB Monthly Report"
SET email_body = concat("eddobmonthly_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")

Select into (value(email_body)) build2("EDD OB Monthly Report Report is attached to this email.",
            char(13), char(10), char(13), char(10),
            "This report ran on date and time: ",format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"),
            char(13), char(10), char(13),char(10),"CCL Object name: ",trim(cnvtlower(curprog)),char(13), char(10),
             char(13),char(10))
    from dummyt
    with format, noheading


    ;set send_to = "DwayneL.Simmons@medstar.net ,nalango.tunson@medstar.net"
    set send_to = "michael.m.mayes@medstar.net"


    SET  BDATE = cnvtdatetime(DATETIMEFIND(cnvtlookbehind("1,M"),"M","B","B"))
    SET  EDATE   = cnvtdatetime(DATETIMEFIND(cnvtlookbehind("1,M"),"M","E","E"))


endif

;;002 end
;***************************************************************************
; LOAD THE SELECTED LOCATION LIST PRIOR TO FILTERING LOGIC
;***************************************************************************
if(loadlocations(null) = -1)
    go to print_error_msg
endif

;call echorecord(LOCATIONList)
declare exp_cnt = i4 with noconstant(0)
declare org_parser = vc
if(locationlist->qual_cnt = 0)
    set org_parser = "1=1"
else

set org_parser = concat("(expand(EXP_CNT, 1, LOCATIONList->qual_cnt,pi.organization_id \
    ,LOCATIONList->qual[EXP_CNT].location_cd)", "OR expand(EXP_CNT, 1, LOCATIONList->qual_cnt, pi.organization_id \
    , LOCATIONList->qual[EXP_CNT].location_cd ))")
endif

;***************************************************************************
; SUBROUTINE TO PARSE THE LOCATIONS SELECTED AND LOAD A TEMPORARY LIST
; FOR USE BY THE APPLYFILTER SUBROUTINE
;***************************************************************************
declare lname = vc with protect, noconstant("")
declare oname = vc with protect, noconstant("")
subroutine loadlocations(null)
    declare mf8_loc_cd = f8 with protect, noconstant(0.0)
    declare mf8_org_id = f8 with protect, noconstant(0.0)
    declare mi4_loc_cnt1 = i4 with protect, noconstant(1)
    declare mi4_loc_cnt2 = i4 with protect, noconstant(0)
    declare mvc_loc_disp = vc with protect, noconstant("")
    declare mvc_org_disp = vc with protect, noconstant("")
    set mvc_loc_disp = substring(1, 1, trim(reflect(parameter(3, 0)), 3))
    call echo(build("MVC_LOC_DISP: ", mvc_loc_disp))
    if(not(mvc_loc_disp in ("F", "L")))

        ;call EchoIt("**** INVALID LOCATION DATA TYPE ****")
        return (-1)
    endif
    if(mvc_loc_disp = "L")
        while(mi4_loc_cnt1 > 0
            and mi4_loc_cnt2 < 9999)
            set mvc_loc_disp = substring(1, 1, trim(reflect(parameter(3, mi4_loc_cnt1)), 3))
            call echo(build("MVC_LOC_DISP: ", mvc_loc_disp))
            if(not(mvc_loc_disp = "F"))
                set mi4_loc_cnt = 0
            else
                set mf8_loc_cd = parameter(3, mi4_loc_cnt1)
                call echo(build("MF8_LOC_CD: ", mf8_loc_cd))
                if(not(mf8_loc_cd = 0.0))
                    set locationlist->qual_cnt = locationlist->qual_cnt + 1
                    if(mod(locationlist->qual_cnt, 100) = 1)
                        set stat = alterlist(locationlist->qual, locationlist->qual_cnt + 99)
                    endif
                    set locationlist->qual[locationlist->qual_cnt].location_cd = mf8_loc_cd
                endif
                set mi4_loc_cnt1 = mi4_loc_cnt1 + 1
            endif
            set mi4_loc_cnt2 = mi4_loc_cnt2 + 1 ;DEBUG ONLY
        endwhile
    else
        set mf8_loc_cd = parameter(3, mi4_loc_cnt1)
        call echo(build("MF8_LOC_CD: ", mf8_loc_cd))
        if(not(mf8_loc_cd = 0.0))
            set locationlist->qual_cnt = locationlist->qual_cnt + 1
            set stat = alterlist(locationlist->qual, locationlist->qual_cnt)
            set locationlist->qual[locationlist->qual_cnt].location_cd = mf8_loc_cd
        endif
    endif
    if(not(locationlist->qual_cnt = 0))
        set mi2_loc_filter_ind = 1
        set stat = alterlist(locationlist->qual, locationlist->qual_cnt)
        return (1)
    endif
    set mvc_loc_disp = substring(1, 1, trim(reflect(parameter(2, 0)), 3))
    call echo(build("MVC_LOC_DISP: ", mvc_loc_disp))
    if(not(mvc_loc_disp in ("F", "L")))

        ;call EchoIt("**** INVALID FACILITY DATA TYPE ****")
        return (-1)
    endif
    set mi4_loc_cnt1 = 1
    set mi4_loc_cnt2 = 0
    if(mvc_loc_disp = "L")
        while(mi4_loc_cnt1 > 0
            and mi4_loc_cnt2 < 9999)
            set mvc_loc_disp = substring(1, 1, trim(reflect(parameter(2, mi4_loc_cnt1)), 3))
            if(not(mvc_loc_disp = "F"))
                set mi4_loc_cnt = 0
            else
                set mf8_loc_cd = parameter(2, mi4_loc_cnt1)
                if(not(mf8_loc_cd in (0.0, -9999999999.0)))
                    set facilitylist->qual_cnt = facilitylist->qual_cnt + 1
                    if(mod(facilitylist->qual_cnt, 100) = 1)
                        set stat = alterlist(facilitylist->qual, facilitylist->qual_cnt + 99)
                    endif
                    set facilitylist->qual[facilitylist->qual_cnt].location_cd = mf8_loc_cd
                endif
                set mi4_loc_cnt1 = mi4_loc_cnt1 + 1
            endif
            set mi4_loc_cnt2 = mi4_loc_cnt2 + 1 ;DEBUG ONLY
        endwhile
    else
        set mf8_loc_cd = parameter(2, mi4_loc_cnt1)
        if(not(mf8_loc_cd in (0.0, -9999999999.0)))
            set facilitylist->qual_cnt = facilitylist->qual_cnt + 1
            set stat = alterlist(facilitylist->qual, facilitylist->qual_cnt)
            set facilitylist->qual[facilitylist->qual_cnt].location_cd = mf8_loc_cd
        endif
    endif
    if(facilitylist->qual_cnt = 0)
        return (0)
    endif

    select into "nl:"
        loc_cd = l3.organization_id
        ,loc_disp = trim(uar_get_code_display(l3.location_cd), 3) ;l3.location_cd,
;NEW
;LOC_OID = l3.organization_id
    from location_group lg
        ,location l2
        ,location_group lg2
        ,location l3
    plan lg where expand(mi4_loc_cnt1, 1, facilitylist->qual_cnt, lg.parent_loc_cd, facilitylist->qual[mi4_loc_cnt1].location_cd)
        and lg.root_loc_cd = 0
        and lg.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
        and lg.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
        and lg.active_ind = 1
    join l2 where l2.location_cd = lg.child_loc_cd
        and l2.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
        and l2.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
        and l2.active_ind = 1
    join lg2 where lg.child_loc_cd = lg2.parent_loc_cd
        and lg2.root_loc_cd = 0
        and lg2.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
        and lg2.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
        and lg2.active_ind = 1
    join l3 where l3.location_cd = lg2.child_loc_cd
        and l3.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
        and l3.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
        and l3.active_ind = 1
    order
        loc_disp
        ,l3.organization_id;l3.location_cd
    head report
        locationlist->qual_cnt = 0
    head l3.organization_id
        locationlist->qual_cnt = locationlist->qual_cnt + 1
         if(mod(locationlist->qual_cnt, 500) = 1)
            stat = alterlist(locationlist->qual, locationlist->qual_cnt + 499)
        endif
         locationlist->qual[locationlist->qual_cnt].location_cd = l3.organization_id  ;l3.location_cd
    foot report
        stat = alterlist(locationlist->qual, locationlist->qual_cnt)
    with nocounter;, time = 300

    if(error(mvc_err_msg, 0) > 0)

        ;call EchoIt("", 1)
        return (-1)
    endif
    set stat = initrec(facilitylist)
    ;RELEASE MEMORY
    if(not(locationlist->qual_cnt = 0))
        set mi2_loc_filter_ind = 1
    endif
    return (evaluate(locationlist->qual_cnt, 0, 0, 1))
end
;LoadLocations

select
    if($status = 1)
        plan pi where pi.active_ind = 1
            and parser(org_parser)
            and pi.preg_end_dt_tm > cnvtdatetime(curdate, curtime3)
            and pi.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
            and pi.historical_ind = 0
        join pb where pb.problem_id = pi.problem_id
            and pb.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
            and pb.life_cycle_status_cd = pb_active
        join p where p.person_id = pi.person_id
        order
            pi.person_id
            ,pb.onset_dt_tm
            ,pi.pregnancy_id
    elseif($status = 2)
        plan pi where pi.active_ind = 1
            and parser(org_parser)
            and pi.preg_end_dt_tm < cnvtdatetime(curdate, curtime3)
            and pi.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
            and pi.historical_ind = 0
        join pb where pb.problem_id = pi.problem_id
            and pb.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
            and pb.life_cycle_status_cd = pb_resolved
        join p where p.person_id = pi.person_id
        order
            pi.person_id
            ,pb.onset_dt_tm
            ,pi.pregnancy_id
    endif
into "NL:"
from pregnancy_instance pi
    ,problem pb
    ,person p
plan pi where pi.active_ind = 1
    and parser(org_parser)
    and pi.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
    and pi.historical_ind = 0
join pb where pb.problem_id = pi.problem_id
    and pb.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
    and pb.life_cycle_status_cd in (pb_active, pb_resolved)
join p where p.person_id = pi.person_id
order
    pi.person_id
    ,pb.onset_dt_tm
    ,pi.pregnancy_id
head report
    p_cnt = 0
head pi.person_id
    preg_cnt = 0
     call echo(build(pi.person_id, ","))
head pi.pregnancy_id
    p_cnt = p_cnt + 1
     if(mod(p_cnt, 10) = 1)
        stat = alterlist(ob->pt, p_cnt + 9)
    endif
     ob->pt[p_cnt].person_id = pi.person_id
     ob->pt[p_cnt].last_name = p.name_last_key
     ob->pt[p_cnt].first_name = p.name_first_key
     ob->pt[p_cnt].dob = p.birth_dt_tm
     ob->pt[p_cnt].pregnancy_id = pi.pregnancy_id
     ob->pt[p_cnt].org_id = pi.organization_id
     ob->pt[p_cnt].preg_onset_dt_tm = pb.onset_dt_tm
     ob->pt[p_cnt].life_cycle_status_cd = pb.life_cycle_status_cd
     ob->pt[p_cnt].life_cycle_status = uar_get_code_display(pb.life_cycle_status_cd)
     ob->pt[p_cnt].preg_end_dt_tm = pi.preg_end_dt_tm
     if(pb.onset_dt_tm != null
        and pb.onset_dt_tm < ob->earliestpregnancydt)
        ob->earliestpregnancydt = pb.onset_dt_tm
    endif
     preg_cnt = preg_cnt + 1
foot report
    stat = alterlist(ob->pt, p_cnt)
with nocounter

if(curqual > 0)
    ;002 START MRN/EMPI
    select into "NL:"

    from PERSON_ALIAS PA
        ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join PA where PA.person_id = ob->pt[d1.seq].person_id
        and PA.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and PA.active_ind = 1
        AND PA.PERSON_ALIAS_TYPE_CD IN ( 2.00   ;Community Medical Record Number
                                        ;, 10.00 ;MRN    ;003 We are going to kill this and do it later.

                                        )
    order
        PA.person_id
        ,PA.PERSON_ALIAS_TYPE_CD

    DETAIL

        IF(PA.PERSON_ALIAS_TYPE_CD = 2.00)
            ob->pt[d1.seq].EMPI = PA.ALIAS
        ELSEIF(PA.PERSON_ALIAS_TYPE_CD = 10.00)     ;003 We are going to kill this and do it later.
            ob->pt[d1.seq].mrn  = PA.ALIAS
        ENDIF

        ;IF(PA.PERSON_ALIAS_TYPE_CD = 2.00)
        ;    ob->pt[d1.seq].EMPI = PA.ALIAS
        ;;ELSEIF(PA.PERSON_ALIAS_TYPE_CD = 10.00)     ;003 We are going to kill this and do it later.
        ;;    ob->pt[d1.seq].mrn  = PA.ALIAS
        ;ENDIF
    with nocounter

     ;002 END







    ;PRIMARY PHONE NUMBER

    select into "NL:"
        p_id = ob->pt[d1.seq].person_id
    from phone ph
        ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join ph where ph.parent_entity_id = ob->pt[d1.seq].person_id
        and ph.active_ind = 1
        and ph.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and ph.phone_type_seq = 1
    order
        p_id
        ,ph.beg_effective_dt_tm
    head p_id
        homex = ""
         businessx = ""
         alternatex = ""
         mobilex = ""
    detail
        case(ph.phone_type_cd)
         of phhome: homex = ph.phone_num
         of phbusiness: businessx = ph.phone_num
         of phalternate: alternatex = ph.phone_num
         of phmobile: mobilex = ph.phone_num
        endcase
    foot p_id
        if(homex != "")
            ob->pt[d1.seq].primary_phone = homex
        else
            if(mobilex != "")
                ob->pt[d1.seq].primary_phone = mobilex
            else
                if(alternatex != "")
                    ob->pt[d1.seq].primary_phone = alternatex
                else
                    if(businessx != "")
                        ob->pt[d1.seq].primary_phone = businessx
                    else
                        ob->pt[d1.seq].primary_phone = "n/a"
                    endif
                endif
            endif
        endif
    with nocounter

;ADDRESS

    select into "NL:"
        p_id = ob->pt[d1.seq].person_id
    from address a
        ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join a where a.parent_entity_id = ob->pt[d1.seq].person_id
        and a.active_ind = 1
        and a.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and a.address_type_cd = home_addr
    order
        p_id
    detail
        ob->pt[d1.seq].address_1 = a.street_addr
         ob->pt[d1.seq].address_2 = a.street_addr2
         ob->pt[d1.seq].city = a.city
         ob->pt[d1.seq].state = a.state
         ob->pt[d1.seq].zip = a.zipcode
    with nocounter

;PRIMARY HEALTH INSURANCE

    select into "NL:"
    from person_plan_reltn pr
        ,health_plan h
        ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join pr where pr.person_id = ob->pt[d1.seq].person_id
        and pr.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and pr.active_ind = 1
    join h where h.health_plan_id = pr.health_plan_id
    order
        pr.person_id
    head pr.person_id
        ob->pt[d1.seq].primary_insurance = h.plan_name
    with nocounter


    select into "NL:"
    from pregnancy_estimate pe
        ,long_text lt
        ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join pe where pe.pregnancy_id = ob->pt[d1.seq].pregnancy_id
        and pe.pregnancy_estimate_id not in (select
            pe2.prev_preg_estimate_id
            from pregnancy_estimate pe2
            where pe2.pregnancy_id = pe.pregnancy_id)
    join lt where lt.long_text_id = outerjoin(pe.edd_comment_id)
    order
        pe.pregnancy_id
        ,pe.entered_dt_tm desc
        ,pe.pregnancy_estimate_id
    head pe.pregnancy_id
        p_weeks = fillstring(5, " ")
         p_days = fillstring(5, " ")
    detail

        ; #001 - pe.est_gest_age_days doesn't get updated daily which leads to erroneous results
        ; #001 - modified to use 280 days minus date diff between report runtime and est del date to get est gest age
         calc_est_gest_age = 280 - datetimediff(pe.est_delivery_dt_tm, cnvtdatetime(curdate, curtime3))
         ; #001
         p_weeks = cnvtstring(cnvtint(calc_est_gest_age / 7))
         ; #001 - CNVTINT eliminates rounding issues
         p_days = cnvtstring(mod(calc_est_gest_age, 7))
         ; #001
        ;   p_weeks = cnvtstring((pe.est_gest_age_days/7))          ; #001
        ;   p_days = cnvtstring(mod(pe.est_gest_age_days, 7))       ; #001
         ob->pt[d1.seq].est_gest_age = calc_est_gest_age  ; #001
;   ob->pt[d1.seq]->est_gest_age = pe.est_gest_age_days     ; #001
         ob->pt[d1.seq].ega_format = build2(trim(p_weeks), " weeks ", trim(p_days), " days ")
         ob->pt[d1.seq].pregnancy_estimate_id = pe.pregnancy_estimate_id
         ob->pt[d1.seq].pregnancy_id = pe.pregnancy_id
         ob->pt[d1.seq].status_flag = pe.status_flag
         ob->pt[d1.seq].method_cd = pe.method_cd
         ob->pt[d1.seq].method_dt_tm = pe.method_dt_tm
         ob->pt[d1.seq].author_id = pe.author_id
         ob->pt[d1.seq].descriptor_cd = pe.descriptor_cd
         ob->pt[d1.seq].descriptor_txt = pe.descriptor_txt
         ob->pt[d1.seq].descriptor_flag = pe.descriptor_flag
         ob->pt[d1.seq].crown_rump_length = pe.crown_rump_length
         ob->pt[d1.seq].biparietal_diameter = pe.biparietal_diameter
         ob->pt[d1.seq].head_circumference = pe.head_circumference
         ob->pt[d1.seq].est_delivery_date = pe.est_delivery_dt_tm
         ob->pt[d1.seq].confirmation_cd = pe.confirmation_cd
         ob->pt[d1.seq].prev_edd_id = pe.prev_preg_estimate_id
         ob->pt[d1.seq].active_ind = pe.active_ind
         ob->pt[d1.seq].updt_dt_tm = pe.updt_dt_tm
         ob->pt[d1.seq].entered_dt_tm = pe.entered_dt_tm
         ob->pt[d1.seq].edd_comment = lt.long_text
    with nocounter

;call echo("[TRACE]: Fetching historic estimates")
    declare act_eddcnt = i2 with private, constant(size(ob->pt, 5))
    declare prev_edd_id = f8 with protect, noconstant(0.0)
    declare i = i4 with protect, noconstant(0)
    declare chaincnt = i4 with protect, noconstant(0)

    ;PREVIOUS EDD
    for(i = 1 to act_eddcnt)
        set prev_edd_id = ob->pt[i].prev_edd_id
        set chaincnt = 0
        set stat = alterlist(ob->pt[i].prev_edds, 10)
        while(prev_edd_id != 0.0)

            select into "nl:"
            from pregnancy_estimate pe
                ,long_text lt
                ,pregnancy_detail pd
            plan pe where pe.pregnancy_estimate_id = prev_edd_id
            join lt where lt.long_text_id = outerjoin(pe.edd_comment_id)
            join pd where pd.pregnancy_estimate_id = outerjoin(pe.pregnancy_estimate_id)
            head report
                chaincnt = chaincnt + 1
                 if(mod(chaincnt, 10) = 1)
                    stat = alterlist(ob->pt[i].prev_edds, chaincnt + 9)
                endif
                 ob->pt[i].prev_edds[chaincnt].pregnancy_estimate_id = pe.pregnancy_estimate_id
                 ob->pt[i].prev_edds[chaincnt].pregnancy_id = pe.pregnancy_id
                 ob->pt[i].prev_edds[chaincnt].status_flag = pe.status_flag
                 ob->pt[i].prev_edds[chaincnt].method_cd = pe.method_cd
                 ob->pt[i].prev_edds[chaincnt].method_dt_tm = pe.method_dt_tm
                 ob->pt[i].prev_edds[chaincnt].descriptor_cd = pe.descriptor_cd
                 ob->pt[i].prev_edds[chaincnt].descriptor_txt = pe.descriptor_txt
                 ob->pt[i].prev_edds[chaincnt].descriptor_flag = pe.descriptor_flag
                 ob->pt[i].prev_edds[chaincnt].crown_rump_length = pe.crown_rump_length
                 ob->pt[i].prev_edds[chaincnt].biparietal_diameter = pe.biparietal_diameter
                 ob->pt[i].prev_edds[chaincnt].head_circumference = pe.head_circumference
                 ob->pt[i].prev_edds[chaincnt].est_gest_age = pe.est_gest_age_days
                 ob->pt[i].prev_edds[chaincnt].est_delivery_date = pe.est_delivery_dt_tm
                 ob->pt[i].prev_edds[chaincnt].confirmation_cd = pe.confirmation_cd
                 ob->pt[i].prev_edds[chaincnt].active_ind = pe.active_ind
                 ob->pt[i].prev_edds[chaincnt].edd_comment = lt.long_text
                 ob->pt[i].prev_edds[chaincnt].author_id = pe.author_id
                 ob->pt[i].prev_edds[chaincnt].entered_dt_tm = pe.entered_dt_tm
                 prev_edd_id = pe.prev_preg_estimate_id
                 if(pd.pregnancy_detail_id > 0)
                    stat = alterlist(ob->pt[i].prev_edds[chaincnt].details, 1)
                     ob->pt[i].prev_edds[chaincnt].details[1].lmp_symptoms_txt = pd.lmp_symptoms_txt
                     ob->pt[i].prev_edds[chaincnt].details[1].breastfeeding_ind = pd.breastfeeding_ind
                     ob->pt[i].prev_edds[chaincnt].details[1].contraception_duration = pd.contraception_duration
                     ob->pt[i].prev_edds[chaincnt].details[1].contraception_ind = pd.contraception_ind
                     ob->pt[i].prev_edds[chaincnt].details[1].menarche_age = pd.menarche_age
                     ob->pt[i].prev_edds[chaincnt].details[1].pregnancy_test_dt_tm = pd.pregnancy_test_dt_tm
                     ob->pt[i].prev_edds[chaincnt].details[1].menstrual_freq = pd.menstrual_freq
                     ob->pt[i].prev_edds[chaincnt].details[1].prior_menses_dt_tm = pd.prior_menses_dt_tm
                endif
            with nocounter

            if(curqual = 0)
                set prev_edd_id = 0.0
            endif
        endwhile
        set stat = alterlist(ob->pt[i].prev_edds, chaincnt)
        if(chaincnt > 0)
            set ob->pt[i].creator_id = ob->pt[i].prev_edds[chaincnt].author_id
            set ob->pt[i].original_entered_dttm = ob->pt[i].prev_edds[chaincnt].entered_dt_tm
        endif
    endfor
/*******************************************************************************************
fixing backend error 255 exceeds parameter limit
 with expand failing to pass all locations with any prompt change to dummyt
********************************************************************************************/
    select into "NL:"
    from
     (dummyt d1 with seq = size(ob->pt, 5));002
     ,(dummyt d2 with SEQ = 1);002
    ,pregnancy_detail pd
    ;plan pd where expand(ndx, 1, size(ob->pt, 5), pd.pregnancy_estimate_id, ob->pt[ndx].pregnancy_estimate_id)

     plan d1 where  maxrec(d2,size(ob->pt[d1.seq].details,5))
        JOIN D2

       join pd
       where
       pd.pregnancy_estimate_id =  ob->pt[d1.SEQ].pregnancy_estimate_id
        and pd.active_ind = 1
    order
        pd.pregnancy_estimate_id
        ,pd.pregnancy_detail_id
    head pd.pregnancy_estimate_id
        ;pos = locateval(nx, 1, size(ob->pt, 5), pd.pregnancy_estimate_id, ob->pt[nx].pregnancy_estimate_id)
         ;stat = alterlist(ob->pt[d1.SEQ].details, 10)
         ;dtx = 0
         null
    detail
        ;dtx = dtx + 1
         ;if(mod(dtx, 10) = 1)
            ;stat = alterlist(ob->pt[d1.SEQ].details, dtx + 9)
        ;endif
         ob->pt[d1.SEQ].details[d2.SEQ].lmp_symptoms_txt = pd.lmp_symptoms_txt
         ob->pt[d1.SEQ].details[d2.SEQ].breastfeeding_ind = pd.breastfeeding_ind
         ob->pt[d1.SEQ].details[d2.SEQ].contraception_duration = pd.contraception_duration
         ob->pt[d1.SEQ].details[d2.SEQ].contraception_ind = pd.contraception_ind
         ob->pt[d1.SEQ].details[d2.SEQ].menarche_age = pd.menarche_age
         ob->pt[d1.SEQ].details[d2.SEQ].pregnancy_test_dt_tm = pd.pregnancy_test_dt_tm
         ob->pt[d1.SEQ].details[d2.SEQ].menstrual_freq = pd.menstrual_freq
         ob->pt[d1.SEQ].details[d2.SEQ].prior_menses_dt_tm = pd.prior_menses_dt_tm
    foot pd.pregnancy_estimate_id
        ob->pt[d1.SEQ].prior_menses_dt_tm = pd.prior_menses_dt_tm
         ;stat = alterlist(ob->pt[pos].details, dtx)
    with nocounter

;REVIEWING ENCOUNTERS

    select
        if($status = 2)
            plan d1
            join e where e.person_id = ob->pt[d1.seq].person_id
                and e.organization_id = ob->pt[d1.seq].org_id   
                and e.reg_dt_tm between cnvtdatetime(ob->pt[d1.seq].preg_onset_dt_tm) and
                cnvtdatetime(ob->pt[d1.seq].preg_end_dt_tm)
            order
                e.person_id
                ,e.reg_dt_tm
                ,e.encntr_id
        endif
    into "NL:"
    from encounter e
       ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join e where e.person_id = ob->pt[d1.seq].person_id
        and e.organization_id = ob->pt[d1.seq].org_id  
        and e.reg_dt_tm >= cnvtdatetime(ob->pt[d1.seq].preg_onset_dt_tm)

    order
        e.person_id
        ,e.reg_dt_tm
        ,e.encntr_id
    head report
        x = 0
    head e.person_id
        x = x + 1
         y = 0
         e = 0
;detail
    head e.encntr_id
        y = y + 1
         e = e + 1
         if(mod(e, 10) = 1)
            stat = alterlist(ob->pt[d1.seq].ambx, e + 9)
        endif

         ob->pt[d1.seq].ambx[e].encntr_id = e.encntr_id

         ob->pt[d1.seq].ambx[e].reg_dt_tm = e.reg_dt_tm
         ob->pt[d1.seq].ambx[e].disch_dt_tm = e.disch_dt_tm
         ob->pt[d1.seq].ambx[e].encounter_type = uar_get_code_display(e.encntr_type_cd)
         ob->pt[d1.seq].ambx[e].facility = uar_get_code_display(e.loc_facility_cd)
    foot e.person_id
        stat = alterlist(ob->pt[d1.seq].ambx, e)
         ob->pt[d1.seq].most_recent_encntr_id = e.encntr_id
         ob->pt[d1.seq].most_recent_reg_dt_tm = e.reg_dt_tm
         ob->pt[d1.seq].most_recent_facility = uar_get_code_display(e.loc_facility_cd)
    with nocounter


    select into "NL:"
    from encntr_prsnl_reltn epr
        ,prsnl pr
        ,(dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    join epr where epr.encntr_id = ob->pt[d1.seq].most_recent_encntr_id
        and epr.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and epr.active_ind = 1
    join pr where pr.person_id = epr.prsnl_person_id
        and pr.active_ind = 1
    order
        epr.encntr_id
        ,epr.transaction_dt_tm
        ,epr.encntr_prsnl_reltn_id
    head epr.encntr_id
        attendx = ""
         admitx = ""
         primaryteamx = ""
    detail
        case(epr.encntr_prsnl_r_cd)
         of var_primaryteam: primaryteamx = pr.name_full_formatted
         of var_attending: attendx = pr.name_full_formatted
         of var_admitting: admitx = pr.name_full_formatted
        endcase
    foot epr.encntr_id
        ob->pt[d1.seq].primaryteamx = primaryteamx
         ob->pt[d1.seq].attendx = attendx
         ob->pt[d1.seq].admitx = admitx
    with nocounter


;003->
;This is where I am going to do my work, because we've found the most recent_encntr_id above... so I don't have to do that work.
;Nevermind, can't use that, they only want MRN and FIN if the case is delievered.

;I'm going to borrow some of my logic for that.  Which is... we'll go out and find a delivery date DTA, and use that encounter
;for our stuff.

select into 'nl:'
  
  from pregnancy_instance pi
     , clinical_event    ce
     , (dummyt d with seq = size(ob->pt, 5))
  
  plan d
   where size(ob->pt, 5)            > 0
     and ob->pt[d.seq].pregnancy_id > 0
   
  join pi
   where pi.pregnancy_id            =  ob->pt[d.seq].pregnancy_id
  
  join ce
   where ce.person_id               =  pi.person_id
     and ce.event_cd                in (4159920.00, 2207848353.00)
     and ce.event_end_dt_tm    between pi.preg_start_dt_tm and pi.preg_end_dt_tm

order by pi.pregnancy_id, ce.event_end_dt_tm desc

head pi.pregnancy_id

    ob->pt[d.seq]->del_encntr_id = ce.encntr_id

with nocounter
   



/**********************************************************************
DESCRIPTION:  Find most recent MRN
***********************************************************************/
select into 'nl:'

  from encntr_alias ea
     , (dummyt d with seq = size(ob->pt, 5))

  plan d
   where size(ob->pt, 5)              > 0
     and ob->pt[d.seq]->del_encntr_id > 0

  join ea
   where ea.encntr_id                 =  ob->pt[d.seq]->del_encntr_id
     and ea.encntr_alias_type_cd      =  1079.00  ; MRN
     and ea.active_ind                =  1
     and ea.beg_effective_dt_tm       <  cnvtdatetime(curdate,curtime)
     and ea.end_effective_dt_tm       >  cnvtdatetime(curdate,curtime)

order by ea.encntr_id

detail

    ob->pt[d.seq]->new_mrn = trim(ea.alias, 3)

with nocounter


/**********************************************************************
DESCRIPTION:  Find most recent FIN
***********************************************************************/
select into 'nl:'

  from encntr_alias ea
     , (dummyt d with seq = size(ob->pt, 5))

  plan d
   where size(ob->pt, 5)              > 0
     and ob->pt[d.seq]->del_encntr_id > 0

  join ea
   where ea.encntr_id                 =  ob->pt[d.seq]->del_encntr_id
     and ea.encntr_alias_type_cd      =  1077.00  ; FIN
     and ea.active_ind                =  1
     and ea.beg_effective_dt_tm       <  cnvtdatetime(curdate,curtime)
     and ea.end_effective_dt_tm       >  cnvtdatetime(curdate,curtime)

order by ea.encntr_id

detail

    ob->pt[d.seq]->fin = trim(ea.alias, 3)

with nocounter




;003<-



/*************************************************************
CREATE THE OUTFILE
**********************************************************/
 declare preg_id = f8 with noconstant(0)
    declare location = vc with noconstant("")
    declare last_name = vc with noconstant("")
    declare first_name = vc with noconstant("")
    declare dob = vc with noconstant("")
    declare lmp = vc with noconstant("")
    declare last_visit_provider = vc with noconstant("")
    declare last_visit_date = vc with noconstant("")
    declare edd = vc with noconstant("")
    declare ega = vc with noconstant("")
    declare address_1 = vc with noconstant("")
    declare address_2 = vc with noconstant("")
    declare city = vc with noconstant("")
    declare state = vc with noconstant("")
    declare status = vc with noconstant("")
    declare zip = vc with noconstant("")
    declare primary_insurance = vc with noconstant("")
    declare primary_phone = vc with noconstant("")
    declare eddx = dq8
    ;call echorecord(ob)

if ($OUTDEV = "OPS") ;002 LOGIC FOR EMAIL
 select into value(output_file)
          LOCATION = substring(1, 50, ob->pt[d1.seq].most_recent_facility)
         ,LAST_NAME= substring(1, 50, ob->pt[d1.seq].last_name)
         ,FIRST_NAME= substring(1, 50, ob->pt[d1.seq].first_name)
         ,DOB= substring(1, 20, format(ob->pt[d1.seq].dob, "MM/DD/YYYY;;d"))
         ;.,MRN= substring(1, 50, ob->pt[d1.seq].mrn) ;002
         ,MRN= substring(1, 50, ob->pt[d1.seq].new_mrn) ;003
         ,FIN= substring(1, 50, ob->pt[d1.seq].fin) ;003
         ,EMPI= substring(1, 50, ob->pt[d1.seq].EMPI)

         ,LAST_VISIT_PROVIDER = if(ob->pt[d1.seq].primaryteamx != null)
                                    substring(1, 50, ob->pt[d1.seq].primaryteamx)
                                else
                                        if(ob->pt[d1.seq].attendx != null)
                                            substring(1, 50, ob->pt[d1.seq].attendx)
                                        else
                                            substring(1, 50, ob->pt[d1.seq].admitx)
                                        endif
                                endif
         ,LAST_VISIT_DATE= substring(1, 30, format(ob->pt[d1.seq].most_recent_reg_dt_tm, ";;q"))
         ,EDD= substring(1, 30, format(ob->pt[d1.seq].est_delivery_date, "MM/DD/YYYY;;d"))
         ,EGA= substring(1, 20, ob->pt[d1.seq].ega_format)
         ,STATUS= substring(1, 10, ob->pt[d1.seq].life_cycle_status)
         ,ADDRESS_1= substring(1, 50, ob->pt[d1.seq].address_1)
         ,ADDRESS_2= substring(1, 50, ob->pt[d1.seq].address_2)
         ,CITY= substring(1, 50, ob->pt[d1.seq].city)
         ,STATE= substring(1, 50, ob->pt[d1.seq].state)
         ,ZIP= substring(1, 20, ob->pt[d1.seq].zip)
         ,PRIMARY_PHONE = substring(1, 20, trim(ob->pt[d1.seq].primary_phone))
         ,PRIMARY_INSURANCE = substring(1, 50, trim(ob->pt[d1.seq].primary_insurance))
         ,preg_id = ob->pt[d1.seq].pregnancy_id
          ,eddx = ob->pt[d1.seq].est_delivery_date
    from (dummyt d1 with seq = size(ob->pt, 5))
    plan d1 where ob->pt[d1.seq].est_delivery_date between cnvtdatetime(BDATE) and cnvtdatetime(EDATE)
     order BY
       eddx
        ,preg_id


with nocounter, format, format=stream, pcformat('"', ',',1),compress, check

if(findfile(trim(output_file)) =1)  ;EMAIL ONLY CURRENT DAYS FILE
    call xmailx("reporting@medstar.net",value(send_to),"",value(email_subject),value(email_body),output_file)
ENDIF
ENDIF

;;002 LOGIC FOR EMAIL END
IF ($OUTDEV !="OPS") ;002


    select into $outdev
        preg_id = ob->pt[d1.seq].pregnancy_id
        ,eddx = ob->pt[d1.seq].est_delivery_date
    from (dummyt d1 with seq = size(ob->pt, 5))
    plan d1
    where ob->pt[d1.seq].est_delivery_date between cnvtdatetime($startdate) and cnvtdatetime($enddate)

    order
        eddx
        ,preg_id
    head report
        ;002 START
         col 0   "LOCATION"
         col 50  "LAST_NAME"
         col 100 "FIRST_NAME"
         col 150 "DOB"
         ;col 180 "MRN"    ;003 Removing this.
         col 180 "MRN" ;003 These are new and adjusted all the col numbers.
         col 210 "FIN"
         col 260 "EMPI"
         col 310 "LAST_VISIT_PROVIDER"
         col 360 "LAST_VISIT_DATE"
         col 410 "EDD"
         col 450 "EGA"
         col 480 "STATUS"
         col 510 "ADDRESS_1"
         col 540 "ADDRESS_2"
         col 570 "CITY"
         col 600 "STATE"
         col 630 "ZIP"
         col 660 "PRIMARY_PHONE"
         col 710 "PRIMARY_INSURANCE"

        ROW+1
        /*col 0 "LOCATION"
         col 50 "LAST_NAME"
         col 100 "FIRST_NAME"
         col 150 "DOB"
         col 170 "LAST_VISIT_PROVIDER"
         col 220 "LAST_VISIT_DATE"
         col 250 "EDD"
         col 280 "EGA"
         col 300 "STATUS"
         col 310 "ADDRESS_1"
         col 360 "ADDRESS_2"
         col 410 "CITY"
         col 460 "STATE"
         col 510 "ZIP"
         col 530 "PRIMARY_PHONE"
         col 550 "PRIMARY_INSURANCE"
         row+1*/ ;002 END
    detail
        location = substring(1, 50, ob->pt[d1.seq].most_recent_facility)
         last_name = substring(1, 50, ob->pt[d1.seq].last_name)
         first_name = substring(1, 50, ob->pt[d1.seq].first_name)
         dob = substring(1, 20, format(ob->pt[d1.seq].dob, "MM/DD/YYYY;;d"))
         lmp = substring(1, 30, format(ob->pt[d1.seq].prior_menses_dt_tm, ";;q"))
         mrn = substring(1, 50, ob->pt[d1.seq].mrn) ;002
         newmrn = substring(1, 50, ob->pt[d1.seq].new_mrn) ;003
         fin = substring(1, 50, ob->pt[d1.seq].fin) ;003
         empi = substring(1, 50, ob->pt[d1.seq].EMPI);002

         if(ob->pt[d1.seq].primaryteamx != null)
            last_visit_provider = substring(1, 50, ob->pt[d1.seq].primaryteamx)
        else
            if(ob->pt[d1.seq].attendx != null)
                last_visit_provider = substring(1, 50, ob->pt[d1.seq].attendx)
            else
                last_visit_provider = substring(1, 50, ob->pt[d1.seq].admitx)
            endif
        endif
         last_visit_date = substring(1, 30, format(ob->pt[d1.seq].most_recent_reg_dt_tm, ";;q"))
         edd = substring(1, 30, format(ob->pt[d1.seq].est_delivery_date, "MM/DD/YYYY;;d"))
         ega = substring(1, 20, ob->pt[d1.seq].ega_format)
         address_1 = substring(1, 50, ob->pt[d1.seq].address_1)
         address_2 = substring(1, 50, ob->pt[d1.seq].address_2)
         city = substring(1, 50, ob->pt[d1.seq].city)
         state = substring(1, 50, ob->pt[d1.seq].state)
         zip = substring(1, 20, ob->pt[d1.seq].zip)
         primary_phone = substring(1, 20, trim(ob->pt[d1.seq].primary_phone))
         primary_insurance = substring(1, 50, trim(ob->pt[d1.seq].primary_insurance))
         status = substring(1, 10, ob->pt[d1.seq].life_cycle_status)
         col 0  ,location
         col 50 ,last_name
         col 100,first_name
         col 150,dob
         ;col 180,mrn     ;002   ;003 removing
         col 180,newmrn  ;003
         col 210,fin     ;003
         col 260,empi    ;002
         col 310,last_visit_provider
         col 360,last_visit_date
         col 410,edd
         col 450,ega
         col 480,status
         col 510,address_1
         col 540,address_2
         col 570,city
         col 600,state
         col 630,zip
         col 660,primary_phone
         col 710,primary_insurance
         /*col 170,last_visit_provider
         col 220,last_visit_date
         col 250,edd
         col 280,ega
         col 300,status
         col 310,address_1
         col 360,address_2
         col 410,city
         col 460,state
         col 510,zip
         col 530,primary_phone
         col 550,primary_insurance*/
         row+1
    foot report
        ;p2 = cnvtreal($2)
        ; p3 = cnvtreal($3)
         row+2
         col 0 "END OF REPORT"
         row+1
    with format, maxcol = 1000, maxrow = 1000, separator = " ", nullreport


    select into "NL:"
        d1.seq
    from (dummyt d1 with format)
    with nocounter, maxrow = 1000, separator = " ", nullreport
else
    declare noqual = vc
    set noqual = "No qualifying results"

    select into $outdev
    from (dummyt d1 with seq = 1)
    plan d1
    head report
        col 0 " "
         row+1
         col 0 "No qualifying results"
    with format, maxcol = 1000, maxrow = 1000, separator = " "

endif
ENDIF ;002 END



/**************************************************************************
EMAIL SUBROUTINE
*************************************************************************/


subroutine xmailx(afrom, ato, acc, asubject, abody, afile)
  set xcommand = fillstring(512, " ")
  if(afrom = "")
      set xfrom = "reporting@medstar.net"
  else
      set xfrom = afrom
  endif

  set xbody = concat("cat ", abody," | tr -d \\r | mailx ")

  if(afile != "")
      set xfile = concat(" -a ", char(34), trim(afile, 7), char(34))
  else
      set xfile = ""
  endif
  set xsubject = concat(" -s ", char(34), asubject, char(34))
  if(acc != "")
      set xcc = concat(" -c ", acc)
  else
      set xcc = ""
  endif
  set xfromto = concat(" -r ", xfrom, " ", ato)
  if(xcc != "")
      set xcommand = concat(trim(xbody, 7), xsubject, xfile, xcc, xfromto)
  else
      set xcommand = concat(trim(xbody, 7), xsubject, xfile, xfromto)
  endif
  call echo(xcommand)
  set xlength = size(trim(xcommand, 7))
  set xstatus = 0
  call dcl(trim(xcommand, 7), xlength, xstatus)
  call echo(xstatus)
  return
end


call echorecord(ob)


end go
