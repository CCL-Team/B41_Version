/*****************************************************************************************
 Program Title: GUH Patient Label Work Around
 
 Object name:   6_pat_label_work_around_guh
 Source file:   6_pat_label_work_around_guh.prg
 
 Purpose:       Phew... so a package broke cassette label printing, and now it is up
                to me to create a script that will print the labels manually.
 
                After much hunting, and help from others, we determined an existing
                label will work... and that label is created by MHGR_DC_PHA_PAT_LABEL
 
                However that script only has a request for one patient at a time.
 
                We want to run for a set of WHC Nurse Units.
 
                So I'm creating a Frankenstein wrapper, to build a bigger request
                programmatically, to see if I can get multiple labels to show up.
 
                Haha, just kidding they had me modify the layout too.
                Still used the other one as a base.
 Tables read:
 
 Executed from:
 
 Special Notes: Old mod block of this guy from prod.
        *********************************************************************
        Program:        MHGR_DC_PHA_PAT_LABEL.prg
 
        Programmer:     Brad Weaver
        Date:           08/19/10
        Request ID:
 
        Executed From:  PhaMedMgr
        Purpose:        Replaces rx_rpt_std_patient_label as the patient label
                        used in PhaMedMgr.
 
 
        **********************************************************************
        *                      GENERATED MODIFICATION CONTROL LOG            *
        **********************************************************************
        *                                                                    *
        Mod Date       Worker        Comment                                 *
        --- ---------- ------------- ----------------------------------------*
        001 08/19/2010 Brad Weaver   Initial Development
        **********************************************************************
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 07/09/2020 Michael Mayes               Initial release
002 04/08/2024 Michael Mayes        346821 Adding C52
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
 
 
  drop program 6_pat_label_work_around_guh:dba go
create program 6_pat_label_work_around_guh:dba
 
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
 
with OUTDEV
 
 
;run id: 2477560
;MAYES NOTE: We don't want the request anymore... we'll generate stuff ourselves.
;if (  not ( validate ( request , 0 ) ) )
;    record  request  (
;    1  person_id            =  f8
;    1  encntr_id            =  f8
;    1  name_full_formatted  =  vc
;    1  age                  =  i4
;    1  birth_dt_tm          =  vc
;    1  sex                  =  vc
;    1  height_nbr           =  f8
;    1  height_unit_cd       =  f8
;    1  weight_nbr           =  f8
;    1  weight_unit_cd       =  f8
;    1  mrn_nbr              =  vc
;    1  fin_nbr              =  vc
;    1  facility_cd          =  f8
;    1  facility_display     =  vc
;    1  location_cd          =  f8
;    1  location_display     =  vc
;    1  output_format_cd     =  f8
;    1  output_device_cd     =  f8
;    1  label_cnt            =  i4
;    1  note_text            =  vc
;    1  labeldetail_qual [*]
;        2  item_cnt         =  i4 ) with  protect
;endif
 
;MAYES NOTE: This also goes away.
;record  data  (
;    1  labeldetail [*]
;        2  label_id               =  i4
;        2  name_full_formatted    =  vc
;        2  age                    =  i4
;        2  birth_dt_tm            =  vc
;        2  sex                    =  vc
;        2  height_str             =  vc
;        2  weight_str             =  vc
;        2  mrn_nbr                =  vc
;        2  fin_nbr                =  vc
;        2  ssn_nhs_nbr            =  vc
;        2  person_street_addr1    =  vc
;        2  person_street_addr2    =  vc
;        2  person_street_addr3    =  vc
;        2  person_street_addr4    =  vc
;        2  person_city            =  vc
;        2  person_state           =  vc
;        2  person_zipcode         =  vc
;        2  person_phone           =  vc
;        2  facility               =  vc
;        2  location               =  vc
;        2  room                   =  vc
;        2  bed                    =  vc
;        2  facility_street_addr1  =  vc
;        2  facility_street_addr2  =  vc
;        2  facility_street_addr3  =  vc
;        2  facility_street_addr4  =  vc
;        2  facility_city          =  vc
;        2  facility_state         =  vc
;        2  facility_zipcode       =  vc
;        2  facility_phone         =  vc
;        2  note_text              =  vc
;        2  item_cnt               =  i4
;)
 
 
record rdata(
    1 cnt                     = i4 ;MAYES ADDITION
    1 labeldetail[*]
        2 encntr_id           = f8
        2 person_id           = f8
        2 admit_dt_tm         = vc
        2 med_service         = vc
        2 age_disp            = vc
        2 age_dob_sex         = c60
        2 name_full_formatted = vc
        2 birth_dt_tm         = vc
        2 sex                 = vc
        2 location            = vc
        2 room                = vc
        2 bed                 = vc
        2 fin_nbr             = vc
        2 fin_disp            = vc
        2 mrn_nbr             = vc
        2 attend_doc          = vc
        2 admit_doc           = vc
)with protect
 
RECORD reply (
    1 ops_event = vc
    1 status_data
        2 status = c1
        2 subeventstatus [1 ]
            3 operationname = vc
            3 operationstatus = c1
            3 targetobjectname = vc
            3 targetobjectvalue = vc
 )
 
set reply->ops_event = '6_pat_label_work_around'
set reply->status_data->status = 'S'
set reply->status_data->subeventstatus->operationstatus = 'S'
set reply->status_data->subeventstatus->operationname = 'Autosuccess'
 
;-->
;MAYES NOTES: Additions here for a population rather than a request.
;We do this by looking for non-discharged in the nurse units we are after.
;These nurse units came from the cassette batch build.
;Performance might be a concern, but seemed to work mostly okay for me.
select into 'nl:'
       loc_nu_disp   = trim(uar_get_code_display(e.loc_nurse_unit_cd), 3)
     , loc_room_disp = trim(uar_get_code_display(e.loc_room_cd)      , 3)
     , loc_bed_disp  = trim(uar_get_code_display(e.loc_bed_cd)       , 3)
  from encounter e
     , person    p
 where e.disch_dt_tm       is null
   and e.loc_nurse_unit_cd in ( 8252317.0   ;GUH C51
                              , 4378637.0   ;GUH C52   ;002 Adding this.
                              , 4378671.0   ;GUH W31
                              , 4385166.0   ;GUH W32
                              )
   and e.active_ind        =  1
 
   and p.person_id         =  e.person_id
order by loc_nu_disp, loc_room_disp, loc_bed_disp
detail
    rdata->cnt = rdata->cnt + 1
 
    if(mod(rdata->cnt, 10) = 1)
        stat = alterlist(rdata->labeldetail, rdata->cnt + 9)
    endif
 
    ;First the important identifiers.
    rdata->labeldetail[rdata->cnt].encntr_id = e.encntr_id
    rdata->labeldetail[rdata->cnt].person_id = p.person_id
 
 
    ;Now whatever encounter/person info we can get our hands on without further querying.
    rdata->labeldetail[rdata->cnt].admit_dt_tm         = format(e.reg_dt_tm, "MM/DD/YY HH:MM")
    rdata->labeldetail[rdata->cnt].med_service         = uar_get_code_display(e.med_service_cd)
    rdata->labeldetail[rdata->cnt].age_disp            = cnvtage(p.birth_dt_tm)
    rdata->labeldetail[rdata->cnt].age_dob_sex         = concat( format(p.birth_dt_tm, "MM/DD/YY;;D")
                                                               , trim(cnvtage(p.birth_dt_tm))
                                                               , "    "
                                                               , substring(1, 1, uar_get_code_display(p.sex_cd))
                                                               )
    rdata->labeldetail[rdata->cnt].name_full_formatted = trim(p.name_full_formatted, 3)
    rdata->labeldetail[rdata->cnt].birth_dt_tm         = format(p.birth_dt_tm, "MM/DD/YY;;D")
    rdata->labeldetail[rdata->cnt].sex                 = substring(1, 1, uar_get_code_display(p.sex_cd))
    rdata->labeldetail[rdata->cnt].location            = trim(uar_get_code_display(e.loc_nurse_unit_cd), 3)
    rdata->labeldetail[rdata->cnt].room                = trim(uar_get_code_display(e.loc_room_cd)      , 3)
    rdata->labeldetail[rdata->cnt].bed                 = trim(uar_get_code_display(e.loc_bed_cd)       , 3)
 
    call echo(build(rdata->labeldetail[rdata->cnt].location, ":"
                   ,rdata->labeldetail[rdata->cnt].room, ":"
                   ,rdata->labeldetail[rdata->cnt].bed))
 
foot report
    stat = alterlist(rdata->labeldetail, rdata->cnt)
with nocounter
 
 
/**********************************************************************
DESCRIPTION:  Find MRN
***********************************************************************/
select into "nl:"
  from person_alias pa
     , (dummyt d with seq = rdata->cnt)
  plan d
   where rdata->cnt                          > 0 ;MAYES NOTE: This was added by me.
     and rdata->labeldetail[d.seq].person_id > 0 ;MAYES NOTE: This was added by me.
  join pa
   where pa.person_id                        = rdata->labeldetail[d.seq].person_id
     and pa.person_alias_type_cd             = 10
     and pa.end_effective_dt_tm              > cnvtdatetime(curdate, curtime3)
     and pa.active_ind                       = 1
detail
    ;MAYES NOTE: This is goofy that they handle this different than FIN.  But WHATEVs
    rdata->labeldetail[d.seq]->mrn_nbr = concat("MRN#: ", trim(pa.alias, 3))
with nocounter
 
 
/**********************************************************************
DESCRIPTION:  Find MRN
***********************************************************************/
select into "nl:"
  from encntr_alias ea
     , (dummyt d with seq = rdata->cnt)
  plan d
   where rdata->cnt                          > 0 ;MAYES NOTE: This was added by me.
     and rdata->labeldetail[d.seq].encntr_id > 0 ;MAYES NOTE: This was added by me.
 
  join ea
   where ea.encntr_id                        = rdata->labeldetail[d.seq].encntr_id
     and ea.encntr_alias_type_cd             = 1077
     and ea.end_effective_dt_tm              > cnvtdatetime(curdate, curtime3)
     and ea.active_ind                       = 1
detail
    rdata->labeldetail[d.seq]->fin_nbr  = trim(ea.alias, 3)
    rdata->labeldetail[d.seq]->fin_disp = concat("FIN#: ", trim(ea.alias, 3))
with nocounter
 
;<--
 
set cvadmit_doc     = uar_get_code_by("MEANING", 333, "ADMITDOC")
set cvattend_doc    = uar_get_code_by("MEANING", 333, "ATTENDDOC")
 
 
;MAYES NOTE: This should work out for us just fine.
select into "nl:"
  from (dummyt d with seq = rdata->cnt) ;MAYES NOTE: This was changed by me.
     , encounter e
     , person p
     , encntr_prsnl_reltn epr1
     , encntr_prsnl_reltn epr2
     , prsnl pr1
     , prsnl pr2
 
  plan d
   where rdata->cnt                          > 0 ;MAYES NOTE: This was added by me.
     and rdata->labeldetail[d.seq].encntr_id > 0 ;MAYES NOTE: This was added by me.
 
  join e
   where e.encntr_id            = rdata->labeldetail[d.seq].encntr_id
 
  join p
   where p.person_id            = e.person_id
 
  join epr1
   where epr1.encntr_id         = outerjoin(e.encntr_id)
     and epr1.encntr_prsnl_r_cd = outerjoin(cvadmit_doc)
 
  join pr1
   where pr1.person_id          = outerjoin(epr1.prsnl_person_id)
 
  join epr2
   where epr2.encntr_id         = outerjoin(e.encntr_id)
     and epr2.encntr_prsnl_r_cd = outerjoin(cvattend_doc)
 
  join pr2
   where pr2.person_id          = outerjoin(epr2.prsnl_person_id)
 
detail
    rdata->labeldetail[d.seq].admit_doc     = pr1.name_full_formatted
    rdata->labeldetail[d.seq].attend_doc    = pr2.name_full_formatted
with counter, time = 300
 
 
execute reportrtl
%i cust_script:6_pat_label_work_around_guh.dvl
 
 
set _sendto = $outdev
call layoutquery(0)
 
call echorecord(rdata)
 
end
go
 
 
 
