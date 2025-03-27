/*************************************************************************
 Program Title: Bariatric ED Orderset Result

 Object name:   0_eks_bari_ed_os_res
 Source file:   0_eks_bari_ed_os_res.prg

 Purpose:       Identify the most recent Bariatric Procedure, and location
                for a patient for a couple of Bariatric rules.

 Tables read:

 Executed from: Rules
                CUST_BARI_OS_RESULT
                CUST_BARI_OS_SZ_NOTIFY
                CUST_ED_BARI_OS_PROC_DAYS

 Special Notes:

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 12/05/2024 Michael Mayes        347124 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_bari_ed_os_res:dba go
create program 0_eks_bari_ed_os_res:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)

/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/



/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))  
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))    
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED')) 

declare ord_loc        = vc  with protect, noconstant('')
declare lab_name       = vc  with protect, noconstant('')
declare lab_result     = vc  with protect, noconstant('')

/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_bari_ed_os_res failed during execution"



/**********************************************************************
DESCRIPTION:  Find Location of the Patient
      NOTES:  We are after
                FSH UMH GSH HH
                WHC GUH
                MMC
                SMH
                SMHC
***********************************************************************/
select into 'nl:'
  from encounter e
 where e.encntr_id  =  trigger_encntrid
detail
    ;Defaulting a case in
    ord_loc = 'Unknown'

    case(e.organization_id)
    of  589723.00:  ord_loc = 'FSH' ;FSH
    of  628058.00:  ord_loc = 'UMH' ;UMH
    of  627889.00:  ord_loc = 'GSH' ;GSH
    of  628009.00:  ord_loc = 'HH'  ;HH
    of  628088.00:  ord_loc = 'WHC' ;WHC
    of  628085.00:  ord_loc = 'GUH' ;GUH
    of 3763758.00:  ord_loc = 'MMC' ;MMC
    of 3440653.00:  ord_loc = 'SMH' ;SMH
    of 3837372.00:  ord_loc = 'SMHC';SMHC
    of  628738.00:  ord_loc = 'NRH' ;NRH - not in specs... probably not covered.

    endcase
with nocounter


/**********************************************************************
DESCRIPTION:  Find Lab name
      NOTES:  This is done outside of results, in case we don't have 
              actual results, and the lab just went complete.
***********************************************************************/
select into 'nl:'
  
  from orders o
     , order_catalog oc
  
 where o.order_id = link_orderid
 
   and oc.catalog_cd = o.catalog_cd
   
detail
    
    lab_name = trim(oc.description, 3)
    
with nocounter


/**********************************************************************
DESCRIPTION:  Find Result Data if we can.
      NOTES:  
***********************************************************************/
select into 'nl:'
  
  from clinical_event ce
 
 where ce.order_id = link_orderid
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
   and ce.view_level        =  1
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)

detail

    lab_result = trim(ce.result_val, 3)
    
    if(uar_get_code_display(ce.result_units_cd) > '')
        lab_result = notrim(build2(lab_result, ' ', trim(uar_get_code_display(ce.result_units_cd), 3)))
    endif
    
    if(uar_get_code_display(ce.normalcy_cd) not in('NA', ''))
        lab_result = notrim(build2(lab_result, ' ', trim(uar_get_code_display(ce.normalcy_cd), 3)))
    endif

with nocounter




;Debugging here eventually.
    ;Vit D25 Hydroxy Lvl
    ;Vitamin B1, WB     
    ;Vitamin B1 Lvl     
    
    ;9.1 ng/mL LOW

;set ord_loc    = "SMH"
;set lab_name   = ""
;set lab_result = "Mayes, Michael"


;Quick to protect our rule parser
if(lab_result = "") set lab_result = '--'
endif


; Build out a datamessage for the rules
set log_misc1 = notrim(build2(     'LOC', '|', ord_loc
                             ,'|', 'LAB', '|', lab_name
                             ,'|', 'RES', '|', lab_result
                             )
                      )


;For this one we are going to always auto success... we'll catch the no data messages, and set some default.
set retval      =  100
set log_message =  "0_eks_bari_ed_os_res found Data"



/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echo(build('retval     :', retval         ))
call echo(build('log_message:', log_message    ))
call echo(build('log_misc1  :', log_misc1      ))


end
go


