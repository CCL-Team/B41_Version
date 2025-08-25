/******************************************************************************************
 Program Title: Women's Health Rh Negative Report

 Object name:   14_wh_rh_neg_rep
 Source file:   14_wh_rh_neg_rep.prg

 Purpose:       A reporting tool that will identify OB patients that are Rh negative, their
                due date, and the time frame of when they will be 28 weeks

 Tables read:

 Executed from:

 Special Notes:

*******************************************************************************************
                  MODIFICATION CONTROL LOG
*******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ ------------------------------------------------
001 08/22/2024 Michael Mayes        347770 Initial release
*************END OF ALL MODCONTROL BLOCKS* ************************************************/
drop   program 14_wh_rh_neg_rep:dba go
create program 14_wh_rh_neg_rep:dba

prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Start Date"                = "SYSDATE"
    , "End Date"                  = "SYSDATE"
    , "Organization Search"       = ""
    ;<<hidden>>"Search"           = 0
    , "Organization"              = 0.0
    , "Provider Search"           = ""
    ;<<hidden>>"Search"           = ""
    , "Provider"                  = VALUE(0.0)
    , "Report Type"               = 1

with OUTDEV, BEG_DT, END_DT, ORG_SEARCH, ORG_IDS, PROV_SEARCH, PROV_IDS, TYPE


/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record data(
    1 cnt = i4
    1 qual[*]
        2 encntr_id             = f8
        2 person_id             = f8

        2 pat_name_last         = vc
        2 pat_name_first        = vc
        2 pat_dob               = dq8
        2 pat_dob_txt           = vc
        2 pat_empi              = vc

        2 preg_id               = f8
        2 preg_beg_dt           = dq8
        2 preg_end_dt           = dq8

        2 edd                   = dq8
        2 edd_txt               = vc
        
        2 wk_28                 = dq8
        2 wk_28_txt             = vc
        2 wk_28_beg             = dq8
        2 wk_28_beg_txt         = vc
        2 wk_28_end             = dq8
        2 wk_28_end_txt         = vc

        2 blood_dt              = dq8
        2 blood_type            = vc
        2 blood_rh              = vc

        2 rhogam_event_id       = f8
        2 rhogam_dt_tm          = dq8
        2 rhogam_txt            = vc
)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'                        ))
declare mod_cd               = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'                      ))
declare auth_cd              = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'                          ))
declare altr_cd              = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'                       ))

declare empi_cd              = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     4, 'COMMUNITYMEDICALRECORDNUMBER'  ))

declare blood_type_cd        = f8  with protect,   constant(uar_get_code_by(   'DISPLAY',    72, 'Patient Blood Type'            ))
declare blood_unit_type      = f8  with protect,   constant(uar_get_code_by(   'DISPLAY',    72, 'Blood Unit Type'               ))
declare blood_unit_type1     = f8  with protect,   constant(uar_get_code_by(   'DISPLAY',    72, 'Blood Unit Type:'              ))
declare blood_type_ext       = f8  with protect,   constant(uar_get_code_by(   'DISPLAY',    72, 'Blood Type, External'          ))
declare blood_type_trans     = f8  with protect,   constant(uar_get_code_by(   'DISPLAY',    72, 'Blood Type, Transcribed'       ))

declare rhtype_cd            = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'RHTYPE'                        ))

declare rhogam_cd            = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  1604, 'RHOGAM'                        ))
declare transfuse_cd         = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",  1610, 'TRANSFUSED'                    ))

/*************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('act_cd          :', act_cd          ))
call echo(build('mod_cd          :', mod_cd          ))
call echo(build('auth_cd         :', auth_cd         ))
call echo(build('altr_cd         :', altr_cd         ))

call echo(build('empi_cd         :', empi_cd         ))

call echo(build('blood_type_cd   :', blood_type_cd   ))
call echo(build('blood_unit_type :', blood_unit_type ))
call echo(build('blood_unit_type1:', blood_unit_type1))
call echo(build('blood_type_ext  :', blood_type_ext  ))
call echo(build('blood_type_trans:', blood_type_trans))

call echo(build('rhtype_cd:', rhtype_cd))

call echo(build('rhogam_cd:', rhogam_cd))


/**********************************************************************
DESCRIPTION:  Check for Any Any case and prevent
      NOTES:  We want to prevent a case where we have any location
              any provider... as we'll pull all encounters... ever...
***********************************************************************/
if(   0 in ($org_ids)
   and (    0 in ($prov_ids)
        or -1 in ($prov_ids)
       )
  )

       select into $OUTDEV
         from dummyt
        detail
            row + 1
            col 1 "Please use a non-any value for provider or location.."
            col 25
            row + 1
            col 1  "Please Try Your Search Again"
            row + 1
        with format, separator = " "

    go to exit_script

endif


/**********************************************************************
DESCRIPTION:  Find patient pop and basic information
      NOTES:
***********************************************************************/
select into 'nl:'
  from org_set        os
     , org_set_org_r  osor
     , organization   o
     , location       l
     
     , encounter      e
     , person         p


 where os.name               in ('*Amb*','*Medstar Facilities*')
   and os.active_ind         =  1

   and osor.org_set_id       =  os.org_set_id
   and osor.active_ind       =  1

   and o.organization_id     =  osor.organization_id
   and o.active_ind          =  1
   and (   0                 in ($org_ids)  ;The any box
        or o.organization_id in ($org_ids)  ;Or the filters coming in
       )
   and o.organization_id not in(   589723.00
                               ,   627889.00
                               ,   628009.00
                               ,   628058.00
                               ,   628085.00
                               ,   628088.00
                               ,   628738.00
                               ,   640191.00
                               ,   640192.00
                               ,   640194.00
                               ,   640196.00
                               ,   642194.00
                               ,   664189.00
                               ,   807419.00
                               ,   807425.00
                               ,   807427.00
                               ,  3440653.00
                               ,  3476823.00
                               ,  4678436.00
                               ,  5335375.00
                               ,  5335384.00
                               ,  6591470.00
                               ,  7232532.00
                               ,  7232553.00
                               ,  7232577.00
                               ,  7232590.00
                               ,  7232615.00
                               ,  7316485.00
                               ,  8608690.00
                               ,  8611509.00
                               ,  9308346.00
                               ,  9448872.00
                               ,  9514275.00
                               ,  1325870.00
                               ,  1650929.00
                               ,  2650023.00
                               ,  3433629.00
                               , 10608377.00
                               , 10608446.00
                               , 10679417.00
                               , 10843874.00
                               , 10925508.00
                               , 12012326.00
                               )

   and l.organization_id     =  o.organization_id
   and l.location_type_cd    =  ( select cv.code_value
                                    from code_value cv
                                   where cv.code_set = 222
                                     and cdf_meaning = 'FACILITY'
                                )
   and l.beg_effective_dt_tm <  cnvtdatetime(curdate, curtime3)
   and l.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and l.active_ind = 1

   and e.organization_id     =  o.organization_id
   and e.reg_dt_tm           between cnvtdatetime($beg_dt) and cnvtdatetime($end_dt)
   
   and (    0 in ($prov_ids)
        or exists(select 'x'
                    from person_prsnl_reltn ppr
                   where ppr.prsnl_person_id in ($prov_ids)
                     and ppr.person_id = e.person_id
                 )
        or exists(select 'x'
                    from encntr_prsnl_reltn epr
                   where epr.prsnl_person_id in ($prov_ids)
                     and epr.encntr_id = e.encntr_id
                 )
       )

   and p.person_id           =  e.person_id

order by e.person_id, e.reg_dt_tm desc

head e.person_id

    data->cnt = data->cnt + 1

    if(mod(data->cnt, 10) = 1)
        stat = alterlist(data->qual, data->cnt + 9)
    endif

    data->qual[data->cnt]->person_id      = e.person_id
    data->qual[data->cnt]->encntr_id      = e.encntr_id

    data->qual[data->cnt]->pat_name_last  = p.name_last
    data->qual[data->cnt]->pat_name_first = p.name_first

    data->qual[data->cnt]->pat_dob        = p.birth_dt_tm
    data->qual[data->cnt]->pat_dob_txt    = format(p.birth_dt_tm, 'MM/DD/YYYY;;q')

foot report
    stat = alterlist(data->qual, data->cnt)

with nocounter


/**********************************************************************
DESCRIPTION:  Find EMPI
***********************************************************************/
select into 'nl:'

  from person_alias pa
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->person_id >  0

  join pa
   where pa.person_id                 =  data->qual[d.seq]->person_id
     and pa.person_alias_type_cd      =  empi_cd
     and pa.active_ind                =  1
     and pa.beg_effective_dt_tm       <= cnvtdatetime(curdate, curtime3)
     and pa.end_effective_dt_tm       >= cnvtdatetime(curdate, curtime3)

detail

    data->qual[d.seq]->pat_empi = cnvtalias(pa.alias, pa.alias_pool_cd)

with nocounter


/**********************************************************************
DESCRIPTION:  Find Blood Type
      NOTES:  I found a new table... but I'm finding this AFTER the 
              result work I am doing below.
              
              Going to try and use this then comment out the other stuff
              we had below I think.
***********************************************************************/
select into 'nl:'
  
  from person_aborh pa
     , (dummyt d with seq = data->cnt)
  
  
  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->person_id >  0
  
  join pa
   where pa.person_id = data->qual[d.seq]->person_id
     and pa.active_ind = 1
     and pa.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
  
detail
    data->qual[d.seq]->blood_dt   = pa.begin_effective_dt_tm

    data->qual[d.seq]->blood_type = uar_get_code_display(pa.abo_cd)
    data->qual[d.seq]->blood_rh   = uar_get_code_display(pa.rh_cd )

with nocounter

;/**********************************************************************
;DESCRIPTION:  Find Blood Type
;***********************************************************************/
;select into 'nl:'
;
;  from clinical_event ce
;     , (dummyt d with seq = data->cnt)
;
;  plan d
;   where data->cnt                    >  0
;     and data->qual[d.seq]->person_id >  0
;
;  join ce
;   where ce.person_id         =  data->qual[d.seq]->person_id
;     and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
;     and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
;     and ce.event_cd          in ( blood_type_cd , blood_unit_type     , blood_unit_type1
;                                 , blood_type_ext, blood_type_trans
;                                 )
;order by ce.person_id, ce.event_end_dt_tm desc
;
;head ce.person_id
;    data->qual[d.seq]->blood_dt       = ce.event_end_dt_tm
;
;    data->qual[d.seq]->blood_event_id = ce.event_id
;
;    data->qual[d.seq]->blood_type = replace(replace(cnvtupper(trim(ce.result_val, 3)), "POSITIVE", ""), "NEGATIVE", "")
;
;    if(findstring("POSITIVE", cnvtupper(trim(ce.result_val, 3))) > 0) data->qual[d.seq]->blood_rh = "POSITIVE"
;    endif
;    if(findstring("NEGATIVE", cnvtupper(trim(ce.result_val, 3))) > 0) data->qual[d.seq]->blood_rh = "NEGATIVE"
;    endif
;
;
;with nocounter
;
;
;/**********************************************************************
;DESCRIPTION:  Find RH
;***********************************************************************/
;select into 'nl:'
;
;  from clinical_event ce
;     , (dummyt d with seq = data->cnt)
;
;  plan d
;   where data->cnt                    >  0
;     and data->qual[d.seq]->person_id >  0
;
;  join ce
;   where ce.person_id         =  data->qual[d.seq]->person_id
;     and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
;     and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
;     and ce.event_cd          =  rhtype_cd
;
;order by ce.person_id, ce.event_end_dt_tm desc
;
;head ce.person_id
;
;    call echo(format(ce.event_end_dt_tm,';;q'))
;    call echo(format(cnvtdatetime(data->qual[d.seq]->blood_dt),';;q'))
;    if(ce.event_end_dt_tm > cnvtdatetime(data->qual[d.seq]->blood_dt))
;
;        call echo('yep')
;        data->qual[d.seq]->blood_rh = cnvtupper(trim(ce.result_val, 3))
;    endif
;
;
;with nocounter


/**********************************************************************
DESCRIPTION:  Trying for Rhogam
      NOTES:  This is all new to me... looking at a few scripts... looks
              like products are involved... not sure about that but
              trying it for now.

              jjk_bb_daily_rpt.prg (commented out code... similar to
                                    other places I've found
                                   )
              
              Actually going to try what 0x_token_rhogam_given.prg does.
***********************************************************************/
;select into 'nl:'
;
;  from clinical_event ce
;     , ce_product     cp
;     , product        p
;     , (dummyt d with seq = value(data->cnt))
;
;  plan d
;   where data->cnt                    >  0
;     and data->qual[d.seq]->person_id >  0
;
;  join ce
;   where ce.person_id         =  data->qual[d.seq]->person_id
;     and ce.event_cd          =  transfuse_cd
;     and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
;     and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
;
;  join cp
;   where cp.event_id = ce.event_id
;
;  join p
;   where p.product_id = cp.product_id
;     and p.product_cd = rhogam_cd
;
;order by ce.person_id, ce.event_end_dt_tm desc
;
;head ce.person_id
;
;    data->qual[d.seq]->rhogam_event_id = ce.event_id
;
;    data->qual[d.seq]->rhogam_dt_tm    = ce.event_end_dt_tm
;    data->qual[d.seq]->rhogam_txt      = format(ce.event_end_dt_tm,';;q')
;
;
;with nocounter
select into 'nl:'

  from orders o
     , clinical_event ce
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->person_id >  0
  
  join o
   where o.person_id           = data->qual[d.seq]->person_id
     and o.catalog_cd          = 2768135.000000  ;RHODIMMUNEGLOBULIN

  join ce
   where ce.order_id           =  o.order_id
     and ce.result_status_cd   in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)

order by ce.person_id, ce.event_end_dt_tm desc

head ce.person_id

    data->qual[d.seq]->rhogam_event_id = ce.event_id

    data->qual[d.seq]->rhogam_dt_tm    = ce.event_end_dt_tm
    data->qual[d.seq]->rhogam_txt      = format(ce.event_end_dt_tm,';;q')


with nocounter


;/**********************************************************************
;DESCRIPTION:  Find Active, or most recent pregnancy
;***********************************************************************/
select into 'nl:'
  
  from pregnancy_instance pi
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                    >  0
     and data->qual[d.seq]->person_id >  0
  
  join pi
   where pi.person_id = data->qual[d.seq]->person_id
     and pi.active_ind = 1
     and pi.preg_end_dt_tm > cnvtdatetime(curdate, curtime3)

order by pi.person_id, pi.preg_start_dt_tm

detail
    
    data->qual[d.seq]->preg_id     = pi.pregnancy_id
    data->qual[d.seq]->preg_beg_dt = pi.preg_start_dt_tm
    data->qual[d.seq]->preg_end_dt = pi.preg_end_dt_tm

with nocounter


;/**********************************************************************
;DESCRIPTION:  Find Active, or most recent pregnancy
;***********************************************************************/
select into 'nl:'
  
  from pregnancy_estimate pe
     , (dummyt d with seq = data->cnt)

  plan d
   where data->cnt                  >  0
     and data->qual[d.seq]->preg_id >  0
  
  join pe
   where pe.pregnancy_id  = data->qual[d.seq]->preg_id
     and pe.active_ind    = 1
     and pe.status_flag   = 2.00  ;Authoritative
     and pe.method_dt_tm  = (select max(pe2.method_dt_tm)
                               from pregnancy_estimate pe2
                              where pe2.pregnancy_id = pe.pregnancy_id
                                and pe2.active_ind   = 1
                                and pe2.status_flag  = 2.00  ;Authoritative
                            )

order by pe.pregnancy_id

detail
    
    data->qual[d.seq]->edd     = cnvtdatetime(datetimezoneformat(pe.est_delivery_dt_tm, pe.est_delivery_tz, "dd-MMM-yyyy"))
    data->qual[d.seq]->edd_txt = datetimezoneformat(pe.est_delivery_dt_tm, pe.est_delivery_tz, "dd-MMM-yyyy")
    
    ;What the heck do I do about the preg 28 weeks thing.  I have a EDD... how many weeks is that usually.
    ;I think we are assuming that pregs are 40 weeks.  So I can subtract 12 weeks from the EDD, and find that date... 
    ;then compute the week start and end as per requirements.
    
    data->qual[d.seq]->wk_28         = cnvtlookbehind('12,W', pe.est_delivery_dt_tm)
    data->qual[d.seq]->wk_28_beg     = datetimefind(cnvtdatetime(data->qual[d.seq]->wk_28), 'W', 'B', 'B')
    data->qual[d.seq]->wk_28_end     = datetimefind(cnvtdatetime(data->qual[d.seq]->wk_28), 'W', 'E', 'E')
    
    data->qual[d.seq]->wk_28_txt     = format(cnvtdatetime(data->qual[d.seq]->wk_28    ), ';;DD-MMM-YYYY')
    data->qual[d.seq]->wk_28_beg_txt = format(cnvtdatetime(data->qual[d.seq]->wk_28_beg), ';;DD-MMM-YYYY')
    data->qual[d.seq]->wk_28_end_txt = format(cnvtdatetime(data->qual[d.seq]->wk_28_end), ';;DD-MMM-YYYY')
    

with nocounter



;Presentation time
if($type = 1)
    if (data->cnt > 0)
        select into $outdev
               PAT_LAST_NAME               = trim(substring(1,  140, data->qual[d.seq].pat_name_last ))
             , PAT_FIRST_NAME              = trim(substring(1,  140, data->qual[d.seq].pat_name_first))
             , PAT_DOB                     = trim(substring(1,   12, data->qual[d.seq].pat_dob_txt   ))
             , PAT_EMPI                    = trim(substring(1,   20, data->qual[d.seq].pat_empi      ))
                                          
             , OB_EDD                      = trim(substring(1,   20, data->qual[d.seq].edd_txt       ))
             , WK_28_DATE_BASED_ON_EDD_EGA = trim(substring(1,   20, data->qual[d.seq].wk_28_txt     ))
             , BEG_WK_28_BASED_ON_EDD_EGA  = trim(substring(1,   20, data->qual[d.seq].wk_28_beg_txt ))
             , END_WK_28_BASED_ON_EDD_EGA  = trim(substring(1,   20, data->qual[d.seq].wk_28_end_txt ))

             , BLOOD_TYPE                  = trim(substring(1,   20, data->qual[d.seq].blood_type    ))
             , BLOOD_RH                    = trim(substring(1,   20, data->qual[d.seq].blood_rh      ))
                                           
             , LAST_RHOGAM                 = trim(substring(1,   20, data->qual[d.seq].rhogam_txt    ))



          from (dummyt d with SEQ = data->cnt)
        where data->qual[d.seq]->blood_rh =  'NEG'
          and data->qual[d.seq]->preg_id  != 0
          ;and data->qual[d.seq]->edd      >= cnvtdatetime(curdate, curtime3)
        with format, separator = " ", time = 300

    else
       select into $OUTDEV
         from dummyt
        detail
            row + 1
            col 1 "There were no results for your filter selections.."
            col 25
            row + 1
            col 1  "Please Try Your Search Again"
            row + 1
        with format, separator = " "
    endif

endif


/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

#exit_script
;DEBUGGING
call echorecord(data)

end
go
