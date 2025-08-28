/*********************************************************************************************************************************
 Object name:       14_token_pat_letter
 Source file:       14_token_pat_letter.prg
 Purpose:           Display Patient Letter for urgent care patients
 Executed from:     PowerChart Depart Process Tab
 Programs Executed: N/A
 Special Notes:     N/A


**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
 Mod  Date        Analyst               OPAS              Comment
 ---  ----------  --------------------  ------            -------------------------------------------------------------------------
 001  09/13/2021  Simeon Akinsulie      MCGA228956        Initial
 002  5/30/2024   Kim Frazier           SCTASK0092640     Alternate text for eVisit locations
 003  10/30/2024
 004  08/27/2025  Michael Mayes         352465            Removing header, as it is superfluous in the AVS, and doesn't seem used
                                                          in depart according to Starky.
*********************************END OF ALL MODCONTROL BLOCKS********************************************************************/
drop program 14_token_pat_letter go
create program  14_token_pat_letter


 /****************************************************************************************************
                                    Variable Declarations
*****************************************************************************************************/
declare csText = vc
declare csHeader = vc
declare patient_id = vc ;with noconstant("PatientID - Your unique patient ID appears on page one of this document")
set csHeader = concat("<html><body></body></html>")
set csText = csHeader

declare bus_ph_cd = f8 with protect, constant(uar_get_code_by("MEANING", 43, "BUSINESS"))
declare fax_ph_cd = f8 with protect, constant(uar_get_code_by("MEANING", 43, "FAX ALT"))
declare fax_bus_ph_cd = f8 with protect, constant(uar_get_code_by("MEANING", 43, "FAX BUS"))
declare usual_add_cd = f8 with protect, constant(uar_get_code_by("MEANING", 212, "USUAL"))
declare usual_ph_cd = f8 with protect, constant(uar_get_code_by("MEANING", 43, "USUAL"))

;set csText = concat(csText, "<p style='font-size:12.0pt;font-family:Arial'>")
/****************************************************************************************************
                                See if Patient Has an EMPI
*****************************************************************************************************/
record rep(
    1 e_is_uc = c1
    1 e_address1 = vc
    1 e_address2 = vc
    1 e_city = vc
    1 e_zipcode = vc
    1 e_state = vc
    1 pat_name = vc
    1 e_date = vc
    1 e_loc_name = vc
    1 e_loc_id = f8
    1 business_ph = vc
)

select into "nl:"
    facility = cnvtlower(trim(uar_get_code_display(e.loc_facility_cd),3)),
    p.name_full_formatted,e.reg_dt_tm,
    a.street_addr
from encounter e,
    person p,
    address a
plan e
    WHERE e.encntr_id = request->encntr_id ;203510851.00
    and e.loc_facility_cd in (SELECT CV1.CODE_VALUE
                             FROM CODE_VALUE CV1
                            WHERE CV1.CODE_SET = 220 AND CV1.ACTIVE_IND = 1
                            ;and cv1.code_value =   2540098069.00
                            and (cnvtlower(cv1.display) = 'medstar health uc*'
                            or cnvtlower(cv1.display) = 'medstar health urgent*'
                            or cnvtlower(cv1.display) = 'medstar hlth urgent*'
                            or cnvtlower(cv1.display) = '*medstar uc*'
                            or cnvtlower(cv1.display) = 'medstar urgent care*'
                            or cnvtlower(cv1.display) = '*mmg evisit on demand*'
                            or cnvtlower(cv1.display) = 'medstar health evisit*') ;002 )
                            and cv1.cdf_meaning = 'FACILITY')
join p
    where p.person_id = e.person_id
join a where a.parent_entity_id = e.organization_id
  and a.address_type_cd = 754
  and a.parent_entity_name = 'ORGANIZATION'
  and a.active_ind = 1
  and a.beg_effective_dt_tm < sysdate
  and a.end_effective_dt_tm > sysdate
detail
    rep->e_is_uc = "y"
    if( facility like 'medstar health evisit*')
        rep->e_is_uc = "e"
    endif
  if(e.loc_facility_cd = 5475587827.00)
    rep->e_is_uc = "e"
    rep->e_loc_name = "MedStar Health eVisit Telehealth"
  else
    rep->e_loc_name = trim(uar_get_code_description(e.loc_facility_cd),3)
  endif
    rep->pat_name = build2(trim(p.name_first_key,3)," ",trim(p.name_last_key,3))
    rep->e_loc_id = e.organization_id
    ;trim(p.name_full_formatted,3)
    rep->e_date = format(e.reg_dt_tm, "mm/dd/yyyy")
    rep->e_address1 = a.street_addr
    rep->e_address2 = a.street_addr2
    rep->e_zipcode = a.zipcode
    rep->e_city = trim(a.city,3)
    if (a.state = NULL)
        rep->e_state = trim(uar_get_code_display(a.state_cd),3)
    else
        rep->e_state = trim(a.state,3)
    endif
with nocounter
;002 if(rep->e_is_uc = "y")
if(rep->e_loc_id > 0)
    if(rep->e_is_uc != " ");002
        select into "nl:"
        from phone p
            where p.parent_entity_id = rep->e_loc_id
            and p.parent_entity_name = "ORGANIZATION"
            and p.phone_type_cd in (usual_ph_cd, bus_ph_cd)
            and p.active_ind = 1
          order by p.active_status_dt_tm
          head report
            usual_ph_flag = 0
          detail
            if (p.phone_type_cd = usual_ph_cd)
             rep->business_ph = p.phone_num_key
             usual_ph_flag = 1
            elseif (p.phone_type_cd = bus_ph_cd AND usual_ph_flag = 0)
             rep->business_ph = cnvtphone(p.phone_num_key,0)
            endif
          with nocounter
    endif

;8888086483
/****************************************************************************************************
                                 Format the Reply HTML style='font-size:16pt;font-weight:bold;text-align:center'
*****************************************************************************************************/
    if(rep->e_is_uc = "y");002 added to separate from eVisit
        set csText = build2("<html><body>",
        ;004-> Removing this.
        ;"<span style='font-weight: bold; font-size: 15pt; border-bottom: 1px solid #999'>Work School Materials</span><br><br>",
        ;004<-
        "<p><b>",trim(rep->e_loc_name,3),"</b><br>",trim(rep->e_address1,3),"<br>",
        trim(rep->e_city,3)," ",trim(rep->e_state,3),", ",trim(rep->e_zipcode,3),"<br>",rep->business_ph,"<br><br><br>",
        "To Whom It May Concern,<br><br>",trim(rep->pat_name,3)," was seen at ",trim(rep->e_loc_name)," on ",
        trim(rep->e_date,3),". Please excuse from work and/or school on ",trim(rep->e_date,3),".<br><br>If you feel that you need ",
        "additional days off due to illness, you will need to contact and follow-up with another clinician as noted in your ",
        "discharge instructions. The Urgent Care staff does NOT determine total disability due to injury.<br><br></p></body></html>")
    elseif(rep->e_is_uc = "e") ;002 an evisit test
        set csText = build2("<html><body>",
        ;004-> Removing this.
        ;"<span style='font-weight: bold; font-size: 15pt; border-bottom: 1px solid #999'>Work School Materials</span><br><br>",
        ;004<-
        "<p><b>",trim(rep->e_loc_name,3),"</b><br>",rep->business_ph,"<br><br><br><br>",
        "To Whom It May Concern,<br><br>",trim(rep->pat_name,3)," was seen at ",trim(rep->e_loc_name)," on ",
        trim(rep->e_date,3),". Please excuse from work and/or school on ",trim(rep->e_date,3),".<br><br>If you need ",
        "additional days off due to illness, please follow-up with your primary care provider and/or engage with ",
        "eVisit for a re-evaluation.<br><br></p></body></html>")
    endif
;else
;   set csText = "<html><body><p><b>Patient Not found</p></body></html>"
endif
;set csText = build2("<html><body><p><b>",trim(rep->e_loc_name,3),"</b><br>",trim(rep->e_address1,3),"<br>",
;   trim(rep->e_city,3)," ",trim(rep->e_state,3)," ",trim(rep->e_zipcode,3),"<br><br><br>",
;   "<b>TO WHOM IT MAY CONCERN</b><br><br>",trim(rep->pat_name,3)," was seen in MedStar Health Urgent Care on ",
;   trim(rep->e_date,3),". Please excuse from work and/or school on ",trim(rep->e_date,3),"<br><br><br>",
;   "Thanks_______________________________________</p></body></html>")

/****************************************************************************************************
                                 Final Formatting
*****************************************************************************************************/
;set csText = build2(csText, "</p></body></html>")
call echo(csText)
set reply->text = csText ; "<html><body><p>simeon testing</p></body></html>";csText
set reply->format = 1

;set _MEMORY_REPLY_STRING = csText
;select into $OUTDEV
;csText
;from dummyt
;with nocounter
/****************************************************************************************************
                                    End of Program
*****************************************************************************************************/
end
go
