select * from order_catalog where description in ('Referral to CTO*', 'Referral to MedStar CareFirst Care*') go


select * from order_catalog_synonym where catalog_cd = 3656251113 go

 3656251113.00
 3504277635.00
 
 select * from order_sentence where parent_entity_id = 3656251113 and parent_entity_name = 'ORDER_CATALOG_SYNONYM' go
 
 
 
cust_mp_mdpcp_prog_enroll_data 'MINE', 0, 0, 0 go
 
 
 


---------------------------
Message from webpage
---------------------------
You are viewing the patient chart for ZZZTEST, INPATIENTONE.
$PAT_PersonId$|$VIS_EncntrId$|{ORDER|0|3656251129|0|0|0|0|0}|0|{2|127}|32
---------------------------
OK   
---------------------------


select oc.*
  from order_catalog         oc
     , order_catalog_synonym ocs
 where oc.description in ('Referral to CTO*', 'Referral to MedStar CareFirst Care*')
   and oc.active_ind  =  1

   and ocs.catalog_cd =  oc.catalog_cd
   and ocs.active_ind =  1
   
   
   
ea '2302413733' go

encntr_id           person_id
  208143585.00         28363948.00
  
  
  
cust_mp_mdpcp_prog_enroll_data 'MINE', 28363948, 208143585, 0 go


e 192178031.00 go

2210104.00

;real patient here
cust_mp_mdpcp_prog_enroll_data 'MINE', 2210104, 192178031, 0 go



select * from person_prsnl_reltn 
 where person_prsnl_r_cd = 2085299519.00 
   and active_ind = 1
   and end_effective_dt_tm > sysdate
   and beg_effective_dt_tm > sysdate - 30
with uar_code(D) go


select * from encounter where person_id = 15956838.00 order by reg_dt_tm desc go


;real patient here
set trace rdbbind go
set trace rdbdebug go
cust_mp_mdpcp_prog_enroll_data 'MINE', 15956838.00, 250606553, 0 go




free record hi_get_hi_demographics_request go
record hi_get_hi_demographics_request(
;%i cclsource:hi_get_person_demogr_req.inc
    1 person_id                    = f8
    1 hi_person_identifier         = vc
    1 demographics_test_uri        = vc
    1 benefit_coverage_source_type = vc
) go

free record hi_get_hi_demographics_reply go
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
) go


set hi_get_hi_demographics_request->person_id             = 15956838 go
set hi_get_hi_demographics_request->demographics_test_uri = '' go


execute mmmtest with replace("REQUEST", hi_get_hi_demographics_request)
                                   , replace("REPLY"  , hi_get_hi_demographics_reply)
go




select p.name_full_formatted, ppr.* 
  from person_prsnl_reltn ppr 
     , prsnl p
 where ppr.person_id = 15956838.000000 
   and p.person_id   = ppr.prsnl_person_id
with uar_code(D) go



cust_mp_mdpcp_prog_enroll_data 'MINE', 22140166.00, 192457081.00, 0 go



ea '910000010' go

encntr_id           person_id
  251323956.00         17343729.00
  
  
cust_mp_mdpcp_prog_enroll_data 'MINE', 17343729, 251323956, 0 go





ea '755556834' go
ea '772372504' go
ea '736320565' go
ea '748829678' go


encntr_id           person_id
  249193417.00         26817165.00
encntr_id           person_id
  256319585.00         32647092.00
encntr_id           person_id
  241273490.00         20736209.00
encntr_id           person_id
  246397837.00         17180061.00


set trace rdbbind go
set trace rdbdebug go

cust_mp_mdpcp_prog_enroll_data 'MINE', 26817165, 249193417, 0 go
cust_mp_mdpcp_prog_enroll_data 'MINE', 32647092, 256319585, 0 go
cust_mp_mdpcp_prog_enroll_data 'MINE', 20736209, 241273490, 0 go
cust_mp_mdpcp_prog_enroll_data 'MINE', 17180061, 246397837, 0 go



set trace rdbbind go
set trace rdbdebug go
cust_mp_mdpcp_prog_enroll_data 'MINE', 31236167, 263506864, 0 go

set trace rdbbind go
set trace rdbdebug go
cust_mp_mdpcp_prog_enroll_data 'MINE', 17510918.00, 123114861.00, 0 go

set trace rdbbind go
set trace rdbdebug go
cust_mp_mdpcp_prog_enroll_data 'MINE', 17250704.00, 247282738.00, 0 go

set trace rdbbind go
set trace rdbdebug go
cust_mp_mdpcp_prog_enroll_data 'MINE', 36168205.00, 242666667.00, 0 go



select bdv.MPAGE_PARAM_VALUE, bdc.CATEGORY_NAME, bdv.MPAGE_PARAM_VALUE
  from br_datamart_value bdv
     , br_datamart_category bdc
     
 where bdv.mpage_param_mean = 'mp_label'
   and bdv.MPAGE_PARAM_VALUE = 'MDPCP*'
   
   and bdc.br_datamart_category_id = bdv.br_datamart_category_id
order by bdc.CATEGORY_NAME
go




select * from order_catalog where description = 'Referral to MedStar Family Choice Care Coordinator/Case Manager' go
select * from order_catalog_synonym where catalog_cd = 5028657453.00 go


select * from ocs_facility_r where synonym_id = 5028657467.00 go




select p.name_full_formatted, e2.*
  from orders o
     , encounter e
     , encounter e2
     , person p
 where o.catalog_cd = 5028657453
   and e.encntr_id = o.encntr_id
   and p.person_id = e.person_id
   and e2.person_id = e.person_id
   and e2.loc_facility_cd in (select facility_cd
                               from ocs_facility_r where synonym_id = 5028657467.00)   
go


mmmea 261880830.00 go




select * from order_catalog where description = 'Referral to MedStar CareFirst Behavioral Health Care Manager' go



select * from orders where catalog_cd = 3504270305.00 go


select * from code_value where code_value in(

 818277419.00
, 818772583.00
, 833015459.00
, 837937589.00
, 837937749.00
, 838016079.00
,1680019697.00
, 939961415.00
, 828124337.00
, 828124347.00
, 838016139.00
)

go
/*
MedStar Family Health Center at MFSMC   
MedStar Primary Care at Harbor Hospital 
MedStar Medical Group FM at St. Clements
MedStar Medical Group IM at St Mary's   
MedStar Medical Group Fam Med at Olney  
MedStar Medical Group IM at Dorsey Hall 
MedStar Medical Group IM at Bethesda    
MedStar Med Grp IM at North Parkville   
MedStar Medical Group IM at Wilkens Ave 
MMG FM at Hyattsville                   
MMG Primary Care at Annapolis           
*/



select * from encounter where
loc_facility_cd = 818277419
a