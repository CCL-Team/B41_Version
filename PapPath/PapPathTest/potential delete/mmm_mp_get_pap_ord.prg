/**************************************************************************
 Program Title:   mPage Get PAP Orders
 
 Object name:     mmm_mp_get_pap_ord
 Source file:     mmm_mp_get_pap_ord.prg
 
 Purpose:         Gets a defined list of orders for the Pap/Path mPage
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 02/22/2018 Michael Mayes        210739    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mmm_mp_get_pap_ord:dba go
create program mmm_mp_get_pap_ord:dba


prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
with OUTDEV


/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/

free record orders
record orders(
    1 results[*]
        2 text        = vc
        2 children[*]
            4 id      = f8
            4 text    = vc
%i cust_script:mmm_mp_status.inc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/



/**************************************************************
; DVDev Start Coding
**************************************************************/

/*Right now it looks like everything is grouped by 2 groups.  RS and frontend will need work if this changes
  Here is the current state of things:
                                                                 Same order note
  LabCorp
      Ages 21-29
          AptmPap IGTP CT/NG NAA rfx HPV ASCUS (LabCorp Only)    [1]
          AptmPap IGTP rfx HPV ASCUS (LabCorp Only)              [2]
      Ages 30+
          AptmPap IGTP CT/NG NAA rfx HPV ASCUS (LabCorp Only)    [1]
          AptmPap IGTP HPV rfx HPV16,18/45 (LabCorp Only)
          AptmPap IGTP rfx HPV ASCUS (LabCorp Only)              [2]
          AptmPapIGTP HPV rfx HPV16,18/45 CT/NG (LabCorp Only)
          AptmPapIGTP HPVrfxHPV16,18/45 CT/NG (LabCorp Only)
  Quest
      Ages 21-29
          Pap IG Ct-Ng rfx HPV ASCU                              [3]
          Pap IG, rfx HPV ASCU                                   [4]
      Ages 30+ (16/18 testing every 3 years)
          Pap IG Ct-Ng rfx HPV ASCU                              [3]
          PAP IG HPV E6-E7 Rfx HPV 16/18, 45 (Quest Only
          Pap IG, rfx HPV ASCU                                   [4]
  Cultures
      LabCorp CT/NG & TV
          Aptm CT/NG NAA (LabCorp Only)
          Aptm CT/NG/TV NAA (LabCorp Only)
      Quest CT/NG & TV
          Chlamydia/Gonorrhoeae Nucleic Acid Amplification
          CT/NG, T. Vaginalis, PCR                               ;I can't find this one?  Is it CT/NG, Trich, HSV PCR?
      VG & VG (LabCorp or Quest)
          Vaginitis (BV, Candida, Trich) PCR
          Vaginitis Plus (BV, Candida, Trich, CT/NG) PCR
      Culture  ;Taking liberties here, these are actually in the spreadsheet as just under the cultures parent. We'll try this first
          Culture, Bact, Genital
          Culture, Viral, HSV Reflex to Typing

AAAAAND apparently none of that is possible in HTML.  Only one select group.          
*/  




/***********************************************************************
DESCRIPTION:  Gather orders, pulling their names and ids
***********************************************************************/
select into 'nl:'
  from order_catalog oc
 where oc.primary_mnemonic in( 
    'AptmPap IGTP CT/NG NAA rfx HPV ASCUS (LabCorp Only)',
    'AptmPap IGTP rfx HPV ASCUS (LabCorp Only)',
    'AptmPap IGTP HPV rfx HPV16,18/45 (LabCorp Only)',
    'AptmPapIGTP HPVrfxHPV16,18/45 CT/NG (LabCorp Only)', ;This one was spaced different than the spreadsheet
    
    'Pap IG Ct-Ng rfx HPV ASCU',
    'Pap IG, rfx HPV ASCU',
    'PAP IG HPV E6-E7 Rfx HPV 16/18,45 (Quest Only)', ;This one was spaced different than the spreadsheet
    
    'Aptm CT/NG NAA (LabCorp Only)',
    'Aptm CT/NG/TV NAA (LabCorp Only)',
    'Chlamydia/Gonorrhoeae nucleic acid amplification', ;This one was spaced different than the spreadsheet
    ;I'm missing one here....
    'Vaginitis (BV, Candida, Trich) PCR',
    'Vaginitis Plus (BV, Candida, Trich, CT/NG) PCR',
    'Culture, Bact, Genital',
    'Culture, Viral, HSV Reflex to Typing'
    )
order by oc.description 
head report
    ;This is obviously pretty hardcody, but this is simple enough I think I can get away with it
    stat = alterlist(orders->results, 3)
    
    orders->results[1]->text = "LabCorp"
        stat = alterlist(orders->results[1]->children, 4)
        
    orders->results[2]->text = "Quest"
        stat = alterlist(orders->results[2]->children, 3)
    
    orders->results[3]->text = "Cultures"
        stat = alterlist(orders->results[3]->children, 7)

    
head oc.description 
    case(oc.primary_mnemonic)
        of 'AptmPap IGTP CT/NG NAA rfx HPV ASCUS (LabCorp Only)':
            orders->results[1]->children[1]->id   = oc.catalog_cd
            orders->results[1]->children[1]->text = trim(oc.description, 3)
            
        of 'AptmPap IGTP rfx HPV ASCUS (LabCorp Only)':
            orders->results[1]->children[2]->id   = oc.catalog_cd
            orders->results[1]->children[2]->text = trim(oc.description, 3)
            
        of 'AptmPap IGTP HPV rfx HPV16,18/45 (LabCorp Only)':
            orders->results[1]->children[3]->id   = oc.catalog_cd
            orders->results[1]->children[3]->text = trim(oc.description, 3)
            
        of 'AptmPapIGTP HPVrfxHPV16,18/45 CT/NG (LabCorp Only)':
            orders->results[1]->children[4]->id   = oc.catalog_cd
            orders->results[1]->children[4]->text = trim(oc.description, 3)
        
        of 'Pap IG Ct-Ng rfx HPV ASCU':
            orders->results[2]->children[1]->id   = oc.catalog_cd
            orders->results[2]->children[1]->text = trim(oc.description, 3)
             
        of 'Pap IG, rfx HPV ASCU':
            orders->results[2]->children[2]->id   = oc.catalog_cd
            orders->results[2]->children[2]->text = trim(oc.description, 3)
            
        of 'PAP IG HPV E6-E7 Rfx HPV 16/18,45 (Quest Only)':
            orders->results[2]->children[3]->id   = oc.catalog_cd
            orders->results[2]->children[3]->text = trim(oc.description, 3)
            
        of 'Aptm CT/NG NAA (LabCorp Only)':
            orders->results[3]->children[1]->id   = oc.catalog_cd
            orders->results[3]->children[1]->text = trim(oc.description, 3)
            
        of 'Aptm CT/NG/TV NAA (LabCorp Only)':
            orders->results[3]->children[2]->id   = oc.catalog_cd
            orders->results[3]->children[2]->text = trim(oc.description, 3)
            
        of 'Chlamydia/Gonorrhoeae nucleic acid amplification':
            orders->results[3]->children[3]->id   = oc.catalog_cd
            orders->results[3]->children[3]->text = trim(oc.description, 3)

        ;of 'CT/NG, T. Vaginalis, PCR':
        
        of 'Vaginitis (BV, Candida, Trich) PCR':
            orders->results[3]->children[4]->id   = oc.catalog_cd
            orders->results[3]->children[4]->text = trim(oc.description, 3)
            
        of 'Vaginitis Plus (BV, Candida, Trich, CT/NG) PCR':
            orders->results[3]->children[5]->id   = oc.catalog_cd
            orders->results[3]->children[5]->text = trim(oc.description, 3)
            
        of 'Culture, Bact, Genital':
            orders->results[3]->children[6]->id   = oc.catalog_cd
            orders->results[3]->children[6]->text = trim(oc.description, 3)
            
        of 'Culture, Viral, HSV Reflex to Typing':
            orders->results[3]->children[7]->id   = oc.catalog_cd
            orders->results[3]->children[7]->text = trim(oc.description, 3)
    endcase
    
with format, separator = " "





/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script

call echorecord(orders)
call echojson(orders)

if(size(orders->results,5) > 0)
    set orders->status_data->status = "S"
else
    set orders->status_data->status = "Z"
endif


call putStringToFile($outdev, orders)


end
go
 