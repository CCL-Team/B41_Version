/******************************************************************************************************************************
 Program Title:		Scheduling Request List of Oncology
 Create Date:		NA
 Object name:		kb_schq_wcomments_v3
 Source file:		kb_schq_wcomments_v3.prg
 Previous version:	File: kb_schreqs.prg
 					CCL Object: kb_schq_wcomments_v2
 Purpose: 			Displays appointments for Oncology at the selected location.
 Tables read:
 Tables updated:	N/A
 Executed from:		schapptbook -> Eye -> Request List -> Any ONC Appt Inquiry.
 Test Exec:			
 Special Notes:
 
 Mayes here: Hey... I came in here and butchered this... well actually re factored it, because reading it was hard.
 
    I don't think I've broken anything, but if I did, come talk to me because I have the older versions.
    
    And to be nice, since that might make someone mad, I'll tell you how you can run this standalone as atonement:
     
    set trace rdbbind go
    set trace rdbdebug go   
    free record request go
    record request(
        1 qual[*]
            2 oe_field_id            = f8
            2 oe_field_value         = f8
            2 oe_field_display_value = vc
            2 oe_field_dt_tm_value   = vc
            2 oe_field_meaning_id    = f8
            2 oe_field_meaning       = vc
    ) go


    set stat = alterlist(request->qual, 1) go

    set request->qual[1]->oe_field_value = 1353451.00 go
    set request->qual[1]->oe_field_meaning = 'QUEUE'  go

    kb_schq_wcomments_v2 go
    
    I think from the tool called schedule inquiry, it always runs it as a queue...
    The id is found on 
    SCH_OBJECT.
    
    Select * from SCH_OBJECT where mnemonic = 'ONC*' go
    
    The field value above is just the sch_object_id from that table.
 
 
 
********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
********************************************************************************************************************************
Mod		Date			Analyst                  	SOM/MCGA        Comment
---    	----------      --------------------    	------      	--------------------------------------------
001						CERNER										Version 1
002		Oct 27, 2022	Swetha Srinivasaraghavan	233648			Following updates were made:
																	1. Added column: Order Date
																	2. Added column: Time bw Order and Earliest Dates[Format x days y hrs z mins]
																	3. Updated column: Special Instructions, to display up to 500 characters.
																	4. THE request list displayed ALL records for the location.
																	Updated the list to display records which have the 'earliest date'
																	that go back as far as 90 days and look ahead up to a year.
003     Aug 29, 2023    Michael Mayes               231394          Adding Order Details for additional special_inst
004     2025-08-21      Michael Mayes               355047          Changing lookback for several of the sites... shortening
004     2025-08-21      Michael Mayes               355048          Changing default sorting for a few sites too...
************END OF ALL MODCONTROL BLOCKS* *****************************************************************************************/
DROP PROGRAM kb_schq_wcomments_v3 :dba GO
CREATE PROGRAM kb_schq_wcomments_v3 :dba
    if (validate (action_none          , -1) != 0)          declare action_none          = i2 with protect, noconstant(0)
    endif                                                   
    if (validate (action_add           , -1) != 1)          declare action_add           = i2 with protect, noconstant(1)
    endif                                                   
    if (validate (action_chg           , -1) != 2)          declare action_chg           = i2 with protect, noconstant(2)
    endif                                                   
    if (validate (action_del           , -1) != 3)          declare action_del           = i2 with protect, noconstant(3)
    endif                                                   
    if (validate (action_get           , -1) != 4)          declare action_get           = i2 with protect, noconstant(4)
    endif                                                   
    if (validate (action_ina           , -1) != 5)          declare action_ina           = i2 with protect, noconstant(5)
    endif                                                   
    if (validate (action_act           , -1) != 6)          declare action_act           = i2 with protect, noconstant(6)
    endif                                                   
    if (validate (action_temp          , -1) != 999)        declare action_temp          = i2 with protect, noconstant(999)
    endif                                                   
    if (validate (true                 , -1) != 1)          declare true                 = i2 with protect, noconstant(1)
    endif                                                   
    if (validate (false                , -1) != 0)          declare false                = i2 with protect, noconstant(0)
    endif                                                   
    if (validate (gen_nbr_error        , -1) != 3)          declare gen_nbr_error        = i2 with protect, noconstant(3)
    endif                                                   
    if (validate (insert_error         , -1) != 4)          declare insert_error         = i2 with protect, noconstant(4)
    endif                                                   
    if (validate (update_error         , -1) != 5)          declare update_error         = i2 with protect, noconstant(5)
    endif                                                   
    if (validate (replace_error        , -1) != 6)          declare replace_error        = i2 with protect, noconstant(6)
    endif                                                   
    if (validate (delete_error         , -1) != 7)          declare delete_error         = i2 with protect, noconstant(7)
    endif                                                   
    if (validate (undelete_error       , -1) != 8)          declare undelete_error       = i2 with protect, noconstant(8)
    endif                                                   
    if (validate (remove_error         , -1) != 9)          declare remove_error         = i2 with protect, noconstant(9)
    endif                                                   
    if (validate (attribute_error      , -1) != 10)         declare attribute_error      = i2 with protect, noconstant(10)
    endif                                                   
    if (validate (lock_error           , -1) != 11)         declare lock_error           = i2 with protect, noconstant(11)
    endif                                                   
    if (validate (none_found           , -1) != 12)         declare none_found           = i2 with protect, noconstant(12)
    endif                                                   
    if (validate (select_error         , -1) != 13)         declare select_error         = i2 with protect, noconstant(13)
    endif                                                   
    if (validate (update_cnt_error     , -1) != 14)         declare update_cnt_error     = i2 with protect, noconstant(14)
    endif                                                   
    if (validate (not_found            , -1) != 15)         declare not_found            = i2 with protect, noconstant(15)
    endif                                                   
    if (validate (version_insert_error , -1) != 16)         declare version_insert_error = i2 with protect, noconstant(16)
    endif                                                   
    if (validate (inactivate_error     , -1) != 17)         declare inactivate_error     = i2 with protect, noconstant(17)
    endif                                                   
    if (validate (activate_error       , -1) != 18)         declare activate_error       = i2 with protect, noconstant(18)
    endif                                                   
    if (validate (version_delete_error , -1) != 19)         declare version_delete_error = i2 with protect, noconstant(19)
    endif                                                   
    if (validate (uar_error            , -1) != 20)         declare uar_error            = i2 with protect, noconstant(20)
    endif                                                   
    if (validate (duplicate_error      , -1) != 21)         declare duplicate_error      = i2 with protect, noconstant(21)
    endif                                                   
    if (validate (ccl_error            , -1) != 22)         declare ccl_error            = i2 with protect, noconstant(22)
    endif                                                   
    if (validate (execute_error        , -1) != 23)         declare execute_error        = i2 with protect, noconstant(23)
    endif                                                   
    if (validate (failed               , -1) != 0)          declare failed               = i2 with protect, noconstant(false)
    endif                                                   
    if (validate (table_name           ,"zzz") = "zzz")     declare table_name = vc with protect, noconstant("")
    else                                                    declare table_name = vc with protect, noconstant(fillstring (100 ," "))
    endif                                                   
    if (validate (call_echo_ind        , -1) != 0)          declare call_echo_ind        = i2 with protect, noconstant(false)
    endif                                                   
    if (validate (i_version            , -1) != 0)          declare i_version            = i2 with protect, noconstant(0)
    endif                                                   
    if (validate (program_name         ,"zzz") = "zzz")     declare program_name = vc with protect, noconstant(fillstring (30 ," "))
    endif                                                   
    if (validate (sch_security_id      , -1) != 0)          declare sch_security_id = f8 with protect, noconstant(0.0)
    endif                                               
    if (validate (last_mod             ,"nomod") = "nomod") declare last_mod = c5 with private, noconstant ("")
    endif
 
    if ((validate (schuar_def ,999 ) = 999 ) )
        call echo ("Declaring schuar_def")
        
        declare schuar_def = i2 with persist
        set schuar_def = 1
        
        declare uar_sch_check_security ((sec_type_cd = f8 (ref ) ) 
                                       ,(parent1_id = f8 (ref ) ) 
                                       ,(parent2_id = f8 (ref ) ) 
                                       ,(parent3_id = f8 (ref ) ) 
                                       ,(sec_id = f8 (ref ) ) 
                                       ,(user_id = f8 (ref ) ) ) = i4
           with image_axp = "shrschuar" 
              , image_aix = "libshrschuar.a(libshrschuar.o)" 
              , uar       = "uar_sch_check_security" 
              , persist
  
        declare uar_sch_security_insert ((user_id = f8 (ref ) ) 
                                        ,(sec_type_cd = f8 (ref ) ) 
                                        ,(parent1_id = f8 (ref ) ) 
                                        ,(parent2_id = f8 (ref ) ) 
                                        ,(parent3_id = f8 (ref ) ) 
                                        ,(sec_id = f8 (ref ) ) ) = i4
           with image_axp = "shrschuar" 
              , image_aix = "libshrschuar.a(libshrschuar.o)" 
              , uar       = "uar_sch_security_insert" 
              , persist
  
        declare uar_sch_security_perform () = i4 
           with image_axp = "shrschuar" 
              , image_aix = "libshrschuar.a(libshrschuar.o)" 
              , uar = "uar_sch_security_perform" 
              , persist
              
        declare uar_sch_check_security_ex ((user_id = f8 (ref ) ) 
                                          ,(sec_type_cd = f8 (ref ) ) 
                                          ,(parent1_id   = f8 (ref ) ) 
                                          ,(parent2_id = f8 (ref ) ) 
                                          ,(parent3_id = f8 (ref ) ) 
                                          ,(sec_id = f8 (ref ) ) ) = i4
           with image_axp = "shrschuar" 
              , image_aix = "libshrschuar.a(libshrschuar.o)" 
              , uar       = "uar_sch_check_security_ex" 
              , persist
        
        declare uar_sch_check_security_ex2 ((user_id = f8 (ref ) ) 
                                           ,(sec_type_cd = f8 (ref ) ) 
                                           ,(parent1_id = f8 (ref ) ) 
                                           ,(parent2_id = f8 (ref ) ) 
                                           ,(parent3_id = f8 (ref ) ) 
                                           ,(sec_id = f8 (ref) ) 
                                           ,(position_cd = f8 (ref ) ) ) = i4 
          with image_axp = "shrschuar" 
             , image_aix = "libshrschuar.a(libshrschuar.o)" 
             , uar       = "uar_sch_check_security_ex2" 
             , persist
        
        declare uar_sch_security_insert_ex2 ((user_id = f8 (ref ) ) 
                                            ,(sec_type_cd = f8 (ref ) ) 
                                            ,(parent1_id = f8 (ref ) ) 
                                            ,(parent2_id = f8 (ref ) ) 
                                            ,(parent3_id = f8 (ref ) ) 
                                            ,(sec_id = f8 (ref) ) 
                                            ,(position_cd = f8 (ref ) ) ) = i4 
           with image_axp = "shrschuar" 
              , image_aix = "libshrschuar.a(libshrschuar.o)"
              , uar       = "uar_sch_security_insert_ex2" 
              , persist
    endif
 
    if ((validate (i18nuar_def ,999 ) = 999 ) )
        call echo ("Declaring i18nuar_def" )
  
        declare i18nuar_def = i2 with persist
        set i18nuar_def = 1
        
        declare uar_i18nlocalizationinit ((p1 = i4 ) ,(p2 = vc ) ,(p3 = vc ) ,(p4 = f8 ) ) = i4 with persist
        declare uar_i18ngetmessage ((p1 = i4 ) ,(p2 = vc ) ,(p3 = vc ) ) = vc with persist
        declare uar_i18nbuildmessage () = vc with persist
        declare uar_i18ngethijridate ((imonth = i2 (val ) ) 
                                     ,(iday = i2 (val ) ) 
                                     ,(iyear = i2 (val ) ) 
                                     ,(sdateformattype = vc (ref ) ) ) = c50 
           with image_axp = "shri18nuar" 
           ,image_aix     =  "libi18n_locale.a(libi18n_locale.o)" 
           ,uar           = "uar_i18nGetHijriDate" 
           ,persist
  
        declare uar_i18nbuildfullformatname ((sfirst = vc (ref ) ) 
                                            ,(slast = vc (ref ) ) 
                                            ,(smiddle = vc (    ref ) ) 
                                            ,(sdegree = vc (ref ) ) 
                                            ,(stitle = vc (ref ) ) 
                                            ,(sprefix = vc (ref ) ) 
                                            ,(ssuffix = vc (ref ) ) 
                                            ,(sinitials = vc (ref ) ) 
                                            ,(soriginal = vc (ref ) ) ) = c250 
           with image_axp =  "shri18nuar" 
              , image_aix = "libi18n_locale.a(libi18n_locale.o)" 
              , uar       = "i18nBuildFullFormatName" 
              , persist
        
        declare uar_i18ngetarabictime ((ctime = vc (ref ) ) ) = c20 
           with image_axp = "shri18nuar" 
              , image_aix = "libi18n_locale.a(libi18n_locale.o)" 
              , uar       = "i18n_GetArabicTime" 
              , persist
    endif
 
    declare i18nhandle = i4 WITH public ,noconstant (0 )
    set stat = uar_i18nlocalizationinit (i18nhandle ,curprog ,"" ,curcclrev )
 
    IF (NOT (validate (format_text_request ,0 ) ) )
        RECORD format_text_request (
            1 call_echo_ind  = i2
            1 raw_text       = vc
            1 temp_str       = vc
            1 chars_per_line = i4
        )
    ENDIF
    
    IF (NOT (validate (format_text_reply ,0 ) ) )
        RECORD format_text_reply (
            1 beg_index       = i4
            1 end_index       = i4
            1 temp_index      = i4
            1 qual_alloc      = i4
            1 qual_cnt        = i4
            1 qual [* ]
                2 text_string = vc
        )
    ENDIF
 
    SET format_text_reply->qual_cnt = 0
    SET format_text_reply->qual_alloc = 0
    
    SUBROUTINE  format_text (null_index )
        SET format_text_request->raw_text = trim (format_text_request->raw_text ,3 )
        SET text_length = textlen (format_text_request->raw_text )
        SET format_text_request->temp_str = " "
        FOR (j_text = 1 TO text_length )
            SET temp_char = substring (j_text ,1 ,format_text_request->raw_text )
            IF ((temp_char = " " ) )
                SET temp_char = "^"
            ENDIF
            SET t_number = ichar (temp_char )
            IF ((t_number != 10 )
                 AND (t_number != 13 ) )
                SET format_text_request->temp_str = concat (format_text_request->temp_str ,temp_char )
            ENDIF
            IF ((t_number = 13 ) )
                SET format_text_request->temp_str = concat (format_text_request->temp_str ,"^" )
            ENDIF
        ENDFOR
        SET format_text_request->temp_str = replace (format_text_request->temp_str ,"^" ," " ,0 )
        SET format_text_request->raw_text = format_text_request->temp_str
        SET format_text_reply->beg_index = 0
        SET format_text_reply->end_index = 0
        SET format_text_reply->qual_cnt = 0
        SET text_len = textlen (format_text_request->raw_text )
        IF ((text_len > format_text_request->chars_per_line ) )
            WHILE ((text_len > format_text_request->chars_per_line ) )
                SET wrap_ind = 0
                SET format_text_reply->beg_index = 1
                WHILE ((wrap_ind = 0 ) )
                    SET format_text_reply->end_index = findstring (" " , format_text_request->raw_text 
                                                                       , format_text_reply->beg_index )
                    IF ((format_text_reply->end_index = 0 ) )
                        SET format_text_reply->end_index = (format_text_request->chars_per_line + 10 )
                    ENDIF
                    IF ((format_text_reply->beg_index = 1 )
                         AND (format_text_reply->end_index > format_text_request->chars_per_line ) )
                        SET format_text_reply->qual_cnt +=1
                        IF ((format_text_reply->qual_cnt > format_text_reply->qual_alloc ) )
                            SET format_text_reply->qual_alloc +=10
                            SET stat = alterlist (format_text_reply->qual ,format_text_reply->qual_alloc )
                        ENDIF
                        SET format_text_reply->qual[format_text_reply->qual_cnt ].text_string = substring (1 ,
                                            format_text_request->chars_per_line ,format_text_request->raw_text )
                        SET format_text_request->raw_text = substring ((format_text_request->chars_per_line + 1 ) ,(
                                            text_len - format_text_request->chars_per_line ) ,format_text_request->raw_text )
                        SET wrap_ind = 1
                    ELSEIF ((format_text_reply->end_index > format_text_request->chars_per_line ) )
                        SET format_text_reply->qual_cnt +=1
                        IF ((format_text_reply->qual_cnt > format_text_reply->qual_alloc ) )
                           SET format_text_reply->qual_alloc +=10
                           SET stat = alterlist (format_text_reply->qual ,format_text_reply->qual_alloc )
                        ENDIF
                        SET format_text_reply->qual[format_text_reply->qual_cnt ].text_string = substring (1 ,(
                                                        format_text_reply->beg_index - 1 ) ,format_text_request->raw_text )
                        SET format_text_request->raw_text = substring (format_text_reply->beg_index ,((text_len -
                                                    format_text_reply->beg_index ) + 1 ) ,format_text_request->raw_text )
                        SET wrap_ind = 1
                    ENDIF
                    SET format_text_reply->beg_index = (format_text_reply->end_index + 1 )
                ENDWHILE
                SET text_len = textlen (format_text_request->raw_text )
            ENDWHILE
            SET format_text_reply->qual_cnt +=1
            IF ((format_text_reply->qual_cnt > format_text_reply->qual_alloc ) )
                SET format_text_reply->qual_alloc +=10
                SET stat = alterlist (format_text_reply->qual ,format_text_reply->qual_alloc )
            ENDIF
            SET format_text_reply->qual[format_text_reply->qual_cnt ].text_string = format_text_request->raw_text
        ELSE
            SET format_text_reply->qual_cnt +=1
            IF ((format_text_reply->qual_cnt > format_text_reply->qual_alloc ) )
                SET format_text_reply->qual_alloc +=10
                SET stat = alterlist (format_text_reply->qual ,format_text_reply->qual_alloc )
            ENDIF
            SET format_text_reply->qual[format_text_reply->qual_cnt ].text_string = format_text_request->raw_text
        ENDIF
    END ;Subroutine
 
    SUBROUTINE  inc_format_text (null_index )
        SET format_text_reply->qual_cnt +=1
        IF ((format_text_reply->qual_cnt > format_text_reply->qual_alloc ) )
            SET format_text_reply->qual_alloc +=10
            SET stat = alterlist (format_text_reply->qual ,format_text_reply->qual_alloc )
        ENDIF
    END ;Subroutine
 
    IF (NOT (validate (get_atgroup_exp_request ,0 ) ) )
        RECORD get_atgroup_exp_request (
            1 security_ind = i2
            1 call_echo_ind = i2
            1 qual [* ]
                2 sch_object_id = f8
                2 duplicate_ind = i2
        )
    ENDIF
    
    IF (NOT (validate (get_atgroup_exp_reply ,0 ) ) )
        RECORD get_atgroup_exp_reply (
            1 qual_cnt = i4
            1 qual [* ]
                2 sch_object_id = f8
                2 qual_cnt = i4
                2 qual [* ]
                    3 appt_type_cd = f8
        )
    ENDIF
    
    IF (NOT (validate (get_locgroup_exp_request ,0 ) ) )
        RECORD get_locgroup_exp_request (
        1 security_ind = i2
        1 call_echo_ind = i2
        1 qual [* ]
            2 sch_object_id = f8
            2 duplicate_ind = i2
        )
    ENDIF
    
    IF (NOT (validate (get_locgroup_exp_reply ,0 ) ) )
        RECORD get_locgroup_exp_reply (
            1 qual_cnt = i4
            1 qual [* ]
                2 sch_object_id = f8
                2 qual_cnt = i4
                2 qual [* ]
                    3 location_cd = f8
        )
    ENDIF
    
    IF (NOT (validate (get_res_group_exp_request ,0 ) ) )
        RECORD get_res_group_exp_request (
            1 security_ind = i2
            1 call_echo_ind = i2
            1 qual [* ]
                2 res_group_id = f8
                2 duplicate_ind = i2
        )
    ENDIF
    
    IF (NOT (validate (get_res_group_exp_reply ,0 ) ) )
        RECORD get_res_group_exp_reply (
            1 qual_cnt = i4
            1 qual [* ]
                2 res_group_id = f8
                2 qual_cnt = i4
                2 qual [* ]
                    3 resource_cd = f8
                    3 mnemonic = vc
                    3 description = vc
                    3 quota = i4
                    3 person_id = f8
                    3 id_disp = vc
                    3 res_type_flag = i2
                    3 active_ind = i2
        )
    ENDIF
    
    IF (NOT (validate (get_slot_group_exp_request ,0 ) ) )
        RECORD get_slot_group_exp_request (
            1 security_ind = i2
            1 call_echo_ind = i2
            1 qual [* ]
                2 slot_group_id = f8
                2 duplicate_ind = i2
        )
    ENDIF
    
    IF (NOT (validate (get_slot_group_exp_reply ,0 ) ) )
        RECORD get_slot_group_exp_reply (
            1 qual_cnt = i4
            1 qual [* ]
                2 slot_group_id = f8
                2 qual_cnt = i4
                2 qual [* ]
                    3 slot_type_id = f8
        )
    ENDIF
    
    DECLARE s_cdf_meaning = c12 WITH public ,noconstant (fillstring (12 ," " ) )
    DECLARE s_code_value = f8 WITH public ,noconstant (0.0 )

    SUBROUTINE  (loadcodevalue (code_set =i4 ,cdf_meaning =vc ,option_flag =i2 ) =f8 )
        SET s_cdf_meaning = cdf_meaning
        SET s_code_value = 0.0
        SET stat = uar_get_meaning_by_codeset (code_set ,s_cdf_meaning ,1 ,s_code_value )
 
        IF ((((stat != 0 ) ) OR ((s_code_value <= 0 ) )) )
            SET s_code_value = 0.0
            CASE (option_flag )
            OF 0 :
                SET table_name = build ("ERROR-->loadcodevalue (" ,code_set ,"," ,'"' ,s_cdf_meaning ,'"' ,"," ,
                                        option_flag ,") not found, CURPROG [" ,curprog ,"]" )
                CALL echo (table_name )
                SET failed = uar_error
                GO TO exit_script
            OF 1 :
                CALL echo (build ("INFO-->loadcodevalue (" ,code_set ,"," ,'"' ,s_cdf_meaning ,'"' ,"," ,
                           option_flag ,") not found, CURPROG [" ,curprog ,"]" ) )
            ENDCASE
        ELSE
            CALL echo (build ("SUCCESS-->loadcodevalue (" ,code_set ,"," ,'"' ,s_cdf_meaning ,'"' ,"," ,
                        option_flag ,") CODE_VALUE [" ,s_code_value ,"]" ) )
        ENDIF
        RETURN (s_code_value )
    END ;Subroutine

    RECORD reply (
        1 attr_qual_cnt              = i4
        1 attr_qual [* ]
            2 attr_name              = c31
            2 attr_label             = c60
            2 attr_type              = c8
            2 attr_def_seq           = i4
            2 attr_alt_sort_column   = vc
        1 query_qual_cnt             = i4
        1 query_qual [* ]
            2 hide#schentryid        = f8
            2 hide#scheventid        = f8
            2 hide#scheduleid        = f8
            2 hide#scheduleseq       = i4
            2 hide#reqactionid       = f8
            2 hide#actionid          = f8
            2 hide#schapptid         = f8
            2 hide#statemeaning      = vc
            2 hide#earliestdttm      = dq8
            2 hide#latestdttm        = dq8
            2 hide#reqmadedttm       = dq8
            2 hide#entrystatemeaning = c12
            2 hide#reqactionmeaning  = c12
            2 hide#encounterid       = f8
            2 hide#personid          = f8
            2 hide#bitmask           = i4
            2 hide#orderid           = f8
            2 isolation_type         = vc
            2 stat                   = vc
            2 inpatient              = vc
            2 cmt                    = vc
            2 time                   = vc
            2 earliest_dt_tm         = dq8
            2 scheduled_dt_tm        = dq8
            2 days_of_week           = vc
            2 req_action_display     = vc
            2 appt_type_display      = vc
            2 person_name            = vc
            2 sch_action_id          = f8
            2 sch_event_id           = f8
            2 orders                 = vc
            2 ord_date               = dq8 ;00xss
            2 time_diff_ord_earliest = vc  ;00xss
            2 order_cmt              = vc
            2 special_inst           = vc
            2 add_special_inst       = vc  ;003
            2 order_doc              = vc
            2 pp_activity_id         = f8
            2 pp_activity            = vc
            2 pp_phase_activity      = vc
            2 pp_reference           = vc
            2 pp_phase_reference     = vc
            2 pp_scheduled_phase_id  = f8
            2 pp_scheduled_phase     = vc
            2 isolation_display      = vc
        1 status_data
            2 status                 = c1
            2 subeventstatus [1 ]
                3 operationname      = c25
                3 operationstatus    = c1
                3 targetobjectname   = c25
                3 targetobjectvalue  = vc
    ) WITH persistscript

    DECLARE cs23010_disppidrl_cd = f8 WITH public ,constant (loadcodevalue (23010 ,"DISPPIDRL" ,1 ) )
    DECLARE pref_value_disppidrl = f8 WITH public ,noconstant (0.0 )

    IF ((cs23010_disppidrl_cd > 0.0 ) )
        SELECT INTO "nl:"
               a.pref_id
          FROM (sch_pref a )
          PLAN (a
         WHERE (a.pref_type_cd = cs23010_disppidrl_cd )
           AND (a.parent_table = "SYSTEM" )
           AND (a.parent_id = 0 )
           AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
         DETAIL
             pref_value_disppidrl = a.pref_value
         WITH nocounter
         ;end select
    ENDIF

    SET reply->attr_qual_cnt = 35

    DECLARE max_length_orders = i4 WITH public ,noconstant (0 )
    DECLARE max_length_pp_activity = i4 WITH public ,noconstant (0 )
    DECLARE max_length_pp_phase_activity = i4 WITH public ,noconstant (0 )
    DECLARE max_length_pp_reference = i4 WITH public ,noconstant (0 )
    DECLARE max_length_pp_phase_reference = i4 WITH public ,noconstant (0 )
    DECLARE max_length_pp_scheduled_phase = i4 WITH public ,noconstant (0 )
    DECLARE iso_field_meaning_id = f8 WITH protect ,constant (12 )

    IF ((pref_value_disppidrl > 0.0 ) )
        SET reply->attr_qual_cnt +=5
    ENDIF

    SET t_index = 0
    SET stat = alterlist (reply->attr_qual ,reply->attr_qual_cnt )
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#schentryid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#SCHENTRYID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#scheventid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#SCHEVENTID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#scheduleid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#SCHEDULEID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#scheduleseq"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#SCHEDULESEQ"
    SET reply->attr_qual[t_index ].attr_type = "i4"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#reqactionid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#REQACTIONID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#actionid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#ACTIONID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#schapptid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#SCHAPPTID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#statemeaning"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#STATEMEANING"
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#earliestdttm"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#EARLIESTDTTM"
    SET reply->attr_qual[t_index ].attr_type = "dq8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#latestdttm"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#LATESTDTTM"
    SET reply->attr_qual[t_index ].attr_type = "dq8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#reqmadedttm"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#REQMADEDTTM"
    SET reply->attr_qual[t_index ].attr_type = "dq8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#entrystatemeaning"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#ENTRYSTATEMEANING"
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#reqactionmeaning"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#REQACTIONMEANING"
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#encounterid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#ENCOUNTERID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#personid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#PERSONID"
    SET reply->attr_qual[t_index ].attr_type = "f8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#bitmask"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#BITMASK"
    SET reply->attr_qual[t_index ].attr_type = "i4"
    
    ;003->
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "hide#orderid"
    SET reply->attr_qual[t_index ].attr_label = "HIDE#ORDERID"
    SET reply->attr_qual[t_index ].attr_type = "i4"
    ;003
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "cmt"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"C" ,"C" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "order_cmt"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"OC" ,"OC" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "isolation_type"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Iso" ,"Iso" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "stat"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Stat" ,"Stat" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "inpatient"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Inp" ,"Inp" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "req_action_display"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Action" ,"Action" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "person_name"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Person Name" , "Person Name" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "appt_type_display"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Appointment Type" , "Appointment Type" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "earliest_dt_tm"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Earliest Date" , "Earliest Date" )
    SET reply->attr_qual[t_index ].attr_type = "dq8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "time"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Time" ,"Time" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "orders"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Orders" ,"Orders" )
    SET reply->attr_qual[t_index ].attr_type = "vc"

    ;; 002 begins
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "ord_date"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Order Date" ,"Order Date" )
    SET reply->attr_qual[t_index ].attr_type = "dq8"

    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "time_diff_ord_earliest"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle
                                                                , "Time bw Order & Earliest Dates"
                                                                , "Time bw Order & Earliest Dates" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    ;; 002 ends

    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "special_inst"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Special Instructions" ,
    "Special Instructions" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    ;003->

    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "add_special_inst"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Additional Special Instructions" ,
    "Additional Special Instructions" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    ;003<-
   
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "order_doc"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Ordering Provider","Ordering Provider")
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "scheduled_dt_tm"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Scheduled Date" , "Scheduled Date" )
    SET reply->attr_qual[t_index ].attr_type = "dq8"
    
    SET t_index +=1
    SET reply->attr_qual[t_index ].attr_name = "isolation_display"
    SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"Isolation Display" , "Isolation Display" )
    SET reply->attr_qual[t_index ].attr_type = "vc"
    
    IF ((pref_value_disppidrl > 0.0 ) )
         SET t_index +=1
         SET reply->attr_qual[t_index ].attr_name = "pp_activity"
         SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"PowerPlan Activity" , "PowerPlan Activity" )
         SET reply->attr_qual[t_index ].attr_type = "vc"
         
         SET t_index +=1
         SET reply->attr_qual[t_index ].attr_name = "pp_Phase_activity"
         SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle , "PowerPlan Phase Activity" 
                                                                                    ,"PowerPlan Phase Activity" )
         SET reply->attr_qual[t_index ].attr_type = "vc"
         
         SET t_index +=1
         SET reply->attr_qual[t_index ].attr_name = "pp_reference"
         SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle ,"PowerPlan Reference" 
                                                                                    , "PowerPlan Referencee" )
         SET reply->attr_qual[t_index ].attr_type = "vc"
         
         SET t_index +=1
         SET reply->attr_qual[t_index ].attr_name = "pp_phase_reference"
         SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle , "PowerPlan Phase Reference" 
                                                                                    ,"PowerPlan Phase Reference" )
         SET reply->attr_qual[t_index ].attr_type = "vc"
         
         SET t_index +=1
         SET reply->attr_qual[t_index ].attr_name = "pp_scheduled_phase"
         SET reply->attr_qual[t_index ].attr_label = uar_i18ngetmessage (i18nhandle , "PowerPlan Scheduled Phase" 
                                                                                    ,"PowerPlan Scheduled Phase" )
         SET reply->attr_qual[t_index ].attr_type = "vc"
    ENDIF
    
    SET reply->query_qual_cnt = 0
    SET stat = alterlist (reply->query_qual ,reply->query_qual_cnt )

    FREE SET t_record
    RECORD t_record (
        1 queue_id                    = f8
        1 person_id                   = f8
        1 resource_cd                 = f8
        1 location_cd                 = f8
        1 beg_dt_tm                   = dq8
        1 end_dt_tm                   = dq8
        1 atgroup_id                  = f8
        1 locgroup_id                 = f8
        1 res_group_id                = f8
        1 slot_group_id               = f8
        1 appt_type_cd                = f8
        1 title                       = vc
        1 appttype_qual_cnt           = i4
        1 appttype_qual [* ]
          2 appt_type_cd              = f8
        1 location_qual_cnt           = i4
        1 location_qual [* ]
          2 location_cd               = f8
        1 resource_qual_cnt           = i4
        1 resource_qual [* ]
          2 resource_cd               = f8
            2 person_id               = f8
        1 slot_qual_cnt               = i4
        1 slot_qual [* ]
            2 slot_type_id            = f8
        1 user_defined                = vc
        1 order_type_cd               = f8
        1 order_type_meaning          = c12
        1 pending_state_cd            = f8
        1 pending_state_meaning       = c12
        1 isobeg_type_cd              = f8
        1 isobeg_type_meaning         = c12
        1 isoend_type_cd              = f8
        1 isoend_type_meaning         = c12
        1 isolation_type_cd           = f8
        1 isolation_type_meaning      = c12
        1 userdefined_type_cd         = f8
        1 userdefined_type_meaning    = c12
        1 temp_beg_dt_tm              = dq8
        1 temp_end_dt_tm              = dq8
        1 temp_isolation_cd           = f8
        1 ordcomment_cd               = f8
        1 ordcomment_meaning          = c12
        1 order_action_cd             = f8
        1 order_action_meaning        = c12
        1 modify_action_cd            = f8
        1 modify_action_meaning       = c12
        1 collection_action_cd        = f8
        1 collection_action_meaning   = c12
        1 renew_action_cd             = f8
        1 renew_action_meaning        = c12
        1 activate_action_cd          = f8
        1 activate_action_meaning     = c12
        1 futuredc_action_cd          = f8
        1 futuredc_action_meaning     = c12
        1 resume_renew_action_cd      = f8
        1 resume_renew_action_meaning = c12
        1 max_order_cnt               = i4
        1 event_qual [* ]
            2 protocol_parent_id      = f8
            2 order_qual_cnt          = i4
            2 order_qual [* ]
                3 order_id            = f8
                3 description         = vc
                3 order_seq_nbr       = i4
    )
    
    CALL echo ("Checking the input fields..." )
    FOR (i_input = 1 TO size (request->qual ,5 ) )
        IF ((request->qual[i_input ].oe_field_meaning_id = 0 ) )
            CASE (request->qual[i_input ].oe_field_meaning )
            OF "QUEUE"     : SET t_record->queue_id      = request->qual[i_input ].oe_field_value
            OF "PERSON"    : SET t_record->person_id     = request->qual[i_input ].oe_field_value
            OF "RESOURCE"  : SET t_record->resource_cd   = request->qual[i_input ].oe_field_value
            OF "LOCATION"  : SET t_record->location_cd   = request->qual[i_input ].oe_field_value
            OF "BEGDTTM"   : SET t_record->beg_dt_tm     = request->qual[i_input ].oe_field_dt_tm_value
            OF "ENDDTTM"   : SET t_record->end_dt_tm     = request->qual[i_input ].oe_field_dt_tm_value
            OF "ATGROUP"   : SET t_record->atgroup_id    = request->qual[i_input ].oe_field_value
            OF "LOCGROUP"  : SET t_record->locgroup_id   = request->qual[i_input ].oe_field_value
            OF "RESGROUP"  : SET t_record->res_group_id  = request->qual[i_input ].oe_field_value
            OF "SLOTGROUP" : SET t_record->slot_group_id = request->qual[i_input ].oe_field_value
            OF "TITLE"     : SET t_record->title         = request->qual[i_input ].oe_field_display_value
            OF "APPTTYPE"  : SET t_record->appt_type_cd  = request->qual[i_input ].oe_field_value
            ENDCASE
        ELSE
            CASE (request->qual[i_input ].label_text )
                OF "<Label Text Goes Here>" : SET t_record->user_defined = request->qual[i_input ].oe_field_display_value
            ENDCASE
        ENDIF
    ENDFOR

    IF ((t_record->atgroup_id > 0 ) )
        SET get_atgroup_exp_request->call_echo_ind = 0
        SET get_atgroup_exp_request->security_ind = 1
        SET get_atgroup_exp_reply->qual_cnt = 1
        SET stat = alterlist (get_atgroup_exp_request->qual ,get_atgroup_exp_reply->qual_cnt )
        SET get_atgroup_exp_request->qual[get_atgroup_exp_reply->qual_cnt ].sch_object_id = t_record->atgroup_id
        SET get_atgroup_exp_request->qual[get_atgroup_exp_reply->qual_cnt ].duplicate_ind = 1
     
        EXECUTE sch_get_atgroup_exp
        FOR (i_input = 1 TO get_atgroup_exp_reply->qual_cnt )
            SET t_record->appttype_qual_cnt = get_atgroup_exp_reply->qual[i_input ].qual_cnt
            SET stat = alterlist (t_record->appttype_qual ,t_record->appttype_qual_cnt )
            FOR (j_input = 1 TO t_record->appttype_qual_cnt )
                SET t_record->appttype_qual[j_input ].appt_type_cd = 
                                      get_atgroup_exp_reply->qual[i_input ].qual[j_input ].appt_type_cd
            ENDFOR
        ENDFOR
    ELSE
        SET t_record->appttype_qual_cnt = 0
    ENDIF

    IF ((t_record->locgroup_id > 0 ) )
        SET get_locgroup_exp_request->call_echo_ind = 0
        SET get_locgroup_exp_request->security_ind = 1
        SET get_locgroup_exp_reply->qual_cnt = 1
        SET stat = alterlist (get_locgroup_exp_request->qual ,get_locgroup_exp_reply->qual_cnt )
        SET get_locgroup_exp_request->qual[get_locgroup_exp_reply->qual_cnt ].sch_object_id = t_record->locgroup_id
        SET get_locgroup_exp_request->qual[get_locgroup_exp_reply->qual_cnt ].duplicate_ind = 1
 
        EXECUTE sch_get_locgroup_exp
        
        FOR (i_input = 1 TO get_locgroup_exp_reply->qual_cnt )
            SET t_record->location_qual_cnt = get_locgroup_exp_reply->qual[i_input ].qual_cnt
            SET stat = alterlist (t_record->location_qual ,t_record->location_qual_cnt )
            
            FOR (j_input = 1 TO t_record->location_qual_cnt )
                SET t_record->location_qual[j_input ].location_cd = 
                                    get_locgroup_exp_reply->qual[i_input ].qual[j_input ].location_cd
            ENDFOR
        ENDFOR
    ELSE
        SET t_record->location_qual_cnt = 0
    ENDIF

    IF ((t_record->res_group_id > 0 ) )
        SET get_res_group_exp_request->call_echo_ind = 0
        SET get_res_group_exp_request->security_ind = 1
        SET get_res_group_exp_reply->qual_cnt = 1
        SET stat = alterlist (get_res_group_exp_request->qual ,get_res_group_exp_reply->qual_cnt )
        SET get_res_group_exp_request->qual[get_res_group_exp_reply->qual_cnt ].res_group_id = t_record->res_group_id
        SET get_res_group_exp_request->qual[get_res_group_exp_reply->qual_cnt ].duplicate_ind = 1
        
        EXECUTE sch_get_res_group_exp
 
        FOR (i_input = 1 TO get_res_group_exp_reply->qual_cnt )
            SET t_record->resource_qual_cnt = get_res_group_exp_reply->qual[i_input ].qual_cnt
            SET stat = alterlist (t_record->resource_qual ,t_record->resource_qual_cnt )
  
            FOR (j_input = 1 TO t_record->resource_qual_cnt )
                SET t_record->resource_qual[j_input ].resource_cd = 
                                                    get_res_group_exp_reply->qual[i_input ].qual[j_input ].resource_cd
            ENDFOR
        ENDFOR
    ELSE
        SET t_record->resource_qual_cnt = 0
    ENDIF
    
    IF ((t_record->slot_group_id > 0 ) )
        SET get_slot_group_exp_request->call_echo_ind = 0
        SET get_slot_group_exp_request->security_ind = 1
        SET get_slot_group_exp_reply->qual_cnt = 1
        SET stat = alterlist (get_slot_group_exp_request->qual ,get_slot_group_exp_reply->qual_cnt )
        SET get_slot_group_exp_request->qual[get_slot_group_exp_reply->qual_cnt ].slot_group_id = t_record->slot_group_id
        SET get_slot_group_exp_request->qual[get_slot_group_exp_reply->qual_cnt ].duplicate_ind = 1
 
        EXECUTE sch_get_slot_group_exp
 
        FOR (i_input = 1 TO get_slot_group_exp_reply->qual_cnt )
            SET t_record->slot_qual_cnt = get_slot_group_exp_reply->qual[i_input ].qual_cnt
            SET stat = alterlist (t_record->slot_qual ,t_record->slot_qual_cnt )
            FOR (j_input = 1 TO t_record->slot_qual_cnt )
                SET t_record->slot_qual[j_input ].slot_type_id =
                                            get_slot_group_exp_reply->qual[i_input ].qual[j_input ].slot_type_id
            ENDFOR
        ENDFOR
    ELSE
        SET t_record->slot_qual_cnt = 0
    ENDIF

    IF ((t_record->resource_qual_cnt > 0 ) )
        SELECT INTO "nl:"
               a.person_id ,
               d.seq
          FROM (dummyt d WITH seq = value (t_record->resource_qual_cnt ) ),
               (sch_resource a )
          PLAN (d )
          JOIN (a
         WHERE (a.resource_cd = t_record->resource_qual[d.seq ].resource_cd )
           AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
        DETAIL
            t_record->resource_qual[d.seq ].person_id = a.person_id
        WITH nocounter
        ;end select
    ENDIF

    SET t_record->pending_state_cd = 0.0
    SET t_record->pending_state_meaning = fillstring (12 ," " )
    SET t_record->pending_state_meaning = "PENDING"
    SET stat = uar_get_meaning_by_codeset (23018 ,t_record->pending_state_meaning ,1 ,t_record->pending_state_cd )
    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(23018," ,t_record->pending_state_meaning ,",1," ,t_record->pending_state_cd ,")"))

    IF ((((stat != 0 ) ) OR ((t_record->pending_state_cd <= 0 ) )) )
        IF (call_echo_ind )
            CALL echo (build ("stat = " ,stat ) )
            CALL echo (build ("t_record->pending_state_cd = " ,t_record->pending_state_cd ) )
            CALL echo (build ("Invalid select on CODE_SET (23018), CDF_MEANING(" ,t_record->pending_state_meaning ,")" ) )
        ENDIF
        GO TO exit_script
    ENDIF

    SELECT INTO "nl:"
            ad_null = nullind (ad.sch_action_id ) ,
            l_null = nullind (l.sch_lock_id ) ,
            a.queue_id
      FROM (sch_entry a ),
           (sch_event_action ea ),
           (sch_event e ),
           (person p ),
           (encounter enc ),
           (sch_lock l ),
           (sch_action_date ad )
      PLAN (a
       WHERE (a.queue_id = t_record->queue_id )
         AND (a.entry_state_cd = t_record->pending_state_cd )
         AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) )  
         ;004-> Okay... here, we want this to be a 30 Day lookback for the following places.  The rest... unchanged.
         
         
         ; SCH_OBJECT_ID  VERSION_DT_TM MNEMONIC
         ; 1349469.00      12/31/00 ONC GUH PEDS Infusion Center
         ; 1349475.00      12/31/00 ONC STM Infusion Center
         ; 1353451.00      12/31/00 ONC FSH Infusion Center
         ; 1353453.00      12/31/00 ONC FSCCLR Infusion Center
         ; 1351453.00      12/31/00 ONC Belair Infusion Center
             
         
         ; 2901493.00      12/31/00 Brandywine Infusion Center
         ; 1353455.00      12/31/00 ONC SMHC Infusion Center
         ; 1349473.00      12/31/00 ONC MMC Infusion Center
         ; 1349471.00      12/31/00 ONC GUH BMT Infusion Center
         ; 1349465.00      12/31/00 ONC WHC Infusion Center
         ; 1351455.00      12/31/00 ONC GUH Research Infusion Center
         ; 1349467.00      12/31/00 ONC GUH Infusion Center
         ; 2897495.00      12/31/00 Lorton Infusion Center
         
         ;and a.earliest_dt_tm between cnvtlookbehind("90, D") and cnvtlookahead("1, Y")) ;002
         and (   (    a.queue_id     in (  2901493.00  ; Brandywine Infusion Center
                                        ,  1353455.00  ; ONC SMHC Infusion Center
                                        ,  1349473.00  ; ONC MMC Infusion Center
                                        ,  1349471.00  ; ONC GUH BMT Infusion Center
                                        ,  1349465.00  ; ONC WHC Infusion Center
                                        ,  1351455.00  ; ONC GUH Research Infusion Center
                                        ,  1349467.00  ; ONC GUH Infusion Center
                                        ,  2897495.00  ; Lorton Infusion Center
                                        )
                  and a.earliest_dt_tm between cnvtlookbehind("30, D") and cnvtlookahead("1, Y")
                 )
              or (    a.queue_id not in (  2901493.00  ; Brandywine Infusion Center
                                        ,  1353455.00  ; ONC SMHC Infusion Center
                                        ,  1349473.00  ; ONC MMC Infusion Center
                                        ,  1349471.00  ; ONC GUH BMT Infusion Center
                                        ,  1349465.00  ; ONC WHC Infusion Center
                                        ,  1351455.00  ; ONC GUH Research Infusion Center
                                        ,  1349467.00  ; ONC GUH Infusion Center
                                        ,  2897495.00  ; Lorton Infusion Center
                                        )
                  and a.earliest_dt_tm between cnvtlookbehind("90, D") and cnvtlookahead("1, Y")
                 )
             )
           )
      JOIN (ea
       WHERE (ea.sch_action_id = a.sch_action_id )
         AND (ea.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
      JOIN (e
       WHERE (e.sch_event_id = ea.sch_event_id )
         AND (e.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
      JOIN (p
       WHERE (p.person_id = a.person_id ) )
      JOIN (enc
       WHERE (enc.encntr_id = a.encntr_id ) )
      JOIN (l
       WHERE (l.parent_table = Outerjoin("SCH_EVENT" ))
         AND (l.parent_id = Outerjoin(a.sch_event_id ))
         AND (l.release_dt_tm > Outerjoin(cnvtdatetime (sysdate ) ))
         AND (l.version_dt_tm = Outerjoin(cnvtdatetime ("31-DEC-2100 00:00:00.00" ) )) )
      JOIN (ad
       WHERE (ad.sch_action_id = Outerjoin(a.sch_action_id ))
        AND (ad.scenario_nbr = Outerjoin(1 ))
        AND (ad.seq_nbr = Outerjoin(1 ))
        AND (ad.version_dt_tm = Outerjoin(cnvtdatetime ("31-DEC-2100 00:00:00.00" ) )) )
    ORDER BY a.sch_action_id
    HEAD REPORT
        reply->query_qual_cnt = 0
    HEAD a.sch_action_id
        IF ((((l_null = 1 ) ) 
            OR ((l.status_flag = 3 )
            AND (l.granted_prsnl_id = reqinfo->updt_id ) )) )
            
            reply->query_qual_cnt +=1 ,
   
            IF ((mod (reply->query_qual_cnt ,100 ) = 1 ) ) 
                stat = alterlist (reply->query_qual ,(reply->query_qual_cnt + 99 ) ) ,
                stat = alterlist (t_record->event_qual ,(reply->query_qual_cnt + 99 ))
            ENDIF,
            
            reply->query_qual[reply->query_qual_cnt ].hide#schentryid = a.sch_entry_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#scheventid = a.sch_event_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#scheduleid = a.schedule_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#scheduleseq = e.schedule_seq ,
            reply->query_qual[reply->query_qual_cnt ].hide#reqactionid = a.sch_action_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#actionid = ea.req_action_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#schapptid = a.sch_appt_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#statemeaning = e.sch_meaning ,
            reply->query_qual[reply->query_qual_cnt ].hide#earliestdttm = cnvtdatetime (a.earliest_dt_tm ) ,
            reply->query_qual[reply->query_qual_cnt ].hide#latestdttm = cnvtdatetime (a.latest_dt_tm ) ,
            reply->query_qual[reply->query_qual_cnt ].hide#reqmadedttm = cnvtdatetime (a.request_made_dt_tm ) ,
            reply->query_qual[reply->query_qual_cnt ].hide#entrystatemeaning = a.entry_state_meaning ,
            reply->query_qual[reply->query_qual_cnt ].hide#reqactionmeaning = a.req_action_meaning ,
            reply->query_qual[reply->query_qual_cnt ].hide#encounterid = a.encntr_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#personid = a.person_id ,
            reply->query_qual[reply->query_qual_cnt ].hide#bitmask = 0 ,
   
            IF ((a.earliest_dt_tm > cnvtdatetime ("01-JAN-1800 00:00:00.00" ) ) ) 
                reply->query_qual[reply->query_qual_cnt ].earliest_dt_tm = cnvtdatetime (a.earliest_dt_tm )
            ELSE reply->query_qual[reply->query_qual_cnt ].earliest_dt_tm = 0
            ENDIF,
   
            IF (NOT ((format (a.earliest_dt_tm ,"HHMM;;DATE" ) IN ("0000" ,"0001" ) ) ) ) 
                reply->query_qual[reply->query_qual_cnt ].time = format (a.earliest_dt_tm ,"HH:MM;;DATE" )
            ELSE reply->query_qual[reply->query_qual_cnt ].time = ""
            ENDIF,
            
            IF ((ad_null = 0 ) )
                IF ((ad.time_restr_cd > 0 ) ) 
                    reply->query_qual[reply->query_qual_cnt ].time = uar_get_code_display (ad.time_restr_cd )
                ENDIF,
                FOR (i = 1 TO 7 )
                    IF ((substring (i ,1 ,ad.days_of_week ) = "X" ) ) 
                        reply->query_qual[reply->query_qual_cnt ].days_of_week = 
                            build (reply->query_qual[reply->query_qual_cnt ].days_of_week ,
                                        evaluate (i 
                                                 ,1 ,"Sun," 
                                                 ,2 ,"Mon," 
                                                 ,3 ,"Tue," 
                                                 ,4 ,"Wed," 
                                                 ,5 ,"Thu," 
                                                 ,6 ,"Fri," 
                                                 ,7 ,"Sat," ) )
                    ENDIF
                ENDFOR,
                
                IF ((reply->query_qual[reply->query_qual_cnt ].days_of_week > " " ) )
                    reply->query_qual[reply->query_qual_cnt ].days_of_week = 
                                substring (1 ,(size (reply->query_qual[reply->query_qual_cnt ].days_of_week ) - 1 ) ,
                                                reply->query_qual[reply->query_qual_cnt ].days_of_week )
                ENDIF
                ELSE reply->query_qual[reply->query_qual_cnt ].days_of_week = ""
            ENDIF,
            
            reply->query_qual[reply->query_qual_cnt ].req_action_display = uar_get_code_display (a.req_action_cd ) ,
            reply->query_qual[reply->query_qual_cnt ].appt_type_display = uar_get_code_display (e.appt_synonym_cd ) ,
            
            IF ((a.person_id > 0 ) ) 
                reply->query_qual[reply->query_qual_cnt ].person_name = p.name_full_formatted
            ELSE reply->query_qual[reply->query_qual_cnt ].person_name = ""
            ENDIF,
            
            IF ((e.protocol_type_flag = 1 ) ) 
                t_record->event_qual[reply->query_qual_cnt ].protocol_parent_id = e.sch_event_id
            ENDIF,
   
            IF ((uar_get_code_display (enc.encntr_type_cd ) IN ("Inpatient" ,"After Hours Inpatient" ) ) ) 
                reply->query_qual[reply->query_qual_cnt ].inpatient = "Yes"
            ENDIF
        ENDIF

    FOOT REPORT
        IF ((mod (reply->query_qual_cnt ,100 ) != 0 ) )
            stat = alterlist (reply->query_qual ,reply->query_qual_cnt ) ,
            stat = alterlist (t_record->event_qual ,reply->query_qual_cnt )
        ENDIF,
        
        t_record->max_order_cnt = 0
    WITH nocounter
    ;end select

    IF ((reply->query_qual_cnt <= 0 ) )
        GO TO exit_script
    ENDIF

    SELECT INTO "nl:"
        t_sort = evaluate (a.role_meaning ,"PATIENT" ,2 ,a.primary_role_ind ) ,
        a.updt_cnt
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (sch_appt a )
 
      PLAN (d
       WHERE (reply->query_qual[d.seq ].hide#scheventid > 0 )
         AND (reply->query_qual[d.seq ].hide#scheduleid > 0 ) )
      JOIN (a
       WHERE (a.sch_event_id = reply->query_qual[d.seq ].hide#scheventid )
         AND (a.schedule_id = reply->query_qual[d.seq ].hide#scheduleid )
         AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
    ORDER BY d.seq , t_sort
    DETAIL
        reply->query_qual[d.seq ].hide#bitmask = a.bit_mask ,
        reply->query_qual[d.seq ].scheduled_dt_tm = cnvtdatetime (a.beg_dt_tm )
    WITH nocounter
    ;end select

    SELECT INTO "nl:"
        a.updt_cnt
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (sch_event_comm a )
      PLAN (d )
      JOIN (a
       WHERE (a.sch_event_id = reply->query_qual[d.seq ].hide#scheventid )
         AND (a.sch_action_id = reply->query_qual[d.seq ].hide#reqactionid )
         AND (a.text_type_meaning = "ACTION" )
         AND (a.sub_text_meaning = "ACTION" )
         AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
    DETAIL
        reply->query_qual[d.seq ].cmt = "Y"
    WITH nocounter
    ;end select

    SELECT INTO "nl:"
        a.updt_cnt
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (sch_event_comm a )
      PLAN (d )
      JOIN (a
       WHERE (a.sch_event_id = reply->query_qual[d.seq ].hide#scheventid )
         AND (a.sch_action_id = reply->query_qual[d.seq ].hide#actionid )
         AND (a.text_type_meaning = "ACTION" )
         AND (a.sub_text_meaning = "ACTION" )
         AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
    DETAIL
        reply->query_qual[d.seq ].cmt = "Y"
    WITH nocounter
    ;end select

    SET t_record->order_type_cd = 0.0
    SET t_record->order_type_meaning = fillstring (12 ," " )
    SET t_record->order_type_meaning = "ORDER"
    SET stat = uar_get_meaning_by_codeset (16110 ,t_record->order_type_meaning ,1 ,t_record->order_type_cd )
    
    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(16110," ,t_record->order_type_meaning ,",1," ,t_record->order_type_cd ,")" ) )

    IF ((((stat != 0 ) ) OR ((t_record->order_type_cd <= 0 ) )) )
        IF (call_echo_ind )
            CALL echo (build ("stat = " ,stat ) )
            CALL echo (build ("t_record->order_type_cd = " ,t_record->order_type_cd ) )
            CALL echo (build ("Invalid select on CODE_SET (16110), CDF_MEANING(" ,t_record->order_type_meaning,")" ) )
        ENDIF
        GO TO exit_script
    ENDIF

    SELECT INTO "nl:"
        d.seq
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (sch_event e ),
           (sch_event_attach a )
      PLAN (d
       WHERE (t_record->event_qual[d.seq ].protocol_parent_id > 0 ) )
      JOIN (e
       WHERE (e.protocol_parent_id = t_record->event_qual[d.seq ].protocol_parent_id )
         AND NOT ((e.sch_meaning IN ("CANCELED" ,"NOSHOW" ) ) )
         AND (e.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ) )
      JOIN (a
       WHERE (a.sch_event_id = e.sch_event_id )
         AND (a.attach_type_cd = t_record->order_type_cd )
         AND (a.beg_schedule_seq <= reply->query_qual[d.seq ].hide#scheduleseq )
         AND (a.end_schedule_seq >= reply->query_qual[d.seq ].hide#scheduleseq )
         AND NOT ((a.order_status_meaning IN ("CANCELED" ,"COMPLETED" ,"DISCONTINUED" ) ) )
         AND (a.state_meaning != "REMOVED" )
         AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) )
         AND (a.active_ind = 1 ) )
    ORDER BY d.seq ,
             e.protocol_seq_nbr ,
             a.order_seq_nbr
    HEAD d.seq
        t_record->event_qual[d.seq ].order_qual_cnt = 0
    DETAIL
        t_record->event_qual[d.seq ].order_qual_cnt +=1 ,
        
        IF ((mod (t_record->event_qual[d.seq ].order_qual_cnt ,10 ) = 1 ) ) stat = alterlist (t_record->
            event_qual[d.seq ].order_qual ,(t_record->event_qual[d.seq ].order_qual_cnt + 9 ) )
        ENDIF,
        
        t_record->event_qual[d.seq ].order_qual[t_record->event_qual[d.seq ].order_qual_cnt ].order_id =a.order_id ,
        t_record->event_qual[d.seq ].order_qual[t_record->event_qual[d.seq ].order_qual_cnt ].description = a.description ,
        t_record->event_qual[d.seq ].order_qual[t_record->event_qual[d.seq ].order_qual_cnt ].order_seq_nbr = a.order_seq_nbr
 
    FOOT  d.seq
        IF ((mod (t_record->event_qual[d.seq ].order_qual_cnt ,10 ) != 0 ) ) 
            stat = alterlist (t_record->event_qual[d.seq ].order_qual ,t_record->event_qual[d.seq ].order_qual_cnt )
        ENDIF,
        
        IF ((t_record->event_qual[d.seq ].order_qual_cnt > t_record->max_order_cnt ) ) 
            t_record->max_order_cnt = t_record->event_qual[d.seq ].order_qual_cnt
        ENDIF
    WITH nocounter
    ;end select
    
    SELECT INTO "nl:"
            d.seq
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (sch_event_attach a )
      PLAN (d
       WHERE (t_record->event_qual[d.seq ].protocol_parent_id <= 0 ) )
      JOIN (a
       WHERE (a.sch_event_id = reply->query_qual[d.seq ].hide#scheventid )
         AND (a.attach_type_cd = t_record->order_type_cd )
         AND (a.beg_schedule_seq <= reply->query_qual[d.seq ].hide#scheduleseq )
         AND (a.end_schedule_seq >= reply->query_qual[d.seq ].hide#scheduleseq )
         AND NOT ((a.order_status_meaning IN ("CANCELED" , "COMPLETED" , "DISCONTINUED" ) ) )
         AND (a.state_meaning != "REMOVED" )
         AND (a.version_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) )
         AND (a.active_ind = 1 ) )
    ORDER BY d.seq ,
             a.order_seq_nbr
    HEAD d.seq
        t_record->event_qual[d.seq ].order_qual_cnt = 0
    DETAIL
        t_record->event_qual[d.seq ].order_qual_cnt +=1 ,
  
        IF ((mod (t_record->event_qual[d.seq ].order_qual_cnt ,10 ) = 1 ) ) stat = alterlist (t_record->
            event_qual[d.seq ].order_qual ,(t_record->event_qual[d.seq ].order_qual_cnt + 9 ) )
        ENDIF,
        
        t_record->event_qual[d.seq ].order_qual[t_record->event_qual[d.seq ].order_qual_cnt ].order_id = a.order_id ,
        t_record->event_qual[d.seq ].order_qual[t_record->event_qual[d.seq ].order_qual_cnt ].description = a.description ,
        t_record->event_qual[d.seq ].order_qual[t_record->event_qual[d.seq ].order_qual_cnt ].order_seq_nbr = a.order_seq_nbr ,
  
        CALL echo (build ("PROTOCOL_PARENT_ID[" ,t_record->event_qual[d.seq ].protocol_parent_id 
                         ,"] SCH_EVENT_ID [" ,a.sch_event_id 
                         ,"] ORDER_ID [" ,a.order_id ,"]" ) )
    FOOT  d.seq
  
        IF ((mod (t_record->event_qual[d.seq ].order_qual_cnt ,10 ) != 0 ) ) 
            stat = alterlist (t_record->event_qual[d.seq ].order_qual ,t_record->event_qual[d.seq ].order_qual_cnt )
        ENDIF,
  
        IF ((t_record->event_qual[d.seq ].order_qual_cnt > t_record->max_order_cnt ) ) 
            t_record->max_order_cnt = t_record->event_qual[d.seq ].order_qual_cnt
        ENDIF
    WITH nocounter
    ;end select

    SET t_record->order_action_meaning = "ORDER"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->order_action_meaning ,1 ,t_record->order_action_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->order_action_meaning ,",1," 
                                                                                ,t_record->order_action_cd ,")" ) )

    SET t_record->modify_action_meaning = "MODIFY"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->modify_action_meaning ,1 ,t_record->modify_action_cd )
    
    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->modify_action_meaning ,",1," 
                                                                                ,t_record->modify_action_cd ,")" ) )

    SET t_record->collection_action_meaning = "COLLECTION"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->collection_action_meaning ,1 ,t_record->collection_action_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->collection_action_meaning ,",1,"
                                                                                ,t_record->collection_action_cd ,")" ) )

    SET t_record->renew_action_meaning = "RENEW"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->renew_action_meaning ,1 ,t_record->renew_action_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->renew_action_meaning ,",1," ,
      t_record->renew_action_cd ,")" ) )

    SET t_record->activate_action_meaning = "ACTIVATE"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->activate_action_meaning ,1 ,t_record->activate_action_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->activate_action_meaning ,",1," 
                                                                                ,t_record->activate_action_cd ,")" ) )

    SET t_record->futuredc_action_meaning = "FUTUREDC"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->futuredc_action_meaning ,1 ,t_record->futuredc_action_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->futuredc_action_meaning ,",1," 
                                                                                ,t_record->futuredc_action_cd ,")" ) )

    SET t_record->resume_renew_action_meaning = "RESUME/RENEW"
    SET stat = uar_get_meaning_by_codeset (6003 ,t_record->resume_renew_action_meaning ,1 ,t_record->resume_renew_action_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(6003," ,t_record->resume_renew_action_meaning ,",1," 
                                                                                ,t_record->resume_renew_action_cd ,")" ) )

    IF ((t_record->max_order_cnt > 0 ) )
        SET act_seq = 0
        SELECT INTO "nl:"
            t_order_seq_nbr = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_seq_nbr ,
            od_exists = decode (od.seq ,1 ,0 )
          FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
               (dummyt d2 WITH seq = value (t_record->max_order_cnt ) ),
               (orders o ),
               (order_action oa ),
               (dummyt d3 ),
               (order_detail od )
          PLAN (d )
          JOIN (d2
           WHERE (d2.seq <= t_record->event_qual[d.seq ].order_qual_cnt ) )
          JOIN (o
           WHERE (o.order_id = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_id ) )
          JOIN (oa
           WHERE (oa.order_id = o.order_id )
             AND (     ((oa.action_type_cd = t_record->order_action_cd ) ) 
                  OR ((((oa.action_type_cd = t_record->modify_action_cd ) ) 
                  OR ((((oa.action_type_cd = t_record->activate_action_cd ) ) 
                  OR ((((oa.action_type_cd = t_record->futuredc_action_cd ) ) 
                  OR ((((oa.action_type_cd = t_record->renew_action_cd ) )
                  OR ((((oa.action_type_cd = t_record->resume_renew_action_cd ) ) 
                  OR ((oa.action_type_cd = t_record->collection_action_cd ) )) )) )) )) )) ))
             AND (oa.action_rejected_ind = 0 ) )
          JOIN (d3
           WHERE (d3.seq = 1 ) )
          JOIN (od
           WHERE (od.order_id = oa.order_id )
             AND (od.action_sequence = oa.action_sequence )
             AND (od.oe_field_meaning_id IN (127 ,3519 , 3520 , 3521 ,3522 ,3523 ,12 ) ) )
        ORDER BY d.seq ,
                 d2.seq ,
                 o.order_id ,
                 od.oe_field_id ,
                 od.action_sequence DESC
        HEAD d.seq
            t_index = 0
        HEAD d2.seq
            t_index = 0
        HEAD o.order_id
            IF ((reply->query_qual[d.seq ].orders <= " " ) ) 
                reply->query_qual[d.seq ].orders = t_record->event_qual[d.seq ].order_qual[d2.seq ].description
                reply->query_qual[d.seq ].hide#orderid = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_id ;003
                reply->query_qual[d.seq].ord_date = cnvtdatetime(o.orig_order_dt_tm) ;002
                reply->query_qual[d.seq].time_diff_ord_earliest = format(datetimediff(reply->query_qual[d.seq].earliest_dt_tm
    															, reply->query_qual[d.seq].ord_date)
    															, "DD days HH hrs MM mins;;Z")
            ENDIF,
        
            IF ((pref_value_disppidrl = 1.0 )
            AND (size (reply->query_qual[d.seq ].orders ,1 ) > max_length_orders ) ) max_length_orders =
                size (reply->query_qual[d.seq ].orders ,1 )
            ENDIF,
        
            IF ((o.orig_ord_as_flag = 4 ) ) reply->query_qual[d.seq ].inpatient = "Yes"
            ENDIF
        HEAD od.oe_field_id
            act_seq = od.action_sequence ,flag = 1
        HEAD od.action_sequence
            IF ((act_seq != od.action_sequence ) ) flag = 0
            ENDIF
        DETAIL
            IF ((flag = 1 )
                AND (od_exists = 1 ) )
            
                IF ((od.oe_field_meaning_id = 127 )
                    AND (uar_get_code_meaning (od.oe_field_value ) = "STAT" ) ) 
                    
                    reply->query_qual[d.seq ].stat = "Yes"
            
                ELSEIF ((od.oe_field_meaning_id = iso_field_meaning_id ) )
                reply->query_qual[d.seq ].isolation_display = od.oe_field_display_value
                ENDIF,
            
                IF ((pref_value_disppidrl > 0.0 ) )
                    IF ((od.oe_field_meaning_id = 3519 ) ) 
                        reply->query_qual[d.seq ].pp_activity_id = od.oe_field_value ,
                        reply->query_qual[d.seq ].pp_activity = od.oe_field_display_value
                    ENDIF,
                
                    IF ((od.oe_field_meaning_id = 3520 ) )
                        reply->query_qual[d.seq ].pp_phase_activity = od.oe_field_display_value
                    ENDIF,
                
                    IF ((od.oe_field_meaning_id = 3521 ) ) 
                        reply->query_qual[d.seq ].pp_reference = od.oe_field_display_value
                    ENDIF,
                    IF ((od.oe_field_meaning_id = 3522 ) ) 
                        reply->query_qual[d.seq ].pp_phase_reference = od.oe_field_display_value
                    ENDIF,
                
                    IF ((od.oe_field_meaning_id = 3523 ) ) 
                        reply->query_qual[d.seq ].pp_scheduled_phase_id = od.oe_field_value ,
                        reply->query_qual[d.seq ].pp_scheduled_phase = od.oe_field_display_value
                    ENDIF,
                
                    IF ((pref_value_disppidrl = 1.0 ) )
                        IF ((size (reply->query_qual[d.seq ].pp_activity ,1 ) > max_length_pp_activity ) )
                            max_length_pp_activity = size (reply->query_qual[d.seq ].pp_activity ,1 )
                        ENDIF,
                    
                        IF ((size (reply->query_qual[d.seq ].pp_phase_activity ,1 ) > max_length_pp_phase_activity )) 
                            max_length_pp_phase_activity = size (reply->query_qual[d.seq ].pp_phase_activity ,1 )
                        ENDIF,
                    
                        IF ((size (reply->query_qual[d.seq ].pp_reference ,1 ) > max_length_pp_reference ) )
                            max_length_pp_reference = size (reply->query_qual[d.seq ].pp_reference ,1 )
                        ENDIF
                    
                        IF ((size (reply->query_qual[d.seq ].pp_phase_reference ,1 ) > max_length_pp_phase_reference) ) 
                            max_length_pp_phase_reference = size (reply->query_qual[d.seq ].pp_phase_reference ,1 )
                        ENDIF,
                    
                        IF ((size (reply->query_qual[d.seq ].pp_scheduled_phase ,1 ) > max_length_pp_scheduled_phase) ) 
                            max_length_pp_scheduled_phase = size (reply->query_qual[d.seq ].pp_scheduled_phase ,1 )
                        ENDIF
                    ENDIF
                ENDIF
            ENDIF
        WITH nocounter ,outerjoin = d3 ,dontcare = od
        ;end select
     
        SET t_record->ordcomment_cd = 0.0
        SET t_record->ordcomment_meaning = fillstring (12 ," " )
        SET t_record->ordcomment_meaning = "ORD COMMENT"
        SET stat = uar_get_meaning_by_codeset (14 ,t_record->ordcomment_meaning ,1 ,t_record->ordcomment_cd)
 
        CALL echo (build ("UAR_GET_MEANING_BY_CODESET(14," ,t_record->ordcomment_meaning ,",1," ,t_record->ordcomment_cd ,")" ) )
     
        IF ((((stat != 0 ) ) OR ((t_record->ordcomment_cd <= 0 ) )) )
            IF (call_echo_ind )
                CALL echo (build ("stat = " ,stat ) )
                CALL echo (build ("t_record->ordcomment_cd = " ,t_record->ordcomment_cd ) )
                CALL echo (build ("Invalid select on CODE_SET (14), CDF_MEANING(" ,t_record->ordcomment_meaning ,")" ) )
            ENDIF
            GO TO exit_script
        ENDIF
 
        SELECT INTO "nl:"
                    oc.order_id ,
                    oc.action_sequence ,
                    oc.comment_type_cd
          FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
               (dummyt d2 WITH seq = value (t_record->max_order_cnt ) ),
               (order_comment oc )
          PLAN (d
           WHERE (t_record->event_qual[d.seq ].order_qual_cnt > 0 ) )
          JOIN (d2
           WHERE (d2.seq <= t_record->event_qual[d.seq ].order_qual_cnt ) )
          JOIN (oc
           WHERE (oc.order_id = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_id )
             AND (oc.comment_type_cd = t_record->ordcomment_cd ) )
        HEAD d.seq
            reply->query_qual[d.seq ].order_cmt = "Yes"
        WITH nocounter
        ;end select

    ENDIF

    SELECT INTO "nl:"
        oc.order_id ,
        oc.action_sequence ,
        oc.comment_type_cd
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (dummyt d2 WITH seq = value (t_record->max_order_cnt ) ),
           (order_detail od )
      PLAN (d
       WHERE (t_record->event_qual[d.seq ].order_qual_cnt > 0 ) )
      JOIN (d2
       WHERE (d2.seq <= t_record->event_qual[d.seq ].order_qual_cnt ) )
      JOIN (od
       WHERE (od.order_id = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_id )
         AND (od.oe_field_id = 258409528.00 )
         AND (od.action_sequence = (SELECT max (action_sequence )
                                      FROM (order_detail x )
                                     WHERE (x.order_id = od.order_id )
                                       AND (x.oe_field_id = od.oe_field_id ) 
                                   ) 
              ) 
            )
    HEAD d.seq
        reply->query_qual[d.seq ].special_inst = od.oe_field_display_value
    WITH nocounter
    ;end select
    
    ;003->
    declare temp_addl_spec = vc with protect, noconstant('')
    
    SELECT INTO "nl:"
        oc.order_id ,
        oc.action_sequence ,
        oc.comment_type_cd
      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (dummyt d2 WITH seq = value (t_record->max_order_cnt ) ),
           (order_detail od )
      PLAN (d
       WHERE (t_record->event_qual[d.seq ].order_qual_cnt > 0 ) )
      JOIN (d2
       WHERE (d2.seq <= t_record->event_qual[d.seq ].order_qual_cnt ) )
      JOIN (od
       WHERE (od.order_id = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_id )
         AND (od.oe_field_id = 4534419959.00 )  ;TODO might need prod translate.
         AND (od.action_sequence = (SELECT max (action_sequence )
                                      FROM (order_detail x )
                                     WHERE (x.order_id = od.order_id )
                                       AND (x.oe_field_id = od.oe_field_id ) 
                                   ) 
              ) 
            )
    head d.seq
        temp_addl_spec = ''
    
    detail
        call echo( trim(od.oe_field_display_value, 3))
        if(temp_addl_spec = '')
            temp_addl_spec = trim(od.oe_field_display_value, 3)
        else
            temp_addl_spec = build2(temp_addl_spec, '; ', trim(od.oe_field_display_value, 3))
        endif
    
    foot d.seq
        reply->query_qual[d.seq ].add_special_inst = temp_addl_spec
        call echo(temp_addl_spec)
        call echo(d.seq)
    WITH nocounter
    ;end select
    
    ;003<-
    
    
 
    SELECT INTO "nl:"
            oc.order_id

      FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
           (dummyt d2 WITH seq = value (t_record->max_order_cnt ) ),
           (order_action oa ),
           (prsnl p)
 
      PLAN (d
       WHERE (t_record->event_qual[d.seq ].order_qual_cnt > 0 ) )
      JOIN (d2
       WHERE (d2.seq <= t_record->event_qual[d.seq ].order_qual_cnt ) )
      JOIN (oa
       WHERE (oa.order_id = t_record->event_qual[d.seq ].order_qual[d2.seq ].order_id )
         AND (oa.order_provider_id > 0))
      join (p
       where (p.person_id = oa.order_provider_id))
    order by oa.action_sequence desc
    HEAD d.seq
        reply->query_qual[d.seq ].order_doc = p.name_full_formatted
    WITH nocounter,maxqual(oa,1)
    ;end select

    SET t_record->isobeg_type_cd = 0.0
    SET t_record->isobeg_type_meaning = fillstring (12 ," " )
    SET t_record->isobeg_type_meaning = "ISOBEG"
    SET stat = uar_get_meaning_by_codeset (356 ,t_record->isobeg_type_meaning ,1 ,t_record->isobeg_type_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(356," ,t_record->isobeg_type_meaning ,",1," ,t_record->isobeg_type_cd ,")" ) )

    IF ((((stat != 0 ) ) OR ((t_record->isobeg_type_cd <= 0 ) )) )
        SET t_record->isobeg_type_cd = 0
    ENDIF
    
    SET t_record->isoend_type_cd = 0.0
    SET t_record->isoend_type_meaning = fillstring (12 ," " )
    SET t_record->isoend_type_meaning = "ISOEND"
    SET stat = uar_get_meaning_by_codeset (356 ,t_record->isoend_type_meaning ,1 ,t_record->isoend_type_cd )
    
    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(356," ,t_record->isoend_type_meaning ,",1," ,t_record->isoend_type_cd ,")" ) )

    IF ((((stat != 0 ) ) OR ((t_record->isoend_type_cd <= 0 ) )) )
        SET t_record->isoend_type_cd = 0
    ENDIF

    SET t_record->isolation_type_cd = 0.0
    SET t_record->isolation_type_meaning = fillstring (12 ," " )
    SET t_record->isolation_type_meaning = "ISOLATION"
    SET stat = uar_get_meaning_by_codeset (356 ,t_record->isolation_type_meaning ,1 ,t_record->isolation_type_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(356," ,t_record->isolation_type_meaning ,",1," ,t_record->isolation_type_cd ,")"))
    
    IF ((((stat != 0 ) ) OR ((t_record->isolation_type_cd <= 0 ) )) )
        SET t_record->isolation_type_cd = 0
    ENDIF
    
    SET t_record->userdefined_type_cd = 0.0
    SET t_record->userdefined_type_meaning = fillstring (12 ," " )
    SET t_record->userdefined_type_meaning = "USERDEFINED"
    SET stat = uar_get_meaning_by_codeset (355 ,t_record->userdefined_type_meaning ,1 ,t_record->userdefined_type_cd )

    CALL echo (build ("UAR_GET_MEANING_BY_CODESET(355," ,t_record->userdefined_type_meaning ,",1," 
                                ,t_record->userdefined_type_cd ,")" ) )

    IF ((((stat != 0 ) ) OR ((t_record->userdefined_type_cd <= 0 ) )) )
        SET t_record->userdefined_type_cd = 0
    ENDIF

    IF ((t_record->isobeg_type_cd > 0 )
        AND (t_record->isoend_type_cd > 0 )
        AND (t_record->isolation_type_cd > 0 ) )
 
        SELECT INTO "nl:"
            a.updt_cnt
          FROM (dummyt d WITH seq = value (reply->query_qual_cnt ) ),
               (person_info a ),
               (code_value_extension c )
          PLAN (d
           WHERE (reply->query_qual[d.seq ].hide#personid > 0 ) )
          JOIN (a
           WHERE (a.person_id = reply->query_qual[d.seq ].hide#personid )
             AND (a.beg_effective_dt_tm <= cnvtdatetime (sysdate ) )
             AND (a.end_effective_dt_tm >= cnvtdatetime (sysdate ) )
             AND (a.info_type_cd = t_record->userdefined_type_cd )
             AND (a.info_sub_type_cd IN (t_record->isobeg_type_cd ,t_record->isoend_type_cd ,t_record->isolation_type_cd ) )
             AND (a.active_ind = 1 ) )
          JOIN (c
           WHERE (c.code_value = a.info_sub_type_cd )
             AND (c.field_name = "TYPE" )
             AND (c.code_set = 356 ) )
        HEAD d.seq
            t_record->temp_beg_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ,
            t_record->temp_end_dt_tm = cnvtdatetime ("31-DEC-2100 00:00:00.00" ) ,t_record->temp_isolation_cd = 0
        DETAIL
            IF ((a.info_sub_type_cd = t_record->isobeg_type_cd )
                AND (c.field_value = "DATE" )
                AND (cnvtdatetime (a.value_dt_tm ) > 0 ) ) 
                
                t_record->temp_beg_dt_tm = cnvtdatetime (a.value_dt_tm )
            ENDIF,
   
            IF ((a.info_sub_type_cd = t_record->isoend_type_cd )
                AND (c.field_value = "DATE" )
                AND (cnvtdatetime (a.value_dt_tm ) > 0 ) ) 
                    
                t_record->temp_end_dt_tm = cnvtdatetime (a.value_dt_tm )
            ENDIF,

            IF ((a.info_sub_type_cd = t_record->isolation_type_cd )
                 AND (c.field_value = "CODE" ) ) 
                
                t_record->temp_isolation_cd = a.value_cd
            ENDIF
  
        FOOT  d.seq
            IF ((t_record->temp_isolation_cd > 0 )
                 AND (reply->query_qual[d.seq ].hide#earliestdttm >= t_record->temp_beg_dt_tm )
                 AND (reply->query_qual[d.seq ].hide#earliestdttm <= t_record->temp_end_dt_tm ) ) 
                
                reply->query_qual[d.seq ].isolation_type = "Yes"
            ENDIF
        WITH nocounter ,orahint ("INDEX(A XIE1PERSON_INFO) INDEX(C XPKCODE_VALUE_EXTENSION)" )
        ;end select
    ENDIF

    IF ((pref_value_disppidrl = 1.0 ) )
    
        ;005-> A few sites want alternate sorting... 
             ; SCH_OBJECT_ID  VERSION_DT_TM MNEMONIC
             ; 1349469.00      12/31/00 ONC GUH PEDS Infusion Center
             ; 1353451.00      12/31/00 ONC FSH Infusion Center
             ; 1353453.00      12/31/00 ONC FSCCLR Infusion Center
             ; 1351453.00      12/31/00 ONC Belair Infusion Center
             ; 1353455.00      12/31/00 ONC SMHC Infusion Center
             ; 1349473.00      12/31/00 ONC MMC Infusion Center
             ; 1349471.00      12/31/00 ONC GUH BMT Infusion Center
             ; 1351455.00      12/31/00 ONC GUH Research Infusion Center
             ; 1349467.00      12/31/00 ONC GUH Infusion Center
             
             ; 2901493.00      12/31/00 Brandywine Infusion Center
             ; 1349465.00      12/31/00 ONC WHC Infusion Center
             ; 2897495.00      12/31/00 Lorton Infusion Center
             ; 1349475.00      12/31/00 ONC STM Infusion Center
             
        ;Being dumb about it and just duping the whole query.  Hate me for it later.
        
        if(t_record->queue_id in ( 2901493.00  ; Brandywine Infusion Center
                                 , 1349465.00  ; ONC WHC Infusion Center
                                 , 2897495.00  ; Lorton Infusion Center
                                 , 1349475.00  ; ONC STM Infusion Center
                                 )
          )
          
            SELECT INTO "nl:"
                 val_hide_schentryid        = reply->query_qual[d.seq ].hide#schentryid ,
                 val_hide_scheventid        = reply->query_qual[d.seq ].hide#scheventid ,
                 val_hide_scheduleid        = reply->query_qual[d.seq ].hide#scheduleid ,
                 val_hide_scheduleseq       = reply->query_qual[d.seq ].hide#scheduleseq ,
                 val_hide_reqactionid       = reply->query_qual[d.seq ].hide#reqactionid ,
                 val_hide_schapptid         = reply->query_qual[d.seq ].hide#schapptid ,
                 val_hide_statemeaning      = substring (1 ,12 ,reply->query_qual[d.seq ].hide#statemeaning ) ,
                 val_hide_earliestdttm      = reply->query_qual[d.seq ].hide#earliestdttm ,
                 val_hide_latestdttm        = reply->query_qual[d.seq ].hide#latestdttm ,
                 val_hide_reqmadedttm       = reply->query_qual[d.seq ].hide#reqmadedttm ,
                 val_hide_entrystatemeaning = substring (1 ,12 ,reply->query_qual[d.seq ].hide#entrystatemeaning ) ,
                 val_hide_reqactionmeaning = substring (1 ,12 ,reply->query_qual[d.seq ].hide#reqactionmeaning ) ,
                 val_hide_encounterid       = reply->query_qual[d.seq ].hide#encounterid ,
                 val_hide_personid          = reply->query_qual[d.seq ].hide#personid ,
                 val_hide_bitmask           = reply->query_qual[d.seq ].hide#bitmask ,
                 val_hide_actionid          = reply->query_qual[d.seq ].hide#actionid ,
                 val_hide_orderid           = reply->query_qual[d.seq ].hide#orderid ,  ;003
                 val_isolation_type         = substring (1 ,3 ,reply->query_qual[d.seq ].isolation_type ) ,
                 val_stat                   = substring (1 ,3 ,reply->query_qual[d.seq ].stat ) ,
                 val_inpatient              = substring (1 ,3 ,reply->query_qual[d.seq ].inpatient ) ,
                 val_cmt                    = substring (1 ,1 ,reply->query_qual[d.seq ].cmt ) ,
                 val_time                   = substring (1 ,40 ,reply->query_qual[d.seq ].time ) ,
                 val_earliest_dt_tm         = reply->query_qual[d.seq ].earliest_dt_tm ,
                 val_scheduled_dt_tm        = reply->query_qual[d.seq ].scheduled_dt_tm ,
                 val_days_of_week           = substring (1 ,27 ,reply->query_qual[d.seq ].days_of_week ) ,
                 val_req_action_display     = substring (1 ,40 ,reply->query_qual[d.seq ].req_action_display ) ,
                 val_appt_type_display      = substring (1 ,40 ,reply->query_qual[d.seq ].appt_type_display ) ,
                 val_person_name            = substring (1 ,100 ,reply->query_qual[d.seq ].person_name ) ,
                 val_sch_action_id          = reply->query_qual[d.seq ].sch_action_id ,
                 val_sch_event_id           = reply->query_qual[d.seq ].sch_event_id ,
                 val_orders                 = substring(1 , 50, reply->query_qual[d.seq ].orders ) ,
                 val_ord_date               = reply->query_qual[d.seq].ord_date, ;;002
                 val_time_diff              = substring (1 ,value (max_length_orders )
                                                           , reply->query_qual[d.seq].time_diff_ord_earliest), ;;002
                 val_order_cmt              = substring (1 ,3 ,reply->query_qual[d.seq ].order_cmt ) ,
                 val_spec_inst              = trim(substring(1,500, reply->query_qual[d.seq ].special_inst)), ;002
                 val_add_spec_inst          = trim(substring(1,500, reply->query_qual[d.seq ].add_special_inst)), ;003
                 val_order_doc              = substring(1,50, reply->query_qual[d.seq].order_doc),
                 val_pp_activity_id         = reply->query_qual[d.seq ].pp_activity_id ,
                 val_pp_activity            = substring (1 ,value (max_length_pp_activity ) 
                                                                                    ,reply->query_qual[d.seq ].pp_activity ) ,
                 val_pp_phase_activity      = substring (1 ,value (max_length_pp_phase_activity ) 
                                                                                    ,reply->query_qual[d.seq ].pp_phase_activity ) ,
                 val_pp_reference           = substring (1 ,value (max_length_pp_reference ) 
                                                                                    ,reply->query_qual[d.seq ].pp_reference ) ,
                 val_pp_phase_reference     = substring (1 ,value (max_length_pp_phase_reference ) 
                                                                                    ,reply->query_qual[d.seq ].pp_phase_reference ),
                 val_pp_scheduled_phase_id  = reply->query_qual[d.seq ].pp_scheduled_phase_id ,
                 val_pp_scheduled_phase     = substring (1 ,value (max_length_pp_scheduled_phase ) 
                                                                                    ,reply->query_qual[d.seq ].pp_scheduled_phase )
              FROM (dummyt d WITH seq= value (reply->query_qual_cnt ) )

              PLAN (d )
            ORDER BY reply->query_qual[d.seq ].earliest_dt_tm
            HEAD REPORT
                sch2_idx = 0
            DETAIL
                sch2_idx +=1 ,
                
                reply->query_qual[sch2_idx ].hide#schentryid        = val_hide_schentryid        ,
                reply->query_qual[sch2_idx ].hide#scheventid        = val_hide_scheventid        ,
                reply->query_qual[sch2_idx ].hide#scheduleid        = val_hide_scheduleid        ,
                reply->query_qual[sch2_idx ].hide#scheduleseq       = val_hide_scheduleseq       ,
                reply->query_qual[sch2_idx ].hide#reqactionid       = val_hide_reqactionid       ,
                reply->query_qual[sch2_idx ].hide#schapptid         = val_hide_schapptid         ,
                reply->query_qual[sch2_idx ].hide#statemeaning      = val_hide_statemeaning      ,
                reply->query_qual[sch2_idx ].hide#earliestdttm      = val_hide_earliestdttm      ,
                reply->query_qual[sch2_idx ].hide#latestdttm        = val_hide_latestdttm        ,
                reply->query_qual[sch2_idx ].hide#reqmadedttm       = val_hide_reqmadedttm       ,
                reply->query_qual[sch2_idx ].hide#entrystatemeaning = val_hide_entrystatemeaning ,
                reply->query_qual[sch2_idx ].hide#reqactionmeaning  = val_hide_reqactionmeaning  ,
                reply->query_qual[sch2_idx ].hide#encounterid       = val_hide_encounterid       ,
                reply->query_qual[sch2_idx ].hide#personid          = val_hide_personid          ,
                reply->query_qual[sch2_idx ].hide#bitmask           = val_hide_bitmask           ,
                reply->query_qual[sch2_idx ].hide#actionid          = val_hide_actionid          ,
                reply->query_qual[sch2_idx ].hide#orderid           = val_hide_orderid           ,  ;003
                reply->query_qual[sch2_idx ].isolation_type         = val_isolation_type         ,
                reply->query_qual[sch2_idx ].stat                   = val_stat                   ,
                reply->query_qual[sch2_idx ].inpatient              = val_inpatient              ,
                reply->query_qual[sch2_idx ].cmt                    = val_cmt                    ,
                reply->query_qual[sch2_idx ].time                   = val_time                   ,
                reply->query_qual[sch2_idx ].earliest_dt_tm         = val_earliest_dt_tm         ,
                reply->query_qual[sch2_idx ].scheduled_dt_tm        = val_scheduled_dt_tm        ,
                reply->query_qual[sch2_idx ].days_of_week           = val_days_of_week           ,
                reply->query_qual[sch2_idx ].req_action_display     = val_req_action_display     ,
                reply->query_qual[sch2_idx ].appt_type_display      = val_appt_type_display      ,
                reply->query_qual[sch2_idx ].person_name            = val_person_name            ,
                reply->query_qual[sch2_idx ].sch_action_id          = val_sch_action_id          ,
                reply->query_qual[sch2_idx ].sch_event_id           = val_sch_event_id           ,
                reply->query_qual[sch2_idx ].orders                 = val_orders                 ,
                reply->query_qual[sch2_idx ].ord_date               = val_ord_date               , ;;002
                reply->query_qual[sch2_idx ].time_diff_ord_earliest = val_time_diff              , ;;002
                reply->query_qual[sch2_idx ].order_cmt              = val_order_cmt              ,
                reply->query_qual[sch2_idx ].special_inst           = val_spec_inst              ,
                reply->query_qual[sch2_idx ].add_special_inst       = val_add_spec_inst          , ;003
                reply->query_qual[sch2_idx ].order_doc              = val_order_doc              ,
                reply->query_qual[sch2_idx ].pp_activity_id         = val_pp_activity_id         ,
                reply->query_qual[sch2_idx ].pp_activity            = val_pp_activity            ,
                reply->query_qual[sch2_idx ].pp_phase_activity      = val_pp_phase_activity      ,
                reply->query_qual[sch2_idx ].pp_reference           = val_pp_reference           ,
                reply->query_qual[sch2_idx ].pp_phase_reference     = val_pp_phase_reference     ,
                reply->query_qual[sch2_idx ].pp_scheduled_phase_id  = val_pp_scheduled_phase_id  ,
                reply->query_qual[sch2_idx ].pp_scheduled_phase     = val_pp_scheduled_phase
            WITH nocounter
            ;end select
            
            call echorecord(reply)
        
        
        else
        
            SELECT INTO "nl:"
                 val_hide_schentryid        = reply->query_qual[d.seq ].hide#schentryid ,
                 val_hide_scheventid        = reply->query_qual[d.seq ].hide#scheventid ,
                 val_hide_scheduleid        = reply->query_qual[d.seq ].hide#scheduleid ,
                 val_hide_scheduleseq       = reply->query_qual[d.seq ].hide#scheduleseq ,
                 val_hide_reqactionid       = reply->query_qual[d.seq ].hide#reqactionid ,
                 val_hide_schapptid         = reply->query_qual[d.seq ].hide#schapptid ,
                 val_hide_statemeaning      = substring (1 ,12 ,reply->query_qual[d.seq ].hide#statemeaning ) ,
                 val_hide_earliestdttm      = reply->query_qual[d.seq ].hide#earliestdttm ,
                 val_hide_latestdttm        = reply->query_qual[d.seq ].hide#latestdttm ,
                 val_hide_reqmadedttm       = reply->query_qual[d.seq ].hide#reqmadedttm ,
                 val_hide_entrystatemeaning = substring (1 ,12 ,reply->query_qual[d.seq ].hide#entrystatemeaning ) ,
                 val_hide_reqactionmeaning = substring (1 ,12 ,reply->query_qual[d.seq ].hide#reqactionmeaning ) ,
                 val_hide_encounterid       = reply->query_qual[d.seq ].hide#encounterid ,
                 val_hide_personid          = reply->query_qual[d.seq ].hide#personid ,
                 val_hide_bitmask           = reply->query_qual[d.seq ].hide#bitmask ,
                 val_hide_actionid          = reply->query_qual[d.seq ].hide#actionid ,
                 val_hide_orderid           = reply->query_qual[d.seq ].hide#orderid ,  ;003
                 val_isolation_type         = substring (1 ,3 ,reply->query_qual[d.seq ].isolation_type ) ,
                 val_stat                   = substring (1 ,3 ,reply->query_qual[d.seq ].stat ) ,
                 val_inpatient              = substring (1 ,3 ,reply->query_qual[d.seq ].inpatient ) ,
                 val_cmt                    = substring (1 ,1 ,reply->query_qual[d.seq ].cmt ) ,
                 val_time                   = substring (1 ,40 ,reply->query_qual[d.seq ].time ) ,
                 val_earliest_dt_tm         = reply->query_qual[d.seq ].earliest_dt_tm ,
                 val_scheduled_dt_tm        = reply->query_qual[d.seq ].scheduled_dt_tm ,
                 val_days_of_week           = substring (1 ,27 ,reply->query_qual[d.seq ].days_of_week ) ,
                 val_req_action_display     = substring (1 ,40 ,reply->query_qual[d.seq ].req_action_display ) ,
                 val_appt_type_display      = substring (1 ,40 ,reply->query_qual[d.seq ].appt_type_display ) ,
                 val_person_name            = substring (1 ,100 ,reply->query_qual[d.seq ].person_name ) ,
                 val_sch_action_id          = reply->query_qual[d.seq ].sch_action_id ,
                 val_sch_event_id           = reply->query_qual[d.seq ].sch_event_id ,
                 val_orders                 = substring(1 , 50, reply->query_qual[d.seq ].orders ) ,
                 val_ord_date               = reply->query_qual[d.seq].ord_date, ;;002
                 val_time_diff              = substring (1 ,value (max_length_orders )
                                                           , reply->query_qual[d.seq].time_diff_ord_earliest), ;;002
                 val_order_cmt              = substring (1 ,3 ,reply->query_qual[d.seq ].order_cmt ) ,
                 val_spec_inst              = trim(substring(1,500, reply->query_qual[d.seq ].special_inst)), ;002
                 val_add_spec_inst          = trim(substring(1,500, reply->query_qual[d.seq ].add_special_inst)), ;003
                 val_order_doc              = substring(1,50, reply->query_qual[d.seq].order_doc),
                 val_pp_activity_id         = reply->query_qual[d.seq ].pp_activity_id ,
                 val_pp_activity            = substring (1 ,value (max_length_pp_activity ) 
                                                                                    ,reply->query_qual[d.seq ].pp_activity ) ,
                 val_pp_phase_activity      = substring (1 ,value (max_length_pp_phase_activity ) 
                                                                                    ,reply->query_qual[d.seq ].pp_phase_activity ) ,
                 val_pp_reference           = substring (1 ,value (max_length_pp_reference ) 
                                                                                    ,reply->query_qual[d.seq ].pp_reference ) ,
                 val_pp_phase_reference     = substring (1 ,value (max_length_pp_phase_reference ) 
                                                                                    ,reply->query_qual[d.seq ].pp_phase_reference ),
                 val_pp_scheduled_phase_id  = reply->query_qual[d.seq ].pp_scheduled_phase_id ,
                 val_pp_scheduled_phase     = substring (1 ,value (max_length_pp_scheduled_phase ) 
                                                                                    ,reply->query_qual[d.seq ].pp_scheduled_phase )
              FROM (dummyt d WITH seq= value (reply->query_qual_cnt ) )

              PLAN (d )
            ORDER BY reply->query_qual[d.seq ].pp_activity_id DESC ,
                     reply->query_qual[d.seq ].pp_scheduled_phase_id DESC ,
                     reply->query_qual[d.seq ].hide#reqactionid
            HEAD REPORT
                sch2_idx = 0
            DETAIL
                sch2_idx +=1 ,
                
                reply->query_qual[sch2_idx ].hide#schentryid        = val_hide_schentryid        ,
                reply->query_qual[sch2_idx ].hide#scheventid        = val_hide_scheventid        ,
                reply->query_qual[sch2_idx ].hide#scheduleid        = val_hide_scheduleid        ,
                reply->query_qual[sch2_idx ].hide#scheduleseq       = val_hide_scheduleseq       ,
                reply->query_qual[sch2_idx ].hide#reqactionid       = val_hide_reqactionid       ,
                reply->query_qual[sch2_idx ].hide#schapptid         = val_hide_schapptid         ,
                reply->query_qual[sch2_idx ].hide#statemeaning      = val_hide_statemeaning      ,
                reply->query_qual[sch2_idx ].hide#earliestdttm      = val_hide_earliestdttm      ,
                reply->query_qual[sch2_idx ].hide#latestdttm        = val_hide_latestdttm        ,
                reply->query_qual[sch2_idx ].hide#reqmadedttm       = val_hide_reqmadedttm       ,
                reply->query_qual[sch2_idx ].hide#entrystatemeaning = val_hide_entrystatemeaning ,
                reply->query_qual[sch2_idx ].hide#reqactionmeaning  = val_hide_reqactionmeaning  ,
                reply->query_qual[sch2_idx ].hide#encounterid       = val_hide_encounterid       ,
                reply->query_qual[sch2_idx ].hide#personid          = val_hide_personid          ,
                reply->query_qual[sch2_idx ].hide#bitmask           = val_hide_bitmask           ,
                reply->query_qual[sch2_idx ].hide#actionid          = val_hide_actionid          ,
                reply->query_qual[sch2_idx ].hide#orderid           = val_hide_orderid           ,  ;003
                reply->query_qual[sch2_idx ].isolation_type         = val_isolation_type         ,
                reply->query_qual[sch2_idx ].stat                   = val_stat                   ,
                reply->query_qual[sch2_idx ].inpatient              = val_inpatient              ,
                reply->query_qual[sch2_idx ].cmt                    = val_cmt                    ,
                reply->query_qual[sch2_idx ].time                   = val_time                   ,
                reply->query_qual[sch2_idx ].earliest_dt_tm         = val_earliest_dt_tm         ,
                reply->query_qual[sch2_idx ].scheduled_dt_tm        = val_scheduled_dt_tm        ,
                reply->query_qual[sch2_idx ].days_of_week           = val_days_of_week           ,
                reply->query_qual[sch2_idx ].req_action_display     = val_req_action_display     ,
                reply->query_qual[sch2_idx ].appt_type_display      = val_appt_type_display      ,
                reply->query_qual[sch2_idx ].person_name            = val_person_name            ,
                reply->query_qual[sch2_idx ].sch_action_id          = val_sch_action_id          ,
                reply->query_qual[sch2_idx ].sch_event_id           = val_sch_event_id           ,
                reply->query_qual[sch2_idx ].orders                 = val_orders                 ,
                reply->query_qual[sch2_idx ].ord_date               = val_ord_date               , ;;002
                reply->query_qual[sch2_idx ].time_diff_ord_earliest = val_time_diff              , ;;002
                reply->query_qual[sch2_idx ].order_cmt              = val_order_cmt              ,
                reply->query_qual[sch2_idx ].special_inst           = val_spec_inst              ,
                reply->query_qual[sch2_idx ].add_special_inst       = val_add_spec_inst          , ;003
                reply->query_qual[sch2_idx ].order_doc              = val_order_doc              ,
                reply->query_qual[sch2_idx ].pp_activity_id         = val_pp_activity_id         ,
                reply->query_qual[sch2_idx ].pp_activity            = val_pp_activity            ,
                reply->query_qual[sch2_idx ].pp_phase_activity      = val_pp_phase_activity      ,
                reply->query_qual[sch2_idx ].pp_reference           = val_pp_reference           ,
                reply->query_qual[sch2_idx ].pp_phase_reference     = val_pp_phase_reference     ,
                reply->query_qual[sch2_idx ].pp_scheduled_phase_id  = val_pp_scheduled_phase_id  ,
                reply->query_qual[sch2_idx ].pp_scheduled_phase     = val_pp_scheduled_phase
            WITH nocounter
            ;end select
            
            call echorecord(reply)
        endif
    ENDIF

#exit_script
    IF ((failed = false ) )
        SET reply->status_data.status = "S"
    ELSE
        SET reply->status_data.status = "Z"
        IF ((failed != true ) )
            CASE (failed )
            OF select_error :
                SET reply->status_data.subeventstatus[1 ].operationname = "SELECT"
            ELSE
                SET reply->status_data.subeventstatus[1 ].operationname = "UNKNOWN"
            ENDCASE
            SET reply->status_data.subeventstatus[1 ].operationstatus = "Z"
            SET reply->status_data.subeventstatus[1 ].targetobjectname = "TABLE"
            SET reply->status_data.subeventstatus[1 ].targetobjectvalue = table_name
        ENDIF
    ENDIF

FREE SET t_record

END GO