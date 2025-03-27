select
  from orders o
 where o.order_id           = @ORDERID:{Order}
   and o.pathway_catalog_id = (select pw.pathway_catalog_id
                                 from pathway_catalog pw
                                where pw.description = 'ED Bariatric Surgery Hx'
                                  and pw.active_ind = 1
                                  and pw.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
                              )
head report
    log_misc1 = ''
    log_message = ''
    log_retval = 0
detail
    log_misc1 = 'ORDERSET FOUND'
    log_message = 'ORDERSET FOUND'
    log_retval = 100
WITH nocounter, NULLREPORT go


cycle -entry 150
cycle -entry 151
cycle -entry 152
cycle -entry 153
cycle -entry 175
cycle -entry 176



select * from orders where encntr_id = 251277589.00
and order_status_cd = 2550.00
with uar_code(D) go




99_mmm_test_result_order 38982869.00, 251277589.00, 8646395.00, 124542345123.00, '79.0' go
99_mmm_test_result_order 38982869.00, 251277589.00, 823843985.00, 24542345127.00, '79.0' go


ORDER_ID       OE_FORMAT_ID   ENCNTR_ID      PERSON_ID      CATALOG_DISPLAY
24542345123.00      312486.00   251277589.00    38982869.00 Vitamin D-25 Hydroxy Level
24542345127.00      312486.00   251277589.00    38982869.00 Vitamin B1 (Thiamine), Whole Blood


select * from code_value where code_set = 72
and display = 'Vitamin D*' go

CODE_VALUE     CODE_SET    CDF_MEANING  DISPLAY
  823843985.00          72              Vitamin B1 Lvl
CODE_VALUE     CODE_SET    CDF_MEANING  DISPLAY
    8646395.00          72              Vit D25 Hydroxy Lvl



update into orders o
   set o.order_status_cd = 2543.00
     , o.dept_status_cd  = 9312.00
 where order_id = 24542345127.0
go

update into orders o
   set o.order_status_cd = 2550.00 
     , o.dept_status_cd  = 9315.00
 where order_id = 24542345123.0
go

update into orders o
   set o.order_status_cd = 2550.00
     , o.dept_status_cd  = 9315.00
 where order_id = 24542345127.0
go

declare log_misc1 = vc go
select o.*
  from orders o
 where o.order_id           = 24542345127.0
   and o.pathway_catalog_id = (select pw.pathway_catalog_id
                                 from pathway_catalog pw
                                where pw.description = 'ED Bariatric Surgery Hx'
                                  and pw.active_ind = 1
                                  and pw.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
                              )
head report
    log_misc1 = ''
    log_message = ''
    log_retval = 0
detail
     log_misc1 = 'ORDERSET FOUND'
     log_message = 'ORDERSET FOUND'
     log_retval = 100
 WITH nocounter, NULLREPORT go

call echo(log_misc1) go


Patient 30 days or LESS post Bariatric Surgery
Patient GREATER than 30 days post Bariatric Surgery.  Notify Bariatric Surgery Team via Bariatric Pool Message and provide patient a referral to the bariatric service.




update into prsnl set position_cd = 915344423.00 where username = 'MMM174' go
update into prsnl set position_cd = 914278371.00 where username = 'MMM174' go

update into prsnl set position_cd = 441.00 where username = 'MMM174' go





select * from organization where
organization_id in (
589723.00
, 628058.00
, 627889.00
, 628009.00
, 628088.00
, 628085.00
, 3763758.00
,1300352.00
,3837372.00
) go


select * from organization where
organization_id in (
1300352
, 3440653
) go
3440653.00




select ;o.order_id, o.encntr_id, od.*
       substring(1, 75, od.oe_field_display_value), cnt = count(*)
  from surgical_case sc
     , surg_case_procedure scp
     , orders o
     , order_detail od
 ;where sc.sched_start_dt_tm between cnvtdatetime(curdate-100, curtime3) and cnvtdatetime(curdate, curtime3)
 where sc.sched_start_dt_tm between cnvtdatetime(curdate-300, curtime3) and cnvtdatetime(curdate-200, curtime3)
   and sc.cancel_dt_tm = null
   and sc.active_ind = 1

   and scp.surg_case_id = sc.surg_case_id
   and scp.active_ind = 1
   and scp.sched_surg_proc_cd != 0

   and o.order_id = scp.order_id

   and od.order_id        = o.order_id
   and od.oe_field_id     = 683615.0;3644439611.00 
   and od.action_sequence = (select max(od2.action_sequence)
                               from order_detail od2
                              where od2.order_id     = od.order_id
                               and  od2.oe_field_id = 683615.0;3644439611.00
                            )
   and (   od.oe_field_display_value = '*43775*'
        or od.oe_field_display_value = '*43644*'
        or od.oe_field_display_value = '*43645*'
        or od.oe_field_display_value = '*43659*'
        or od.oe_field_display_value = '*43846*'
        or od.oe_field_display_value = '*43847*'
        or od.oe_field_display_value = '*43633*'
        or od.oe_field_display_value = '*43843*'
        or od.oe_field_display_value = '*43842*'
        or od.oe_field_display_value = '*43770*'
        or od.oe_field_display_value = '*43771*'
        or od.oe_field_display_value = '*43772*'
        or od.oe_field_display_value = '*43773*'
        or od.oe_field_display_value = '*43774*'
        or od.oe_field_display_value = '*43886*'
        or od.oe_field_display_value = '*43887*'
        or od.oe_field_display_value = '*43888*'
       )
group by od.oe_field_display_value
order by cnt desc 
go





LAPS GSTRC RSTRICTIV PX LONGITUDINAL GASTRECTOMY (43775)
LAPS GSTR RSTCV PX W/BYP ROUX-EN-Y LIMB <150 CM (43644)
UNLISTED LAPAROSCOPY PROCEDURE STOMACH (43659)
LAPS GASTRIC RESTRICTIVE PX REMOVE DEVICE & PORT (43774)
GASTRIC RSTCV W/BYP W/SHORT LIMB 150 CM/< (43846)
GSTRCT PRTL DSTL W/ROUX-EN-Y RCNSTJ (43633)
LAPS GSTRC RSTRICTIV PX LONGITUDINAL GASTRECTOMY (43775)
LAPS GSTR RSTCV PX W/BYP ROUX-EN-Y LIMB <150 CM (43644) 
LAPS GASTRIC RESTRICTIVE PX REMOVE DEVICE (43772)       
UNLISTED LAPAROSCOPY PROCEDURE STOMACH (43659)          
GASTRIC RSTCV W/BYP W/SHORT LIMB 150 CM/< (43846)       
GSTRCT PRTL DSTL W/ROUX-EN-Y RCNSTJ (43633)             
LAPS GASTRIC RESTRICTIVE PX REMOVE DEVICE & PORT (43774)
LAPS GSTRC RSTRICTIV PX LONGITUDINAL GASTRECTOMY (43775)                            143.00
LAPS GSTR RSTCV PX W/BYP ROUX-EN-Y LIMB <150 CM (43644)                              48.00
GSTRCT PRTL DSTL W/ROUX-EN-Y RCNSTJ (43633)                                           3.00
UNLISTED LAPAROSCOPY PROCEDURE STOMACH (43659)                                        2.00
LAPS GASTRIC RESTRICTIVE PX REMOVE DEVICE (43772)                                     1.00

select o.order_id, o.encntr_id, o.person_id, od.*
       
  from surgical_case sc
     , surg_case_procedure scp
     , orders o
     , order_detail od
 where sc.sched_start_dt_tm between cnvtdatetime(curdate-60, curtime3) and cnvtdatetime(curdate-30, curtime3)
   and sc.cancel_dt_tm = null
   and sc.active_ind = 1

   and scp.surg_case_id = sc.surg_case_id
   and scp.active_ind = 1
   and scp.sched_surg_proc_cd != 0

   and o.order_id = scp.order_id

   and od.order_id        = o.order_id
   and od.oe_field_id     = 683615.0;3644439611.00 
   and od.action_sequence = (select max(od2.action_sequence)
                               from order_detail od2
                              where od2.order_id     = od.order_id
                               and  od2.oe_field_id = 683615.0;3644439611.00
                            )
   and (   od.oe_field_display_value = '*43775*'
        or od.oe_field_display_value = '*43644*'
        or od.oe_field_display_value = '*43645*'
        or od.oe_field_display_value = '*43659*'
        or od.oe_field_display_value = '*43846*'
        or od.oe_field_display_value = '*43847*'
        or od.oe_field_display_value = '*43633*'
        or od.oe_field_display_value = '*43843*'
        or od.oe_field_display_value = '*43842*'
        or od.oe_field_display_value = '*43770*'
        or od.oe_field_display_value = '*43771*'
        or od.oe_field_display_value = '*43772*'
        or od.oe_field_display_value = '*43773*'
        or od.oe_field_display_value = '*43774*'
        or od.oe_field_display_value = '*43886*'
        or od.oe_field_display_value = '*43887*'
        or od.oe_field_display_value = '*43888*'
       )

go



;30days supposedly
282649966.00    17579455.00
281269121.00     2365854.00
280798427.00    40120882.00
281665891.00    12100054.00

;+30days supposedly (might be some more recent possibly.)
279824719.00     2578564.00
280010489.00     2040246.00
277928862.00     3645606.00
273297260.00     3554455.00
281028647.00    16778533.00



free set trigger_encntrid go
free set trigger_personid go
free set retval           go
free set log_message      go
free set log_misc1        go

declare trigger_encntrid = f8 with protect, noconstant(279824719.00) go
declare trigger_personid = f8 with protect, noconstant(2578564.00) go
declare retval           = i4 go
declare log_message      = vc go
declare log_misc1        = vc go

0_eks_bari_proc_check go

call echo(build('trigger_encntrid:', trigger_encntrid)) go
call echo(build('retval          :', retval          )) go
call echo(build('log_message     :', log_message     )) go
call echo(build('log_misc1       :', log_misc1       ))   go






free set test_str go
declare test_str = vc go
free set test_piece go
declare test_piece = vc go
set test_str = 'PROCFOUND|1|PROC<30D|1|PROCDATE|10/14/24 11:43:00' go
set test_piece = piece(test_str, '|', 1, '--') go
call echo(build('test_piece 1:', test_piece)) go
set test_piece = piece(test_str, '|', 2, '--') go
call echo(build('test_piece 2:', test_piece)) go
set test_piece = piece(test_str, '|', 3, '--') go
call echo(build('test_piece 3:', test_piece)) go
set test_piece = piece(test_str, '|', 4, '--') go
call echo(build('test_piece 4:', test_piece)) go
set test_piece = piece(test_str, '|', 5, '--') go
call echo(build('test_piece 5:', test_piece)) go
set test_piece = piece(test_str, '|', 6, '--') go
call echo(build('test_piece 6:', test_piece)) go


test_piece 1:PROCFOUND
test_piece 2:1
test_piece 3:PROC<30D
test_piece 4:1
test_piece 5:PROCDATE
test_piece 6:10/14/24 11:43:00




free set trigger_encntrid go
free set trigger_personid go
free set link_orderid go
free set retval           go
free set log_message      go
free set log_misc1        go

declare trigger_encntrid = f8 with protect, noconstant(250777523.00) go
declare trigger_personid = f8 with protect, noconstant(38488860.00) go
declare link_orderid     = f8 with protect, noconstant(24590276885.00) go

declare retval           = i4 go
declare log_message      = vc go
declare log_misc1        = vc go

0_eks_bari_dx_loc_check go

call echo(build('trigger_encntrid:', trigger_encntrid)) go
call echo(build('retval          :', retval          )) go
call echo(build('log_message     :', log_message     )) go
call echo(build('log_misc1       :', log_misc1       ))   go



free set test_str go
declare test_str = vc go
free set test_piece go
declare test_piece = vc go
set test_str = 'LOC|WHC|ORDDX|B virus infection;Test|ORDPROV|Mayes, Michael' go
set test_piece = piece(test_str, '|', 1, '--') go
call echo(build('test_piece 1:', test_piece)) go
set test_piece = piece(test_str, '|', 2, '--') go
call echo(build('test_piece 2:', test_piece)) go
set test_piece = piece(test_str, '|', 3, '--') go
call echo(build('test_piece 3:', test_piece)) go
set test_piece = piece(test_str, '|', 4, '--') go
call echo(build('test_piece 4:', test_piece)) go
set test_piece = piece(test_str, '|', 5, '--') go
call echo(build('test_piece 5:', test_piece)) go
set test_piece = piece(test_str, '|', 6, '--') go
call echo(build('test_piece 6:', test_piece)) go

test_piece 1:LOC
test_piece 2:WHC
test_piece 3:ORDDX
test_piece 4:B virus infection
test_piece 5:ORDPROV
test_piece 6:Mayes, Michael


Patient was seen in the Emergency Room with a diagnosis of <<Diagnosis here>> and the Bariatric Surgery Hx Orderset was placed by <<Ordering Provider>>. This patient has a history of bariatric surgery greater than 30 days.
	 
Patient was seen in the Emergency Room @MISC:{ORDDX} and the Bariatric Surgery Hx Orderset was placed by @MISC:{ORDPROV}. This patient has a history of bariatric surgery greater than 30 days.
	
The "with a diagnosis of ..." is optional.


 
 
evaluate(piece("LOC|FSH|ORDDX|B virus infection|ORDPROV|Mayes, Michael", '|', 4, '-1'), "", "", concat("with a diagnosis of ", piece("LOC|FSH|ORDDX|B virus infection|ORDPROV|Mayes, Michael", '|', 4, '-1'))) go 



select order_status_cd, person_id, encntr_id, *
  from orders 
 where catalog_cd = 1358699549.00 
   and orig_order_dt_tm > sysdate - 10 
   and order_status_cd = 2543.00  ;Comp
with uar_code(D) go

PERSON_ID      ENCNTR_ID      ORDER_ID      
    2029489.00   285914513.00 29168107887.00
   35084023.00   285887473.00 29166651817.00
    2287947.00   285821725.00 29170057633.00
    2029489.00   285914513.00 29168091281.00
    5142616.00   285874132.00 29171549691.00
   41599751.00   285717620.00 29171419095.00

select order_status_cd, person_id, encntr_id, *
  from orders 
 where catalog_cd = 8590089.00 
   and orig_order_dt_tm > sysdate - 10 
   and order_status_cd = 2543.00  ;Comp
with uar_code(D) go

PERSON_ID      ENCNTR_ID      ORDER_ID      
   28857790.00   284504477.00 29166481149.00
   30704166.00   284507831.00 29165491461.00
   33501894.00   285776677.00 29166046139.00
   17273380.00   283614998.00 29163796355.00
    5164214.00   284491227.00 29165469647.00
    2306726.00   285907942.00 29168232129.00
    2079354.00   278123629.00 29167001995.00


free set trigger_encntrid go
free set trigger_personid go
free set link_orderid go
free set retval           go
free set log_message      go
free set log_misc1        go

declare trigger_personid = f8 with protect, noconstant(5164214.00) go
declare trigger_encntrid = f8 with protect, noconstant(284491227.00) go
declare link_orderid     = f8 with protect, noconstant(29165469647.00) go

declare retval           = i4 go
declare log_message      = vc go
declare log_misc1        = vc go

0_eks_bari_ed_os_res go

;call echo(build('trigger_encntrid:', trigger_encntrid)) go
;call echo(build('retval          :', retval          )) go
;call echo(build('log_message     :', log_message     )) go
call echo(build('log_misc1       :', log_misc1       ))   go





LOC|Unknown|LAB|Vitamin D-25 Hydroxy Level|RES|9.1 ng/mL LOW

free set test_str go
declare test_str = vc go
free set test_piece go
declare test_piece = vc go
set test_str = 'LOC|Unknown|LAB|Vitamin D-25 Hydroxy Level|RES|9.1 ng/mL LOW' go
set test_piece = piece(test_str, '|', 1, '--') go
call echo(build('test_piece 1:', test_piece)) go
set test_piece = piece(test_str, '|', 2, '--') go
call echo(build('test_piece 2:', test_piece)) go
set test_piece = piece(test_str, '|', 3, '--') go
call echo(build('test_piece 3:', test_piece)) go
set test_piece = piece(test_str, '|', 4, '--') go
call echo(build('test_piece 4:', test_piece)) go
set test_piece = piece(test_str, '|', 5, '--') go
call echo(build('test_piece 5:', test_piece)) go
set test_piece = piece(test_str, '|', 6, '--') go
call echo(build('test_piece 6:', test_piece)) go

test_piece 1:LOC
test_piece 2:Unknown
test_piece 3:LAB
test_piece 4:Vitamin D-25 Hydroxy Level
test_piece 5:RES
test_piece 6:9.1 ng/mL LOW



declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))   go
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED')) go
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))     go
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))  go

select uar_get_code_display(ce.event_cd)
     , substring(1, 10, trim(ce.result_val, 3))
     , ce.result_units_cd
     , substring(1, 10, uar_get_code_display(ce.result_units_cd))
     , ce.normalcy_cd
     , substring(1, 10, uar_get_code_display(ce.normalcy_cd))
     , ce.*
  
  from clinical_event ce
 
 where ce.order_id          in ( 29168107887.00
                               , 29166651817.00
                               , 29170057633.00
                               , 29176754489.00
                               , 29174910557.00
                               , 29177405089.00
                               , 29166481149.00
                               , 29166046139.00
                               , 29165304591.00
                               , 29163796355.00
                               , 29165469647.00
                               , 29168232129.00
                               )
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
   and ce.view_level        =  1
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
go
   



create program 99_mmm_test_result_order:dba
 
prompt 
	  "PERSON_ID" = 0.0
    , "ENCNTR_ID" = 0.0
    , "EVENT_CD"  = 0.0
    , "ORDER_ID"  = 0.0
    , "RESULT"    =

EVENT_DISPLAY                            EVENT_CD
Vit D25 Hydroxy Lvl                          8646395.00
Vitamin B1, WB                            1400411315.00
Vitamin B1 Lvl                             823843985.00
    

99_mmm_test_result_order 38488860.00, 250777523.00, 823843985.0, 24591270415.00, '37.9' go




declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))   go
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED')) go
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))     go
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))  go
select ce.event_cd
  from clinical_event ce
 where ce.order_id in (  29168107887
                        ,29166651817
                        ,29170057633
                        ,29168091281
                        ,29171549691
                        ,29171419095
                        ,29166481149
                        ,29165491461
                        ,29166046139
                        ,29163796355
                        ,29165469647
                        ,29168232129
                        ,29167001995)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
   and ce.view_level        =  1
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
with uar_code(D)
go


call echo(cnvtstring(
                    cnvtreal(
                             piece("LOC|WHC|LAB|Vitamin D-25 Hydroxy Level|RES|37.9", '|', 6, '-1')
                            )
                    ), 17, 6
         ) go
                  
                  
                  
call echo(CNVTSTRING(cnvtreal(ceil(10 * (cnvtreal(0.03) * cnvtreal(25)))) / 10,11,2)) go
call echo(CNVTSTRING(cnvtreal(ceil(10 * (cnvtreal(0.03) * cnvtreal(25)))) / 10,11,1)) go






Order
24590274417

select * from sn_proc_cpt_r where procedure_cd = 957735379.00 go


NOMENCLATURE_ID
    34147213.00
    34147436.00
    
select * from nomenclature where nomenclature_id in (34147213.00, 34147436.00) go





free set trigger_encntrid go
free set trigger_personid go
free set retval           go
free set log_message      go
free set log_misc1        go

declare trigger_encntrid = f8 with protect, noconstant(251347535.00) go
declare trigger_personid = f8 with protect, noconstant(39120861.00) go
declare retval           = i4 go
declare log_message      = vc go
declare log_misc1        = vc go

0_eks_bari_proc_check go







99_mmm_test_result_order 38488860.00, 250777523.00, 823843985.0, 24606808443.00, '37.9' go
p_id, e_id, event_cd, ord_id, result






select FIN = substring(1, 20, ea.alias), uar_get_code_display(e.loc_facility_cd), uar_get_code_display(e.loc_nurse_unit_cd), e.*
  from surgical_case       sc
     , surg_case_procedure scp
     , sn_proc_cpt_r       spcr
     , nomenclature        n
     
     , encounter           e
     , encntr_alias        ea
  
 where sc.cancel_dt_tm      =  null
   and sc.checkin_dt_tm     != null
   and sc.surg_start_dt_tm  != null
   and sc.surg_stop_dt_tm   != null
   and sc.active_ind        =  1
   and sc.surg_start_dt_tm  <= cnvtlookbehind('30,D')

   and scp.surg_case_id = sc.surg_case_id
   and scp.active_ind   = 1
   and scp.surg_proc_cd > 0

   and spcr.procedure_cd = scp.surg_proc_cd
   
   and n.nomenclature_id = spcr.nomenclature_id
   and (   n.source_identifier = '43775'
        or n.source_identifier = '43644'
        or n.source_identifier = '43645'
        or n.source_identifier = '43659'
        or n.source_identifier = '43846'
        or n.source_identifier = '43847'
        or n.source_identifier = '43633'
        or n.source_identifier = '43843'
        or n.source_identifier = '43842'
        or n.source_identifier = '43770'
        or n.source_identifier = '43771'
        or n.source_identifier = '43772'
        or n.source_identifier = '43773'
        or n.source_identifier = '43774'
        or n.source_identifier = '43886'
        or n.source_identifier = '43887'
        or n.source_identifier = '43888'
       )
   
   and e.encntr_id = sc.encntr_id
   
   and ea.encntr_id = e.encntr_id
   and ea.ENCNTR_ALIAS_TYPE_CD = 1077 ;fin
   and ea.active_ind = 1 

go




select FIN = substring(1, 20, ea.alias), uar_get_code_display(e.loc_facility_cd), uar_get_code_display(e.loc_nurse_unit_cd), e.*
  from surgical_case       sc
     , surg_case_procedure scp
     , sn_proc_cpt_r       spcr
     , nomenclature        n
     
     , encounter           e
     , encntr_alias        ea
  
 where sc.cancel_dt_tm      =  null
   and sc.checkin_dt_tm     != null
   and sc.surg_start_dt_tm  != null
   and sc.surg_stop_dt_tm   != null
   and sc.active_ind        =  1
   and sc.surg_start_dt_tm  <= cnvtlookbehind('30,D')
   and sc.surg_start_dt_tm  >= cnvtlookbehind('90,D')
   and not exists(
   
        select 'X'
          from surgical_case       sc2
             , surg_case_procedure scp2
             , sn_proc_cpt_r       spcr2
             , nomenclature        n2
          
         where sc2.cancel_dt_tm      =  null
           and sc2.checkin_dt_tm     != null
           and sc2.surg_start_dt_tm  != null
           and sc2.surg_stop_dt_tm   != null
           and sc2.active_ind        =  1
           and sc2.surg_start_dt_tm  >= cnvtlookbehind('30,D')

           and scp2.surg_case_id = sc2.surg_case_id
           and scp2.active_ind   = 1
           and scp2.surg_proc_cd > 0

           and spcr2.procedure_cd = scp2.surg_proc_cd
           
           and n2.nomenclature_id = spcr2.nomenclature_id
           and (   n2.source_identifier = '43775'
                or n2.source_identifier = '43644'
                or n2.source_identifier = '43645'
                or n2.source_identifier = '43659'
                or n2.source_identifier = '43846'
                or n2.source_identifier = '43847'
                or n2.source_identifier = '43633'
                or n2.source_identifier = '43843'
                or n2.source_identifier = '43842'
                or n2.source_identifier = '43770'
                or n2.source_identifier = '43771'
                or n2.source_identifier = '43772'
                or n2.source_identifier = '43773'
                or n2.source_identifier = '43774'
                or n2.source_identifier = '43886'
                or n2.source_identifier = '43887'
                or n2.source_identifier = '43888'
               )
   )

   and scp.surg_case_id = sc.surg_case_id
   and scp.active_ind   = 1
   and scp.surg_proc_cd > 0

   and spcr.procedure_cd = scp.surg_proc_cd
   
   and n.nomenclature_id = spcr.nomenclature_id
   and (   n.source_identifier = '43775'
        or n.source_identifier = '43644'
        or n.source_identifier = '43645'
        or n.source_identifier = '43659'
        or n.source_identifier = '43846'
        or n.source_identifier = '43847'
        or n.source_identifier = '43633'
        or n.source_identifier = '43843'
        or n.source_identifier = '43842'
        or n.source_identifier = '43770'
        or n.source_identifier = '43771'
        or n.source_identifier = '43772'
        or n.source_identifier = '43773'
        or n.source_identifier = '43774'
        or n.source_identifier = '43886'
        or n.source_identifier = '43887'
        or n.source_identifier = '43888'
       )
   
   and e.encntr_id = sc.encntr_id
   
   and ea.encntr_id = e.encntr_id
   and ea.ENCNTR_ALIAS_TYPE_CD = 1077 ;fin
   and ea.active_ind = 1 

go