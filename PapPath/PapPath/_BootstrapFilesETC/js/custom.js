/**
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */



var AppointmentTable;
var autoRefreshTgl;

var fromDate = moment().startOf('day').format('DD-MMM-YYYY HH:MM:SS'); 
var toDate = moment().endOf('day').format('DD-MMM-YYYY HH:MM:SS'); 
var popupWindowHandle;
function getPopupWindowHandle() {
	return popupWindowHandle;
}
XMLCclRequest = function(options) {
/************ Attributes *************/
	return window.external.XMLCclRequest();
}
XMLCCLREQUESTOBJECTPOINTER = [];	
	
// /Sidebar

// Switchery

function init_switchery()
{
	autoRefreshTgl = new Switchery($('#autoRefreshTgl')[0], 	{
		size:"small",
		color: '#26B99A'
	});
}
// /Switchery
//$("div.toolbar2").html('<select style="float: left" name="select-filter" id="select-filter"><option value=""></option></select>');
 
            $('#tblActivity tbody').on( 'click', 'button', function () {
                var data = AppointmentTable.row( $(this).parents('tr') ).data();
                //alert( data[2] +"'s salary is: "+ data[ 5] );
                openChart(data[1]);
                //location.href = APPLINK(0,"Powerchart.exe","/PERSONID="+data[1] +"/FIRSTTAB=^PowerOrders+^")
            } );
            populateDDLPL();
 
           // populateDDLPhy();
 
           
            
            //alert(fromDate + ' - '+ toDate);
 
            $('#apptDTSel').on('apply.daterangepicker', function (ev, picker) {
                //NProgress.start();
                var date = new Date();
                fromDate = picker.startDate.format('DD-MMM-YYYY HH:MM:SS');
                toDate = picker.endDate.format('DD-MMM-YYYY HH:MM:SS');
                if(autoRefreshTgl.isChecked())
                {
                    loadPatients(fromDate, toDate,$("#select-practiceLoc").select2("val"), "no");
                }
            });
 
            $('#select-practiceLoc').on("change", function(e) {
                if(autoRefreshTgl.isChecked())
                {
                    loadPatients(fromDate, toDate,$("#select-practiceLoc").select2("val"), "no");
                }
                    //alert("Selected value is: "+$("#select-practiceLoc").select2("val"));
                // what you would like to happen
                });
            NProgress.done();
 
            var _link = document.createElement('a');
            var _relToAbs = function (el) {
                var url;
                var clone = $(el).clone()[0];
                var linkHost;
                if (clone.nodeName.toLowerCase() === 'link') {
                    _link.href = clone.href;
                    linkHost = _link.host;
                    // IE doesn't have a trailing slash on the host
                    // Chrome has it on the pathname
                    if (linkHost.indexOf('/') === -1 && _link.pathname.indexOf('/') !== 0) {
                        linkHost += '/';
                    }
                    clone.href = _link.protocol + "//" + linkHost + _link.pathname + _link.search;
                }
                return clone.outerHTML;
            };
 
 
 
            $('#refBtn').click(function () {
                loadPatients(fromDate, toDate,$("#select-practiceLoc").select2("val"),"yes");
            });
 
            $('#DatePrevBtn').click(function () {
                $('#apptDTSel').data('daterangepicker').setStartDate($('#apptDTSel').data('daterangepicker').startDate.add(-1, 'days').startOf('day').format('MM/DD/YYYY'));
                $('#apptDTSel').data('daterangepicker').setEndDate($('#apptDTSel').data('daterangepicker').startDate.endOf('day').format('MM/DD/YYYY'));
                fromDate = $('#apptDTSel').data('daterangepicker').startDate.startOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
                toDate = $('#apptDTSel').data('daterangepicker').endDate.endOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
                loadPatients(fromDate, toDate,$("#select-practiceLoc").select2("val"),"no");
            });
 
            $('#DateNextBtn').click(function () {
                $('#apptDTSel').data('daterangepicker').setStartDate($('#apptDTSel').data('daterangepicker').startDate.add(1, 'days').startOf('day').format('MM/DD/YYYY'));
                $('#apptDTSel').data('daterangepicker').setEndDate($('#apptDTSel').data('daterangepicker').startDate.endOf('day').format('MM/DD/YYYY'));
                fromDate = $('#apptDTSel').data('daterangepicker').startDate.startOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
                toDate = $('#apptDTSel').data('daterangepicker').endDate.endOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
                loadPatients(fromDate, toDate,$("#select-practiceLoc").select2("val"),"no");
            });

		 
		/* SELECT2 */
	  
	function init_select2() {
		if( typeof (select2) === 'undefined'){ return; }
		console.log('init_toolbox');
			
		$(".select2_single").select2({
			placeholder: "Select a state",
			allowClear: true
		});
		$(".select2_group").select2({});
		$(".select2_multiple").select2({
			maximumSelectionLength: 4,
			placeholder: "With Max Selection limit 4",
			allowClear: true
		});		
	};	 
	
	/* DATA TABLES */
			
	function init_DataTables() {
		AppointmentTable = $('#tblActivity')
			.on('processing.dt', function ( e, settings, processing ) {
						$('#processingIndicator').css( 'display', processing ? 'block' : 'none' );
					} )
            .DataTable({
							responsive: true,
							"processing": true,
							"paging": true,
							"dom": '<"top"l<"toolbar2">f>rt<"bottom"ip><"clear">',
							"iDisplayLength": 25,
							emptyTable: "No Data to display....Please select Location and Date",
							"columnDefs": [
								{
										"targets": [1],
										"visible": false,
										"searchable": false
								},
								{
										"targets": [0],
										"data": null,
										"defaultContent":"<button class='fa fa-plus text-primary'></button>",
										"orderable": false
								},
								{
										"targets": [6],
										"data": null,
										"render": function ( data, type, row, meta ) {
										return type === 'display' && data[6].toLowerCase().trim() == "due"  ?
												'<i class="fa fa-heartbeat"></i>  '+data[6] :
														type === 'display' && data[6].toLowerCase().trim() == "not due"  ?
														'<i class="fa fa-heart"></i>  '+data[6]:
														data[6];
										}
								},
								{
										"targets": [8],
										"data": null,
										"render": function ( data, type, row, meta ) {
										return type === 'display' && data[8].toLowerCase().trim() == "due"  ?
												'<i class="fa fa-heartbeat"></i>  '+data[8] :
														type === 'display' && data[8].toLowerCase().trim() == "not due"  ?
														'<i class="fa fa-heart"></i>  '+data[8]:
														data[8];
										}
								},
								{
										"targets": [10],
										"data": null,
										"render": function ( data, type, row, meta ) {
										return type === 'display' && data[10].toLowerCase().trim() == "due"  ?
												'<i class="fa fa-heartbeat"></i>  '+data[10] :
														type === 'display' && data[10].toLowerCase().trim() == "not due"  ?
														'<i class="fa fa-heart"></i>  '+data[10]:
														data[10];
										}
								}
							],
							"createdRow": function ( row, data, index ) {
								if (data[6].toLowerCase().trim() =="due" ) 
								{
									$(row).find('td:eq(5)').addClass('highlight');
								}
								if (data[8].toLowerCase().trim() =="due" ) 
								{
									$(row).find('td:eq(7)').addClass('highlight');
								}
								if(data[10].toLowerCase().trim() =="due" ) {
									$(row).find('td:eq(9)').addClass('highlight');
								}								
								if(data[18].toLowerCase().trim() =="due" ) {
									$(row).find('td:eq(17)').addClass('highlight');
								}
								if(data[17].toLowerCase().trim() =="due" ) {
									$(row).find('td:eq(16)').addClass('highlight');
								}
								var tbcStatus = data[16].trim().split(':')
								if(tbcStatus[0].toLowerCase().trim() =="current" ) {
									$(row).find('td:eq(15)').addClass('highlight');                            
								}
								var bp = data[15].trim().split('/');
								if(parseInt(bp[0]) >= 140 ||parseInt(bp[1]) >= 90){
									$(row).find('td:eq(14)').addClass('highlight');                            
								}
								var hga1c = data[13].trim().split(' ');
								if(parseInt(hga1c[0].trim()) >= 9){
									$(row).find('td:eq(12)').addClass('highlight');
								}
							}
						}
					);
	}
	function init_daterangepicker() 
	{
		var optionSet1 = {
			startDate: moment(),
			endDate: moment(),
			minDate: '01/01/2012',
			maxDate: '12/31/2020',
			dateLimit: {
				days: 60
			},
			showDropdowns: true,
			showWeekNumbers: true,
			timePicker: false,
			timePickerIncrement: 1,
			timePicker12Hour: true,
			ranges: {
				'Today': [moment(), moment()],
				'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
				'Last 7 Days': [moment().subtract(6, 'days'), moment()],
				'Last 30 Days': [moment().subtract(29, 'days'), moment()],
				'This Month': [moment().startOf('month'), moment().endOf('month')],
				'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
			},
			opens: 'right',
			buttonClasses: ['btn btn-default'],
			applyClass: 'btn-small btn-primary',
			cancelClass: 'btn-small',
			format: 'MM/DD/YYYY',
			separator: ' to ',
			locale: {
				applyLabel: 'Submit',
				cancelLabel: 'Clear',
				fromLabel: 'From',
				toLabel: 'To',
				customRangeLabel: 'Custom',
				daysOfWeek: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
				monthNames: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
				firstDay: 1
			}
		}; 
 
		$('#apptDTSel').daterangepicker(optionSet1);
	}

	function populateDDLPL()
	{
		var RS = null;
		RS = new XMLCclRequest();
		RS.onreadystatechange = function ()
		{
			if (RS.readyState == 4 || RS.readyState=="complete")
			{
				if (RS.status == 200)
				{
						tempObj = JSON.parse(RS.responseText);
						var replyObj = tempObj.RS;
						var locCnt = replyObj.QUAL.length;
						$('#select-practiceLoc').select2({
								placeholder: "Select a Location",
								width: 'resolve',
								data:$.map($(tempObj.RS.QUAL), function (obj) {
										obj.id = obj.id || obj.LOCATION_ID;
										obj.text = obj.text || obj.LOCATION_NAME; // replace name with the property used for the text
										return obj;
								}),
						});

				}
			}
		};
		RS.open('GET', 'saa126_mp_amb_locationsV2',true)
		try{
			var promptVal = "^MINE^";
			//cclData.send("^MINE^, 0, 0, value($USR_PersonId$), 1");
			//RS.send(promptVal)
			RS.send('MINE');
		}
		catch(e){
			alert(e.description);
			return;
			NProgress.done();
		}
	}

	function countUnique(iterable) {
		return new Set(iterable).size;
 }
 function getCounts(gender, arrData) {
		 var ThisCt = 0; // RESET THE COUNT
		 $.each(arrData, function(i2, val2) {
				 if (gender === val2.PATIENT_GENDER.toLowerCase().trim()) {
						 ThisCt++; // ADD ONE
				 }
		 });
		 return ThisCt;
 }
function getMinMax(array, type) 
{
	var out = [];
	array.forEach(function(el) { return out.push.apply(out, el[type]); }, []);
	return { min: Math.min.apply(null, out), max: Math.max.apply(null, out) };
}

function openChart(element) {
	APPLINK(0,"$APP_AppName$","/PERSONID="+element + " /ENCNTRID=" +
	""+ " /FIRSTTAB=^Quick Orders^")
}
 
function loadPatients(fromDate, toDate, selVal, isBtn)
{
	if(selVal == "-9999999999")
	{
		selVal = "ALL";
	}
	if(autoRefreshTgl.isChecked() || isBtn == "yes")
	{
		NProgress.done();
		NProgress.start();
		waitingDialog.show();
		var RS = null;
		RS = new XMLCclRequest();
		RS.onreadystatechange = function ()
		{
			if (RS.readyState == 4 || RS.readyState=="complete")
			{
				if (RS.status == 200)
				{
					var tempObj = JSON.parse(RS.responseText);
					var replyObj = tempObj.RS;
					var locCnt = replyObj.QUAL.length;
					var statCnt = replyObj.STATLIST.length;
					var statTotal = [];
					var arr = replyObj.STATLIST;
					arr = $.map(arr, function(o){ return o.HOUR; });
					var maxHour = Math.max.apply(this,arr);
					var minHour = Math.min.apply(this,arr);

					if(statCnt >0)
					{
						var statCategory = [];
						var timeAmPm = " AM";
						var time =0;
						if(((maxHour-minHour)+1) ==statCnt)
						{
							for(idx =0; idx<statCnt; idx++)
							{
								time = replyObj.STATLIST[idx].HOUR
								if(time >11)
								{
									timeAmPm = " PM";
									if(time!=12)
									{
										time = time - 12;
									}
								}
								statCategory.push(String(time)+timeAmPm)
								statTotal.push(replyObj.STATLIST[idx].TOTAL);
							}
						}
						else
						{
							var statAllHours = [];
							for(idx =minHour; idx<maxHour+1; idx++)
							{
									time = idx
									if(time > 11)
									{
									timeAmPm = " PM";
									if(time!=12)
									{
										time = time - 12;
									}
								}
								statCategory.push(String(time)+timeAmPm)
								var ThisTot = 0; // RESET THE COUNT
								$.each(replyObj.STATLIST, function(i2, val2) {
									if (idx === val2.HOUR) {
										ThisTot = ThisTot + val2.TOTAL
									};
								});
								statTotal.push(ThisTot);
							}
						}                                    
					}

					AppointmentTable.search('');
					AppointmentTable.clear().draw();
					var column = AppointmentTable.column(5);
					if(locCnt >0)
					{
						//waitingDialog.show();
						$("div.toolbar2").html('');
						var select = $('<select style="float: left" class="form-control input-sm" name="select-filter" id="select-filter"><option value=""></option></select>')
							.appendTo( $("div.toolbar2") )
							.on( 'change', function () {
											var val = $.fn.dataTable.util.escapeRegex(
													$(this).val()
											);
											column
													.search( val ? '^'+val+'$' : '', true, false )
													.draw();
									}
							);

							for(idx = 0; idx<locCnt; idx++)
							{
								AppointmentTable.row.add([
									'',
									replyObj.QUAL[idx].PERSON_ID,
									replyObj.QUAL[idx].APPT_TM,
									replyObj.QUAL[idx].PATIENT_NAME ,
									replyObj.QUAL[idx].PAT_AGE,
									replyObj.QUAL[idx].SCH_PROVIDER,
									replyObj.QUAL[idx].COL_SCRN_STATUS,
									replyObj.QUAL[idx].COL_SCRN_LACTN,
									replyObj.QUAL[idx].BRST_CAN_SCRN_STATUS,
									replyObj.QUAL[idx].BRST_CAN_SCRN_LACTN,
									replyObj.QUAL[idx].DM_EYEEXM_SCRN_STATUS,
									replyObj.QUAL[idx].DM_EYEEXM_LACTN,
									replyObj.QUAL[idx].HGA1C_DATE,
									replyObj.QUAL[idx].HGA1C_RESULT,
									replyObj.QUAL[idx].SYS_DIA_BPDATE,
									replyObj.QUAL[idx].SYS_DIA_BP,
									replyObj.QUAL[idx].SHX_TOBUSERES,
									replyObj.QUAL[idx].INFLUENZA_VACC,
									replyObj.QUAL[idx].PNEUMOVAX_VACC
								]);
							}
							var phyCnt = 0;
							column.data().unique().sort().each(function( d, j ){
								if(d.length!=0 )
								{
									phyCnt = phyCnt+1;
									select.append( '<option value="'+d+'">'+d+'</option>' )
								}
							});
							$("#statsRow").css("display","inline");
							$(".sparkline_one").sparkline(statTotal, {
									type: 'bar',
									height: '50',
									barWidth: 20,
									spotColor: '#4578a0',
									tooltipFormat: '{{offset:offset}} {{value}} Patient',
									tooltipValueLookups: {'offset': statCategory},
									minSpotColor: '#728fb2',
									maxSpotColor: '#6d93c4',
									highlightSpotColor: '#ef5179',
									highlightLineColor: '#8ba8bf',
									barSpacing: 2,
									barColor: '#26B99A'
							});
							var malePatientCount = getCounts("male",replyObj.QUAL);
							var femalePatientCount = getCounts("female",replyObj.QUAL);
							$("#totPatients").text(parseInt(femalePatientCount)+parseInt(malePatientCount));
							$("#MaleCount").text(malePatientCount);
							$("#FemaleCount").text(femalePatientCount);
							$("#ProviderCount").text(phyCnt);                                    
						}
						else{
								$("div.toolbar2").html('');
								$("#statsRow").css("display","none");
								alert("No Data found for the selection");
						}
						AppointmentTable
								.search('')
								.columns().search( '' )
								.draw();
						NProgress.done();
						waitingDialog.hide();
				}
			}
		};
		RS.open('GET', '14_mp_Daily_QPDailyHuddle',true)
		try{
				var promptVal = "^MINE^,^"+fromDate+"^,^"+toDate+"^,^"+selVal+"^";
				//alert(promptVal);
				//cclData.send("^MINE^, 0, 0, value($USR_PersonId$), 1");
				RS.send(promptVal)
		}
		catch(e){
				alert(e.description);
				return;
				NProgress.done();
				waitingDialog.hide();
		}
	}
};
	   
	$(document).ready(function() {
		init_DataTables();		
		init_daterangepicker();
		//populateDDLPL()
		init_switchery();

		// //init_sparklines();
		// init_sidebar();
		// init_TagsInput();
		// //init_parsley();
		// 
		// init_daterangepicker_right();
		// init_daterangepicker_single_call();
		// init_select2();
		// 
		// //init_starrr();
		// init_echarts();
		// init_calendar();
		// init_autosize();				
	});	
	
	var waitingDialog = waitingDialog || (function ($) {
		'use strict'; 
		// Creating modal dialog's DOM
		var $dialog = $(
				'<div class="modal fade" data-backdrop="static" data-keyboard="false" tabindex="-1" role="dialog" aria-hidden="true" style="padding-top:15%; overflow-y:visible;">' +
				'<div class="modal-dialog modal-m">' +
				'<div class="modal-content">' +
						'<div class="modal-header"><h3 style="margin:0;"></h3></div>' +
						'<div class="modal-body">' +
								'<div class="progress progress-striped active" style="margin-bottom:0;"><div class="progress-bar" style="width: 100%"></div></div>' +
						'</div>' +
				'</div></div></div>');

		return {
				/**
				 * Opens our dialog
				 * @param message Custom message
				 * @param options Custom options:
				 * 				  options.dialogSize - bootstrap postfix for dialog size, e.g. "sm", "m";
				 * 				  options.progressType - bootstrap postfix for progress bar type, e.g. "success", "warning".
				 */
				show: function (message, options) {
						// Assigning defaults
						if (typeof options === 'undefined') {
								options = {};
						}
						if (typeof message === 'undefined') {
								message = 'Loading';
						}
						var settings = $.extend({
								dialogSize: 'm',
								progressType: '',
								onHide: null // This callback runs after the dialog was hidden
						}, options);

						// Configuring dialog
						$dialog.find('.modal-dialog').attr('class', 'modal-dialog').addClass('modal-' + settings.dialogSize);
						$dialog.find('.progress-bar').attr('class', 'progress-bar');
						if (settings.progressType) {
								$dialog.find('.progress-bar').addClass('progress-bar-' + settings.progressType);
						}
						$dialog.find('h3').text(message);
						// Adding callbacks
						if (typeof settings.onHide === 'function') {
								$dialog.off('hidden.bs.modal').on('hidden.bs.modal', function (e) {
										settings.onHide.call($dialog);
								});
						}
						// Opening dialog
						$dialog.modal();
				},
				/**
				 * Closes dialog
				 */
				hide: function () {
						$dialog.modal('hide');
				}
		};

})(jQuery);

