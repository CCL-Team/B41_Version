/**************************************************************************
 Program Title:   mPage get obgyn high risk pats
 
 Object name:     cust_mp_high_risk_obgyn
 Source file:     cust_mp_high_risk_obgyn.prg
 
 Purpose:         Gets a list of high risk patients, qualifying with a 
                  complex set of specs, and filters for the page.
                  
                  TODO list specs
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 03/09/2021 Michael Mayes        218308    Initial release
002 08/27/2024 Michael Mayes        239854    Adding filter for provider and appt range.
*************END OF ALL MODCONTROL BLOCKS* ********************************/
  drop program cust_mp_high_risk_obgyn:dba go
create program cust_mp_high_risk_obgyn:dba

prompt
      "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Organization"                = 0.0
    , "Lookback"                    = 0.0
    , "Providers"                   = ""         ;002
    , "Beg Appt Date"               = "SYSDATE"  ;002
    , "End Appt Date"               = "SYSDATE"  ;002
with OUTDEV, ORGS, LOOKBACK, PROVIDERS, BEG_APPT_DT, END_APPT_DT 


/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc
%i cust_script:cust_timers_debug.inc

/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
;002->
free record gen_pop
record gen_pop(
    1 cnt           = i4
    1 qual[*]
        2 per_id    = f8
        2 enc_id    = f8
        2 appt_ind  = i2
)
;002<-

free record hpv_pats
record hpv_pats(
    1 cnt           = i4
    1 qual[*]
        2 per_id    = f8
        2 enc_id    = f8
        2 ord_id    = f8
)

free record high_risk_cyto
record high_risk_cyto(
    1 cnt           = i4
    1 qual[*]
        2 per_id    = f8
        2 enc_id    = f8
        2 ord_id    = f8
)

free record colposcopy
record colposcopy(
    1 cnt            = i4
    1 qual[*]
        2 per_id     = f8
        2 enc_id     = f8
        2 ord_id     = f8
        2 ord_dt     = dq8
        2 col_ind    = i2
        2 check_type = vc ;Maybe mostly debugging.
        2 age        = vc
)

free record tp_outstand
record tp_outstand(
    1 cnt            = i4
    1 qual[*]
        2 per_id     = f8
        2 enc_id     = f8
        2 ord_id     = f8
)

free record results
record results(
    1 cnt = i4
    1 qual[*]
        2 patient
            3 per_id               = f8
            3 enc_id               = f8
            3 location             = vc
            3 name                 = vc
            3 dob                  = vc
            3 phone                = vc
            3 pcp                  = vc
        2 last_appt                
            3 appt_id              = f8
            3 event_id             = f8
            3 location             = vc
            3 datetime             = vc
            3 sortdatetime         = vc
            3 prov_name            = vc
            3 appt_type_cd         = f8
            3 appt_type            = vc
        2 next_appt                
            3 appt_id              = f8
            3 event_id             = f8
            3 location             = vc
            3 datetime             = vc
            3 sortdatetime         = vc
            3 prov_name            = vc
            3 appt_type_cd         = f8
            3 appt_type            = vc
        2 obgyn_cnt                = i4
        2 obgyn[*]
            3 person_id            = f8
            3 name                 = vc
            3 encntr_person_flag   = vc  ; these are mainly debugging... 
            3 reltn_type_flag      = vc  ; these are mainly debugging... 
            3 position             = vc  ; these are mainly debugging... 
        2 reason_cnt               = i4
        2 reasons[*]
            3 reason_flag          = i4  ; 1 - out of care; 2 - high risk; 4 - Need Colposcopy; 8 - Pathology Outstanding
            3 reason_txt           = vc
        2 order_cnt                = i4
        2 orders[*]
            3 ord_id               = f8
            3 ord_enc_id           = f8
            3 ord_prov_id          = f8  ;002
            3 ord_prov_name        = vc  ;002
            3 order_name           = vc
            3 endorse_by           = vc
            3 endorse_dt_tm        = vc
            3 sort_endorse_dt_tm   = vc
            3 result_cnt           = i4
            3 ord_res[*]
                4 event_title      = vc
                4 event_id         = f8
        2 comment_cnt              = i4
        2 comments[*]
            3 com_event_id         = f8
            3 date_event_id        = f8
            3 comment              = vc
            3 followup_dt          = dq8
            3 followup_dt_txt      = vc
            3 followup_sort_dt_txt = vc
            3 event_end_dt         = dq8
            3 event_end_dt_txt     = vc
            3 prsnl_name           = vc
    1 stats
        2 out_care_cnt             = i4
        2 high_risk_cnt            = i4
        2 need_colpo_cnt           = i4
        2 tissue_path_cnt          = i4
%i cust_script:mmm_mp_status.inc
)

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
;declare start_dt_tm = dq8 with protect,   constant(cnvtdatetime($beg_range                            ))
;declare end_dt_tm   = dq8 with protect,   constant(cnvtdatetime($end_range                            ))

declare obgyn_cd        = f8  with protect,   constant(uar_get_code_by('MEANING'   ,   331, 'OBGYN'          ))
declare pcp_cd          = f8  with protect,   constant(uar_get_code_by('MEANING'   ,   331, 'PCP'            ))
                        
declare hpv_res_cd      = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'HPVAPTIMA'      ))
declare pap_dx_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    72, 'PAPDIAGNOSIS'   ))
                        
declare auth_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     8, 'AUTHVERIFIED'   ))
declare modified_cd     = f8  with protect,   constant(uar_get_code_by('MEANING'   ,     8, 'MODIFIED'       ))
declare altered_cd      = f8  with protect,   constant(uar_get_code_by('MEANING'   ,     8, 'ALTERED'        ))
                        
declare text_cd         = f8  with protect,   constant(uar_get_code_by('MEANING'   ,    53, 'TXT'            ))
                        
declare comp_cd         = f8  with protect,   constant(uar_get_code_by('MEANING'   ,   120, 'OCFCOMP'        ))
                        
declare endorse_cd      = f8  with protect,   constant(uar_get_code_by('MEANING'   ,    21, 'ENDORSE'        ))
declare perform_cd      = f8  with protect,   constant(uar_get_code_by('MEANING'   ,    21, 'PERFORM'        ))
                        
declare tissue_path_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   200, 'TISSUEPATHOLOGY'))
                        
declare discon_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'DISCONTINUED'   ))
declare cancel_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'CANCELED'       ))
declare voided_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',  6004, 'DELETED'        ))
                        
declare comment_cd      = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    72, 'AMBCERVCYTOCOMMENTMP' ))
declare due_dt_cd       = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    72, 'AMBCERVCYTOFOLLOWUPMP'))
                        
declare uncomp_blob     = vc  with protect, noconstant(notrim(fillstring(32767," "))) 
declare final_blob      = vc  with protect, noconstant(notrim(fillstring(32767," ")))
declare uncomp_size     = w8  ;002
                        
declare lookback_dt     = dq8 with protect
                        
declare cyto_flag       = i4  with protect, noconstant(0)
declare cyto_check      = i4  with protect, noconstant(0)
declare temp_ord_id     = f8  with protect, noconstant(0.0)
declare temp_ord_dt     = dq8 with protect
                        
declare looper          = i4  with protect, noconstant(0)
declare idx             = i4  with protect, noconstant(0)
declare pos             = i4  with protect, noconstant(0)
                        
declare result_pos      = i4  with protect, noconstant(0)
declare reason_pos      = i4  with protect, noconstant(0)
declare order_pos       = i4  with protect, noconstant(0)

declare temp_res_title  = vc  with protect, noconstant('')
                                                                                                              

declare prov_parser     = vc  with protect, noconstant('1=1')  ;002
declare prov_ord_parser = vc  with protect, noconstant('1=1')  ;002
                                                                                                              

declare appt_filt_ind   = i2  with protect, noconstant(0)

/**************************************************************
; DVDev Start Coding
**************************************************************/

case($LOOKBACK)
of 1: set lookback_dt = cnvtlookbehind('1,Y')
of 2: set lookback_dt = cnvtlookbehind('2,Y')
of 3: set lookback_dt = cnvtlookbehind('3,Y')
endcase

declare prog_timer = i4
set prog_timer = ctd_add_timer_seq('Cerv Cyto High Risk', 100)


;002->
if(0 not in ($providers))
    declare prov_str = vc with protect, noconstant('')
    
    select into 'nl:'
      from prsnl p
     where p.person_id in ($providers)
    detail
        if(prov_str = '') prov_str = trim(cnvtstring(p.person_id,17,2), 3)
        else              prov_str = build(prov_str, ',', trim(cnvtstring(p.person_id,17,2), 3))
        endif
    with nocounter
    
    set prov_parser = concat( ^exists (select 'x'                                       ^
                            , ^          from orders       o2                           ^
                            , ^             , order_action oa                           ^
                            , ^         where o2.order_id           =  ce.order_id      ^
                            , ^                                                         ^
                            , ^           and oa.order_id           =  o2.order_id      ^
                            , ^           and oa.action_type_cd     =  2534.0           ^              
                            , ^           and oa.order_provider_id in (^, prov_str, ^)  ^
                            , ^       )                                                 ^
                            )  
    
    set prov_ord_parser = concat( ^exists (select 'x'                                       ^
                                , ^          from order_action oa                           ^
                                , ^         where oa.order_id          =  o.order_id        ^
                                , ^           and oa.action_type_cd    =  2534.0            ^              
                                , ^           and oa.order_provider_id in (^, prov_str, ^)  ^
                                , ^       )                                                 ^
                                )  
                            
          
endif
call echo(prov_parser)
call echo(prov_ord_parser)

;002<-

;002->
if(    $BEG_APPT_DT > ' '
   and $END_APPT_DT > ' '
  )
    set appt_filt_ind = 1
endif
;002<-




;DEBUGGING
;set hpv_pats->cnt = 13
;set hpv_pats->cnt = hpv_pats->cnt + 1
;if(mod(hpv_pats->cnt, 10) = 1)
;    set stat = alterlist(hpv_pats->qual, hpv_pats->cnt + 9)
;endif
;
;set hpv_pats->qual[hpv_pats->cnt].per_id    = 16464238.00
;set hpv_pats->qual[hpv_pats->cnt].enc_id    = 77917886
;set hpv_pats->qual[hpv_pats->cnt].ord_id    = 0
;
;
;set hpv_pats->cnt = hpv_pats->cnt + 1
;if(mod(hpv_pats->cnt, 10) = 1)
;    set stat = alterlist(hpv_pats->qual, hpv_pats->cnt + 9)
;endif
;
;set hpv_pats->qual[hpv_pats->cnt].per_id    = 24147664.00
;set hpv_pats->qual[hpv_pats->cnt].enc_id    = 166701486.00
;set hpv_pats->qual[hpv_pats->cnt].ord_id    = 0
;
;
;set hpv_pats->cnt = hpv_pats->cnt + 1
;if(mod(hpv_pats->cnt, 10) = 1)
;    set stat = alterlist(hpv_pats->qual, hpv_pats->cnt + 9)
;endif
;
;set hpv_pats->qual[hpv_pats->cnt].per_id    = 29031830.00
;set hpv_pats->qual[hpv_pats->cnt].enc_id    = 171657022.00
;set hpv_pats->qual[hpv_pats->cnt].ord_id    = 0

;002->
;**************
; Going to try and improve performance by finding an encounter list to check everything against first.
;**************
call ctd_add_timer('General Population')
select into 'nl:'
  
  from encounter e
  
 where (0                       in ($ORGS)
        or e.organization_id    in ($ORGS)
       )
   and e.reg_dt_tm          >= cnvtdatetime(lookback_dt)
   
   and (   exists( select 'x'
                     from clinical_event ce
                    
                    where ce.encntr_id =  e.encntr_id
                      and ce.event_cd  =  hpv_res_cd
                      and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
                      and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
                 )
        or exists( select 'x'
                     from orders o
                    
                    where o.encntr_id  =  e.encntr_id
                      and o.catalog_cd =  tissue_path_cd
                 )
       )

order by e.person_id, e.reg_dt_tm desc

head e.encntr_id
    gen_pop->cnt = gen_pop->cnt + 1
    
    if(mod(gen_pop->cnt, 10) = 1)
        stat = alterlist(gen_pop->qual, gen_pop->cnt + 9)
    endif
    
    gen_pop->qual[gen_pop->cnt]->per_id = e.person_id
    gen_pop->qual[gen_pop->cnt]->enc_id = e.encntr_id
    
    if(appt_filt_ind = 0) gen_pop->qual[gen_pop->cnt]->appt_ind = 1  ;Just defaulting these guys in if we aren't filtering.
    endif
    
foot report
    stat = alterlist(gen_pop->qual, gen_pop->cnt)
    
with nocounter, orahintcbo('GATHER_PLAN_STATISTICS MONITOR mmm1745')
call ctd_end_timer(0)


if(appt_filt_ind = 1)
    call ctd_add_timer('Next Appointment Filter')
    select into 'nl:'
                                        ;TODO These might need codified?
           sort = if(per.position_cd in (915338723, 2229780007, 1842502051)) 0
                  else                                                       1
                  endif
      from sch_appt  sa
         , sch_appt  ap
         , prsnl     per
         , (dummyt d with seq = gen_pop->cnt)
      plan d
       where gen_pop->cnt                 >  0
         and gen_pop->qual[d.seq]->per_id != 0
         
      join sa
       where sa.person_id                  =  gen_pop->qual[d.seq]->per_id
         and sa.sch_role_cd                =  4572.000000                                 ;TODO codify?
         and sa.sch_state_cd               not in (4535.00, 4540.00) ;canceled deleted    ;TODO codify?
         and sa.beg_dt_tm                  >= cnvtdatetime(curdate, curtime3)
         and sa.schedule_seq               =  (select max(sa2.schedule_seq)
                                                 from sch_appt sa2
                                                where sa2.sch_event_id = sa.sch_event_id
                                              )
         and sa.beg_dt_tm                 >= cnvtdatetime($BEG_APPT_DT)
         and sa.beg_dt_tm                 <= cnvtdatetime($END_APPT_DT)
      
      join ap
       where ap.sch_event_id              =  sa.sch_event_id
         and ap.sch_role_cd               =  4574.000000  ;TODO codify?
       
      join per
       where per.person_id                =  ap.person_id
    
    order by sa.person_id, sort, sa.beg_dt_tm
    
    detail
            gen_pop->qual[d.seq]->appt_ind = 1
       
    with nocounter
    call ctd_end_timer(0)
endif

;002<-

;**************
; case 1 HPV positive, no repeat HPV testing or cytology within 1 year
;**************

/***********************************************************************
DESCRIPTION:  Gather HPV Positive patients without a test in the last 
              year.
       
       NOTE:  Query got confusing so this is what it is trying to do in 
              real human words.  We want to find patients that had a
              positive hpv result.  Of those patients we want to have 
              repeat testing done within the last year.  
              
              We can ignore patients that had a latest positive within
              the last year.
***********************************************************************/
call ctd_add_timer('Case 1')
select into 'nl:'
  from clinical_event ce
     , clinical_event ce2
     
 where expand(idx, 1, gen_pop->cnt, ce.encntr_id, gen_pop->qual[idx]->enc_id, 1, gen_pop->qual[idx]->appt_ind)  ;002
   and ce.event_cd              =  hpv_res_cd
   and ce.event_tag             = 'Positive'
   and ce.event_class_cd        =  text_cd
   and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
   and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
   and ce.event_end_dt_tm       <  cnvtlookbehind('1,Y')  ;Only consider results over a year old
   
   and parser(prov_parser)
   
   ;find other results within last year
   and ce2.person_id            =  outerjoin(ce.person_id)
   and ce2.event_cd             =  outerjoin(hpv_res_cd)
   and (   ce2.result_status_cd =  outerjoin(auth_cd)
        or ce2.result_status_cd =  outerjoin(modified_cd)
        or ce2.result_status_cd =  outerjoin(altered_cd)
       )
   and ce2.valid_until_dt_tm    >  outerjoin(cnvtdatetime(curdate,curtime3))
   and ce2.event_end_dt_tm      >= outerjoin(cnvtlookbehind('1,Y'))  ;Only consider within the last year
   
   
order by ce.person_id, ce.event_end_dt_tm desc
head report
    cnt = 0
head ce.person_id
    if(ce2.event_id = 0)
        hpv_pats->cnt = hpv_pats->cnt + 1
        
        if(mod(hpv_pats->cnt, 10) = 1)
            stat = alterlist(hpv_pats->qual, hpv_pats->cnt + 9)
        endif
        
        hpv_pats->qual[hpv_pats->cnt].per_id    = ce.person_id
        hpv_pats->qual[hpv_pats->cnt].enc_id    = ce.encntr_id
        hpv_pats->qual[hpv_pats->cnt].ord_id    = ce.order_id
        
        call echo(build('EVENT_ID:', ce.event_id, '.  Has no additional testing within the last year.'))
    else
        ;debugging
        call echo(build('EVENT_ID:', ce.event_id, '.  Has additional testing within the last year.  EVENT_ID:', ce2.event_id))
    endif
    
foot report
    stat = alterlist(hpv_pats->qual, hpv_pats->cnt)
with nocounter, expand = 1
call ctd_end_timer(0)


;**************
; case 2 HPV positive AND cytology shows ASCUS-H, LGSIL, HGSIL AND AGUS no follow up appointment or referral to GYN
;**************
/***********************************************************************
DESCRIPTION:  Gather HPV Positive patients with tests results indicating
              ASCUS-H, LGSIL, HGSIL, AGUS.
***********************************************************************/
call ctd_add_timer('Case 2')
select into 'nl:'
  from clinical_event ce
     , orders         o  ;This join is really for case 3
     , clinical_event ce2
     , ce_event_note  cen
     , long_blob      lb
     , person         p  ;This join is really for case 3
     , (dummyt d with seq = gen_pop->cnt)
  
  plan d
   where gen_pop->cnt > 0
     and gen_pop->qual[d.seq]->enc_id   > 0
     and gen_pop->qual[d.seq]->appt_ind = 1
  
  join ce
   where ce.encntr_id             =  gen_pop->qual[d.seq]->enc_id
     and ce.event_cd              =  hpv_res_cd
     and ce.event_tag             = 'Positive'
     and ce.event_class_cd        =  text_cd
     and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
     and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
     and ce.event_end_dt_tm       >  cnvtdatetime(lookback_dt)
     
     and parser(prov_parser)
  
  join p  
   where p.person_id              =  ce.person_id
     and p.active_ind             =  1
   
  join o
   where o.order_id               =  ce.order_id
   
  join ce2 
   ;Now find results for pap that indicate above.
   where ce2.person_id            =  ce.person_id
     and ce2.parent_event_id      =  ce.parent_event_id
     and ce2.event_cd             =  pap_dx_cd
     and ce2.result_status_cd     in (auth_cd, modified_cd, altered_cd)
     and ce2.valid_until_dt_tm    >  cnvtdatetime(curdate,curtime3)
   
  join cen 
   where cen.event_id             =  ce2.event_id
     and cen.valid_until_dt_tm    >  cnvtdatetime(curdate, curtime3)
   
  join lb
   where lb.parent_entity_name    =  "CE_EVENT_NOTE"
     and lb.parent_entity_id      =  cen.ce_event_note_id
     and lb.active_ind            =  1
   
order by ce.person_id, ce.event_end_dt_tm desc

head ce.person_id
    uncomp_blob = notrim(fillstring(32767," "))
    final_blob  = notrim(fillstring(32767," "))

    if(cen.compression_cd = comp_cd)
        call uar_ocf_uncompress(lb.long_blob, size(lb.long_blob), uncomp_blob, size(uncomp_blob), uncomp_size)    ;002
    else
        uncomp_blob = substring(1, findstring("ocf_blob", lb.long_blob) - 1, lb.long_blob)
    endif
    
    ;Don't think we need the RTF strip here... if we do... check out 14_amb_post_proc_phone
    final_blob = uncomp_blob
    
    if(   findstring('(LSIL)'                                               , final_blob) > 0
       or findstring('(LGSIL)'                                              , final_blob) > 0
       or findstring('LOW-GRADE SQUAMOUS INTRAEPITHELIAL LESION'            , final_blob) > 0
       
       or findstring('ASC-US'                                               , final_blob) > 0
       or findstring('ATYPICAL SQUAMOUS CELLS OF UNDETERMINED SIGNIFICANCE.', final_blob) > 0
       or findstring('ATYPICAL SQUAMOUS CELLS,'                             , final_blob) > 0
       or findstring('(ASC-H)'                                              , final_blob) > 0
       
       or findstring('(AGC)'                                                , final_blob) > 0
       or findstring('(AGUS)'                                               , final_blob) > 0
       
       or findstring('(HGSIL)'                                              , final_blob) > 0
       or findstring('(HSIL)'                                               , final_blob) > 0
      )
        ;These are the cases that have results we are interested in.
        
        ;we want to pull appointment data for them?  Temp storing in an RS
        high_risk_cyto->cnt = high_risk_cyto->cnt + 1
        
        if(mod(high_risk_cyto->cnt, 10) = 1)
            stat = alterlist(high_risk_cyto->qual, high_risk_cyto->cnt + 9)
        endif
        
        high_risk_cyto->qual[high_risk_cyto->cnt].per_id    = ce.person_id
        high_risk_cyto->qual[high_risk_cyto->cnt].enc_id    = ce.encntr_id
        high_risk_cyto->qual[high_risk_cyto->cnt].ord_id    = ce.order_id
        
        ;Case 3 stuff
        if(p.birth_dt_tm <= cnvtlookbehind('30,Y'))
            ;This is a case of a positive, older than thirty candidate.
            
            colposcopy->cnt = colposcopy->cnt + 1
        
            if(mod(colposcopy->cnt, 10) = 1)
                stat = alterlist(colposcopy->qual, colposcopy->cnt + 9)
            endif
            
            colposcopy->qual[colposcopy->cnt].per_id     = ce.person_id
            colposcopy->qual[colposcopy->cnt].enc_id     = ce.encntr_id
            colposcopy->qual[colposcopy->cnt].ord_id     = ce.order_id
            colposcopy->qual[colposcopy->cnt].ord_dt     = o.orig_order_dt_tm
            
            colposcopy->qual[colposcopy->cnt].check_type = 'HPV with Cyto, older than 30'
            
            colposcopy->qual[colposcopy->cnt].age        = cnvtage(p.birth_dt_tm)
        endif
        
    endif
    
foot report
    stat = alterlist(high_risk_cyto->qual, high_risk_cyto->cnt)
    
with nocounter, expand = 1
call ctd_end_timer(0)

;**************
; case 3 Needs Colposcopy
;        A bunch of cases falls into this:
;        1) Age over 30, and HPV Positive with cytology showing AGUS, ASCUS, ASCUS-H, LGSIL, or HGSIL
;        2) Age over 30, with HPV 16 or 18 positive without cytology
;        3) Age over 30 with repeat HPV Positives without cytology
;
;        For case 1) we grabbed positive patients over 30 already, and placed in the colposcopy RS.  Need
;        To check them for a colposcopy after the result.
;**************
/***********************************************************************
DESCRIPTION:  Gather Age over 30, with HPV 16 or 18 positive without cytology
       Note:  This is case 2) above.
***********************************************************************/
call ctd_add_timer('Case 3 First')
select into 'nl:'
  from clinical_event ce
     , orders         o
     , order_catalog  oc
     , clinical_event ce2
     , ce_event_note  cen
     , long_blob      lb
     , person         p
     
 where expand(idx, 1, gen_pop->cnt, ce.encntr_id, gen_pop->qual[idx]->enc_id, 1, gen_pop->qual[idx]->appt_ind)  ;002
   and ce.event_cd              =  hpv_res_cd
   and ce.event_tag             =  'Positive'
   and ce.event_class_cd        =  text_cd
   and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
   and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
   
   and parser(prov_parser)
   
   and p.person_id              =  ce.person_id
   and p.active_ind             =  1
   
   and o.order_id               =  ce.order_id
   
   and oc.catalog_cd            =  o.catalog_cd
   and oc.description           =  '*16*18*'     ;This is to just pull the HPVs that are for 16/18 genotypes.
   
   ;Now find results for pap that indicate above.
   and ce2.person_id            =  ce.person_id
   and ce2.parent_event_id      =  ce.parent_event_id
   and ce2.event_cd             =  pap_dx_cd
   and ce2.result_status_cd     in (auth_cd, modified_cd, altered_cd)
   and ce2.valid_until_dt_tm    >  cnvtdatetime(curdate,curtime3)
   
   and cen.event_id             =  ce2.event_id
   and cen.valid_until_dt_tm    >  cnvtdatetime(curdate, curtime3)
   
   and lb.parent_entity_name    =  "CE_EVENT_NOTE"
   and lb.parent_entity_id      =  cen.ce_event_note_id
   and lb.active_ind            =  1
   
   
order by ce.person_id, ce.event_end_dt_tm desc

head ce.person_id
    uncomp_blob = notrim(fillstring(32767," "))
    final_blob  = notrim(fillstring(32767," "))

    if(cen.compression_cd = comp_cd)
        call uar_ocf_uncompress(lb.long_blob, size(lb.long_blob), uncomp_blob, size(uncomp_blob), uncomp_size)
    else
        uncomp_blob = substring(1, findstring("ocf_blob", lb.long_blob) - 1, lb.long_blob)
    endif
    
    ;Don't think we need the RTF strip here... if we do... check out 14_amb_post_proc_phone
    final_blob = uncomp_blob
    
    if(not(
              findstring('(LSIL)'                                               , final_blob) > 0
           or findstring('(LGSIL)'                                              , final_blob) > 0
           or findstring('LOW-GRADE SQUAMOUS INTRAEPITHELIAL LESION'            , final_blob) > 0
           
           or findstring('ASC-US'                                               , final_blob) > 0
           or findstring('ATYPICAL SQUAMOUS CELLS OF UNDETERMINED SIGNIFICANCE.', final_blob) > 0
           or findstring('ATYPICAL SQUAMOUS CELLS,'                             , final_blob) > 0
           or findstring('(ASC-H)'                                              , final_blob) > 0
           
           or findstring('(AGC)'                                                , final_blob) > 0
           or findstring('(AGUS)'                                               , final_blob) > 0
           
           or findstring('(HGSIL)'                                              , final_blob) > 0
           or findstring('(HSIL)'                                               , final_blob) > 0
          )
      )
        ;These are the cases that have results we are interested in.
        
        ;Case 3 stuff
        if(p.birth_dt_tm <= cnvtlookbehind('30,Y'))
            ;This is a case of a positive, older than thirty candidate.
            
            colposcopy->cnt = colposcopy->cnt + 1
        
            if(mod(colposcopy->cnt, 10) = 1)
                stat = alterlist(colposcopy->qual, colposcopy->cnt + 9)
            endif
            
            colposcopy->qual[colposcopy->cnt].per_id     = ce.person_id
            colposcopy->qual[colposcopy->cnt].enc_id     = ce.encntr_id
            colposcopy->qual[colposcopy->cnt].ord_id     = ce.order_id
            colposcopy->qual[colposcopy->cnt].ord_dt     = o.orig_order_dt_tm
            
            colposcopy->qual[colposcopy->cnt].check_type = 'HPV 1618 w/o Cyto, older than 30'
            
            colposcopy->qual[colposcopy->cnt].age        = cnvtage(p.birth_dt_tm)
        endif
        
    endif
    
with nocounter, expand = 1
call ctd_end_timer(0)



/***********************************************************************
DESCRIPTION:  Gather HPV Positive patients with tests results indicating
              NO ASCUS-H, LGSIL, HGSIL.  Twice in a row
       Note:  This is case 3) above.
       
              I tried to do this above, but I think that query performance
              tanked for some reason... probably the fact that I had to 
              take event_tag = positive out.
***********************************************************************/
call ctd_add_timer('Case 3 Second')
select into 'nl:'
  from clinical_event ce
     , orders         o
     , clinical_event ce2
     , ce_event_note  cen
     , long_blob      lb
     , person         p
     , (dummyt d with seq = gen_pop->cnt)
  
  plan d
   where gen_pop->cnt > 0
     and gen_pop->qual[d.seq]->enc_id   > 0
     and gen_pop->qual[d.seq]->appt_ind = 1
  
  join ce
   where ce.encntr_id             =  gen_pop->qual[d.seq]->enc_id
     and ce.event_cd              =  hpv_res_cd
     and ce.event_class_cd        =  text_cd
     and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
     and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)
   
     and parser(prov_parser)
  
  join p  
   where p.person_id              =  ce.person_id
     and p.active_ind             =  1
   
  join o
   where o.order_id               =  ce.order_id
   
  join ce2 
   ;Now find results for pap that indicate above.
   where ce2.person_id            =  ce.person_id
     and ce2.parent_event_id      =  ce.parent_event_id
     and ce2.event_cd             =  pap_dx_cd
     and ce2.result_status_cd     in (auth_cd, modified_cd, altered_cd)
     and ce2.valid_until_dt_tm    >  cnvtdatetime(curdate,curtime3)
   
  join cen 
   where cen.event_id             =  ce2.event_id
     and cen.valid_until_dt_tm    >  cnvtdatetime(curdate, curtime3)
   
  join lb
   where lb.parent_entity_name    =  "CE_EVENT_NOTE"
     and lb.parent_entity_id      =  cen.ce_event_note_id
     
and lb.active_ind            =  1
   
order by ce.person_id, ce.event_end_dt_tm desc

head ce.person_id
    cyto_check = 0
    
    temp_ord_id = ce.order_id
    temp_ord_dt = o.orig_order_dt_tm

detail
    if(cyto_check < 2) ;We only want the most recent two results
        cyto_check = cyto_check + 1
        
        if(ce.event_tag = 'Positive')
            uncomp_blob = notrim(fillstring(32767," "))
            final_blob  = notrim(fillstring(32767," "))

            if(cen.compression_cd = comp_cd)
                call uar_ocf_uncompress(lb.long_blob, size(lb.long_blob), uncomp_blob, size(uncomp_blob), uncomp_size)
            else
                uncomp_blob = substring(1, findstring("ocf_blob", lb.long_blob) - 1, lb.long_blob)
            endif
            
            ;Don't think we need the RTF strip here... if we do... check out 14_amb_post_proc_phone
            final_blob = uncomp_blob
            
            if(   findstring('(LSIL)'                                               , final_blob) > 0
               or findstring('(LGSIL)'                                              , final_blob) > 0
               or findstring('LOW-GRADE SQUAMOUS INTRAEPITHELIAL LESION'            , final_blob) > 0
               
               or findstring('ASC-US'                                               , final_blob) > 0
               or findstring('ATYPICAL SQUAMOUS CELLS OF UNDETERMINED SIGNIFICANCE.', final_blob) > 0
               or findstring('ATYPICAL SQUAMOUS CELLS,'                             , final_blob) > 0
               or findstring('(ASC-H)'                                              , final_blob) > 0
               
               or findstring('(AGC)'                                                , final_blob) > 0
               or findstring('(AGUS)'                                               , final_blob) > 0
               
               or findstring('(HGSIL)'                                              , final_blob) > 0
               or findstring('(HSIL)'                                               , final_blob) > 0
              )
                
                ;We found cyto in the first 2... we don't want these.
                cyto_check = 3
            ;else

                ;Nothing happens we loop to the next result.  It'll increment... and check the next one... either moving to three 
                ;or being happy and staying at 2.
            endif
        else
            ;One of the first two results was negative.  We don't want these.
            cyto_check = 3
        endif
    endif

foot ce.person_id
    ;We should now be in a state where we can check to see if cyto_check = 2.  If so we want this patient checked for colposcopy
        
    ;Case 3 stuff
    if(p.birth_dt_tm <= cnvtlookbehind('30,Y') and cyto_check = 2)
        colposcopy->cnt = colposcopy->cnt + 1
    
        if(mod(colposcopy->cnt, 10) = 1)
            stat = alterlist(colposcopy->qual, colposcopy->cnt + 9)
        endif
        
        colposcopy->qual[colposcopy->cnt].per_id     = ce.person_id
        colposcopy->qual[colposcopy->cnt].enc_id     = ce.encntr_id
        colposcopy->qual[colposcopy->cnt].ord_id     = temp_ord_id
        colposcopy->qual[colposcopy->cnt].ord_dt     = temp_ord_dt
        
        colposcopy->qual[colposcopy->cnt].check_type = 'HPV with no Cyto, twice'
        
        colposcopy->qual[colposcopy->cnt].age        = cnvtage(p.birth_dt_tm)
    endif
with nocounter, expand = 1, orahintcbo('INDEX(CE XIE30CLINICAL_EVENT)')
call ctd_end_timer(0)


;Fix the list size now that we are through the three checks that add.
set stat = alterlist(colposcopy->qual, colposcopy->cnt)

call echo(colposcopy->qual)



/***********************************************************************
DESCRIPTION:  See if we had a colposcopy after the order...
       Note:  Last step... we want to filter out the ones that had the gap
              cleared.
***********************************************************************/
call ctd_add_timer('Case 3 Colo Check')
select into 'nl:'
  from orders        o
     , order_catalog oc
     , (dummyt d with seq = colposcopy->cnt)
  
  plan d
   where colposcopy->cnt                > 0
     and colposcopy->qual[d.seq].per_id > 0
     and colposcopy->qual[d.seq].ord_dt > 0
  
  join o
   where o.person_id         =  colposcopy->qual[d.seq].per_id
     and o.orig_order_dt_tm  >  cnvtdatetime(colposcopy->qual[d.seq].ord_dt)
     and o.discontinue_ind   =  0
     and o.order_status_cd   not in (discon_cd, cancel_cd, voided_cd)
  
  join oc
   where oc.catalog_cd       =  o.catalog_cd
     and oc.active_ind       =  1
     and oc.description      =  '*Colposcopy*'
     and oc.description      != '*Schedule Colposcopy*'
detail
    ; We found one.
    colposcopy->qual[d.seq].col_ind = 1
    
    call echo('FOUND COLPOSCOPY')
    call echo(o.catalog_cd)
    
with nocounter
call ctd_end_timer(0)



;**************
; case 4 Tissue Pathology Outstanding.
;        This is just non-endorsed Tissue Pathology orders
;**************
call ctd_add_timer('Case 4')
select into 'nl:'
  from orders o
       
 where expand(idx, 1, gen_pop->cnt, o.encntr_id, gen_pop->qual[idx]->enc_id, 1, gen_pop->qual[idx]->appt_ind)  ;002
   and o.encntr_id               != 0  ;Not sure if I need to worry about future orders
   and o.catalog_cd              =  tissue_path_cd
   and o.order_status_cd         not in (discon_cd, cancel_cd, voided_cd)
   and o.orig_order_dt_tm        >= cnvtdatetime(lookback_dt)
   
   and parser(prov_ord_parser)
   
   and not exists(select 'X'
                    from clinical_event ce
                       , ce_event_prsnl cep
                   where ce.order_id           =  o.order_id
                     and ce.result_status_cd   in (auth_cd, modified_cd, altered_cd) 
                     and ce.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
                     
                     and cep.event_id          =  ce.event_id
                     and cep.action_type_cd    =  endorse_cd
                     and cep.valid_until_dt_tm >  sysdate
                 )
   
order by o.person_id

head report
    tp_outstand->cnt = 0
    
detail

    tp_outstand->cnt = tp_outstand->cnt + 1
    
    if(mod(tp_outstand->cnt, 10) = 1)
        stat = alterlist(tp_outstand->qual, tp_outstand->cnt + 9)
    endif
    
    tp_outstand->qual[tp_outstand->cnt].per_id    = o.person_id
    tp_outstand->qual[tp_outstand->cnt].enc_id    = o.encntr_id
    tp_outstand->qual[tp_outstand->cnt].ord_id    = o.order_id

    
foot report
    stat = alterlist(tp_outstand->qual, tp_outstand->cnt)
with nocounter, expand = 1
call ctd_end_timer(0)



call ctd_add_timer('Looper')
; Here I want to concat the lists into the final reporting RS.  The RSes above will be compiled into this 
; single source of truth, with a flag that mentions the problems.
for(looper = 1 to hpv_pats->cnt)
    set results->cnt = results->cnt + 1
    
    if(mod(results->cnt, 10) = 1)
        set stat = alterlist(results->qual, results->cnt + 9)
    endif
    
    set results->qual[results->cnt]->per_id = hpv_pats->qual[looper]->per_id
    set results->qual[results->cnt]->enc_id = hpv_pats->qual[looper]->enc_id
    
    ;for brevity
    set reason_pos = results->qual[results->cnt]->reason_cnt + 1
    
    set results->qual[results->cnt]->reason_cnt = reason_pos
    
    set stat = alterlist(results->qual[results->cnt]->reasons, reason_pos)
    
    set results->qual[results->cnt]->reasons[reason_pos]->reason_txt = 'HPV Positive w/o Test in Last Year'
    set results->qual[results->cnt]->reasons[reason_pos]->reason_flag = 1
    
    ;for brevity
    set results->qual[results->cnt]->order_cnt = results->qual[results->cnt]->order_cnt + 1
    
    set order_pos = results->qual[results->cnt]->order_cnt
    
    set stat = alterlist(results->qual[results->cnt]->orders, order_pos)
    
    set results->qual[results->cnt]->orders[order_pos]->ord_id  = hpv_pats->qual[looper]->ord_id
    
    ;stats
    set results->stats->out_care_cnt = results->stats->out_care_cnt + 1
    
endfor


for(looper = 1 to high_risk_cyto->cnt)
    ;Now we have to see if the person is already there.
    
    set result_pos = locateval(idx, 1                                  , results->cnt
                                  , high_risk_cyto->qual[looper].per_id, results->qual[idx]->patient->per_id)
    
    if(result_pos = 0)
        ;call echo('adding new person.')
        set results->cnt = results->cnt + 1
    
        set result_pos = results->cnt
    
        if(mod(results->cnt, 10) = 1)
            set stat = alterlist(results->qual, results->cnt + 9)
        endif
        
        set results->qual[result_pos]->per_id = high_risk_cyto->qual[looper]->per_id
        set results->qual[result_pos]->enc_id = high_risk_cyto->qual[looper]->enc_id
    ;else
    ;    call echo('adding reason to exisiting person')
    endif
    
    
    ;for brevity
    set reason_pos = results->qual[result_pos]->reason_cnt + 1
    
    set results->qual[result_pos]->reason_cnt = reason_pos
    
    set stat = alterlist(results->qual[result_pos]->reasons, reason_pos)
    
    set results->qual[result_pos]->reasons[reason_pos]->reason_txt  = 'HPV Positive w/ ASCUS-H/LGSIL/HGSIL'
    set results->qual[result_pos]->reasons[reason_pos]->reason_flag = 2
    
    
    set order_pos = locateval(idx, 1                                   , results->qual[result_pos]->order_cnt
                                 , high_risk_cyto->qual[looper]->ord_id, results->qual[result_pos]->orders[idx]->ord_id)
    
    ;debugging
    ;if(looper = 3) set order_pos = 0 endif
    
    if(order_pos = 0)
        set results->qual[result_pos]->order_cnt = results->qual[result_pos]->order_cnt + 1
        
        set order_pos = results->qual[result_pos]->order_cnt
    
        set stat = alterlist(results->qual[result_pos]->orders, order_pos)
        
        set results->qual[result_pos]->orders[order_pos]->ord_id = high_risk_cyto->qual[looper]->ord_id
    ;else
    ;    call echo('test')
    ;    call echo(high_risk_cyto->qual[looper]->ord_id)
    ;    call echo(results->qual[result_pos]->orders[1]->ord_id)
    
    endif
    
    ;stats
    set results->stats->high_risk_cnt = results->stats->high_risk_cnt + 1
    
endfor

call echo('test')
call echorecord(colposcopy)
for(looper = 1 to colposcopy->cnt)
    if(colposcopy->qual[looper]->col_ind = 0)
        ;Now we have to see if the person is already there.
        
        set result_pos = locateval(idx, 1                              , results->cnt
                                      , colposcopy->qual[looper].per_id, results->qual[idx]->patient->per_id)
        
        if(result_pos = 0)
            ;call echo('adding new person.')
            set results->cnt = results->cnt + 1
        
            set result_pos = results->cnt
        
            if(mod(results->cnt, 10) = 1)
                set stat = alterlist(results->qual, results->cnt + 9)
            endif
            
            set results->qual[result_pos]->per_id = colposcopy->qual[looper]->per_id
            set results->qual[result_pos]->enc_id = colposcopy->qual[looper]->enc_id
        ;else
        ;    call echo('adding reason to exisiting person')
        endif
        
        ;These guys like to have multiple and it is messing with me.  I need to combine them for now in the backend.
        set reason_pos = locateval(idx, 1, results->qual[result_pos]->reason_cnt
                                      , 4, results->qual[result_pos]->reasons[idx]->reason_flag)
                                      
        ;call echorecord(results->qual[result_pos]->reasons)
        ;call echo(reason_pos)
                                      
        if(reason_pos > 0)
            set results->qual[result_pos]->reasons[reason_pos]->reason_txt = 
                concat( results->qual[result_pos]->reasons[reason_pos]->reason_txt, '; '
                      , colposcopy->qual[looper]->check_type
                      )
        else
            ;for brevity
            set reason_pos = results->qual[result_pos]->reason_cnt + 1
            
            set results->qual[result_pos]->reason_cnt = reason_pos
            
            set stat = alterlist(results->qual[result_pos]->reasons, reason_pos)
            
            set results->qual[result_pos]->reasons[reason_pos]->reason_txt  =  colposcopy->qual[looper]->check_type

            set results->qual[result_pos]->reasons[reason_pos]->reason_flag = 4
            
            ;stats
            set results->stats->need_colpo_cnt = results->stats->need_colpo_cnt + 1
    
        endif
        
        set order_pos = locateval(idx, 1                               , results->qual[result_pos]->order_cnt
                                         , colposcopy->qual[looper]->ord_id, results->qual[result_pos]->orders[idx]->ord_id)
        
        ;call echo(results->qual[result_pos]->reasons[reason_pos]->reason_txt)
            
        if(order_pos = 0)
            set results->qual[result_pos]->order_cnt = results->qual[result_pos]->order_cnt + 1
            
            set order_pos = results->qual[result_pos]->order_cnt
        
            set stat = alterlist(results->qual[result_pos]->orders, order_pos)
            
            set results->qual[result_pos]->orders[order_pos]->ord_id = colposcopy->qual[looper]->ord_id
        ;else
        ;    call echo('test')
        ;    call echo(colposcopy->qual[looper]->ord_id)
        ;    call echo(results->qual[result_pos]->orders[1]->ord_id)
        ;    call echo(results->qual[result_pos]->reasons[reason_pos]->reason_txt)
        
        endif
        
    endif
endfor


for(looper = 1 to tp_outstand->cnt)
    ;Now we have to see if the person is already there.
    
    set result_pos = locateval(idx, 1                               , results->cnt
                                  , tp_outstand->qual[looper].per_id, results->qual[idx]->patient->per_id)
    
    if(result_pos = 0)
        ;call echo('adding new person.')
        set results->cnt = results->cnt + 1
    
        set result_pos = results->cnt
    
        if(mod(results->cnt, 10) = 1)
            set stat = alterlist(results->qual, results->cnt + 9)
        endif
        
        set results->qual[result_pos]->per_id = tp_outstand->qual[looper]->per_id
        set results->qual[result_pos]->enc_id = tp_outstand->qual[looper]->enc_id
    ;else
    ;    call echo('adding reason to exisiting person')
    endif
    
    
    ;for brevity
    set reason_pos = results->qual[result_pos]->reason_cnt + 1
    
    set results->qual[result_pos]->reason_cnt = reason_pos
    
    set stat = alterlist(results->qual[result_pos]->reasons, reason_pos)
    
    set results->qual[result_pos]->reasons[reason_pos]->reason_txt  = 'Tissue Pathology Outstanding'
    set results->qual[result_pos]->reasons[reason_pos]->reason_flag = 8
    
    
    set order_pos = locateval(idx, 1                                , results->qual[result_pos]->order_cnt
                                 , tp_outstand->qual[looper]->ord_id, results->qual[result_pos]->orders[idx]->ord_id)
    
    ;debugging
    ;if(looper = 3) set order_pos = 0 endif
    
    if(order_pos = 0)
        set results->qual[result_pos]->order_cnt = results->qual[result_pos]->order_cnt + 1
        
        set order_pos = results->qual[result_pos]->order_cnt
    
        set stat = alterlist(results->qual[result_pos]->orders, order_pos)
        
        set results->qual[result_pos]->orders[order_pos]->ord_id = tp_outstand->qual[looper]->ord_id
    ;else
    ;    call echo('test')
    ;    call echo(high_risk_cyto->qual[looper]->ord_id)
    ;    call echo(results->qual[result_pos]->orders[1]->ord_id)
    
    endif
    
    ;stats
    set results->stats->tissue_path_cnt = results->stats->tissue_path_cnt + 1
    
endfor


set stat = alterlist(results->qual, results->cnt)

call ctd_end_timer(0)

/***********************************************************************
DESCRIPTION:  Gather patient information
***********************************************************************/
call ctd_add_timer('Gather patient information')
select into 'nl:'
  from person             p
     , encounter          e
     , phone              ph
     , person_prsnl_reltn pcp
     , prsnl              pcpp
     , (dummyt d with seq = results->cnt)
  
  plan d
   where results->cnt > 0
     and results->qual[d.seq]->per_id != 0
     and results->qual[d.seq]->enc_id != 0
     
  join p
   where results->qual[d.seq]->per_id  =  p.person_id
     and p.active_ind                  =  1
  
  join e
   where results->qual[d.seq]->enc_id  =  e.encntr_id
     and e.active_ind                  =  1
  
  join ph
   where ph.parent_entity_id           =  outerjoin(p.person_id                    )
     and ph.parent_entity_name         =  outerjoin('PERSON'                       )
     and ph.active_ind                 =  outerjoin(1                              )
     and ph.beg_effective_dt_tm        <= outerjoin(cnvtdatetime(curdate,curtime3) )
     and ph.end_effective_dt_tm        >  outerjoin(cnvtdatetime(curdate,curtime3) )
     and trim(ph.phone_num_key,3)      >  outerjoin(""                             )
     and ph.phone_type_seq             =  outerjoin(1                              )
  
  join pcp
   where pcp.person_id                 =  outerjoin(p.person_id                    )
     and pcp.active_ind                =  outerjoin(1                              )
     and pcp.beg_effective_dt_tm       <= outerjoin(cnvtdatetime(curdate, curtime3))
     and pcp.end_effective_dt_tm       >= outerjoin(cnvtdatetime(curdate, curtime3))
     and pcp.person_prsnl_r_cd         =  outerjoin(pcp_cd                         )
  
  join pcpp
   where pcpp.person_id                =  outerjoin(pcp.prsnl_person_id            )
     
     
order by p.person_id
head p.person_id
    
    results->qual[d.seq]->name     = trim(p.name_full_formatted, 3)
    results->qual[d.seq]->dob      = format(p.birth_dt_tm, "MM-DD-YYYY")
    results->qual[d.seq]->phone    = concat(substring(1, 3, ph.phone_num_key), '-',
                                                   substring(4, 3, ph.phone_num_key), '-',
                                                   substring(7, 4, ph.phone_num_key)
                                                  )
    
    results->qual[d.seq]->pcp      = trim(pcpp.name_full_formatted, 3)
    
    
    results->qual[d.seq]->location = trim(uar_get_code_display(e.loc_nurse_unit_cd), 3)
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Gather OBGYN Person level
***********************************************************************/
call ctd_add_timer('Gather OBGYN Person level')
select into 'nl:'
  from person_prsnl_reltn ppr
     , prsnl              p
     , (dummyt d with seq = results->cnt)
   plan d
    where results->cnt                 >  0
      and results->qual[d.seq]->enc_id != 0
   
   join ppr
    where ppr.person_id                =  results->qual[d.seq]->per_id
      and ppr.active_ind               =  1 
      and ppr.end_effective_dt_tm      >= cnvtdatetime(curdate, curtime3)
   
   join p
    where p.person_id                  =  ppr.prsnl_person_id
    ;TODO These might need codeified?
      and p.position_cd                in ( 915338723.00  ; Physician - Women's Health
                                          , 2229780007.00 ; Physician - Women's Health - New
                                          )
detail
    pos = locateval(idx, 1, results->qual[d.seq]->obgyn_cnt, p.person_id
                                                           , results->qual[d.seq]->obgyn[idx]->person_id
                   )
    
    if(pos = 0)
        results->qual[d.seq]->obgyn_cnt = results->qual[d.seq]->obgyn_cnt + 1
        
        pos = results->qual[d.seq]->obgyn_cnt
        
        stat = alterlist(results->qual[d.seq]->obgyn, pos)
        
        results->qual[d.seq]->obgyn[pos]->person_id          = p.person_id
        results->qual[d.seq]->obgyn[pos]->name               = trim(p.name_full_formatted, 3)
        results->qual[d.seq]->obgyn[pos]->encntr_person_flag = 'PERSON'
        results->qual[d.seq]->obgyn[pos]->reltn_type_flag    = uar_get_code_display(ppr.person_prsnl_r_cd)
        results->qual[d.seq]->obgyn[pos]->position           = uar_get_code_display(p.position_cd)
    endif
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Gather OBGYN Encounter level
***********************************************************************/
call ctd_add_timer('Gather OBGYN Encounter level')
select into 'nl:'
  from encntr_prsnl_reltn epr
     , prsnl              p
     , (dummyt d with seq = results->cnt)
   plan d
    where results->cnt                 >  0
      and results->qual[d.seq]->enc_id != 0
   
   join epr
    where epr.encntr_id                =  results->qual[d.seq]->enc_id
      and epr.active_ind               =  1 
      and epr.end_effective_dt_tm      >= cnvtdatetime(curdate, curtime3)
   
   join p
    where p.person_id                  =  epr.prsnl_person_id
    ;TODO These might need codified?
      and p.position_cd                in ( 915338723.00  ; Physician - Women's Health
                                          , 2229780007.00 ; Physician - Women's Health - New
                                          )
detail
    pos = locateval(idx, 1, results->qual[d.seq]->obgyn_cnt, p.person_id
                                                           , results->qual[d.seq]->obgyn[idx]->person_id
                   )
    
    if(pos = 0)
        results->qual[d.seq]->obgyn_cnt = results->qual[d.seq]->obgyn_cnt + 1
        
        pos = results->qual[d.seq]->obgyn_cnt
        
        stat = alterlist(results->qual[d.seq]->obgyn, pos)
        
        results->qual[d.seq]->obgyn[pos]->person_id          = p.person_id
        results->qual[d.seq]->obgyn[pos]->name               = trim(p.name_full_formatted, 3)
        results->qual[d.seq]->obgyn[pos]->encntr_person_flag = 'ENCNTR'
        results->qual[d.seq]->obgyn[pos]->reltn_type_flag    = uar_get_code_display(epr.encntr_prsnl_r_cd)
        results->qual[d.seq]->obgyn[pos]->position           = uar_get_code_display(p.position_cd)
    endif
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Gather Ordering Providers
***********************************************************************/
;002->
call ctd_add_timer('Gather Ordering Providers Loop')
for(looper = 1 to results->cnt)
    select into 'nl:'
      from order_action oa
         , prsnl        p
         , (dummyt d with seq = results->qual[looper]->order_cnt)
       plan d
        where results->cnt                                 >  0
          and results->qual[looper]->order_cnt             >  0
          and results->qual[looper]->orders[d.seq]->ord_id != 0
       
       join oa
        where oa.order_id      =  results->qual[looper]->orders[d.seq]->ord_id
          and oa.action_type_cd =  2534.0
       
       join p
        where p.person_id       =  oa.order_provider_id
        
    detail
        results->qual[looper]->orders[d.seq]->ord_prov_id   = oa.order_provider_id
        results->qual[looper]->orders[d.seq]->ord_prov_name = trim(p.name_full_formatted, 3)
        
    with nocounter
endfor
call ctd_end_timer(0)
;002<-


/***********************************************************************
DESCRIPTION:  Gather Prev Appointment information
***********************************************************************/
call ctd_add_timer('Gather Prev Appointment information')
select into 'nl:'
  from sch_appt  sa
     , sch_event se
     , person    p
     , sch_appt  ap
     , prsnl     per
    , (dummyt d with seq = results->cnt)
  plan d
   where results->cnt                 >  0
     and results->qual[d.seq]->per_id != 0
     
  join sa
   where sa.person_id                  =  results->qual[d.seq]->per_id
     and sa.sch_role_cd                =  4572.000000                                                  ;TODO codify?
     and sa.sch_state_cd               in (4536.00, 4537.00, 4054213.00) ;checkin checkout complete    ;TODO codify?
     and sa.beg_dt_tm                  <= cnvtdatetime(curdate, curtime3)
     and sa.schedule_seq               =  (select max(sa2.schedule_seq)
                                             from sch_appt sa2
                                            where sa2.sch_event_id = sa.sch_event_id
                                          )

  join se
   where se.sch_event_id              =  sa.sch_event_id
  
  join p
   where p.person_id                  =  sa.person_id
  
  join ap
   where ap.sch_event_id              =  sa.sch_event_id
     and ap.sch_role_cd               =  4574.000000  ;TODO codify?
   
  join per
   where per.person_id                =  ap.person_id
     ;TODO These might need codified?
     and per.position_cd              in ( 915338723.00  ; Physician - Women's Health
                                         , 2229780007.00 ; Physician - Women's Health - New
                                         , 1842502051.00 ; Physician - Family Medicine/Med Peds
                                         )
order by sa.person_id, sa.beg_dt_tm desc
head sa.person_id

    results->qual[d.seq]->last_appt->appt_id      = sa.sch_appt_id
    results->qual[d.seq]->last_appt->event_id     = sa.sch_event_id

    results->qual[d.seq]->last_appt->location     = trim(uar_get_code_display(sa.appt_location_cd), 3)
    results->qual[d.seq]->last_appt->datetime     = format(sa.beg_dt_tm, "MM-DD-YYYY HH:MM:SS")
    results->qual[d.seq]->last_appt->sortdatetime = format(sa.beg_dt_tm, "YYYY-MM-DD HH:MM:SS")
    results->qual[d.seq]->last_appt->prov_name    = trim(per.name_full_formatted, 3)
    
    results->qual[d.seq]->last_appt->appt_type    = uar_get_code_display(se.appt_type_cd)
    results->qual[d.seq]->last_appt->appt_type_cd = se.appt_type_cd
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Gather Next Appointment information
       NOTE:  "Sort" doing some weird stuff here... what I intend:
              If they have a women's health encounter... it counts above
              all else... even if there are closer upcoming appointments 
              elsewhere.  If there are no WH appts, then we pick the 
              first upcoming "any" appt.
***********************************************************************/
call ctd_add_timer('Gather Next Appointment information')
select into 'nl:'
                                    ;TODO These might need codified?
       sort = if(per.position_cd in (915338723, 2229780007, 1842502051)) 0
              else                                                       1
              endif
  from sch_appt  sa
     , sch_event se
     , person    p
     , sch_appt  ap
     , prsnl     per
     , (dummyt d with seq = results->cnt)
  plan d
   where results->cnt                 >  0
     and results->qual[d.seq]->per_id != 0
     
  join sa
   where sa.person_id                  =  results->qual[d.seq]->per_id
     and sa.sch_role_cd                =  4572.000000                                 ;TODO codify?
     and sa.sch_state_cd               not in (4535.00, 4540.00) ;canceled deleted    ;TODO codify?
     and sa.beg_dt_tm                  >= cnvtdatetime(curdate, curtime3)
     and sa.schedule_seq               =  (select max(sa2.schedule_seq)
                                             from sch_appt sa2
                                            where sa2.sch_event_id = sa.sch_event_id
                                          )

  join se
   where se.sch_event_id              =  sa.sch_event_id
  
  join p
   where p.person_id                  =  sa.person_id
  
  join ap
   where ap.sch_event_id              =  sa.sch_event_id
     and ap.sch_role_cd               =  4574.000000  ;TODO codify?
   
  join per
   where per.person_id                =  ap.person_id
     ;We don't want to do this anymore... we are going to trust "sort" to grab the WH appts first.  Otherwise, we just want whatever
     ;and per.position_cd              in ( 915338723.00  ; Physician - Women's Health
     ;                                    , 2229780007.00 ; Physician - Women's Health - New
     ;                                    , 1842502051.00 ; Physician - Family Medicine/Med Peds
     ;                                    )
order by sa.person_id, sort, sa.beg_dt_tm
head sa.person_id

    results->qual[d.seq]->next_appt->appt_id      = sa.sch_appt_id
    results->qual[d.seq]->next_appt->event_id     = sa.sch_event_id
    
    results->qual[d.seq]->next_appt->location     = trim(uar_get_code_display(sa.appt_location_cd), 3)
    results->qual[d.seq]->next_appt->datetime     = format(sa.beg_dt_tm, "MM-DD-YYYY HH:MM:SS")
    results->qual[d.seq]->next_appt->sortdatetime = format(sa.beg_dt_tm, "YYYY-MM-DD HH:MM:SS")
    results->qual[d.seq]->next_appt->prov_name    = trim(per.name_full_formatted, 3)
    
    results->qual[d.seq]->next_appt->appt_type    = uar_get_code_display(se.appt_type_cd)
    results->qual[d.seq]->next_appt->appt_type_cd = se.appt_type_cd
with nocounter
call ctd_end_timer(0)


/***********************************************************************
DESCRIPTION:  Gather Previous Comments and Due Dates
      NOTES:  If you do something to this RS... you'll have to touch 
              cust_mp_hr_obgyn_comment too.
***********************************************************************/
call ctd_add_timer('Gather Previous Comments and Due Dates')
select into 'nl:'
  from clinical_event   ce
     , ce_event_prsnl   cep
     , prsnl            p 
     , ce_date_result   cdr
     , ce_string_result csr
     , (dummyt d with seq = results->cnt)
  plan d
   where results->cnt                 >  0
     and results->qual[d.seq]->per_id != 0
     
  join ce
   where ce.person_id             =  results->qual[d.seq]->per_id
     and ce.event_cd              in (comment_cd, due_dt_cd)
     and ce.result_status_cd      in (auth_cd, modified_cd, altered_cd)
     and ce.valid_until_dt_tm     >  cnvtdatetime(curdate,curtime3)

  join cep  ;  Multiple here... might not matter.  Each CE has at least a row here.
   where cep.event_id          =  ce.event_id
     and cep.action_type_cd    =  perform_cd
     and cep.valid_until_dt_tm >  sysdate
     
  join p
   where p.person_id           = cep.action_prsnl_id

  join cdr
    where cdr.event_id            =  outerjoin(ce.event_id)
      and cdr.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))
  
  join csr
    where csr.event_id            =  outerjoin(ce.event_id)
      and csr.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))
  
order by ce.event_end_dt_tm desc, ce.event_cd
head ce.event_end_dt_tm
    results->qual[d.seq]->comment_cnt = results->qual[d.seq]->comment_cnt + 1
    
    pos = results->qual[d.seq]->comment_cnt
    
    stat = alterlist(results->qual[d.seq]->comments, pos)
    
    results->qual[d.seq]->comments[pos]->event_end_dt     = ce.event_end_dt_tm
    results->qual[d.seq]->comments[pos]->event_end_dt_txt = format(ce.event_end_dt_tm, "MM-DD-YYYY HH:MM:SS")
    results->qual[d.seq]->comments[pos]->prsnl_name       = trim(p.name_full_formatted, 3)
    
detail

    if(csr.string_result_text != null)
        results->qual[d.seq]->comments[pos]->com_event_id    = ce.event_id
        
        results->qual[d.seq]->comments[pos]->comment         = csr.string_result_text
    endif
    
    if(cdr.result_dt_tm != null)
        results->qual[d.seq]->comments[pos]->date_event_id   = ce.event_id
        
        results->qual[d.seq]->comments[pos]->followup_dt          = cdr.result_dt_tm
        results->qual[d.seq]->comments[pos]->followup_dt_txt      = format(cdr.result_dt_tm, 'MM-DD-YYYY')
        results->qual[d.seq]->comments[pos]->followup_sort_dt_txt = format(cdr.result_dt_tm, 'YYYY-MM-DD')
    endif


with nocounter
call ctd_end_timer(0)


;  For the moment I am going to be a bum and do this in a loop rather than
;  fighting multiple dummyts.
call ctd_add_timer('Gather Additional order information')
for(looper = 1 to results->cnt)
    
    if(results->qual[looper]->order_cnt > 0)
        /***********************************************************************
        DESCRIPTION:  Gather Additional order information
        ***********************************************************************/
        select into 'nl:'
               title = trim(uar_get_code_display(ce.event_cd), 3)
          from orders         o
             , clinical_event ce
             , (dummyt d with seq = results->qual[looper]->order_cnt)
          
          plan d
           where results->cnt                                 >  0
             and results->qual[looper]->orders[d.seq]->ord_id > 0
           
          join o
           where o.order_id           =  results->qual[looper]->orders[d.seq]->ord_id
          
          join ce
           where ce.order_id          =  outerjoin(o.order_id)
             and ce.valid_until_dt_tm >  outerjoin(cnvtdatetime(curdate, curtime3))
             and ce.event_class_cd    in (236, 233, 228, 232, 223, 225)  ;"TXT", "NUM", "IMMUN", "MED", "DATE", and "DONE"  
                                                                         ;TODO Codify?
          
        order by o.order_id, title, ce.event_id
        head o.order_id
            ;Doing this the dumb way... one order is too big for popper and I solve by inserting a space.
            if(trim(o.hna_order_mnemonic, 3) = 'AptmPapIGTPHPVrfxHPV16,18/45CT/NG/TV (LabCorp Only)')
                results->qual[looper]->orders[d.seq]->order_name = 'AptmPapIGTPHPVrfxHPV16, 18/45CT/NG/TV (LabCorp Only)'
            else
                results->qual[looper]->orders[d.seq]->order_name = trim(o.hna_order_mnemonic, 3)
            endif

            results->qual[looper]->orders[d.seq]->ord_enc_id = o.encntr_id
        
        head ce.event_id
            results->qual[looper]->orders[d.seq]->result_cnt = results->qual[looper]->orders[d.seq]->result_cnt + 1
            
            result_pos = results->qual[looper]->orders[d.seq]->result_cnt
            
            stat = alterlist(results->qual[looper]->orders[d.seq]->ord_res, result_pos)
            
            results->qual[looper]->orders[d.seq]->ord_res[result_pos]->event_id    = ce.event_id
            
            temp_res_title = trim(uar_get_code_display(ce.event_cd), 3)
            
            if(substring(size(temp_res_title, 3), 1, temp_res_title) = ':') 
                temp_res_title = substring(1, size(temp_res_title, 3) - 1, temp_res_title)
            endif
            
            results->qual[looper]->orders[d.seq]->ord_res[result_pos]->event_title = temp_res_title
        with nocounter
        
        
        /***********************************************************************
        DESCRIPTION:  Find Endorsement tied to the result if already found
        ***********************************************************************/
        select into 'nl:'
          from ce_event_prsnl cep
             , clinical_event ce
             , prsnl p
             , (dummyt d with seq = results->qual[looper]->order_cnt)
          plan d
           where results->cnt                                 >  0
             and results->qual[looper]->enc_id                != 0
             and results->qual[looper]->orders[d.seq]->ord_id >  0
          join ce
           where ce.encntr_id          =  results->qual[looper]->enc_id
             and ce.order_id           =  results->qual[looper]->orders[d.seq]->ord_id
             and ce.result_status_cd   in (auth_cd, modified_cd, altered_cd)
             and ce.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
          join cep
           where cep.event_id          =  ce.event_id
             and cep.action_type_cd    =  endorse_cd
             and cep.valid_until_dt_tm >  sysdate
          join p
           where p.person_id = cep.action_prsnl_id
        order by cep.action_dt_tm 
        detail
            
            results->qual[looper]->orders[d.seq]->endorse_by         = trim(p.name_full_formatted, 3)
            results->qual[looper]->orders[d.seq]->endorse_dt_tm      = format(cep.action_dt_tm, "MM-DD-YYYY HH:MM:SS")
            results->qual[looper]->orders[d.seq]->sort_endorse_dt_tm = format(cep.action_dt_tm, "YYYY-MM-DD HH:MM:SS")
            
        with nocounter
        
        
        
    endif
endfor
call ctd_end_timer(0)


#exit_script

if(size(results->cnt, 5) > 0)
    set results->status_data->status = "S"
else
    set results->status_data->status = "Z"
endif


;for(looper = 1 to results->cnt)
;    if(results->qual[looper]->reason_cnt > 1)
;        call echorecord(results->qual[looper])
;    endif
;endfor


;call echorecord(hpv_pats)
;call echorecord(high_risk_cyto)
;call echorecord(colposcopy)
;call echorecord(tp_outstand)
;call echorecord(gen_pop)
call echorecord(results)

call ctd_end_timer(prog_timer)
call ctd_print_timers(null)

call putRSToFile($outdev, results)






end
go