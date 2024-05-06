/**************************************************************************
 Program Title:   MDPCP Program Enrollment Component Data

 Object name:     cust_mp_mdpcp_prog_enroll_data
 Source file:     cust_mp_mdpcp_prog_enroll_data.prg

 Purpose:         Gather information for the MDPCP Program Enrollment 
                  component

 Tables read:

 Executed from:   MPage (Advanced Directives Component)

 Special Notes:   Some of this is borrowed from 14_mp_hi_get_risk_api
                  which serves the Program Enrollment component

***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------
001 07/19/2023 Michael Mayes        238981 Initial release 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop   program cust_mp_mdpcp_prog_enroll_data:dba go
create program cust_mp_mdpcp_prog_enroll_data:dba


prompt
    'Output to File/Printer/MINE' = 'MINE'
    , 'Person Id:' = 0.0
    , 'Encntr Id:' = 0.0
    , 'Data Type:' = 0

with outdev, personid, encntrid, datatype


/**************************************************************
; DVDev INCLUDES
**************************************************************/


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record rec
record rec (
    1 per_id             = f8
    1 enc_id             = f8
    1 enc_fac_cd         = f8
    1 enc_fac            = vc
    1 care_first_ind     = i2
    1 cto_ind            = i2
    1 mdpcp_ind          = i2
    1 fc_ind             = i2
    1 care_mgmt_cnt      = i4
    1 care_mgmt[*]
        2 synonym_disp   = vc
        2 synonym_id     = f8
    1 diab_cnt           = i4
    1 diab[*]
        2 synonym_disp   = vc
        2 synonym_id     = f8
    1 empanel_status     = vc
    1 empanel_status_msg = vc
    1 empanel_cnt        = i4
    1 empanel[*]
        2 type           = vc
        2 value          = vc
        2 name           = vc
        2 beg_dt         = vc
    1 attrib_status      = vc
    1 attrib_status_msg  = vc
    1 attrib_prov_cnt    = i4
    1 attrib_prov[*]
        2 name           = vc
        2 user_cnt       = i4
        2 users[*]
            3 alias      = vc
        2 position_cd    = f8
        2 position       = vc
    1 mdpcp
        2 mdpcp_provider = vc
        2 care_man_title = vc
        2 care_manager   = vc
    1 diab_info
        2 a1c_qual_ind   = i2
        2 a1c_res        = vc
        2 a1c_res_dt_tm  = dq8
        2 a1c_res_dt_txt = vc
%i cust_script:mpajax_cust_status.inc
)


free record hi_get_hi_demographics_request
record hi_get_hi_demographics_request(
;%i cclsource:hi_get_person_demogr_req.inc
    1 person_id                    = f8
    1 hi_person_identifier         = vc
    1 demographics_test_uri        = vc
    1 benefit_coverage_source_type = vc
)

free record hi_get_hi_demographics_reply
record hi_get_hi_demographics_reply(
;%i cclsource:hi_get_person_demogr_rep.inc
    1 person_id                         = f8
    1 hi_person_identifier              = vc
    1 given_names[*]
        2 given_name                    = vc
    1 family_names[*]
        2 family_name                   = vc
    1 full_name                         = vc
    1 date_of_birth                     = vc
    1 gender_details
        2 id                            = vc
        2 coding_system_id              = vc
    1 address
        2 street_addresses[*]
            3 street_address            = vc
        2 type
            3 id                        = vc
            3 coding_system_id          = vc
        2 city                          = vc
        2 state_or_province_details
            3 id                        = vc
            3 coding_system_id          = vc
        2 postal_code                   = vc
        2 county_or_parish              = vc
        2 county_or_parish_details
            3 id                        = vc
            3 coding_system_id          = vc
        2 country_details
            3 id                        = vc
            3 coding_system_id          = vc
    1 telecoms[*]
        2 preferred                     = vc
        2 number                        = vc
        2 country_code                  = vc
        2 type
            3 id                        = vc
            3 coding_system_id          = vc
            3 display                   = vc
    1 email_addresses[*]
        2 address                       = vc
        2 type
            3 id                        = vc
            3 coding_system_id          = vc
    1 health_plans[*]
        2 mill_health_plan_id           = f8
        2 payer_name                    = vc
        2 plan_name                     = vc
        2 begin_iso_dt_tm               = vc
        2 end_iso_dt_tm                 = vc
        2 member_nbr                    = vc
        2 line_of_business              = vc
        2 source
            3 contributing_organization = vc
            3 partition_description     = vc
            3 type                      = vc
        2 plan_identifiers[*]
            3 value                     = vc
            3 type                      = vc
%i cclsource:status_block.inc
)


free record person_demogr_reply
record person_demogr_reply
(
;%i cclsource:hi_proxy_reply_common.inc
  1 transactionStatus
    2 successInd = ui1
    2 debugErrorMessage = vc
    2 prereqErrorInd = ui1
  1 httpReply
    2 version = vc
    2 status = ui2
    2 statusReason = vc
    2 httpHeaders[*]
      3 name = vc
      3 value = vc
    2 body = gvc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare cnvtisodttmtodq8(p1 = vc) = dq8 with protect

/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare current_date_time     = dq8 with protect,   constant(cnvtdatetime(curdate, curtime3))

declare reply_txt             = vc  with protect, noconstant('')

declare looper                = i4  with protect, noconstant(0)
declare looper2               = i4  with protect, noconstant(0)
declare pos                   = i4  with protect, noconstant(0)

declare at_risk_plan_mnemonic = vc  with protect,   constant("HEALTHEINTENT") ;empanelment

declare mdpcp_cd              = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 331, 'MDPCPPROVIDER'))
declare cto_no_heart_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 331, 'CTOCAREMANAGERNONHEART'))
declare cto_heart_cd          = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 331, 'CTOCAREMANAGERHEARTPATIENT'))

declare act_cd                = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'ACTIVE'))
declare mod_cd                = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'MODIFIED'))
declare auth_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'AUTH'))
declare altr_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'ALTERED'))
                              
declare h1c_cd                = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HGBA1C'                   ))
declare h1cglyco_cd           = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HGBA1CGLYCOSYLATED'       ))
declare poc_h1c_cd            = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'POCHGBA1C'                ))
declare h1c_trans_cd          = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'HEMOGLOBINA1CTRANSCRIBED' ))

declare result                = f8
declare result_txt            = vc

declare plan_name             = vc 
declare plan_beg_iso_dt_tm    = vc 
declare plan_end_iso_dt_tm    = vc
declare ident_cnt             = i4 
declare plan_type             = vc
declare plan_value            = vc

declare attrib_obj            = vc

declare enc_fac_cd            = f8  with protect, noconstant(0.0)

/**************************************************************
; DVDev Start Coding
**************************************************************/
set rec->per_id = $personid
set rec->enc_id = $encntrid


/***********************************************************************
DESCRIPTION:  Find encounter facility
      NOTES:  This is going to be used in a synonym virtual view check
              in a bit.
***********************************************************************/
select into 'nl:'
  
  from encounter e
 
 where encntr_id = rec->enc_id

detail
    rec->enc_fac_cd = e.loc_facility_cd
    rec->enc_fac    = uar_get_code_display(e.loc_facility_cd)
    
with nocounter


set hi_get_hi_demographics_request->person_id             = rec->per_id
set hi_get_hi_demographics_request->demographics_test_uri = ''

execute 14_mp_get_person_demogr with replace("REQUEST", hi_get_hi_demographics_request)
                                   , replace("REPLY"  , hi_get_hi_demographics_reply)

;execute mmmtest with replace("REQUEST", hi_get_hi_demographics_request)
;                                   , replace("REPLY"  , hi_get_hi_demographics_reply)

call echorecord(hi_get_hi_demographics_reply)

if(hi_get_hi_demographics_reply->status_data->status = 'S')
    for(looper = 1 to size(hi_get_hi_demographics_reply->health_plans, 5))
        set plan_name          = hi_get_hi_demographics_reply->health_plans[looper]->plan_name
        set plan_beg_iso_dt_tm = hi_get_hi_demographics_reply->health_plans[looper]->begin_iso_dt_tm
        set plan_end_iso_dt_tm = hi_get_hi_demographics_reply->health_plans[looper]->end_iso_dt_tm

        set  ident_cnt         = size(hi_get_hi_demographics_reply->health_plans[looper]->plan_identifiers, 5)

        ;active health plans only.
        if(textlen(plan_end_iso_dt_tm) = 0 or cnvtisodttmtodq8(plan_end_iso_dt_tm) > current_date_time)
            set plan_beg_iso_dt_tm = substring(1, 10, plan_beg_iso_dt_tm)
            
            ;call echorecord(hi_get_hi_demographics_reply->health_plans[looper])
            
            for(looper2 = 1 to ident_cnt)
                set plan_type      = hi_get_hi_demographics_reply->health_plans[looper]->plan_identifiers[looper2]->type
                set plan_value     = hi_get_hi_demographics_reply->health_plans[looper]->plan_identifiers[looper2]->value
            
                if(    plan_type  =  at_risk_plan_mnemonic
                   ;and plan_value != 'MDPCP'
                  )  ;Might want to filter out MDPCP here.  plan_value != 'MDPCP'
                    set rec->empanel_cnt = rec->empanel_cnt + 1
                    
                    set stat = alterlist(rec->empanel, rec->empanel_cnt)
                    
                    set rec->empanel[rec->empanel_cnt]->type   = plan_type
                    set rec->empanel[rec->empanel_cnt]->value  = plan_value
                    set rec->empanel[rec->empanel_cnt]->name   = plan_name
                    set rec->empanel[rec->empanel_cnt]->beg_dt = plan_beg_iso_dt_tm
                    
                    ;call echorecord(hi_get_hi_demographics_reply->health_plans[looper])
                    
                endif
            endfor       
        endif
    endfor
    
    set rec->empanel_status     = hi_get_hi_demographics_reply->status_data->status
    set rec->empanel_status_msg = hi_get_hi_demographics_reply->status_data->subeventstatus[1]->targetobjectvalue
else
    set rec->empanel_status     = hi_get_hi_demographics_reply->status_data->status
    set rec->empanel_status_msg = hi_get_hi_demographics_reply->status_data->subeventstatus[1]->targetobjectvalue
endif


;Trying for the Attributed Provider now:
declare HI_EMPI_LOOKUP_KEY = vc with protect, constant("hi_record_person_empi_lookup")
declare PERSON_DEMOGRAPHICS_REQUEST_KEY = vc with protect, constant("hi_record_api_person_demographics")

execute hi_alias_lookup "MINE", HI_EMPI_LOOKUP_KEY, PERSON_DEMOGRAPHICS_REQUEST_KEY, rec->per_id

;call echorecord(aliasLookupReply)

;This avoids an error on the frontend while we work out the below:
set rec->attrib_status     = '1'

;This is temp removed... no attributed providers while they await some HealtheIntent changes.
;if (aliasLookupReply->status_data->status = "S")
;    ;Okie Dokie... I have no idea how the URL is generated, but the hi_alias_lookup will build it, with the 
;    ;population UID, and the person UID... and testing on my end says this will work when I flip over to 
;    ;healtheregistries from healtherecords... so... I'm letting the above do all that work for me, then
;    ;I have to manhandle the URL to actually get what I need.
;    
;    call echo(aliasLookupReply->hiUri)
;    
;    set aliasLookupReply->hiUri = replace( aliasLookupReply->hiUri
;                                         , 'https://medstarhealth.record.healtheintent.com/api/populations/'
;                                         , 'https://medstarhealth.registries.healtheintent.com/api/populations/'
;                                         )
;    
;    ;This thing has a data partition in it now... joy.  Looks like I have to yank that off.
;    set pos = findstring('?', aliasLookupReply->hiUri)
;    
;    if(pos > 0) set aliasLookupReply->hiUri = substring(1, pos - 1, aliasLookupReply->hiUri)
;    endif
;    
;    call echo(aliasLookupReply->hiUri)
;    
;    ;set aliasLookupReply->hiUri = replace( aliasLookupReply->hiUri
;    ;                                     , 'people/'
;    ;                                     , 'people/1'
;    ;                                     )
;    
;    set aliasLookupReply->hiUri = build2(aliasLookupReply->hiUri, '/provider_relationships/')
;    
;    call echo(aliasLookupReply->hiUri)
;    
;    ;call echorecord(aliasLookupReply)
;    
;    ;That should be our URL
;    execute hi_http_proxy_get_request "MINE", aliasLookupReply->hiUri, "JSON"
;            with replace("PROXYREPLY", person_demogr_reply)
;    
;    ;call echorecord(person_demogr_reply)
;
;    if(person_demogr_reply->transactionStatus->successInd = 1)
;        
;        ;call echorecord(person_demogr_reply)
;        
;        set attrib_obj = concat('{"attrib":{"prov":', person_demogr_reply->httpReply->body, '}}')
;        
;        ;call echo(findstring('Unable to locate the specified resource.', person_demogr_reply->httpReply->body))
;        ;call echo(findstring('The page you are attempting to access does not exist.', person_demogr_reply->httpReply->body))
;        
;        if(    findstring('Unable to locate the specified resource.'             , person_demogr_reply->httpReply->body) = 0
;           and findstring('The page you are attempting to access does not exist.', person_demogr_reply->httpReply->body) = 0)
;           
;            ;call echo('got in')
;        
;            set stat = cnvtjsontorec(attrib_obj)
;            
;            ;call echorecord(rec)
;            
;            ;call echojson(attrib)
;            
;            for(looper = 1 to size(attrib->prov, 5))
;                set rec->attrib_prov_cnt = rec->attrib_prov_cnt + 1
;                
;                set stat = alterlist(rec->attrib_prov, rec->attrib_prov_cnt)
;                
;                set rec->attrib_prov[rec->attrib_prov_cnt]->name = attrib->prov[looper].name
;                
;                for(looper2 = 1 to size(attrib->prov[looper]->aliases, 5))
;                    if(attrib->prov[looper]->aliases[looper2]->alias_type = 'USER')
;                        set pos                                              = rec->attrib_prov[rec->attrib_prov_cnt]->user_cnt  + 1
;                        set rec->attrib_prov[rec->attrib_prov_cnt]->user_cnt = pos
;                
;                        set stat = alterlist(rec->attrib_prov[rec->attrib_prov_cnt]->users, pos)
;                        
;                        set rec->attrib_prov[rec->attrib_prov_cnt]->users[pos]->alias = 
;                                                                                    attrib->prov[looper]->aliases[looper2]->alias_id
;                        
;                    endif
;                endfor
;                
;                /**********************************************************************
;                DESCRIPTION:  Find Care Mgmt Orders
;                      Notes:  I can't tell the username from the person_id... so just 
;                              hitting prsnl with both.  Only one should work.
;                ***********************************************************************/
;                select into 'nl:'
;                  
;                  from prsnl p
;                     , (dummyt d with seq = rec->attrib_prov[rec->attrib_prov_cnt]->user_cnt)
;                  
;                  plan d
;                   where rec->attrib_prov[rec->attrib_prov_cnt]->user_cnt            > 0
;                     and rec->attrib_prov[rec->attrib_prov_cnt]->users[d.seq]->alias > ' '
;
;                  join p
;                   where p.username            = rec->attrib_prov[rec->attrib_prov_cnt]->users[d.seq]->alias
;                     and p.active_ind          = 1
;                     and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
;                
;                detail
;                    rec->attrib_prov[rec->attrib_prov_cnt]->position_cd = p.position_cd
;                    rec->attrib_prov[rec->attrib_prov_cnt]->position    = trim(uar_get_code_display(p.position_cd), 3)
;                with nocounter
;                
;            endfor
;            
;            set rec->attrib_status     = cnvtstring(person_demogr_reply->transactionStatus->successInd)
;            set rec->attrib_status_msg = person_demogr_reply->transactionStatus->debugErrorMessage
;        
;        else
;            set rec->attrib_status     = '0'
;            set rec->attrib_status_msg = 'Unable to locate the specified resource.'
;        endif
;
;    else
;        set rec->attrib_status     = cnvtstring(person_demogr_reply->transactionStatus->successInd)
;        set rec->attrib_status_msg = 'Error while calling HealtheIntent API for attributed providers.'
;    endif
;else
;    set rec->attrib_status     = aliasLookupReply->status_data->status
;    set rec->attrib_status_msg = aliasLookupReply->status_data->subeventstatus[1]->targetobjectvalue
;    
;endif


;Time for some MDPCP stuff
/***********************************************************************
DESCRIPTION:  Retrieve MDPCP relationships
***********************************************************************/
select into 'nl:'
  from person_prsnl_reltn ppr  ;mdpcp
     , prsnl              p
 
 where ppr.person_id           =  $personid
   and ppr.person_prsnl_r_cd   in (mdpcp_cd, cto_no_heart_cd, cto_heart_cd)
   and ppr.active_ind          =  1
   and ppr.end_effective_dt_tm >  cnvtdatetime(curdate, curtime3)
   
   and p.person_id             =  ppr.prsnl_person_id

order by ppr.person_prsnl_r_cd, ppr.beg_effective_dt_tm desc

head ppr.person_prsnl_r_cd
    rec->mdpcp_ind = 1
    
    case(ppr.person_prsnl_r_cd)
    ;This is temp removed... no attributed providers while they await some HealtheIntent changes.
    ;of mdpcp_cd       :  rec->mdpcp->mdpcp_provider = trim(p.name_full_formatted                , 3)
    of cto_no_heart_cd:  rec->mdpcp->care_manager   = trim(p.name_full_formatted                , 3)
                         rec->mdpcp->care_man_title = trim(uar_get_code_display(cto_no_heart_cd), 3)
    of cto_heart_cd   :  rec->mdpcp->care_manager   = trim(p.name_full_formatted                , 3)
                         rec->mdpcp->care_man_title = trim(uar_get_code_display(cto_heart_cd)   , 3)
    endcase

with nocounter


/***********************************************************************
DESCRIPTION:  Retrieve Latest A1C
      NOTES:  This conditionally shows some stuff on the frontend if in range.
***********************************************************************/
select into 'nl:'

  from clinical_event ce
  
   where ce.person_id            =  rec->per_id
     and ce.result_status_cd     in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.valid_until_dt_tm    >  cnvtdatetime(curdate,curtime3)
     and ce.result_val           >= ' '
     and ce.event_class_cd       =  233.00  ;NUM
     and ce.event_cd             in ( h1c_cd
                                    , h1cglyco_cd
                                    , poc_h1c_cd
                                    , h1c_trans_cd
                                    )
     
order by ce.person_id, ce.event_end_dt_tm desc

head ce.person_id

    result     = cnvtreal(ce.result_val)
    
    ;I don't think these usually have the %.  But rather than blindly adding, I'm going to remove it if it is there then add.
    result_txt = replace(ce.result_val, "%", '')
    result_txt = concat(result_txt, ' %')
    
    
    if(cnvtreal(ce.result_val) >= 8.0) rec->diab_info->a1c_qual_ind = 1
    endif
    
    rec->diab_info->a1c_res        = trim(result_txt, 3)
    rec->diab_info->a1c_res_dt_tm  = ce.event_end_dt_tm
    rec->diab_info->a1c_res_dt_txt = format(ce.event_end_dt_tm, '@SHORTDATE')
    
with nocounter


;We are going to loop the empanelments to try and find our plans that drive conditional referrals.
for(looper = 1 to rec->empanel_cnt)
    if(   cnvtupper(rec->empanel[looper]->name ) = 'CAREFIRST*'
       or cnvtupper(rec->empanel[looper]->value) = 'CAREFIRST*'
      )
        set rec->care_first_ind = 1
    
    elseif(   cnvtupper(rec->empanel[looper]->name ) = 'MEDSTAR*SELECT*'
           or cnvtupper(rec->empanel[looper]->value) = 'MEDSTAR*SELECT*'
           or cnvtupper(rec->empanel[looper]->value) = 'AETNA*'
           or cnvtupper(rec->empanel[looper]->name ) = 'CIGNA*'
           or cnvtupper(rec->empanel[looper]->value) = 'CIGNA*'
          )
        set rec->cto_ind = 1
    elseif(   cnvtupper(rec->empanel[looper]->name ) = 'MFC*'
           or cnvtupper(rec->empanel[looper]->value) = 'MEDSTARFAMILYCHOICE*')
        set rec->fc_ind = 1
    endif
    
endfor



/**********************************************************************
DESCRIPTION:  Find Plan Conditional Orders
***********************************************************************/
select into 'nl:'
  from order_catalog         oc
     , order_catalog_synonym ocs
     , ocs_facility_r        ofr
 where oc.description  in ( 'Referral to MedStar CareFirst Care Manager'
                          , 'Referral to MedStar CareFirst Behavioral Health Care Manager'
                          
                          , 'Referral to CTO Care Coordination'
                             
                          , 'Referral to MedStar MDPCP Care Coordinator/Case Manager'
                          , 'Referral to MedStar MDPCP Social Needs Team'
                          
                          , 'Referral to MedStar Family Choice Care Coordinator/Case Manager'
                          
                          , 'Referral to MedStar Diabetes Pathway/Bootcamp'
                                                   
                          )
   and oc.active_ind   =  1

   and ocs.catalog_cd  =  oc.catalog_cd
   and ocs.active_ind  =  1
   
   and ofr.synonym_id  =  ocs.synonym_id
   and (   ofr.facility_cd = rec->enc_fac_cd
        or ofr.facility_cd = 0               ;All facs
       )
order by oc.description
detail
    case(oc.description)
    of 'Referral to MedStar CareFirst Care Manager':
    of 'Referral to MedStar CareFirst Behavioral Health Care Manager':
        if(rec->care_first_ind = 1)
            rec->care_mgmt_cnt = rec->care_mgmt_cnt + 1
            stat = alterlist(rec->care_mgmt, rec->care_mgmt_cnt)
            
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_disp = trim(ocs.mnemonic, 3)
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_id   = ocs.synonym_id
        endif
        
    of 'Referral to CTO Care Coordination':
        if(rec->cto_ind = 1)
            rec->care_mgmt_cnt = rec->care_mgmt_cnt + 1
            stat = alterlist(rec->care_mgmt, rec->care_mgmt_cnt)
            
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_disp = trim(ocs.mnemonic, 3)
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_id   = ocs.synonym_id
        endif
        
    
    of 'Referral to MedStar MDPCP Care Coordinator/Case Manager':
    of 'Referral to MedStar MDPCP Social Needs Team'            :
        if(rec->mdpcp_ind = 1)
            rec->care_mgmt_cnt = rec->care_mgmt_cnt + 1
            stat = alterlist(rec->care_mgmt, rec->care_mgmt_cnt)
            
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_disp = trim(ocs.mnemonic, 3)
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_id   = ocs.synonym_id
        endif
        
    of 'Referral to MedStar Family Choice Care Coordinator/Case Manager':
        if(rec->fc_ind = 1)
            rec->care_mgmt_cnt = rec->care_mgmt_cnt + 1
            stat = alterlist(rec->care_mgmt, rec->care_mgmt_cnt)
            
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_disp = trim(ocs.mnemonic, 3)
            rec->care_mgmt[rec->care_mgmt_cnt]->synonym_id   = ocs.synonym_id
        endif
    
    
    of 'Referral to MedStar Diabetes Pathway/Bootcamp':
        rec->diab_cnt = rec->diab_cnt + 1
        stat = alterlist(rec->diab, rec->diab_cnt)
        
        rec->diab[rec->diab_cnt]->synonym_disp = trim(ocs.mnemonic, 3)
        rec->diab[rec->diab_cnt]->synonym_id   = ocs.synonym_id
    
    endcase

    
with nocounter




/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
/**
 * cnvtisodttmtodq8()
 * Purpose:
 *   Converts an ISO 8601 formatted date into a DQ8
 *
 * @return {dq8, which is the same as a f8}
 *
 * @param {vc} isoDtTmStr ISO 8601 formatted string (ie, 2013-10-24T15:08:77Z)
*/
subroutine cnvtisodttmtodq8(isoDtTmStr)
	declare convertedDq8 = dq8 with protect, noconstant(0)
 
	set convertedDq8 = cnvtdatetimeutc2( substring(1, 10, isoDtTmStr), "YYYY-MM-DD"
                                       , substring(12, 8, isoDtTmStr), "HH:MM:SS"
                                       , 4, CURTIMEZONEDEF)
 
	return(convertedDq8)
 
end  ;subroutine cnvtisodttmtodq8


#exit_script

; send back recordset data as JSON or XML
if (cnvtint($datatype) = 0)
    call echojson(rec) ;for debugging
    set reply_txt            = cnvtrectojson(rec)
    set _MEMORY_REPLY_STRING = reply_txt
else
    call echoxml(rec) ;for debugging
    set reply_txt            = cnvtrectoxml(rec)
    set _MEMORY_REPLY_STRING = reply_txt
endif

end
go
