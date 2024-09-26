this_Vax_hx = ''
vaxhx_template = '<ul class="list-unstyled timeline">\
	<li>\
		<div class="block">\
			<div class="tags">\
				<a href="" class="tag">\
					<span>doseOrdinal</span>\
				</a>\
			</div>\
			<div class="block_content">\
				<h2 class="title"><b>\
					<i class="fas fa-syringe"></i>\
					<a>VaccineName</a>\
				</b></h2>\
				<h4>\
					<a><b><i class="fas fa-calendar-check"></i> Admin Date:</b></a>\
					<a>ADMINDATE</a>\
				</h4>\
				<h4>\
					<a><b><i class="fas fa-calendar-check"></i> Days Since Admin:</b></a>\
					<a>DAYSSINCEADMIN</a>\
				</h4>\
			</div>\
		</div>\
	</li>\
</ul>'
//Wrappers for all fields
var questionaire = $('#questionaire');
var allergicReaction = $('#allergicReaction')
var anaphylaxis = $('#anaphylaxis')
var feverQuestion = $('#feverQuestion')
var factSheetQuestion = $('#factSheetQuestion')
var vaxToAdminister = $('#vaxToAdminister')
var stopMessage = $('#stopMessage')
var stopOverrideDiv = $('#stopOverrideDiv')
var timeFrameLabel = $('#timeFrameLabel')
var vaxCountSelectorDiv = $('#vaxCountSelectorDiv')
var immunoCompromiseDiv = $('#immunoCompromiseDiv')
var vaxTypeSelector = $('#vaxTypeSelector')
var noVaxRecQuestion = $('#noVaxRecQuestion')
var confirmVaxhx = $('#confirmVaxhx')
var stopDocVax = $('#stopDocVax')
var consultProviderDiv = $('#consultProvider')
var immunoCompEligible = 0
var notImunoCompEligible = 0
var immunoCompResult = ''
var vaxHxConfirmCheckValue = ''

var preferredVax = ""
var preferredVaxSynonymId = 0
var alternateVax = ""
var alternateVaxSynonymId = 0
var preferenceInd = 1

var iCPreferredVaxName = ""
var iCPreferredVaxSynonym = 0
var iCAltVaxName = ""
var iCAltVaxSynonym = 0
var iCPrefInd = 1

var notICPreferredVaxName = ""
var notICPreferredVaxSynonym = 0
var notICAltVaxName = ""
var notICAltVaxSynonym = 0
var notICPrefInd = 1
var existingOrderId = 0
var btnCancelOverride = $('.btnCancelOverride')
var override_vaxName1 = ""
var override_vaxName2 = ""
var override_provider_id = 0
var override_provider_name = ''



var vaxConfirmCheck = $('input:radio[name=vaxConfirmCheck]');
var qAllergicReactionCheck = $('input:radio[name=qAllergicReactionCheck]');
var qAnaphylaxisCheck = $('input:radio[name=qAnaphylaxisCheck]');
var qFeverCheck = $('input:radio[name=qFeverCheck]');
var qFactSheetCheck = $('input:radio[name=qFactSheetCheck]');


var immunoCompCheck = $('input:radio[name=immunoCompCheck]');
var vaxHxConfirmCheck = $('input:radio[name=vaxHxConfirmCheck]');

var questionaireRadio = $('.questionaireRadio input:radio')
var monovalentCount = 0
var bivalentCount = 0
var ccl_monovalentCount = 0
var ccl_bivalentCount = 0

var pfizerMonovalentCount = 0
var pfizerBivalentCount = 0
var modernaMonovalentCount = 0
var modernaBivalentCount = 0

var ccl_pfizerMonovalentCount = 0
var ccl_pfizerBivalentCount = 0
var ccl_modernaMonovalentCount = 0
var ccl_modernaBivalentCount = 0


var patAge = 0
var monthsSinceAdmin = -1
var personid = 0
var encounterid = 0
var use_ccl_timeframe = 0

var allergicReactionValue = ""
var anaphylaxisValue = ""
var feverValue = ""
var factSheetValue = ""

var firstVax = ""
var firstVaxClass = "btn-success"
var secondVax = ""
var secondVaxClass = "btn-success"


var pfizerCount = ""
var pfizer2324Count = ""
var modernaCount = ""
var moderna2324Count = ""
var oldVaxCount = ""
var vax2324Count = ""
var override = 0

$(document).ready(function () {
	testimonial_ok = false;
	//getVaxHx()
	var patientSearch = window.external.DiscernObjectFactory("PVPATIENTSEARCHMPAGE"); //creates patient search object  
	var searchResult = patientSearch.SearchForPatientAndEncounter(); //launches patient search dialog and assigns the returned object to a variable when the dialog closes.  
	 if(searchResult.PersonId > 0 && searchResult.EncounterId >= 0){ //checks to make sure a valid patient id and encounter id were returned.  
		 personid = searchResult.PersonId 
		 encounterid = searchResult.EncounterId
	// // alert(personid)
	// // alert(encounterid)
		 getVaxHx(personid, encounterid)
	 }
	//personid = '31663399'
	//encounterid = '269469463'
	// 5331953053.00// //alert("")
	getVaxHx(personid, encounterid)
	// //Inputs that determine what fields to show

	//Open patient chart
	$('#immSchedule').click(function (e) {
		Lib.openChart(personid, encounterid, "Immunization Schedule")
	})

	$('.btnOverride').click(function (e) {
		questionaireRadio.prop('checked', false);
		qAnaphylaxisCheck.prop('checked', false);
		qFeverCheck.prop('checked', false);
		qFactSheetCheck.prop('checked', false);
		qAllergicReactionCheck.prop('checked', false);
		anaphylaxis.addClass('hidden')
		feverQuestion.addClass('hidden')
		factSheetQuestion.addClass('hidden')
		vaxToAdminister.addClass('hidden')
		if (confirm("Please confirm override. You will be asked to provider tha name of Provider who approved this override if you continue!") == true) {
			override = 1
			questionaire.removeClass('hidden');
			consultProviderDiv.removeClass('hidden')
			//allergicReaction.removeClass('hidden');
			btnCancelOverride.removeClass('hidden');
			stopMessage.addClass('hidden');
			stopDocVax.addClass('hidden');
			$('.btnOverride').prop('disabled', true)
			preferredVax = override_vaxName1
			alternateVax = override_vaxName2
			preferenceInd = 0
		}
		else {
			override = 0
			questionaire.addClass('hidden');
			consultProviderDiv.addClass('hidden')
			allergicReaction.addClass('hidden');
			btnCancelOverride.addClass('hidden');
			stopMessage.removeClass('hidden');

			vaxTypeSelector.addClass('hidden');
			$('.btnOverride').prop('disabled', false)
		}
	})

	btnCancelOverride.click(function (e) {
		questionaireRadio.prop('checked', false);
		qAnaphylaxisCheck.prop('checked', false);
		qFeverCheck.prop('checked', false);
		qFactSheetCheck.prop('checked', false);
		$('.btnOverride').prop('disabled', false)
		override = 0
		questionaire.addClass('hidden');
		consultProviderDiv.addClass('hidden')
		allergicReaction.addClass('hidden');
		btnCancelOverride.addClass('hidden');
		vaxTypeSelector.addClass('hidden');
		$('#consultPrsnl').val("")		
		override_provider_id = 0
		override_provider_name = ''
		preferredVax = ""
		alternateVax = ""
		if (vaxHxConfirmCheckValue == 'no') {
			stopDocVax.removeClass('hidden');
		} else {
			stopMessage.removeClass('hidden');
		}

	})

	$('.orderSubmitBtn').click(function (e) {
		try {
			//alert("Work in progress. Button has not been configured to place order.")
			vaxText = $(this).text()
			vax_type = ""
			switch (vaxText) {
				case "Pfizer 6m-4yrs":
					vax_type = "Pfizer 6m-4yrs"
					break;
				case "Pfizer 12yrs+":
					vax_type = "Pfizer 12yrs Plus"
					break;
				case "Moderna 12yrs+":
					vax_type = "Moderna 12yrs Plus"
					break;
				case "Moderna 6m-11yr":
					vax_type = "Moderna 6m-11yr"
					break;
				case "Pfizer 5yr-11yr":
					vax_type = "Pfizer 5yr-11yr"
					break;
			}
			//if(consultPrsnl
			//if(vax_type == "Moderna 6m-11yr" || vax_type == "Moderna 12yrs Plus"){
			sReq = '{"request_in":{"person_id":' + personid + ',"encntr_id":' + encounterid + ',"vax_type":"' + vax_type + '", "allergic_reaction":"' + allergicReactionValue + '","anaphylaxis":"' + anaphylaxisValue + 
			'","fever":"' + feverValue + '","fact_sheet":"' + factSheetValue +'","override_ind":"' + override + '","override_provider_name":"' + override_provider_name + '","override_provider_id":"' + override_provider_id +'"}}'
			ccl_param = ['^MINE^', '^writeVaccine^,^' + sReq + '^']
			Lib.makeCall("14_mp_covid_vax_advisor_test2", ccl_param.join(), true, function (reply) {
				questionaireRadio.disabled = true;
				$('#firstVaxBtn').prop('disabled', true)//.disabled = true; 
				$('#secondVaxBtn').prop('disabled', true)//.disabled = true;  				
				alert("Order placed successfully")
			})
			// }
			// else{
			// alert("Pfizer is not currently available for ordering")
			// }
		}
		catch (e) {
			alert(e.message)
		}
	})


	$('#consultPrsnlSearch').click(function (e) {
		$('#consultProviderModal').modal('show');
	})

	$('body').on('click', '.consultPrsnlSelect', function (e) {
		$('#consultPrsnl').val($(this).attr('sName'))
		override_provider_id = $(this).attr('prsnlId')
		override_provider_name = $(this).attr('sName')
		$("#consultPrsnl").attr("prsnlId", $(this).attr('prsnlId'));
		$('#consultProviderModal').modal('hide')
		if ($('#consultPrsnl').val() != "") {
			allergicReaction.removeClass('hidden');
		}
	})


	$('#srcBtn').click(function (e) {
		consultPrsnlSearchFName = $('#consultPrsnlSearchFName').val()
		consultPrsnlSearchLName = $('#consultPrsnlSearchLName').val()
		sReq = '{"request_in":{"firstName":"' + consultPrsnlSearchFName + '","lastName":"' + consultPrsnlSearchLName + '"}}'
		paramSend = ['^MINE^', '^SearchPrsnl^', '^' + sReq + '^']
		Lib.makeCall("14_mp_covid_vax_advisor_test2", paramSend.join(), true, function (reply) {
			try {
				replyJson = $.parseJSON(reply);
				//alert(JSON.stringify(replyJson))
				tableWidgetJson({
					"widgetName": "consultProviderSearchTable",
					"pageLevel": "ORG",
					"headerName": "MedStartMpages",
					"queryObject": "14_mp_covid_vax_advisor_test2",
					"paramString": paramSend,
					"record": "reply",
					"tagName": "items",
					"tableName": "consultProviderSearchTable",
					"jsonObject": replyJson,
					"tableOptions": {
						"responsive": true,
						"processing": true,
						"bAutoWidth": true,
						"paging": true,
						"Processing": true,
						"iDisplayLength": 25,
						"order": [
							[0, 'asc']
						],
						"dom": "Bfrtip"
					},
					"aoColumnDefs": [
						{
							"sTitle": "",
							"aTargets": [0],
							"mData": "sName",
							"render": function (data, type, row) {
								return '<button prsnlId="' + row.dPSId + '" sName ="' + row.sName + '" class="consultPrsnlSelect"  type="button"><i class="fas fa-edit"></i> Select</button>'
							}
						},
						{
							"sTitle": "Personnel Name",
							"aTargets": [1],
							"mData": "sName"
						},
						{
							"sTitle": "Position",
							"aTargets": [2],
							"mData": "sPos"
						},
						{
							"sTitle": "Username",
							"aTargets": [3],
							"mData": "sUsername"
						}
					],
					"buttons": [
						{
							extend: 'pageLength'
						}
					],
					"divName": "divConsultProviderSearchTable"
				});
			}
			catch (e) {
				alert(e.message)
			}
		})
	})


	vaxHxConfirmCheck.change(function () {
		value = this.value;
		vaxHxConfirmCheckValue = value
		qAnaphylaxisCheck.prop('checked', false);
		qFeverCheck.prop('checked', false);
		qFactSheetCheck.prop('checked', false);

		vaxCountSelectorDiv.addClass('hidden');
		immunoCompCheck.prop('checked', false);
		questionaireRadio.prop('checked', false);

		allergicReaction.addClass('hidden');
		stopMessage.addClass('hidden');
		stopOverrideDiv.addClass('hidden');
		consultProviderDiv.addClass('hidden');

		stopDocVax.addClass('hidden');
		vaxTypeSelector.addClass('hidden');
		questionaire.addClass('hidden');
		qAllergicReactionCheck.prop('checked', false);
		immunoCompromiseDiv.addClass('hidden');
		try {
			if (value == 'yes') {
				if (existingOrderId == 0) {
					immunoCompromiseDiv.removeClass('hidden');
				}
				else {
					$('#stopMessageText').html("This patient already has an active vaccine order.  If you don’t see the order/task, please refresh and look again.").addClass('red')
					$('#stopMessage').removeClass('hidden')
					stopOverrideDiv.removeClass('hidden');
					questionaireRadio.disabled = true;
					$('#firstVaxBtn').disabled = true;
					$('#secondVaxBtn').disabled = true;
				}
			}
			else if (value == 'no') {
				stopOverrideDiv.removeClass('hidden');
				stopDocVax.removeClass('hidden');
				$('.btnOverride').prop('disabled', false)
			}
		} catch (e) {
			alert(e.message)
		}
	});

	immunoCompCheck.change(function () {
		btnCancelOverride.addClass('hidden');
		value = this.value;
		immunoCompResult = value
		anaphylaxis.addClass('hidden')
		feverQuestion.addClass('hidden')
		factSheetQuestion.addClass('hidden')
		vaxToAdminister.addClass('hidden')
		stopMessage.addClass('hidden');
		stopOverrideDiv.addClass('hidden');
		consultProviderDiv.addClass('hidden');
		allergicReaction.addClass('hidden');

		qAllergicReactionCheck.prop('checked', false);
		questionaireRadio.prop('checked', false);
		qAnaphylaxisCheck.prop('checked', false);
		qFeverCheck.prop('checked', false);
		qFactSheetCheck.prop('checked', false);

		monovalentCount = parseInt(monovalentCount)
		bivalentCount = parseInt(bivalentCount)
		// alertMessage = "pfizerCount: "+pfizerCount +"\n pfizer2324Count: "+pfizer2324Count+ "\n modernaCount: "+modernaCount+ "\n moderna2324Count: "+moderna2324Count +"\n oldVaxCount:"+oldVaxCount+"\n vax2324Count:"+vax2324Count
		// +"\n notImunoCompEligible:"+notImunoCompEligible+"\n immunoCompEligible:"+immunoCompEligible
		// alert(alertMessage)
		if ((value == 'yes' && immunoCompEligible == 1) || (value == 'no' && notImunoCompEligible == 1)) {
			questionaire.removeClass('hidden');
			allergicReaction.removeClass('hidden');
			if (value == "yes") {
				preferredVax = iCPreferredVaxName
				preferredVaxSynonymId = iCPreferredVaxSynonym
				alternateVax = iCAltVaxName
				alternateVaxSynonymId = iCAltVaxSynonym
				preferenceInd = parseInt(iCPrefInd)
			}
			else {
				preferredVax = notICPreferredVaxName
				preferredVaxSynonymId = notICPreferredVaxSynonym
				alternateVax = notICAltVaxName
				alternateVaxSynonymId = notICAltVaxSynonym
				preferenceInd = parseInt(notICPrefInd)
			}
		}
		else {
			stopMessage.removeClass('hidden')
			stopOverrideDiv.removeClass('hidden');
			$('.btnOverride').prop('disabled', false)
		}
	});

	qAllergicReactionCheck.change(function () {
		value = this.value;
		allergicReactionValue = value
		anaphylaxis.addClass('hidden')
		feverQuestion.addClass('hidden')
		factSheetQuestion.addClass('hidden')
		vaxToAdminister.addClass('hidden')
		stopMessage.addClass('hidden');
		//stopOverrideDiv.addClass('hidden');
		//consultProviderDiv.addClass('hidden');

		qAnaphylaxisCheck.prop('checked', false);
		qFeverCheck.prop('checked', false);
		qFactSheetCheck.prop('checked', false);

		if (value == 'no') {
			anaphylaxis.removeClass('hidden');
			stopMessage.addClass('hidden');
		}
		else {
			stopMessage.removeClass('hidden');
		}
	});

	qAnaphylaxisCheck.change(function () {
		value = this.value;
		anaphylaxisValue = value
		feverQuestion.addClass('hidden')
		factSheetQuestion.addClass('hidden')
		vaxToAdminister.addClass('hidden')
		stopMessage.addClass('hidden');

		qFeverCheck.prop('checked', false);
		qFactSheetCheck.prop('checked', false);

		if (value == 'no' || value == 'yes') {
			feverQuestion.removeClass('hidden');
			stopMessage.addClass('hidden');
		}
		else {
			stopMessage.removeClass('hidden');
		}
	});

	qFeverCheck.change(function () {
		try {
			value = this.value;
			feverValue = value
			factSheetQuestion.addClass('hidden')
			vaxToAdminister.addClass('hidden')
			stopMessage.addClass('hidden');
			qFactSheetCheck.prop('checked', false);
			if (value == 'no') {
				factSheetQuestion.removeClass('hidden');
				stopMessage.addClass('hidden');
				$('#firstVaxBtn').html(preferredVax).addClass(firstVaxClass);//.removeClass("btn-success")
				$('#secondVaxBtn').html(alternateVax).addClass(secondVaxClass);//.removeClass("btn-success")
				if (preferenceInd == 1) {
					$('#secondVaxBtn').removeClass("btn-success").addClass("btn-info")
					$('#preferrencePointerDiv').removeClass('hidden')
					$('#alternativeDiv').removeClass('hidden')
				}
				else {
					$('#preferrencePointerDiv').addClass('hidden')
					$('#alternativeDiv').addClass('hidden')
				}
			}
			else {
				stopMessage.removeClass('hidden');
			}
		} catch (e) {
			alert(e.message)
		}
	});

	qFactSheetCheck.change(function () {
		value = this.value;
		factSheetValue = value
		vaxToAdminister.addClass('hidden')
		stopMessage.removeClass('hidden');

		if (value == 'yes') {
			vaxToAdminister.removeClass('hidden');
			stopMessage.addClass('hidden');
		}
		else {
			stopMessage.removeClass('hidden');
		}
	});


	//	value = this.value;
	//	vaxToAdminister.addClass('hidden');

	//	if (value == 'no') {
	//		//Something else here
	//		vaxToAdminister.removeClass('hidden');
	//	}
	//});	
});

function nth(n) {
	return ["st", "nd", "rd"][((n + 90) % 100 - 10) % 10 - 1] || "th"
}

function getTestData() {
	var testData = '{ "reply": { "regDt": "", "personId": 29787162.000000, "encntrId": 261992878.000000, "type": "bivalent", "orderId": 0.000000, "orderDetail": "", "daysFromOrder": 7, "passTimeframeReq": "no ", "vaxCount": 2, "monoVaxCount": 0, "modernaMonovalentCnt": 0, "modernaBivalentCnt": 0, "pfizerMonovalentCnt": 0, "pfizerBivalentCnt": 1, "pfizerCount": 1, "pfizer2324Count": 0, "modernaCount": 0, "moderna2324Count": 1, "oldVaxCount": 1, "vax2324Count": 1, "weekssincelastvax": 1.145053, "ageatfirstvax": 35.000000, "immunoCompEligible": 0, "notImunoCompEligible": 0, "notICPreferredVaxName": "", "notICPreferredVaxSynonym": 0.000000, "notICAltVaxName": "", "notICAltVaxSynonym": 0.000000, "notICPrefInd": 1, "iCPreferredVaxName": "Moderna 12yrs+", "iCPreferredVaxSynonym": 0.000000, "iCAltVaxName": "Pfizer 12yrs+", "iCAltVaxSynonym": 0.000000, "iCPrefInd": 1, "biVaxCount": 1, "patientName": "ZZZTESTDDC, NICOLE", "patientAge": 35.933607, "patientAgeVc": " 35 Years", "ageYear": 35, "items": [{ "orderName": "SARS-CoV-2(COVID-19)mRNA-LNP vac(cvx312)", "lotNum": "12345", "adminProvider": "Adeseye, Babatunde A", "adminDate": "01\/12\/2024", "daysFromOrder": "7", "type": "", "passTimeframeReq": "" }, { "orderName": "Pfizer-BioNTech COVID-19 (12y+) Bivalent Booster Vaccine PF", "lotNum": "", "adminProvider": "Coulter, RN, Diedre D.", "adminDate": "11\/06\/2023", "daysFromOrder": "74", "type": "", "passTimeframeReq": "" }] } }'
	return testData;
}
function getVaxHx(personid, encounterid) {
	//promptV = ['^MINE^,^'+personid+'^']
	//promptVal = "^MINE^, value($PAT_Personid$)"
	sReq = '{"request_in":{"person_id":' + personid + ',"encntr_id":' + encounterid + '}}'
	//sReq = '{"request_in":{"person_id":$PAT_PERSONID$ ,"encntr_id":$VIS_ENCNTRID$}}'
	//promptV = ['^MINE^,^'+personid+'^']
	//promptVal = "^MINE^, value($PAT_Personid$)"
	//sReq = '{"request_in":{"person_id":' + personid + ',"encntr_id":'+encounterid+'}}'	
	//sReq = '{"request_in":{"person_id":$PAT_PERSONID$ ,"encntr_id":$VIS_ENCNTRID$}}'
	ccl_param = ['^MINE^', '^getPatVaccine^,^' + sReq + '^']
	if (typeof (XMLCclRequest) === 'undefined') {
		processVax(getTestData())
	}
	else {
		Lib.makeCall("14_mp_covid_vax_advisor_test2", ccl_param.join(), true, function (reply) {
			processVax(reply)
		})
	}
}

function processVax(reply) {
	vaxReply = $.parseJSON(reply).reply;
	try {
		items = $.parseJSON(reply).reply.items;
		patAge = vaxReply.ageYear
		$('#patientName').text(vaxReply.patientName);
		$('#patientAge').text(vaxReply.patientAge);

		$('#monovalentCountLbl').text(vaxReply.monoVaxCount);
		$('#BivalentCountLbl').text(vaxReply.biVaxCount);
		monovalentCount = parseInt(vaxReply.monoVaxCount)
		bivalentCount = parseInt(vaxReply.biVaxCount)
		ccl_monovalentCount = vaxReply.monoVaxCount
		ccl_bivalentCount = vaxReply.biVaxCount

		pfizerBivalentCount = parseInt(vaxReply.pfizer2324Count)
		pfizerMonovalentCount = parseInt(vaxReply.pfizerCount)
		modernaBivalentCount = parseInt(vaxReply.modernaCount)
		modernaMonovalentCount = parseInt(vaxReply.moderna2324Count)
		ccl_modernaBivalentCount = vaxReply.modernaCount
		ccl_modernaMonovalentCount = vaxReply.moderna2324Count
		ccl_pfizerBivalentCount = vaxReply.pfizer2324Count
		ccl_pfizerMonovalentCount = vaxReply.pfizerCount
		$('#pfizer2324CountLbl').text(vaxReply.pfizer2324Count);
		$('#pfizerPre2324CountLbl').text(vaxReply.pfizerCount);
		$('#modernaPre2324CountLbl').text(vaxReply.modernaCount);
		$('#moderna2324CountLbl').text(vaxReply.moderna2324Count);

		notImunoCompEligible = vaxReply.notImunoCompEligible
		immunoCompEligible = vaxReply.immunoCompEligible

		pfizerCount = vaxReply.pfizerCount
		pfizer2324Count = vaxReply.pfizer2324Count
		modernaCount = vaxReply.modernaCount
		moderna2324Count = vaxReply.moderna2324Count
		oldVaxCount = vaxReply.oldVaxCount
		vax2324Count = vaxReply.vax2324Count

		iCPreferredVaxName = vaxReply.iCPreferredVaxName
		iCPreferredVaxSynonym = vaxReply.iCPreferredVaxSynonym
		iCAltVaxName = vaxReply.iCAltVaxName
		iCAltVaxSynonym = vaxReply.iCAltVaxSynonym
		iCPrefInd = vaxReply.iCPrefInd
		override_vaxName1 = vaxReply.overrideVax1
		override_vaxName2 = vaxReply.overrideVax2
		notICPreferredVaxName = vaxReply.notICPreferredVaxName
		notICPreferredVaxSynonym = vaxReply.notICPreferredVaxSynonym
		notICAltVaxName = vaxReply.notICAltVaxName
		notICAltVaxSynonym = vaxReply.notICAltVaxSynonym
		notICPrefInd = vaxReply.notICPrefInd

		personid = parseInt(vaxReply.personId)
		encounterid = parseInt(vaxReply.encntrId)
		existingOrderId = parseFloat(vaxReply.orderId)
		//alert(vaxReply.orderId)
		if (items.length > 0) {

			// monovalentCount = vaxReply.monoVaxCount
			// bivalentCount = vaxReply.biVaxCount
			this_Vax_hx = ''
			$.each(items, function (count, val) {
				copy_vaxhx_template = vaxhx_template
				if (count == 0) {
					copy_vaxhx_template = copy_vaxhx_template.replace('doseOrdinal', 'Last Dose')
				}
				else {
					copy_vaxhx_template = copy_vaxhx_template.replace('doseOrdinal', (items.length - count) + nth(items.length - count) + ' Dose')
				}
				copy_vaxhx_template = copy_vaxhx_template.replace('VaccineName', val.orderName)
				copy_vaxhx_template = copy_vaxhx_template.replace('ADMINDATE', val.adminDate)
				copy_vaxhx_template = copy_vaxhx_template.replace('DAYSSINCEADMIN', val.daysFromOrder)
				this_Vax_hx += copy_vaxhx_template
			})
			$('#vaccineHistoryDiv').html(this_Vax_hx)
			confirmVaxhx.removeClass('hidden')
			monthsSinceAdmin = vaxReply.daysFromOrder
			if (parseFloat(vaxReply.orderId) > 0) {
				//alert("herere")
				$('#confirmVaxhx').addClass('hidden')
				$('#stopMessageText').html("This patient already has an active vaccine order.  If you don’t see the order/task, please refresh and look again.").addClass('red')
				// $('#stopMessageText').addClass('red')
				$('#stopMessage').removeClass('hidden')
				questionaireRadio.disabled = true;
				$('#firstVaxBtn').disabled = true;
				$('#secondVaxBtn').disabled = true;
			}
		}
		else {
			$('#novaxhistoryLabel').removeClass('hidden')
		}
		if (existingOrderId > 0) {
			$('#stopMessageText').html("This patient already has an active vaccine order.  If you don’t see the order/task, please refresh and look again.").addClass('red')
			$('#confirmVaxhx').addClass('hidden')
			$('#stopMessage').removeClass('hidden')
			questionaireRadio.disabled = true;
			$('#firstVaxBtn').disabled = true;
			$('#secondVaxBtn').disabled = true;
		}
		//alert(thisCmnt)			
	}
	catch (e) {
		alert(e.message)
	}
}