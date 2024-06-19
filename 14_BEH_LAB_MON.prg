/*****************************************************************************************************************
 
Script Name:    14_beh_lab_mon.prg
Description:    Behavioral Health Lab Monitoring Report
 
Date Written:   August 06, 2018
Written by:     Michael Mayes
 
******************************************************************************************************************
                                            Special Instructions
******************************************************************************************************************
 
******************************************************************************************************************
                                            Revision Information
******************************************************************************************************************
Rev Date     By             MCGA   Comments
--- -------- -------------- ------ ----------------------------------------------------------------------------------
001 08/06/18 Michael Mayes         Initial Release (original report 14_bh_lab_mon)
002 08/10/19 Joe Troy       216794 Rewritten and renamed to 14_beh_lab_mon. Accomodating more specific user needs.
003 04/20/21 Michael Mayes  224005 Adding protocol tables to view.  And supporting work.
004 08/03/21 Michael Mayes  226508 Various additions (tot patients... percentages... missing labs)
005 02/03/22 Nichael Mayes  226508 Late validation changes that got pushed into a separate low priorty task for
                                   adding inpatient locations and counts to the providers.
006 03/14/24 Nichael Mayes  345126 Changes: CMRN instead of MRN.  Make Prompt require one Provider.  Counts are once per pat, not 
                                            lab.  But for antipsych, once per RX, not lab.  So multiple labs, once per RX.
******************************************************************************************************************/
;TODO this isn't DBA, this will need work when publishing.
  drop program 14_beh_lab_mon:dba go
create program 14_beh_lab_mon:dba
 
prompt 
    ;* Enter or select the printer
	"O"                                                                                      = "MINE"
	, "Select Active Medication(s): (No selection                                            = * ALL)" = 0
	, "WARNING: If no Location AND no Provider selected, then can only show a 60 day window" = ""
	, "Medications Prescribed between"                                                       = CURDATE
	, "and"                                                                                  = CURDATE
	, "Location Name Contains: (Type at least 3 letters, then hit TAB key)"                  = ""
	, "Select Location(s): (No selection = *ALL Locations)"                                  = 0
	, "Last Name of Prescribing MD: (Type first few letters, then hit TAB key)"              = ""
	, "Select Provider(s):"                                                                  = 0
	;<<hidden>>"prompt2"                                                                     = ""
	, "Email Spreadsheet?"                                                                   = 0
	, "Email Address:"                                                                       = ""
	, "Lab Lookbacks based on:"                                                              = "RX" 

with OUTDEV, eMed, prompt1, dtBeg, dtEnd, sLoc, dUnit, sPrv, dPrvId, bEmail, sEmail, 
	lookback_flag
 
 
execute 0_rpt_common_subs ; <- access to report common routines RPTCOM
 
 
record qual(
    1 pats[*]
        2 bQual        = i1
        2 dPId         = f8
        2 dEId         = f8
        2 sName        = vc
        2 sMRN         = vc
        2 sDOB         = vc
        2 meds[*]
            3 dCatCd   = f8
            3 bQual    = i1
            3 eMed     = i2
            3 dPSId    = f8
            3 sPhys    = vc
            3 ord_id   = f8
            3 rx_dt    = dq8
            3 missing[*]
                4 sLab = vc
    ;004->
    1 tot_cnt          = i4
    1 tot_lith         = i4
    1 tot_val          = i4
    1 tot_psy          = i4
    1 miss_cnt         = i4
    1 miss_lith        = i4
    1 miss_val         = i4
    1 miss_psy         = i4
    1 per_tot_miss     = vc
    1 per_miss_lith    = vc
    1 per_miss_val     = vc
    1 per_miss_psy     = vc
    ;004<-
)
 
; qualify meds to identify patient population (qual->pats), then qualify labs and populate all qualified groups under pats record
; then perform a don't exist on the ref->labs record to identify which required labs are missing (lab groups covers
 
;004->
;I could try and do this layout side... but stuff is easiser to see in prg land... so here we are.
record phys_cnts(
    1 cnt               = i4
    1 qual[*]
        2 phys_id       = f8
        2 phys_name     = vc
        2 tot_cnt       = i4
        2 lith_cnt      = i4
        2 val_cnt       = i4
        2 psy_cnt       = i4
        2 tot_miss_cnt  = i4
        2 lith_miss_cnt = i4
        2 val_miss_cnt  = i4
        2 psy_miss_cnt  = i4
        2 tot_per_miss  = vc
        2 lith_per_miss = vc
        2 val_per_miss  = vc
        2 psy_per_miss  = vc
)
;004<-
 
record ref(
    1 meds[*]
        2 dCd       = f8
        2 eMed      = i2
    1 labs[*]
        2 bOrd      = i1
        2 dCd       = f8
        2 sLookBack = vc
        2 eMed      = i2
        2 nGroup    = i2
    1 med_lab_group[*]
        2 eMed      = i2
        2 nGroup    = i2
        2 sLbl      = vc
)
 
; subs
declare AddRefLab(sKey=vc, eMed=i2, nGroup=i4, sLookBack=vc, bOrd=i1(val,0)) = null
 
 
; variables
declare sTitleMeds  = vc
declare sTitleRange = vc
declare sTitleLoc   = vc
declare sTitlePrv   = vc
declare sTitleLookB = vc
 
;003->
declare lith_ind    = i2
declare valp_ind    = i2
declare psy_ind     = i2
;003<-
 
;004->
declare pat_looper  = i4
declare med_looper  = i4
declare phys_looper = i4
 
declare temp_per    = f8
 
declare pos         = i4
declare idx         = i4
;004<-
 
set nRefMed         = 0
set nRefLab         = 0
set nMedLabGrp      = 0
set nNdx            = 0
set nCnt            = 0
 
; med enumerations
set eAll            = 0
set eLith           = 1
set eValp           = 2
set ePsy            = 3
 
set dtBeg     = cnvtdatetime(cnvtdate($dtBeg), 0)
set dtEnd     = cnvtdatetime(cnvtdate($dtEnd), 235959)
set bAllPrv   = evaluate($dPrvId, 0, 1, 0)
set bAllUnits = evaluate($dUnit , 0, 1, 0)


declare allMissFound  = i2 with protect, noconstant  ;006
declare lithMissFound = i2 with protect, noconstant  ;006
declare valMissFound  = i2 with protect, noconstant  ;006
declare psyMissFound  = i2 with protect, noconstant  ;006


declare allFound  = i2 with protect, noconstant  ;006
declare lithFound = i2 with protect, noconstant  ;006
declare valFound  = i2 with protect, noconstant  ;006
declare psyFound  = i2 with protect, noconstant  ;006
 
 
; check date range validity. Prevents system resource hogging
if(bAllPrv and bAllUnits and datetimediff(cnvtdatetime(dtEnd), cnvtdatetime(dtBeg)) > 60)
      set _memory_reply_string = concat( "ERROR: Must specify at least one Provider or Location"
                                       , " if specified date range is greater than 60 days"
                                       )
      go to EXIT_SCRIPT
endif
 
 
; format email and check validity
; this is to allow user to enter email without Medstar suffix and also for
; ops param string to be shorter when auto job goes to multiple emails
declare sParamEmail = vc
 
if($bEmail)
    ; allow medstar only emails
    if(not RPTCOM_ValidateMedstarEmail($sEmail, sParamEmail, ','))
        set _memory_reply_string = build2( "ERROR: Invalid email entered. Must be a valid Medstar "
                                         , "email address (XXX@medstar.net)"
                                         , " -> ", sParamEmail)
 
        go to EXIT_SCRIPT
    endif
endif
 
 
if($eMed = eAll or eLith in($eMed))
    call AddRefMed("LITHIUM", eLith)
 
    ; labs
    call AddRefLab("BUN"                           , eLith, 0, "6,M")
    call AddRefLab("CREATININE"                    , eLith, 0, "6,M")
    call AddRefLab("GFRAFRICANAMERICAN"            , eLith, 0, "6,M")
    call AddRefLab("GFRNONAFRICANAMERICAN"         , eLith, 0, "6,M")
    call AddRefLab("EGFRTRANSCRIBED"               , eLith, 0, "6,M")
    call AddRefLab("EGFRAFRICANAMERICANTRANSCRIBED", eLith, 0, "6,M")
    call AddMedLabGroup(eLith, 0, "Serum Creatinine, e-GFR, or Creatinine Clearance")
 
    ;004 This is changing on us 6M to 12M
    call AddRefLab("TSH"   , eLith, 1, "12,M")  ;"6,M")
    call AddRefLab("T4FREE", eLith, 1, "12,M")  ;"6,M")
    call AddMedLabGroup(eLith, 1, "TSH")
 
    ;004 This is changing on us 6M to 12M
    call AddRefLab("LITHIUMLVL", eLith, 2, "12,M")  ;"6,M")
    call AddMedLabGroup(eLith, 2, "Lithium Level")
 
    set sTitleMeds = ", Lithium"
    set lith_ind   = 1 ;003
endif
 
 
if($eMed = eAll or eValp in($eMed))
    call AddRefMed("DIVALPROEXSODIUM", eValp)
    call AddRefMed("VALPROICACID"    , eValp)
 
    ;004 This is changing on us 12M to 6M
    call AddRefLab("COMPLETEBLOODCOUNTWDIFFERENTIAL"    , eValp, 0, "6,M", 1)  ;"12,M", 1)
    call AddRefLab("COMPLETEBLOODCOUNTWNODIFFERENTIAL"  , eValp, 0, "6,M", 1)  ;"12,M", 1)
    call AddRefLab("NEONATECBC"                         , eValp, 0, "6,M", 1)  ;"12,M", 1)
    call AddRefLab("NIACBCCOMPONENT"                    , eValp, 0, "6,M", 1)  ;"12,M", 1)
    call AddRefLab("NIACBCSLIDE"                        , eValp, 0, "6,M", 1)  ;"12,M", 1)
    call AddRefLab("PAREXELCOMPLETEBLOODCOUNTWDIFFERENT", eValp, 0, "6,M", 1)  ;"12,M", 1)
    call AddMedLabGroup(eValp, 0, "CBC")
 
    ;004 This is changing on us 12M to 6M
    call AddRefLab("VALPROACIDLVL"       , eValp, 1, "6,M")  ;"12,M")
    call AddRefLab("FREEVALPROICACID"    , eValp, 1, "6,M")  ;"12,M")
    call AddRefLab("VALPROICACIDLVLTOTAL", eValp, 1, "6,M")  ;"12,M")
    call AddRefLab("VALPROICACIDPCTFREE" , eValp, 1, "6,M")  ;"12,M")
    call AddMedLabGroup(eValp, 1, "Valproic Acid Level")
 
    ;004 This is changing on us 12M to 6M
    call AddRefLab("ALKPHOS"                          , eValp, 2, "6,M")     ;"12,M")
    call AddRefLab("ALKALINEPHOSPHATASEISOENZYMEBLOOD", eValp, 2, "6,M", 1)  ;"12,M", 1)
    call AddRefLab("ALKALINEPHOS"                     , eValp, 2, "6,M")     ;"12,M")
    call AddRefLab("AMMONIALVL"                       , eValp, 2, "6,M")     ;"12,M")
    call AddMedLabGroup(eValp, 2, "Alkaline Phosphatase or Ammonia")
 
    set sTitleMeds = build2(sTitleMeds, ", Depakote/Valproic Acid")
    set valp_ind   = 1 ;003
endif
 
 
if($eMed = eAll or ePsy in($eMed))
    ;004 Changes here are more intensive.  These three groups (hgbA1C, Fasting Lipid, Fasting Glucose) were all ands.
    ;    Now we want it to be Fasting Lipid AND (hgbA1C OR Fasting Glucose)
    ;    That means group work is changing here.
 
    call AddRefMed("CHLORPROMAZINE"      , ePsy)
    call AddRefMed("FLUPHENAZINE"        , ePsy)
    call AddRefMed("HALOPERIDOL"         , ePsy)
    call AddRefMed("LOXAPINE"            , ePsy)
    call AddRefMed("MOLINDONE"           , ePsy)
    call AddRefMed("PERPHENAZINE"        , ePsy)
    call AddRefMed("PIMOZIDE"            , ePsy)
    call AddRefMed("THIORIDAZINE"        , ePsy)
    call AddRefMed("THIOTHIXENE"         , ePsy)
    call AddRefMed("TRIFLUOPERAZINE"     , ePsy)
    call AddRefMed("ARIPIPRAZOLE"        , ePsy)
    call AddRefMed("ASENAPINE"           , ePsy)
    call AddRefMed("BREXPIPRAZOLE"       , ePsy)
    call AddRefMed("CARIPRAZINE"         , ePsy)
    call AddRefMed("CLOZAPINE"           , ePsy)
    call AddRefMed("ILOPERIDONE"         , ePsy)
    call AddRefMed("LURASIDONE"          , ePsy)
    call AddRefMed("OLANZAPINE"          , ePsy)
    call AddRefMed("PALIPERIDONE"        , ePsy)
    call AddRefMed("QUETIAPINE"          , ePsy)
    call AddRefMed("RISPERIDONE"         , ePsy)
    call AddRefMed("ZIPRASIDONE"         , ePsy)
    call AddRefMed("FLUOXETINEOLANZAPINE", ePsy)
 
    call AddRefLab("HGBA1CGLYCOSYLATED"  , ePsy, 0, "12,M")
    call AddRefLab("HGBA1C"              , ePsy, 0, "12,M")
    call AddRefLab("GLUCOSEFASTING"      , ePsy, 0, "12,M")
    call AddRefLab("GLUCOSELVLRANDOM"    , ePsy, 0, "12,M")
    call AddMedLabGroup(ePsy, 0, "HgbA1C or Fasting Glucose")
 
    ;004 Removing, and replacing above
    ;call AddRefLab("HGBA1CGLYCOSYLATED"  , ePsy, 0, "12,M")
    ;call AddRefLab("HGBA1C"              , ePsy, 0, "12,M")
    ;call AddMedLabGroup(ePsy, 0, "HgbA1C")
 
    call AddRefLab("CHOLESTEROL"  , ePsy, 1, "12,M")
    call AddRefLab("TRIGLYCERIDE" , ePsy, 1, "12,M")
    call AddRefLab("HDL"          , ePsy, 1, "12,M")
    call AddRefLab("LDLCALCULATED", ePsy, 1, "12,M")
    call AddRefLab("CHOLHDL"      , ePsy, 1, "12,M")
    call AddMedLabGroup(ePsy, 1, "Fasting Lipid Profile")
 
    ;004 Removing, and replacing above
    ;call AddRefLab("GLUCOSEFASTING"  , ePsy, 2, "12,M")
    ;call AddRefLab("GLUCOSELVLRANDOM", ePsy, 2, "12,M")
    ;call AddMedLabGroup(ePsy, 2, "Fasting Glucose")
 
    set sTitleMeds = build2(sTitleMeds, ", Atypical Anti-psychotics")
    set psy_ind    = 1 ;003
endif
 
 
set sTitleMeds = trim(replace(sTitleMeds, ",", " ", 1), 3)
 
 
; determine report titles
if(bAllUnits)
    set sTitleLoc = "*ALL Locations"
 
else
    select into "nl:"
      from code_value cv
      plan cv
       where cv.code_value = $dUnit
    order cv.display desc
 
    detail
        sTitleLoc = concat(trim(replace(cv.display, "MedStar", " ", 1), 3), ", ", sTitleLoc)
    with nocounter
 
    set sTitleLoc = trim(replace(sTitleLoc, ",", " ", 2))
 
endif
 
if(bAllPrv)
    set sTitlePrv = "*ALL Providers"
 
else
    select into "nl:"
      from prsnl ps
      plan ps
       where ps.person_id = $dPrvId
    order ps.name_full_formatted desc
    detail
        sTitlePrv = concat(trim(ps.name_full_formatted), "; ", sTitlePrv)
    with nocounter
 
 
    set sTitlePrv = trim(replace(sTitlePrv, ";", " ", 2))
 
endif


;006->
if($lookback_flag = 'RX') set sTitleLookB = 'RX Compliance'
else                      set sTitleLookB = 'Current Compliance'
endif
;006<-

 
set sTitleRange = build2("Prescribed between ", format(dtBeg, "mm/dd/yyyy;;D"), " and ", format(dtEnd, "mm/dd/yyyy;;D"))
 
; ************************************************
; **************** MAIN POPULATION ***************
; ************************************************
; qualify all specified prescriptions over the past year for specifed locations and/or providers
; only qualify prescriptions that are still active
set dtNow = cnvtdatetime(curdate, curtime3)
select into "nl:"
  from orders       o
     , encounter    e
     , order_action oa
     , prsnl        ps
  plan o
   where o.orig_order_dt_tm     between cnvtdatetime(dtBeg) and cnvtdatetime(dtEnd) and
         o.synonym_id           =  ( ; qualifying syn_id for index usage
                                    select ocs.synonym_id
                                      from order_catalog_synonym ocs
                                     where expand(nNdx, 1, nRefMed, ocs.catalog_cd, ref->meds[nNdx].dCd)
                                       and ocs.active_ind = 1
                                   )
     and o.activity_type_cd     =  705.0  ; pharmacy
     and o.product_id           =  0.0
     and o.order_status_cd      =  2550.0 ; ordered
     and o.orig_ord_as_flag     =  1 ; prescription
  join e
   where e.encntr_id            = o.encntr_id
     and e.loc_nurse_unit_cd    = ( ; ensure clinic location if *ALL is selected
                                   select code_value
                                   from code_value
                                   where (   bAllUnits  = 1
                                          or code_value = $dUnit)
                                     and code_set       = 220
                                     and cdf_meaning    in ("AMBULATORY", "NURSEUNIT")
                                     and active_ind     = 1
                                  )
  join oa
   where oa.order_id            =  o.order_id
   and oa.action_type_cd        =  2534.0 ; order
   and (   bAllPrv              =  1
        or oa.order_provider_id =  $dPrvId)
  join ps
   where ps.person_id           =  oa.order_provider_id
order o.person_id, o.synonym_id
head o.person_id
    nCnt = nCnt + 1
    nMed = 0
 
    if(mod(nCnt, 10) = 1)
        stat = alterlist(qual->pats, nCnt + 9)
    endif
 
    qual->pats[nCnt].dPId = o.person_id
    qual->pats[nCnt].dEId = o.encntr_id
 
head o.synonym_id
    nMed = nMed + 1
 
    nNdx = locateval(nNdx, 1, nRefMed, o.catalog_cd, ref->meds[nNdx].dCd)
 
    stat = alterlist(qual->pats[nCnt].meds, nMed)
 
    qual->pats[nCnt].meds[nMed].dPSId  = ps.person_id
    qual->pats[nCnt].meds[nMed].sPhys  = trim(ps.name_full_formatted)
    qual->pats[nCnt].meds[nMed].eMed   = ref->meds[nNdx].eMed
    qual->pats[nCnt].meds[nMed].dCatCd = o.catalog_cd
    qual->pats[nCnt].meds[nMed].ord_id = o.order_id
    qual->pats[nCnt].meds[nMed].rx_dt  = o.orig_order_dt_tm
;004->
;He seems to have missed this and it irks me
foot report
    stat = alterlist(qual->pats, nCnt)
;004<-
with nocounter, orahintcbo('INDEX(O XIE17ORDERS) LEADING(O E)')
 
if(not curqual)
  set _memory_reply_string = "No data qualified for specified parameters"
  go to EXIT_SCRIPT
endif
 
 
; ********************************************************************
; now determine missing labs for each patient specific to each med
; ********************************************************************
set bNoQual = 1

if($lookback_flag = 'RX')
    select into "nl:"
        nGroup = ref->labs[l.seq].nGroup
      from (dummyt p   with seq = value(nCnt))
         , dummyt  pm
         , (dummyt l   with seq = value(nRefLab))
         , (dummyt mlg with seq = value(nMedLabGrp))
         , dummyt  d
         , clinical_event ce
      plan p
       where maxrec(pm, size(qual->pats[p.seq].meds, 5))
     
      join pm
     
      join l
       where ref->labs[l.seq].eMed              =  qual->pats[p.seq].meds[pm.seq].eMed
     
      join mlg
       where ref->med_lab_group[mlg.seq].eMed   =  ref->labs[l.seq].eMed
         and ref->med_lab_group[mlg.seq].nGroup =  ref->labs[l.seq].nGroup
      ;004 what is this goofy stuff
      join (d
      join ce
       where ce.person_id                       =  qual->pats[p.seq].dPId
         and ((    ref->labs[l.seq].bOrd        =  0
               and ce.event_cd                  =  ref->labs[l.seq].dCd
              )
              or
              (    ref->labs[l.seq].bOrd        =  1
               and ce.catalog_cd                =  ref->labs[l.seq].dCd
              )
             )
         and ce.event_end_dt_tm                 >= cnvtlookbehind( ref->labs[l.seq].sLookBack
                                                                 , cnvtdatetime(qual->pats[p.seq].meds[pm.seq].rx_dt)
                                                                 )
         and ce.event_end_dt_tm                 <= cnvtdatetime(qual->pats[p.seq].meds[pm.seq].rx_dt)
         and ce.view_level                      =  1
         and ce.valid_until_dt_tm               >  sysdate
         and ce.result_status_cd                in (25, 34, 35)
      )
    order p.seq, pm.seq, nGroup, ce.event_id
    head p.seq
        row + 0
     
    head pm.seq
        n = 0
     
    head nGroup
        bHas = 0 ; default nothing in this group of labs
     
    head ce.event_id
        if(ce.event_id > 0) ; found a lab in this group
            bHas = 1
        endif

    foot nGroup
        if(not bHas) ; if no labs found in this group
            n = n + 1
     
            qual->pats[p.seq].bQual = 1
     
            stat = alterlist(qual->pats[p.seq].meds[pm.seq].missing, n)
     
            qual->pats[p.seq].meds[pm.seq].bQual = 1
     
            bNoQual = 0
     
            qual->pats[p.seq].meds[pm.seq].missing[n].sLab = ref->med_lab_group[mlg.seq].sLbl
        endif
    with nocounter, outerjoin = d

else
    select into "nl:"
        nGroup = ref->labs[l.seq].nGroup
      from (dummyt p   with seq = value(nCnt))
         , dummyt  pm
         , (dummyt l   with seq = value(nRefLab))
         , (dummyt mlg with seq = value(nMedLabGrp))
         , dummyt  d
         , clinical_event ce
      plan p
       where maxrec(pm, size(qual->pats[p.seq].meds, 5))
     
      join pm
     
      join l
       where ref->labs[l.seq].eMed              =  qual->pats[p.seq].meds[pm.seq].eMed
     
      join mlg
       where ref->med_lab_group[mlg.seq].eMed   =  ref->labs[l.seq].eMed
         and ref->med_lab_group[mlg.seq].nGroup =  ref->labs[l.seq].nGroup
      ;004 what is this goofy stuff
      join (d
      join ce
       where ce.person_id                       =  qual->pats[p.seq].dPId
         and ((    ref->labs[l.seq].bOrd        =  0
               and ce.event_cd                  =  ref->labs[l.seq].dCd
              )
              or
              (    ref->labs[l.seq].bOrd        =  1
               and ce.catalog_cd                =  ref->labs[l.seq].dCd
              )
             )
         and ce.event_end_dt_tm                 >  cnvtlookbehind(ref->labs[l.seq].sLookBack)
         and ce.view_level                      =  1
         and ce.valid_until_dt_tm               >  sysdate
         and ce.result_status_cd                in (25, 34, 35)
      )
    order p.seq, pm.seq, nGroup, ce.event_id
    head p.seq
        row + 0
     
    head pm.seq
        n = 0
     
    head nGroup
        bHas = 0 ; default nothing in this group of labs
     
    head ce.event_id
        if(ce.event_id > 0) ; found a lab in this group
            bHas = 1
        endif

    foot nGroup
        if(not bHas) ; if no labs found in this group
            n = n + 1
     
            qual->pats[p.seq].bQual = 1
     
            stat = alterlist(qual->pats[p.seq].meds[pm.seq].missing, n)
     
            qual->pats[p.seq].meds[pm.seq].bQual = 1
     
            bNoQual = 0
     
            qual->pats[p.seq].meds[pm.seq].missing[n].sLab = ref->med_lab_group[mlg.seq].sLbl
        endif
    with nocounter, outerjoin = d



endif



if(bNoQual)
    set _memory_reply_string = "No Data. All patients active on specified med(s) are lab compliant."
    go to EXIT_SCRIPT
endif
 
 
; ********************************************************************
; qualify additional patient data on those who've qualified for this report
; ********************************************************************
select into "nl:"
  from (dummyt d with seq = value(nCnt))
     , person       p
     , person_alias pa
  plan d
   where qual->pats[d.seq].bQual =  1
  join p
   where p.person_id             =  qual->pats[d.seq].dPId
  ;006->This is changing to PA
  join pa
   where pa.person_id            =  qual->pats[d.seq].dPId
     and pa.person_alias_type_cd =  2.0
     and pa.active_ind           =  1
     and pa.end_effective_dt_tm  >  sysdate
  ;006<-
 
detail
    qual->pats[d.seq].sName = trim(p.name_full_formatted)
    qual->pats[d.seq].sMRN  = trim(cnvtalias(pa.alias, pa.alias_pool_cd))  ;006
    qual->pats[d.seq].sDOB  = format(p.birth_dt_tm, "mm/dd/yyyy;;D")
with nocounter
 

;006 We are about to butcher this... so... saving for postarity.
;004->
/* Most the work is done for us, thank god.  We just need to get patient totals over the whole list
   as well as physician totals.  And Percentage work as well.  He seems to be storing most of what we
   need already... So... I think I'm just going to loop and do our work rather than try and shoehorn
   into the above
*/
 
;for(pat_looper = 1 to size(qual->pats, 5))
;    for(med_looper = 1 to size(qual->pats[pat_looper]->meds, 5))
;        ;find our position for phys specific counts.
;        set pos = locateval(idx, 1, phys_cnts->cnt, qual->pats[pat_looper]->meds[med_looper]->dPSId
;                                                  , phys_cnts->qual[idx].phys_id)
; 
;        if(pos = 0)
;            set phys_cnts->cnt = phys_cnts->cnt + 1
;            set pos            = phys_cnts->cnt
; 
;            set stat           = alterlist(phys_cnts->qual, phys_cnts->cnt)
; 
;            set phys_cnts->qual[pos]->phys_id   = qual->pats[pat_looper]->meds[med_looper]->dPSId
;            set phys_cnts->qual[pos]->phys_name = qual->pats[pat_looper]->meds[med_looper]->sPhys
;        endif
; 
; 
;        set qual->tot_cnt = qual->tot_cnt + 1
;        set phys_cnts->qual[pos]->tot_cnt = phys_cnts->qual[pos]->tot_cnt + 1
; 
;        if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
;            set qual->miss_cnt = qual->miss_cnt + 1
;            set phys_cnts->qual[pos]->tot_miss_cnt = phys_cnts->qual[pos]->tot_miss_cnt + 1
;        endif
; 
; 
;        case(qual->pats[pat_looper]->meds[med_looper]->eMed)
;        of 1:
;            set qual->tot_lith = qual->tot_lith + 1
;            set phys_cnts->qual[pos]->lith_cnt = phys_cnts->qual[pos]->lith_cnt + 1
; 
;            if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
;                set qual->miss_lith = qual->miss_lith + 1
;                set phys_cnts->qual[pos]->lith_miss_cnt = phys_cnts->qual[pos]->lith_miss_cnt + 1
;            endif
; 
;        of 2:
;            set qual->tot_val = qual->tot_val + 1
;            set phys_cnts->qual[pos]->val_cnt = phys_cnts->qual[pos]->val_cnt + 1
; 
;            if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
;                set qual->miss_val = qual->miss_val + 1
;                set phys_cnts->qual[pos]->val_miss_cnt = phys_cnts->qual[pos]->val_miss_cnt + 1
;            endif
; 
;        of 3:
;            set qual->tot_psy  = qual->tot_psy + 1
;            set phys_cnts->qual[pos]->psy_cnt = phys_cnts->qual[pos]->psy_cnt + 1
; 
;            if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
;                set qual->miss_psy = qual->miss_psy + 1
;                set phys_cnts->qual[pos]->psy_miss_cnt = phys_cnts->qual[pos]->psy_miss_cnt + 1
;            endif
; 
;        endcase
;    endfor
;endfor

;006-> New version of all this.  Now we want to count each pat just once for each med, and in the total.
for(pat_looper = 1 to size(qual->pats, 5))
    ;006 doesn't make since to do this RS stuff for phys anymore... because we are forcing a run of one physician.
    ;    But leaving it... for now.
    ;find our position for phys specific counts.

    
    call echo('----------------')
    call echo(build('qual->pats[pat_looper]->dPId:', qual->pats[pat_looper]->dPId))
    call echo(build('pat_looper                  :', pat_looper                  ))
    
    set allFound      = 0
    set lithFound     = 0
    set valFound      = 0
    set psyFound      = 0
    
    set allMissFound  = 0
    set lithMissFound = 0
    set valMissFound  = 0
    set psyMissFound  = 0
    
    
    set qual->tot_cnt = qual->tot_cnt + 1
    
    for(med_looper = 1 to size(qual->pats[pat_looper]->meds, 5))
        
        set allFound = 1
        
        
        set pos = locateval(idx, 1, phys_cnts->cnt, qual->pats[pat_looper]->meds[med_looper]->dPSId
                                                  , phys_cnts->qual[idx].phys_id)

        if(pos = 0)
            set phys_cnts->cnt = phys_cnts->cnt + 1
            set pos            = phys_cnts->cnt

            set stat           = alterlist(phys_cnts->qual, phys_cnts->cnt)

            set phys_cnts->qual[pos]->phys_id   = qual->pats[pat_looper]->meds[med_looper]->dPSId
            set phys_cnts->qual[pos]->phys_name = qual->pats[pat_looper]->meds[med_looper]->sPhys
        endif


        if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
            set allMissFound = 1
        endif
 
 
        case(qual->pats[pat_looper]->meds[med_looper]->eMed)
        of 1:
            set lithFound = 1
            
            if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
                set lithMissFound = 1
            endif
 
        of 2:
            set valFound = 1
            
            if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
                set valMissFound = 1
            endif
 
        of 3:
            set psyFound = 1
 
            if(qual->pats[pat_looper]->meds[med_looper]->bQual = 1)
                set psyMissFound = 1
            endif
 
        endcase
    endfor
    
    
    
    if(allFound = 1) 
        set phys_cnts->qual[pos]->tot_cnt = phys_cnts->qual[pos]->tot_cnt + 1 
    endif
    
    if(lithFound = 1)
        set qual->tot_lith = qual->tot_lith + 1       
        set phys_cnts->qual[pos]->lith_cnt = phys_cnts->qual[pos]->lith_cnt + 1       
    endif
    
    if(valFound = 1)
        set qual->tot_val = qual->tot_val + 1
        set phys_cnts->qual[pos]->val_cnt = phys_cnts->qual[pos]->val_cnt + 1       
    endif
    
    if(psyFound = 1)
        set qual->tot_psy  = qual->tot_psy + 1
        set phys_cnts->qual[pos]->psy_cnt = phys_cnts->qual[pos]->psy_cnt + 1       
    endif
    
    
    
    if(allMissFound = 1) 
        set qual->miss_cnt = qual->miss_cnt + 1 
        set phys_cnts->qual[pos]->tot_miss_cnt = phys_cnts->qual[pos]->tot_miss_cnt + 1
    endif
    
    if(lithMissFound = 1)
        set qual->miss_lith = qual->miss_lith + 1
        set phys_cnts->qual[pos]->lith_miss_cnt = phys_cnts->qual[pos]->lith_miss_cnt + 1       
    endif
    
    if(valMissFound = 1)
        set qual->miss_val = qual->miss_val + 1
        set phys_cnts->qual[pos]->val_miss_cnt = phys_cnts->qual[pos]->val_miss_cnt + 1       
    endif
    
    if(psyMissFound = 1)
        set qual->miss_psy = qual->miss_psy + 1
        set phys_cnts->qual[pos]->psy_miss_cnt = phys_cnts->qual[pos]->psy_miss_cnt + 1       
    endif

    call echo(notrim(build2('allFound      :', allFound      , '         ', 'tot_cnt      :', phys_cnts->qual[pos]->tot_cnt)))
    call echo(notrim(build2('lithFound     :', lithFound     , '         ', 'lith_cnt     :', phys_cnts->qual[pos]->lith_cnt)))
    call echo(notrim(build2('valFound      :', valFound      , '         ', 'val_cnt      :', phys_cnts->qual[pos]->val_cnt)))
    call echo(notrim(build2('psyFound      :', psyFound      , '         ', 'psy_cnt      :', phys_cnts->qual[pos]->psy_cnt)))
    call echo(notrim(build2('allMissFound  :', allMissFound  , '         ', 'tot_miss_cnt :', phys_cnts->qual[pos]->tot_miss_cnt)))
    call echo(notrim(build2('lithMissFound :', lithMissFound , '         ', 'lith_miss_cnt:', phys_cnts->qual[pos]->lith_miss_cnt)))
    call echo(notrim(build2('valMissFound  :', valMissFound  , '         ', 'val_miss_cnt :', phys_cnts->qual[pos]->val_miss_cnt)))
    call echo(notrim(build2('psyMissFound  :', psyMissFound  , '         ', 'psy_miss_cnt :', phys_cnts->qual[pos]->psy_miss_cnt)))



endfor
;006<-
 
 
set temp_per = (cnvtreal(qual->miss_cnt) / cnvtreal(qual->tot_cnt)) * 100.0
set qual->per_tot_miss = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
set temp_per = (cnvtreal(qual->miss_lith) / cnvtreal(qual->tot_lith)) * 100.0
set qual->per_miss_lith = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
set temp_per = (cnvtreal(qual->miss_val) / cnvtreal(qual->tot_val)) * 100.0
set qual->per_miss_val = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
set temp_per = (cnvtreal(qual->miss_psy) / cnvtreal(qual->tot_psy)) * 100.0
set qual->per_miss_psy  = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
 
for(phys_looper = 1 to phys_cnts->cnt)
    set temp_per = ( cnvtreal(phys_cnts->qual[phys_looper]->tot_miss_cnt)
                   / cnvtreal(phys_cnts->qual[phys_looper]->tot_cnt     )) * 100.0
    set phys_cnts->qual[phys_looper]->tot_per_miss = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
    set temp_per = ( cnvtreal(phys_cnts->qual[phys_looper]->lith_miss_cnt)
                   / cnvtreal(phys_cnts->qual[phys_looper]->lith_cnt     )) * 100.0
    set phys_cnts->qual[phys_looper]->lith_per_miss = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
    set temp_per = ( cnvtreal(phys_cnts->qual[phys_looper]->val_miss_cnt)
                   / cnvtreal(phys_cnts->qual[phys_looper]->val_cnt     )) * 100.0
    set phys_cnts->qual[phys_looper]->val_per_miss = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
 
    set temp_per = ( cnvtreal(phys_cnts->qual[phys_looper]->psy_miss_cnt)
                   / cnvtreal(phys_cnts->qual[phys_looper]->psy_cnt     )) * 100.0
    set phys_cnts->qual[phys_looper]->psy_per_miss = concat(trim(cnvtstring(temp_per, 3, 0), 3), '%')
endfor
;004<-
 
 
; output
execute ReportRtl
 
%i cust_script:14_beh_lab_mon.dvl
 
set _SendTo = $1
 
call LayoutQuery(0)
 
; get out if not emailing
if(not $bEmail)
    go to EXIT_SCRIPT
endif
 
 
; emailing at this point
%i cust_script:0_file_io.inc
 
 
declare sFile = vc
declare sDCL  = vc
declare sTmp  = vc
 
set sFile = concat( "BEH Med-Lab Monitor "
                  , format(dtBeg, "yyyymmdd;;D"), "-", format(dtEnd, "yyyymmdd;;D")
                  , "_"
                  , substring(6, 3, cnvtstring(rand(0)))
                  , ".csv"
                  )
 
select into "nl:"
    dPSId = qual->pats[d.seq].meds[d2.seq].dPSId,
    dPId  = qual->pats[d.seq].dPId,
    eMed  = qual->pats[d.seq].meds[d2.seq].eMed
  from (dummyt d with seq = value(nCnt))
     , dummyt d2
     , dummyt d3
 
  plan d
   where qual->pats[d.seq].bQual = 1
     and maxrec(d2, size(qual->pats[d.seq].meds, 5))
 
  join d2
   where qual->pats[d.seq].meds[d2.seq].bQual = 1
     and maxrec(d3, size(qual->pats[d.seq].meds[d2.seq].missing, 5))
  join d3
order dPSId, dPId, eMed
head report
    call OpenFile(sFile, eWrite)
    call WriteLine("BEH Med/Lab Compliance Monitoring"                           )
    call WriteLine(build2("Medications: ", sTitleMeds                            ))
    call WriteLine(sTitleRange                                                   )
    call WriteLine(build2("Locations: ", sTitleLoc                               ))
    call WriteLine(build2("Providers: ", sTitlePrv                               ))
    call WriteLine(" "                                                           )
    call WriteLine(",Provider,Patient Name,DOB,MRN,Active Medication,Missing Lab")
 
detail
    sTmp = build2( ',"'
                 , qual->pats[d.seq].meds[d2.seq].sPhys, '","'
                 , qual->pats[d.seq].sName, '",="'
                 , qual->pats[d.seq].sDOB, '",="'
                 , qual->pats[d.seq].sMRN, '","'
                 , trim(uar_get_code_display(qual->pats[d.seq].meds[d2.seq].dCatCd)), '","'
                 , qual->pats[d.seq].meds[d2.seq].missing[d3.seq].sLab, '"'
                 )
 
    call WriteLine(sTmp)
 
foot report
    call CloseFile(0)
with nocounter
 
; email the spreadsheet
set sDCL = build2( '(echo "Your report is attached. Please do not respond to this email")'
                 , '|mailx -s "BEH Med-Lab Monitoring Report" -a "'
                 , sFile, '" -r reports.no-reply@medstar.net '
                 , sParamEmail
                 )
 
call dcl(sDCL, textlen(sDCL), 0)
 
set stat = remove(sFile)
 
 
#EXIT_SCRIPT
 
subroutine AddRefMed(sKey, eMed)
    set nRefMed = nRefMed + 1
 
    set stat = alterlist(ref->meds, nRefMed)
 
    set ref->meds[nRefMed].dCd  = uar_get_code_by("DISPLAYKEY", 200, sKey)
    set ref->meds[nRefMed].eMed = eMed
end
 
subroutine AddRefLab(sKey, eMed, nGroup, sLookBack, bOrd)
    set nRefLab = nRefLab + 1
 
    set stat = alterlist(ref->labs, nRefLab)
 
    if(bOrd)
        set ref->labs[nRefLab].bOrd = 1
        set ref->labs[nRefLab].dCd = uar_get_code_by("DISPLAYKEY", 200, sKey)
 
    else
        set ref->labs[nRefLab].dCd = uar_get_code_by("DISPLAYKEY", 72, sKey)
 
    endif
 
    set ref->labs[nRefLab].eMed      = eMed
    set ref->labs[nRefLab].nGroup    = nGroup ; meds within a group are "OR" conditions
    set ref->labs[nRefLab].sLookBack = sLookBack
end
 
subroutine AddMedLabGroup(eMed, nGroup, sLbl)
    set nMedLabGrp = nMedLabGrp + 1
 
    set stat = alterlist(ref->med_lab_group, nMedLabGrp)
 
    set ref->med_lab_group[nMedLabGrp].eMed   = eMed
    set ref->med_lab_group[nMedLabGrp].nGroup = nGroup
    set ref->med_lab_group[nMedLabGrp].sLbl   = sLbl
end
 
 
call echorecord(qual)
call echorecord(phys_cnts)
 
 
end go
 
 
 

