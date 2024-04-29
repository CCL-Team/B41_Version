drop program 14_mp_get_person_demogr go
create program 14_mp_get_person_demogr
 
 
/*************************************************************************
*  Include files                                                         *
*************************************************************************/
;%i cclsource:mp_common.inc
 
/* DECLARE VARIABLES *****************************************************************************/
declare CURRENT_DATE_TIME		= dq8 with constant(cnvtdatetime(curdate,curtime3)), protect
declare CURRENT_TIME_ZONE		= i4 with constant(datetimezonebyname(curtimezone)), protect
declare ENDING_DATE_TIME		= dq8 with constant(cnvtdatetime("31-DEC-2100")), protect
declare BIND_CNT				= i4 with constant(50), protect
declare lower_bound_date 		= vc with constant("01-JAN-1800 00:00:00.00"),protect
declare upper_bound_date 		= vc with constant ("31-DEC-2100 23:59:59.99"),protect
declare codeListCnt				= i4 with noconstant(0), protect
declare prsnlListCnt			= i4 with noconstant(0), protect
declare phoneListCnt			= i4 with noconstant(0), protect
 
declare code_idx = i4 with noconstant(0), protect
declare prsnl_idx = i4 with noconstant(0), protect
declare phone_idx = i4 with noconstant(0), protect
declare prsnl_cnt = i4 with noconstant(0), protect
 
declare MPC_AP_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_DOC_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_MDOC_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_RAD_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_TXT_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_NUM_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_IMMUN_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_MED_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_DATE_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_DONE_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_MBO_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_PROCEDURE_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_GRP_TYPE_CD = f8 with  protect, noconstant(0.0)
declare MPC_HLATYPING_TYPE_CD = f8 with  protect, noconstant(0.0)
declare eventClassCdPopulated = i2 with  protect, noconstant(0)
 
/* DECLARE SUBROUTINES ***************************************************************************/
declare AddCodeToList(P1=F8(VAL), P2=VC(REF))							= null with protect
declare AddPersonnelToList(P1=F8(VAL), P2=VC(REF))						= null with protect
declare AddPersonnelToListWithDate(P1=F8(VAL), P2=VC(REF),P3=F8(VAL)) 	= null with protect
declare AddPhonesToList(P1=F8(VAL), P2=VC(REF))							= null with protect
declare PutJSONRecordToFile(P1=VC(REF))									= null with protect
declare PutStringToFile(P1=VC(VAL))										= null with protect
declare OutputCodeList(P1=VC(REF))										= null with protect
declare OutputPersonnelList(P1=VC(REF)) 								= null with protect
declare OutputPhoneList(P1=F8(VAL), P2=VC(REF))							= null with protect
declare GetParameterValues(P1=I4(VAL), P2=VC(REF))						= null with protect
declare GetLookbackDateByType(P1=I4(VAL), P2=I4(VAL)) 					= dq8 with protect
declare GetCodeValuesFromCodeset(P1=VC(REF), P2=VC(REF))				= null with protect
declare GetEventSetNamesFromEventSetCds(P1=VC(REF), P2=VC(REF))			= null with protect
declare returnViewerType(P1=F8(VAL), P2=F8(VAL))						= vc with protect
declare cnvtIsoDtTmToDQ8(P1=VC)											= DQ8 with protect
declare cnvtDQ8ToIsoDtTm(P1=F8) 										= VC with protect
declare GetOrgSecurityFlag(NULL)										= i2 with protect
declare GetCompOrgSecurityFlag(P1=VC(VAL))								= i2 with protect
declare PopulateAuthorizedOrganizations(P1=F8(VAL), P2=VC(REF))			= null with protect
declare GetUserLogicalDomain (P1=f8) 									= f8 with protect
 
/* RECORD STRUCTURES *****************************************************************************/
/* The record structure to pass in phone types should look like the following (in order of preference)
free record phone_types
record phone_types(
	1 phone_codes[*]
		2 phone_cd = f8
)
*/
 
/*
AddCodeToList(DOUBLE, VC) adds a code value to the code_list record.
*/
subroutine AddCodeToList(code_value, record_data)
	if (code_value != 0)
		if (codeListCnt = 0 or locateval(code_idx, 1, codeListCnt, code_value, record_data->codes[code_idx].code) <= 0)
			set codeListCnt = codeListCnt + 1
			set stat = alterlist(record_data->codes, codeListCnt)
			set record_data->codes[codeListCnt].code = code_value
			set record_data->codes[codeListCnt].sequence = uar_get_collation_seq(code_value)
			set record_data->codes[codeListCnt].meaning = uar_get_code_meaning(code_value)
			set record_data->codes[codeListCnt].display = uar_get_code_display(code_value)
			set record_data->codes[codeListCnt].description = uar_get_code_description(code_value)
			set record_data->codes[codeListCnt].code_set = uar_get_code_set(code_value)
		endif
	endif
end
 
/*
OutputCodeListXML(VC) given a record structure will populate the code list based on the code values added
to the code list.
*/
subroutine OutputCodeList(record_data)
	call log_message("In OutputCodeList() @deprecated", LOG_LEVEL_DEBUG)
end
 
/*
AddPersonnelToList(DOUBLE, VC) add a personnel id to the prsnl_list record structure.
*/
subroutine AddPersonnelToList(prsnl_id, record_data)
	call AddPersonnelToListWithDate(prsnl_id, record_data, CURRENT_DATE_TIME)
end
 
/*
AddPersonnelToListByDate(DOUBLE, VC, DQ8) add a personnel id to the prsnl_list record structure
by their active name at the specific date and time denoted by active_date.
*/
subroutine AddPersonnelToListWithDate(prsnl_id, record_data, active_date)
	declare PERSONNEL_CD = f8 with protect, constant(uar_get_code_by("MEANING", 213, "PRSNL"))
 
 	if(active_date = null or active_date = 0.0)
 		set active_date = CURRENT_DATE_TIME
 	endif
 
 	if (prsnl_id != 0)
		if (prsnlListCnt = 0 or
			locateval(prsnl_idx, 1, prsnlListCnt, prsnl_id, record_data->prsnl[prsnl_idx].id,
					  active_date, record_data->prsnl[prsnl_idx].active_date) <= 0)
			set prsnlListCnt = prsnlListCnt + 1
			if (prsnlListCnt > size(record_data->prsnl, 5))
				set stat = alterlist(record_data->prsnl, prsnlListCnt + 9)
			endif
			set record_data->prsnl[prsnlListCnt].id = prsnl_id
			if(validate(record_data->prsnl[prsnlListCnt].active_date) != 0)
				set record_data->prsnl[prsnlListCnt].active_date = active_date
			endif
		endif
	endif
end
 
/*
OutputPersonnelList(VC) based on the record structure will output the personnel list stored on the prsnl table.
*/
subroutine OutputPersonnelList(report_data)
	call log_message("In OutputPersonnelList()", LOG_LEVEL_DEBUG)
	declare BEGIN_DATE_TIME = dq8 with constant(cnvtdatetime(curdate, curtime3)), private
 	declare PRSNL_NAME_TYPE_CD	= f8 with constant(uar_get_code_by("MEANING", 213, "PRSNL")), protect
	declare active_date_ind = i2 with protect, noconstant(0)
	declare filteredCnt = i4 with protect, noconstant(0)
	declare prsnl_seq = i4 with protect, noconstant(0)
	declare idx = i4 with protect, noconstant(0)
 
	if (prsnlListCnt > 0)
		select into "nl:"
		from prsnl p
			, (left join person_name pn on (pn.person_id = p.person_id and pn.name_type_cd = PRSNL_NAME_TYPE_CD and pn.active_ind = 1))
		plan p
			where expand(idx, 1, size(report_data->prsnl, 5), p.person_id, report_data->prsnl[idx]->id)
		join pn
		order by p.person_id, pn.end_effective_dt_tm desc
		head report
			prsnl_seq = 0
			active_date_ind = validate(report_data->prsnl[1]->active_date, 0)
		head p.person_id
			;This code is here for passivity and just retrieves the latest name
			if(active_date_ind = 0)
				prsnl_seq = locateval(idx, 1, prsnlListCnt, p.person_id, report_data->prsnl[idx].id)
				if (pn.person_id > 0)
					report_data->prsnl[prsnl_seq].provider_name.name_full = trim(pn.name_full, 3)
					report_data->prsnl[prsnl_seq].provider_name.name_first = trim(pn.name_first, 3)
					report_data->prsnl[prsnl_seq].provider_name.name_middle = trim(pn.name_middle, 3)
					report_data->prsnl[prsnl_seq].provider_name.name_last = trim(pn.name_last, 3)
					report_data->prsnl[prsnl_seq].provider_name.username = trim(p.username, 3)
					report_data->prsnl[prsnl_seq].provider_name.initials = trim(pn.name_initials, 3)
					report_data->prsnl[prsnl_seq].provider_name.title = trim(pn.name_initials, 3)
				else
					report_data->prsnl[prsnl_seq].provider_name.name_full = trim(p.name_full_formatted, 3)
					report_data->prsnl[prsnl_seq].provider_name.name_first = trim(p.name_first, 3)
					report_data->prsnl[prsnl_seq].provider_name.name_last = trim(pn.name_last, 3)
					report_data->prsnl[prsnl_seq].provider_name.username = trim(p.username, 3)
				endif
			endif
		detail
			;This is the new logic for retrieving personnel names based on a specific date and time
			if(active_date_ind != 0)
				prsnl_seq = locateval(idx, 1, prsnlListCnt, p.person_id, report_data->prsnl[idx].id)
	 			while(prsnl_seq > 0)
	 				if(report_data->prsnl[prsnl_seq]->active_date between pn.beg_effective_dt_tm and pn.end_effective_dt_tm)
						if (pn.person_id > 0)
							report_data->prsnl[prsnl_seq].person_name_id = pn.person_name_id
							report_data->prsnl[prsnl_seq].beg_effective_dt_tm = pn.beg_effective_dt_tm
							report_data->prsnl[prsnl_seq].end_effective_dt_tm = pn.end_effective_dt_tm
							report_data->prsnl[prsnl_seq].provider_name.name_full = trim(pn.name_full, 3)
							report_data->prsnl[prsnl_seq].provider_name.name_first = trim(pn.name_first, 3)
							report_data->prsnl[prsnl_seq].provider_name.name_middle = trim(pn.name_middle, 3)
							report_data->prsnl[prsnl_seq].provider_name.name_last = trim(pn.name_last, 3)
							report_data->prsnl[prsnl_seq].provider_name.username = trim(p.username, 3)
							report_data->prsnl[prsnl_seq].provider_name.initials = trim(pn.name_initials, 3)
							report_data->prsnl[prsnl_seq].provider_name.title = trim(pn.name_initials, 3)
						else
							report_data->prsnl[prsnl_seq].provider_name.name_full = trim(p.name_full_formatted, 3)
							report_data->prsnl[prsnl_seq].provider_name.name_first = trim(p.name_first, 3)
							report_data->prsnl[prsnl_seq].provider_name.name_last = trim(pn.name_last, 3)
							report_data->prsnl[prsnl_seq].provider_name.username = trim(p.username, 3)
						endif
						if(report_data->prsnl[prsnl_seq].active_date = CURRENT_DATE_TIME)
							report_data->prsnl[prsnl_seq].active_date = 0
						endif
					endif
					prsnl_seq = locateval(idx, prsnl_seq + 1, prsnlListCnt, p.person_id, report_data->prsnl[idx].id)
				endwhile
			endif
		foot report
			stat = alterlist(report_data->prsnl, prsnlListCnt)
		with nocounter
 
		call ERROR_AND_ZERO_CHECK_REC(curqual, "PRSNL", "OutputPersonnelList", 1, 0, report_data)
 
		;filter out duplicate names
	 	if(active_date_ind != 0)
	 		select into "nl:"
	 			end_effective_dt_tm = report_data->prsnl[d.seq].end_effective_dt_tm
	 			, person_name_id = report_data->prsnl[d.seq].person_name_id
	 			, prsnl_id = report_data->prsnl[d.seq].id
	 		from (dummyt d with seq = size(report_data->prsnl, 5))
	 		order by end_effective_dt_tm desc, person_name_id, prsnl_id
	 		head report
	 			filteredCnt = 0
	 			idx = size(report_data->prsnl, 5)
	 			stat = alterlist(report_data->prsnl, idx * 2)
 
	 		head end_effective_dt_tm
	 			donothing = 0
 
	 		head prsnl_id
				idx = idx + 1
				filteredCnt = filteredCnt + 1
 			 	report_data->prsnl[idx]->id = report_data->prsnl[d.seq]->id
				report_data->prsnl[idx]->person_name_id = report_data->prsnl[d.seq]->person_name_id
				if(report_data->prsnl[d.seq]->person_name_id > 0.0)
					report_data->prsnl[idx]->beg_effective_dt_tm = report_data->prsnl[d.seq]->beg_effective_dt_tm
					report_data->prsnl[idx]->end_effective_dt_tm = report_data->prsnl[d.seq]->end_effective_dt_tm
				else
					report_data->prsnl[idx]->beg_effective_dt_tm = cnvtdatetime("01-JAN-1900")
					report_data->prsnl[idx]->end_effective_dt_tm = cnvtdatetime("31-DEC-2100")
				endif
				report_data->prsnl[idx]->provider_name->name_full = report_data->prsnl[d.seq]->provider_name->name_full
				report_data->prsnl[idx]->provider_name->name_first = report_data->prsnl[d.seq]->provider_name->name_first
				report_data->prsnl[idx]->provider_name->name_middle = report_data->prsnl[d.seq]->provider_name->name_middle
				report_data->prsnl[idx]->provider_name->name_last = report_data->prsnl[d.seq]->provider_name->name_last
				report_data->prsnl[idx]->provider_name->username = report_data->prsnl[d.seq]->provider_name->username
				report_data->prsnl[idx]->provider_name->initials = report_data->prsnl[d.seq]->provider_name->initials
				report_data->prsnl[idx]->provider_name->title = report_data->prsnl[d.seq]->provider_name->title
 
	 		foot report
	 			;resize by newListCnt to filter down the unused elements
	 			stat = alterlist(report_data->prsnl, idx)
	 			;resize the list to just show the results that were not filtered
	 			stat = alterlist(report_data->prsnl, filteredCnt, 0)
	 		with nocounter
 
	 		call ERROR_AND_ZERO_CHECK_REC(curqual, "PRSNL", "FilterPersonnelList", 1, 0, report_data)
	 	endif
	endif
 
	call log_message(build("Exit OutputPersonnelList(), Elapsed time in seconds:",
	datetimediff(cnvtdatetime(curdate,curtime3),BEGIN_DATE_TIME, 5)), LOG_LEVEL_DEBUG)
end
 
/*
AddPhonesToList(DOUBLE, VC) add a personnel id to the phone_list record structure
*/
subroutine AddPhonesToList(prsnl_id, record_data)
 
 	if (prsnl_id != 0)
		if (phoneListCnt = 0 or
			locateval(phone_idx, 1, phoneListCnt, prsnl_id, record_data->phone_list[prsnl_idx].person_id) <= 0)
			set phoneListCnt = phoneListCnt + 1
			if (phoneListCnt > size(record_data->phone_list, 5))
				set stat = alterlist(record_data->phone_list, phoneListCnt + 9)
			endif
			set record_data->phone_list[phoneListCnt].person_id = prsnl_id
			set prsnl_cnt = prsnl_cnt + 1
		endif
	endif
 
end
 
 
/*
OutputPhoneList(VC) based on the record structure will output the phone list stored on the phone table.
*/
subroutine OutputPhoneList(report_data, phone_types)
	call log_message("In OutputPhoneList()", LOG_LEVEL_DEBUG)
	declare BEGIN_DATE_TIME = dq8 with constant(cnvtdatetime(curdate, curtime3)), private
	declare PERSONCNT = i4 with protect, constant(size(report_data->phone_list, 5))
	declare idx = i4 with protect, noconstant(0)
	declare idx2 = i4 with protect, noconstant(0)
	declare idx3 = i4 with protect, noconstant(0)
	declare phoneCnt = i4 with protect, noconstant(0)
	declare prsnlIdx = i4 with protect, noconstant(0)
 	;;report_data->phone_list size is greater than 0.  prsnlListCnt is set in AddPhonesToList() in mp_common.inc
	if (phoneListCnt > 0)
		select into "nl:"
			phone_sorter = locateval(idx2, 1, size(phone_types->phone_codes, 5), ph.phone_type_cd, phone_types->phone_codes[idx2]->phone_cd)
		from phone ph
		where expand(idx, 1, PERSONCNT, ph.parent_entity_id, report_data->phone_list[idx]->person_id)
			and ph.parent_entity_name = "PERSON"
			and ph.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
			and ph.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
			and ph.active_ind = 1
			and expand(idx2, 1, size(phone_types->phone_codes, 5), ph.phone_type_cd, phone_types->phone_codes[idx2]->phone_cd)
			and ph.phone_type_seq = 1
		order by ph.parent_entity_id, phone_sorter
 
		head ph.parent_entity_id
			phoneCnt = 0
			prsnlIdx = locateval(idx3, 1, PERSONCNT, ph.parent_entity_id, report_data->phone_list[idx3]->person_id)
		head phone_sorter
			phoneCnt = phoneCnt + 1
			if(size(report_data->phone_list[prsnlIdx]->phones,5) < phoneCnt)
				stat = alterlist(report_data->phone_list[prsnlIdx]->phones, phoneCnt + 5)
			endif
			report_data->phone_list[prsnlIdx]->phones[phoneCnt].phone_type = uar_get_code_display(ph.phone_type_cd)
			report_data->phone_list[prsnlIdx]->phones[phoneCnt].phone_num =
						FormatPhoneNumber(ph.phone_num, ph.phone_format_cd, ph.extension)
		foot ph.parent_entity_id
			stat = alterlist(report_data->phone_list[prsnlIdx]->phones, phoneCnt)
		with nocounter, expand = value(evaluate(floor((PERSONCNT - 1)/30), 0, 0, 1))  ;If more than 30 persons use global temp table.
 
 		set stat = alterlist(report_data->phone_list, prsnl_cnt)
 
		call ERROR_AND_ZERO_CHECK_REC(curqual, "PHONE", "OutputPhoneList", 1, 0, report_data)
	endif
 
	call log_message(build("Exit OutputPhoneList(), Elapsed time in seconds:",
	datetimediff(cnvtdatetime(curdate,curtime3),BEGIN_DATE_TIME, 5)), LOG_LEVEL_DEBUG)
end
 
subroutine PutStringToFile(sValue)
	call log_message("In PutStringToFile()", LOG_LEVEL_DEBUG)
	declare BEGIN_DATE_TIME = dq8 with constant(cnvtdatetime(curdate, curtime3)), private
 
	if(validate(_Memory_Reply_String)=1)
		set _Memory_Reply_String = sValue
	else
		; REQUEST record to display the file
		free record putREQUEST
		record putREQUEST (
			1 source_dir = vc
			1 source_filename = vc
			1 nbrlines = i4
			1 line [*]
				2 lineData = vc
			1 OverFlowPage [*]
				2 ofr_qual [*]
					3 ofr_line = vc
			1 IsBlob = c1
			1 document_size = i4
			1 document = gvc
		)
 
		; Set parameters for displaying the file
		set putRequest->source_dir = $outdev
		set putRequest->IsBlob = "1"
		set putRequest->document = sValue
		set putRequest->document_size = size(putRequest->document)
 
		;  Display the file.  This allows XmlCclRequest to receive the output
		execute eks_put_source with replace("REQUEST",putRequest),replace("REPLY",putReply)
	endif
 
	call log_message(build("Exit PutStringToFile(), Elapsed time in seconds:",
	datetimediff(cnvtdatetime(curdate,curtime3),BEGIN_DATE_TIME, 5)), LOG_LEVEL_DEBUG)
end
 
/*
PutJSONRecordToFile(VC) puts the current record to the output
*/
subroutine PutJSONRecordToFile(record_data)
	call log_message("In PutJSONRecordToFile()", LOG_LEVEL_DEBUG)
	declare BEGIN_DATE_TIME = dq8 with constant(cnvtdatetime(curdate, curtime3)), private
 
	call PutStringToFile(cnvtrectojson(record_data))
 
	call log_message(build("Exit PutJSONRecordToFile(), Elapsed time in seconds:",
	datetimediff(cnvtdatetime(curdate,curtime3),BEGIN_DATE_TIME, 5)), LOG_LEVEL_DEBUG)
end
 
/*
GetParameterValues(index, value_rec) get the parameter values passed into the prompt at a given index.  An assumption is
made that the values are all 'I4's and 'F8's.  The value_rec is also required to look like:
 
 
free record temp_rec
record temp_rec
(
	1 cnt = i4
	1 qual[*]
		2 value = f8
)
 
For example of usage of this method, if the following is executed:
mp_get_allergies "mine", <person_id>, <encntr_id> go
mp_get_allergies "mine", 1548144, value(1550459, 1550468) go
 
The 1st index is the parameter "mine".  The 2nd index is the parameter '1548144' which is the person_id, and the 3rd index is
the parameter array 'value(1550459, 1550468)'.  To extract all the _cds or _ids from an index you would call the method as
follows for the current example
 
call GetParameterValues(3, temp_rec)
 
The outcome of the retrieval of the parameter values is
>>>Begin EchoRecord VALUE_REC   ;ENCNTR_REC
 1 CNT= I4   {2}
 1 QUAL[1,2*]
  2 VALUE=F8   {1550459.0000000000                      }
 1 QUAL[2,2*]
  2 VALUE=F8   {1550468.0000000000                      }
 
*/
subroutine GetParameterValues(index, value_rec)
	declare par = vc with noconstant(""), protect
	declare lnum = i4 with noconstant(0), protect
	declare num = i4 with noconstant(1), protect
	declare cnt = i4 with noconstant(0), protect
	declare cnt2 = i4 with noconstant(0), protect
	declare param_value = f8 with noconstant(0.0), protect
	declare param_value_str = vc with noconstant(""), protect
 
	SET par = reflect(parameter(index,0))
	if (validate(debug_ind, 0) = 1)
		call echo(par)
	endif
	if (par = "F8" or par = "I4")
		set param_value = parameter(index,0)
		if (param_value > 0)
			set value_rec->cnt = value_rec->cnt + 1
			set stat = alterlist(value_rec->qual, value_rec->cnt)
			set value_rec->qual[value_rec->cnt].value = param_value
		endif
	elseif (substring(1,1,par) = "C")
		set param_value_str = parameter(index,0)
		if (trim(param_value_str, 3) != "")
			set value_rec->cnt = value_rec->cnt + 1
			set stat = alterlist(value_rec->qual, value_rec->cnt)
			set value_rec->qual[value_rec->cnt].value = trim(param_value_str, 3)
		endif
	elseif (substring(1,1,par) = "L") ;this is list type
		set lnum = 1
		while (lnum>0)
			set par = reflect(parameter(index,lnum))
			if (par != " ")
				if (par = "F8" or par = "I4")
					;valid item in list for parameter
					set param_value = parameter(index,lnum)
					if (param_value > 0)
						set value_rec->cnt = value_rec->cnt + 1
						set stat = alterlist(value_rec->qual, value_rec->cnt)
						set value_rec->qual[value_rec->cnt].value = param_value
					endif
					set lnum = lnum+1
				elseif (substring(1,1,par) = "C")
					;valid item in list for parameter
					set param_value_str = parameter(index,lnum)
					if (trim(param_value_str, 3) != "")
						set value_rec->cnt = value_rec->cnt + 1
						set stat = alterlist(value_rec->qual, value_rec->cnt)
						set value_rec->qual[value_rec->cnt].value = trim(param_value_str, 3)
					endif
					set lnum = lnum+1
				endif
			else
				set lnum = 0
			endif
		endwhile
	endif
	if (validate(debug_ind, 0) = 1)
		call echorecord(value_rec)
	endif
end
 
subroutine GetLookbackDateByType(units,flag)
	declare looback_date = dq8 with noconstant(cnvtdatetime("01-JAN-1800 00:00:00"))
	if(units != 0)
		case (flag)
			of 1: set looback_date = cnvtlookbehind(build(units,",H"),cnvtdatetime(curdate,curtime3))
			of 2: set looback_date = cnvtlookbehind(build(units,",D"),cnvtdatetime(curdate,curtime3))
			of 3: set looback_date = cnvtlookbehind(build(units,",W"),cnvtdatetime(curdate,curtime3))
			of 4: set looback_date = cnvtlookbehind(build(units,",M"),cnvtdatetime(curdate,curtime3))
			of 5: set looback_date = cnvtlookbehind(build(units,",Y"),cnvtdatetime(curdate,curtime3))
		endcase
	endif
	return (looback_date)
end
 
subroutine GetCodeValuesFromCodeset(evt_set_rec, evt_cd_rec)
	declare csIdx = i4 with noconstant(0)
 
	select distinct into "nl:"
	from v500_event_set_explode vese
		where expand(csIdx, 1, evt_set_rec->cnt, vese.event_set_cd, evt_set_rec->qual[csIdx].value)
	detail
		evt_cd_rec->cnt = evt_cd_rec->cnt + 1
		stat = alterlist(evt_cd_rec->qual, evt_cd_rec->cnt)
 
		evt_cd_rec->qual[evt_cd_rec->cnt].value = vese.event_cd
	with nocounter
end
 
/*
	GetEventSetNamesFromEventSetCds
	params:
		evt_set_rec : Record containing event set cds
		evt_set_name_rec : Destination Record for event set names
				Record Structure for both:
					free record temp_rec
					record temp_rec
					(
						1 cnt = i4
						1 qual[*]
							2 value = f8
					)
 
    Returns:
		null
 
*/
 
subroutine GetEventSetNamesFromEventSetCds(evt_set_rec, evt_set_name_rec)
declare index = i4 with protect,noconstant(0)
declare pos =i4 with protect, noconstant(0)
  select into "nl:"
    es_name = cnvtupper(v.event_set_cd_disp)
  from v500_event_set_code v
  where expand(index,1,evt_set_rec->cnt,v.event_set_cd,evt_set_rec->qual[index].value)
 
  head report
    stat = alterlist(evt_set_name_rec->qual,evt_set_rec->cnt)
  detail
    	pos = locateval(index,1,evt_set_rec->cnt,v.event_set_cd,evt_set_rec->qual[index].value)
 
		while(pos > 0)
			evt_set_name_rec->qual[pos].value = v.event_set_name
    		pos = locateval(index,pos+1,evt_set_rec->cnt,v.event_set_cd,evt_set_rec->qual[index].value)
    	endwhile
  foot report
    evt_set_name_rec->cnt = evt_set_rec->cnt
  with nocounter, expand = value(evaluate(floor((evt_set_rec->cnt-1)/30),0,0,1))
end
 
/*
	returnViewerType
	params:
		eventClassCd = the event_class_cd of the document to be viewed
		EventId = the event_id of the document to be viewed
	returns:
		String representing viewer
*/
subroutine returnViewerType(eventClassCd, eventId)
	call log_message("In returnViewerType()", LOG_LEVEL_DEBUG)
	declare BEGIN_DATE_TIME = dq8 with constant(cnvtdatetime(curdate, curtime3)), private
	if(eventClassCdPopulated = 0)
	  	 set MPC_AP_TYPE_CD = uar_get_code_by("MEANING", 53, "AP")
		 set MPC_DOC_TYPE_CD = uar_get_code_by("MEANING", 53, "DOC")
		 set MPC_MDOC_TYPE_CD = uar_get_code_by("MEANING", 53, "MDOC")
		 set MPC_RAD_TYPE_CD = uar_get_code_by("MEANING", 53, "RAD")
		 set MPC_TXT_TYPE_CD = uar_get_code_by("MEANING", 53, "TXT")
		 set MPC_NUM_TYPE_CD = uar_get_code_by("MEANING", 53, "NUM")
		 set MPC_IMMUN_TYPE_CD = uar_get_code_by("MEANING", 53, "IMMUN")
		 set MPC_MED_TYPE_CD = uar_get_code_by("MEANING", 53, "MED")
		 set MPC_DATE_TYPE_CD = uar_get_code_by("MEANING", 53, "DATE")
		 set MPC_DONE_TYPE_CD = uar_get_code_by("MEANING", 53, "DONE")
		 set MPC_MBO_TYPE_CD = uar_get_code_by("MEANING", 53, "MBO")
		 set MPC_PROCEDURE_TYPE_CD = uar_get_code_by("MEANING", 53, "PROCEDURE")
		 set MPC_GRP_TYPE_CD = uar_get_code_by("MEANING", 53, "GRP")
		 set MPC_HLATYPING_TYPE_CD = uar_get_code_by("MEANING", 53, "HLATYPING")
		 set eventClassCdPopulated = 1
	endif
	declare sViewerFlag = vc with protect, noconstant("")
 
	case(eventClassCd)
		of MPC_AP_TYPE_CD:
			set sViewerFlag = "AP"
		of MPC_DOC_TYPE_CD:
		of MPC_MDOC_TYPE_CD:
		of MPC_RAD_TYPE_CD:
			set sViewerFlag = "DOC"
		of MPC_TXT_TYPE_CD:
		of MPC_NUM_TYPE_CD:
		of MPC_IMMUN_TYPE_CD:
		of MPC_MED_TYPE_CD:
		of MPC_DATE_TYPE_CD:
		of MPC_DONE_TYPE_CD:
			set sViewerFlag = "EVENT"
		of MPC_MBO_TYPE_CD:
			set sViewerFlag = "MICRO"
		of MPC_PROCEDURE_TYPE_CD:
			set sViewerFlag = "PROC"
		of MPC_GRP_TYPE_CD:
			set sViewerFlag = "GRP"
		of MPC_HLATYPING_TYPE_CD:
			set sViewerFlag = "HLA"
		else
			set sViewerFlag = "STANDARD"
	endcase
 
	if(eventClassCd = MPC_MDOC_TYPE_CD)
		select into "nl:"
			c2.*
		from clinical_event c1
			,clinical_event c2
		plan c1 where c1.event_id = eventId
		join c2 where c1.parent_event_id = c2.event_id
			and c2.valid_until_dt_tm = cnvtdatetime("31-DEC-2100")
 
		head c2.event_id
			if(c2.event_class_cd = MPC_AP_TYPE_CD)
				sViewerFlag = "AP"
			endif
		with nocounter
	endif
 
	call log_message(build("Exit returnViewerType(), Elapsed time in seconds:",
	datetimediff(cnvtdatetime(curdate,curtime3),BEGIN_DATE_TIME, 5)), LOG_LEVEL_DEBUG)
 
	return(sViewerFlag)
end
 
/**
 * cnvtIsoDtTmToDQ8()
 * Purpose:
 *   Converts an ISO 8601 formatted date into a DQ8
 *
 * @return {dq8, which is the same as a f8}
 *
 * @param {vc} isoDtTmStr ISO 8601 formatted string (ie, 2013-10-24T15:08:77Z)
*/
subroutine cnvtIsoDtTmToDQ8(isoDtTmStr)
	declare convertedDq8 = dq8 with protect, noconstant(0)
 
	set convertedDq8 =
		cnvtdatetimeutc2(substring(1,10,isoDtTmStr),"YYYY-MM-DD",substring(12,8,isoDtTmStr),"HH:MM:SS", 4, CURTIMEZONEDEF)
 
	return(convertedDq8)
 
end  ;subroutine cnvtIsoDtTmToDQ8
 
 
/**
 * cnvtDQ8ToIsoDtTm()
 * Purpose:
 *   Converts a DQ8 into an ISO 8601 formatted date string
 *
 * @return {vc}
 *
 * @param {f8, which is the same as a dq8} dq8DtTm DateTime Value
*/
subroutine cnvtDQ8ToIsoDtTm(dq8DtTm)
	declare convertedIsoDtTm = vc with protect, noconstant("")
 
	set convertedIsoDtTm = build(replace(datetimezoneformat(cnvtdatetime(dq8DtTm) ,
		DATETIMEZONEBYNAME("UTC"),"yyyy-MM-dd HH:mm:ss",curtimezonedef)," ","T",1),"Z")
 
	return(convertedIsoDtTm)
 
end  ;subroutine cnvtDQ8ToIsoDtTm
 
/**
 *GetOrgSecurityFlag
 *Purpose:
 *	detecting if organization security is enabled
 *  @return {i2} authorizedOrganizations record
*/
subroutine GetOrgSecurityFlag(null)
	declare org_security_flag = i2 with noconstant(0), protect
	select into "nl:"
	from dm_info di
	where di.info_domain = "SECURITY"
	  and di.info_name = "SEC_ORG_RELTN"
	head report
		org_security_flag = 0
	detail
	  	org_security_flag = cnvtint(di.info_number)
	with nocounter
	return (org_security_flag)
end
 
/**
 *GetCompOrgSecurityFlag
 *Purpose:
 *	detecting if organization security is enabled
 *  @return {i2} authorizedOrganizations record
*/
subroutine GetCompOrgSecurityFlag(dminfo_name)
	declare org_security_flag = i2 with noconstant(0), protect
	select into "nl:"
	from dm_info di
	where di.info_domain = "SECURITY"
	  and di.info_name = dminfo_name
	head report
		org_security_flag = 0
	detail
	  	org_security_flag = cnvtint(di.info_number)
	with nocounter
	return (org_security_flag)
end
 
/**
 *PopulateAuthorizedOrganizations
 *Purpose:
 *	get authorized organization Ids for a personnel
 *
 *
 *  @param {f8} personnel_id value
 *	@param {vc} authorizedOrganizations record
*/
;free record authorizedOrganizations
;record authorizedOrganizations
;(
;	1 cnt					= i4
;	1 organizations[*]
;		2 organizationId	= f8
;)
subroutine PopulateAuthorizedOrganizations(personId, value_rec)
	declare organization_cnt = i4 with noconstant(0), protect
	select into "nl:"
      from prsnl_org_reltn por
      where por.person_id = personId
      	and por.active_ind = 1
      	and (por.beg_effective_dt_tm between cnvtdatetime(lower_bound_date) and cnvtdatetime(curdate,curtime3))
    	and (por.end_effective_dt_tm between cnvtdatetime(curdate,curtime3) and cnvtdatetime(upper_bound_date))
      order by por.organization_id
    head report
    	organization_cnt = 0
    detail
      organization_cnt = organization_cnt + 1
      if (mod(organization_cnt, 20) = 1)
        stat = alterlist(value_rec->organizations, organization_cnt + 19)
      endif
 
      value_rec->organizations[organization_cnt].organizationId = por.organization_id
    foot report
	  value_rec->cnt = organization_cnt
      stat = alterlist(value_rec->organizations, organization_cnt)
    with nocounter
    if (validate(debug_ind, 0) = 1)
		call echorecord(value_rec)
	endif
end
 
/**
 *GetUserLogicalDomain
 *Purpose:
 *	this subroutine obtains the user's logical domain if needed
 *
 *  @return {f8}
 *  @param {f8} person_id value
*/
subroutine GetUserLogicalDomain(id)
 
	declare returnId = f8 with protect, noconstant(0.0)
 
	select into "nl:"
	from prsnl p
	where p.person_id = id
 
	detail
		returnId = p.logical_domain_id
 
	with nocounter
 
	return (returnId)
 
end ;GetUserLogicalDomain
 
 
 
;%i cclsource:mp_script_logging.inc
 
/***********************************************************************
 *   Parameter Variables                                               *
 ***********************************************************************/
  declare log_program_name  = vc with protect, noconstant("")
  declare log_override_ind  = i2 with protect, noconstant(0)
 
/***********************************************************************
 *   Initialize Parameters                                             *
 ***********************************************************************/
  set log_program_name = CURPROG
  set log_override_ind = 0
 
/***********************************************************************
 *   Initialize Constants                                              *
 ***********************************************************************/
  declare LOG_LEVEL_ERROR   = i2 with protect, noconstant(0)
  declare LOG_LEVEL_WARNING = i2 with protect, noconstant(1)
  declare LOG_LEVEL_AUDIT   = i2 with protect, noconstant(2)
  declare LOG_LEVEL_INFO    = i2 with protect, noconstant(3)
  declare LOG_LEVEL_DEBUG   = i2 with protect, noconstant(4)
 
/***********************************************************************
 *   Initialize Logging and Error() Function                           *
 ***********************************************************************/
  declare hSys     = i4 with protect, noconstant(0)
  declare SysStat  = i4 with protect, noconstant(0)
  declare sErrMsg  = c132 with protect, noconstant(" ")
  declare iErrCode = i4 with protect, noconstant(Error(sErrMsg, 1))
 
  declare CRSL_MSG_DEFAULT = i4 with protect, noconstant(0)
  declare CRSL_MSG_LEVEL   = i4 with protect, noconstant(0)
 
  execute msgrtl
  set CRSL_MSG_DEFAULT = uar_MsgDefHandle ()
  set CRSL_MSG_LEVEL   = uar_MsgGetLevel (CRSL_MSG_DEFAULT)
 
/************************************************************************
 *   Initialize other variables.  These were moved here since a declare *
 *   statement cannot be used within a subroutine called from within    *
 *   detail clauses (as these subroutines are).                         *
 ***********************************************************************/
  declare lCRSLSubEventCnt       = i4 with protect, noconstant(0)
  declare iCRSLLoggingStat       = i2 with protect, noconstant(0)
  declare lCRSLSubEventSize      = i4 with protect, noconstant(0)
  declare iCRSLLogLvlOverrideInd = i2 with protect, noconstant(0)
  declare sCRSLLogText           = vc with protect, noconstant("")
  declare sCRSLLogEvent          = vc with protect, noconstant("")
  declare iCRSLHoldLogLevel      = i2 with protect, noconstant(0)
  declare iCRSLErrorOccured      = i2 with protect, noconstant(0)
  declare lCRSLUarMsgwriteStat   = i4 with protect, noconstant(0)
 
/***********************************************************************
 *   Read the DM_INFO table for the program name.  This will eliminate *
 *   the need for scripts to read for a DM_INFO row to turn on script  *
 *   logging override.                                                 *
 *   Simply setup the DM_INFO row as follows to turn on logging:       *
 *     INFO_DOMAIN = "PATHNET SCRIPT LOGGING"                          *
 *     INFO_NAME   = ccl program name in all uppercase                 *
 *     INFO_CHAR   = "L"                                               *
 ***********************************************************************/
  declare CRSL_INFO_DOMAIN    = vc with protect, constant("DISCERNABU SCRIPT LOGGING")
  declare CRSL_LOGGING_ON     = c1 with protect, constant("L")
 
if(LOGICAL("MP_LOGGING_ALL") > " " OR LOGICAL(concat("MP_LOGGING_", log_program_name)) > " ")
	set log_override_ind = 1
endif
 
 
DECLARE LOG_MESSAGE(LogMsg=VC,LogLvl=I4) = NULL
/***********************************************************************
 *   LOG_MESSAGE routine is called to write out a log message to       *
 *   msgview.  The log message and message level should be passed in   *
 *   the corresponding parameters.  The routine will use the string    *
 *   stored in log_program_name as the script.  It will also override  *
 *   the log level passed in if the log_override_ind is set to 1.      *
 ***********************************************************************/
subroutine LOG_MESSAGE(LogMsg, LogLvl)
 
  ; Initialize override flag
  set iCRSLLogLvlOverrideInd = 0
 
  ; Build log message in form "{{Script::ScriptName}} Log Message"
  set sCRSLLogText = ""
  set sCRSLLogEvent = ""
  set sCRSLLogText = CONCAT("{{Script::", VALUE(log_program_name), "}} ", LogMsg)
 
  ; Determine the appropriate log level at which to write message
  if (log_override_ind = 0)
    set iCRSLHoldLogLevel = LogLvl               ; write using passed in log level
  else
    if (CRSL_MSG_LEVEL < LogLvl)
      set iCRSLHoldLogLevel = CRSL_MSG_LEVEL  ; write using server log level (override)
      set iCRSLLogLvlOverrideInd = 1
    else
      set iCRSLHoldLogLevel = LogLvl             ; write using passed in log level
    endif
  endif
 
  ; Write log message using appropriate log level
  if (iCRSLLogLvlOverrideInd = 1)
    set sCRSLLogEvent = "Script_Override"
  else
    case (iCRSLHoldLogLevel)
      of LOG_LEVEL_ERROR:
         set sCRSLLogEvent = "Script_Error"
      of LOG_LEVEL_WARNING:
         set sCRSLLogEvent = "Script_Warning"
      of LOG_LEVEL_AUDIT:
         set sCRSLLogEvent = "Script_Audit"
      of LOG_LEVEL_INFO:
         set sCRSLLogEvent = "Script_Info"
      of LOG_LEVEL_DEBUG:
         set sCRSLLogEvent = "Script_Debug"
    endcase
  endif
 
  set lCRSLUarMsgwriteStat =
    uar_MsgWrite(CRSL_MSG_DEFAULT, 0, nullterm(sCRSLLogEvent), iCRSLHoldLogLevel, nullterm(sCRSLLogText))
    call echo(LogMsg)
 
end ; LOG_MESSAGE subroutine
 
/***************/
 
 
DECLARE ERROR_MESSAGE(LogStatusBlockInd = i2) = i2
/***********************************************************************
 *   The ERROR_MESSAGE routine is called to check for CCL errors after *
 *   a CCL select statement.  If errors are found, this routine will   *
 *   write the error to msgview and the subeventstatus block in the    *
 *   reply record.                                                     *
 ***********************************************************************/
subroutine ERROR_MESSAGE(LogStatusBlockInd)
 
  set iCRSLErrorOccured = 0
 
  ; Check for CCL error
  set iErrCode = Error(sErrMsg, 0)
  while (iErrCode > 0)
    set iCRSLErrorOccured = 1
    if(validate(reply))
      set reply->status_data->status = "F"
    endif
 
    ; Write CCL error message to msgview
    call log_message(sErrMsg, log_level_audit)
 
    ; Write CCL errors to subeventstatus block if it exists
    if (LogStatusBlockInd = 1)
      ; write error to subeventstatus
	  if(validate(reply))  ;validate reply exists before attempting to populate subeventstatus
        call populate_subeventstatus("EXECUTE", "F", "CCL SCRIPT", sErrMsg)
	  endif
    endif
 
    ; Retrieve additional CCL errors
    set iErrCode = Error(sErrMsg, 0)
  endwhile
 
  return(iCRSLErrorOccured)
 
end ; ERROR_MESSAGE subroutine
 
 /***************/
 
DECLARE ERROR_AND_ZERO_CHECK_REC(QualNum = i4,
                             OpName = vc,
                             LogMsg = vc,
                             ErrorForceExit = i2,
                             ZeroForceExit = i2,
                             RecordData = vc (REF)) = i2
/***********************************************************************
 *   The ERROR_AND_ZERO_CHECK routine is called to check for           *
 *   CCL errors or zero rows after a CCL select statement.             *
 *   If errors are found, this routine will                            *
 *   write the error to msgview and the subeventstatus block in the    *
 *   record structure provided                                         *
 ***********************************************************************/
subroutine ERROR_AND_ZERO_CHECK_REC(QualNum, OpName, LogMsg,
                                ErrorForceExit, ZeroForceExit,RecordData)
  set iCRSLErrorOccured = 0
 
  ; Check for CCL error
  set iErrCode = Error(sErrMsg, 0)
  while (iErrCode > 0)
    set iCRSLErrorOccured = 1
 
    ; Write CCL error message to msgview
    call log_message(sErrMsg, log_level_audit)
 
    ; write error to subeventstatus
    call populate_subeventstatus_rec(OpName, "F", sErrMsg, LogMsg, RecordData)
 
    ; Retrieve additional CCL errors
    set iErrCode = Error(sErrMsg, 0)
  endwhile
 
  if (iCRSLErrorOccured = 1 and ErrorForceExit = 1)
  	set RecordData->status_data->status = "F"
    go to exit_script
  endif
 
  ; Check for Zero Returned
 
  if (QualNum = 0 and ZeroForceExit = 1)
  	set RecordData->status_data->status = "Z"
    ; write error to subeventstatus
    call populate_subeventstatus_rec(OpName, "Z", "No records qualified", LogMsg, RecordData)
    go to exit_script
  endif
 
 
  return(iCRSLErrorOccured)
end
 
 /***************/
 
DECLARE ERROR_AND_ZERO_CHECK(QualNum = i4,
                             OpName = vc,
                             LogMsg = vc,
                             ErrorForceExit = i2,
                             ZeroForceExit = i2) = i2
/***********************************************************************
 *   The ERROR_AND_ZERO_CHECK routine is called to check for           *
 *   CCL errors or zero rows after a CCL select statement.             *
 *   If errors are found, this routine will                            *
 *   write the error to msgview and the subeventstatus block in the    *
 *   reply record.                                                     *
 ***********************************************************************/
subroutine ERROR_AND_ZERO_CHECK(QualNum, OpName, LogMsg, ErrorForceExit, ZeroForceExit)
  return(ERROR_AND_ZERO_CHECK_REC(QualNum, OpName, LogMsg,ErrorForceExit, ZeroForceExit, reply))
end ; ERROR_AND_ZERO_CHECK subroutine
 
 
declare POPULATE_SUBEVENTSTATUS_REC(OperationName = vc (value),
                                OperationStatus = vc (value),
                                TargetObjectName = vc (value),
                                TargetObjectValue = vc (value),
                                RecordData = vc(REF)) = i2
 
/***************************************************************************
*   The POPULATE_SUBEVENTSTATUS_REC routine is called to fill out an entry *
*   in the subeventstatus list of a standard record.                       *
***************************************************************************/
subroutine POPULATE_SUBEVENTSTATUS_REC(OperationName, OperationStatus, TargetObjectName, TargetObjectValue, RecordData)
 
  /* Validate that status block exists */
  if (validate(RecordData->status_data->status, "-1") != "-1")
    /* get current size of subevent status */
    set lCRSLSubEventCnt = size(RecordData->status_data->subeventstatus, 5)
 
    /* If last item in array is populated, then increase the size of the array by one.
       Otherwise, assume it is an empty item in the list and use it. */
    set lCRSLSubEventSize = size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].OperationName))
    set lCRSLSubEventSize = lCRSLSubEventSize +
      size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].OperationStatus))
    set lCRSLSubEventSize = lCRSLSubEventSize +
      size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].TargetObjectName))
    set lCRSLSubEventSize = lCRSLSubEventSize +
      size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].TargetObjectValue))
 
    if (lCRSLSubEventSize > 0)
      set lCRSLSubEventCnt = lCRSLSubEventCnt + 1
      set iCRSLLoggingStat = alter(RecordData->status_data->subeventstatus, lCRSLSubEventCnt)
    endif
 
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].OperationName =
      substring(1, 25, OperationName)
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].OperationStatus =
      substring(1, 1, OperationStatus)
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].TargetObjectName =
      substring(1, 25, TargetObjectName)
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].TargetObjectValue =
      TargetObjectValue
  endif
 
end ; POPULATE_SUBEVENTSTATUS subroutine
 
/***************/
 /***************/
 
 declare POPULATE_SUBEVENTSTATUS(OperationName = vc (value),
                                OperationStatus = vc (value),
                                TargetObjectName = vc (value),
                                TargetObjectValue = vc (value)) = i2
/***********************************************************************
*   The POPULATE_SUBEVENTSTATUS routine is called to fill out an entry *
*   in the subeventstatus list of a standard reply.                    *
************************************************************************/
subroutine POPULATE_SUBEVENTSTATUS(OperationName, OperationStatus, TargetObjectName, TargetObjectValue)
  call POPULATE_SUBEVENTSTATUS_REC(OperationName, OperationStatus, TargetObjectName, TargetObjectValue, reply)
end ; POPULATE_SUBEVENTSTATUS subroutine
 
/***************/
 
declare POPULATE_SUBEVENTSTATUS_MSG(OperationName = vc (value),
                                    OperationStatus = vc (value),
                                    TargetObjectName = vc (value),
                                    TargetObjectValue = vc (value),
                                    LogLevel = i2 (value)) = i2
/***************************************************************************
*   The POPULATE_SUBEVENTSTATUS_MSG routine is called to fill out an entry *
*   in the subeventstatus list of a standard reply and to write the        *
*   TargetObjectValue argument to the message log                          *
****************************************************************************/
subroutine POPULATE_SUBEVENTSTATUS_MSG(OperationName, OperationStatus, TargetObjectName, TargetObjectValue, LogLevel)
 
  call populate_subeventstatus(OperationName, OperationStatus, TargetObjectName, TargetObjectValue)
  call log_message(TargetObjectValue, LogLevel)
 
 
end ; POPULATE_SUBEVENTSTATUS_MSG subroutine
 
/***************/
 
DECLARE CHECK_LOG_LEVEL( arg_log_level = i4 ) = i2
/****************************************************************************
*   The CHECK_LOG_LEVEL routine determines if message will be written at a  *
*   given level.                                                            *
****************************************************************************/
subroutine CHECK_LOG_LEVEL(arg_log_level)
  if( CRSL_MSG_LEVEL  >= arg_log_level
   or log_override_ind = 1)
    return (1)  ;The log_level is sufficient to log messages or override is turned on
  else
    return (0)  ;The log_level is not sufficient to log messages
  endif
 
end ; CHECK_LOG_LEVEL subroutine
 
/*************************************************************************
* Subroutine Declarations                                                *
*************************************************************************/
declare ConvertStrDateToIsoFormat(date = vc) = vc with protect
 
/*************************************************************************
* Record Structures                                                      *
*************************************************************************/
/*
record request
(
%i cclsource:hi_get_person_demogr_req.inc
)
*/
 
if (not validate(reply))
record reply
(
;%i cclsource:hi_get_person_demogr_rep.inc
1 person_id = f8
1 hi_person_identifier = vc
1 given_names[*]
  2 given_name = vc
1 family_names[*]
  2 family_name = vc
1 full_name = vc
1 date_of_birth = vc
1 gender_details
  2 id = vc
  2 coding_system_id = vc
1 address
  2 street_addresses[*]
    3 street_address = vc
  2 type
    3 id = vc
    3 coding_system_id = vc
  2 city = vc
  2 state_or_province_details
    3 id = vc
    3 coding_system_id = vc
  2 postal_code = vc
  2 county_or_parish = vc
  2 county_or_parish_details
    3 id = vc
    3 coding_system_id = vc
  2 country_details
    3 id = vc
    3 coding_system_id = vc
1 telecoms[*]
  2 preferred = vc
  2 number = vc
  2 country_code = vc
  2 type
    3 id = vc
    3 coding_system_id = vc
    3 display = vc
1 email_addresses[*]
  2 address = vc
  2 type
    3 id = vc
    3 coding_system_id = vc
1 health_plans[*]
  2 mill_health_plan_id = f8
  2 payer_name = vc
  2 plan_name = vc
  2 begin_iso_dt_tm = vc
  2 end_iso_dt_tm = vc
  2 member_nbr = vc
  2 line_of_business = vc
  2 source
    3 contributing_organization = vc
    3 partition_description = vc
    3 type = vc
  2 plan_identifiers[*]
    3 value = vc
    3 type = vc
;%i cclsource:status_block.inc
1 status_data
    2 status = c1
    2 subeventstatus[1]
      3 OperationName = c25
      3 OperationStatus = c1
      3 TargetObjectName = c25
      3 TargetObjectValue = vc
)
endif
 
free record person_demogr_reply
record person_demogr_reply
(
;%i cclsource:hi_proxy_reply_common.inc
  1 transactionStatus
    2 successInd = ui1
    2 debugErrorMessage = vc
    2 prereqErrorInd = ui1
  1 httpReply
    2 version = vc
    2 status = ui2
    2 statusReason = vc
    2 httpHeaders[*]
      3 name = vc
      3 value = vc
    2 body = gvc
)
 
/*************************************************************************
*  Variable Declarations                                                 *
*************************************************************************/
;call echorecord(request)
 
declare PERSON_DEMOGRAPHICS_TEST_URI = vc with protect, constant(request->demographics_test_uri)
declare PERSON_ID = f8 with protect, constant(request->person_id)
declare HI_PERSON_IDENTIFIER = vc with protect, constant(request->hi_person_identifier)
declare HI_BENEFIT_FILTER_SOURCE_TYPE = vc with protect, constant(request->benefit_coverage_source_type)
declare PERSON_DEMOGRAPHICS_REQUEST_KEY = vc with protect, constant("hi_record_api_person_demographics")
declare HI_EMPI_LOOKUP_KEY = vc with protect, constant("hi_record_person_empi_lookup")
 
declare person_demographics = gvc with protect, noconstant("")
declare person_demographic_parameters = vc with protect, noconstant("empi_person_id=")
declare bc_idx = i4 with protect, noconstant(0)
declare plan_idx = i4 with protect, noconstant(0)
declare plan_cnt = i4 with protect, noconstant(0)
declare plan_value = vc with protect, noconstant("")
declare plan_type = vc with protect, noconstant("")
declare hi_proxy_error_message = vc with protect, noconstant("")
 
/*************************************************************************
*  Begin Program                                                         *
*************************************************************************/
 
;call echo ("made it to start of program: person demographics")
 
set reply->person_id = PERSON_ID
set reply->hi_person_identifier = HI_PERSON_IDENTIFIER
set reply->status_data->status = "F"
 
;call echorecord(reply)
 
; The component is coded to pass in the service key if uri is not set in bedrock.
if (textlen(trim(PERSON_DEMOGRAPHICS_TEST_URI)) > 0)
 
call echo ("made it to start of program: execute get http request via URI")
 
  execute hi_http_proxy_get_request "MINE", PERSON_DEMOGRAPHICS_TEST_URI
    with replace("PROXYREPLY", person_demogr_reply)
else
  if (PERSON_ID = 0 and textlen(trim(HI_PERSON_IDENTIFIER)) = 0)
    set reply->status_data->subeventstatus[1]->TargetObjectValue = "Missing valid person id or HI person identifer"
    go to END_SCRIPT
  endif
 
  if (textlen(trim(HI_PERSON_IDENTIFIER)) > 0)
    set person_demographic_parameters = concat(person_demographic_parameters, trim(HI_PERSON_IDENTIFIER))
 
    if (textlen(trim(HI_BENEFIT_FILTER_SOURCE_TYPE)) > 0)
      set person_demographic_parameters =
        build2(person_demographic_parameters, ";", "benefit_coverages.type=", trim(HI_BENEFIT_FILTER_SOURCE_TYPE))
    endif
 
    execute hi_http_proxy_get_request "MINE", PERSON_DEMOGRAPHICS_REQUEST_KEY, "JSON", 0.0, 0.0,
      person_demographic_parameters with replace("PROXYREPLY", person_demogr_reply)
  else
    if (PERSON_ID > 0)
      ; call hi_alias_lookup to get record api demographics url in the aliasLookupReply.
      execute hi_alias_lookup "MINE", HI_EMPI_LOOKUP_KEY, PERSON_DEMOGRAPHICS_REQUEST_KEY, PERSON_ID
 
      ; For a successful response, call the record api demographics endpoint
      if (aliasLookupReply->status_data->status = "S")
        if (textlen(trim(request->benefit_coverage_source_type)) > 0)
          set aliasLookupReply->hiUri = build2(aliasLookupReply->hiUri,
            "&benefit_coverages.type=", HI_BENEFIT_FILTER_SOURCE_TYPE)
        endif
 
        execute hi_http_proxy_get_request "MINE", aliasLookupReply->hiUri, "JSON"
            with replace("PROXYREPLY", person_demogr_reply)
 
      ; For a successful response, but no HealtheIntent person was found.
      elseif(aliasLookupReply->status_data->status = "P")
        set reply->status_data->status = "Z"
        go to END_SCRIPT
 
      else
        set reply->status_data->status = "F"
        set reply->status_data->subeventstatus[1]->targetObjectName =
          aliasLookupReply->status_data->subeventstatus[1]->targetObjectName
        set reply->status_data->subeventstatus[1]->targetObjectValue =
          aliasLookupReply->status_data->subeventstatus[1]->targetObjectValue
        call log_message(build2("httpReply->status: ", person_demogr_reply->httpReply->status), LOG_LEVEL_ERROR)
        call log_message(person_demogr_reply->httpReply->body, LOG_LEVEL_ERROR)
 
        go to END_SCRIPT
      endif
    endif
  endif
endif
 
;call echorecord (person_demogr_reply)
 
;declare temp=vc
;set temp = person_demogr_reply->httpreply->body
;call echo (build("temp:", temp) )
 
/*
 
set temp=vc
set temp= person_demogr_reply->httpreply->body)
call echo (build("temp:", temp) )
 
>>>Begin EchoRecord PERSON_DEMOGR_REPLY   ;PERSON_DEMOGR_REPLY
 1 TRANSACTIONSTATUS
  2 SUCCESSIND=UI1   {1}
  2 DEBUGERRORMESSAGE=VC0   {}
  2 PREREQERRORIND=UI1   {0}
 1 HTTPREPLY
  2 VERSION=VC8   {HTTP/1.1}
  2 STATUS=UI2   {200}
  2 STATUSREASON=VC2   {OK}
  2 HTTPHEADERS[1,24*]
   3 NAME=VC12   {Content-Type}
   3 VALUE=VC31   {application/json; charset=utf-8}
  2 HTTPHEADERS[2,24*]
   3 NAME=VC17   {Transfer-Encoding}
   3 VALUE=VC7   {chunked}
  2 HTTPHEADERS[3,24*]
   3 NAME=VC10   {Connection}
   3 VALUE=VC10   {keep-alive}
  2 HTTPHEADERS[4,24*]
   3 NAME=VC4   {Date}
   3 VALUE=VC29   {Sun, 10 Oct 2021 06:13:34 GMT}
  2 HTTPHEADERS[5,24*]
   3 NAME=VC13   {Cache-Control}
   3 VALUE=VC35   {max-age=0, private, must-revalidate}
  2 HTTPHEADERS[6,24*]
   3 NAME=VC21   {Cerner-Correlation-Id}
   3 VALUE=VC36   {b72c01c8-688b-42b2-b8be-0b2fbf1cae6d}
  2 HTTPHEADERS[7,24*]
   3 NAME=VC4   {Etag}
   3 VALUE=VC36   {W/"b139657fe9e01c2b0328a963e3c9b818"}
  2 HTTPHEADERS[8,24*]
   3 NAME=VC15   {Referrer-Policy}
   3 VALUE=VC31   {strict-origin-when-cross-origin}
  2 HTTPHEADERS[9,24*]
   3 NAME=VC6   {Server}
   3 VALUE=VC25   {nginx + Phusion Passenger}
  2 HTTPHEADERS[10,24*]
   3 NAME=VC6   {Status}
   3 VALUE=VC6   {200 OK}
  2 HTTPHEADERS[11,24*]
   3 NAME=VC25   {Strict-Transport-Security}
   3 VALUE=VC35   {max-age=31536000; includeSubDomains}
  2 HTTPHEADERS[12,24*]
   3 NAME=VC22   {X-Content-Type-Options}
   3 VALUE=VC7   {nosniff}
  2 HTTPHEADERS[13,24*]
   3 NAME=VC18   {X-Download-Options}
   3 VALUE=VC6   {noopen}
  2 HTTPHEADERS[14,24*]
   3 NAME=VC15   {X-Frame-Options}
   3 VALUE=VC10   {SAMEORIGIN}
  2 HTTPHEADERS[15,24*]
   3 NAME=VC19   {X-Newrelic-App-Data}
   3 VALUE=VC136   {PxQGVlRSDAcCR1NRBAgBU1QGBBFORCANXhZKDVRUUUAcBEkIHhFWDRRaUk4VC1dEEkhRTAcdB0hVCQYA}
                   {UlZaVwFSCFYICgwBAUkUUB1DBVsFBwYAA1YAAQgCBQYAAxVKAlBaQAc7}
  2 HTTPHEADERS[16,24*]
   3 NAME=VC33   {X-Permitted-Cross-Domain-Policies}
   3 VALUE=VC4   {none}
  2 HTTPHEADERS[17,24*]
   3 NAME=VC12   {X-Powered-By}
   3 VALUE=VC17   {Phusion Passenger}
  2 HTTPHEADERS[18,24*]
   3 NAME=VC12   {X-Request-Id}
   3 VALUE=VC36   {d1516ffb-1cc1-4573-8215-fced6b4b433a}
  2 HTTPHEADERS[19,24*]
   3 NAME=VC9   {X-Runtime}
   3 VALUE=VC8   {0.179382}
  2 HTTPHEADERS[20,24*]
   3 NAME=VC16   {X-Xss-Protection}
   3 VALUE=VC13   {1; mode=block}
  2 HTTPHEADERS[21,24*]
   3 NAME=VC7   {X-Cache}
   3 VALUE=VC20   {Miss from cloudfront}
  2 HTTPHEADERS[22,24*]
   3 NAME=VC3   {Via}
   3 VALUE=VC64   {1.1 c923d89f70351e442aa1b87e2d6434f8.cloudfront.net (CloudFront)}
  2 HTTPHEADERS[23,24*]
   3 NAME=VC12   {X-Amz-Cf-Pop}
   3 VALUE=VC8   {ATL56-C1}
  2 HTTPHEADERS[24,24*]
   3 NAME=VC11   {X-Amz-Cf-Id}
   3 VALUE=VC56   {GGgH0vYtAuNB_LWHBI4yo-496Udu7dJrG1Z59N6VhmWGUO4nXf9QXA==}
  2 BODY=VC37991   {{"prefix":null,"suffix":null,"full_name":"NEWTON, TINA MARIE","given_names":["TI}
 
*/
 
if (person_demogr_reply->transactionStatus->successInd = 1 and person_demogr_reply->httpReply->status = 200)
  set person_demographics = concat('{"demographics_data":', person_demogr_reply->httpReply->body, '}')
  set stat = cnvtjsontorec(person_demographics)
else ;failed executing hi_http_proxy_get_request
  set hi_proxy_error_message = "person_demogr_reply->httpReply->body: "
  set hi_proxy_error_message = concat(hi_proxy_error_message, person_demogr_reply->httpReply->body)
  set hi_proxy_error_message = concat(hi_proxy_error_message, person_demogr_reply->transactionStatus->debugErrorMessage)
 
  call log_message(build2("person_demogr_reply->status: ", person_demogr_reply->httpReply->status), LOG_LEVEL_ERROR)
  call log_message(build2("Debug error message: ", person_demogr_reply->transactionStatus->debugErrorMessage)
    ,LOG_LEVEL_ERROR)
 
  set reply->status_data->subeventstatus[1]->targetObjectName = "ERROR_EXECUTING_HI_HTTP_PROXY_GET_REQUEST"
  set reply->status_data->subeventstatus[1]->targetObjectValue = hi_proxy_error_message
 
  go to END_SCRIPT
endif
 
; Map given names from person data to the reply structure.
if (validate(demographics_data->given_names))
  set given_names_size = size(demographics_data->given_names, 5)
  set stat = alterlist(reply->given_names, given_names_size)
  for (given_names_idx = 1 to given_names_size)
    set reply->given_names[given_names_idx]->given_name =
      demographics_data->given_names[given_names_idx]
  endfor
endif
 
; Map family names from person data to the reply structure.
if (validate(demographics_data->family_names))
  set family_names_size = size(demographics_data->family_names, 5)
  set stat = alterlist(reply->family_names, family_names_size)
  for (family_names_idx = 1 to family_names_size)
    set reply->family_names[family_names_idx]->family_name =
      demographics_data->family_names[family_names_idx]
  endfor
endif
 
if (validate(demographics_data->full_name) and demographics_data->full_name)
  set reply->full_name = demographics_data->full_name
endif
 
if (validate(demographics_data->date_of_birth) and demographics_data->date_of_birth)
  set reply->date_of_birth = demographics_data->date_of_birth
endif
 
; Map gender details from person data to the reply structure for hcm_ens_person_from_hi script.
if (validate(demographics_data->gender) and demographics_data->gender)
 
  if (validate(demographics_data->gender->id) and demographics_data->gender->id)
    set reply->gender_details->id = demographics_data->gender->id
  endif
 
  if (validate(demographics_data->gender->code_system_id) and demographics_data->gender->code_system_id)
    set reply->gender_details->coding_system_id =
      demographics_data->gender->code_system_id
  endif
endif
 
; Map street addresses from person data to the reply structure.
if (validate(demographics_data->address) and demographics_data->address)
 
  if (validate(demographics_data->address->street_addresses))
    set street_addresses_size = size(demographics_data->address->street_addresses, 5)
    set stat = alterlist(reply->
      address->street_addresses, street_addresses_size)
    for (street_addresses_idx = 1 to street_addresses_size)
      set reply->address->
        street_addresses[street_addresses_idx]->street_address =
        demographics_data->address->street_addresses[street_addresses_idx]
    endfor
  endif
 
  ; Map other address information from person data to the reply structure.
  if (validate(demographics_data->address->type) and demographics_data->address->type)
 
    if (validate(demographics_data->address->type->id) and demographics_data->address->type->id)
      set reply->address->type->id = demographics_data->address->type->id
    endif
 
    if (validate(demographics_data->address->type->code_system_id) and demographics_data->address->type->code_system_id)
      set reply->address->type->coding_system_id =
        demographics_data->address->type->code_system_id
    endif
  endif
 
  if (validate(demographics_data->address->city) and demographics_data->address->city)
    set reply->address->city = demographics_data->address->city
  endif
 
  if (validate(demographics_data->address->state_or_province) and demographics_data->address->state_or_province)
 
    if (validate(demographics_data->address->state_or_province->id) and demographics_data->address->state_or_province->id)
      set reply->address->state_or_province_details->id =
        demographics_data->address->state_or_province->id
    endif
 
    if (validate(demographics_data->address->state_or_province->code_system_id)
      and demographics_data->address->state_or_province->code_system_id)
 
      set reply->address->state_or_province_details->coding_system_id =
        demographics_data->address->state_or_province->code_system_id
    endif
  endif
 
  if (validate(demographics_data->address->postal_code) and demographics_data->address->postal_code)
    set reply->address->postal_code = demographics_data->address->postal_code
  endif
 
  if (validate(demographics_data->address->county_or_parish) and demographics_data->address->county_or_parish)
 
    if (validate(demographics_data->address->county_or_parish->display) and demographics_data->address->county_or_parish->display)
      set reply->address->county_or_parish =
        demographics_data->address->county_or_parish->display
    endif
 
    if (validate(demographics_data->address->county_or_parish->id) and demographics_data->address->county_or_parish->id)
      set reply->address->county_or_parish_details->id =
        demographics_data->address->county_or_parish->id
    endif
 
    if (validate(demographics_data->address->county_or_parish->code_system_id)
      and demographics_data->address->county_or_parish->code_system_id)
 
      set reply->address->county_or_parish_details->coding_system_id =
        demographics_data->address->county_or_parish->code_system_id
    endif
  endif
 
  if (validate(demographics_data->address->country) and demographics_data->address->country)
    if (validate(demographics_data->address->country->id) and demographics_data->address->country->id)
      set reply->address->country_details->id =
        demographics_data->address->country->id
    endif
 
    if (validate(demographics_data->address->country->code_system_id) and demographics_data->address->country->code_system_id)
      set reply->address->country_details->coding_system_id =
        demographics_data->address->country->code_system_id
    endif
  endif
endif
 
; Map telecom information from person data to the reply structure.
if (validate(demographics_data->telecoms))
  set telecoms_size = size(demographics_data->telecoms, 5)
  set stat = alterlist(reply->telecoms, telecoms_size)
  for (telecoms_idx = 1 to telecoms_size)
 
    if (validate(demographics_data->telecoms[telecoms_idx]->number) and demographics_data->telecoms[telecoms_idx]->number)
      set reply->telecoms[telecoms_idx]->number =
        demographics_data->telecoms[telecoms_idx]->number
    endif
 
    if (validate(demographics_data->telecoms[telecoms_idx]->type) and demographics_data->telecoms[telecoms_idx]->type)
 
      if (validate(demographics_data->telecoms[telecoms_idx]->type->id) and demographics_data->telecoms[telecoms_idx]->type->id)
        set reply->telecoms[telecoms_idx]->type->id =
          demographics_data->telecoms[telecoms_idx]->type->id
      endif
 
      if (validate(demographics_data->telecoms[telecoms_idx]->type->code_system_id)
        and demographics_data->telecoms[telecoms_idx]->type->code_system_id)
 
        set reply->telecoms[telecoms_idx]->type->coding_system_id =
          demographics_data->telecoms[telecoms_idx]->type->code_system_id
      endif
 
      if (validate(demographics_data->telecoms[telecoms_idx]->preferred))
        if (demographics_data->telecoms[telecoms_idx]->preferred = 1)
          set reply->telecoms[telecoms_idx]->preferred = "true"
        else
          set reply->telecoms[telecoms_idx]->preferred = "false"
        endif
      endif
 
      if (validate(demographics_data->telecoms[telecoms_idx]->country_code)
      and demographics_data->telecoms[telecoms_idx]->country_code)
        set reply->telecoms[telecoms_idx]->country_code =
          demographics_data->telecoms[telecoms_idx]->country_code
      endif
    endif
  endfor
endif
 
; Map email addresses from person data to the reply structure.
if (validate(demographics_data->emails))
  set email_addresses_size = size(demographics_data->emails, 5)
  set stat = alterlist(reply->email_addresses, email_addresses_size)
  for (email_addresses_idx = 1 to email_addresses_size)
 
    if (validate(demographics_data->emails[email_addresses_idx]->address)
 
    and demographics_data->emails[email_addresses_idx]->address)
      set reply->email_addresses[email_addresses_idx]->address =
        demographics_data->emails[email_addresses_idx]->address
    endif
 
    if (validate(demographics_data->emails[email_addresses_idx]->type) and demographics_data->emails[email_addresses_idx]->type)
 
      if (validate(demographics_data->emails[email_addresses_idx]->type->id)
      and demographics_data->emails[email_addresses_idx]->type->id)
        set reply->email_addresses[email_addresses_idx]->type->id =
          demographics_data->emails[email_addresses_idx]->type->id
      endif
 
      if (validate(demographics_data->emails[email_addresses_idx]->type->code_system_id)
        and demographics_data->emails[email_addresses_idx]->type->code_system_id)
        set reply->
          email_addresses[email_addresses_idx]->type->coding_system_id =
          demographics_data->emails[email_addresses_idx]->type->code_system_id
      endif
    endif
  endfor
endif
 
if (validate(demographics_data->benefit_coverages))
  set benefit_coverages_size = size(demographics_data->benefit_coverages, 5)
  set stat = alterlist(reply->health_plans, benefit_coverages_size)
 
  for (bc_idx = 1 to benefit_coverages_size)
    ; payer_name
    if (validate(demographics_data->benefit_coverages[bc_idx]->payer_name)
      and demographics_data->benefit_coverages[bc_idx]->payer_name)
 
      set reply->health_plans[bc_idx]->payer_name = demographics_data->benefit_coverages[bc_idx]->payer_name
    endif
 
    ; plan_name
    if (validate(demographics_data->benefit_coverages[bc_idx]->plan_name)
      and demographics_data->benefit_coverages[bc_idx]->plan_name)
 
      set reply->health_plans[bc_idx]->plan_name = demographics_data->benefit_coverages[bc_idx]->plan_name
    endif
 
    ; begin_iso_dt_tm
    if (validate(demographics_data->benefit_coverages[bc_idx]->begin_date)
      and demographics_data->benefit_coverages[bc_idx]->begin_date)
 
      set reply->health_plans[bc_idx]->begin_iso_dt_tm =
        ConvertStrDateToIsoFormat(demographics_data->benefit_coverages[bc_idx]->begin_date)
    endif
 
    ; end_iso_dt_tm
    if (validate(demographics_data->benefit_coverages[bc_idx]->end_date)
      and demographics_data->benefit_coverages[bc_idx]->end_date)
 
      set reply->health_plans[bc_idx]->end_iso_dt_tm =
        ConvertStrDateToIsoFormat(demographics_data->benefit_coverages[bc_idx]->end_date)
    endif
 
    ; member_nbr
    if (validate(demographics_data->benefit_coverages[bc_idx]->member_id)
      and demographics_data->benefit_coverages[bc_idx]->member_id)
 
      set reply->health_plans[bc_idx]->member_nbr = demographics_data->benefit_coverages[bc_idx]->member_id
    endif
 
    ; line_of_business
    if (validate(demographics_data->benefit_coverages[bc_idx]->line_of_business)
      and demographics_data->benefit_coverages[bc_idx]->line_of_business)
 
      set reply->health_plans[bc_idx]->line_of_business = demographics_data->benefit_coverages[bc_idx]->line_of_business
    endif
 
    ; source
    if (validate(demographics_data->benefit_coverages[bc_idx]->source)
      and demographics_data->benefit_coverages[bc_idx]->source)
 
      if (demographics_data->benefit_coverages[bc_idx]->source->contributing_organization)
        set reply->health_plans[bc_idx]->source->contributing_organization =
          demographics_data->benefit_coverages[bc_idx]->source->contributing_organization
      endif
 
      if (demographics_data->benefit_coverages[bc_idx]->source->partition_description)
        set reply->health_plans[bc_idx]->source->partition_description =
          demographics_data->benefit_coverages[bc_idx]->source->partition_description
      endif
 
      if (demographics_data->benefit_coverages[bc_idx]->source->type)
        set reply->health_plans[bc_idx]->source->type =
          demographics_data->benefit_coverages[bc_idx]->source->type
      endif
    endif
 
    ; plan_id array
    set plan_cnt = size(demographics_data->benefit_coverages[bc_idx]->plan_ids, 5)
 
    set stat = alterlist(reply->health_plans[bc_idx]->plan_identifiers, plan_cnt)
 
    for (plan_idx = 1 to plan_cnt)
      if ((validate(demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->value)
        and demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->value)
        and (validate(demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->type)
        and demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->type))
 
        set plan_value = demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->value
        set plan_type = demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->type
 
        set reply->health_plans[bc_idx]->plan_identifiers[plan_idx]->value = plan_value
        set reply->health_plans[bc_idx]->plan_identifiers[plan_idx]->type = plan_type
      endif
    endfor
  endfor
endif ; end (validate(demographics_data->benefit_coverages))
 
set reply->status_data->status = "S"
 
/*
 * Converts a string date format to ISO datetime format.
 *
 * Example:
 *   ConvertStrDateToIsoFormat("2015-05-05")
 *     => "2015-05-05T05:00:00Z"
 */
subroutine ConvertStrDateToIsoFormat(date)
  declare cnvt_date = vc with protect
 
  set cnvt_date = cnvtDQ8ToIsoDtTm(cnvtdatetime(cnvtdate2(date,"YYYY-MM-DD"), 0))
  return (cnvt_date)
end
 
#END_SCRIPT
 
if (validate(debug_ind, 0) = 1)
  call echorecord(reply)
endif
 
set last_mod = "001"
set mod_date = "January 31, 2017"
 
end
go