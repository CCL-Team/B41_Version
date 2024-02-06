/*************************************************************************
 Program Title:   SBSM Immunizations
 
 Object name:     14_st_ob_imm
 Source file:     14_st_ob_imm.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2023-10-17 Michael Mayes        234863 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_ob_imm:dba go
create program 14_st_ob_imm:dba

%i cust_script:0_rtf_template_format.inc
%i cust_script:0_cust_ce_blob_func.inc
 

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/

if(validate(reply) = 0)
    record reply(
       1 text                       = vc
          1 status_data
             2 status               = c1
             2 subeventstatus[1]
                3 OperationName     = c25
                3 OperationStatus   = c1
                3 TargetObjectName  = c25
                3 TargetObjectValue = vc
    )
endif


free record data
record data(
    1 preg_lookback_dt = dq8
    1 tdap
        2 title        = vc
        2 admin        = vc  ;Yes No
        2 admin_dt     = dq8
        2 admin_dt_txt = vc
    1 covid
        2 title        = vc
        2 admin        = vc  ;Yes No
        2 admin_dt     = dq8
        2 admin_dt_txt = vc
    1 flu
        2 title        = vc
        2 admin        = vc  ;Yes No
        2 admin_dt     = dq8
        2 admin_dt_txt = vc
    1 rsv
        2 title        = vc
        2 admin        = vc  ;Yes No
        2 admin_dt     = dq8
        2 admin_dt_txt = vc
) 


record cells(
    1 cells[*]
        2 size = i4
)

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare soi_row(rs = vc(ref), cell1 = vc, cell2 = vc, cell3 = vc) = vc
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header   = vc  with protect, noconstant(' ')
declare tmp_str  = vc  with protect, noconstant(' ')

declare act_cd   = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'  ))
declare mod_cd   = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd  = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'    ))
declare altr_cd  = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED' ))


declare tdap1_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'TETANUSDIPHTHPERTUSSTDAPADULTADOL' ))

declare flu1_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'INFLUENZAVIRUSVACCINEH1N1INACT'    ))
declare flu2_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'INFLUENZAVIRUSVACCINEH1N1LIVE'     ))
declare flu3_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'INFLUENZAVIRUSVACCINEINACTIVATED'  ))
declare flu4_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'INFLUENZAVIRUSVACCINELIVE'         ))
declare flu5_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'INFLUENZAVIRUSVACCINELIVETRIVALENT'))

declare rsv1_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'RSVVACCINEPREFAPREFBRECOMBINANT'   ))
declare rsv2_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'RSVVACCINEPREF3RECOMBINANT'        ))
declare rsv3_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'NIRSEVIMABCVX306'                  ))
declare rsv4_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 200, 'NIRSEVIMABCVX307'                  ))




;declare looper       = i4  with protect

set data->tdap->title  = 'tdap'
set data->tdap->admin  = 'No'

set data->covid->title = 'covid'
set data->covid->admin = 'No'

set data->flu->title   = 'flu'
set data->flu->admin   = 'No'

set data->rsv->title   = 'rsv'
set data->rsv->admin   = 'No'

 

/**************************************************************
; DVDev Start Coding
**************************************************************/


/**********************************************************************
DESCRIPTION:  Find date range
      NOTES:  We want to find the range of the current active preg,
              and if we don't find one... just go back 10m
***********************************************************************/
select into 'nl:'
  
  from pregnancy_instance pi
 
 where pi.person_id        =  p_id
   and pi.preg_start_dt_tm >= cnvtlookbehind('10,M')
   and pi.preg_end_dt_tm   >  cnvtdatetime(curdate, curtime3)
   and pi.active_ind       =  1
   

order by pi.preg_start_dt_tm desc

head report
    data->preg_lookback_dt = pi.preg_start_dt_tm

with nocounter 


if(data->preg_lookback_dt = 0)
    set data->preg_lookback_dt = cnvtlookbehind('10,M')
endif





/**********************************************************************
DESCRIPTION:  Find Tdap immunization administration info.
      NOTES:  This one _is_ limited to the pregnancy period.
***********************************************************************/
select into 'nl:'
  
  from orders         o
     , clinical_event ce
     , ce_med_result  cmr 
 
 where o.person_id           =  p_id
   and o.catalog_cd          =  tdap1_cd
   
   and ce.order_id           =  o.order_id
   and ce.valid_until_dt_tm  >= cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
   
   and cmr.event_id          =  ce.event_id
   and cmr.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)

order by cmr.admin_start_dt_tm desc

head report
    data->tdap->admin        = 'Yes'
    data->tdap->admin_dt     = cmr.admin_start_dt_tm
    data->tdap->admin_dt_txt = format(cmr.admin_start_dt_tm, '@SHORTDATE')

with nocounter





/**********************************************************************
DESCRIPTION:  Find Influenza immunization administration info.
      NOTES:  This one _is_ limited to the pregnancy period.
              
              But... Health rec uses a bunch of CEs that are not 
              necessarily tied to orders.  So I'm just going to trust 
              CE for this one.
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
 
 where ce.person_id          =  p_id
   and ce.valid_until_dt_tm  >= cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
   and ce.event_cd           in ( flu1_cd
                                , flu2_cd
                                , flu3_cd
                                , flu4_cd
                                , flu5_cd
                                )

order by ce.event_end_dt_tm  desc

head report
    data->flu->admin        = 'Yes'
    data->flu->admin_dt     = ce.event_end_dt_tm
    data->flu->admin_dt_txt = format(ce.event_end_dt_tm, '@SHORTDATE')

with nocounter



/**********************************************************************
DESCRIPTION:  Find Covid immunization administration info.
      NOTES:  This one _is NOT_ limited to the pregnancy period.
              
              Trusting a program changed within this year called
              14_covid_org_summary.  I hope it identified the right
              stuff.
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
 
 where ce.person_id          =  p_id
   and ce.valid_until_dt_tm  >= cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
   
   and exists(
       select 'X'
         
         from code_value       parent
            , code_value_group cvg
            , code_value       child
       
        where parent.code_set       = 100770  ;Ambulatory Custom MPages Groupings
          and parent.display_key    = 'COVIDVACCINES' 
          
          and cvg.parent_code_value = parent.code_value
          
          and child.code_value      = cvg.child_code_value
          and ce.event_cd           = child.code_value
   )
   and ce.event_tag          != "*Not Given*"
   and ce.event_class_cd     =  228.00  ;IMMUNIZATION
		

order by ce.event_end_dt_tm  desc

head report
    data->covid->admin        = 'Yes'
    data->covid->admin_dt     = ce.event_end_dt_tm
    data->covid->admin_dt_txt = format(ce.event_end_dt_tm, '@SHORTDATE')

with nocounter


/**********************************************************************
DESCRIPTION:  Find RSV immunization administration info.
      NOTES:  This one _is_ limited to the pregnancy period.
***********************************************************************/
select into 'nl:'
  
  from orders         o
     , clinical_event ce
     , ce_med_result  cmr 
 
 where o.person_id           =  p_id
   and o.catalog_cd          in (rsv1_cd, rsv2_cd, rsv3_cd, rsv4_cd)
   
   and ce.order_id           =  o.order_id
   and ce.valid_until_dt_tm  >= cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
   
   and cmr.event_id          =  ce.event_id
   and cmr.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)

order by cmr.admin_start_dt_tm desc

head report
    data->rsv->admin        = 'Yes'
    data->rsv->admin_dt     = cmr.admin_start_dt_tm
    data->rsv->admin_dt_txt = format(cmr.admin_start_dt_tm, '@SHORTDATE')

with nocounter


   
;Presentation
;Set up table information
 
set stat = alterlist(cells->cells, 3)
 
set cells->cells[ 1]->size =  2500
set cells->cells[ 2]->size =  4250
set cells->cells[ 3]->size =  6000

 
 
;RTF header
set header = notrim(build2(rhead))

set tmp_str = wr

set tmp_str = notrim(build2(tmp_str, soi_row(cells, 'Immunization Given', 'Adminstered?', 'Administered Date')))

set tmp_str = notrim(build2(tmp_str, soi_row(cells, data->tdap->title , data->tdap->admin , data->tdap->admin_dt_txt )))
set tmp_str = notrim(build2(tmp_str, soi_row(cells, data->covid->title, data->covid->admin, data->covid->admin_dt_txt)))
set tmp_str = notrim(build2(tmp_str, soi_row(cells, data->flu->title  , data->flu->admin  , data->flu->admin_dt_txt  )))
set tmp_str = notrim(build2(tmp_str, soi_row(cells, data->rsv->title  , data->rsv->admin  , data->rsv->admin_dt_txt  )))



 
call include_line(build2(header, tmp_str, RTFEOF))
 
;build reply text
for (cnt = 1 to drec->line_count)
	set  reply -> text  =  concat ( reply -> text, drec -> line_qual [ cnt ]-> disp_line )
endfor
 
set drec->status_data->status = "S"
set reply->status_data->status = "S"
 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
subroutine soi_row(rs, cell1, cell2, cell3)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(cells, 1),
                    rtf_cell(notrim(build2(' ', cell1)), 0),
                    rtf_cell(notrim(build2(' ', cell2)), 0),
                    rtf_cell(notrim(build2(' ', cell3)), 1)
 
    )
 
    return (dr_ret_str)
end






call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go