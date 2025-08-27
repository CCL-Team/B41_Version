/***************************************************************************
  Program Title:    Oncology CoC 2023 Report
  Object name:      14_onc_coc_report
  Source file:      14_onc_coc_report.prg
  Purpose:          The purpose of this report is total the number unique patients that were seen at a location
                    and/or by a physician.  Unique being if they had multiple qualifying visits, they only count once.

  Tables read:

  Executed from:    DA2

  Special Notes:    Code Review Completed
***************************************************************************
                        MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst                MCGA     Comment
--- ---------- ---------------------- -------- -----------------------------
001 10/11/2023 Asha Patil             239568   Initial Release
002 10/03/2024 Vamsi                  349971   Add a new referral order to the "CoC Report" selection items for Referral to
                                               MedStar Genetic Counseling Oncology.Updates to the inclusion criteria for the 
                                               Social Work referral to include the 
                                               Referral to Medstar Social Work Oncology Order and update report to pull 
                                               in new column
003 06/11/2025 Simeon Akinuslie       353933   Add Services Desired column to CoC Quality Report, 
                                               backup = 14_onc_coc_report_bu06112025.prg
004 08/14/2025 Michael Mayes          350478   Adding Advance Directives
*************END OF ALL MODCONTROL BLOCKS* *******************************/

  drop program 14_onc_coc_report:dba go
create program 14_onc_coc_report:dba

prompt
      "Output to File/Printer/MINE"  = "MINE"           ;* Enter or select the printer or file name to send this report to
    , "Select Visit Begin Date:"     = "CURDATE"
    , "Select Visit End Date:"       = "CURDATE"
    , "Select Oncology Location(s):" = VALUE(0.0)
    , "Coc Report:"                  = 0

with OUTDEV, BEG_DT, END_DT, ONCLOC, coc_MODE
;*************************************************************************
; ADDITIONAL RECORD STRUCTURE DEFINITIONS
;*************************************************************************

free record results
record results(
  1 data_cnt            = i4
  1 data[*]
    2 filters           = vc
    2 encntr_id         = f8
    2 person_id         = f8
    2 location          = f8
    2 facility          = f8
    2 visit_dt          = dq8
    2 name              = c100
    2 dob               = vc
    2 fin               = c30
    2 mrn               = c30
    2 diag_code         = vc
    2 diag_desc         = vc
    2 order_name        = vc
    2 ordering_provider = vc
    2 date_of_service   = vc
    2 order_id          = f8
    2 service_desire    = vc
)

declare oc_catalog_parser = vc

;"Referral to MedStar Palliative Care"
if    ($coc_mode = 0) set oc_catalog_parser = "o.catalog_cd = 1591969303.00" 

;"Referral to MedStar Oncology Dietician/Nutritionist"
elseif($coc_mode = 1) set oc_catalog_parser = "o.catalog_cd = 3338434387.00" 

;"Referral to MedStar Social Worker/Clinical", "Referral to MedStar Oncology Social Worker")
elseif($coc_mode = 2) set oc_catalog_parser = "o.catalog_cd = 3338566387.00"

elseif($coc_mode = 3) set oc_catalog_parser = ""

elseif($coc_mode = 4) set oc_catalog_parser = ""

elseif($coc_mode = 5) set oc_catalog_parser = ""

;"Referral to MedStar Genetic Counseling Oncology"
elseif($coc_mode = 6) set oc_catalog_parser = "o.catalog_cd = 2917342103.00" 

;"Referral to MedStar Cancer Survivorship"
elseif($coc_mode = 7) set oc_catalog_parser = "o.catalog_cd = 5616367069.00" 

;004->
;Advance Directive path
elseif($coc_mode = 8) set oc_catalog_parser = "" 
;004<-
endif

; 5616367069.00    249926603.00 Referral to MedStar Cancer Survivorship
; 2917342103.00    249926603.00 Referral to MedStar Genetic Counseling Oncology
; 833738303.00     249926603.00 Referral to MedStar Social Worker/Clinical
; 3338566387.00    249926603.00 Referral to MedStar Oncology Social Worker
; 3338434387.00    249926603.00 Referral to MedStar Oncology Dietician/Nutritionist
; 1591969303.00    249926603.00 Referral to MedStar Palliative Care

if($coc_mode in (0, 1, 2, 6, 7))
    call echo(build2("$coc_mode:", $coc_mode, " Parser: ",oc_catalog_parser," oncloc:", $oncloc))
    
    select into "nl:"
    
      from encounter e
         , orders o
         , person p
         , order_action oa
         , prsnl pr
      plan e
       where e.reg_dt_tm between cnvtdatetime(cnvtdate($beg_dt), 0) and cnvtdatetime(cnvtdate($end_dt), 2359)
         and (0 = $oncloc or e.loc_nurse_unit_cd = $oncloc)
         and e.active_ind = 1
  
      join o
       where o.encntr_id = e.encntr_id
         and o.catalog_type_cd = 249926603.00
         and parser(oc_catalog_parser)
         and o.order_status_cd in (2543.00, 2550.00)
  
      join p
       where p.person_id = e.person_id
  
      join oa
       where o.order_id = oa.order_id
         and oa.action_type_cd = 2534.00
  
      join pr
       where pr.person_id = oa.order_provider_id
    
    order by o.order_id
    
    head report
        cnt = 0
    
    head o.order_id
        cnt = cnt + 1
        
        call echo(o.order_id)
        
        if(cnt > size(results->data,5))
            stat = alterlist(results->data, cnt+10)
        endif
        
        results->data[cnt].person_id         = e.person_id
        results->data[cnt].encntr_id         = e.encntr_id
        results->data[cnt].name              = trim(p.name_full_formatted)
        results->data[cnt].dob               = datebirthformat(p.birth_dt_tm,p.birth_tz,p.birth_prec_flag,"mm/dd/yyyy;;Q")
        results->data[cnt].date_of_service   = format(e.reg_dt_tm, "mm/dd/yyyy;;Q")
        results->data[cnt].order_name        = trim(o.order_mnemonic)
        results->data[cnt].ordering_provider = pr.name_full_formatted
        results->data[cnt].order_id          = o.order_id
  
    foot report
        stat = alterlist(results->data,cnt)
    with nocounter

    if(size(results->data,5)>0)
        ;------------------------------------------------------------------------------------------------------------------------
        ;Get Service Desired                                                                                                     
        ;------------------------------------------------------------------------------------------------------------------------
        select into "nl:"
          from order_detail od
             , (dummyt d with seq = value(size(results->data,5)))
               
          plan d
          
          join od
           where od.order_id            = results->data[d.seq].order_id
             and od.oe_field_meaning_id = 9000.00
             and od.oe_field_id         = 951916695.00
        
        order d.seq, od.action_sequence desc
        
        head d.seq
            results->data[d.seq].service_desire = od.oe_field_display_value
        with nocounter


        ;------------------------------------------------------------------------------------------------------------------------
        ;Get Order Dx
        ;------------------------------------------------------------------------------------------------------------------------
        select into "nl:"
          from nomen_entity_reltn ner
             , nomenclature n
             , (dummyt d with seq = value(size(results->data,5)))
             
          plan d
          
          join ner
           where ner.parent_entity_id    =  results->data[d.seq].order_id
             and ner.parent_entity_name  =  "ORDERS"
             and ner.child_entity_name   =  "DIAGNOSIS"
             and ner.active_ind          =  1
             and ner.end_effective_dt_tm >  sysdate
          
          join n
           where n.nomenclature_id = ner.nomenclature_id
             and n.active_ind = 1
        
        order d.seq,ner.priority
        
        head d.seq
            n = 0
        
        head ner.priority
            n = n + 1
            
            results->data[d.seq].diag_desc = build2( results->data[d.seq].diag_desc, " ", trim(cnvtstring(n), 3), ")"
                                                   , trim(n.source_identifier_keycap ))

            results->data[d.seq].diag_code = build2( results->data[d.seq].diag_code, " ", trim(cnvtstring(n), 3), ")"
                                                   , trim(n.source_identifier_keycap ))
        
        foot d.seq  ;ner.parent_entity_id
            results->data[d.seq].diag_code = trim(results->data[d.seq].diag_code, 3)
            results->data[d.seq].diag_desc = trim(results->data[d.seq].diag_desc, 3)
    
        with nocounter

        
        ;------------------------------------------------------------------------------------------------------------------------
        ;Get FIN and MRN
        ;------------------------------------------------------------------------------------------------------------------------
        select into "nl:"
         
          from encntr_alias ea
             , (dummyt d with seq = value(size(results->data,5)))
         
         plan d
         
         join ea
          where ea.encntr_id            =  results->data[d.seq].encntr_id
            and ea.encntr_alias_type_cd in (1079.00, 1077.00)
        order by d.seq, ea.encntr_alias_type_cd
        head d.seq
            null
        head ea.encntr_alias_type_cd
            case(ea.encntr_alias_type_cd)
            of 1077.00: results->data[d.seq].mrn = ea.alias
            of 1079.00: results->data[d.seq].fin = ea.alias
            endcase
        with nocounter
    
        call echo("Before our")
        call echorecord(results)
        
        
        ;------------------------------------------------------------------------------------------------------------------------
        ;Output
        ;------------------------------------------------------------------------------------------------------------------------
        select into $outdev
               patient_name      = trim(substring(1, 100, results->data[d.seq].name             ))
             , mrn               = trim(substring(1,  12, results->data[d.seq].mrn              ))
             , dob               = trim(substring(1,  20, results->data[d.seq].dob              ))
             , date_of_service   = trim(substring(1,  20, results->data[d.seq].date_of_service  ))
             , fin               = trim(substring(1,  12, results->data[d.seq].fin              ))
             , order_name        = trim(substring(1,  70, results->data[d.seq].order_name       ))
             , ordering_provider = trim(substring(1, 100, results->data[d.seq].ordering_provider))
             , diagnosis_code    = trim(substring(1, 100, results->data[d.seq].diag_code        ))
             , service_desired   = trim(substring(1, 100, results->data[d.seq].service_desire   ))
          from (dummyt d with seq = value(size(results->data,5)))
        with nocounter, format, separator = " "
    endif
    
elseif($coc_mode = 3)

    select into $outdev
           patient_name      = trim(p.name_full_formatted)
         , mrn               = trim(ea.alias)
         , dob               = p.birth_dt_tm
         , date_of_service   = e.reg_dt_tm
         , fin               = trim(ea1.alias)
         , order_name        = pc.description
         , ordering_provider = pr.name_full_formatted
     
     from  encounter e
         , person p
         , encntr_alias ea
         , encntr_alias ea1
         , pathway pw
         , pathway_catalog pc
         , pathway_action pa
         , prsnl pr
    
      plan e 
       where e.reg_dt_tm              between cnvtdatetime(cnvtdate($beg_dt), 0) and cnvtdatetime(cnvtdate($end_dt), 2359)
         and e.active_ind             =  1
         and (   0 in ($oncloc)
              or e.loc_nurse_unit_cd in  ($oncloc)
             )
             
      join p 
       where p.person_id              =  e.person_id
                                         
      join ea                            
       where ea.encntr_id             =  outerjoin(e.encntr_id)
         and ea.encntr_alias_type_cd  =  outerjoin(1079.00)
                                         
      join ea1                           
       where ea1.encntr_id            =  outerjoin(e.encntr_id) ; MRN
         and ea1.encntr_alias_type_cd =  outerjoin(1077.00)
                                         
      join pw                            
       where pw.encntr_id             =  e.encntr_id ;FIN
         and pw.pw_status_cd          in (10742.00, 10740.00)
      
      join pc 
       where pc.pathway_catalog_id    =  pw.pathway_catalog_id
         and pc.description           =  "AMB Medstar Cancer Rehabilitation Referral"
                                         
      join pa                            
       where pa.pathway_id            =  pw.pathway_id
         and pa.action_type_cd        =  10752.00
                                         
      join pr where pr.person_id      =  outerjoin(pa.action_prsnl_id)
                                         
    with nocounter, format, separator =  " "
    
elseif($coc_mode = 4)

    select distinct into $outdev
           patient_name    = trim(p.name_full_formatted)
         , mrn             = trim(ea.alias)
         , dob             = p.birth_dt_tm
         , date_of_service = e.reg_dt_tm
         , fin             = trim(ea1.alias)
         , visit_provider  = pr.name_full_formatted
         , diagnosis_code  = n.source_identifier_keycap
         
      from encounter e
         , person p
         , pt_prot_reg ppr
         , prot_master pm
         , encntr_alias ea
         , encntr_alias ea1
         , encntr_prsnl_reltn epr
         , prsnl pr
         , diagnosis d
         , nomenclature n
         
      plan e 
       where e.reg_dt_tm              between cnvtdatetime(cnvtdate($beg_dt), 0) and cnvtdatetime(cnvtdate($end_dt), 2359)
         and e.active_ind             =  1
         and (   0 in ($oncloc)
              or e.loc_nurse_unit_cd  in ($oncloc)
             )
      
      join p 
       where p.person_id              =  e.person_id
         and p.active_ind             =  1
      
      join ppr 
       where ppr.person_id            =  e.person_id
         and ppr.on_study_dt_tm       <= cnvtdatetime(curdate, curtime3) ;ppr.person_id = REQUEST -> PERSON_ID and
         and ppr.off_study_dt_tm      >= cnvtdatetime(curdate, curtime3)
         and ppr.beg_effective_dt_tm  <= cnvtdatetime(curdate, curtime3)
         and ppr.end_effective_dt_tm  >= cnvtdatetime(curdate, curtime3)
      
      join pm 
       where pm.prot_master_id        =  ppr.prot_master_id
         and pm.beg_effective_dt_tm   <= cnvtdatetime(curdate, curtime3)
         and pm.end_effective_dt_tm   >= cnvtdatetime(curdate, curtime3)
         and pm.display_ind           =  1
      
      join ea 
       where ea.encntr_id             =  outerjoin(e.encntr_id)
         and ea.encntr_alias_type_cd  =  outerjoin(1079.00)
      
      join ea1 
       where ea1.encntr_id            =  outerjoin(e.encntr_id) ; MRN
         and ea1.encntr_alias_type_cd =  outerjoin(1077.00)
      
      join epr 
       where epr.encntr_id            =  e.encntr_id ;FIN
         and epr.encntr_prsnl_r_cd    =  1119.00
         and epr.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)
         and epr.active_ind           =  1
      
      join pr 
       where pr.person_id             =  epr.prsnl_person_id
      
      join d 
       where d.encntr_id              =  e.encntr_id
         and d.active_ind             =  1
         and d.clinical_diag_priority =  1
    
      join n 
       where n.nomenclature_id        =  d.nomenclature_id
         and n.source_vocabulary_cd   =  73005233.00
    
    with nocounter, format, separator = " "

elseif($coc_mode = 5)

    select into $outdev
           patient_name                      = trim(p.name_full_formatted)
         , mrn                               = trim(ea.alias)
         , dob                               = p.birth_dt_tm
         , date_of_service                   = e.reg_dt_tm
         , fin                               = trim(ea1.alias)
         , survivorship_care_plan_documented = ce.event_title_text
         , provider                          = pr.name_full_formatted
         
      from encounter e
         , person p
         , encntr_alias ea
         , encntr_alias ea1
         , clinical_event ce
         , prsnl pr
      
      plan e 
       where e.reg_dt_tm              between cnvtdatetime(cnvtdate($beg_dt), 0) and cnvtdatetime(cnvtdate($end_dt), 2359)
         and e.active_ind             =  1
         and e.med_service_cd         != 950461507.00
         and (   0 in ($oncloc)
              or e.loc_nurse_unit_cd in ($oncloc)
             )
         
      join p 
       where p.person_id              =  e.person_id
                                         
      join ea                            
       where ea.encntr_id             =  outerjoin(e.encntr_id)
         and ea.encntr_alias_type_cd  =  outerjoin(1079.00)
                                         
      join ea1                           
       where ea1.encntr_id            =  outerjoin(e.encntr_id) ; MRN
         and ea1.encntr_alias_type_cd =  outerjoin(1077.00)
                                         
      join ce                            
       where ce.encntr_id             =  e.encntr_id ;FIN
         and ce.event_cd              =  2182635897.00
         and ce.valid_until_dt_tm     =  cnvtdatetime("31-DEC-2100 00:00:00")
         and ce.result_status_cd      in (25.00, 33.00, 35.00)
         and ce.view_level            =  1
      
      join pr 
       where pr.person_id             =  outerjoin(ce.verified_prsnl_id)
    with nocounter, format, separator =  " "

;004->
elseif($coc_mode = 8)

    select into $outdev
           PATIENT_NAME                 = trim(p.name_full_formatted)
         , MRN                          = trim(fin.alias)
         , DOB                          = p.birth_dt_tm
         , PROVIDER                     = visprov.name_full_formatted
         , DATE_OF_SERVICE              = e.reg_dt_tm
         , FIN                          = trim(mrn.alias)
         , ADVANCE_DIRECTIVE_DOCUMENTED = if(findstring('Advance Directive', res.result_val) > 0) 'Y'
                                          else                                                    'N'
                                          endif
         , MOLST_DOCUMENTED             = if(findstring('MO(L)ST'          , res.result_val) > 0) 'Y'
                                          else                                                    'N'
                                          endif
         , DATE_COMPLETED               = format(res.event_end_dt_tm, '@SHORTDATETIME')
         , DOCUMENTED_BY                = auth.name_full_formatted
         
      from encounter e
         , person p
         , encntr_alias fin
         , encntr_alias mrn
         , encntr_prsnl_reltn epr
         , prsnl visprov
         
         , clinical_event res

         , prsnl auth
      
      plan e 
       where e.reg_dt_tm               between cnvtdatetime(cnvtdate($beg_dt), 0) and cnvtdatetime(cnvtdate($end_dt), 2359)
         and e.active_ind              =  1
         and e.med_service_cd          != 950461507.00
         and (   0 in ($oncloc)
              or e.loc_nurse_unit_cd   in ($oncloc)
             )
         
      join p 
       where p.person_id               =  e.person_id
                                         
      join fin                            
       where fin.encntr_id             =  outerjoin(e.encntr_id)
         and fin.encntr_alias_type_cd  =  outerjoin(1079.00)
                                         
      join mrn                           
       where mrn.encntr_id             =  outerjoin(e.encntr_id) ; MRN
         and mrn.encntr_alias_type_cd  =  outerjoin(1077.00)
      
      join epr 
       where epr.encntr_id            =  e.encntr_id ;FIN
         and epr.encntr_prsnl_r_cd    =  1119.00
         and epr.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)
         and epr.active_ind           =  1
      
      join visprov 
       where visprov.person_id        =  epr.prsnl_person_id
      
      join res
       where res.person_id          =  p.person_id
         and res.valid_until_dt_tm  =  cnvtdatetime('31-DEC-2100 00:00:00.000')
         and res.result_status_cd   in (25.00, 33.00, 35.00)
         and res.event_cd           =  704644.00  ;Advance Directives Documents
         and res.event_end_dt_tm    =  (select max(ce2.event_end_dt_tm)
                                         from clinical_event ce2
                                        where ce2.person_id         =  res.person_id
                                          and ce2.event_cd          =  res.event_cd 
                                          and ce2.valid_until_dt_tm =  cnvtdatetime('31-DEC-2100 00:00:00.000')
                                          and ce2.result_status_cd  in (25.00, 33.00, 35.00)
                                      )
      
      join auth 
       where auth.person_id         =  outerjoin(res.verified_prsnl_id)
    with nocounter, format, separator  =  " "
;004<-

endif

end go

