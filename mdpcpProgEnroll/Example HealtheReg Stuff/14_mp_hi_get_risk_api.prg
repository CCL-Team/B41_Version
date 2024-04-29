drop program 14_mp_hi_get_risk_api go
create program 14_mp_hi_get_risk_api
/*--------------------------------------------------------------------------------------------------------------------------------
 Name           : 14_mp_hi_get_risk_api.prg
 Author:        : Simeon Akinsulie
 Date           : 03/07/2022
 Location       : cust_script
 
----------------------------------------------------------------------------------------------------------------------------------
 History
----------------------------------------------------------------------------------------------------------------------------------
 Ver  By   			Date        	Description
 ---  ---------  	----------  	-----------
 001  saa126  		02/24/2022  	Initial Release
 
 End History
----------------------------------------------------------------------------------------------------------------------------------
 
----------------------------------------------------------------------------------------------------------------------------------
Standard MPage Prompts
--------------------------------------------------------------------------------------------------------------------------------*/
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Person Id" = ""
 
with OUTDEV, person_id
 
execute 14_lib_error
 
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
declare OutputPhoneList(P1=VC(REF), P2=VC(REF))							= null with protect ;added P2? error in compile
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
/*--------------------------------------------------------------------------------------------------------------------------------
Declare record
--------------------------------------------------------------------------------------------------------------------------------*/
if (not validate(reply))
record reply
(
	1 health_plans[*]
	  2 value = vc
	  2 type = vc
	  2 hi_plan_name = vc
	  2 hi_plan_beg_date = vc
	1 status_data
    2 status = c1
    2 subeventstatus[1]
      3 OperationName = c25
      3 OperationStatus = c1
      3 TargetObjectName = c25
      3 TargetObjectValue = vc
)
endif
 
free record hi_get_hi_demographics_request
record hi_get_hi_demographics_request
(
;%i cclsource:hi_get_person_demogr_req.inc
1 person_id = f8
1 hi_person_identifier = vc
1 demographics_test_uri = vc
1 benefit_coverage_source_type = vc
)
 
free record hi_get_hi_demographics_reply
record hi_get_hi_demographics_reply
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
 
/*--------------------------------------------------------------------------------------------------------------------------------
Declare variables
--------------------------------------------------------------------------------------------------------------------------------*/
declare AT_RISK_PLAN_MNEMONIC = vc with protect, constant("HEALTHEINTENT") ;empanelment
declare person_id = f8 with protect, noconstant($person_id)
declare hi_person_identifier = vc with protect, noconstant("")
declare demographics_test_uri = vc with protect, noconstant("")
declare hi_benefit_coverages_cnt = i4 with protect, noconstant(0)
declare hi_benefit_coverages_idx = i4 with protect, noconstant(0)
declare hi_plan_ids_cnt = i4 with protect, noconstant(0)
declare hi_plan_ids_idx = i4 with protect, noconstant(0)
declare risk_benefit_coverages_idx = i4 with protect, noconstant(0)
declare risk_plan_ids_cnt = i4 with protect, noconstant(0)
declare risk_plan_ids_idx = i4 with protect, noconstant(0)
declare benefit_coverage_end_iso_dt_tm = vc with protect, noconstant("")
declare matched_at_risk_plan_cnt = i4 with protect, noconstant(0)
declare matched_at_risk_plan_id_cnt = i4 with protect, noconstant(0)
declare hi_plan_type = vc with protect, noconstant("")
declare hi_plan_value = vc with protect, noconstant("")
declare curr_hi_plan_name = vc with protect, noconstant("")
declare curr_hi_plan_date = vc with protect, noconstant("")
 
/*--------------------------------------------------------------------------------------------------------------------------------
Main Program
---------------------------------------------------------------------------------------------------------------------------------*/
if (person_id = 0 and textlen(trim(hi_person_identifier)) = 0 and textlen(trim(demographics_test_uri)) = 0)
  set reply->status_data->subeventstatus[1]->TargetObjectValue = "Missing valid person id or HI person identifer"
  go to END_SCRIPT
endif
 
;call echo ("made it to: ks_hs")
 
; Call hi_get_person_demogr.prg to get patients HI health plans
if (validate(person_id))
  set hi_get_hi_demographics_request->person_id = cnvtreal(person_id)
  set hi_get_hi_demographics_request->demographics_test_uri = demographics_test_uri
endif
 
;call echo ("made it to: validate person_id")
 
if (textlen(trim(hi_person_identifier)) > 0)
  set hi_get_hi_demographics_request->hi_person_identifier = hi_person_identifier
  set hi_get_hi_demographics_request->demographics_test_uri = demographics_test_uri
endif
 
;call echo ("made it to: validate person_identifier")
 
;call echo ("made it to: execute person demographics")
 
execute 14_mp_get_person_demogr with replace("REQUEST", hi_get_hi_demographics_request),
  replace("REPLY", hi_get_hi_demographics_reply)
 
;call echo ("made it to: back from person demographics")
 
if (hi_get_hi_demographics_reply->status_data->status = "Z")
  set reply->status_data->status = "Z"
  go to END_SCRIPT
elseif (hi_get_hi_demographics_reply->status_data->status = "S")
  set hi_benefit_coverages_cnt = size(hi_get_hi_demographics_reply->health_plans, 5)
  set stat = alterlist(reply->health_plans, hi_benefit_coverages_cnt)
 
  ; Loop 1 Patients HI health plans
  for(hi_benefit_coverages_idx = 1 to hi_benefit_coverages_cnt)
    set benefit_coverage_end_iso_dt_tm = hi_get_hi_demographics_reply->health_plans[hi_benefit_coverages_idx]->end_iso_dt_tm
    ; Only match on current health plans
    if (textlen(benefit_coverage_end_iso_dt_tm) = 0 or cnvtIsoDtTmToDQ8(benefit_coverage_end_iso_dt_tm) > CURRENT_DATE_TIME)
    ;active only
 
      ; Loop 2 Current HI health plan plan_identifiers array
      set hi_plan_ids_cnt = size(hi_get_hi_demographics_reply->health_plans[hi_benefit_coverages_idx]->plan_identifiers, 5)
      set curr_hi_plan_name = hi_get_hi_demographics_reply->health_plans[hi_benefit_coverages_idx]->plan_name
      set curr_hi_plan_date = hi_get_hi_demographics_reply->health_plans[hi_benefit_coverages_idx]->begin_iso_dt_tm
      set curr_hi_plan_date = substring(1,10,curr_hi_plan_date)
      for(hi_plan_ids_idx = 1 to hi_plan_ids_cnt)
        set hi_plan_type =
          hi_get_hi_demographics_reply->health_plans[hi_benefit_coverages_idx]->plan_identifiers[hi_plan_ids_idx]->type
        set hi_plan_value =
          hi_get_hi_demographics_reply->health_plans[hi_benefit_coverages_idx]->plan_identifiers[hi_plan_ids_idx]->value
        if(hi_plan_type = AT_RISK_PLAN_MNEMONIC)
          set matched_at_risk_plan_cnt = matched_at_risk_plan_cnt + 1
          set reply->health_plans[matched_at_risk_plan_cnt]->type = hi_plan_type
          set reply->health_plans[matched_at_risk_plan_cnt]->value = hi_plan_value
          set reply->health_plans[matched_at_risk_plan_cnt]->hi_plan_name = curr_hi_plan_name
          set reply->health_plans[matched_at_risk_plan_cnt]->hi_plan_beg_date = curr_hi_plan_date
        endif ; end comparison
      endfor ; End loop 2
    endif; end comparison
  endfor ; end loop 1
 
  ; Reset health_plans array back to size of matched at risk plans
  set stat = alterlist(reply->health_plans, matched_at_risk_plan_cnt)
else
  set reply->status_data->subeventstatus[1]->TargetObjectValue =
    build2(reply->status_data->subeventstatus[1]->TargetObjectValue, " ",
      hi_get_hi_demographics_reply->status_data->subeventstatus[1]->TargetObjectValue)
  go to END_SCRIPT
endif
 
;call echorecord (hi_get_hi_demographics_reply)
 
;call echorecord (reply)
 
set reply->status_data->status = "S"
 
#END_SCRIPT
/*--------------------------------------------------------------------------------------------------------------------------------
Check for errors and add them to record_data
--------------------------------------------------------------------------------------------------------------------------------*/
 
set stat = checkForErrors(null)
 
/*--------------------------------------------------------------------------------------------------------------------------------
 Output the record as json
--------------------------------------------------------------------------------------------------------------------------------*/
 
set _memory_reply_string = cnvtrectojson(reply, 4)
call echo(_memory_reply_string)
 
if (validate(debug_ind, 0) = 1)
  call echorecord(reply)
endif
 
 
end
go
 