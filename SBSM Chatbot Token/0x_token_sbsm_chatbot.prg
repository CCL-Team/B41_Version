/*************************************************************************
 Program Title:   SBSM Chatbot Token
 
 Object name:     0x_token_sbsm_chatbot
 Source file:     0x_token_sbsm_chatbot.prg
 
 Purpose:         Conditionally provides SBSM Chatbot education, if
                  criteria is met.
 
 Tables read:
 
 Executed from:   PowerForms
 
 Special Notes:   This is what I gathered from spec meetings for stuff not 
                  explicitly covered by the specs.
                  
                  1) They want the messages to be conditional for visits using 
                     the same logic as in the chatbot extracts:
                        14_sbsm_chatbot
                        14_sbsm_maternal_chatbot
                  2) The location filtering will probably be handled by the 
                     tracking group, or whatever that is in the depart process
                  3) But we'll have to copy logic from those extracts, just to
                     handle population and exclusions.
                  4) Baby encounter gets the baby message.
                  5) Mother encounter gets the mother message.
                  
                  Images should work out, we do this elsewhere.  I placed the 
                  images here: I:\mPages\SBSMChatBotToken\
                  
                  And away we go.
 
*********************************************************************************
                  MODIFICATION CONTROL LOG
*********************************************************************************
Mod Date       Analyst              	MCGA        	Comment
--- ---------- -------------------- ---------- ----------------------------------
001 05/17/2018 Michael Mayes        	211495			Initial release
*************END OF ALL MODCONTROL BLOCKS* *************************************/
  drop program 0x_token_sbsm_chatbot:dba go
create program 0x_token_sbsm_chatbot:dba 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
 
/*
record request(
    1 encntr_id   = f8
    1 person_id   = f8
    1 tracking_id = f8
)
 
 
record reply(
    1 text = vc
    1 format = i4
)
*/
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare html_head   = vc with protect, constant('<html><body>')
declare html_foot   = vc with protect, constant('</body></html> ')
 
declare mom_html = vc with protect, constant(concat(
      ^<p style='font-size:16pt;font-weight:bold;text-decoration: underline;text-align:center'>CHATBOT FOLLOW-UP MESSAGES</p>^
    , ^<p>^
    ,     ^The day after you leave the hospital you will get a text message and email with important information. ^
    ,     ^We will send you new information 1-2 times per week for six weeks. ^
    ,     ^Please open this message to access information about recovery.^
    , ^</p>^
    
    ; ^<img src='I:\mPages\SBSMChatBotToken\SBSMChatBotMom.png' ^,
    ;           ^style="display:block;margin-left:auto;margin-right:auto;text-align:center" />^
    
    , ^<img src='http://mhgrdceanp.cernerasp.com/mpage-content/b41.mhgr_dc.cernerasp.com/^
    ,            ^custom_mpage_content/mpage_reference_files/SBSMChatBotToken/^
    ,            ^SBSMChatBotMom.png' ^,
                ^style="display:block;margin-left:auto;margin-right:auto;text-align:center" />^

))


declare baby_html = vc with protect, constant(concat(
      ^<p style='font-size:16pt;font-weight:bold;text-decoration: underline;text-align:center'>CHATBOT FOLLOW-UP MESSAGES</p>^
    , ^<p>^
    ,     ^The day after your baby leaves the hospital you will get a text message and email with important information. ^
    ,     ^We will send you new information 1-2 times per week for six weeks. ^
    ,     ^Please open this message to access information about caring for your baby.^ 
    , ^</p>^
    
    ;, ^<img src='I:\mPages\SBSMChatBotToken\SBSMChatBotBaby.png' ^,
    ;            ^style="display:block;margin-left:auto;margin-right:auto;text-align:center" />^
    
    , ^<img src='http://mhgrdceanp.cernerasp.com/mpage-content/b41.mhgr_dc.cernerasp.com/^
    ,            ^custom_mpage_content/mpage_reference_files/SBSMChatBotToken/^
    ,            ^SBSMChatBotBaby.png' ^,
                ^style="display:block;margin-left:auto;margin-right:auto;text-align:center" />^

))


 
/**************************************************************
; DVDev Start Coding
**************************************************************/
/* Okay for this, I'm going to handle the two logics separate at first.  If I can combine logic afterwards, I'll give it a shot.
   I'm copying queries and such out of the extracts, and removing the data parts, leaving the population and exclusion parts.
*/

;Shared Logic ->

declare dispo_txt = vc with protect, noconstant("")

/**********************************************************************
DESCRIPTION: Gather discharge dispo
       NOTE: This is am exclusion from the chatbot, if it isn't "Home".
             Both Baby and Mom do this, so pulling it out.
***********************************************************************/
select into "nl:"

  from orders       ord
     , order_detail o
 
 where ord.encntr_id  = request->encntr_id
   and ord.catalog_cd = 101815629.00  ; discharge patient

   and o.order_id     = ord.order_id
   and o.oe_field_id  = 102229741.00  ; discharge to 
 
detail
    dispo_txt = o.oe_field_display_value
with nocounter



;Shared Logic <-



;Baby Logic ->

declare baby_birth_enc_ind = i2 with protect, noconstant(0)
declare baby_adopt_ind     = i2 with protect, noconstant(0)
declare baby_message_ind   = i2 with protect, noconstant(0)

/**********************************************************************
DESCRIPTION: Check encounter for baby birth encounter qualifications
***********************************************************************/
select into "nl:" 
  
  from encounter           e
     , person              p
     , encntr_encntr_reltn eer
 
 where e.encntr_id              =  request->encntr_id

   and p.person_id              =  e.person_id
   and p.birth_dt_tm            >  cnvtlookbehind("10,W")
   and p.active_ind             =  1

   and eer.encntr_id            =  e.encntr_id
   and eer.encntr_reltn_type_cd =  56648293.00  ;NEWBORN

 
detail
    baby_birth_enc_ind = 1
with nocounter


if(baby_birth_enc_ind = 1)
    /**********************************************************************
    DESCRIPTION: Checking for adoption.
           NOTE: This is a baby exclusion from the chatbot.
    ***********************************************************************/
    select into "nl:"
      
      from diagnosis 	dx
         , nomenclature n
     
     where dx.encntr_id               =  request->encntr_id
       and dx.diagnosis_id            != 0.00
       and dx.confirmation_status_cd  in (3305.00, 674227.00)  ;confirmed, complaint of
       and dx.active_status_cd        =  188.00
       and dx.end_effective_dt_tm     >  cnvtdatetime(curdate,curtime3)
     
       and n.nomenclature_id          =  dx.nomenclature_id
       and n.active_ind               =  1
       and n.active_status_cd         =  188 ; active
       and n.source_identifier_keycap in ( "Z02.82"  ; Encounter for adoption services
                                         , "Z33.3"   ; Pregnant state, gestational carrier
                                         )

    detail
        baby_adopt_ind = 1
    with nocounter

endif


;Baby final determination
if(    baby_birth_enc_ind =  1
   and baby_adopt_ind     != 1
   and dispo_txt          = "Home"
  )
    set baby_message_ind = 1
endif


call echo('********************** Baby Checks **********************')
call echo(build('baby_birth_enc_ind:', baby_birth_enc_ind))
call echo(build('baby_adopt_ind    :', baby_adopt_ind    ))
call echo(build('dispo_txt         :', dispo_txt         ))
call echo(build('baby_message_ind  :', baby_message_ind  ))
call echo('*********************************************************')

;Baby Logic <-

;Mom Logic ->

declare mom_birth_enc_ind = i2 with protect, noconstant(0)
declare mom_fhbc_ind      = i2 with protect, noconstant(0)
declare mom_message_ind   = i2 with protect, noconstant(0)

/**********************************************************************
DESCRIPTION: Check encounter for mother birth encounter qualifications
***********************************************************************/
select into "nl:" 
  
  from encounter           e
     , person              p
     , encntr_encntr_reltn eer
 
 where e.encntr_id              =  request->encntr_id

   and p.person_id              =  e.person_id
   and p.birth_dt_tm            <  cnvtlookbehind("10,Y")
   and p.active_ind             =  1
   and p.name_last_key          != "CAREMOBILE"
   and p.name_last_key          != "REGRESSION"
   and p.name_last_key          != "TEST"
   and p.name_last_key          != "CERNERTEST"
   and p.name_last_key          != "*PATIENT*"
   and not operator(p.name_last_key,"REGEXPLIKE","[0-9]")
   and p.end_effective_dt_tm > cnvtdatetime(sysdate)

   and eer.encntr_id            =  e.encntr_id
   and eer.encntr_reltn_type_cd =  56648293.00  ;NEWBORN

 
detail
    mom_birth_enc_ind = 1
with nocounter


if(mom_birth_enc_ind = 1)
    /**********************************************************************
    DESCRIPTION: Check encounter for location exclusion
    ***********************************************************************/
    select into "nl:"
      from clinical_event c
     
     where c.encntr_id = request->encntr_id
       and c.event_cd =  2363440579.00 
       and c.result_val = "*Family Health and Birthing Center (FHBC)*"
       and c.result_status_cd in (25,34,35)
     
    detail
        mom_fhbc_ind = 1
    with nocounter

    
endif


;Mom final determination
if(    mom_birth_enc_ind =  1
   and mom_fhbc_ind      != 1
   and dispo_txt         = "Home"
  )
    set mom_message_ind = 1
endif


call echo('********************* Mother Checks *********************')
call echo(build('mom_birth_enc_ind:', mom_birth_enc_ind))
call echo(build('mom_fhbc_ind     :', mom_fhbc_ind     ))
call echo(build('dispo_txt        :', dispo_txt        ))
call echo(build('mom_message_ind  :', mom_message_ind  ))
call echo('*********************************************************')

;Mom Logic <-


;Display time.
set reply->format = 1

if    (baby_message_ind = 1) set reply->text = build(html_head, baby_html, html_foot)
elseif(mom_message_ind  = 1) set reply->text = build(html_head, mom_html , html_foot)
else                         set reply->text = build(html_head           , html_foot)
endif
 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
;debugging
call echorecord(reply)
call echo(reply->text)
 
end
go
 