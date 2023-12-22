/*************************************************************************
 Program Title: Shield Appointment Data Extract

 Object name:   99_shield_extract_appt
 Source file:   99_shield_extract_appt.prg

 Purpose:       Retrieve information for the SHIELD data extract involving
                Appointment data and requested data around Appointments.

                For use in a scheduled job.  At the moment this is a Daily
                job scheduled to run on early mornings.

 Tables read:   diagnosis
                encounter
                nomenclature
                person
                person_alias
                prsnl
                prsnl_alias
                prsnl_group
                prsnl_group_reltn
                sch_appt

 Executed from: OpsJob (Olympus)

 Special Notes:

**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 12/26/2019 Michael Mayes        220867 Initial
002 04/15/2021 Michael Mayes        227001 MRN to CMRN        
003 04/28/2021 Michael Mayes        227003 Adding Telehealth ind
*************END OF ALL MODCONTROL BLOCKS* *******************************/
drop   program 99_shield_extract_appt:dba go
create program 99_shield_extract_appt:dba

prompt
      'Output to File/Printer/MINE'     = 'MINE'   ;* Enter or select the printer or file name to send this report to.
    , 'Enter start date (DD-MMM-YYYY):' = 'SYSDATE'
    , 'Enter end date (DD-MMM-YYYY):'   = 'SYSDATE'

with OUTDEV, BEG_DATE, END_DATE


/*************************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************************/
declare CSV_comma_esc(csv_str = vc) = vc


/*************************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************************/

free record extract_data
record extract_data(
    1 cnt                = i4
    1 qual[*]
        2 appt_id        = f8
        2 appt_id_txt    = vc ;I guess we need this to strip the .0s.
        2 appt_status    = vc
        2 sch_event_id   = f8
        2 appt_date      = vc
        2 appt_tm        = vc
        2 person_id      = f8
        2 encntr_id      = f8
        2 name_first     = vc
        2 name_last      = vc
        2 birth_dt_tm    = vc
        2 mrn            = vc
        2 prsnl_id       = f8
        2 doc_name_first = vc
        2 doc_name_last  = vc
        2 prescriber_npi = vc
        2 doc_spec       = vc
        2 clinic_name    = vc
        2 clinic_spec    = vc
        2 prindx         = vc
        2 telehealth     = vc  ;003
)


free set frec ;record used in the CCLIO process to create the ouput file
record frec(
    1 file_desc = i4
    1 file_name = vc
    1 file_buf = vc
    1 file_dir = i4
    1 file_offset = i4
)


/*************************************************************************
; DVDev DECLARED VARIABLES
**************************************************************************/
declare default_beg_dt   = dq8
declare default_end_dt   = dq8

declare patient_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING', 14250, 'PATIENT'                   ))
declare per_mrn_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',     4, 'CMRN'                      )) ;002

declare npi_cd           = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   320, 'NATIONALPROVIDERIDENTIFIER'))
declare spec_cd          = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 19189, 'SPECIALTYGROUP'            ))
declare dischg_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',    17, 'DISCHARGE'                 ))
declare final_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',    17, 'FINAL'                     ))

declare pos              = i4  with protect, noconstant(0)
declare pos2             = i4  with protect, noconstant(0)
declare idx              = i4  with protect, noconstant(0)
declare looper           = i4  with protect, noconstant(0)

declare shield_appt_file = vc  with protect, noconstant('MINE')

declare appt_id_txt_max  = i4  with protect, noconstant(0)
declare appt_status_max  = i4  with protect, noconstant(0)
declare name_first_max   = i4  with protect, noconstant(0)
declare name_last_max    = i4  with protect, noconstant(0)
declare mrn_max          = i4  with protect, noconstant(0)
declare doc_first_max    = i4  with protect, noconstant(0)
declare doc_last_max     = i4  with protect, noconstant(0)
declare npi_max          = i4  with protect, noconstant(0)
declare doc_spec_max     = i4  with protect, noconstant(0)
declare clinic_name_max  = i4  with protect, noconstant(0)
declare clinic_spec_max  = i4  with protect, noconstant(0)
declare prindx_max       = i4  with protect, noconstant(0)

declare out_str          = vc  with protect, noconstant('')
declare cr_char          = vc  with protect,   constant(char(13))
declare lf_char          = vc  with protect,   constant(char(10))
declare delim_char       = vc  with protect,   constant('|')

declare run_beg_dt_tm    = dq8 with protect,   constant(cnvtdatetime(curdate, curtime3))
declare run_end_dt_tm    = dq8 with protect, noconstant(cnvtdatetime(curdate, curtime3))

/*************************************************************************
; DVDev Start Coding
**************************************************************************/

;If we are running in an extract, we'll pass in 0 dates, and we should find our own extract time frame based on when the extract is
;run
if($beg_date = '0' and $end_date = '0')
    ;7 day forward window

    /*
    So if today is Monday the 17th, we want this to be 17-24th.
    */

    set default_beg_dt = datetimefind(cnvtdatetime(curdate, curtime3), 'D', 'B', 'B') ;Beginning of Today.
    set default_end_dt = datetimefind(datetimeadd(default_beg_dt, 6), 'D', 'E', 'E') ;Beginning of Yesterday

    declare beg_dt_tm  = dq8 with protect, constant(default_beg_dt)
    declare end_dt_tm  = dq8 with protect, constant(default_end_dt)

    call echo('Defaulted dates:')

else
    declare beg_dt_tm  = dq8 with protect, constant(cnvtdatetime($beg_date))
    declare end_dt_tm  = dq8 with protect, constant(cnvtdatetime($end_date))

    call echo('Adhoc dates:')
endif


call echo(concat('BEG_DT_TM:', format(beg_dt_tm, '@SHORTDATETIME')))
call echo(concat('END_DT_TM:', format(end_dt_tm, '@SHORTDATETIME')))

if($OUTDEV = 'EXTRACTTEST')
    set shield_appt_file = concat('cust_output:shield/historical/medstar_appointments_',
                                  trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'),3),
                                  '.dat')
elseif($OUTDEV = 'EXTRACT')
    set shield_appt_file = concat('cust_output:shield/medstar_appointments_',
                                  trim(format(cnvtdate(curdate), 'YYYYMMDD;;d'), 3),
                                  '.dat')
else
    set shield_appt_file = $OUTDEV
endif

call echo(concat('File Location: ', shield_appt_file))


/*************************************************************************
DESCRIPTION:  Find main appointment data
       NOTE:  This is doing some goofy performance stuff... It really
              wanted to skip scan XIE14, but I think the XIE2 range scan
              performed better... bad stats?

              Anyway, I've separated this out to separate queries which
              I suppose is still a bit gross.
**************************************************************************/
select into 'nl:'
  from sch_appt sa
     , sch_appt sa2
     , person   p
 where sa.beg_dt_tm         >= cnvtdatetime(beg_dt_tm)
   and sa.beg_dt_tm         <= cnvtdatetime(end_dt_tm)
   and sa.active_ind        =  1
   and sa.person_id         != 0
   and sa.sch_role_cd       =  patient_cd
   and sa.person_id         =  p.person_id
   and p.active_ind         =  1
   and sa2.sch_event_id     =  outerjoin(sa.sch_event_id)
   and sa2.sch_role_cd      != outerjoin(patient_cd)
   and sa2.person_id        != outerjoin(0)
order by sa.sch_event_id,  sa.schedule_seq desc
detail
    pos2 = locateval(idx, 1, size(extract_data->qual, 5), sa.sch_event_id, extract_data->qual[idx]->sch_event_id)

    ;We are descending on the schedule seq... so we just want the first (latest value)
    if(pos2 = 0)
        extract_data->cnt = extract_data->cnt + 1

        ;For cleaner code below
        pos = extract_data->cnt

        if(extract_data->cnt > size(extract_data->qual, 5))
            stat = alterlist(extract_data->qual, extract_data->cnt + 9)
        endif

        extract_data->qual[pos]->appt_id        = sa.sch_event_id
        extract_data->qual[pos]->appt_status    = trim(sa.state_meaning,3)
        extract_data->qual[pos]->sch_event_id   = sa.sch_event_id

        extract_data->qual[pos]->person_id      = sa.person_id
        extract_data->qual[pos]->encntr_id      = sa.encntr_id
        extract_data->qual[pos]->appt_date      = format(sa.beg_dt_tm, 'YYYYMMDD;;d')
        extract_data->qual[pos]->appt_tm        = format(sa.beg_dt_tm, 'HH:MM;;m')
        extract_data->qual[pos]->name_first     = trim(p.name_first, 3)
        extract_data->qual[pos]->name_last      = trim(p.name_last, 3)
        extract_data->qual[pos]->birth_dt_tm    = format(p.birth_dt_tm, 'YYYYMMDD;;d')

        if(sa2.person_id > 0)
            extract_data->qual[pos]->prsnl_id   = sa2.person_id
        endif

        extract_data->qual[pos]->clinic_name    = trim(uar_get_code_display(sa.appt_location_cd), 3)
        ;extract_data->qual[pos]->clinic_spec    =
    endif

foot report
    stat = alterlist(extract_data->qual, extract_data->cnt)

;Deliberately leaving nocounter off here so I can see the counts rise on the query as I'm waiting
;troubleshooting with maxqual, if you need it, comment the order by
;with orahintcbo('INDEX (SA XIE2SCH_APPT)'), maxqual(sa, 10)
with counter, orahintcbo('INDEX (SA XIE2SCH_APPT)')


;003->
/*************************************************************************
DESCRIPTION:  Find Telehealth appt types on sch_event appt_type_cd column
       NOTE:  Guessing a bit... but these look like they have displays
              of *telehealth* or *EVISIT*'
              
              I don't think I need to do sch_seq work here?
**************************************************************************/
select into 'nl:'
  from sch_event se
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->qual[d.seq]->sch_event_id != 0
  join se
   where se.sch_event_id = extract_data->qual[d.seq]->sch_event_id
detail
    if(uar_get_code_display(se.appt_type_cd) in ( '*E-VISIT*'
                                                    , '*Telehealth*'
                                                    ))
        extract_data->qual[d.seq]->telehealth = 'Yes'
    else
        extract_data->qual[d.seq]->telehealth = 'No'
    endif
with nocounter
;003<-

/*************************************************************************
DESCRIPTION:  Find locations for those not on SCH_APPT
       NOTE:  Looks like sometimes SCH_APPT.APPT_LOCATION_CD is unfilled.
              Trying to get this information off the encounter.
**************************************************************************/
select into 'nl:'
  from encounter e
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                      >  0
     and extract_data->qual[d.seq]->encntr_id   >  0
     and extract_data->qual[d.seq]->clinic_name =  ''
  join e
   where e.encntr_id                            =  extract_data->qual[d.seq]->encntr_id
     and e.active_ind                           =  1
detail
    extract_data->qual[d.seq]->clinic_name      =  trim(uar_get_code_display(e.location_cd), 3)
with nocounter


/*************************************************************************
DESCRIPTION:  Find person_alias info
**************************************************************************/
select into 'nl:'
  from person_alias pa
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->person_id != 0
  join pa
   where pa.person_id                         =  extract_data->qual[d.seq]->person_id
     and pa.person_alias_type_cd              =  per_mrn_cd
     and pa.alias                             >  ' '
     and pa.active_ind                        =  1
     and pa.beg_effective_dt_tm               <= cnvtdatetime(curdate, curtime3)
     and pa.end_effective_dt_tm               >= cnvtdatetime(curdate, curtime3)
detail
    extract_data->qual[d.seq]->mrn = trim(pa.alias, 3)
with nocounter


/*************************************************************************
DESCRIPTION:  Find PrinDx
**************************************************************************/
select into 'nl:'
  from diagnosis    dx
     , nomenclature n
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                    >  0
     and extract_data->qual[d.seq]->encntr_id != 0
  join dx
   where dx.encntr_id           =  extract_data->qual[d.seq]->encntr_id
     and dx.diag_type_cd        in (dischg_cd, final_cd)
     and dx.active_ind          =  1
     and dx.diag_priority       =  1
     and dx.beg_effective_dt_tm <= cnvtdatetime(curdate , curtime3)
     and dx.end_effective_dt_tm >= cnvtdatetime(curdate , curtime3)
  join n
   where dx.nomenclature_id     =  n.nomenclature_id
     and n.active_ind           =  1
     and n.beg_effective_dt_tm  <= cnvtdatetime(curdate , curtime3)
     and n.end_effective_dt_tm  >= cnvtdatetime(curdate , curtime3)
detail
    extract_data->qual[d.seq]->prindx = trim(n.source_identifier, 3)
with nocounter


/*************************************************************************
DESCRIPTION:  Find provider/or clinic information
**************************************************************************/
select into 'nl:'
  from prsnl per
     , prsnl_alias pa
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                   >  0
     ;and extract_data->qual[d.seq]->prsnl_id != 0 ;actually we don't want this.  We're going to catch these
                                                   ;cases below.
  join per
   where per.person_id                       =  extract_data->qual[d.seq]->prsnl_id
  join pa
   where pa.person_id                        =  outerjoin(per.person_id)
     and pa.active_ind                       =  outerjoin(1)
     and pa.beg_effective_dt_tm              <= outerjoin(cnvtdatetime(curdate,curtime3))
     and pa.end_effective_dt_tm              >= outerjoin(cnvtdatetime(curdate,curtime3))
     and pa.prsnl_alias_type_cd              =  outerjoin(npi_cd)
order by pa.person_id
detail
    if(extract_data->qual[d.seq]->prsnl_id != 0)
        extract_data->qual[d.seq]->prescriber_npi   = trim(pa.alias, 3)

        extract_data->qual[d.seq]->doc_name_last    = trim(per.name_last, 3)
        extract_data->qual[d.seq]->doc_name_first   = trim(per.name_first, 3)
    else
        extract_data->qual[d.seq]->doc_name_last    = extract_data->qual[d.seq]->clinic_name
    endif
with nocounter


/*************************************************************************
DESCRIPTION:  Find provider specialty
**************************************************************************/
select into 'nl:'
  from prsnl_group_reltn pgr
     , prsnl_group pg
     , (dummyt d with seq = value(extract_data->cnt))
  plan d
   where extract_data->cnt                   >  0
     and extract_data->qual[d.seq]->prsnl_id != 0
  join pgr
   where pgr.person_id                       =  extract_data->qual[d.seq]->prsnl_id
     and pgr.active_ind                      =  1
     and pgr.beg_effective_dt_tm             <= cnvtdatetime(curdate, curtime3)
     and pgr.end_effective_dt_tm             >= cnvtdatetime(curdate, curtime3)
  join pg
   where pg.prsnl_group_id                   =  pgr.prsnl_group_id
     and pg.active_ind                       =  1
     and pg.beg_effective_dt_tm              <= cnvtdatetime(curdate, curtime3)
     and pg.end_effective_dt_tm              >= cnvtdatetime(curdate, curtime3)
     and pg.prsnl_group_class_cd             =  spec_cd
detail
    extract_data->qual[d.seq]->doc_spec = trim(uar_get_code_display(pg.prsnl_group_type_cd), 3)
with nocounter


;Lets find the maxlengths of the columns
for(looper = 1 to extract_data->cnt)
    set extract_data->qual[looper]->appt_id_txt     = cnvtstring(extract_data->qual[looper]->appt_id, 11, 0)

    ;Finding the evil chars causing new lines and such in the file
    set extract_data->qual[looper]->appt_id_txt     = CSV_comma_esc(extract_data->qual[looper]->appt_id_txt   )
    set extract_data->qual[looper]->appt_status     = CSV_comma_esc(extract_data->qual[looper]->appt_status   )
    set extract_data->qual[looper]->name_first      = CSV_comma_esc(extract_data->qual[looper]->name_first    )
    set extract_data->qual[looper]->name_last       = CSV_comma_esc(extract_data->qual[looper]->name_last     )
    set extract_data->qual[looper]->mrn             = CSV_comma_esc(extract_data->qual[looper]->mrn           )
    set extract_data->qual[looper]->doc_name_first  = CSV_comma_esc(extract_data->qual[looper]->doc_name_first)
    set extract_data->qual[looper]->doc_name_last   = CSV_comma_esc(extract_data->qual[looper]->doc_name_last )
    set extract_data->qual[looper]->prescriber_npi  = CSV_comma_esc(extract_data->qual[looper]->prescriber_npi)
    set extract_data->qual[looper]->doc_spec        = CSV_comma_esc(extract_data->qual[looper]->doc_spec      )
    set extract_data->qual[looper]->clinic_name     = CSV_comma_esc(extract_data->qual[looper]->clinic_name   )
    set extract_data->qual[looper]->clinic_spec     = CSV_comma_esc(extract_data->qual[looper]->clinic_spec   )
    set extract_data->qual[looper]->prindx          = CSV_comma_esc(extract_data->qual[looper]->prindx        )


    if(appt_id_txt_max < size(extract_data->qual[looper]->appt_id_txt, 3))
        set appt_id_txt_max = size(extract_data->qual[looper]->appt_id_txt, 3)
    endif

    if(appt_status_max < size(extract_data->qual[looper]->appt_status, 3))
        set appt_status_max = size(extract_data->qual[looper]->appt_status, 3)
    endif

    if(name_first_max < size(extract_data->qual[looper]->name_first, 3))
        set name_first_max = size(extract_data->qual[looper]->name_first, 3)
    endif

    if(name_last_max < size(extract_data->qual[looper]->name_last, 3))
        set name_last_max = size(extract_data->qual[looper]->name_last, 3)
    endif

    if(mrn_max < size(extract_data->qual[looper]->mrn, 3))
        set mrn_max = size(extract_data->qual[looper]->mrn, 3)
    endif

    if(doc_first_max < size(extract_data->qual[looper]->doc_name_first, 3))
        set doc_first_max = size(extract_data->qual[looper]->doc_name_first, 3)
    endif

    if(doc_last_max < size(extract_data->qual[looper]->doc_name_last, 3))
        set doc_last_max = size(extract_data->qual[looper]->doc_name_last, 3)
    endif

    if(npi_max < size(extract_data->qual[looper]->prescriber_npi, 3))
        set npi_max = size(extract_data->qual[looper]->prescriber_npi, 3)
    endif

    if(doc_spec_max < size(extract_data->qual[looper]->doc_spec, 3))
        set doc_spec_max = size(extract_data->qual[looper]->doc_spec, 3)
    endif

    if(clinic_name_max < size(extract_data->qual[looper]->clinic_name, 3))
        set clinic_name_max = size(extract_data->qual[looper]->clinic_name, 3)
    endif

    ;Since we are packing two data points in here, we need the max of both
    if(doc_last_max < clinic_name_max)
        set doc_last_max = clinic_name_max
    endif

    if(clinic_spec_max < size(extract_data->qual[looper]->clinic_spec, 3))
        set clinic_spec_max = size(extract_data->qual[looper]->clinic_spec, 3)
    endif

    if(prindx_max < size(extract_data->qual[looper]->prindx, 3))
        set prindx_max = size(extract_data->qual[looper]->prindx, 3)
    endif

endfor


set run_end_dt_tm    = cnvtdatetime(curdate, curtime3)


;Draw out the file.  I tried doing this in dummyts but due to the with clauses we had to use, we were
;getting different operation from the opsjob vs the manual runs.
set frec->file_name = shield_appt_file ;set the file name/location
set frec->file_buf  = "w"
set stat = cclio("OPEN",frec) ;open the file and prepare for writing

set out_str = notrim(check(build2(
    'APPOINTMENT_ID'    ,delim_char,
    'APPOINTMENT_STATUS',delim_char,
    'MRN_PATIENT'       ,delim_char,
    'NAMEFIRST_PATIENT' ,delim_char,
    'NAMELAST_PATIENT'  ,delim_char,
    'DOB_PATIENT'       ,delim_char,
    'APPT_DATE'         ,delim_char,
    'APPT_TIME'         ,delim_char,
    'NAMELAST_DOC'      ,delim_char,
    'NAMEFIRST_DOC'     ,delim_char,
    'SPECIALTY_DOC'     ,delim_char,
    'PRESCRIBER_NPI'    ,delim_char,
    'CLINIC_NAME'       ,delim_char,
    'CLINIC_SPECIALTY'  ,delim_char,
    'ICD1_RX'           ,delim_char,
    'APPOINTMENT_TYPE'               ;003
)))


set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
set stat = cclio("WRITE",frec)


for(looper = 1 to extract_data->cnt)
    ;I don't really need all the dumb max vars anymore since we are not in a query...
    ;however I'm just going to keep it for now.
    set out_str = notrim(build2(
        trim(substring(1, value(appt_id_txt_max), extract_data->qual[looper]->appt_id_txt   ),3), delim_char,
        trim(substring(1, value(appt_status_max), extract_data->qual[looper]->appt_status   ),3), delim_char,
        trim(substring(1, value(mrn_max        ), extract_data->qual[looper]->mrn           ),3), delim_char,
        trim(substring(1, value(name_first_max ), extract_data->qual[looper]->name_first    ),3), delim_char,
        trim(substring(1, value(name_last_max  ), extract_data->qual[looper]->name_last     ),3), delim_char,
        trim(substring(1,                     10, extract_data->qual[looper]->birth_dt_tm   ),3), delim_char,
        trim(substring(1,                     10, extract_data->qual[looper]->appt_date     ),3), delim_char,
        trim(substring(1,                      6, extract_data->qual[looper]->appt_tm       ),3), delim_char,
        trim(substring(1, value(doc_last_max   ), extract_data->qual[looper]->doc_name_last ),3), delim_char,
        trim(substring(1, value(doc_first_max  ), extract_data->qual[looper]->doc_name_first),3), delim_char,
        trim(substring(1, value(doc_spec_max   ), extract_data->qual[looper]->doc_spec      ),3), delim_char,
        trim(substring(1, value(npi_max        ), extract_data->qual[looper]->prescriber_npi),3), delim_char,
        trim(substring(1, value(clinic_name_max), extract_data->qual[looper]->clinic_name   ),3), delim_char,
        trim(substring(1, value(clinic_spec_max), extract_data->qual[looper]->clinic_spec   ),3), delim_char,
        trim(substring(1, value(prindx_max     ), extract_data->qual[looper]->prindx        ),3), delim_char,
        trim(substring(1,                     10, extract_data->qual[looper]->telehealth    ),3)               ;003
    ))

    set frec->file_buf = notrim(build2(out_str,cr_char,lf_char))
    set stat = cclio("WRITE",frec)
endfor

set stat = cclio("CLOSE",frec)


/*************************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************************/
/* CSV_comma_esc
   This subroutine should check a string, looking for a delim within it.
   If found, remove it.  We also remove other chars that are problems.

   Input:
        csv_str (vc): The string to check

   Output:
        ret_str (vc): The string wrapped in quotes if a comma is found, or
                      as is if not.

   NOTES:
        It might be worthwhile to have it check to see if we have quotes already too?

*/
subroutine CSV_comma_esc(csv_str)
    declare ret_str = vc with protect, noconstant(csv_str)

    ;replace bad chars now
    set ret_str = replace(ret_str, char(10), '')
    set ret_str = replace(ret_str, char(13), '')
    set ret_str = replace(ret_str, char(0), '')
    set ret_str = replace(ret_str, '|', '')

    ;if(findstring('|', ret_str) > 0)
    ;    set ret_str = concat('"', ret_str ,'"')
    ;endif

    return(ret_str)
end



#exit_script
;DEBUGGING
;call echorecord(extract_data)
call echo(concat('Script run time: ',
                  format(datetimediff(run_end_dt_tm, run_beg_dt_tm), "DD Days HH:MM:SS:CC;;Z")))

end
go
