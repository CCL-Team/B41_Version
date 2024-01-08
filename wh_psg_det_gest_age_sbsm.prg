/*************************************************************************
 Program Title:   SBSM EGA and EDD
 
 Object name:     wh_psg_det_gest_age_sbsm
 Source file:     wh_psg_det_gest_age_sbsm.prg
 
 Purpose:         For a new SBSM office clinic note, it was desired to make
                  changes to a Cerner built ST called wh_psg_det_gest_age.
                  
                  Basically the only change involved here is that when a 
                  section of the ST (data elements under EGA and EDD) is 
                  missing documentation, instead of showing the line with
                  -- as the data, we will supress the line.
 
 Tables read:
 
 Executed from:
 
 Special Notes:   wh_psg_det_gest_age was the script that was translated
                  in order to complete this work.
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2023-10-12 Michael Mayes        234863 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  DROP PROGRAM wh_psg_det_gest_age_sbsm:dba GO
CREATE PROGRAM wh_psg_det_gest_age_sbsm:dba

IF ( NOT (validate(rhead,0)))
    SET rhead                = "{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss Arial;}}"
    SET rhead_colors1        = "{\colortbl;\red0\green0\blue0;\red255\green255\blue255;"
    SET rhead_colors2        = "\red99\green99\blue99;\red22\green107\blue178;"
    SET rhead_colors3        = "\red0\green0\blue255;\red123\green193\blue67;\red255\green0\blue0;}"
    SET reol                 = "\par "
    SET rtab                 = "\tab "
    SET wr                   = "\plain \f0 \fs16 \cb2 "
    SET wr11                 = "\plain \f0 \fs11 \cb2 "
    SET wr18                 = "\plain \f0 \fs18 \cb2 "
    SET wr20                 = "\plain \f0 \fs20 \cb2 "
    SET wu                   = "\plain \f0 \fs16 \ul \cb2 "
    SET wb                   = "\plain \f0 \fs16 \b \cb2 "
    SET wbu                  = "\plain \f0 \fs16 \b \ul \cb2 "
    SET wi                   = "\plain \f0 \fs16 \i \cb2 "
    SET ws                   = "\plain \f0 \fs16 \strike \cb2"
    SET wb2                  = "\plain \f0 \fs18 \b \cb2 "
    SET wb18                 = "\plain \f0 \fs18 \b \cb2 "
    SET wb20                 = "\plain \f0 \fs20 \b \cb2 "
    SET rsechead             = "\plain \f0 \fs28 \b \ul \cb2 "
    SET rsubsechead          = "\plain \f0 \fs22 \b \cb2 "
    SET rsecline             = "\plain \f0 \fs20 \b \cb2 "
    SET hi                   = "\pard\fi-2340\li2340 "
    SET rtfeof               = "}"
    SET wbuf26               = "\plain \f0 \fs26 \b \ul \cb2 "
    SET wbuf30               = "\plain \f0 \fs30 \b \ul \cb2 "
    SET rpard                = "\pard "
    SET rtitle               = "\plain \f0 \fs36 \b \cb2 "
    SET rpatname             = "\plain \f0 \fs38 \b \cb2 "
    SET rtabstop1            = "\tx300"
    SET rtabstopnd           = "\tx400"
    SET wsd                  = "\plain \f0 \fs13 \cb2 "
    SET wsb                  = "\plain \f0 \fs13 \b \cb2 "
    SET wrs                  = "\plain \f0 \fs14 \cb2 "
    SET wbs                  = "\plain \f0 \fs14 \b \cb2 "
    DECLARE snot_documented  = vc WITH public, constant("--")
    SET color0               = "\cf0 "
    SET colorgrey            = "\cf3 "
    SET colornavy            = "\cf4 "
    SET colorblue            = "\cf5 "
    SET colorgreen           = "\cf6 "
    SET colorred             = "\cf7 "
    SET row_start            = "\trowd"
    SET row_end              = "\row"
    SET cell_start           = "\intbl "
    SET cell_end             = "\cell"
    SET cell_text_center     = "\qc "
    SET cell_text_left       = "\ql "
    SET cell_border_top      = "\clbrdrt\brdrt\brdrw1"
    SET cell_border_left     = "\clbrdrl\brdrl\brdrw1"
    SET cell_border_bottom   = "\clbrdrb\brdrb\brdrw1"
    SET cell_border_right    = "\clbrdrr\brdrr\brdrw1"
    SET cell_border_top_left = "\clbrdrt\brdrt\brdrw1\clbrdrl\brdrl\brdrw1"
    SET block_start          = "{"
    SET block_end            = "}"
ENDIF


DECLARE whorgsecpref        = i2 WITH protect, noconstant(0)
DECLARE prsnl_override_flag = i2 WITH protect, noconstant(0)


IF ( NOT (validate(preg_org_sec_ind)))
    DECLARE preg_org_sec_ind = i4 WITH noconstant(0), public
ENDIF

DECLARE os_idx = i4 WITH noconstant(0)


IF ( NOT (validate(encntr_list)))
    FREE RECORD encntr_list
    RECORD encntr_list(
        1 cnt       = i4
        1 qual[*]
            2 value = f8
    )
ENDIF


DECLARE en_idx = i4 WITH public, noconstant(0)


IF (validate(antepartum_run_ind)=0)
    DECLARE antepartum_run_ind = i4 WITH public, noconstant(0)
ENDIF

IF ( NOT (validate(whsecuritydisclaim)))
    DECLARE whsecuritydisclaim = vc WITH public, constant(uar_i18ngetmessage(i18nhandle,"cap99",
                                                        "(Report contains only data from encounters at associated organizations)"))
ENDIF

IF ( NOT (validate(whcaosecuritydisclaim)))
    DECLARE whcaosecuritydisclaim = vc WITH public, constant(uar_i18ngetmessage(i18nhandle,"cap199",
                                         "(Report contains only data from encounters at associated organizations and care units)"))
ENDIF

IF ( NOT (validate(preg_sec_orgs)))
    FREE RECORD preg_sec_orgs
    RECORD preg_sec_orgs(
        1 qual[*]
            2 org_id = f8
            2 confid_level = i4
    )
ENDIF

DECLARE getpersonneloverride(person_id=f8(val),prsnl_id=f8(val))    = i2 WITH protect
DECLARE getpreferences()                                            = i2 WITH protect
DECLARE getorgsecurity()                                            = null WITH protect
DECLARE loadorganizationsecuritylist()                              = null
DECLARE loadencounterlistforcao(person_id=f8(val),cao_flag=i2(ref)) = null

IF (((    validate(honor_org_security_flag)=0) 
      OR (validate(chart_access_flag)=0)) )
     DECLARE honor_org_security_flag = i2 WITH public, noconstant(0)
     DECLARE chart_access_flag       = i2 WITH public, noconstant(0)
 
    SET whorgsecpref = getpreferences(null)
 
    CALL getorgsecurity(null)
 
    SET prsnl_override_flag = getpersonneloverride(request->person[1].person_id,reqinfo->updt_id)
    IF (    preg_org_sec_ind= 1
        AND whorgsecpref    = 1)
        
        CALL loadencounterlistforcao(request->person[1].person_id,chart_access_flag)
  
        IF (((chart_access_flag=1) OR (prsnl_override_flag=0)) )
            SET honor_org_security_flag = 1
        ENDIF
    ENDIF

ELSEIF ((encntr_list->cnt=0))
    CALL loadencounterlistforcao(request->person[1].person_id,chart_access_flag)
ENDIF


SUBROUTINE getpersonneloverride(person_id,prsnl_id)
    CALL echo(build("person_id=",person_id))
    CALL echo(build("prsnl_id=",prsnl_id))
    
    DECLARE override_ind = i2 WITH protect, noconstant(0)
    
    IF (((person_id <= 0.0) OR (prsnl_id <= 0.0)) )
        RETURN(0)
    ENDIF
  
    SELECT INTO "nl:"
      
      FROM person_prsnl_reltn ppr,
           code_value_extension cve
   
      PLAN (ppr
       WHERE ppr.prsnl_person_id=prsnl_id
         AND ppr.active_ind=1
         AND ((ppr.person_id+ 0)=person_id)
         AND ppr.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
         AND ppr.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
    
      JOIN (cve
       WHERE cve.code_value=ppr.person_prsnl_r_cd
         AND cve.code_set=331
         AND ((cve.field_value="1") OR (cve.field_value="2"))
         AND cve.field_name="Override")
    DETAIL
        override_ind = 1
    WITH nocounter
    ;end select
  
    RETURN(override_ind)
END ;Subroutine


SUBROUTINE getpreferences(null)
    DECLARE powerchart_app_number = i4 WITH protect, constant(600005)
    DECLARE spreferencename = vc WITH protect, constant("PREGNANCY_SMART_TMPLT_ORG_SEC")
    DECLARE prefvalue = vc WITH noconstant("0"), protect
    
    SELECT INTO "nl:"
      
      FROM app_prefs ap,
           name_value_prefs nvp
    
      PLAN (ap
       WHERE ap.prsnl_id=0.0
         AND ap.position_cd=0.0
         AND ap.application_number=powerchart_app_number)
    
      JOIN (nvp
       WHERE nvp.parent_entity_name="APP_PREFS"
         AND nvp.parent_entity_id=ap.app_prefs_id
         AND trim(nvp.pvc_name,3)=cnvtupper(spreferencename))
   
    DETAIL
         prefvalue = nvp.pvc_value
    WITH nocounter
    ;end select
  
    RETURN(cnvtint(prefvalue))
END ;Subroutine


SUBROUTINE getorgsecurity(null)
    SELECT INTO "nl:"
     
      FROM dm_info d1
   
     WHERE d1.info_domain="SECURITY"
       AND d1.info_name="SEC_ORG_RELTN"
       AND d1.info_number=1
    DETAIL
        preg_org_sec_ind = 1
    WITH nocounter
    ;end select
  
    CALL echo(build("org_sec_ind=",preg_org_sec_ind))
  
    IF (preg_org_sec_ind=1)
        CALL loadorganizationsecuritylist(null)
    ENDIF
END ;Subroutine


SUBROUTINE loadorganizationsecuritylist(null)
    DECLARE org_cnt = i2 WITH noconstant(0)
    DECLARE stat = i2 WITH protect, noconstant(0)
    
    IF (validate(sac_org)=1)
        FREE RECORD sac_org
    ENDIF
    
    IF (validate(_sacrtl_org_inc_,99999)=99999)
        DECLARE _sacrtl_org_inc_ = i2 WITH constant(1)
    
        RECORD sac_org(
            1 organizations[*]
                2 organization_id = f8
                2 confid_cd = f8
                2 confid_level = i4
        )
   
        EXECUTE secrtl
        EXECUTE sacrtl
       
        DECLARE orgcnt           = i4 WITH protected, noconstant(0)
        DECLARE secstat          = i2
        DECLARE logontype        = i4 WITH protect, noconstant(- (1))
        DECLARE dynamic_org_ind  = i4 WITH protect, noconstant(- (1))
        DECLARE dcur_trustid     = f8 WITH protect, noconstant(0.0)
        DECLARE dynorg_enabled   = i4 WITH constant(1)
        DECLARE dynorg_disabled  = i4 WITH constant(0)
        DECLARE logontype_nhs    = i4 WITH constant(1)
        DECLARE logontype_legacy = i4 WITH constant(0)
        DECLARE confid_cnt       = i4 WITH protected, noconstant(0)
        
        RECORD confid_codes(
            1 list[*]
                2 code_value = f8
                2 coll_seq = f8
        )
       
        CALL uar_secgetclientlogontype(logontype)
        CALL echo(build("logontype:",logontype))
   
        IF (logontype != logontype_nhs)
            SET dynamic_org_ind = dynorg_disabled
        ENDIF
   
        IF (logontype=logontype_nhs)
            DECLARE getdynamicorgpref(dtrustid=f8) = i4
    
            SUBROUTINE getdynamicorgpref(dtrustid)
                DECLARE scur_trust = vc
                DECLARE pref_val = vc
                DECLARE is_enabled = i4 WITH constant(1)
                DECLARE is_disabled = i4 WITH constant(0)
                
                SET scur_trust = cnvtstring(dtrustid)
                SET scur_trust = concat(scur_trust,".00")
          
                IF ( NOT (validate(pref_req,0)))
                    RECORD pref_req(
                        1 write_ind = i2
                        1 delete_ind = i2
                        1 pref[*]
                            2 contexts[*]
                                3 context = vc
                                3 context_id = vc
                            2 section = vc
                            2 section_id = vc
                            2 subgroup = vc
                            2 entries[*]
                                3 entry = vc
                                3 values[*]
                                    4 value = vc
                    )
                ENDIF
          
                IF ( NOT (validate(pref_rep,0)))
                    RECORD pref_rep(
                        1 pref[*]
                            2 section = vc
                            2 section_id = vc
                            2 subgroup = vc
                            2 entries[*]
                                3 pref_exists_ind = i2
                                3 entry = vc
                                3 values[*]
                                    4 value = vc
                        1 status_data
                            2 status = c1
                            2 subeventstatus[1]
                                3 operationname = c25
                                3 operationstatus = c1
                                3 targetobjectname = c25
                                3 targetobjectvalue = vc
                    )
                ENDIF
          
                SET stat = alterlist(pref_req->pref,1)
                SET stat = alterlist(pref_req->pref[1].contexts,2)
                SET stat = alterlist(pref_req->pref[1].entries,1)
                SET pref_req->pref[1].contexts[1].context = "organization"
                SET pref_req->pref[1].contexts[1].context_id = scur_trust
                SET pref_req->pref[1].contexts[2].context = "default"
                SET pref_req->pref[1].contexts[2].context_id = "system"
                SET pref_req->pref[1].section = "workflow"
                SET pref_req->pref[1].section_id = "UK Trust Security"
                SET pref_req->pref[1].entries[1].entry = "dynamic organizations"

                EXECUTE ppr_preferences  WITH replace("REQUEST","PREF_REQ"), replace("REPLY","PREF_REP")

                IF (cnvtupper(pref_rep->pref[1].entries[1].values[1].value)="ENABLED")
                    RETURN(is_enabled)
                ELSE
                    RETURN(is_disabled)
                ENDIF
            END ;Subroutine
    
            DECLARE hprop = i4 WITH protect, noconstant(0)
            DECLARE tmpstat = i2
            DECLARE spropname = vc
            DECLARE sroleprofile = vc
            
            SET hprop = uar_srvcreateproperty()
            SET tmpstat = uar_secgetclientattributesext(5,hprop)
            SET spropname = uar_srvfirstproperty(hprop)
            SET sroleprofile = uar_srvgetpropertyptr(hprop,nullterm(spropname))
    
            SELECT INTO "nl:"
            
              FROM prsnl_org_reltn_type prt,
                   prsnl_org_reltn por
             
              PLAN (prt
               WHERE prt.role_profile=sroleprofile
                 AND prt.active_ind=1
                 AND prt.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
                 AND prt.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
              
              JOIN (por
               WHERE outerjoin(prt.organization_id)=por.organization_id
                 AND por.person_id=outerjoin(prt.prsnl_id)
                 AND por.active_ind=outerjoin(1)
                 AND por.beg_effective_dt_tm <= outerjoin(cnvtdatetime(curdate,curtime3))
                 AND por.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3)))
             
            ORDER BY por.prsnl_org_reltn_id
             
            DETAIL
                orgcnt = 1, 
                secstat = alterlist(sac_org->organizations,1), 
                
                user_person_id = prt.prsnl_id,
                
                sac_org->organizations[1].organization_id = prt.organization_id, 
                sac_org->organizations[1].confid_cd = por.confid_level_cd, 
                
                confid_cd = uar_get_collation_seq(por.confid_level_cd),
                
                sac_org->organizations[1].confid_level = IF (confid_cd > 0) confid_cd
                                                         ELSE 0
                                                         ENDIF
            WITH maxrec = 1
            ;end select
        
            SET dcur_trustid = sac_org->organizations[1].organization_id
            SET dynamic_org_ind = getdynamicorgpref(dcur_trustid)
            
            CALL uar_srvdestroyhandle(hprop)
        ENDIF
   
        IF (dynamic_org_ind=dynorg_disabled)
            SET confid_cnt = 0

            SELECT INTO "NL:"
                  c.code_value
                , c.collation_seq
         
              FROM code_value c
         
             WHERE c.code_set=87
            
            DETAIL
                confid_cnt = (confid_cnt+ 1)
          
                IF (mod(confid_cnt,10)=1)
                    secstat = alterlist(confid_codes->list,(confid_cnt+ 9))
                ENDIF
          
                confid_codes->list[confid_cnt].code_value = c.code_value, 
                confid_codes->list[confid_cnt].coll_seq = c.collation_seq
            WITH nocounter
            ;end select
        
            SET secstat = alterlist(confid_codes->list,confid_cnt)
        
            SELECT DISTINCT INTO "nl:"
              
              FROM prsnl_org_reltn por
             
             WHERE (por.person_id=reqinfo->updt_id)
               AND por.active_ind=1
               AND por.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
               AND por.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
         
            HEAD REPORT
                IF (orgcnt > 0)
                    secstat = alterlist(sac_org->organizations,100)
                ENDIF
            
            DETAIL
                orgcnt = (orgcnt+ 1)
                IF (mod(orgcnt,100)=1)
                    secstat = alterlist(sac_org->organizations,(orgcnt+ 99))
                ENDIF
                
                sac_org->organizations[orgcnt].organization_id = por.organization_id, 
                sac_org->organizations[orgcnt].confid_cd = por.confid_level_cd
            
            FOOT REPORT
                secstat = alterlist(sac_org->organizations,orgcnt)
            WITH nocounter
            ;end select

        
            SELECT INTO "NL:"
         
             FROM (dummyt d1  WITH seq = value(orgcnt)),
                  (dummyt d2  WITH seq = value(confid_cnt))
         
             PLAN (d1)
             
             JOIN (d2
               WHERE (sac_org->organizations[d1.seq].confid_cd=confid_codes->list[d2.seq].code_value))
            DETAIL
                sac_org->organizations[d1.seq].confid_level = confid_codes->list[d2.seq].coll_seq
            WITH nocounter
            ;end select
    
        ELSEIF (dynamic_org_ind=dynorg_enabled)
            DECLARE nhstrustchild_org_org_reltn_cd = f8

            SET nhstrustchild_org_org_reltn_cd = uar_get_code_by("MEANING",369,"NHSTRUSTCHLD")

            SELECT INTO "nl:"
              
              FROM org_org_reltn oor
              
              PLAN (oor
               WHERE oor.organization_id=dcur_trustid
                 AND oor.active_ind=1
                 AND oor.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
                 AND oor.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
                 AND oor.org_org_reltn_cd=nhstrustchild_org_org_reltn_cd)
         
            HEAD REPORT
                IF (orgcnt > 0)
                    secstat = alterlist(sac_org->organizations,10)
                ENDIF
         
            DETAIL
                IF (oor.related_org_id > 0)
                    orgcnt = (orgcnt+ 1)
           
                    IF (mod(orgcnt,10)=1)
                        secstat = alterlist(sac_org->organizations,(orgcnt+ 9))
                    ENDIF
                    
                    sac_org->organizations[orgcnt].organization_id = oor.related_org_id
                ENDIF
            FOOT REPORT
                secstat = alterlist(sac_org->organizations,orgcnt)
            WITH nocounter
            ;end select
            
        ELSE
            CALL echo(build("Unexpected login type: ",dynamimc_org_ind))
        ENDIF
    ENDIF
    
    SET org_cnt = size(sac_org->organizations,5)
    CALL echo(build("org_cnt: ",org_cnt))
    SET stat = alterlist(preg_sec_orgs->qual,(org_cnt+ 1))
    
    FOR (count = 1 TO org_cnt)
        SET preg_sec_orgs->qual[count].org_id = sac_org->organizations[count].organization_id
        SET preg_sec_orgs->qual[count].confid_level = sac_org->organizations[count].confid_level
    ENDFOR
    
    SET preg_sec_orgs->qual[(org_cnt+ 1)].org_id = 0.00
    SET preg_sec_orgs->qual[(org_cnt+ 1)].confid_level = 0
    CALL echorecord(preg_sec_orgs)
END ;Subroutine


SUBROUTINE loadencounterlistforcao(person_id,cao_flag)
    DECLARE log_program_name = vc WITH protect, noconstant("")
    DECLARE log_override_ind = i2 WITH protect, noconstant(0)
    
    SET log_program_name           = curprog
    SET log_override_ind           = 0
    
    DECLARE log_level_error        = i2 WITH protect, noconstant(0)
    DECLARE log_level_warning      = i2 WITH protect, noconstant(1)
    DECLARE log_level_audit        = i2 WITH protect, noconstant(2)
    DECLARE log_level_info         = i2 WITH protect, noconstant(3)
    DECLARE log_level_debug        = i2 WITH protect, noconstant(4)
    DECLARE hsys                   = i4 WITH protect, noconstant(0)
    DECLARE sysstat                = i4 WITH protect, noconstant(0)
    DECLARE serrmsg                = c132 WITH protect, noconstant(" ")
    DECLARE ierrcode               = i4 WITH protect, noconstant(error(serrmsg,1))
    DECLARE crsl_msg_default       = i4 WITH protect, noconstant(0)
    DECLARE crsl_msg_level         = i4 WITH protect, noconstant(0)
    EXECUTE msgrtl
    
    SET crsl_msg_default           = uar_msgdefhandle()
    SET crsl_msg_level             = uar_msggetlevel(crsl_msg_default)
    
    DECLARE lcrslsubeventcnt       = i4 WITH protect, noconstant(0)
    DECLARE icrslloggingstat       = i2 WITH protect, noconstant(0)
    DECLARE lcrslsubeventsize      = i4 WITH protect, noconstant(0)
    DECLARE icrslloglvloverrideind = i2 WITH protect, noconstant(0)
    DECLARE scrsllogtext           = vc WITH protect, noconstant("")
    DECLARE scrsllogevent          = vc WITH protect, noconstant("")
    DECLARE icrslholdloglevel      = i2 WITH protect, noconstant(0)
    DECLARE icrslerroroccured      = i2 WITH protect, noconstant(0)
    DECLARE lcrsluarmsgwritestat   = i4 WITH protect, noconstant(0)
    DECLARE crsl_info_domain       = vc WITH protect, constant("DISCERNABU SCRIPT LOGGING")
    DECLARE crsl_logging_on        = c1 WITH protect, constant("L")
  
  
    IF ((    (logical("MP_LOGGING_ALL") > " ") 
          OR (logical(concat("MP_LOGGING_",log_program_name)) > " ")
       ))
        SET log_override_ind = 1
    ENDIF
  
    DECLARE log_message(logmsg=vc,loglvl=i4) = null
    
    SUBROUTINE log_message(logmsg,loglvl)
        SET icrslloglvloverrideind = 0
        SET scrsllogtext = ""
        SET scrsllogevent = ""
        SET scrsllogtext = concat("{{Script::",value(log_program_name),"}} ",logmsg)
        
        IF (log_override_ind=0)
            SET icrslholdloglevel = loglvl
        ELSE
            IF (crsl_msg_level < loglvl)
                SET icrslholdloglevel = crsl_msg_level
                SET icrslloglvloverrideind = 1
        
        ELSE
                SET icrslholdloglevel = loglvl
            ENDIF
        ENDIF
        
        IF (icrslloglvloverrideind=1)
            SET scrsllogevent = "Script_Override"
        
        ELSE
            CASE (icrslholdloglevel)
            OF log_level_error:
                SET scrsllogevent = "Script_Error"
            
            OF log_level_warning:
                SET scrsllogevent = "Script_Warning"
            
            OF log_level_audit:
                SET scrsllogevent = "Script_Audit"
            
            OF log_level_info:
                SET scrsllogevent = "Script_Info"
            
            OF log_level_debug:
                SET scrsllogevent = "Script_Debug"
            ENDCASE
        ENDIF
        
        SET lcrsluarmsgwritestat = uar_msgwrite( crsl_msg_default,0,nullterm(scrsllogevent)
                                               , icrslholdloglevel,nullterm(scrsllogtext))
        CALL echo(logmsg)
    END ;Subroutine
  
    DECLARE error_message(logstatusblockind=i2) = i2
    
    SUBROUTINE error_message(logstatusblockind)
        SET icrslerroroccured = 0
        SET ierrcode = error(serrmsg,0)
        
        WHILE (ierrcode > 0)
            SET icrslerroroccured = 1
      
            IF (validate(reply))
                SET reply->status_data.status = "F"
            ENDIF
      
            CALL log_message(serrmsg,log_level_audit)
            
            IF (logstatusblockind=1)
                IF (validate(reply))
                    CALL populate_subeventstatus("EXECUTE","F","CCL SCRIPT",serrmsg)
                ENDIF
            ENDIF
      
            SET ierrcode = error(serrmsg,0)
        ENDWHILE
    
        RETURN(icrslerroroccured)
    END ;Subroutine
  
    DECLARE error_and_zero_check_rec(qualnum=i4,opname=vc,logmsg=vc,errorforceexit=i2,zeroforceexit=i2, recorddata=vc(ref)) = i2
  
    SUBROUTINE error_and_zero_check_rec(qualnum,opname,logmsg,errorforceexit,zeroforceexit,recorddata)
        SET icrslerroroccured = 0
        SET ierrcode = error(serrmsg,0)
       
        WHILE (ierrcode > 0)
            SET icrslerroroccured = 1
            CALL log_message(serrmsg,log_level_audit)
            CALL populate_subeventstatus_rec(opname,"F",serrmsg,logmsg,recorddata)
            SET ierrcode = error(serrmsg,0)
        ENDWHILE
    
        IF (    icrslerroroccured=1
            AND errorforceexit=1)
     
            SET recorddata->status_data.status = "F"
            GO TO exit_script
        ENDIF
    
        IF (    qualnum=0
            AND zeroforceexit=1)
     
            SET recorddata->status_data.status = "Z"
            CALL populate_subeventstatus_rec(opname,"Z","No records qualified",logmsg,recorddata)
            GO TO exit_script
        ENDIF
        
        RETURN(icrslerroroccured)
    END ;Subroutine
  
    DECLARE error_and_zero_check(qualnum=i4,opname=vc,logmsg=vc,errorforceexit=i2,zeroforceexit=i2) = i2
    SUBROUTINE error_and_zero_check(qualnum,opname,logmsg,errorforceexit,zeroforceexit)
        RETURN(error_and_zero_check_rec(qualnum,opname,logmsg,errorforceexit,zeroforceexit,reply))
    END ;Subroutine
  
    DECLARE populate_subeventstatus_rec(operationname=vc(value)
                                       ,operationstatus=vc(value)
                                       ,targetobjectname=vc(value)
                                       ,targetobjectvalue=vc(value)
                                       ,recorddata=vc(ref)) = i2
    SUBROUTINE populate_subeventstatus_rec(operationname,operationstatus,targetobjectname,targetobjectvalue,recorddata)
        IF (validate(recorddata->status_data.status,"-1") != "-1")
            SET lcrslsubeventcnt = size(recorddata->status_data.subeventstatus,5)
            SET lcrslsubeventsize = size(trim(recorddata->status_data.subeventstatus[lcrslsubeventcnt].operationname))
            SET lcrslsubeventsize = ( lcrslsubeventsize 
                                    + size(trim(recorddata->status_data.subeventstatus[lcrslsubeventcnt].operationstatus)))
            SET lcrslsubeventsize = (lcrslsubeventsize
                                    + size(trim(recorddata->status_data.subeventstatus[lcrslsubeventcnt].targetobjectname)))
            SET lcrslsubeventsize = (lcrslsubeventsize
                                    + size(trim(recorddata->status_data.subeventstatus[lcrslsubeventcnt].targetobjectvalue)))
     
            IF (lcrslsubeventsize > 0)
                SET lcrslsubeventcnt = (lcrslsubeventcnt+ 1)
                SET icrslloggingstat = alter(recorddata->status_data.subeventstatus,lcrslsubeventcnt)
            ENDIF
     
            SET recorddata->status_data.subeventstatus[lcrslsubeventcnt].operationname = substring(1,25,operationname)
            SET recorddata->status_data.subeventstatus[lcrslsubeventcnt].operationstatus = substring(1,1,operationstatus)
            SET recorddata->status_data.subeventstatus[lcrslsubeventcnt].targetobjectname = substring(1,25,targetobjectname)
            SET recorddata->status_data.subeventstatus[lcrslsubeventcnt].targetobjectvalue = targetobjectvalue
        ENDIF
    END ;Subroutine
  
    DECLARE populate_subeventstatus(operationname=vc(value)
                                   ,operationstatus=vc(value)
                                   ,targetobjectname =vc(value)
                                   ,targetobjectvalue=vc(value)) = i2
    
    SUBROUTINE populate_subeventstatus(operationname,operationstatus,targetobjectname,targetobjectvalue)
        CALL populate_subeventstatus_rec(operationname,operationstatus,targetobjectname,targetobjectvalue,reply)
    END ;Subroutine
  
    DECLARE populate_subeventstatus_msg(operationname=vc(value)
                                       ,operationstatus=vc(value)
                                       ,targetobjectname=vc(value)
                                       ,targetobjectvalue=vc(value)
                                       ,loglevel=i2(value)) = i2
    SUBROUTINE populate_subeventstatus_msg(operationname,operationstatus,targetobjectname,targetobjectvalue,loglevel)
        CALL populate_subeventstatus(operationname,operationstatus,targetobjectname,targetobjectvalue)
        CALL log_message(targetobjectvalue,loglevel)
    END ;Subroutine
  
    DECLARE check_log_level(arg_log_level=i4) = i2
    SUBROUTINE check_log_level(arg_log_level)
        IF (((crsl_msg_level >= arg_log_level) OR (log_override_ind=1)) )
            RETURN(1)
        ELSE
            RETURN(0)
        ENDIF
    END ;Subroutine
  
    DECLARE loadpregnancyorganizationsecuritylist() = null
    IF (validate(preg_org_sec_ind)=0)
        DECLARE preg_org_sec_ind = i4 WITH noconstant(0)
   
        SELECT INTO "nl:"
          FROM dm_info d1,
               dm_info d2
    
         WHERE d1.info_domain="SECURITY"
           AND d1.info_name="SEC_ORG_RELTN"
           AND d1.info_number=1
           AND d2.info_domain="SECURITY"
           AND d2.info_name="SEC_PREG_ORG_RELTN"
           AND d2.info_number=1
        DETAIL
            preg_org_sec_ind = 1
        WITH nocounter
        ;end select
   
        CALL echo(build("preg_org_sec_ind=",preg_org_sec_ind))
   
        IF (preg_org_sec_ind=1)
            FREE RECORD preg_sec_orgs
            RECORD preg_sec_orgs(
                1 qual[*]
                    2 org_id = f8
                    2 confid_level = i4
            )
    
            CALL loadpregnancyorganizationsecuritylist(null)
        ENDIF
    ENDIF

    SUBROUTINE loadpregnancyorganizationsecuritylist(null)
        DECLARE org_cnt = i2 WITH noconstant(0)
        DECLARE stat = i2 WITH protect, noconstant(0)
    
        IF (validate(sac_org)=1)
            FREE RECORD sac_org
        ENDIF
    
        IF (validate(_sacrtl_org_inc_,99999)=99999)
            DECLARE _sacrtl_org_inc_ = i2 WITH constant(1)
            
            RECORD sac_org(
                1 organizations[*]
                    2 organization_id = f8
                    2 confid_cd = f8
                    2 confid_level = i4
            )
     
            EXECUTE secrtl
            EXECUTE sacrtl
         
            DECLARE orgcnt = i4 WITH protected, noconstant(0)
            DECLARE secstat = i2
            DECLARE logontype = i4 WITH protect, noconstant(- (1))
            DECLARE dynamic_org_ind = i4 WITH protect, noconstant(- (1))
            DECLARE dcur_trustid = f8 WITH protect, noconstant(0.0)
            DECLARE dynorg_enabled = i4 WITH constant(1)
            DECLARE dynorg_disabled = i4 WITH constant(0)
            DECLARE logontype_nhs = i4 WITH constant(1)
            DECLARE logontype_legacy = i4 WITH constant(0)
            DECLARE confid_cnt = i4 WITH protected, noconstant(0)
            
            RECORD confid_codes(
                1 list[*]
                    2 code_value = f8
                    2 coll_seq = f8
                )
         
            CALL uar_secgetclientlogontype(logontype)
            CALL echo(build("logontype:",logontype))
            
            IF (logontype != logontype_nhs)
                SET dynamic_org_ind = dynorg_disabled
            ENDIF
         
            IF (logontype=logontype_nhs)
                DECLARE getdynamicorgpref(dtrustid=f8) = i4
         
                SUBROUTINE getdynamicorgpref(dtrustid)
                
                    DECLARE scur_trust = vc
                    DECLARE pref_val = vc
                    DECLARE is_enabled = i4 WITH constant(1)
                    DECLARE is_disabled = i4 WITH constant(0)
                    
                    SET scur_trust = cnvtstring(dtrustid)
                    SET scur_trust = concat(scur_trust,".00")
            
                    IF ( NOT (validate(pref_req,0)))
                        RECORD pref_req(
                            1 write_ind = i2
                            1 delete_ind = i2
                            1 pref[*]
                                2 contexts[*]
                                    3 context = vc
                                    3 context_id = vc
                                2 section = vc
                                2 section_id = vc
                                2 subgroup = vc
                                2 entries[*]
                                    3 entry = vc
                                    3 values[*]
                                        4 value = vc
                        )
                    ENDIF
            
                    IF ( NOT (validate(pref_rep,0)))
                        RECORD pref_rep(
                            1 pref[*]
                                2 section = vc
                                2 section_id = vc
                                2 subgroup = vc
                                2 entries[*]
                                    3 pref_exists_ind = i2
                                    3 entry = vc
                                    3 values[*]
                                        4 value = vc
                            1 status_data
                                2 status = c1
                                2 subeventstatus[1]
                                    3 operationname = c25
                                    3 operationstatus = c1
                                    3 targetobjectname = c25
                                    3 targetobjectvalue = vc
                        )
                    ENDIF
            
                    SET stat = alterlist(pref_req->pref,1)
                    SET stat = alterlist(pref_req->pref[1].contexts,2)
                    SET stat = alterlist(pref_req->pref[1].entries,1)
                    SET pref_req->pref[1].contexts[1].context = "organization"
                    SET pref_req->pref[1].contexts[1].context_id = scur_trust
                    SET pref_req->pref[1].contexts[2].context = "default"
                    SET pref_req->pref[1].contexts[2].context_id = "system"
                    SET pref_req->pref[1].section = "workflow"
                    SET pref_req->pref[1].section_id = "UK Trust Security"
                    SET pref_req->pref[1].entries[1].entry = "dynamic organizations"

                    EXECUTE ppr_preferences  WITH replace("REQUEST","PREF_REQ"), replace("REPLY","PREF_REP")
            
                    IF (cnvtupper(pref_rep->pref[1].entries[1].values[1].value)="ENABLED")
                        RETURN(is_enabled)
                    ELSE
                        RETURN(is_disabled)
                    ENDIF
                END ;Subroutine
          
          
                DECLARE hprop = i4 WITH protect, noconstant(0)
                DECLARE tmpstat = i2
                DECLARE spropname = vc
                DECLARE sroleprofile = vc
                
                SET hprop = uar_srvcreateproperty()
                SET tmpstat = uar_secgetclientattributesext(5,hprop)
                SET spropname = uar_srvfirstproperty(hprop)
                SET sroleprofile = uar_srvgetpropertyptr(hprop,nullterm(spropname))
                
                SELECT INTO "nl:"
                  FROM prsnl_org_reltn_type prt,
                       prsnl_org_reltn por
                  
                  PLAN (prt
                   WHERE prt.role_profile=sroleprofile
                     AND prt.active_ind=1
                     AND prt.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
                     AND prt.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
            
                  JOIN (por
                   WHERE outerjoin(prt.organization_id)=por.organization_id
                     AND por.person_id=outerjoin(prt.prsnl_id)
                     AND por.active_ind=outerjoin(1)
                     AND por.beg_effective_dt_tm <= outerjoin(cnvtdatetime(curdate,curtime3))
                     AND por.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3)))
                
                ORDER BY por.prsnl_org_reltn_id
                
                DETAIL
                    orgcnt = 1, 
                    secstat = alterlist(sac_org->organizations,1), 
                    user_person_id = prt.prsnl_id,
                    sac_org->organizations[1].organization_id = prt.organization_id, 
                    sac_org->organizations[1].confid_cd = por.confid_level_cd, 
                    confid_cd = uar_get_collation_seq(por.confid_level_cd),
                    sac_org->organizations[1].confid_level =
            
                    IF (confid_cd > 0) confid_cd
                    ELSE 0
                    ENDIF
                
                WITH maxrec = 1
                ;end select
          
                SET dcur_trustid = sac_org->organizations[1].organization_id
                SET dynamic_org_ind = getdynamicorgpref(dcur_trustid)
                CALL uar_srvdestroyhandle(hprop)
            ENDIF
            IF (dynamic_org_ind=dynorg_disabled)
                SET confid_cnt = 0
          
                SELECT INTO "NL:"
                    c.code_value, c.collation_seq
                  FROM code_value c
                 WHERE c.code_set=87
                DETAIL
                    confid_cnt = (confid_cnt+ 1)
            
                    IF (mod(confid_cnt,10)=1)
                        secstat = alterlist(confid_codes->list,(confid_cnt+ 9))
                    ENDIF
            
                    confid_codes->list[confid_cnt].code_value = c.code_value, 
                    confid_codes->list[confid_cnt].coll_seq = c.collation_seq
                WITH nocounter
                ;end select
          
                SET secstat = alterlist(confid_codes->list,confid_cnt)
                
                SELECT DISTINCT INTO "nl:"
                  
                  FROM prsnl_org_reltn por
                 
                 WHERE (por.person_id=reqinfo->updt_id)
                   AND por.active_ind=1
                   AND por.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
                   AND por.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
                HEAD REPORT
                    IF (orgcnt > 0)
                        secstat = alterlist(sac_org->organizations,100)
                    ENDIF
                DETAIL
                    orgcnt = (orgcnt+ 1)
            
                    IF (mod(orgcnt,100)=1)
                        secstat = alterlist(sac_org->organizations,(orgcnt+ 99))
                    ENDIF
            
                    sac_org->organizations[orgcnt].organization_id = por.organization_id, 
                    sac_org->organizations[orgcnt].confid_cd = por.confid_level_cd
                FOOT REPORT
                    secstat = alterlist(sac_org->organizations,orgcnt)
                WITH nocounter
                ;end select
          
          
                SELECT INTO "NL:"
                  FROM (dummyt d1  WITH seq = value(orgcnt)),
                       (dummyt d2  WITH seq = value(confid_cnt))
           
                  PLAN (d1)
            
                  JOIN (d2
                   WHERE (sac_org->organizations[d1.seq].confid_cd=confid_codes->list[d2.seq].code_value))
           
                DETAIL
                    sac_org->organizations[d1.seq].confid_level = confid_codes->list[d2.seq].coll_seq
                WITH nocounter
                
                ;end select
         
            ELSEIF (dynamic_org_ind=dynorg_enabled)
                DECLARE nhstrustchild_org_org_reltn_cd = f8
                SET nhstrustchild_org_org_reltn_cd = uar_get_code_by("MEANING",369,"NHSTRUSTCHLD")
          
                SELECT INTO "nl:"
                  
                  FROM org_org_reltn oor
                  
                  PLAN (oor
                 
                 WHERE oor.organization_id=dcur_trustid
                   AND oor.active_ind=1
                   AND oor.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
                   AND oor.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
                   AND oor.org_org_reltn_cd=nhstrustchild_org_org_reltn_cd)
                HEAD REPORT
                    IF (orgcnt > 0)
                        secstat = alterlist(sac_org->organizations,10)
                    ENDIF
                DETAIL
                    IF (oor.related_org_id > 0)
                        orgcnt = (orgcnt+ 1)
                        
                        IF (mod(orgcnt,10)=1)
                            secstat = alterlist(sac_org->organizations,(orgcnt+ 9))
                        ENDIF
                        
                        sac_org->organizations[orgcnt].organization_id = oor.related_org_id
                    ENDIF
                FOOT REPORT
                    secstat = alterlist(sac_org->organizations,orgcnt)
                WITH nocounter
                ;end select
            ELSE
                CALL echo(build("Unexpected login type: ",dynamimc_org_ind))
            ENDIF
        ENDIF
    
        SET org_cnt = size(sac_org->organizations,5)
        
        CALL echo(build("org_cnt: ",org_cnt))
        
        SET stat = alterlist(preg_sec_orgs->qual,(org_cnt+ 1))
        
        FOR (count = 1 TO org_cnt)
            SET preg_sec_orgs->qual[count].org_id = sac_org->organizations[count].organization_id
            SET preg_sec_orgs->qual[count].confid_level = sac_org->organizations[count].confid_level
        ENDFOR
        
        SET preg_sec_orgs->qual[(org_cnt+ 1)].org_id = 0.00
        SET preg_sec_orgs->qual[(org_cnt+ 1)].confid_level = 0
  
    END ;Subroutine

    DECLARE getallpregencounters(p1=f8(val),p3=vc(ref)) = null WITH protect
    DECLARE getpregpreferences(p1=vc(val)) = vc WITH protect

    RECORD encounters(
        1 encounter_ids[*]
            2 encounter_id = f8
    )
  
    SUBROUTINE getallpregencounters(person_id,encounters)
        CALL log_message("In GetAllPregEncounters()",log_level_debug)
        
        DECLARE lcnt = i4 WITH protect, noconstant(0)
        DECLARE begin_date_time = dq8 WITH constant(cnvtdatetime(curdate,curtime3)), private
        
        IF (preg_org_sec_ind=0)
            SELECT INTO "nl:"
              FROM encounter e
             WHERE e.person_id=person_id
               AND e.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
               AND ((e.end_effective_dt_tm+ 0) > cnvtdatetime(curdate,curtime3))
               AND ((e.active_ind+ 0)=1)
               AND ((e.organization_id+ 0) > 0.0)
            DETAIL
                lcnt = (lcnt+ 1)
           
                IF (mod(lcnt,10)=1)
                    lstat = alterlist(encounters->encounter_ids,(lcnt+ 9))
                ENDIF
           
                encounters->encounter_ids[lcnt].encounter_id = e.encntr_id
            WITH nocounter
            ;end select
         
            SET stat = alterlist(encounters->encounter_ids,lcnt)
        ENDIF
        
        CALL log_message(build("Exit GetAllPregEncounters(), Elapsed time in seconds:",datetimediff(
           cnvtdatetime(curdate,curtime3),begin_date_time,5)),log_level_debug)
    END ;Subroutine
 
    SUBROUTINE getpregpreferences(preferencename)
        CALL log_message("In GetPregPreferences()",log_level_debug)

        DECLARE begin_date_time = dq8 WITH constant(cnvtdatetime(curdate,curtime3)), private
        DECLARE preferencevalue = vc WITH noconstant(""), protect

        RECORD pregnancy_event_sets(
            1 qual[*]
                2 pref_entry_name = vc
                2 event_set_name = vc
        )
        
        DECLARE stat = i2 WITH protect, noconstant(0)
        DECLARE hpref = i4 WITH private, noconstant(0)
        DECLARE hgroup = i4 WITH private, noconstant(0)
        DECLARE hrepgroup = i4 WITH private, noconstant(0)
        DECLARE hsection = i4 WITH private, noconstant(0)
        DECLARE hattr = i4 WITH private, noconstant(0)
        DECLARE hentry = i4 WITH private, noconstant(0)
        DECLARE lentrycnt = i4 WITH private, noconstant(0)
        DECLARE lentryidx = i4 WITH private, noconstant(0)
        DECLARE ilen = i4 WITH private, noconstant(255)
        DECLARE lattrcnt = i4 WITH private, noconstant(0)
        DECLARE lattridx = i4 WITH private, noconstant(0)
        DECLARE lvalcnt = i4 WITH private, noconstant(0)
        DECLARE sentryname = c255 WITH private, noconstant("")
        DECLARE sattrname = c255 WITH private, noconstant("")
        DECLARE sval = c255 WITH private, noconstant("")
        DECLARE sentryval = c255 WITH private, noconstant("")
        DECLARE tempdeldate = dq8 WITH private, noconstant(0)
        DECLARE deldate = dq8 WITH private, noconstant(0)
        
        CALL echo("Entering GetPregPreferences subroutine")
        
        EXECUTE prefrtl
        
        SET hpref = uar_prefcreateinstance(0)
        SET stat = uar_prefaddcontext(hpref,nullterm("default"),nullterm("system"))
        SET stat = uar_prefsetsection(hpref,nullterm("component"))
        SET hgroup = uar_prefcreategroup()
        SET stat = uar_prefsetgroupname(hgroup,nullterm("Pregnancy"))
        SET stat = uar_prefaddgroup(hpref,hgroup)
        SET stat = uar_prefperform(hpref)
        SET hsection = uar_prefgetsectionbyname(hpref,nullterm("component"))
        SET hrepgroup = uar_prefgetgroupbyname(hsection,nullterm("Pregnancy"))
        SET stat = uar_prefgetgroupentrycount(hrepgroup,lentrycnt)
        
        FOR (lentryidx = 0 TO (lentrycnt - 1))
            SET hentry = uar_prefgetgroupentry(hrepgroup,lentryidx)
            SET ilen = 255
            SET sentryname = ""
            SET sentryval = ""
            SET stat = uar_prefgetentryname(hentry,sentryname,ilen)
            IF (sentryname=preferencename)
                SET lattrcnt = 0
                SET stat = uar_prefgetentryattrcount(hentry,lattrcnt)
                
                FOR (lattridx = 0 TO (lattrcnt - 1))
                    SET hattr = uar_prefgetentryattr(hentry,lattridx)
                    SET ilen = 255
                    SET sattrname = ""
                    SET stat = uar_prefgetattrname(hattr,sattrname,ilen)
             
                    IF (sattrname="prefvalue")
                        SET lvalcnt = 0
                        SET stat = uar_prefgetattrvalcount(hattr,lvalcnt)
                        
                        IF (lvalcnt > 0)
                            SET sval = ""
                            SET ilen = 255
                            SET stat = uar_prefgetattrval(hattr,sval,ilen,0)
                            SET preferencevalue = trim(sval)
                        ENDIF
                        
                        SET lattridx = lattrcnt
                    ENDIF
                ENDFOR
            ENDIF
        ENDFOR
       
        CALL uar_prefdestroysection(hsection)
        CALL uar_prefdestroygroup(hgroup)
        CALL uar_prefdestroyinstance(hpref)
        
        CALL log_message(build("Exit GetPregPreferences(), Elapsed time in seconds:",datetimediff(
                                                                cnvtdatetime(curdate,curtime3),begin_date_time,5)),log_level_debug)
        
        RETURN(preferencevalue)
    END ;Subroutine

    RECORD accessible_encntr_person_ids(
        1 person_ids[*]
            2 person_id = f8
    ) WITH public


    RECORD accessible_encntr_ids(
        1 accessible_encntrs_cnt = i4
        1 accessible_encntrs[*]
            2 accessible_encntr_id = f8
        ) WITH public
      
    RECORD accessible_encntr_ids_maps(
        1 persons_cnt = i4
        1 persons[*]
            2 person_id = f8
            2 accessible_encntrs_cnt = i4
            2 accessible_encntrs[*]
                3 accessible_encntr_id = f8
    ) WITH public

    DECLARE getaccessibleencntrerrormsg = vc WITH protect
    DECLARE getaccessibleencntrtoggleerrormsg = vc WITH protect
    DECLARE h3202611srvmsg = i4 WITH noconstant(0), protect
    DECLARE h3202611srvreq = i4 WITH noconstant(0), protect
    DECLARE h3202611srvrep = i4 WITH noconstant(0), protect
    DECLARE hsys = i4 WITH noconstant(0), protect
    DECLARE sysstat = i4 WITH noconstant(0), protect
    DECLARE slogtext = vc WITH noconstant(""), protect
    DECLARE access_encntr_req_number = i4 WITH constant(3202611), protect
    DECLARE get_accessible_encntr_ids_by_person_id(person_id=f8,concept=vc,disable_access_security_ind=i2(value,0)) = i4
    DECLARE get_accessible_encntr_ids_by_person_ids(accessible_encntr_person_ids=vc(ref)
                                                   ,concept=vc
                                                   ,disable_access_security_ind=i2(value,0)) = i4
    DECLARE get_accessible_encntr_ids_by_person_ids_map(accessible_encntr_person_ids=vc(ref)
                                                       ,concept=vc
                                                       ,disable_access_security_ind=i2(value,0)) = i4
    DECLARE get_accessible_encntr_toggle(result=i4(ref)) = i4
    DECLARE isfeaturetoggleon(togglename=vc,systemidentifier=vc,featuretoggleflag=i2(ref)) = i4
    DECLARE ischartaccesson(concept=vc,chartaccessflag=i2(ref)) = i4

    SUBROUTINE get_accessible_encntr_ids_by_person_id(person_id,concept,disable_access_security_ind)
        SET h3202611srvmsg = uar_srvselectmessage(access_encntr_req_number)
        
        IF (h3202611srvmsg=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to select message ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        SET h3202611srvreq = uar_srvcreaterequest(h3202611srvmsg)
        IF (h3202611srvreq=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to create request ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        SET h3202611srvrep = uar_srvcreatereply(h3202611srvmsg)
        IF (h3202611srvrep=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to create reply ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        DECLARE e_count = i4 WITH noconstant(0), protect
        DECLARE encounter_count = i4 WITH noconstant(0), protect
        DECLARE htransactionstatus = i4 WITH noconstant(0), protect
        DECLARE hencounter = i4 WITH noconstant(0), protect
        
        SET stat = uar_srvsetdouble(h3202611srvreq,"patientId",person_id)
        SET stat = uar_srvsetstring(h3202611srvreq,"concept",nullterm(concept))
        SET stat = uar_srvsetshort(h3202611srvreq,"disableAccessSecurityInd",disable_access_security_ind)
        SET stat = uar_srvexecute(h3202611srvmsg,h3202611srvreq,h3202611srvrep)
        
        IF (stat=0)
            SET htransactionstatus = uar_srvgetstruct(h3202611srvrep,"transactionStatus")
            IF (htransactionstatus=0)
                SET getaccessibleencntrerrormsg = build2("Failed to get transaction status from reply of ",
                                                                                            build(access_encntr_req_number))
                RETURN(1)
            ELSE
                IF (uar_srvgetshort(htransactionstatus,"successIndicator") != 1)
                    SET getaccessibleencntrerrormsg = build2("Failure for call to ",build(
                                            access_encntr_req_number),". Debug Msg =",uar_srvgetstringptr(htransactionstatus,
                                            "debugErrorMessage"))
                    RETURN(1)
                ELSE

                    SET encounter_count = uar_srvgetitemcount(h3202611srvrep,"encounterIds")
                    SET stat = alterlist(accessible_encntr_ids->accessible_encntrs,encounter_count)
                    SET accessible_encntr_ids->accessible_encntrs_cnt = encounter_count

                    FOR (e_count = 1 TO encounter_count)
                        SET hencounter = uar_srvgetitem(h3202611srvrep,"encounterIds",(e_count - 1))
                        SET accessible_encntr_ids->accessible_encntrs[e_count].accessible_encntr_id =
                        uar_srvgetdouble(hencounter,"encounterId")
                    ENDFOR
                ENDIF
            ENDIF
            
            RETURN(0)
        
        ELSE
            SET getaccessibleencntrerrormsg = build2("Failure for call to ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
    END ;Subroutine

    
    SUBROUTINE get_accessible_encntr_ids_by_person_ids(accessible_encntr_person_ids,concept,disable_access_security_ind)
        SET h3202611srvmsg = uar_srvselectmessage(access_encntr_req_number)
        
        IF (h3202611srvmsg=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to select message ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        SET h3202611srvreq = uar_srvcreaterequest(h3202611srvmsg)
        
        IF (h3202611srvreq=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to create request ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        SET h3202611srvrep = uar_srvcreatereply(h3202611srvmsg)
        IF (h3202611srvrep=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to create reply ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        DECLARE p_count = i4 WITH noconstant(0), protect
        DECLARE person_count = i4 WITH noconstant(0), protect
        DECLARE e_count = i4 WITH noconstant(0), protect
        DECLARE encounter_count = i4 WITH noconstant(0), protect
        DECLARE htransactionstatus = i4 WITH noconstant(0), protect
        DECLARE hencounter = i4 WITH noconstant(0), protect
        DECLARE curr_encntr_cnt = i4 WITH noconstant(0), protect
        DECLARE prev_encntr_cnt = i4 WITH noconstant(0), protect
        
        
        SET person_count = size(accessible_encntr_person_ids->person_ids,5)
        
        FOR (p_count = 1 TO person_count)
            SET stat = uar_srvsetdouble(h3202611srvreq,"patientId",accessible_encntr_person_ids->person_ids[p_count].person_id)
            SET stat = uar_srvsetstring(h3202611srvreq,"concept",nullterm(concept))
            SET stat = uar_srvsetshort(h3202611srvreq,"disableAccessSecurityInd",disable_access_security_ind)
            SET stat = uar_srvexecute(h3202611srvmsg,h3202611srvreq,h3202611srvrep)
          
            IF (stat=0)
                SET htransactionstatus = uar_srvgetstruct(h3202611srvrep,"transactionStatus")
                
                IF (htransactionstatus=0)
                    SET getaccessibleencntrerrormsg = build2("Failed to get transaction status from reply of ",
                                                                                                   build(access_encntr_req_number))
                    RETURN(1)
                ELSE
                    IF (uar_srvgetshort(htransactionstatus,"successIndicator") != 1)
                        SET getaccessibleencntrerrormsg = build2("Failure for call to ",build(
                                                  access_encntr_req_number),". Debug Msg =",uar_srvgetstringptr(htransactionstatus,
                                                  "debugErrorMessage"))
                        RETURN(1)
                    ELSE
                        SET encounter_count = uar_srvgetitemcount(h3202611srvrep,"encounterIds")
                        SET prev_encntr_cnt = curr_encntr_cnt
                        SET curr_encntr_cnt = (curr_encntr_cnt+ encounter_count)
                        SET stat = alterlist(accessible_encntr_ids->accessible_encntrs,curr_encntr_cnt)
                        SET accessible_encntr_ids->accessible_encntrs_cnt = curr_encntr_cnt
             
                        FOR (e_count = 1 TO encounter_count)
                            SET hencounter = uar_srvgetitem(h3202611srvrep,"encounterIds",(e_count - 1))
                            SET accessible_encntr_ids->accessible_encntrs[(e_count+ prev_encntr_cnt)].accessible_encntr_id = 
                                                                                        uar_srvgetdouble(hencounter,"encounterId")
                        ENDFOR
                    ENDIF
                ENDIF
            ELSE
                SET getaccessibleencntrerrormsg = build2("Failure for call to ",build(access_encntr_req_number))
                RETURN(1)
            ENDIF
        ENDFOR
        
        RETURN(0)
    
    END ;Subroutine
    
    
    SUBROUTINE get_accessible_encntr_ids_by_person_ids_map(accessible_encntr_person_ids,concept,disable_access_security_ind)
        SET h3202611srvmsg = uar_srvselectmessage(access_encntr_req_number)
        
        IF (h3202611srvmsg=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to select message ",build(access_encntr_req_number))
            RETURN(1)
        ENDIF
        
        SET h3202611srvreq = uar_srvcreaterequest(h3202611srvmsg)
        IF (h3202611srvreq=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to create request ",build(access_encntr_req_number))
            
            RETURN(1)
        ENDIF
        
        SET h3202611srvrep = uar_srvcreatereply(h3202611srvmsg)
        IF (h3202611srvrep=0)
            SET getaccessibleencntrerrormsg = build2("*** Failed to create reply ",build(access_encntr_req_number))
            
            RETURN(1)
        ENDIF
        
        DECLARE p_count = i4 WITH noconstant(0), protect
        DECLARE person_count = i4 WITH noconstant(0), protect
        DECLARE e_count = i4 WITH noconstant(0), protect
        DECLARE encounter_count = i4 WITH noconstant(0), protect
        DECLARE htransactionstatus = i4 WITH noconstant(0), protect
        DECLARE hencounter = i4 WITH noconstant(0), protect
        
        SET person_count = size(accessible_encntr_person_ids->person_ids,5)
        SET accessible_encntr_ids_maps->persons_cnt = person_count
        
        FOR (p_count = 1 TO person_count)
            SET stat = uar_srvsetdouble(h3202611srvreq,"patientId",accessible_encntr_person_ids->person_ids[p_count].person_id)
            SET stat = uar_srvsetstring(h3202611srvreq,"concept",nullterm(concept))
            SET stat = uar_srvsetshort(h3202611srvreq,"disableAccessSecurityInd",disable_access_security_ind)
            SET accessible_encntr_ids_maps->persons[p_count].person_id = accessible_encntr_person_ids->person_ids[p_count].person_id
            SET stat = uar_srvexecute(h3202611srvmsg,h3202611srvreq,h3202611srvrep)
            IF (stat=0)
                SET htransactionstatus = uar_srvgetstruct(h3202611srvrep,"transactionStatus")
                IF (htransactionstatus=0)
                    SET getaccessibleencntrerrormsg = build2("Failed to get transaction status from reply of ",
                                                                                        build(access_encntr_req_number))
                    RETURN(1)
                ELSE
                
                    IF (uar_srvgetshort(htransactionstatus,"successIndicator") != 1)
                        SET getaccessibleencntrerrormsg = build2("Failure for call to ",build(
                                                access_encntr_req_number),". Debug Msg =",uar_srvgetstringptr(htransactionstatus,
                                                "debugErrorMessage"))
                    
                        RETURN(1)
                    ELSE
                
                        SET encounter_count = uar_srvgetitemcount(h3202611srvrep,"encounterIds")
                        SET stat = alterlist(accessible_encntr_ids_maps->persons[p_count].accessible_encntrs,encounter_count)
                        SET accessible_encntr_ids_maps->persons[p_count].accessible_encntrs_cnt = encounter_count
                    
                        FOR (e_count = 1 TO encounter_count)
                            SET hencounter = uar_srvgetitem(h3202611srvrep,"encounterIds",(e_count - 1))
                            SET accessible_encntr_ids_maps->persons[p_count].accessible_encntrs[e_count].accessible_encntr_id = 
                                                                                          uar_srvgetdouble(hencounter,"encounterId")
                        ENDFOR
                    ENDIF
                ENDIF
            ELSE
            
                SET getaccessibleencntrerrormsg = build2("Failure for call to ",build(access_encntr_req_number))
                RETURN(1)
            ENDIF
        ENDFOR
        
        RETURN(0)
    
    END ;Subroutine
    
    
    SUBROUTINE get_accessible_encntr_toggle(result)
        DECLARE concept_policies_req_concept = vc WITH constant("PowerChart_Framework"), protect
        DECLARE featuretoggleflag = i2 WITH noconstant(false), protect
        DECLARE chartaccessflag = i2 WITH noconstant(false), protect
        DECLARE featuretogglestat = i2 WITH noconstant(0), protect
        DECLARE chartaccessstat = i2 WITH noconstant(0), protect
        
        SET featuretogglestat = isfeaturetoggleon("urn:cerner:millennium:accessible-encounters-by-concept","urn:cerner:millennium",
                                                    featuretoggleflag)
        
        CALL uar_syscreatehandle(hsys,sysstat)
        
        IF (hsys > 0)
            SET slogtext = build2("get_accessible_encntr_toggle - featureToggleStat is ",build(featuretogglestat))
            
            CALL uar_sysevent(hsys,4,"pm_get_access_encntr_by_person",nullterm(slogtext))
            
            SET slogtext = build2("get_accessible_encntr_toggle - featureToggleFlag is ",build(featuretoggleflag))
         
            CALL uar_sysevent(hsys,4,"pm_get_access_encntr_by_person",nullterm(slogtext))
            CALL uar_sysdestroyhandle(hsys)
        ENDIF
        
        IF (    featuretogglestat=0
            AND featuretoggleflag=true)
            
            SET result = 1
            RETURN(0)
        ENDIF
        
        IF (featuretogglestat != 0)
            CALL uar_syscreatehandle(hsys,sysstat)
            IF (hsys > 0)
                SET slogtext = build("Feature toggle service returned failure status.")
                
                CALL uar_sysevent(hsys,1,"pm_get_access_encntr_by_person",nullterm(slogtext))
                CALL uar_sysdestroyhandle(hsys)
            ENDIF
        ENDIF
        
        
        SET chartaccessstat = ischartaccesson(concept_policies_req_concept,chartaccessflag)
        
        CALL uar_syscreatehandle(hsys,sysstat)
        
        IF (hsys > 0)
            SET slogtext = build2("get_accessible_encntr_toggle - chartAccessStat is ",build(chartaccessstat))
            
            CALL uar_sysevent(hsys,4,"pm_get_access_encntr_by_person",nullterm(slogtext))
            
            SET slogtext = build2("get_accessible_encntr_toggle - chartAccessFlag is ",build(chartaccessflag))
         
            CALL uar_sysevent(hsys,4,"pm_get_access_encntr_by_person",nullterm(slogtext))
            CALL uar_sysdestroyhandle(hsys)
        ENDIF
        
        IF (chartaccessstat != 0)
            RETURN(1)
        ENDIF
        
        IF (chartaccessflag=true)
            SET result = 1
        ENDIF
        
        RETURN(0)
    END ;Subroutine
    
    SUBROUTINE isfeaturetoggleon(togglename,systemidentifier,featuretoggleflag)
        DECLARE feature_toggle_req_number = i4 WITH constant(2030001), protect
        DECLARE toggle = vc WITH noconstant(""), protect
        DECLARE htransactionstatus = i4 WITH noconstant(0), protect
        DECLARE hfeatureflagmsg = i4 WITH noconstant(0), protect
        DECLARE hfeatureflagreq = i4 WITH noconstant(0), protect
        DECLARE hfeatureflagrep = i4 WITH noconstant(0), protect
        DECLARE rep2030001count = i4 WITH noconstant(0), protect
        DECLARE rep2030001successind = i2 WITH noconstant(0), protect
        
        SET hfeatureflagmsg = uar_srvselectmessage(feature_toggle_req_number)
        
        IF (hfeatureflagmsg=0)
            RETURN(0)
        ENDIF
        
        SET hfeatureflagreq = uar_srvcreaterequest(hfeatureflagmsg)
        
        IF (hfeatureflagreq=0)
            RETURN(0)
        ENDIF
        
        SET hfeatureflagrep = uar_srvcreatereply(hfeatureflagmsg)
        
        IF (hfeatureflagrep=0)
            RETURN(0)
        ENDIF
        
        SET stat = uar_srvsetstring(hfeatureflagreq,"system_identifier",nullterm(systemidentifier))
        SET stat = uar_srvsetshort(hfeatureflagreq,"ignore_overrides_ind",1)
        
        IF (uar_srvexecute(hfeatureflagmsg,hfeatureflagreq,hfeatureflagrep)=0)
            SET htransactionstatus = uar_srvgetstruct(hfeatureflagrep,"transaction_status")
            
            IF (htransactionstatus != 0)
                SET rep2030001successind = uar_srvgetshort(htransactionstatus,"success_ind")
            ELSE
                SET getaccessibleencntrtoggleerrormsg = build2("Failed to get transaction status from reply of ",
                                                                        build(feature_toggle_req_number))
            
                RETURN(1)
            ENDIF
         
            IF (rep2030001successind=1)
                IF (uar_srvgetitem(hfeatureflagrep,"feature_toggle_keys",0) > 0)
                    SET rep2030001count = uar_srvgetitemcount(hfeatureflagrep,"feature_toggle_keys")
           
                    FOR (loop = 0 TO (rep2030001count - 1))
                        SET toggle = uar_srvgetstringptr(uar_srvgetitem(hfeatureflagrep,"feature_toggle_keys",loop),"key")
            
                        IF (togglename=toggle)
                            SET featuretoggleflag = true
                            
                            RETURN(0)
                        ENDIF
                    ENDFOR
                ENDIF
            ELSE
                SET getaccessibleencntrtoggleerrormsg = build2("Failure for call to ",build(
                                                  feature_toggle_req_number),". Debug Msg =",uar_srvgetstringptr(htransactionstatus,
                                                  "debug_error_message"))
          
                RETURN(1)
            ENDIF
        ELSE
            SET getaccessibleencntrtoggleerrormsg = build2("Failure for call to ",build(feature_toggle_req_number))
         
            RETURN(1)
        ENDIF
        
        RETURN(0)
    END ;Subroutine
      
    SUBROUTINE ischartaccesson(concept,chartaccessflag)
        DECLARE concept_policies_req_number = i4 WITH constant(3202590), protect
        DECLARE htransactionstatus = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesreqstruct = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesmsg = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesreq = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesrep = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesstruct = i4 WITH noconstant(0), protect
        DECLARE rep3202590count = i4 WITH noconstant(0), protect
        DECLARE rep3202590successind = i2 WITH noconstant(0), protect
    
        SET hconceptpoliciesmsg = uar_srvselectmessage(concept_policies_req_number)
    
        IF (hconceptpoliciesmsg=0)
            RETURN(0)
        ENDIF
        
        SET hconceptpoliciesreq = uar_srvcreaterequest(hconceptpoliciesmsg)
        
        IF (hconceptpoliciesreq=0)
            RETURN(0)
        ENDIF
        
        SET hconceptpoliciesrep = uar_srvcreatereply(hconceptpoliciesmsg)
        
        IF (hconceptpoliciesrep=0)
            RETURN(0)
        ENDIF
        
        SET hconceptpoliciesreqstruct = uar_srvadditem(hconceptpoliciesreq,"concepts")
        
        IF (hconceptpoliciesreqstruct > 0)
            SET stat = uar_srvsetstring(hconceptpoliciesreqstruct,"concept",nullterm(concept))
                
            IF (uar_srvexecute(hconceptpoliciesmsg,hconceptpoliciesreq,hconceptpoliciesrep)=0)
                SET htransactionstatus = uar_srvgetstruct(hconceptpoliciesrep,"transaction_status")
                
                IF (htransactionstatus != 0)
                    SET rep3202590successind = uar_srvgetshort(htransactionstatus,"success_ind")
                ELSE
                    SET getaccessibleencntrtoggleerrormsg = build2(
                                               "Failed to get transaction status from reply of ",build(concept_policies_req_number))
                    
                    RETURN(1)
                ENDIF
          
                IF (rep3202590successind=1)
                    IF (uar_srvgetitem(hconceptpoliciesrep,"concept_policies_batch",0) > 0)
                        SET rep3202590count = uar_srvgetitemcount(hconceptpoliciesrep,"concept_policies_batch")
                    
                        FOR (loop = 0 TO (rep3202590count - 1))
                            SET hconceptpoliciesstruct = uar_srvgetstruct(uar_srvgetitem(hconceptpoliciesrep,
                                                                                          "concept_policies_batch",loop),"policies")
                            IF (hconceptpoliciesstruct > 0)
                                IF (uar_srvgetshort(hconceptpoliciesstruct,"chart_access_group_security_ind")=1)
                                    SET chartaccessflag = true
               
                                    RETURN(0)
                                ENDIF
                            ELSE
                                SET getaccessibleencntrtoggleerrormsg = build2("Failure for call to ",build(
                                                    concept_policies_req_number),build("Found an invalid hConceptPoliciesStruct : ",
                                                    hconceptpoliciesstruct))
              
                                RETURN(1)
                            ENDIF
                        ENDFOR
                    ENDIF
                ELSE
                    SET getaccessibleencntrtoggleerrormsg = build2("Failure for call to ",build(
                                                concept_policies_req_number),". Debug Msg =",uar_srvgetstringptr(htransactionstatus,
                                                "debug_error_message"))
                    
                    RETURN(1)
                ENDIF
            ELSE
                SET getaccessibleencntrtoggleerrormsg = build2("Failure for call to ",build(concept_policies_req_number))
          
                RETURN(1)
            ENDIF
        ELSE
            SET getaccessibleencntrtoggleerrormsg = build2("Failure for call to ",build(
                                            concept_policies_req_number),build("Found an invalid hConceptPoliciesReqStruct : ",
                                            hconceptpoliciesreqstruct))
            
            RETURN(1)
        ENDIF
        
        RETURN(0)
    END ;Subroutine


    RECORD encounters(
        1 encounter_ids[*]
            2 encounter_id = f8
    )
    
    
    DECLARE pregnancy_concept = vc WITH constant("PREGNANCY"), protect
    DECLARE womens_health_concept = vc WITH constant("WOMENS_HEALTH"), protect
    DECLARE getaccessibleencounters(encntrsrec=vc(ref),personid=f8(val),ispregcomp=i2(val,0)) = i4
    DECLARE getallencounters(encntrsrec=vc(ref),personid=f8(val)) = i4
    DECLARE getaccessibleencounterbypersonids(personids=vc(ref),encntrsrec=vc(ref),patientcount=i4(val,0)) = i4
    DECLARE ischartaccessenabled(chartaccessflag=i2(ref),ispregcomp=i2(val,0)) = i4
    
    SUBROUTINE ischartaccessenabled(chartaccessflag,ispregcomp)
        CALL log_message("In IsChartAccessEnabled()",log_level_debug)
        
        DECLARE begin_date_time = dq8 WITH constant(curtime3), private
        DECLARE concept_policies_req_num = i4 WITH constant(3202590), protect
        DECLARE htransactionstatus = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesreqstruct = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesmsg = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesreq = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesrep = i4 WITH noconstant(0), protect
        DECLARE hconceptpoliciesstruct = i4 WITH noconstant(0), protect
        DECLARE rep3202590count = i4 WITH noconstant(0), protect
        DECLARE rep3202590successind = i2 WITH noconstant(0), protect
        DECLARE rep3202590debugerrormsg = vc WITH noconstant(""), protect
        DECLARE concept = vc WITH noconstant(womens_health_concept), private
        
        IF (ispregcomp=1)
            SET concept = pregnancy_concept
        ENDIF
        
        SET hconceptpoliciesmsg = uar_srvselectmessage(concept_policies_req_num)
        
        IF (hconceptpoliciesmsg=0)
            RETURN(0)
        ENDIF
        
        SET hconceptpoliciesreq = uar_srvcreaterequest(hconceptpoliciesmsg)
        
        IF (hconceptpoliciesreq=0)
            RETURN(0)
        ENDIF
        
        SET hconceptpoliciesrep = uar_srvcreatereply(hconceptpoliciesmsg)
        IF (hconceptpoliciesrep=0)
            RETURN(0)
        ENDIF
        
        SET hconceptpoliciesreqstruct = uar_srvadditem(hconceptpoliciesreq,"concepts")
        IF (hconceptpoliciesreqstruct > 0)
            
            SET stat = uar_srvsetstring(hconceptpoliciesreqstruct,"concept",nullterm(concept))
            
            IF (uar_srvexecute(hconceptpoliciesmsg,hconceptpoliciesreq,hconceptpoliciesrep)=0)
                SET htransactionstatus = uar_srvgetstruct(hconceptpoliciesrep,"transaction_status")
                
                IF (htransactionstatus != 0)
                    SET rep3202590successind = uar_srvgetshort(htransactionstatus,"success_ind")
                    SET rep3202590debugerrormsg = uar_srvgetstringptr(htransactionstatus,"debug_error_message")
                ELSE
           
                    IF (validate(debug_ind,0)=1)
                        CALL echo(build2("Failed to get transaction status from reply of ",build(concept_policies_req_num)))
                    ENDIF
                
                    CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3 -
                                                                                    begin_date_time)/ 100.0)),log_level_debug)
           
                    RETURN(1)
                ENDIF
          
                IF (rep3202590successind=1)
                    IF (uar_srvgetitem(hconceptpoliciesrep,"concept_policies_batch",0) > 0)
                        SET rep3202590count = uar_srvgetitemcount(hconceptpoliciesrep,"concept_policies_batch")
                            
                        FOR (loop = 0 TO (rep3202590count - 1))
                            SET hconceptpoliciesstruct = uar_srvgetstruct(uar_srvgetitem(hconceptpoliciesrep,
                                                                                      "concept_policies_batch",loop),"policies")
                    
                            IF (hconceptpoliciesstruct > 0)
                                IF (uar_srvgetshort(hconceptpoliciesstruct,"chart_access_group_security_ind")=1)
                                    SET chartaccessflag = true
                                    CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3
                                                                                    - begin_date_time)/ 100.0)),log_level_debug)
                    
                                    RETURN(0)
                                ENDIF
                            ELSE
                                IF (validate(debug_ind,0)=1)
                                    CALL echo(build2("Failure for call to ",build(concept_policies_req_num),build(
                                        "Found an invalid hConceptPoliciesStruct : ",hconceptpoliciesstruct)))
                                ENDIF
                                
                                CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3
                                                                                        - begin_date_time)/ 100.0)),log_level_debug)
                    
                                RETURN(1)
                            ENDIF
                        ENDFOR
                    ENDIF
                ELSE
                    IF (validate(debug_ind,0)=1)
                        CALL echo(build2("Failure for call to ",build(concept_policies_req_num),". Debug Msg =",
                                                                     uar_srvgetstringptr(htransactionstatus,"debug_error_message")))
                    ENDIF
                
                    CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3 -
                                                                                          begin_date_time)/ 100.0)),log_level_debug)
                
                    RETURN(1)
                ENDIF
            ELSE
                IF (validate(debug_ind,0)=1)
                    CALL echo(build2("Failure for call to ",build(concept_policies_req_num)))
                ENDIF
                
                CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3 -
                                                                                    begin_date_time)/ 100.0)),log_level_debug)
            
                RETURN(1)
            ENDIF
        
        ELSE
            IF (validate(debug_ind,0)=1)
                CALL echo(build2("Failure for call to ",build(concept_policies_req_num),build(
                                                    "Found an invalid hConceptPoliciesReqStruct : ",hconceptpoliciesreqstruct)))
            ENDIF
         
            CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3 -
                                                                                          begin_date_time)/ 100.0)),log_level_debug)
            RETURN(1)
        ENDIF
        
        CALL log_message(build("Exit IsChartAccessEnabled(), Elapsed time in seconds:",((curtime3 -
                                                    begin_date_time)/ 100.0)),log_level_debug)
        RETURN(0)
    END ;Subroutine

    SUBROUTINE getallencounters(encntrsrec,personid)
        CALL log_message("In GetAllEncounters()",log_level_debug)
        
        DECLARE begin_date_time = dq8 WITH constant(curtime3), private
        
        IF (preg_org_sec_ind=0)
            CALL getallpregencounters(personid,encounters)
         
            SET stat = alterlist(encntrsrec->qual,0)
            SET stat = moverec(encounters->encounter_ids,encntrsrec->qual)
        ENDIF
        
        CALL log_message(build("Exit GetAllEncounters(), Elapsed time in seconds:",((curtime3 -
                                                                                    begin_date_time)/ 100.0)),log_level_debug)
    END ;Subroutine


    SUBROUTINE getaccessibleencounters(encntrsrec,personid,ispregcomp)
        CALL log_message("In GetAccessibleEncounters()",log_level_debug)
        
        DECLARE begin_date_time = dq8 WITH constant(curtime3), private
        DECLARE result = i4 WITH protect, noconstant(0)
        DECLARE concept = vc WITH noconstant(womens_health_concept), private
        
        IF (ispregcomp=1)
            SET concept = pregnancy_concept
        ENDIF
        
        CALL get_accessible_encntr_toggle(result)
        
        IF (result=1)
            SET stat = get_accessible_encntr_ids_by_person_id(personid,concept,0)
            IF (stat=0)
                SET stat = alterlist(encntrsrec->qual,0)
                SET stat = moverec(accessible_encntr_ids->accessible_encntrs,encntrsrec->qual)
                SET encntrsrec->cnt = accessible_encntr_ids->accessible_encntrs_cnt
            ENDIF
        
        ELSEIF (ispregcomp=1)
            CALL getallencounters(encntrsrec,personid)
        ENDIF
        
        CALL log_message(build("Exit GetAccessibleEncounters(), Elapsed time in seconds:",((curtime3 -
                                                                            begin_date_time)/ 100.0)),log_level_debug)
    END ;Subroutine


    SUBROUTINE getaccessibleencounterbypersonids(patientids,encntrsrec,patientcount)
        CALL log_message("In GetAccessibleEncounterByPersonIds()",log_level_debug)

        DECLARE begin_date_time = dq8 WITH constant(curtime3), private
        DECLARE pcount = i4 WITH noconstant(0), protect
        DECLARE encntrcount = i4 WITH protect, noconstant(0)
        DECLARE prevencntrcount = i4 WITH protect, noconstant(0)
        DECLARE currencntrcount = i4 WITH protect, noconstant(0)
        DECLARE result = i4 WITH protect, noconstant(0)

        IF (patientcount=0)
            SET patientcount = size(patientids->patient_list,5)
        ENDIF
        
        CALL get_accessible_encntr_toggle(result)
        IF (result=1)
            FOR (pcount = 1 TO patientcount)
                SET stat = get_accessible_encntr_ids_by_person_id(patientids->patient_list[pcount].patient_id,pregnancy_concept,0)
        
                IF (stat=0)
                    SET encntrcount = accessible_encntr_ids->accessible_encntrs_cnt
                    SET prevencntrcount = currencntrcount
                    SET currencntrcount = (currencntrcount+ encntrcount)
                    SET stat = alterlist(encntrsrec->qual,currencntrcount)
                    SET encntrsrec->cnt = currencntrcount
           
                    FOR (ecount = 1 TO encntrcount)
                        SET encntrsrec->qual[(ecount+ prevencntrcount)].value = accessible_encntr_ids->
                                                                                     accessible_encntrs[ecount].accessible_encntr_id
                    ENDFOR
                ENDIF
            ENDFOR
        ENDIF
        
        CALL log_message(build("Exit GetAccessibleEncounterByPersonIds(), Elapsed time in seconds:",((
                                                                              curtime3 - begin_date_time)/ 100.0)),log_level_debug)
    END ;Subroutine


    CALL ischartaccessenabled(cao_flag)
    IF (cao_flag=1)
        CALL getaccessibleencounters(encntr_list,person_id)
    ENDIF

END ;Subroutine












IF (validate(i18nuar_def,999)=999)
    CALL echo("Declaring i18nuar_def")
    
    DECLARE i18nuar_def = i2 WITH persist
 
    SET i18nuar_def = 1
 
    DECLARE uar_i18nlocalizationinit(p1=i4,p2=vc,p3=vc,p4=f8) = i4 WITH persist
    DECLARE uar_i18ngetmessage(p1=i4,p2=vc,p3=vc) = vc WITH persist
    DECLARE uar_i18nbuildmessage() = vc WITH persist
    DECLARE uar_i18ngethijridate(imonth=i2(val),iday=i2(val),iyear=i2(val),sdateformattype=vc(ref)) =
                                    c50 WITH image_axp = "shri18nuar", image_aix = "libi18n_locale.a(libi18n_locale.o)", uar =
                                    "uar_i18nGetHijriDate",
                                    persist
    DECLARE uar_i18nbuildfullformatname(sfirst=vc(ref),slast=vc(ref),smiddle=vc(ref),sdegree=vc(ref),
                                    stitle=vc(ref),
                                    sprefix=vc(ref),ssuffix=vc(ref),sinitials=vc(ref),soriginal=vc(ref)) = c250 WITH image_axp =
                                "shri18nuar", image_aix = "libi18n_locale.a(libi18n_locale.o)", uar = "i18nBuildFullFormatName",
                                persist
    DECLARE uar_i18ngetarabictime(ctime=vc(ref)) = c20 WITH image_axp = "shri18nuar", image_aix =
                                                            "libi18n_locale.a(libi18n_locale.o)", uar = "i18n_GetArabicTime",
                                                            persist
ENDIF

DECLARE edd_id = f8
DECLARE current_ega_days = f8
DECLARE ega_found = i4 WITH public, noconstant(0)
DECLARE ispatientdelivered(null) = i2 WITH protect

FREE RECORD dcp_request
RECORD dcp_request(
    1 provider_id = f8
    1 position_cd = f8
    1 cal_ega_multiple_gest = i2
    1 patient_list[*]
        2 patient_id = f8
        2 encntr_id = f8
    1 provider_list[*]
        2 patient_id = f8
        2 encntr_id = f8
        2 provider_patient_reltn_cd = f8
    1 pregnancy_list[*]
        2 pregnancy_id = f8
    1 multiple_egas = i2
)

SET stat = alterlist(dcp_request->patient_list,1)
SET dcp_request->patient_list[1].patient_id = request->person[1].person_id
SET dcp_request->cal_ega_multiple_gest = 1
SET dcp_request->multiple_egas = 1
SET dcp_request->provider_id = reqinfo->updt_id
SET dcp_request->position_cd = reqinfo->position_cd

EXECUTE dcp_get_final_ega  WITH replace("REQUEST",dcp_request), replace("REPLY",dcp_reply)

SET modify = nopredeclare

IF ((dcp_reply->gestation_info[1].edd_id > 0.0))
    SELECT INTO "nl:"
    
      FROM pregnancy_estimate pe
  
      PLAN (pe
  
     WHERE (pe.pregnancy_estimate_id=dcp_reply->gestation_info[1].edd_id))
  
    DETAIL
        ega_found = 1
   
        IF ((dcp_reply->gestation_info[1].current_gest_age > 0))
            current_ega_days = dcp_reply->gestation_info[1].current_gest_age
        ELSEIF ((dcp_reply->gestation_info[1].gest_age_at_delivery > 0))
            current_ega_days = dcp_reply->gestation_info[1].gest_age_at_delivery
        ENDIF
   
        edd_id = pe.pregnancy_estimate_id
    WITH nocounter
    ;end select
ENDIF

SUBROUTINE ispatientdelivered(null)
    DECLARE patient_delivered_ind = i2 WITH protect, noconstant(0)
    IF (    (dcp_reply->gestation_info[1].delivered_ind=1)
        AND (dcp_reply->gestation_info[1].partial_delivery_ind=0)
        AND size(dcp_reply->gestation_info[1].dynamic_label,5) > 0)
   
        SET patient_delivered_ind = 1
    ENDIF
  
    RETURN(patient_delivered_ind)
END ;Subroutine


IF ( NOT (validate(i18nhandle)))
    DECLARE i18nhandle = i4 WITH protect, noconstant(0)
ENDIF

SET stat = uar_i18nlocalizationinit(i18nhandle,curprog,"",curcclrev)
DECLARE stand_alone_ind = i4 WITH protect, noconstant(0)

IF ( NOT (validate(request->person[1].pregnancy_list)))
    SET stand_alone_ind = 1
ENDIF

IF (validate(debug_ind,0)=1)
    CALL echo(build("stand_alone_ind:",stand_alone_ind))
ENDIF

FREE SET gest_age
RECORD gest_age(
    1 edd_calc_cnt = i4
    1 ega_current = vc
    1 edd_calc[*]
        2 confirmation = vc
        2 status = vc
        2 ega_current = vc
        2 method = vc
        2 description = vc
        2 documented_by = vc
        2 edd_final = vc
        2 entry_date = vc
        2 method_date = vc
        2 comments = vc
        2 comments_wrapped[*]
            3 wrap_text = vc
)

FREE RECORD pt
RECORD pt(
    1 line_cnt = i2
    1 lns[*]
        2 line = vc
)
IF (validate(pt_info)=0)
    RECORD pt_info(
        1 age = vc
        1 gravida = vc
        1 para_full_term = vc
        1 para_premature = vc
        1 para_abortions = vc
        1 para = vc
        1 final_edd = vc
        1 mod_ind = vc
        1 ega = vc
    )
ENDIF

DECLARE cki_lmp                 = f8 WITH protect, constant(uar_get_code_by_cki("CKI.CODEVALUE!12676043"))
DECLARE cckideldttm             = vc WITH protect, constant("CERNER!ASYr9AEYvUr1YoPTCqIGfQ")
DECLARE dqdel_dt_tm             = dq8
DECLARE del_ind                 = i2 WITH protect, noconstant(0)
DECLARE cnodata                 = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap1","No EGA/EDD calculations have been recorded"))
DECLARE captions_title          = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap2","Gestational Age (EGA) and EDD"))
DECLARE captions_edd_final      = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap3","EDD:"))
DECLARE captions_ega            = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap4","EGA*:"))
DECLARE captions_status         = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap5","Type:"))
DECLARE captions_method_dt      = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap6","Method Date:"))
DECLARE captions_method         = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap7","Method:"))
DECLARE captions_confirmation   = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap8","Confirmation:"))
DECLARE captions_description    = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap9","Description:"))
DECLARE captions_comments       = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap10","Comments:"))
DECLARE captions_documented_by  = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap11","Entered by:"))
DECLARE captions_other_ega      = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap16","EGA (At Entry):"))
DECLARE captions_other_edd_head = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap18","Other EDD Calculations for this Pregnancy:"))
DECLARE captions_no_other       = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap19","No additional EDD calculations have been recorded for this pregnancy"))
DECLARE con                     = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap20"," on"))
DECLARE cweeks                  = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap21"," weeks"))
DECLARE cdays                   = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap22"," days"))
DECLARE c1week                  = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap23","1 week"))
DECLARE c1day                   = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap24","1 day"))
DECLARE cnonauthoritative       = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap25","Non-Authoritative"))
DECLARE cinitial                = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap26","Initial"))
DECLARE cauthoritative          = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap27","Authoritative"))
DECLARE cfinal                  = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap28","Final"))
DECLARE cinitial_final          = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap29","Initial / Final"))
DECLARE cnormalamt              = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap30"," Normal Amount/Duration"))
DECLARE cabnormalamt            = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap31"," Abnormal Amount/Duration"))
DECLARE cdateapproximate        = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap32"," Date Approximate"))
DECLARE cdatedefinite           = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap33"," Date Definite"))
DECLARE cdateunknown            = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap34"," Date Unknown"))
DECLARE cdisclaimer             = vc WITH protect, constant(uar_i18ngetmessage(i18nhandle,"cap35","     * Note: EGA calculated as of"))
DECLARE wk                      = vc WITH public, noconstant("")
DECLARE dy                      = vc WITH public, noconstant("")
DECLARE space                   = c6 WITH protect, constant(" ")
DECLARE space_comments          = c25 WITH protect, constant(" ")
DECLARE max_length              = i4 WITH protect, noconstant(90)
DECLARE patient_delivered_ind   = i2 WITH public, noconstant(0)

IF (ispatientdelivered(null))
    IF ((dcp_reply->gestation_info[1].gest_age_at_delivery <= 0))
        SET pt_info->ega = snot_documented
    ELSEIF ((dcp_reply->gestation_info[1].gest_age_at_delivery < 7))
        SET pt_info->ega = build(dcp_reply->gestation_info[1].gest_age_at_delivery,cdays)
    ELSEIF ((dcp_reply->gestation_info[1].gest_age_at_delivery=7))
        SET pt_info->ega = c1week
    ELSEIF (mod(dcp_reply->gestation_info[1].gest_age_at_delivery,7)=0)
        SET pt_info->ega = build((dcp_reply->gestation_info[1].gest_age_at_delivery/ 7),cweeks)
    ELSE
        IF (    ((dcp_reply->gestation_info[1].gest_age_at_delivery/ 7) >= 1)
            AND ((dcp_reply->gestation_info[1].gest_age_at_delivery/ 7) < 2))
            SET wk = c1week
        ELSE
            SET wk = build(trim(cnvtstring((dcp_reply->gestation_info[1].gest_age_at_delivery/ 7))),cweeks)
        ENDIF
        
        IF (mod(dcp_reply->gestation_info[1].gest_age_at_delivery,7)=1)
            SET dy = c1day
        ELSE
            SET dy = build(trim(cnvtstring(mod(dcp_reply->gestation_info[1].gest_age_at_delivery,7))),cdays)
        ENDIF
  
        SET pt_info->ega = concat(wk," ",dy)
    ENDIF
ELSE
    IF ((dcp_reply->gestation_info[1].current_gest_age <= 0))
        SET pt_info->ega = snot_documented
    ELSEIF ((dcp_reply->gestation_info[1].current_gest_age < 7))
        SET pt_info->ega = build(dcp_reply->gestation_info[1].current_gest_age,cdays)
    ELSEIF ((dcp_reply->gestation_info[1].current_gest_age=7))
        SET pt_info->ega = c1week
    ELSEIF (mod(dcp_reply->gestation_info[1].current_gest_age,7)=0)
        SET pt_info->ega = build((dcp_reply->gestation_info[1].current_gest_age/ 7),cweeks)
    ELSE
        IF (((dcp_reply->gestation_info[1].current_gest_age/ 7) >= 1)
            AND ((dcp_reply->gestation_info[1].current_gest_age/ 7) < 2))
            
            SET wk = c1week
        ELSE
            SET wk = build(trim(cnvtstring((dcp_reply->gestation_info[1].current_gest_age/ 7))),cweeks)
        ENDIF
  
    IF (mod(dcp_reply->gestation_info[1].current_gest_age,7)=1)
        SET dy = c1day
    ELSE
        SET dy = build(trim(cnvtstring(mod(dcp_reply->gestation_info[1].current_gest_age,7))),cdays)
    ENDIF
        SET pt_info->ega = concat(wk," ",dy)
    ENDIF
ENDIF

SELECT
    IF (honor_org_security_flag=1)
        PLAN (pi
         WHERE (pi.person_id=request->person[1].person_id)
           AND pi.active_ind=1
           AND pi.historical_ind=0
           AND pi.preg_end_dt_tm=cnvtdatetime("31-DEC-2100")
           AND expand(os_idx,1,size(preg_sec_orgs->qual,5),pi.organization_id,preg_sec_orgs->qual[os_idx].org_id))
   
        JOIN (pe
         WHERE pe.pregnancy_id=pi.pregnancy_id
           AND pe.active_ind=1
           AND pe.entered_dt_tm != null)
        
        JOIN (pr
         WHERE pr.person_id=pe.author_id)
        
        JOIN (lt
         WHERE lt.parent_entity_name=outerjoin("PREGNANCY_ESTIMATE")
          AND lt.parent_entity_id=outerjoin(pe.pregnancy_estimate_id)
          AND lt.active_ind=outerjoin(1))
    ELSE
  
        PLAN (pi
         WHERE (pi.person_id=request->person[1].person_id)
           AND pi.active_ind=1
           AND pi.historical_ind=0
           AND pi.preg_end_dt_tm=cnvtdatetime("31-DEC-2100"))
        
        JOIN (pe
         WHERE pe.pregnancy_id=pi.pregnancy_id
           AND pe.active_ind=1
           AND pe.entered_dt_tm != null)
        
        JOIN (pr
         WHERE pr.person_id=pe.author_id)
        
        JOIN (lt
         WHERE lt.parent_entity_name=outerjoin("PREGNANCY_ESTIMATE")
           AND lt.parent_entity_id=outerjoin(pe.pregnancy_estimate_id)
           AND lt.active_ind=outerjoin(1))
    ENDIF
    
    INTO "nl:"
          confirmation = uar_get_code_display(pe.confirmation_cd) 
        , status = IF     (pe.status_flag=0) cnonauthoritative
                   ELSEIF (pe.status_flag=1) cinitial
                   ELSEIF (pe.status_flag=2) cauthoritative
                   ELSEIF (pe.status_flag=3) cfinal
                   ELSEIF (pe.status_flag=4) cinitial_final
                   ELSE " "
                   ENDIF
        , edd_final_dt = format(pe.est_delivery_dt_tm,"@SHORTDATE4YR")
        , sort = IF (pe.status_flag=3) 1
                 ELSEIF (pe.status_flag=2) 2
                 ELSEIF (pe.status_flag=1) 3
                 ELSE 4
                 ENDIF
        , ega = IF (mod(round(pe.est_gest_age_days,0),7)=0) 
                    build(cnvtint(round((pe.est_gest_age_days/ 7),0)),cweeks)
                ELSE concat(trim(cnvtstring(cnvtint((pe.est_gest_age_days/ 7)))),cweeks," ",trim(cnvtstring(mod(pe
                     .est_gest_age_days,7))),cdays)
                ENDIF
        , method = trim(uar_get_code_display(pe.method_cd))
        , docby = nullterm(pr.name_full_formatted)
    
    FROM pregnancy_instance pi,
     pregnancy_estimate pe,
     prsnl pr,
     long_text lt
    
    ORDER BY pe.status_flag DESC, pe.entered_dt_tm DESC
    DETAIL
          gest_age->edd_calc_cnt = (gest_age->edd_calc_cnt+ 1)
        , stat = alterlist(gest_age->edd_calc,gest_age->edd_calc_cnt)
        , gest_age->edd_calc[gest_age->edd_calc_cnt].confirmation  = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].status        = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].ega_current   = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].method        = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].documented_by = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].edd_final     = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].entry_date    = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].method_date   = snot_documented
        , gest_age->edd_calc[gest_age->edd_calc_cnt].comments      = snot_documented
        
        , mod_value = pe.descriptor_flag
        
        , gest_age->edd_calc[gest_age->edd_calc_cnt].edd_final    = edd_final_dt
        , gest_age->edd_calc[gest_age->edd_calc_cnt].confirmation = confirmation
        , gest_age->edd_calc[gest_age->edd_calc_cnt].status       = status
        , gest_age->edd_calc[gest_age->edd_calc_cnt].ega_current  = ega
        , gest_age->edd_calc[gest_age->edd_calc_cnt].method       = method
        
        IF (pe.descriptor_cd > 0)
            gest_age->edd_calc[gest_age->edd_calc_cnt].description = uar_get_code_display(pe.descriptor_cd)
        ELSEIF (pe.descriptor_flag > 0)
            IF (pe.descriptor_txt > " ")
                gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                        concat(gest_age->edd_calc[gest_age->edd_calc_cnt].description,trim(pe.descriptor_txt),", ")
            ENDIF
            
            IF (band(1,pe.descriptor_flag) > 0)
                gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                        concat(gest_age->edd_calc[gest_age->edd_calc_cnt].description,cnormalamt,", ")
            ENDIF
   
            IF (band(2,pe.descriptor_flag) > 0)
                gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                        concat(gest_age->edd_calc[gest_age->edd_calc_cnt].description,cabnormalamt,", ")
            ENDIF
   
            IF (band(4,pe.descriptor_flag) > 0)
                gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                            concat(gest_age->edd_calc[gest_age->edd_calc_cnt].description,cdateapproximate,", ")
            ENDIF
            IF (band(8,pe.descriptor_flag) > 0)
                gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                            concat(gest_age->edd_calc[gest_age->edd_calc_cnt].description,cdatedefinite,", ")
            ENDIF
            IF (band(16,pe.descriptor_flag) > 0)
                gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                            concat(gest_age->edd_calc[gest_age->edd_calc_cnt].description,cdateunknown,", ")
            ENDIF
            IF (size(gest_age->edd_calc[gest_age->edd_calc_cnt].description) > 0)
                  gest_age->edd_calc[gest_age->edd_calc_cnt].description = 
                                          substring(1,(size(gest_age->edd_calc[gest_age->edd_calc_cnt].description) - 1)
                , gest_age->edd_calc[gest_age->edd_calc_cnt].description)
            ENDIF
        ELSE
            gest_age->edd_calc[gest_age->edd_calc_cnt].description = snot_documented
        ENDIF
  
          gest_age->edd_calc[gest_age->edd_calc_cnt].documented_by = docby
        , gest_age->edd_calc[gest_age->edd_calc_cnt].entry_date = format(pe.entered_dt_tm,"@SHORTDATE4YR")
        , gest_age->edd_calc[gest_age->edd_calc_cnt].method_date = format(pe.method_dt_tm,"@SHORTDATE4YR")
  
        IF (lt.long_text_id > 0)
            gest_age->edd_calc[gest_age->edd_calc_cnt].comments = lt.long_text
        ENDIF
WITH nocounter
;end select

IF (validate(debug_ind,0)=1)
    CALL echorecord(gest_age)
ENDIF

IF (stand_alone_ind=1)
    SET reply->text = concat(reply->text,rhead,rhead_colors1,rhead_colors2,rhead_colors3)
    
    IF (chart_access_flag=1)
        SET reply->text = concat(reply->text,rtab,wu,whcaosecuritydisclaim,wr,reol)
    ELSEIF (honor_org_security_flag=1)
        SET reply->text = concat(reply->text,rtab,wu,whsecuritydisclaim,wr,reol)
    ENDIF
ENDIF



SET reply->text = concat( reply->text, "\tx1450\tx3200\tx5000\tx6500"
                        , rsechead, colornavy, captions_title
                        , wsd, colorgrey     , cdisclaimer, " ", format(cnvtdatetime(curdate,curtime3),"@SHORTDATE4YR")
                        , wr, reol)

IF (size(gest_age->edd_calc,5)=0)
    SET reply->text = concat(reply->text, rpard, rtabstopnd, wr, reol, rtab, cnodata, reol)
    GO TO exit_script
ELSE
    SET reply->text = concat(reply->text,reol)
    FOR (i = 1 TO size(gest_age->edd_calc,5))
        SET pt->line_cnt = 0
        SET stat = alterlist(pt->lns,0)
        
        EXECUTE dcp_parse_text value(gest_age->edd_calc[i].comments), value(max_length)
        
        SET stat = alterlist(gest_age->edd_calc[i].comments_wrapped,pt->line_cnt)
        
        FOR (wrapcnt = 1 TO pt->line_cnt)
            SET gest_age->edd_calc[i].comments_wrapped[wrapcnt].wrap_text = pt->lns[wrapcnt].line
        ENDFOR
        
        FOR (z = 1 TO size(gest_age->edd_calc[i].comments_wrapped,5))
            IF (z=1)
                SET gest_age->edd_calc[i].comments = gest_age->edd_calc[i].comments_wrapped[z].wrap_text
            ELSE
                SET gest_age->edd_calc[i].comments = concat(gest_age->edd_calc[i].comments,reol,space_comments,
                                                            gest_age->edd_calc[i].comments_wrapped[z].wrap_text)
            ENDIF
        ENDFOR
    ENDFOR
    ;001 This is changing to pull out sections if we are no-data.
    /*
    SET reply->text = concat(reply->text
                            , wr, colorgrey, captions_edd_final    , " ", wr, gest_age->edd_calc[1].edd_final
            , rtab          , wr, colorgrey, captions_ega          , " ", wr, pt_info->ega
            , "            ", wr, colorgrey, captions_status       , " ", wr, gest_age->edd_calc[1].status
            , rtab          , wr, colorgrey, captions_method_dt    , " ", wr, gest_age->edd_calc[1].method_date
                                                                   
                            , reol                                                 
                            , reol                                                 
                                                                   
            , space         , wr, colorgrey, captions_method       , " ", wr, gest_age->edd_calc[1].method,wsd,colorgrey
                                                                            , " (", gest_age->edd_calc[1].method_date, ")"
                            , wr                                                   
                            , reol                                                 
                                                                   
            , space         , wr, colorgrey, captions_confirmation , " ", wr, gest_age->edd_calc[1].confirmation
                            , reol                                                 
                                                                   
            , space         , wr, colorgrey, captions_description  , " ", wr, gest_age->edd_calc[1].description
                            , reol                                                 
                                                                   
            , space         , wr, colorgrey, captions_comments     , " ", wr, gest_age->edd_calc[1].comments
                            , reol
            
            , space         , wr, colorgrey, captions_documented_by, " ", wr, gest_age->edd_calc[1].documented_by
                                                                            , con, " "
                                                                            , gest_age->edd_calc[1].entry_date," "
                            ,reol
                            ,reol
                            , wu,            captions_other_edd_head, wr
                            )
    */
    
    SET reply->text = concat(reply->text
                            , wr, colorgrey, captions_edd_final    , " ", wr, gest_age->edd_calc[1].edd_final
            , rtab          , wr, colorgrey, captions_ega          , " ", wr, pt_info->ega
            , "            ", wr, colorgrey, captions_status       , " ", wr, gest_age->edd_calc[1].status
            , rtab          , wr, colorgrey, captions_method_dt    , " ", wr, gest_age->edd_calc[1].method_date
                                                                   
                            , reol                                                 
                            , reol                                                 
                            )
                            
    
    
    if(gest_age->edd_calc[1].method != snot_documented)
        SET reply->text = concat(reply->text
                , space         , wr, colorgrey, captions_method       , " ", wr, gest_age->edd_calc[1].method,wsd,colorgrey
                                                                                , " (", gest_age->edd_calc[1].method_date, ")"
                                , wr                                                   
                                , reol
                                )
    endif
    
    if(gest_age->edd_calc[1].confirmation != snot_documented)
        SET reply->text = concat(reply->text    
                , space         , wr, colorgrey, captions_confirmation , " ", wr, gest_age->edd_calc[1].confirmation
                                , reol   
                                )
    endif
    
    if(gest_age->edd_calc[1].description != snot_documented)
        SET reply->text = concat(reply->text    
                , space         , wr, colorgrey, captions_description  , " ", wr, gest_age->edd_calc[1].description
                                , reol
                                )
    endif
    
    if(gest_age->edd_calc[1].comments != snot_documented)
        SET reply->text = concat(reply->text    
                , space         , wr, colorgrey, captions_comments     , " ", wr, gest_age->edd_calc[1].comments
                                , reol
                                )
    endif
    
    if(gest_age->edd_calc[1].documented_by != snot_documented)
        SET reply->text = concat(reply->text    
                , space         , wr, colorgrey, captions_documented_by, " ", wr, gest_age->edd_calc[1].documented_by
                                                                            , con, " "
                                                                            , gest_age->edd_calc[1].entry_date," "
                                ,reol
                                )
    endif
    
ENDIF


;001 This is changing to pull out sections if we are no-data.
/*
IF (size(gest_age->edd_calc,5) > 1)
    FOR (i = 2 TO size(gest_age->edd_calc,5))
        SET reply->text = concat(reply->text
                       , reol, reol
                                   , space, wr, colorgrey, captions_method       , " ", wr, gest_age->edd_calc[i].method
                             , reol, space, wr, colorgrey, captions_method_dt    , " ", wr, gest_age->edd_calc[i].method_date
                             , reol, space, wr, colorgrey, captions_edd_final    , " ", wr, gest_age->edd_calc[i].edd_final
                             , reol, space, wr, colorgrey, captions_other_ega    , " ", wr, gest_age->edd_calc[i].ega_current
                             , reol, space, wr, colorgrey, captions_status       , " ", wr, gest_age->edd_calc[i].status
                             , reol, space, wr, colorgrey, captions_comments     , " ", wr, gest_age->edd_calc[i].comments
                             , reol, space, wr, colorgrey, captions_documented_by, " ", wr, gest_age->edd_calc[i].documented_by
                                                                                         , con, " "
                                                                                         , gest_age->edd_calc[i].entry_date
                                                                                , " "
                                )
    ENDFOR
*/
IF (size(gest_age->edd_calc,5) > 1)
    
    SET reply->text = concat(reply->text    
                            ,reol
                            , wu,            captions_other_edd_head, wr
                            )

    FOR (i = 2 TO size(gest_age->edd_calc,5))
        SET reply->text = concat(reply->text , reol)
        
        if(gest_age->edd_calc[i].method != snot_documented)
            SET reply->text = concat(reply->text    
                       , reol, space, wr, colorgrey, captions_method       , " ", wr, gest_age->edd_calc[i].method
                                    )
        endif
        
        if(gest_age->edd_calc[i].method_date != snot_documented)
            SET reply->text = concat(reply->text    
                       , reol, space, wr, colorgrey, captions_method_dt       , " ", wr, gest_age->edd_calc[i].method_date
                                    )
        endif
        
        if(gest_age->edd_calc[i].edd_final != snot_documented)
            SET reply->text = concat(reply->text    
                       , reol, space, wr, colorgrey, captions_edd_final       , " ", wr, gest_age->edd_calc[i].edd_final
                                    )
        endif
        
        if(gest_age->edd_calc[i].ega_current != snot_documented)
            SET reply->text = concat(reply->text    
                       , reol, space, wr, colorgrey, captions_other_ega       , " ", wr, gest_age->edd_calc[i].ega_current
                                    )
        endif
        
        if(gest_age->edd_calc[i].status != snot_documented)
            SET reply->text = concat(reply->text    
                       , reol, space, wr, colorgrey, captions_status       , " ", wr, gest_age->edd_calc[i].status
                                    )
        endif
        
        if(gest_age->edd_calc[i].comments != snot_documented)
            SET reply->text = concat(reply->text    
                       , reol, space, wr, colorgrey, captions_comments       , " ", wr, gest_age->edd_calc[i].comments
                                    )
        endif
        
        if(gest_age->edd_calc[i].documented_by != snot_documented)
            SET reply->text = concat(reply->text    
                             , reol, space, wr, colorgrey, captions_documented_by, " ", wr, gest_age->edd_calc[i].documented_by
                                                                                         , con, " "
                                                                                         , gest_age->edd_calc[i].entry_date
                                                                                , " "
                                    )
        endif
    ENDFOR
ELSE
    SET reply->text = concat(reply->text,reol,wr,space,colorgrey,captions_no_other,reol)
    GO TO exit_script
ENDIF

SET reply->text = concat(reply->text,rpard)
SET reply->text = concat(reply->text,rpard,reol)

GO TO exit_script


#no_data
IF (    (request->person_cnt > 0)
    AND (request->visit_cnt > 0)
    AND (request->prsnl_cnt > 0))
    SET reply->text = concat(reply->text,rhead,wr,cpnodata,reol)

ELSE
    SET reply->text = concat(reply->text,rhead,wbuf26,cpgatitle,wr,reol,reol,cpnodata,reol)
ENDIF
GO TO exit_script


#exit_script
IF (stand_alone_ind=1)
    SET reply->text = concat(reply->text,rtfeof)
ENDIF
SET script_version = "000"

call echorecord(gest_age)

END 
GO
