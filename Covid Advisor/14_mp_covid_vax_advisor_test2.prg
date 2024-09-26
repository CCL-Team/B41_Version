drop program 14_mp_covid_vax_advisor_test2 go
create program 14_mp_covid_vax_advisor_test2

/****************************************************************************************************
                    VARIABLE DECLARATIONS
*****************************************************************************************************/
declare linecnt = i4 with noconstant(0), public
declare uline = c21 with constant("\plain \f1 \fs19 \ul")
declare num = i4
declare pos = i4
%i cust_script:14_rprq1000012.inc

call echo($2) 
if($2 = "getPatVaccine")  
    call echo("Getting Patient Encounter Info") 
    call getpatvaccine($3) 
elseif($2 = "writeVaccine") 
    call echo("Calling Subroutine for Sync Event") 
    call writevaccine($3) 
elseif($2 = "SearchPrsnl") 
    call echo("In search logic") 
    call searchprsnl($3) 
endif




;---------------------------------------------------------------------------------------------------------------------------------
; subroutines / services Code
;---------------------------------------------------------------------------------------------------------------------------------
subroutine getpatvaccine(sreq)
    
;---------------------------------------------------------------------------------------------------------------------------------
;RECORD STRUCTURES
;---------------------------------------------------------------------------------------------------------------------------------

  free record reply
  record reply(
    1 reg_dt = vc
    1 person_id = f8
    1 encntr_id = f8
    1 type = vc
    1 order_id = f8
    1 order_detail = vc
    1 days_from_order = i4
    1 pass_timeframe_req = c3
    1 vax_count = i4
    1 mono_vax_count = i4
    1 moderna_monovalent_cnt = i4
    1 moderna_bivalent_cnt = i4
    1 pfizer_monovalent_cnt = i4
    1 pfizer_bivalent_cnt = i4
      
    1 pfizer_count = i4
    1 pfizer2324_count = i4
    1 moderna_count = i4
    1 moderna2324_count = i4
    1 old_vax_count = i4
    1 vax2324_count = i4
;--------------------------------------------------     
    1 pfizer_6m_4yrs = i4
    1 pfizer_5yr_11yr = i4
    1 moderna_6m_11yr = i4
    1 last_vax_age = f8
;--------------------------------------------------      
    1 weekssincelastvax = f8
    1 ageatfirstvax = f8
    1 immuno_comp_eligible = i4
    1 not_imuno_comp_eligible = i4
      
    1 not_i_c_preferred_vax_name = vc
    1 not_i_c_preferred_vax_synonym = f8
    1 not_i_c_alt_vax_name = vc
    1 not_i_c_alt_vax_synonym = f8
    1 not_i_c_pref_ind = i4
      
    1 i_c_preferred_vax_name = vc
    1 i_c_preferred_vax_synonym = f8
    1 i_c_alt_vax_name = vc
    1 i_c_alt_vax_synonym = f8
    1 i_c_pref_ind = i4
      
    1 override_vax_1 = vc
    1 override_vax_2 = vc
      
    1 bi_vax_count = i4
    1 patient_name = vc
    1 patient_age = f8
    1 patient_age_vc = vc
    1 age_year = i4
    1 items[*]
      2 order_name = vc
      2 lot_num = vc
      2 admin_provider = vc
      2 admin_date = vc
      2 days_from_order = vc
      2 type = vc
      2 pass_timeframe_req = c3
  )
    
  


  
  free record event_cd
  record event_cd(
    1 qual[*]
      2 event_cd = f8
      2 display = vc
  )
    
  free record displayqual
  record displayqual(
         
    1 line_cnt = i4
    1 display_line = vc
    1 line_qual[*]
      2 disp_line = vc
   
  )
    
    
  ; 
  ;record reply
  ;      (
  ;  1 text = vc
  ;  1 status_data
  ;    2 status = c1
  ;    2 subeventstatus[1]
  ;      3 OperationName = c25
  ;      3 OperationStatus = c1
  ;      3 TargetObjectName = c25
  ;      3 TargetObjectValue = vc
  ;)
  call echo(sreq) 
  set stat = cnvtjsontorec(sreq) 
  if(cnvtreal(request_in->person_id) > 0 and cnvtreal(request_in->encntr_id)) 
    set reply->i_c_pref_ind = 1 
    set reply->not_i_c_pref_ind = 1 
;---------------------------------------------------------------------------------------------------------------------------------
;Get Vaccine Event Codes
;---------------------------------------------------------------------------------------------------------------------------------
        
    select into "nl:" 
      cv.display 
      ,cvg.child_code_value 
      ,cvc.display 
    from code_value cv 
      ,code_value_group cvg 
      ,code_value cvc 
    plan cv 
      where cv.code_set = 100770.00 
      and cv.display_key = 'COVIDVACCINES'
            
    join cvg where cvg.parent_code_value = cv.code_value
            
    join cvc where cvc.code_value = cvg.child_code_value
    order cvc.code_value
    head report
      cnt = 0  
    head cvc.code_value
      cnt = cnt + 1  
      stat = alterlist(event_cd->qual, cnt)  
      event_cd->qual[cnt].event_cd = cvc.code_value  
      event_cd->qual[cnt].display = cvc.display  
    with nocounter
         
;---------------------------------------------------------------------------------------------------------------------------------
;Check for pending covid vax order in a Ordered status
;---------------------------------------------------------------------------------------------------------------------------------    
        
    select into "nl:" 
    from orders o 
    where o.encntr_id = request_in->encntr_id 
    and o.catalog_cd in (3810427393.00, 3810427263.00, 4753271125.00, 4753271563.00, 4753271495.00, 4753271359.00, 4753271643.00) 
    and o.order_status_cd = 2550.00
    head report
      null
    detail
      reply->order_id = o.order_id  
      reply->order_detail = o.ordered_as_mnemonic  
    with nocounter
         
;---------------------------------------------------------------------------------------------------------------------------------
;           GET VACCINES
;---------------------------------------------------------------------------------------------------------------------------------          
   
    select into "nl:" 
    from person p 
      where p.person_id = cnvtreal(request_in->person_id)
    head report
      reply->age_year = cnvtint(cnvtalphanum(cnvtage(p.birth_dt_tm), 1))  
      reply->person_id = p.person_id  
      reply->encntr_id = cnvtreal(request_in->encntr_id)  
      reply->patient_name = p.name_full_formatted  
      reply->patient_age_vc = cnvtage(p.birth_dt_tm)  
      reply->patient_age = datetimediff(sysdate, p.birth_dt_tm, 9)  
      if(reply->patient_age >= 0 and reply->patient_age < 5) 
        reply->override_vax_1 = "Pfizer 6m-4yrs"  
        reply->override_vax_2 = "Moderna 6m-11yr"  
      elseif(reply->patient_age >= 5 and reply->patient_age < 12) 
        reply->override_vax_1 = "Pfizer 5yr-11yr"  
        reply->override_vax_2 = "Moderna 6m-11yr"  
      elseif(reply->patient_age >= 12) 
        reply->override_vax_1 = "Pfizer 12yrs+"  
        reply->override_vax_2 = "Moderna 12yrs+"  
      endif         
        ;cnvtreal(cnvtalphanum(cnvtage(p.birth_dt_tm),1))
    with nocounter

;---------------------------------------------------------------------------------------------------------------------------------
; Get vaccine administration history
;---------------------------------------------------------------------------------------------------------------------------------
    select into "nl:" 
    from clinical_event c 
      ,person p 
      ,prsnl pr 
      ,ce_med_result cemr 
    plan c 
      where c.person_id = reply->person_id 
      and expand(num, 1, size(event_cd->qual, 5), c.event_cd, event_cd->qual[num].event_cd) 
      and c.result_status_cd in (25.00, 34.00, 35.00) 
      and c.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    join pr 
      where pr.person_id = c.updt_id
    join cemr 
      where cemr.event_id = outerjoin(c.event_id) 
      and cemr.valid_until_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))
    join p 
      where p.person_id = c.person_id
    order c.person_id, c.event_end_dt_tm desc
    head c.person_id
      new_cnt = 0  
      reply->pass_timeframe_req = 'no'  
      reply->days_from_order = datetimediff(sysdate, c.event_end_dt_tm)  
      reply->type = 'monovalent'  
      reply->type = 'monovalent'  
      reply->last_vax_age = datetimediff(c.event_end_dt_tm, p.birth_dt_tm, 10)  
      reply->weekssincelastvax = datetimediff(cnvtdatetime(curdate + 1, curtime3), c.event_end_dt_tm, 2)  
      if(c.event_cd in (3810427277.00, 3810427407.00, 3810426959.00, 4013729089.00, 4013727887.00)) 
        reply->type = 'bivalent'  
      endif
      
      if(reply->type = 'monovalent' and reply->days_from_order >= 60) 
        reply->pass_timeframe_req = 'yes'  
      elseif(reply->type = 'bivalent' and reply->vax_count = 1 and reply->days_from_order >= 120) 
        reply->pass_timeframe_req = 'yes'  
      elseif(reply->type = 'bivalent' and reply->vax_count >= 2 and reply->days_from_order >= 60) 
        reply->pass_timeframe_req = 'yes'  
      endif
    detail
      new_cnt = new_cnt + 1  
      stat = alterlist(reply->items, new_cnt)  
      pos = locateval(num, 1, size(event_cd->qual, 5), c.event_cd, event_cd->qual[num].event_cd)  
      reply->items[new_cnt].order_name = event_cd->qual[pos].display  
      reply->type = 'monovalent'  
; reply->age_year = cnvtint(cnvtalphanum(cnvtage(p.birth_dt_tm),1))
      if(c.event_cd in (2506235019.00, 2506234713.00, 2651124259.00, 3149587929.00, 3149721785.00, 3406799045.00, 3579715013.00, 
      3352325459.00)) 
        reply->mono_vax_count = reply->mono_vax_count + 1  
        if(c.event_cd in (2506234713.00, 3406799045.00, 3579715013.00)) 
          reply->moderna_monovalent_cnt = reply->moderna_monovalent_cnt + 1  
        elseif(c.event_cd in (2506235019.00, 3149587929.00, 3149721785.00, 3352325459.00)) 
          reply->pfizer_monovalent_cnt = reply->pfizer_monovalent_cnt + 1  
                                           
                  
        endif
      elseif(c.event_cd in (3810427277.00, 3810427407.00, 3810426959.00, 4013729089.00, 4013727887.00)) 
        reply->bi_vax_count = reply->bi_vax_count + 1  
        if(c.event_cd in (4013727887.00, 3810427277.00)) 
          reply->moderna_bivalent_cnt = reply->moderna_bivalent_cnt + 1  
        elseif(c.event_cd in (4013729089.00, 3810426959.00, 3810427407.00)) 
          reply->pfizer_bivalent_cnt = reply->pfizer_bivalent_cnt + 1  
        endif
      endif
      if(c.event_cd in (4013729089.00, 3810426959.00, 3810427407.00, 2506235019.00, 3149587929.00, 3149721785.00, 3352325459.00)) 
        reply->pfizer_count = reply->pfizer_count + 1  
        reply->old_vax_count = reply->old_vax_count + 1  
      elseif(c.event_cd in (4013727887.00, 3810427277.00, 2506234713.00, 3406799045.00, 3579715013.00, 3579715215.00)) 
        reply->moderna_count = reply->moderna_count + 1  
        reply->old_vax_count = reply->old_vax_count + 1  
      
      elseif(c.event_cd in (4753271509.00, 4753271373.00, 4753271657.00)) 
        
        ;reply->pfizer2324_count = reply->pfizer2324_count + 1  
        ;if(c.event_end_dt_tm >= cnvtdatetime(cnvtdate(08262024),0))  ;This is commented for Amy testing.
        if(c.event_end_dt_tm >= cnvtdatetime(cnvtdate(01012024),0))   ;Uncomment and remove this line when done.
          reply->vax2324_count = reply->vax2324_count + 1  
          reply->pfizer2324_count = reply->pfizer2324_count + 1
        else
          reply->old_vax_count = reply->old_vax_count + 1 
          reply->pfizer_count = reply->pfizer_count + 1
        endif
      elseif(c.event_cd in (4753271139.00, 4753271577.00)) 
        
        ;reply->moderna2324_count = reply->moderna2324_count + 1  
        ;if(c.event_end_dt_tm >= cnvtdatetime(cnvtdate(08262024),0)) ;This is commented for Amy testing.
        if(c.event_end_dt_tm >= cnvtdatetime(cnvtdate(01012024),0))  ;Uncomment and remove this line when done.
          reply->vax2324_count = reply->vax2324_count + 1  
                                                   
          reply->moderna2324_count = reply->moderna2324_count + 1  
        else
          call echo('yeah')
          reply->old_vax_count = reply->old_vax_count + 1  
          reply->moderna_count = reply->moderna_count + 1  
        endif
      endif
      if(c.event_cd = 4753271509.00) 
        reply->pfizer_6m_4yrs = reply->pfizer_6m_4yrs + 1  
      elseif(c.event_cd = 4753271373.00) 
        reply->pfizer_5yr_11yr = reply->pfizer_5yr_11yr + 1  
      elseif(c.event_cd = 4753271577.00) 
        reply->moderna_6m_11yr = reply->moderna_6m_11yr + 1  
      endif
      case(c.event_cd) 
                      
        of 2506235019.00: reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 Vaccine 30 mcg Inj IM vacc"   
                      
        of 2506234713.00: reply->items[new_cnt].order_name = "Moderna COVID-19 Vaccine 100 mcg Inj IM vacc"   
                      
        of 2651124259.00: reply->items[new_cnt].order_name = "Janssen COVID-19 Vaccine  0.5 mL Inj IM One Time"   
                      
        of 3149587929.00: reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 (5y-11y) Vaccine PF"   
                          
        of 3149721785.00: reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 Vaccine(Do Not Dilute)"  
                          
        of 3406799045.00: reply->items[new_cnt].order_name = "Moderna COVID-19 Vaccine - Booster Hx"  
                          
        of 3579715013.00: reply->items[new_cnt].order_name = "Moderna COVID-19 (6m-5y) Vaccine PF"  
                          
        of 3352325459.00: reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 (6m-4y) Vaccine PF"  
        of 3810427277.00: 
          reply->items[new_cnt].order_name = "Moderna COVID-19 Bivalent Booster Vaccine PF"  
          reply->type = 'bivalent'  
        of 3810427407.00: 
          reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 (12y+) Bivalent Booster Vaccine PF"  
          reply->type = 'bivalent'  
        of 3810426959.00: 
          reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 (5y-11y) Bivalent Booster Vaccine PF"  
          reply->type = 'bivalent'  
        of 4013729089.00: 
          reply->items[new_cnt].order_name = "Pfizer-BioNTech COVID-19 (6m-4y) Bivalent Booster Vaccine PF"  
          reply->type = 'bivalent'  
        of 4013727887.00: 
          reply->items[new_cnt].order_name = "Moderna COVID-19 (6m-5y) Bivalent Booster Vaccine PF"  
          reply->type = 'bivalent'  
        else
          reply->items[new_cnt].order_name = uar_get_code_display(c.event_cd)  
      endcase
      reply->items[new_cnt].admin_provider = pr.name_full_formatted  
      reply->items[new_cnt].lot_num = cemr.substance_lot_number  
      reply->items[new_cnt].admin_date = format(c.event_end_dt_tm, "MM/DD/YYYY;;Q")  
      reply->items[new_cnt].days_from_order = cnvtstring(datetimediff(sysdate, c.event_end_dt_tm))  
    foot report
      reply->vax_count = new_cnt  
      reply->ageatfirstvax = datetimediff(c.event_end_dt_tm, p.birth_dt_tm, 10)  
    with format, nocounter, time = 30
         
;---------------------------------------------------------------------------------------------------------------------------------
; Immunocompromise Logic
;---------------------------------------------------------------------------------------------------------------------------------  
       
        if(reply->patient_age >= 0 and reply->patient_age < 5)
          call below5Years(0)
        elseif(reply->patient_age >= 5 and reply->patient_age < 6)
          call age5To6Years(0)   
          
                                                                                                                                  
                                           
                                                  
                                                                                                        
                                      
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                           
                                                  
                                                                                                        
                                      
                                                                                                                                  
                                                                                                                                  
                                                                                                                                 
           
                                                                                                                                  
           
                                                                                                                                  
                                                                                                                                  
                                           
                                                  
                                                                                                                                  
                                                         
           
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                 
                                                             
                                                
                                                      
                                            
                                                                                                       
                                      
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                
                                                            
                                                
                                                       
                                            
                                                                                                        
                                      
                                                                                                                                
                                                            
                                                
                                                       
                                            
                                   
           
                                                                                                                                  
        elseif(reply->patient_age >= 6 and reply->patient_age < 12)
          call age6To12(0)
        elseif(reply->patient_age >= 12 and reply->patient_age < 65)
          call age12To65(0)
         
                                                                                                                                 
                                          
                                                 
                                                                                                        
                                      
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                
                                          
                                                 
                                                                                                        
                                      
                                                                                                                                  
                                                                                                                                  
                                                                                                                                   
                                          
                                                 
        elseif(reply->patient_age >= 65)
          call age65AndOlder(0)
                                                 
           
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                 
                                                             
                                                
                                                       
                                          
                                                                                                       
                                     
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                   
                                                             
                                                
                                                       
                                                
                                                                                                         
                                     
                                                                                                                                
                                                             
                                                
                                                       
                                                
                                                 
        endif
    endif        
    set _memory_reply_string = cnvtrectojson(reply, 4) 
    call echo(_memory_reply_string) 
    
                                                                                                                                 
                                          
                                                 
                                                                                                        
                                      
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                 
                                          
                                                 
                                                                                                    
                                          
                                                                                                                                  
                                                                                                                                  
                                                                                                                                
                                          
                                                 
                                                                                                  
                                       
                                                 
                                              
                
                                                                                                                                  
                                                                                                                                  
                                                                                                                                 
    call echojson(reply)
end
                                                                                                                                 
                                                                                                                                 
                                                                                                                                 
                                                           
                                                
                                                      
                                          
                                                                                                   
                                         
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  
                                                                                                                                 
                                                            
                                                
                                                     
                                          
                                                                                                       
                                      
                                                                                                                                
                                                           
                                                
                                                      
                                          
                                      
           
         
                                                                                                                                  
                            
                                                                                                                                      

;;;;;;;;;;;;;;;;;NIC
subroutine below5Years(p0);<5
;---------------------------------------------------IC----------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 2 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count >= 3 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 2 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >= 3 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  endif
;---------------------------------------------------NIC---------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 2 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 1 
           
                                                                                                                                      
  elseif(reply->pfizer_count >= 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
                                                                                                                                
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_pref_ind = 1 
           
                                                
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >= 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_alt_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 0 
           
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 6m-4yrs' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 0 
           
           
      
           
  endif
end
                               
     

subroutine age5To6Years(p0)
;---------------------------------------------------IC----------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 2 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count >= 3 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 
  and reply->moderna2324_count = 1 
      and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 2 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >= 3 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  endif
;---------------------------------------------------NIC---------------------------------------------------------------------------
  if(reply->pfizer_6m_4yrs <=2 and reply->last_vax_age < 5 and reply->pfizer_5yr_11yr =0 and reply->weekssincelastvax >= 3) 
    set reply->immuno_comp_eligible = 1 
    set reply->not_i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
    set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
    set reply->not_i_c_pref_ind = 1
  elseif(reply->pfizer_6m_4yrs <=2 and reply->last_vax_age < 5 and reply->pfizer_5yr_11yr =1 and reply->weekssincelastvax >= 8) 
    set reply->immuno_comp_eligible = 1 
    set reply->not_i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
    set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
    set reply->not_i_c_pref_ind = 1 
  elseif(reply->moderna_6m_11yr =1 and reply->last_vax_age < 5 and reply->weekssincelastvax >= 4) 
    set reply->immuno_comp_eligible = 1 
    set reply->not_i_c_preferred_vax_name = 'Moderna 6m-11yr' 
    set reply->not_i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
    set reply->not_i_c_pref_ind = 1   
  endif
end

subroutine age6To12(p0);6-12
;---------------------------------------------------IC----------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 2 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count >= 3 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
      and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 2 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >= 3 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_alt_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 5yr-11yr' 
      set reply->i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->i_c_pref_ind = 0 
  endif
;---------------------------------------------------NIC---------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 5yr-11yr ' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 0 
      
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weeksSinceLastVax >= 8)
      set reply->not_imuno_comp_eligible =1     
      set reply->not_i_c_preferred_vax_name ='Pfizer 5yr-11yr ' 
      set reply->not_i_c_alt_vax_name ='Moderna 6m-11yr'    
      set reply->i_c_pref_ind =0
      
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >=1 and reply->moderna2324_count = 0 
  and reply->weeksSinceLastVax >= 8)    
      set reply->not_imuno_comp_eligible =1     
      set reply->not_i_c_preferred_vax_name ='Pfizer 5yr-11yr ' 
      set reply->not_i_c_alt_vax_name ='Moderna 6m-11yr'    
      set reply->i_c_pref_ind =0
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 5yr-11yr ' 
      set reply->not_i_c_alt_vax_name = 'Moderna 6m-11yr' 
      set reply->not_i_c_pref_ind = 0 
  endif
end


;12 - 65
subroutine age12To65(p0)
;---------------------------------------------------IC----------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 2 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count >= 3 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 2 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >= 3 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  endif
;---------------------------------------------------NIC---------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->not_i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->not_i_c_pref_ind = 0 
  
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weeksSinceLastVax >= 8)
      set reply->not_imuno_comp_eligible =1     
      set reply->not_i_c_preferred_vax_name ='Pfizer 12yrs+'    
                                                                                              
                                                        
         
                                                                                                 
                                                      
              
                                  
                   
                       
                                                                                          
                                           
                                                                                                                   
                  
        
                                                          
                                                  
                                                          
      set reply->not_i_c_alt_vax_name ='Moderna 12yrs+' 
      set reply->i_c_pref_ind =1
           

  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >=1 and reply->moderna2324_count = 0 
  and reply->weeksSinceLastVax >= 8)
      set reply->not_imuno_comp_eligible =1     
      set reply->not_i_c_preferred_vax_name ='Moderna 12yrs+'   
      set reply->not_i_c_alt_vax_name ='Pfizer 12yrs+'  
      set reply->i_c_pref_ind =1

  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->not_i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->not_i_c_pref_ind = 0 
  endif
end  


subroutine age65AndOlder(p0) ;>=65
;---------------------------------------------------IC----------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 2 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 3) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 1 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count >= 3 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 2 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >= 3 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 1 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_alt_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 1 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 4) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 1 
  elseif(reply->pfizer_count = 2 and reply->pfizer2324_count = 0 and reply->moderna_count = 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count = 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 2 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->immuno_comp_eligible = 1 
      set reply->i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->i_c_pref_ind = 0 
  endif

;---------------------------------------------------NIC---------------------------------------------------------------------------
  if(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 0) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->not_i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->not_i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
  and reply->weekssincelastvax >= 8) 
      set reply->not_imuno_comp_eligible = 1 
      set reply->not_i_c_preferred_vax_name = 'Pfizer 12yrs+' 
      set reply->not_i_c_alt_vax_name = 'Moderna 12yrs+' 
      set reply->not_i_c_pref_ind = 0 
  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count = 0 and reply->moderna2324_count = 0 
  and reply->weeksSinceLastVax >= 8)
      set reply->not_imuno_comp_eligible =1     
      set reply->not_i_c_preferred_vax_name ='Pfizer 12yrs+'    
      set reply->not_i_c_alt_vax_name ='Moderna 12yrs+' 
      set reply->i_c_pref_ind =1
  elseif(reply->pfizer_count = 0 and reply->pfizer2324_count = 0 and reply->moderna_count >=1 and reply->moderna2324_count = 0 
  and reply->weeksSinceLastVax >= 8)      
    set reply->not_imuno_comp_eligible =1       
    set reply->not_i_c_preferred_vax_name ='Moderna 12yrs+' 
    set reply->not_i_c_alt_vax_name ='Pfizer 12yrs+'    
    set reply->i_c_pref_ind =1
;  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 1 and reply->moderna_count >= 1 and reply->moderna2324_count = 0 
;  and reply->weekssincelastvax >= 2) 
;      set reply->not_imuno_comp_eligible = 1 
;      set reply->not_i_c_preferred_vax_name = 'Pfizer 12yrs+' 
;      set reply->not_i_c_alt_vax_name = 'Moderna 12yrs+' 
;      set reply->not_i_c_pref_ind = 0 
;  elseif(reply->pfizer_count >= 1 and reply->pfizer2324_count = 0 and reply->moderna_count >= 1 and reply->moderna2324_count = 1 
;  and reply->weekssincelastvax >= 2) 
;      set reply->not_imuno_comp_eligible = 1 
;      set reply->not_i_c_preferred_vax_name = 'Pfizer 12yrs+' 
;      set reply->not_i_c_alt_vax_name = 'Moderna 12yrs+' 
;      set reply->not_i_c_pref_ind = 0 
  endif
end

subroutine write_ce(order_id, result, event_cd, eid, pid, comment)
    declare todaynowdttm = f8
    set todaynowdttm = cnvtdatetime(sysdate) 
    set dtupdt = cnvtdatetime(curdate, curtime3) 
    set record_status_cd = uar_get_code_by("DISPLAYKEY", 48, "ACTIVE") 
    set dperform = uar_get_code_by("MEANING", 21, "PERFORM") 
    set dverify = uar_get_code_by("MEANING", 21, "VERIFY") 
    set dcomplete = uar_get_code_by("MEANING", 103, "COMPLETED") 
    set dauth = uar_get_code_by("DISPLAYKEY", 8, "AUTHVERIFIED") 
    
    ;set dtupdt = cnvtdatetime(curdate, curtime3)
    ; select reqinfo->updt_id;,reqinfo->updt_task 
    ; from dummyt
    set cerequest->clin_event[1].contributor_system_cd = 469.00 
    set cerequest->clin_event[1].performed_dt_tm = dtupdt 
    set cerequest->clin_event[1].performed_dt_tm_ind = 0 
    set cerequest->clin_event[1].verified_prsnl_id = reqinfo->updt_id 
    set cerequest->clin_event[1].updt_dt_tm = dtupdt 
    set cerequest->clin_event[1].updt_dt_tm_ind = 0 
    set cerequest->clin_event[1].updt_id = reqinfo->updt_id 
    set cerequest->clin_event[1].updt_task = reqinfo->updt_task 
    set cerequest->clin_event[1].updt_task_ind = 0 
    set cerequest->clin_event[1].updt_applctx = reqinfo->updt_applctx 
    set cerequest->clin_event[1].updt_applctx_ind = 0 
    set cerequest->clin_event[1].view_level = 1 
    set cerequest->clin_event[1].view_level_ind = 0 
    set cerequest->clin_event[1].publish_flag = 1 
    set cerequest->clin_event[1].publish_flag_ind = 0 
    set cerequest->clin_event[1].person_id = pid 
    set cerequest->clin_event[1].encntr_id = eid 
    set cerequest->clin_event[1].order_id = order_id 
    set cerequest->ensure_type = 1 
    set cerequest->clin_event[1].event_cd = event_cd 
    set cerequest->clin_event[1].result_status_cd = dauth 
    set cerequest->clin_event[1].event_start_dt_tm = dtupdt 
    set cerequest->clin_event[1].event_start_dt_tm_ind = 0 
    set cerequest->clin_event[1].event_end_dt_tm = dtupdt 
    set cerequest->clin_event[1].event_end_dt_tm_ind = 0 
    set cerequest->clin_event[1].event_end_dt_tm_os_ind = 1 
    set cerequest->clin_event[1].record_status_cd = record_status_cd 
    set cerequest->clin_event[1].authentic_flag_ind = 1 
    set cerequest->clin_event[1].publish_flag = 1 
    set cerequest->clin_event[1].publish_flag_ind = 0 
    set cerequest->clin_event[1].expiration_dt_tm_ind = 1 
    set cerequest->clin_event[1].valid_until_dt_tm_ind = 1 
    set cerequest->clin_event[1].valid_from_dt_tm_ind = 1 
    set cerequest->clin_event[1].verified_dt_tm_ind = 1 
    set cerequest->clin_event[1].performed_prsnl_id = reqinfo->updt_id 
    set cerequest->clin_event[1].valid_until_dt_tm = cnvtdatetime("31-dec-2100 00:00:00") 
    
    ; event prsnl (perform and verify)
    set stat = alterlist(cerequest->clin_event[1].event_prsnl_list, 2) 
    set cerequest->clin_event.event_prsnl_list[1].person_id = reqinfo->updt_id 
    set cerequest->clin_event.event_prsnl_list[1].action_type_cd = dverify 
    set cerequest->clin_event.event_prsnl_list[1].request_dt_tm_ind = 1 
    set cerequest->clin_event.event_prsnl_list[1].action_dt_tm = dtupdt 
    set cerequest->clin_event.event_prsnl_list[1].action_prsnl_id = reqinfo->updt_id 
    set cerequest->clin_event.event_prsnl_list[1].action_status_cd = dcomplete 
    set cerequest->clin_event.event_prsnl_list[1].valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00") 
    set cerequest->clin_event.event_prsnl_list[2].person_id = reqinfo->updt_id 
    set cerequest->clin_event.event_prsnl_list[2].action_type_cd = dperform 
    set cerequest->clin_event.event_prsnl_list[2].request_dt_tm_ind = 1 
    set cerequest->clin_event.event_prsnl_list[2].action_dt_tm = dtupdt 
    set cerequest->clin_event.event_prsnl_list[2].action_prsnl_id = reqinfo->updt_id 
    set cerequest->clin_event.event_prsnl_list[2].action_status_cd = dcomplete 
    set cerequest->clin_event.event_prsnl_list[2].valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00") 
    
    ;string result
    set stat = alterlist(cerequest->clin_event[1].string_result, 1) 
    set cerequest->clin_event[1].string_result[1].string_result_text = result 
    set cerequest->clin_event[1].event_tag = result 
    set cerequest->clin_event[1].event_class_cd = uar_get_code_by("DISPLAYKEY", 53, "TXT") 
    set cerequest->clin_event[1].string_result[1].string_result_format_cd = uar_get_code_by("DISPLAYKEY", 14113, "ALPHA") 
    if(textlen(trim(comment)) > 0) 
        set cerequest->clin_event[1].subtable_bit_map = 8195 
        set stat = alterlist(cerequest->clin_event[1].event_note_list, 1) 
        set cerequest->clin_event.event_note_list[1].note_type_cd = 74.00 
        set cerequest->clin_event.event_note_list[1].note_format_cd = 114 
        set cerequest->clin_event.event_note_list[1].entry_method_cd = 42 
        set cerequest->clin_event.event_note_list[1].note_prsnl_id = reqinfo->updt_id 
        set cerequest->clin_event.event_note_list[1].note_dt_tm = todaynowdttm 
        set cerequest->clin_event.event_note_list[1].note_dt_tm_ind = 0 
        set cerequest->clin_event.event_note_list[1].record_status_cd = record_status_cd 
        set cerequest->clin_event.event_note_list[1].compression_cd = 727 
        set cerequest->clin_event.event_note_list[1].checksum = 0 
        set cerequest->clin_event.event_note_list[1].checksum_ind = 1 
        set cerequest->clin_event.event_note_list[1].non_chartable_flag = 0 
        set cerequest->clin_event.event_note_list[1].long_blob = trim(comment) 
        set cerequest->clin_event.event_note_list[1].valid_from_dt_tm_ind = 1 
        set cerequest->clin_event.event_note_list[1].valid_until_dt_tm_ind = 1 
        set cerequest->clin_event.event_note_list[1].updt_dt_tm = todaynowdttm 
        set cerequest->clin_event.event_note_list[1].updt_dt_tm_ind = 0 
        set cerequest->clin_event.event_note_list[1].updt_task = reqinfo->updt_task 
        set cerequest->clin_event.event_note_list[1].updt_task_ind = 0 
        set cerequest->clin_event.event_note_list[1].updt_id = reqinfo->updt_id 
        set cerequest->clin_event.event_note_list[1].updt_cnt_ind = 1 
        set cerequest->clin_event.event_note_list[1].updt_applctx = reqinfo->updt_applctx 
        set cerequest->clin_event.event_note_list[1].updt_applctx_ind = 0 
    else
        set stat = alterlist(cerequest->clin_event[1].event_note_list, 0) 
        set cerequest->clin_event[1].subtable_bit_map = 8193 
    endif
    set retval = 0 
    set ceservertm = curtime3 
    call echorecord(cerequest) 
    declare errmsg = vc with protect
    declare errcode = i4 with protect, noconstant(0)
    call echo("tdbexecute for 1000012") 
    set stat = tdbexecute(0, 3055000, 1000012, "REC", cerequest, "REC", cereply, 1) 
    set errcode = error(errmsg, 1) 
    if(stat != 0) 
        set retval = -(1) 
        set rep->tdb_result = concat("tdbexecute 1000012 - error code: ", build(errcode), " with error message: ", build(errmsg)) 
        set msg = concat("tdbexecute 1000012 - error code: ", build(errcode), " with error message: ", build(errmsg)) 
        call echo(msg) 
    endif
end
subroutine writevaccine(sreq)
    set stat = cnvtjsontorec(sreq) 
    call echorecord(request_in) 
    free record reply
    record reply(
        1 reply_text = vc
        1 this_curnode = vc
        1 order_id = f8
    )
    
    if(cnvtreal(request_in->person_id) > 0 
        and cnvtreal(request_in->encntr_id) > 0) 
        declare errmsg = vc with protect
        declare errcode = i4 with protect, noconstant(0)
        
        ;if(reqinfo->updt_id in(3885149.00,15750119))
        execute eks_call_synch_event "MINE", request_in->person_id, request_in->encntr_id, "0.0", "CUST_SYNC_COVID_VAX_ADVSR_V2", request_in->vax_type 
        set errcode = error(errmsg, 1) 
        if(stat != 0) 
            set retval = -(1) 
            set reply->reply_text = concat("tdbexecute 1000012 - error code: ", build(errcode), " with error message: ", build(errmsg)) 
            set msg = concat("tdbexecute 1000012 - error code: ", build(errcode), " with error message: ", build(errmsg)) 
            call echo(msg) 
        else
            declare o_catalog_parser = vc with noconstant("1=1")
            if(request_in->vax_type = "Moderna 6m-11yr") 
                set o_catalog_parser = "o.catalog_cd = 4562782473" 
            elseif(request_in->vax_type = "Moderna 12yrs Plus") 
                set o_catalog_parser = "o.catalog_cd = 4562782433" 
            endif
            
            select into "nl:" 
            from orders o 
            plan o where o.encntr_id = request_in->encntr_id 
                and o.orig_order_dt_tm between cnvtlookbehind("10,s") and cnvtlookahead("0,s") 
                and parser(o_catalog_parser) 
                and o.order_status_cd = 2550.00
            order
                o.orig_order_dt_tm desc
            head o.encntr_id
                reply->order_id = o.order_id  
            with nocounter
             
        endif
        declare result = vc
        declare rst_comment = vc
        declare thisresultdttm = vc
        set thisresultdttm = format(cnvtdatetime(curdate, curtime3), ";;Q") 
        set rst_comment = "complete via mpage" 
;write_ce(order_id, result, event_cd, eid, pid, comment)
;allergic_reaction":no,"anaphylaxis":no,"fever":no,"fact_sheet":yes}}^ 
        if(trim(request_in->allergic_reaction) = "no") 
            set result = "NO: continue to next question" 
        else
            set result = "Yes; DO NOT ADMINISTER VACCINE" 
        endif
        execute 14_mp_add_event_code "NL:", request_in->person_id, request_in->encntr_id, reqinfo->updt_id, 2712334749.0, "TXT", result, thisresultdttm, reply->order_id, rst_comment 
;call write_ce((reply->order_id,result, 2712334749,request_in->encntr_id, request_in->person_id,rst_comment)
        if(trim(request_in->anaphylaxis) = "no") 
            set result = "NO: continue to next question" 
        elseif(trim(request_in->anaphylaxis) = "yesno") 
            set result = "Yes, pt does not want to be vaccinated due to allergy risk" 
        else
            set result = build2("Yes, pt reviewed the documentation regarding risk of allergic reaction / anaphylaxis and wants ", "to continue with vaccination today") 
                                           
        endif
        execute 14_mp_add_event_code "NL:", request_in->person_id, request_in->encntr_id, reqinfo->updt_id, 2561197397.0, "TXT", result, thisresultdttm, reply->order_id, rst_comment 
                                                     
;call write_ce(reply->order_id,result, 2561197397,request_in->encntr_id, request_in->person_id,rst_comment)
   
   
        if(trim(request_in->fever) = "no") 
            set result = "NO: continue to next question" 
        else
            set result = "Yes; DO NOT ADMINISTER VACCINE; can return once fever free for at least 24hr" 
        endif
        execute 14_mp_add_event_code "NL:", request_in->person_id, request_in->encntr_id, reqinfo->updt_id, 2515700391.0, "TXT", result, thisresultdttm, reply->order_id, rst_comment 
        
        if(trim(request_in->override_ind) = "1" and cnvtreal(request_in->override_provider_id)>0 and textlen(trim(request_in->override_provider_name,3))>0) 
          call echo("Got to override")
          execute 14_mp_add_event_code "NL:", request_in->person_id, request_in->encntr_id, reqinfo->updt_id, 5331953053.0, "TXT", request_in->override_provider_name, thisresultdttm, reply->order_id, rst_comment 
        endif
        
;call write_ce(reply->order_id,result, 2515700391,request_in->encntr_id, request_in->person_id,rst_comment)
   
   
;   if(trim(request_in->fact_sheet) = "no")
;      set result = "No, DO NOT ADMINISTER VACCINE"      
;   else
;      set result = "Yes, Sign Form, CONTINUE TO VACCINATION"    
;   endif
;   call write_ce(reply->order_id,result, 2515700171,request_in->encntr_id, request_in->person_id,rst_comment)
;   
;   COVID19 Vacc Scrn mRNA allergy PEG   2712334749.00  NO: continue to next question | Yes; DO NOT ADMINISTER VACCINE
;   COVID19 Vacc Scrn Fever 38C or greater   2515700391.00 | NO: continue to next question</string-value>
;    COVID19 Vacc Fact Sheet Given   2515700171.00 | 
;    COVID19 Vacc Scrn Severe Allergy History    2561197397.00 NO: continue to next question|Yes, 
;pt does not want to be vaccinated due to allergy risk|




  
        set reply->reply_text = "Done with call" 
        set reply->this_curnode = curnode 
    endif
    set _memory_reply_string = cnvtrectojson(reply, 4) 
    call echo(_memory_reply_string) 
    
end
                            


;end of writeDTA Subrountine
;---------------------------------------------------------------------------------------------------------------------------------
; Search prsnl
;---------------------------------------------------------------------------------------------------------------------------------  
subroutine searchprsnl(sreq)
    call echo("SearchPrsnl") 
    set stat = cnvtjsontorec(sreq) 
    free record reply
    record reply(
        1 items[*]
            2 d_p_s_id = f8
            2 s_name = vc
            2 s_pos = vc
            2 s_username = vc
    )
    
    declare snamef = vc
    declare snamel = vc
    set snamef = cnvtupper(request_in->firstname) 
    set snamel = cnvtupper(request_in->lastname) 
    if(snamef = "") 
        ; first name not specified
        set snamef = "*" 
    endif
 
    call echorecord(request_in) 
    
    ; collect matching names
    
    select into "nl:" 
      
    from prsnl ps 
    plan ps where ps.name_last_key = patstring(concat(snamel, "*")) 
                                                         
        and ps.name_first_key = patstring(concat(snamef, "*")) 
        and ps.active_ind = 1 
        and ps.position_cd > 0
    order
        ps.name_last_key
        ,ps.name_first_key
 
    head report
        n = 0  
    detail
        
        n = n + 1  
         stat = alterlist(reply->items, n)  
         reply->items[n].d_p_s_id = ps.person_id  
         reply->items[n].s_name = build2(trim(ps.name_last), ", ", trim(ps.name_first))  
         reply->items[n].s_pos = trim(uar_get_code_display(ps.position_cd))  
         reply->items[n].s_username = trim(ps.username)  
    with nocounter
     
    set _memory_reply_string = cnvtrectojson(reply, 4) 
    call echo(_memory_reply_string) 
end


end go
  
 