var AppointmentTable;
var HighRiskTable;
var autoRefreshTgl;
var autoRefreshHRTgl;

var fromDate   = moment().startOf('day').subtract(7, 'days').format('DD-MMM-YYYY HH:mm:SS');
var toDate     = moment().endOf('day').format('DD-MMM-YYYY HH:mm:SS');

var fromHRDate = '';
var toHRDate   = '';

var orderLogLoading = false;
var HighRiskLoading = false;

var followUpDate = 0;

var temp_test = 0;

var commentBigList = [];


var ordLogCols = {
      PER_ID      : 0    /* 0  PER_ID       DT HIDDEN    */
    , ENC_ID      : 1    /* 1  ENC_ID       DT HIDDEN    */
    , NAME        : 2    /* 2  NAME                      */
    , FIN         : 3    /* 3  FIN                       */
    , PROVIDER    : 4    /* 4  PROVIDER                  */
    , ORDER_DATE  : 5    /* 5  ORDER_DATE                */
    , ORD_NAME    : 6    /* 6  ORD_NAME                  */
    , STATUS      : 7    /* 7  STATUS                    */
    , TURNAROUND  : 8    /* 8  TURNAROUND                */
    , RECEIVED    : 9    /* 9  RECEIVED                  */
    , RESULT_DATE : 10   /* 10 RESULT_DATE               */
    , ENDORSED_BY : 11   /* 11 ENDORSED_BY               */
    , ENDORSE_DATE: 12   /* 12 ENDORSE_DATE              */
}

var HRLogCols = {
      LINKS          : 0    /* 0  LINKS                        */
    , RISKS          : 1    /* 1  RISKS                        */
    , PER_ID         : 2    /* 2  PER_ID             DT HIDDEN */
    , ENC_ID         : 3    /* 3  ENC_ID             DT HIDDEN */
    , ORD_ID         : 4    /* 4  ORD_ID             DT HIDDEN */
    , LOCATION       : 5    /* 5  LOCATION           DT HIDDEN */
    , NAME           : 6    /* 6  NAME                         */
    , DOB            : 7    /* 7  DOB                          */
    , PHONE          : 8    /* 8  PHONE                        */
    , PCP            : 9    /* 9  PCP                          */
    , OB_GYN         : 10   /* 10 OB_GYN                       */
    , LAST           : 11   /* 11 LAST                         */
    , LAST_APPT_TYPE : 12   /* 12 LAST_APPT_TYPE     DT HIDDEN */
    , LAST_APPT_DATE : 13   /* 13 LAST_APPT_DATE     DT HIDDEN */
    , LAST_APPT_LOC  : 14   /* 14 LAST_APPT_LOC      DT HIDDEN */
    , LAST_APPT_PROV : 15   /* 15 LAST_APPT_PROV     DT HIDDEN */
    , NEXT           : 16   /* 16 NEXT                         */
    , NEXT_APPT_TYPE : 17   /* 17 NEXT_APPT_TYPE     DT HIDDEN */
    , NEXT_APPT_DATE : 18   /* 18 NEXT_APPT_DATE     DT HIDDEN */
    , NEXT_APPT_LOC  : 19   /* 19 NEXT_APPT_LOC      DT HIDDEN */
    , NEXT_APPT_PROV : 20   /* 20 NEXT_APPT_PROV     DT HIDDEN */
    , ORDER_PROV     : 21   /* 21 ORDER_PROVIDER               */
    , ORDER_RESULTS  : 22   /* 22 ORDER_RESULTS                */
    , ENDORSED_BY    : 23   /* 23 ENDORSED_BY                  */
    , ENDORSE_DATE   : 24   /* 24 ENDORSE_DATE                 */
    , FOLLOW_UP_DATE : 25   /* 25 FOLLOW_UP_DATE               */
    , COMMENTS       : 26   /* 26 COMMENTS                     */
}




var popupWindowHandle;
var initLoadCnt = 0;
var initTotalCnt = 1;
// This is dumb, but we needed it for print.
var tableGroupHeader =
    "<tr style='font-weight:700' id='tableGroupHeader'> \
        <td colspan='2' class='text-center          '>PATIENT</td> \
        <td colspan='4' class='text-center dtHeadSec'>ORDER</td> \
        <td colspan='3' class='text-center dtHeadSec'>RESULT</td> \
        <td colspan='2' class='text-center dtHeadSec'>ENDORSEMENT</td> \
    </tr>";


//Note these are not the same spans as the HTML... because we are brute force hiding some columns in the buttons.print.js.
var hrTableGroupHeader =
    "<tr id='tableGroupHeaderHR'>                                             \
        <td colspan='1'  class='text-center'                >RISK        </td>\
        <td colspan='5'  class='text-center dtHeadSec'      >PATIENT     </td>\
        <td colspan='2'  class='text-center'                >APPOINTMENT </td>\
        <td colspan='3'  class='text-center'                >RESULTS     </td>\
        <td colspan='2'  class='text-center dtHeadSecOrange'>PLAN OF CARE</td>\
    </tr>";

var commentDiv =
    "<div>\
        <div class='card commentCard'>\
            <div class='card-title'>\
                <div class='comCardTitle commentCardFlex'>\
                    <div>\
                        <i class='fas fa-user-tie'></i>\
                        <i class='fas fa-comments'></i>\
                        <span class='comCardTitle'>prsnlName</span>\
                    </div>\
                    <div class='commentDate'>\
                        <span class='card-subtitle text-muted'>\
                            <small>cmntDateTm</small>\
                        </span>\
                    </div>\
                </div>\
            </div>\
            <div class='card-text'>\
                <p>Follow Up Date: cmntFollow</p>\
                <p>cmntVal</p>\
            </div>\
        </div>\
    </div>"
    
//We got expensive bootstrapping of select2s on load.  We want to be done with both, before we release the page to the user.
var reportCount = 0;
function reportLoadDone(){
    
    reportCount++;
    
    if(reportCount >= 2) startProgressDone();
}


function getPopupWindowHandle() {
    return popupWindowHandle;
}

//Modals and scroll stop stuff
$('a[data-toggle="tab"]').on('shown.bs.tab', function (event) {
  //event.target // newly activated tab
  //event.relatedTarget // previous active tab
  
  checkActiveModals();
});


function toggleModal(modal){
    if($(modal).hasClass('modalHide')){
        $(modal).removeClass('modalHide');
    }else{
        $(modal).addClass('modalHide');
    }
    
    checkActiveModals();
}

function checkActiveModals(){
    startBodyScroll();
    
    if($('#orderLog').hasClass('active')){
        if($('#OLWait').is(':visible')){
            stopBodyScroll();
        }
    }
    if($('#highRisk').hasClass('active')){
        if(   $('#HRWait'    ).is(':visible')
           || $('#HRPOCModal').is(':visible')
          ){
            stopBodyScroll();
        }
    }
}


function stopBodyScroll(){
    $('body').addClass('bodyScrollOff');
}

function startBodyScroll(){
    $('body').removeClass('bodyScrollOff');
}



/**
   Several AJAX calls exist before loading the page.  This will count as they finish for nProgress.
   After initial load, normal usuage should be possible by NProgress.start() before the ajax call,
   and NProgress.done() in the last part of the parseReply.

*/
function startProgressDone() {
    initLoadCnt++;

    if(initLoadCnt === initTotalCnt) {
        NProgress.done();
    }
    else{
        NProgress.set((1.0 / initTotalCnt) * initLoadCnt);
    }
}


//Future todo
//  You can set up a quick prototyping mockAjax framework by wrapping xmlcclrequest and mPageCCLCall with
//  checks to catch if you are outside powerchart like this:
//  if(typeof window.external.XMLCclRequest == 'function')
//
//  And you can place JSON in XML and use something like mockAjax to simulate ajax calls where that JSON is returned.
//  It's nice but I don't want to take the time to do that yet.  Maybe after I have more downtime.
XMLCclRequest = function(options) {
/************ Attributes *************/
    return window.external.XMLCclRequest();
}
XMLCCLREQUESTOBJECTPOINTER = [];


/**
 * Creates and returns a Millennium MPage middleware script call.
 *
 * @param {String} script The name of the script being responsible for fulfilling
 *              the Ajax request.
 * @param {Function} fn A function that will take the JSON object marshaled by the
 *              returned function.
 * @param {Function} stat [optional] A function that will take the JSON object
 *              representing the standard CCL status reply block. If omitted and
 *              if a status block is returned and has a non -success/-empty status,
 *              this method will not call <b>fn</b>, instead, will <tt>alert</tt>
 *              the status block.
 * @returns {Function} A function which takes a String argument, the Ajax SEND
 *              options. This function will create the MPage script
 *              call that, once invoked, will marshal the reply into a JSON object.
 */
//TODO this can probably make a mPage common include allowing the reply processing
//     code to be abstracted away from the call return processing
mPageCCLCall = function(script, fn, stat, errfn) {

    return function(opts) {
        var ajax = new XMLCclRequest();
        ajax.onreadystatechange = function() {
            if (ajax.readyState === 4 && ajax.status === 200) {
                var callFn, json, statusData;

                callFn = true;
                json = $.parseJSON(ajax.responseText);
                //alert(JSON.stringify(json));
                statusData = null;
                for (var i in json) {
                    if (json[i]["STATUS_DATA"]) {
                        statusData = json[i]["STATUS_DATA"];
                        break;
                    }
                }
                if (statusData && statusData.STATUS) {
                    if (stat) {
                        stat(statusData);
                    } else if (/[fp]/i.test(statusData.STATUS)) {
                        callFn = false;
                    }
                }
                callFn && fn(json);
            }
            else if (ajax.readyState === 4 && ajax.status >= 400 && ajax.status <= 599) {
                console.log("The page did not load properly, please refresh the page to try again.");
                console.log(ajax);
                errfn && errfn();
            }
        };
        ajax.open("GET", script);
        ajax.send(opts);
    };
};


//Tooltips
var linkTooltip =
'<h5>Link Icon Legend</h5>                              ' +
'<table>                                                ' +
'    <tr>                                               ' +
'        <td><i class="fas fa-clipboard-list"></i></td> ' +
'        <td>Visit Orders Tab</td>                      ' +
'    </tr>                                              ' +
'    <tr>                                               ' +
'        <td><i class="fas fas fa-bell"></i></td>       ' +
'        <td>Visit Recommendations Tab</td>             ' +
'    </tr>                                              ' +
'</table>                                               '

var riskTooltip =
'<h5>Risks</h5>                                                                                                    ' +
'<table>                                                                                                           ' +
'    <tr>                                                                                                          ' +
'        <td style="vertical-align: top">Out of Care:</td>                                                         ' +
'        <td> HPV Positive, with no repeat HPV/Cytology witin last year.</td>                                      ' +
'    </tr>                                                                                                         ' +
'    <tr>                                                                                                          ' +
'        <td style="vertical-align: top">High Risk:</td>                                                           ' +
'        <td> HPV Positive, with cytology showing LSIL, LGSIL, ASC-US, ASC-H, AGC, AGUS, HGSIL, HSIL.</td>         ' +
'    </tr>                                                                                                         ' +
'    <tr>                                                                                                          ' +
'        <td style="vertical-align: top">Needs Colposcopy:</td>                                                    ' +
'        <td> Age over 30 and HPV Positive with cytology showing LSIL, LGSIL, ASC-US, ASC-H, AGC, AGUS, HGSIL, HSIL' +
'             <br/>or Age over 30 and HPV 16 or 18 positive without follow up or referral                          ' +
'             <br/>or Age over 30 and Repeat HPV Positive without cytology                                         ' +
'             <br/>(Risk text can be hovered over to explain qualification)                                        ' +
'        </td>                                                                                                     ' +
'    </tr>                                                                                                         ' +
'    <tr>                                                                                                          ' +
'        <td style="vertical-align: top">Tissue Pathology Outstanding:</td>                                        ' +
'        <td>Tissue pathology ordered, not endorsed</td>                                                           ' +
'    </tr>                                                                                                         ' +
'</table>                                                                                                          '

var resultTooltip =
'<h5>Results</h5>                                                                                                   ' +
'<p>Order name of order that qualified for the risks column, followed by results that are tied to that order.</p>   ' +
'<p>Results are click-able links to view the results directly.                                               </p>   '


var apptTooltip =
'<h4>Next Appt Date Filter</h4>                                                                                     ' +
'<p>Date range for next appotinemtn.  Blank for "Any".</p>                                                          ' 



// Switchery
function init_switchery()
{
    autoRefreshTgl = new Switchery($('#autoRefreshTgl')[0],     {
        size:"small",
        color: '#26B99A'
    });

    autoRefreshHRTgl = new Switchery($('#autoRefreshTglHR')[0],     {
        size:"small",
        color: '#26B99A'
    });
}

$('#tblActivity tbody').on('dblclick', 'tr', function () {
    var data = AppointmentTable.row( this ).data();
    openChart(ordLogCols.PER_ID, ordLogCols.ENC_ID, "");
} );

$('#tblActivityHR tbody').on('dblclick', 'tr', function () {
    var data = HighRiskTable.row( this ).data();
    openChart(data[HRLogCols.PER_ID], data[HRLogCols.ENC_ID], "");
} );


$('#refBtn').click(function () {
    loadPatients(true);
});

$('#refBtnHR').click(function () {
    loadHRPatients(true);
});


$('#defBtn').click(function () {
    saveFilters();
});

$('#defBtnHR').click(function () {
    saveHRFilters();
});



$("#select-practiceLoc").on('change', function(){
    if(autoRefreshTgl.isChecked())
    {
        loadPatients(false);
    }
});

$("#select-practiceLocHR").on('change', function(){
    if(autoRefreshHRTgl.isChecked())
    {
        loadHRPatients(false);
    }
});


//Weird stuff happening, sounds like the buttons are reinjected into dom every once in a while.
$('.hrLBButton').on('click', function() {
    $(this).addClass('active').siblings().removeClass('active');

    if(autoRefreshHRTgl.isChecked()){
        loadHRPatients(false);
    }
});

function provAny(){
    var option = new Option("Any", 0, true, true);
    
    $(option).addClass("select2-selection__choice");
    
    $('#select-provider').append(option);
    $('#select-provider').val(0);
    
}
function provHRAny(){
    var option = new Option("Any", 0, true, true);
    
    $(option).addClass("select2-selection__choice");
    
    $('#select-hrprovider').append(option);
    $('#select-hrprovider').val(0);
    
}
$('#select-provider'  ).change(function(){
    var values;
    
    values = $('#select-provider'  ).val();
    if(values){
        values = values.map(function(item){
            return parseInt(item);
        });
    }
    
    if(values && values.length > 1){
        if(values.indexOf(0) >= 0){
            values = values.filter(function(item){
                return item !== 0;
            });
            
            //Jeze I'm doing something wrong.  If any was there, and is there again at page load... we remove both.
            if(values.length === 0)  values = [0];
            
            $('#select-provider'  ).val(values);
        }
        
    }else if(values && values.length === 0){
        $('#select-provider'  ).val(0);
    }else if(!values){
        $('#select-provider'  ).val(0);
    }
    
    if(autoRefreshTgl.isChecked()) {
        loadPatients(false);
    }
    
});
$('#select-hrprovider').change(function(){
    var values;
    
    values = $('#select-hrprovider'  ).val();
    if(values){
        values = values.map(function(item){
            return parseInt(item);
        });
    }
    
    if(values && values.length > 1){
        if(values.indexOf(0) >= 0){
            values = values.filter(function(item){
                return item !== 0;
            });
            
            //Jeze I'm doing something wrong.  If any was there, and is there again at page load... we remove both.
            if(values.length === 0)  values = [0];
            
            
            $('#select-hrprovider'  ).val(values);
        }
        
    }else if(values && values.length === 0){
        $('#select-hrprovider'  ).val(0);
    }else if(!values){
        $('#select-hrprovider'  ).val(0);
    }
    
    if(autoRefreshHRTgl.isChecked()) {
        loadHRPatients(false);
    }
    
});




function loadProviders(arData){    
    pageSize = 50

    try{
        $(function() {
            pageSize = 50

            jQuery.fn.select2.amd.require(["select2/data/array", "select2/utils"],

            function(ArrayData, Utils) {
                function CustomData($element, options) {
                    CustomData.__super__.constructor.call(this, $element, options);
                }
                Utils.Extend(CustomData, ArrayData);

                CustomData.prototype.query = function(params, callback) {

                    var results = [];
                    if (params.term && params.term !== '') {
                        results = _.filter(arData, function(e) {
                            return e.text.toUpperCase().indexOf(params.term.toUpperCase()) >= 0;
                        });
                    } else {
                        results = arData;
                    }

                    if (!("page" in params)) {
                        params.page = 1;
                    }
                    var data = {};
                    data.results = results.slice((params.page - 1) * pageSize, params.page * pageSize);
                    data.pagination = {};
                    data.pagination.more = params.page * pageSize < results.length;
                    callback(data);
                };

                $(document).ready(function() {
                    $("#select-provider").select2({
                        ajax: {},
                        dataAdapter: CustomData
                    });
                    provAny();
                    $("#select-hrprovider").select2({
                        ajax: {},
                        dataAdapter: CustomData
                    });
                    provHRAny();
                    
                    var requestObj = {   "MPAGE_DATA": {
                                             "PRSNL_ID": 0.0,  //this will be reset by the ccl, using the second param.
                                             "ELEMENT": [{
                                                     "CDF_MEAN": "OBGYNFILT",
                                                     "DATA": ""
                                                 }, {
                                                     "CDF_MEAN": "OBGYNHRFILT",
                                                     "DATA": ""
                                                 }
                                             ],
                                             "STATUS_DATA": {
                                                 "STATUS": "",
                                                 "SUBEVENTSTATUS": []
                                             }
                                         }
                                     };
                    
                    opts = "^MINE^,value($USR_PERSONID$),^^,^"+ JSON.stringify(requestObj) +"^";
                    parseReply = function(json){
                        var i, savedVal, savedValHR, provIdList = [], provHRIdList = [];

                        savedVal = {
                              "locations" : []
                            , "providers" : []
                        }

                        savedValHR = {
                              "locations" : []
                            , "providers" : []
                        }


                        for(i = 0; i < json.MPAGE_DATA.ELEMENT.length; i++){

                            if(json.MPAGE_DATA.ELEMENT[i].DATA.length > 0){
                                if(json.MPAGE_DATA.ELEMENT[i].CDF_MEAN === "OBGYNFILT")   savedVal   = JSON.parse(json.MPAGE_DATA.ELEMENT[i].DATA);
                                if(json.MPAGE_DATA.ELEMENT[i].CDF_MEAN === "OBGYNHRFILT") savedValHR = JSON.parse(json.MPAGE_DATA.ELEMENT[i].DATA);
                            }
                        }
                        
                        
                        if(savedVal.locations.length > 0){
                            $('#select-practiceLoc').val(savedVal.locations);
                            $('#select-practiceLoc').trigger('change');
                        }
                        
                        if(savedValHR.locations.length > 0){
                            $('#select-practiceLocHR').val(savedValHR.locations);
                            $('#select-practiceLocHR').trigger('change');
                        }
                        
                        if(savedVal.providers.length   > 0){
                            savedVal.providers.forEach(function(item){
                                provIdList.push(item.id);
                                    
                                if($('#select-provider').val().indexOf(item.id.toString()) === -1){
                                    var option = new Option(item.text, item.id, true, true);
                                    
                                    $(option).addClass("select2-selection__choice");
                                    
                                    $('#select-provider').append(option);
                                }
                            });
                            
                            $('#select-provider').val(provIdList).trigger('change');
                        
                        }
                        
                        if(savedValHR.providers.length > 0){
                            savedValHR.providers.forEach(function(item){
                                provHRIdList.push(item.id);
                                    
                                if($('#select-hrprovider').val().indexOf(item.id.toString()) === -1){
                                    var option = new Option(item.text, item.id, true, true);
                                    
                                    $(option).addClass("select2-selection__choice");
                                    
                                    $('#select-hrprovider').append(option);
                                }
                            });
                            
                            $('#select-hrprovider').val(provHRIdList).trigger('change');
                        
                        }
                        
                        $('#autoRefreshTgl'  )[0].click();
                        $('#autoRefreshTglHR')[0].click();
                        
                        loadPatients(false);
                        loadHRPatients(false);
                        
                        reportLoadDone();
                    }
                    console.log('0_get_cust_mpage_data ' + opts);
                    mPageCCLCall('0_get_cust_mpage_data', parseReply)(opts);
                    
                });
                

            })
        });
    }
    catch(e){
        alert(e.message)
    }    
}





function init_DataTables()
{
    /* I had to hard steal this from Simeon, which is funny because we are mere days from this working without it.
       The grief here is the datatables we used, hard doesn't allow IE9 looking views (like the IE.dll PowerChart uses)
       from using the jszip stuff it tries to use.  It hard fails.  I couldn't work around this... even knowing the view
       these days shouldn't be acting like IE9.
       
       In any case, Looks like Simeon does a more like CSV build.  But he got the save dialog to work right so... that's nice.
       
       If we want to refancify this... it is easy.  I had the excel functionality tested out in IE11+.  Basically to revert
       to what I had, remove the extend below, and flip the extend in the DT buttons def to flip back to excel from excel2.
    
    */
    DataTable.ext.buttons.excel2 = {
		className: 'buttons-print',

		text: function ( dt ) {
			return dt.i18n( 'buttons.excel2', 'excel2' );
		},

		action: function ( e, dt, button, config ) {
			try{
                var fileName;
				var data = dt.buttons.exportData( config.exportOptions );
				var addCSVRow = function ( d) {
					var str = ''
					str = d.map(function(cell) {
						return '"t"'.replace("t", cell);
					}).join(",");
					return str + "\r\n";
				};
				var csvstring = addCSVRow(data.header)
				
                if(button.hasClass('ordLog'  )) fileName = "wh_cerv_cyto_spec_sti_ord_log.csv";
                if(button.hasClass('highRisk')) fileName = "wh_cerv_cyto_spec_sti_high_risk.csv";
                
                
				for ( var i=0, ien=data.body.length ; i<ien ; i++ ) {
					csvstring =csvstring+ addCSVRow(data.body[i])
				}
				//alert(csvstring)
				// Create a CSV Blob
				var blob = new Blob([csvstring], { type: "text/csv" });
				if (navigator.msSaveOrOpenBlob) {
				  // Works for Internet Explorer and Microsoft Edge
				  navigator.msSaveOrOpenBlob(blob, fileName);
				} else{
                    var a = document.createElement("a");
                    document.body.appendChild(a);
                    a.style = "display: none";
                    var csvUrl = "data:text/plain;charset=utf-8," + encodeURIComponent(csvstring);
                    a.href =  csvUrl;
                    a.download = fileName;
                    a.click();
                    URL.revokeObjectURL(a.href)
                    a.remove();
                }
			}
			catch(e){
				alert(e.message)
			}
		},

		title: '*',

		message: '',

		exportOptions: {},

		header: true,

		footer: false,

		autoPrint: true,

		customize: null
	};
    
    AppointmentTable = $('#tblActivity')
        .on('processing.dt', function ( e, settings, processing ) {
                                 $('#processingIndicator').css( 'display', processing ? 'block' : 'none' );
                             }
           )
        .DataTable({
                        responsive: true,
                        "processing": true,
                        "paging": true,
                        //Here is what all the letters mean
                        // l - length changing - amount on page
                        // f - filtering - search
                        // t - the table
                        // i - table information - showing x out of x entries
                        // p - page control
                        // r - processing element - I think we don't use this.
                        "dom": '<"tableButtonFlex" B<"tableButtonRightFlex"fr<"#topPaginate" p>>>t<"tableButtonFlex"i<"tableButtonRightFlex"p>>',
                        buttons: { dom:{ button:{ tag: 'button'
                                                , className: '' 
                                                }
                                       },
                                   buttons:[ { extend: 'copy'
                                             , text: '<i class="fas fa-copy fa-lg"></i> Copy'
                                             , className: "btn btn-sm btn-outline-secondary"
                                             , title: "Women's Health - Cervical Cytology Specimen and STI Order Log"
                                             , exportOptions: { 
                                                 orthogonal: 'excel'
                                               , stripHtml: true
                                               , columns: [ ordLogCols.NAME
                                                          , ordLogCols.FIN
                                                          , ordLogCols.PROVIDER
                                                          , ordLogCols.ORDER_DATE
                                                          , ordLogCols.ORD_NAME
                                                          , ordLogCols.STATUS
                                                          , ordLogCols.TURNAROUND
                                                          , ordLogCols.RECEIVED
                                                          , ordLogCols.RESULT_DATE
                                                          , ordLogCols.ENDORSED_BY
                                                          , ordLogCols.ENDORSE_DATE
                                                        ]
                                               , format:{
                                                   header: function (data, colIdx){
                                                    return colIdx === ordLogCols.ORD_NAME   ? "ORDER NAME"
                                                         : colIdx === ordLogCols.TURNAROUND ? "TURNAROUND DAYS"                                                 
                                                                                            : data;
                                                   }
                                               }
                                             }
                                           }
                                           , { text: '<i class="fas fa-filter fa-lg"></i> Filter'
                                             , className: "btn btn-sm btn-outline-secondary"
                                             , action: function(e, dt, node, config) {
                                                   $('#OLSubFilters').removeClass('modalHide');
                                                   stopBodyScroll();
                                               }
                                             }
                                           , { extend: "print"
                                             //, autoPrint: false  //TODO Comment this after debug
                                             , text: '<i class="fas fa-print fa-lg"></i> Print'
                                             , className: "btn btn-sm btn-outline-secondary dtable-button"
                                             , exportOptions: {stripHtml: false}
                                             , customize:function(win){
                                                     var last = null;
                                                     var current = null;
                                                     var bod = [];
                                                     
                                                     var css = '@page { size: landscape; margin: .25in;} ',
                                                         css2 = 'td, th  {font-size: 5pt; }',
                                                         //css2 = 'td, th  {font-size: 8pt; }',
                                                         head = win.document.head || win.document.getElementsByTagName('head')[0],
                                                         style = win.document.createElement('style'),
                                                         style2 = win.document.createElement('style');
                                                     
                                                     style.type = 'text/css';
                                                     style.media = 'print';
                                                     
                                                     style2.type = 'text/css';
                                                     
                                                     if (style.styleSheet){
                                                       style.styleSheet.cssText = css;
                                                     }
                                                     else{
                                                       style.appendChild(win.document.createTextNode(css));
                                                     }
                                                     
                                                     if (style2.styleSheet){
                                                       style2.styleSheet.cssText = css2;
                                                     }
                                                     else{
                                                       style2.appendChild(win.document.createTextNode(css2));
                                                     }
                                                     
                                                     head.appendChild(style);
                                                     head.appendChild(style2);
                                                 }
                                           } 
                                         , { extend: "excel2"
                                           , text: '<i class="fas fa-file-excel fa-lg"></i> Export to Excel'
                                           , className: "btn btn-sm btn-outline-secondary ordLog"
                                           , exportOptions: { 
                                                 orthogonal: 'excel'
                                               , stripHtml: true
                                               , columns: [ ordLogCols.NAME
                                                          , ordLogCols.FIN
                                                          , ordLogCols.PROVIDER
                                                          , ordLogCols.ORDER_DATE
                                                          , ordLogCols.ORD_NAME
                                                          , ordLogCols.STATUS
                                                          , ordLogCols.TURNAROUND
                                                          , ordLogCols.RECEIVED
                                                          , ordLogCols.RESULT_DATE
                                                          , ordLogCols.ENDORSED_BY
                                                          , ordLogCols.ENDORSE_DATE
                                                        ]
                                               , format:{
                                                   header: function (data, colIdx){
                                                    return colIdx === ordLogCols.ORDER_DATE   ? "ORDER DATE"
                                                         : colIdx === ordLogCols.ORD_NAME     ? "ORDER NAME"
                                                         : colIdx === ordLogCols.TURNAROUND   ? "TURNAROUND DAYS"                                                 
                                                         : colIdx === ordLogCols.RESULT_DATE  ? "RESULT DATE"                                                 
                                                         : colIdx === ordLogCols.ENDORSE_DATE ? "ENDORSE DATE"                                                 
                                                                                            : data;
                                                   }
                                               }
                                             }
                                           }
                                         , {  extend: 'pageLength'
                                           , className: "btn btn-sm btn-outline-secondary"
                                           }
                                       ]
                                 },
                        "iDisplayLength": 25,
                        emptyTable: "No Data to display....Please select Location and Date",
                        "columnDefs": [
                            {
                                "targets": [ordLogCols.PER_ID],
                                "visible": false,
                                "searchable": false
                            },{
                                "targets": [ordLogCols.ENC_ID],
                                "visible": false,
                                "searchable": false
                            },
                            {
                                "targets": [ordLogCols.NAME],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    return type === 'display' ? '<a class="patientNameLink"><i class="fas fa-user"></i> ' + data[ordLogCols.NAME] + '</a>' :
                                           data[ordLogCols.NAME];
                                }
                            },
                            {
                                "targets": [ordLogCols.TURNAROUND],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    if(type === 'display'){
                                        return data[ordLogCols.TURNAROUND];
                                    }else if(type === 'filter'){
                                        if(data[ordLogCols.TURNAROUND] === '') return '[Blanks]';
                                        else                                   return data[ordLogCols.TURNAROUND]
                                    }else{
                                        if(data[ordLogCols.TURNAROUND].length > 0){
                                            return parseInt(data[ordLogCols.TURNAROUND].replace('days','').replace('day',''));
                                        }else{
                                            return '';
                                        }
                                    }

                                }
                            },
                            {
                                "targets": [ordLogCols.RECEIVED],
                                "data": null,
                                "className": "text-center",
                                "render": function ( data, type, row, meta ) {
                                    if(type === 'display'){
                                        if(data[ordLogCols.RECEIVED] == 0) return '<i class="fas fa-ambulance" style="color:OrangeRed" title="Not Received/Over 7 days"></i>';
                                        if(data[ordLogCols.RECEIVED] == 1) return '<i class="fas fa-times" style="color:Tomato" title="Not Received"></i>';
                                        if(data[ordLogCols.RECEIVED] == 2) return '<i class="fas fa-check" style="color:DarkCyan" title="Received"></i>';
                                    }else if(type === 'excel'){
                                        if(data[ordLogCols.RECEIVED] == 0) return 'Not Received/Over 7 days';
                                        if(data[ordLogCols.RECEIVED] == 1) return 'Not Received';
                                        if(data[ordLogCols.RECEIVED] == 2) return 'Received';
                                    }else{
                                        return data[ordLogCols.RECEIVED];
                                    }
                                }
                            }
                        ]
                });

    HighRiskTable = $('#tblActivityHR')
        .on('processing.dt', function ( e, settings, processing ) {
                                 $('#processingIndicator').css( 'display', processing ? 'block' : 'none' );
                             }
           )
        .DataTable({
                        responsive: true,
                        "processing": true,
                        "paging": true,
                        //Here is what all the letters mean
                        // l - length changing - amount on page
                        // f - filtering - search
                        // t - the table
                        // i - table information - showing x out of x entries
                        // p - page control
                        // r - processing element - I think we don't use this.
                        "dom": '<"tableButtonFlex" B<"tableButtonRightFlex"fr<"#topPaginate" p>>>t<"tableButtonFlex"i<"tableButtonRightFlex"p>>',
                        buttons: { dom:{ button:{ tag: 'button'
                                                , className: '' 
                                                }
                                       },
                                   buttons:[ { extend: 'copy'
                                             , text: '<i class="fas fa-copy fa-lg"></i> Copy'
                                             , className: "btn btn-sm btn-outline-secondary"
                                             , title: "Women's Health - High Risk"
                                             , exportOptions: { 
                                                  orthogonal: 'copy'
                                                , stripHtml: true
                                                , columns: [ HRLogCols.RISKS
                                                           , HRLogCols.NAME
                                                           , HRLogCols.DOB
                                                           , HRLogCols.PHONE
                                                           , HRLogCols.PCP
                                                           , HRLogCols.OB_GYN
                                                           , HRLogCols.LAST_APPT_TYPE
                                                           , HRLogCols.LAST_APPT_DATE
                                                           , HRLogCols.LAST_APPT_LOC
                                                           , HRLogCols.LAST_APPT_PROV
                                                           , HRLogCols.NEXT_APPT_TYPE
                                                           , HRLogCols.NEXT_APPT_DATE
                                                           , HRLogCols.NEXT_APPT_LOC
                                                           , HRLogCols.NEXT_APPT_PROV
                                                           , HRLogCols.ORDER_RESULTS
                                                           , HRLogCols.ENDORSED_BY
                                                           , HRLogCols.ENDORSE_DATE
                                                           , HRLogCols.FOLLOW_UP_DATE
                                                           , HRLogCols.COMMENTS
                                                           ]
                                                }
                                             }
                                           , { text: '<i class="fas fa-filter fa-lg"></i> Filter'
                                             , className: "btn btn-sm btn-outline-secondary"
                                             , action: function(e, dt, node, config) {
                                                   $('#HRSubFilters').removeClass('modalHide');
                                                   stopBodyScroll();
                                               }
                                             }
                                           , { extend: "hrprint"
                                             //, autoPrint: false  //TODO Comment this after debug
                                             , text: '<i class="fas fa-print fa-lg"></i> Print'
                                             , className: "btn btn-sm btn-outline-secondary dtable-button"
                                             , exportOptions: { stripHtml: false
                                                              , orthogonal: 'print'
                                                              }
                                             , customize:function(win){
                                                     var last = null;
                                                     var current = null;
                                                     var bod = [];
                                                     
                                                     var css = '@page { size: landscape; margin: .25in;} ',
                                                         css2 = 'td, th  {font-size: 5pt; }',
                                                         //css2 = 'td, th  {font-size: 8pt; }',
                                                         head = win.document.head || win.document.getElementsByTagName('head')[0],
                                                         style = win.document.createElement('style'),
                                                         style2 = win.document.createElement('style');
                                                     
                                                     style.type = 'text/css';
                                                     style.media = 'print';
                                                     
                                                     style2.type = 'text/css';
                                                     
                                                     if (style.styleSheet){
                                                       style.styleSheet.cssText = css;
                                                     }
                                                     else{
                                                       style.appendChild(win.document.createTextNode(css));
                                                     }
                                                     
                                                     if (style2.styleSheet){
                                                       style2.styleSheet.cssText = css2;
                                                     }
                                                     else{
                                                       style2.appendChild(win.document.createTextNode(css2));
                                                     }
                                                     
                                                     head.appendChild(style);
                                                     head.appendChild(style2);
                                                 }
                                           } 
                                         , { extend: "excel2"
                                           , text: '<i class="fas fa-file-excel fa-lg"></i> Export to Excel'
                                           , className: "btn btn-sm btn-outline-secondary highRisk"
                                           , exportOptions: { 
                                                  orthogonal: 'excel'
                                                , stripHtml: true
                                                , columns: [ HRLogCols.RISKS
                                                           , HRLogCols.NAME
                                                           , HRLogCols.DOB
                                                           , HRLogCols.PHONE
                                                           , HRLogCols.PCP
                                                           , HRLogCols.OB_GYN
                                                           , HRLogCols.LAST_APPT_TYPE
                                                           , HRLogCols.LAST_APPT_DATE
                                                           , HRLogCols.LAST_APPT_LOC
                                                           , HRLogCols.LAST_APPT_PROV
                                                           , HRLogCols.NEXT_APPT_TYPE
                                                           , HRLogCols.NEXT_APPT_DATE
                                                           , HRLogCols.NEXT_APPT_LOC
                                                           , HRLogCols.NEXT_APPT_PROV
                                                           , HRLogCols.ORDER_RESULTS
                                                           , HRLogCols.ENDORSED_BY
                                                           , HRLogCols.ENDORSE_DATE
                                                           , HRLogCols.FOLLOW_UP_DATE
                                                           , HRLogCols.COMMENTS
                                                           ]
                                                //, format: {
                                                //    header: function (data, colIdx){
                                                //                return colIdx === HRLogCols.ORDER_RESULTS? "ORDER"                                                
                                                //                                                         : data;
                                                //            }
                                                //          }
                                                }
                                           }
                                         , {    extend: 'pageLength'
                                           , className: "btn btn-sm btn-outline-secondary"
                                           }
                                       ]
                                 },
                        "drawCallback": function (settings){
                        $('[data-toggle="popover"]').popover({
                            html: true,
                            placement: 'auto',
                            container: 'body',
                            delay: { "show": 500, "hide": 100 }
                        })
                        .on("focus", function () {
                                    $(this).popover("show");
                                })
                        .on("focusout", function () {
                                    var _this = this;
                                    if (!$(".popover:hover").length) {
                                        $(this).popover("hide");
                                    }
                                    else {
                                        $('.popover').mouseleave(function() {
                                            $(_this).popover("hide");
                                            $(this).off('mouseleave');
                                        });
                                    }
                                });
                            

                            $('[data-toggle="popover"]').on('shown.bs.popover', function(){
                                $('.popoverMagic').unbind();
                                $('.popoverMagic').on('click', function () {
                                    var data  = this.id.split(':');

                                    //remove the uniqueness text
                                    data.shift();

                                    //We are strings now... woops... better fix that
                                    data = data.map(function(x) {return(parseInt(x))});

                                    //The rest can be sent to the openResult function
                                    openResult(data[0], data[1]);

                                } );
                                $('.popoverMagic2').unbind();
                                $('.popoverMagic2').on('click', function () {
                                    var data  = this.id.split(':');

                                    //remove the uniqueness text
                                    data.shift();

                                    //We are strings now... woops... better fix that
                                    data = data.map(function(x) {return(parseInt(x))});

                                    //The rest can be sent to the openResult function
                                    openChart(data[0], data[1], 'Orders');

                                } );
                            });
                            $('.colposcopyTooltip').tooltip({
                                placement: 'bottom',
                                container: 'body',
                                html: true
                            });

                            $('.orderTooltip').tooltip({
                                placement: 'bottom',
                                container: 'body',
                                html: true
                            });
                        },
                        "iDisplayLength": 25,
                        emptyTable: "No Data to display....Please select Location and Date",
                        "columnDefs": [
                            //Turning off sorting on columns where it doesn't make sense.
                            {
                               'targets': [ HRLogCols.LINKS
                                          , HRLogCols.OB_GYN
                                          , HRLogCols.ORDER_RESULTS
                                          , HRLogCols.COMMENTS
                                          ], /* column index */
                               'orderable': false, /* true or false */
                            },
                            {
                                "targets": [ HRLogCols.PER_ID
                                           , HRLogCols.ENC_ID
                                           , HRLogCols.ORD_ID
                                           , HRLogCols.LOCATION
                                           , HRLogCols.LAST_APPT_TYPE
                                           , HRLogCols.LAST_APPT_DATE
                                           , HRLogCols.LAST_APPT_LOC
                                           , HRLogCols.LAST_APPT_PROV
                                           //, HRLogCols.NEXT_APPT_TYPE // we need this one to be searchable.
                                           , HRLogCols.NEXT_APPT_DATE
                                           , HRLogCols.NEXT_APPT_LOC
                                           , HRLogCols.NEXT_APPT_PROV
                                           ],
                                "visible": false,
                                "searchable": false
                            },
                            {
                                "targets": [ HRLogCols.NEXT_APPT_TYPE //we need this one to be searchable.
                                           , HRLogCols.ORDER_PROV
                                           ],
                                "visible": false,
                                "searchable": true
                            },
                            {
                                "targets": [HRLogCols.LINKS],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    var ret = '';

                                    if(type === 'display'){
                                        ret += '<a id="ordlink:'+ data[HRLogCols.PER_ID] + ':' + data[HRLogCols.ENC_ID] + '" class="patientOrderLink" title="Orders"><i class="fas fa-clipboard-list fa-2x"></i></a>';
                                        ret += '<a id="reclink:'+ data[HRLogCols.PER_ID] + ':' + data[HRLogCols.ENC_ID] + '" class="patientRecLink" title="Recommendations"><i class="fas fa-bell fa-2x"></i></a>';
                                        return ret;
                                    }else return data[HRLogCols.LINKS];


                                }
                            },
                            {
                                "targets": [HRLogCols.RISKS],
                                "data": null,
                                "className": "wrap-fix",
                                "render": function ( data, type, row, meta ) {
                                    var i, reasons = [],
                                        reasonMap = 0, //For sorting mostly... adding up the flags;
                                        reasonExcel = [];

                                    reasons.push('<ul class="tableList">');
                                    for(i = 0; i < data[HRLogCols.RISKS].length; i++){
                                        if(data[HRLogCols.RISKS][i].REASON_FLAG === 1){
                                            reasons.push('<li>Out of Care</li>');
                                            reasonExcel.push('Out of Care');
                                        }
                                        if(data[HRLogCols.RISKS][i].REASON_FLAG === 2){
                                            reasons.push('<li>High Risk</li>');
                                            reasonExcel.push('High Risk');
                                        }
                                        if(data[HRLogCols.RISKS][i].REASON_FLAG === 4){
                                            reasons.push('<li class="colposcopyTooltip" title="' + data[HRLogCols.RISKS][i].REASON_TXT + '">Needs Colposcopy</li>');
                                            reasonExcel.push('Needs Colposcopy');
                                        }
                                        if(data[HRLogCols.RISKS][i].REASON_FLAG === 8){
                                            reasons.push('<li>Tissue Pathology Outstanding</li>');
                                            reasonExcel.push('Tissue Pathology Outstanding');
                                        }

                                        reasonMap += data[HRLogCols.RISKS][i].REASON_FLAG;

                                    }
                                    reasons.push('</ul>');

                                    if(type === 'display'){
                                        return reasons.join('');
                                    }
                                    else if(type === 'sort'){
                                        return reasonMap;
                                    }
                                    else if(   type === 'excel' 
                                            || type === 'copy'
                                           ){
                                        return reasonExcel.join('; ');
                                    }
                                    else{
                                        return reasons.join('');
                                    }
                                }
                            },
                            {
                                "targets": [HRLogCols.NAME],
                                "data": null,
                                "className": "wrap-fix",
                                "render": function ( data, type, row, meta ) {
                                    return type === 'display' ? '<a class="patientNameLink"><i class="fas fa-user"></i> ' + data[HRLogCols.NAME] + '</a>' :
                                           data[HRLogCols.NAME];
                                }
                            },
                            {
                                "targets": [HRLogCols.PCP],
                                "className": "wrap-fix"
                            },
                            {
                                "targets": [HRLogCols.OB_GYN],
                                "data": null,
                                "className": "wrap-fix",
                                "render": function ( data, type, row, meta ) {
                                    var i, obgyn = [], obgynExcel = [];

                                    obgyn.push('<ul class="tableList">');
                                    for(i = 0; i < data[HRLogCols.OB_GYN].length; i++){
                                        obgyn.push('<li>');
                                        obgyn.push(data[HRLogCols.OB_GYN][i].NAME);
                                        obgyn.push('</li>');
                                        
                                        obgynExcel.push(data[HRLogCols.OB_GYN][i].NAME);
                                    }
                                    obgyn.push('</ul>');


                                    if     (type === 'display') return obgyn.join('');
                                    else if(   type === 'excel' 
                                            || type === 'copy'
                                            || type === 'print'
                                            || type === 'filter'
                                           )                    return obgynExcel.join('; ');
                                    else                        return 'ERROR';
                                }
                            },
                            {
                                "targets": [HRLogCols.LAST],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    var appt = '';

                                    if(data[HRLogCols.LAST].APPT_TYPE !== '') appt += data[HRLogCols.LAST].APPT_TYPE;
                                    else                                      appt += '--';
                                    
                                    appt += '<br/>';

                                    if(data[HRLogCols.LAST].DATETIME  !== '') appt += data[HRLogCols.LAST].DATETIME;
                                    else                                      appt += '--';
                                    
                                    appt += '<br/>';


                                    if(data[HRLogCols.LAST].LOCATION  !== '') appt += data[HRLogCols.LAST].LOCATION;
                                    else                                      appt += '--';

                                    appt += '<br/>';

                                    if(data[HRLogCols.LAST].PROV_NAME !== '') appt += data[HRLogCols.LAST].PROV_NAME;
                                    else                                      appt += '--';

                                    return type === 'display' ? appt        : data[HRLogCols.LAST].SORTDATETIME;
                                }
                            },
                            {
                                "targets": [HRLogCols.NEXT],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    var appt = '';


                                    if(data[HRLogCols.NEXT].APPT_TYPE !== '') appt += data[HRLogCols.NEXT].APPT_TYPE;
                                    else                                      appt += '--';
                                    
                                    appt += '<br/>';

                                    if(data[HRLogCols.NEXT].DATETIME  !== '') appt += data[HRLogCols.NEXT].DATETIME;
                                    else                                      appt += '--';

                                    appt += '<br/>';

                                    if(data[HRLogCols.NEXT].LOCATION  !== '') appt += data[HRLogCols.NEXT].LOCATION;
                                    else                                      appt += '--';

                                    appt += '<br/>';

                                    if(data[HRLogCols.NEXT].PROV_NAME !== '') appt += data[HRLogCols.NEXT].PROV_NAME;
                                    else                                      appt += '--';

                                    return type === 'display' ? appt        : data[HRLogCols.NEXT].SORTDATETIME;
                                }
                            },
                            {
                                "targets": [HRLogCols.NEXT_APPT_TYPE],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    if     (type === 'display') return data[HRLogCols.NEXT_APPT_TYPE];
                                    else if(type === 'filter' ){
                                        if(data[HRLogCols.NEXT_APPT_TYPE] === '') return "[Blank]";
                                        else                                      return data[HRLogCols.NEXT_APPT_TYPE];
                                    }
                                    else return data[HRLogCols.NEXT_APPT_TYPE];
                                           
                                }
                            },
                            {
                                "targets": [HRLogCols.ORDER_PROV],
                                "data": null,
                                "className": "wrap-fix",
                                "render": function ( data, type, row, meta ) {
                                    var ret = '', excelList = [], ordData = data[HRLogCols.ORDER_PROV];

                                    if(ordData.length > 0){
                                        for(i = 0; i < ordData.length; i++){
                                            if(ordData[i].ORD_PROV_ID !== 0){
                                                ret += "<li>" + ordData[i].ORD_PROV_NAME + "</li>";
                                                excelList.push(ordData[i].ORD_PROV_NAME);
                                            }
                                        }
                                        
                                        if(ret !== '') ret = '<ul class="tableList">' + ret + "</ul>";
                                    }
                                    

                                    if     (   type === 'display') return ret;
                                    else if(   type === 'excel'
                                            || type === 'copy'
                                            || type === 'print'
                                            || type === 'filter'
                                           )                       return excelList.join('; ');
                                    else                           return 'ERROR'

                                }
                            },
                            {
                                "targets": [HRLogCols.ORDER_RESULTS],
                                "data": null,
                                "className": "tab_center",
                                "render": function ( data, type, row, meta ) {
                                    var ret = '', bigId, popContent = [], content, excelOrdNameList = [];

                                    for(i = 0; i < data[HRLogCols.ORDER_RESULTS].length; i++){
                                        popContent = [];

                                        popContent.push('<a id=\'popMag2:' + data[HRLogCols.PER_ID] + ':' + data[HRLogCols.ORDER_RESULTS][i].ORD_ENC_ID + '\' class=\'popoverMagic2 blue\'> [Link to Order] </a>');

                                        for(j = 0; j < data[HRLogCols.ORDER_RESULTS][i].ORD_RES.length; j++){
                                            popContent.push('<a id=\'popMag:' + data[HRLogCols.PER_ID] + ':' + data[HRLogCols.ORDER_RESULTS][i].ORD_RES[j].EVENT_ID + '\' class=\'popoverMagic\'> ' + data[HRLogCols.ORDER_RESULTS][i].ORD_RES[j].EVENT_TITLE + ' </a>');
                                        }

                                        if(popContent.length > 0){
                                            content = popContent.join('<br/>');
                                            ret += '<span class="orderTooltip" title="' + data[HRLogCols.ORDER_RESULTS][i].ORDER_NAME  + '"><a class="patientResLink tab_center" tabindex="0" role="button" data-toggle="popover"  title="' + data[HRLogCols.ORDER_RESULTS][i].ORDER_NAME  + '" data-content="' + content + '" ><i class="fas fa-solid fa-2x fa-flask"></i></a></span>';
                                            
                                            excelOrdNameList.push(data[HRLogCols.ORDER_RESULTS][i].ORDER_NAME);
                                        }
                                    }

                                    if     (   type === 'display') return ret;
                                    else if(   type === 'excel'
                                            || type === 'copy'
                                            || type === 'print'
                                           )                       return excelOrdNameList.join('; ');
                                    else                           return 'ERROR'

                                }
                            },
                            {
                                "targets": [HRLogCols.ENDORSED_BY],
                                "data": null,
                                "className": "wrap-fix",
                                "render": function ( data, type, row, meta ) {
                                    var ret = '', bigId, popContent = [], content;

                                    for(i = 0; i < data[HRLogCols.ENDORSED_BY].length; i++){
                                        popContent.push(data[HRLogCols.ENDORSED_BY][i].ENDORSE_BY);
                                    }

                                    ret = popContent.join('<br/>');

                                    //Sort might need work... I don't see multiple, but if it happens I'm just using first.
                                    return type === 'display' ? ret : data[HRLogCols.ENDORSED_BY][0].ENDORSE_BY;
                                }
                            },
                            {
                                "targets": [HRLogCols.ENDORSE_DATE],
                                "data": null,
                                "className": "wrap-fix",
                                "render": function ( data, type, row, meta ) {
                                    var ret = '', bigId, popContent = [], content;

                                    for(i = 0; i < data[HRLogCols.ENDORSE_DATE].length; i++){
                                        popContent.push(data[HRLogCols.ENDORSE_DATE][i].ENDORSE_DT_TM);
                                    }

                                    ret = popContent.join('<br/>');

                                    //Sort might need work... I don't see multiple, but if it happens I'm just using first.
                                    return type === 'display' ? ret : data[HRLogCols.ENDORSE_DATE][0].SORT_ENDORSE_DT_TM;
                                }
                            },
                            {
                                "targets": [HRLogCols.FOLLOW_UP_DATE],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    var span, style = '';

                                    if(data[HRLogCols.FOLLOW_UP_DATE].length > 0){
                                        dateStr = data[HRLogCols.FOLLOW_UP_DATE][0].FOLLOWUP_DT.substring(6, data[HRLogCols.FOLLOW_UP_DATE][0].FOLLOWUP_DT.length - 2);

                                        fuDate = moment(new Date(dateStr));

                                        if(fuDate < moment().startOf('day')){
                                            style = 'bolder red';

                                        }else if(fuDate < moment().startOf('day').add(7, 'Days')){
                                            style = 'blue';
                                        }

                                        if(type === 'display'){
                                            span = '<div class="' + style + '">' + data[HRLogCols.FOLLOW_UP_DATE][0].FOLLOWUP_DT_TXT + '</span>'

                                            return span
                                        } else{
                                            return data[HRLogCols.FOLLOW_UP_DATE][0].FOLLOWUP_SORT_DT_TXT;
                                        }

                                    }else{
                                        return type === 'display' ? ' ' : ' ';
                                    }

                                }
                            },
                            {
                                "targets": [HRLogCols.COMMENTS],
                                "data": null,
                                "render": function ( data, type, row, meta ) {
                                    var ret = '', opts = [], text, comment = '';

                                    if(type === 'display'){
                                        //Put our comments for this patient in the big lookup table.
                                        commentBigList.push(data[HRLogCols.FOLLOW_UP_DATE]);

                                        opts.push(data[HRLogCols.PER_ID]);  //PerID
                                        opts.push(data[HRLogCols.ENC_ID]);  //EncID
                                        opts.push(data[HRLogCols.NAME  ]);  //Name
                                        opts.push(commentBigList.length - 1);  //Store an index so we can get it later.
                                        opts.push(meta.row);  //Store an row index so we can get it later.

                                        if(data[HRLogCols.FOLLOW_UP_DATE].length === 0)  text = 'Add';
                                        else{
                                            text = 'View/Update';
                                            comment = data[HRLogCols.FOLLOW_UP_DATE][0].COMMENT;
                                        }

                                        //if(data[2] === 16464238){
                                        //    alert(meta.row);
                                        //    alert(meta.col);
                                        //    var id = '#cell-'+meta.row+'-'+meta.col
                                        //    alert(id)
                                        //    HighRiskTable.cell(id).data('!!!');
                                        //}

                                        ret = '<button pocOpts="'+ opts.join(':') + '" class="pocButton btn btn-primary btn-sm"><i class="fas fa-edit"></i> '+ text + '</button>'

                                        return ret;
                                    }else if(   type === 'excel'
                                             || type === 'copy'
                                             || type === 'print'
                                            ){
                                        if(data[HRLogCols.FOLLOW_UP_DATE].length !== 0)  comment = data[HRLogCols.FOLLOW_UP_DATE][0].COMMENT;
                                        
                                        return comment;
                                    }else{
                                        return ret;
                                    }
                                }
                            },
                        ],
                        "initComplete": function(settings) {
                            $('.linkTooltip'  ).attr('data-content', linkTooltip  );
                            $('.riskTooltip'  ).attr('data-content', riskTooltip  );
                            $('.resultTooltip').attr('data-content', resultTooltip);
                            $('.apptTooltip'  ).attr('data-content', apptTooltip  );
                            

                            /* Apply the tooltips */
                            $('.linkTooltip').popover({
                                placement: 'bottom',
                                container: 'body',
                                html: true,
                                animation: true,
                                trigger: 'hover',
                                sanitize: false  //was stripping out tables.
                            });
                            $('.riskTooltip').popover({
                                placement: 'bottom',
                                container: 'body',
                                html: true,
                                animation: true,
                                trigger: 'hover',
                                sanitize: false  //was stripping out tables.
                            });
                            $('.resultTooltip').popover({
                                placement: 'bottom',
                                container: 'body',
                                html: true,
                                animation: true,
                                trigger: 'hover',
                                sanitize: false  //was stripping out tables.
                            });
                            $('.apptTooltip').popover({
                                placement: 'bottom',
                                container: 'body',
                                html: true,
                                animation: true,
                                trigger: 'hover',
                                sanitize: false  //was stripping out tables.
                            });
                        }
                });
                
                //This seems to handle all cases I can think of... table redraws... reloads... searches... filters... 
                //Will recalculate numbers in data tiles based on what is in the table... shown... filtered rows ignored.
                AppointmentTable.on( 'search.dt', function (){
                    updateDataTiles();
                });
                
                //This seems to handle all cases I can think of... table redraws... reloads... searches... filters... 
                //Will recalculate numbers in data tiles based on what is in the table... shown... filtered rows ignored.
                HighRiskTable.on( 'search.dt', function (){
                    updateHRDataTiles();
                });
}

function init_daterangepicker()
{
    var optionSet1 = {
        startDate: moment().subtract(7, 'days'),
        endDate: moment(),
        //minDate: '01/01/2012',
        //maxDate: '12/31/2020',
        //dateLimit: {
        //    days: 60
        //},
        showDropdowns: true,
        showWeekNumbers: true,
        timePicker: false,
        timePickerIncrement: 1,
        timePicker12Hour: true,
        linkedCalendars: false,
        alwaysShowCalendars: true,
        ranges: {
            'Today': [moment(), moment()],
            'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
            'Last 7 Days': [moment().subtract(6, 'days'), moment()],
            'Last 30 Days': [moment().subtract(29, 'days'), moment()],
            'This Month': [moment().startOf('month'), moment().endOf('month')],
            'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
        },
        opens: 'left',
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

    var optionSet2 = {
        autoApply: true,
        autoUpdateInput: false,
        showDropdowns: true,
        showWeekNumbers: true,
        timePicker: false,
        timePickerIncrement: 1,
        timePicker12Hour: true,
        linkedCalendars: false,
        alwaysShowCalendars: true,
        singleDatePicker: true,
        opens: 'left',
        buttonClasses: ['btn btn-default'],
        applyClass: 'btn-small btn-primary',
        cancelClass: 'btn-small',
        format: 'MM/DD/YYYY',
        locale: {
            applyLabel: 'Submit',
            cancelLabel: 'Clear',
            fromLabel: 'From',
            customRangeLabel: 'Custom',
            daysOfWeek: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
            monthNames: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
            firstDay: 1
        }
    }
    var optionSet3 = {
        showDropdowns: true,
        showWeekNumbers: true,
        timePicker: false,
        timePickerIncrement: 1,
        timePicker12Hour: true,
        linkedCalendars: false,
        alwaysShowCalendars: true,
        autoUpdateInput: false,
        ranges: {
            'Today': [moment(), moment()],
            'Tomorrow': [moment().add(1, 'days'), moment().add(1, 'days')],
            'Next 7 Days': [moment(), moment().add(6, 'days')],
            'Next 30 Days': [moment(), moment().add(29, 'days')],
            'This Month': [moment().startOf('month'), moment().endOf('month')],
            'Next Month': [moment().add(1, 'month').startOf('month'), moment().add(1, 'month').endOf('month')]
        },
        opens: 'left',
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

    $('#dateRange').on('apply.daterangepicker', function (ev, picker) {
        var date = new Date();
        fromDate = picker.startDate.format('DD-MMM-YYYY HH:mm:SS');
        toDate = picker.endDate.format('DD-MMM-YYYY HH:mm:SS');
        if(autoRefreshTgl.isChecked())
        {
            loadPatients(false);
        }
    });
    $('#HRdateRange').on('apply.daterangepicker', function (ev, picker) {
        var date = new Date();
        
        fromHRDate = picker.startDate.format('DD-MMM-YYYY HH:mm:SS');
        toHRDate   = picker.endDate.format('DD-MMM-YYYY HH:mm:SS');
        
        $(this).val(picker.startDate.format('MM/DD/YYYY') + ' - ' + picker.endDate.format('MM/DD/YYYY'));
        
        if(autoRefreshHRTgl.isChecked())
        {
            loadHRPatients(false);
        }
    });
    $('#HRdateRange').on('cancel.daterangepicker', function(ev, picker) {
        fromHRDate = '';
        toHRDate   = '';
        
        $(this).val('');
        
        if(autoRefreshHRTgl.isChecked())
        {
            loadHRPatients(false);
        }
    });



    $('#HRPOCDatePicker').on('apply.daterangepicker', function (ev, picker) {
        //$(this).val(picker.startDate.format('DD-MMM-YYYY'));
        $(this).val(picker.startDate.format('MM/DD/YYYY'));

        followUpDate = picker.startDate;
    });


    $('#HRPOCDatePicker').on('cancel.daterangepicker', function(ev, picker) {
        $(this).val('');

        followUpDate = 0;
    }); 
    
    $('#DateCalBtn').unbind();
    $('#DateCalBtn').click(function () {
        $('#dateRange').click();
    });

    $('#HRDateCalBtn').unbind();
    $('#HRDateCalBtn').click(function () {
        $('#HRdateRange').click();
    });
    
    $('#DatePrevBtn').click(function () {
        $('#dateRange').data('daterangepicker').setStartDate($('#dateRange').data('daterangepicker').startDate.add(-1, 'days').startOf('day').format('MM/DD/YYYY'));
        $('#dateRange').data('daterangepicker').setEndDate($('#dateRange').data('daterangepicker').endDate.add(-1, 'days').endOf('day').format('MM/DD/YYYY'));
        fromDate = $('#dateRange').data('daterangepicker').startDate.startOf('day').format('DD-MMM-YYYY HH:mm:SS') ;
        toDate = $('#dateRange').data('daterangepicker').endDate.endOf('day').format('DD-MMM-YYYY HH:mm:SS') ;
        if(autoRefreshTgl.isChecked())
        {
            loadPatients(false);
        }
    });

    $('#DateNextBtn').click(function () {
        $('#dateRange').data('daterangepicker').setStartDate($('#dateRange').data('daterangepicker').startDate.add(1, 'days').startOf('day').format('MM/DD/YYYY'));
        $('#dateRange').data('daterangepicker').setEndDate($('#dateRange').data('daterangepicker').endDate.add(1, 'days').endOf('day').format('MM/DD/YYYY'));
        fromDate = $('#dateRange').data('daterangepicker').startDate.startOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
        toDate = $('#dateRange').data('daterangepicker').endDate.endOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
        if(autoRefreshTgl.isChecked())
        {
            loadPatients(false);
        }
    });

    $('#HRDatePrevBtn').click(function () {
        if(fromHRDate !== ''){
            var picker = $('#HRdateRange').data('daterangepicker');
            
            picker.setStartDate(picker.startDate.add(-1, 'days').startOf('day').format('MM/DD/YYYY'));
            picker.setEndDate  (picker.endDate.add(-1, 'days').endOf('day').format('MM/DD/YYYY'));
            
            fromDate = picker.startDate.startOf('day').format('DD-MMM-YYYY HH:mm:SS') ;
            toDate   = picker.endDate.endOf('day').format('DD-MMM-YYYY HH:mm:SS') ;
            
            $('#HRdateRange').val(picker.startDate.format('MM/DD/YYYY') + ' - ' + picker.endDate.format('MM/DD/YYYY'));
            
            if(autoRefreshHRTgl.isChecked())
            {
                loadHRPatients(false);
            }
        }
    });

    $('#HRDateNextBtn').click(function () {
        if(fromHRDate !== ''){
            var picker = $('#HRdateRange').data('daterangepicker');
            
            picker.setStartDate(picker.startDate.add(1, 'days').startOf('day').format('MM/DD/YYYY'));
            picker.setEndDate  (picker.endDate.add(1, 'days').endOf('day').format('MM/DD/YYYY'));
            
            fromDate = picker.startDate.startOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
            toDate   = picker.endDate.endOf('day').format('DD-MMM-YYYY HH:MM:SS') ;
            
            $('#HRdateRange').val(picker.startDate.format('MM/DD/YYYY') + ' - ' + picker.endDate.format('MM/DD/YYYY'));
            
            if(autoRefreshHRTgl.isChecked())
            {
                loadHRPatients(false);
            }
        }
    });



    $('#dateRange'  ).daterangepicker(optionSet1);
    $('#HRdateRange').daterangepicker(optionSet3);

    $('#HRPOCDatePicker').daterangepicker(optionSet2);
    
   
}


var OLsubFilterWindow = {
    clear: function(){
        $('#OLsubfiltProv').val([]).trigger('change');
        $('#OLsubfiltTA'  ).val([]).trigger('change');
    }
  , retrieveUserInput: function(){
        var ProvList = [], TAList = [];
        var provData, TAData;
        
        provData = $('#OLsubfiltProv').select2('data');
        TAData   = $('#OLsubfiltTA'  ).select2('data');
        
        var regexEscape = function(string){
            //https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
            return(string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')); // $& means the whole matched string
        } 
        
        
        provData.forEach(function(item){
            ProvList.push(regexEscape(item.text));
        });
        
        TAData.forEach(function(item){
            TAList.push(regexEscape(item.text));
        });
        
        var retObj = {
              prov       : ProvList
            , turnAround : TAList
        };
        
        return retObj;
    }
  , applyFilters: function(){
        var values = OLsubFilterWindow.retrieveUserInput();
        
        var provColumn = AppointmentTable.column(ordLogCols.PROVIDER  );
        var TAColumn   = AppointmentTable.column(ordLogCols.TURNAROUND);
        
        var provStr  = values.prov.join('|');
        var TAStr    = values.turnAround.join('|');
        
        provColumn.search(provStr, true, false, true);
        TAColumn.search(TAStr, true, false, true);
        
        AppointmentTable.draw();
        
        //updateDataTiles();
    }
}


var HRsubFilterWindow = {
    clear: function(){
        $('#HRsubfiltProv').val([]).trigger('change');
        $('#HRsubfiltRisk').val([]).trigger('change');
        $('#HRsubfiltAPPT').val([]).trigger('change');
    }
  , retrieveUserInput: function(){
        var provList = [], riskList = [], apptList = [];
        var provData, riskData, apptData;
        
        provData = $('#HRsubfiltProv').select2('data');
        riskData = $('#HRsubfiltRisk').select2('data');
        apptData = $('#HRsubfiltAPPT').select2('data');
        
        var regexEscape = function(string){
            //https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
            return(string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')); // $& means the whole matched string
        } 
        
        
        provData.forEach(function(item){
            provList.push(regexEscape(item.text));
        });
        
        riskData.forEach(function(item){
            riskList.push(regexEscape(item.text));
        });
        
        apptData.forEach(function(item){
            apptList.push(regexEscape(item.text));
        });
        
        var retObj = {
              prov : provList
            , risk : riskList
            , appt : apptList
        };
        
        return retObj;
    }
  , applyFilters: function(){
        var values = HRsubFilterWindow.retrieveUserInput();
        
        var provColumn = HighRiskTable.column(HRLogCols.ORDER_PROV    );
        var riskColumn = HighRiskTable.column(HRLogCols.RISKS         );
        var apptColumn = HighRiskTable.column(HRLogCols.NEXT_APPT_TYPE);
        
        var provStr  = values.prov.join('|');
        var riskStr  = values.risk.join('|');
        var apptStr  = values.appt.join('|');
        
        provColumn.search(provStr, true, false, true);
        riskColumn.search(riskStr, true, false, true);
        apptColumn.search(apptStr, true, false, true);
        
        HighRiskTable.draw();
        
        //updateDataTiles();
    }
}

function init_subFilts(){
    $('#OLsubfiltProv').select2();
    $('#OLsubfiltTA'  ).select2();
    $('#HRsubfiltProv').select2();
    $('#HRsubfiltRisk').select2();
    $('#HRsubfiltAPPT').select2();
    
    $('#OLSubFiltBut').click(function(){
        OLsubFilterWindow.applyFilters();
        $('#OLSubFilters').addClass('modalHide');
        startBodyScroll();
    });
    
    $('#HRSubFiltBut').click(function(){
        HRsubFilterWindow.applyFilters();
        $('#HRSubFilters').addClass('modalHide');
        startBodyScroll();
    });
    
    $('#OLSubFiltButClear').click(function(){
        OLsubFilterWindow.clear();
    });
    
    $('#HRSubFiltButClear').click(function(){
        HRsubFilterWindow.clear();
    });
    
    $('#ORSubFiltButClear').click(function(){
        OLsubFilterWindow.clear();
    });
    
    $('#HRSubFiltButClear').click(function(){
        HRsubFilterWindow.clear();
    });
        
    $('#OLSubFiltDismiss').on('click', function() {
        $('#OLSubFilters').addClass('modalHide');
        startBodyScroll();
    });
        
    $('#HRSubFiltDismiss').on('click', function() {
        $('#HRSubFilters').addClass('modalHide');
        startBodyScroll();
    });
}



var RPOCClick;
$('#RPOCBtn').on('click', function (e) {RPOCClick(e);});

$('body').on('click', '.pocButton', function() {
    var data = [], cmntList = '';

    data = $(this).attr('pocOpts').split(':');

    //alert(JSON.stringify(data));

    $('#HRPOCTitle').text(data[2]);

    $('#HRPOCText').val('');
    $('#HRPOCDatePicker').val('');
    followUpDate = 0;

    $.each(
        commentBigList[+data[3]],  //We got stringed by the join/split.  We need the int for the index.  + Does that.
        function(){
            var thisCmntDiv = commentDiv;
            thisCmntDiv = thisCmntDiv.replace('prsnlName' ,this.PRSNL_NAME      );
            thisCmntDiv = thisCmntDiv.replace('cmntFollow',this.FOLLOWUP_DT_TXT );
            thisCmntDiv = thisCmntDiv.replace('cmntDateTm',this.EVENT_END_DT_TXT);
            thisCmntDiv = thisCmntDiv.replace('cmntVal'   ,this.COMMENT         );
            cmntList   += thisCmntDiv;
        }
    );

    $('#providerMessages').html(cmntList);


    toggleModal('#HRPOCModal');

    RPOCClick = function (e) {
        e.preventDefault();  //Something goofy goin on.  Causing a page reload.
        var comment, fuDate, parseReply;

        comment = $('#HRPOCText').val();

        fuDate = followUpDate;

        //alert(JSON.stringify(commentBigList[+data[3]]));
        //
        //alert(comment);
        //if(fuDate !== 0){
        //    alert(fuDate);
        //    alert(fuDate.format('DD-MMM-YYYY'));
        //}

        if(comment.length > 0 || fuDate !== 0){
            if(fuDate === 0){
                opts = "^MINE^," + data[0] + "," + data[1] + ",^" + comment + "^,^0^";
            }else{
                opts = "^MINE^," + data[0] + "," + data[1] + ",^" + comment + "^,^" + fuDate.format('DD-MMM-YYYY') + "^";
            }
        
            parseReply = function(json){
                //alert(JSON.stringify(json.OUT_RS.COMMENTS));
        
                var rowData = HighRiskTable.row(data[4]).data();
        
                var retObj  = json.OUT_RS.COMMENTS;
        
                //alert(JSON.stringify(rowData[16]));
        
                rowData[HRLogCols.FOLLOW_UP_DATE] = retObj;
                rowData[HRLogCols.COMMENTS      ] = retObj;
        
                HighRiskTable.row(data[4]).data(rowData);
        
                HighRiskTable.draw();
        
                /*  Goofy stuff happens here... not sure if I should fix it or not but leaving it for now.
                    We were keeping all the comment objects in something called commentBigList, where it's index matched
                    row index.  When we do this work... adding a comment... the add script comes back with a new object.
                    We insert it into the rows data... and rerender.  When we rerender, it drops a new object into biglist...
                    but leaves the old.  But no row has an index to it anymore.
        
                    In theory, I could clean that up and pop it here?  Even then indexes would get messed up.
        
                    I think I don't care enough... and just hope that doesn't get me into trouble?
        
                */
        
        
            }
            console.log('cust_mp_hr_obgyn_comment ' + opts);
            mPageCCLCall('cust_mp_hr_obgyn_comment', parseReply)(opts);
        }
        toggleModal('#HRPOCModal');
    };
});

$('.collapse-link').on('click', function() {
    var card      = $(this).closest('.card'),
        card_icon = $(this).find('i'),
        card_txt  = card.find('.card-text');

    // fix for some div with hardcoded fix class
    if (card_txt.attr('style')){
        $(card_txt).slideToggle(200, function() {
            $(card).removeAttr('style');
        });
    } else {
        $(card_txt).slideToggle(200, function() {
            card_txt.css('display', 'none');
        });
    }

    card_icon.toggleClass('fa-chevron-up fa-chevron-down');
});

$('#HRPOCModalDismiss').on('click', function() {
    toggleModal('#HRPOCModal');
});





function populateLoc()
{
    var opts, parseReply;

    opts = "^MINE^"
    parseReply = function(json){
        var replyObj = json.OUT_RS.ORG;

        $('#select-practiceLoc').select2(
            {
                placeholder: "Select a Location",
                width: 'resolve',
                data:$.map($(replyObj), function (obj) {
                    obj.id = obj.id || obj.ID;
                    obj.text = obj.text || obj.NAME;
                    return obj;
                }),
            }
        );

        $('#select-practiceLocHR').select2(
            {
                placeholder: "Select a Location",
                width: 'resolve',
                data:$.map($(replyObj), function (obj) {
                    obj.id = obj.id || obj.ID;
                    obj.text = obj.text || obj.NAME;
                    return obj;
                }),
            }
        );

        reportLoadDone();

    }
    console.log('cust_mp_amb_orgs ' + opts);
    mPageCCLCall('cust_mp_amb_orgs', parseReply)(opts);
}


function populateProv()
{
    var opts, parseReply;

    opts = "^MINE^"
    parseReply = function(json){
        var provJSON = json.out_rs.prov;

        loadProviders(provJSON);

    }
    console.log('cust_obgyn_providers ' + opts);
    mPageCCLCall('cust_obgyn_providers', parseReply)(opts);
}


function openChart(perID, encID, location) {
    APPLINK(0, "$APP_AppName$", "/PERSONID="+perID + " /ENCNTRID=" + encID+  " /FIRSTTAB=^"+location+"^")
}

function openResult(perID, res){
    //https://wiki.cerner.com/display/public/MPDEVWIKI/Result+Viewer
    var viewer = window.external.DiscernObjectFactory("PVVIEWERMPAGE");

    viewer.CreateEventViewer(perID);

    viewer.AppendEvent(res);

    viewer.LaunchEventViewer();

}

function loadPatients(isBtn){
    var opts, parseReply, loc_cds, prov_cds, ord_cds, tempOptValue, provList = [], TAList = [];

    if(!orderLogLoading){
        orderLogLoading = true;
        
        if(autoRefreshTgl.isChecked() || isBtn){
            //OPTS = OUTDEV, LOCATION, beg_range, end_range

            if($("#select-practiceLoc").val().length > 0){
                loc_cds  = $("#select-practiceLoc").val().join(',');
                prov_cds = $("#select-provider"   ).val().join(',');
                 

                opts = "^MINE^,value(" + loc_cds + "),^" + fromDate + "^,^" + toDate + "^," + "value(" + prov_cds + ")"
                
                toggleModal('#OLWait');

                parseReply = function(json){
                    var replyObj, tableCnt, idx;

                    replyObj = json.OUT_RS.PAT;
                    tableCnt = json.OUT_RS.CNT;

                    AppointmentTable.search('');
                    AppointmentTable.clear().draw();

                    var column = AppointmentTable.column(4);
                    if(tableCnt > 0){
                        $("#toolbar2").html('');
                        var select = $('<select style="float: left" class="form-control input-sm" name="select-filter" id="select-filter"><option value="">All Providers</option></select>')
                                     .appendTo( $("#toolbar2") )
                                     .on( 'change', function () {
                                                        var val = $.fn.dataTable.util.escapeRegex($(this).val());
                                                        column.search( val ? '^'+val+'$' : '', true, false ).draw();
                                                    });

                        for(idx = 0; idx < tableCnt; idx++){
                            AppointmentTable.row.add([
                                 replyObj[idx].PER_ID,               /* 0  PER_ID      DT HIDDEN    */
                                 replyObj[idx].ENC_ID,               /* 1  ENC_ID      DT HIDDEN    */
                                 replyObj[idx].NAME,                 /* 2  NAME                     */
                                 replyObj[idx].FIN,                  /* 3  FIN                      */
                                 replyObj[idx].ORDER.PRSNL_NAME,     /* 4  PROVIDER                 */
                                 replyObj[idx].ORDER.DATE,           /* 5  ORDER_DATE               */
                                 replyObj[idx].ORDER.NAME,           /* 6  ORD_NAME                 */
                                 replyObj[idx].ORDER.STATUS,         /* 7  STATUS                   */
                                 replyObj[idx].RESULT.TURN_TM,       /* 8  TURNAROUND               */
                                 replyObj[idx].RESULT.RECEIVE_IND,   /* 9  RECEIVED                 */
                                 replyObj[idx].RESULT.DATE,          /* 10 RESULT_DATE              */
                                 replyObj[idx].ENDORSE.PRSNL_NAME,   /* 11 ENDORSED_BY              */
                                 replyObj[idx].ENDORSE.DATE,         /* 12 ENDORSE_DATE             */
                            ]);
                            
                            // Special stuff for subfilter modal
                            tempOptValue = replyObj[idx].ORDER.PRSNL_NAME;
                            if(provList.indexOf(tempOptValue) === -1) provList.push(tempOptValue);
                            
                            tempOptValue = replyObj[idx].RESULT.TURN_TM;
                            if(   TAList.indexOf(tempOptValue) === -1
                               && tempOptValue !== ''
                              ) TAList.push(tempOptValue);
                            
                        }
                        
                        provList.sort();
                        TAList.sort(function(a, b){
                            var intA, intB;
                            
                            intA = parseInt(a.replace(' days', '').replace(' day',''));
                            intB = parseInt(b.replace(' days', '').replace(' day',''));
                            
                            return intA-intB;
                        });
                        
                        function optMaker(value){
                            return new Option(value, value, false, false);
                        };
                        
                        $('#OLsubfiltProv').empty();
                        $('#OLsubfiltTA'  ).empty().append(optMaker('[Blanks]'));
                        
                        provList = provList.map(optMaker);
                        TAList   = TAList.map(optMaker);
                        
                        
                        provList.forEach(function (item){
                            $('#OLsubfiltProv').append(item);
                        });
                        TAList.forEach(function (item){
                            $('#OLsubfiltTA'  ).append(item);
                        });
                        
                        
                        column.data().unique().sort().each(function( d, j ){
                            if(d.length!=0 )
                            {
                                select.append( '<option value="'+d+'">'+d+'</option>' )
                            }
                        });

                    }else{
                        $("#toolbar2").html('');
                    }

                    AppointmentTable
                        .search('')
                        .columns().search( '' )
                        .draw();
                    NProgress.done();
                                         
                    toggleModal('#OLWait');
                    
                    orderLogLoading = false;

                }
                console.log("mp_get_obgyn_pats " + opts);
                mPageCCLCall('mp_get_obgyn_pats', parseReply)(opts);
            }
        }
    }
}


function loadHRPatients(isBtn){
    var opts, parseReply, handleErr, loc_cds, prov_cds, ord_cds, lookback, tempOptValue, provList = [], apptList = [];

    if(!HighRiskLoading){
        HighRiskLoading = true;
        
        if(autoRefreshHRTgl.isChecked() || isBtn){
            //OPTS = OUTDEV, LOCATION, beg_range, end_range

            if($("#select-practiceLocHR").val().length > 0){
                loc_cds = $("#select-practiceLocHR").val().join(',');
                prov_cds = $("#select-hrprovider"  ).val().join(',');

                lookback = $('#HRLookback > .active').val();

                opts = "^MINE^,value(" + loc_cds + ")," + lookback + ",value(" + prov_cds + "),'" + fromHRDate + "','" + toHRDate + "'"

                toggleModal('#HRWait');

                parseReply = function(json){
                    var replyObj, tableCnt, idx, reasons;

                    //alert(JSON.stringify(json));

                    replyObj = json.OUT_RS.QUAL;
                    tableCnt = json.OUT_RS.CNT;
                    statsObj = json.OUT_RS.STATS;

                    HighRiskTable.search('');
                    HighRiskTable.clear().draw();

                    commentBigList = [];

                    //var column = AppointmentTable.column(4);
                    if(tableCnt > 0){
                    
                        for(idx = 0; idx < tableCnt; idx++){
                            reasons = ''
                            obgyn   = ''

                            HighRiskTable.row.add([

                                '',                                 /* 0  LINKS                        */
                                replyObj[idx].REASONS,              /* 1  RISKS                        */
                                replyObj[idx].PATIENT.PER_ID,       /* 2  PER_ID             DT HIDDEN */
                                replyObj[idx].PATIENT.ENC_ID,       /* 3  ENC_ID             DT HIDDEN */
                                replyObj[idx].ORDERS[0].ORD_ID,     /* 4  ORD_ID             DT HIDDEN */
                                replyObj[idx].PATIENT.LOCATION,     /* 5  LOCATION           DT HIDDEN */
                                replyObj[idx].PATIENT.NAME,         /* 6  NAME                         */
                                replyObj[idx].PATIENT.DOB,          /* 7  DOB                          */
                                replyObj[idx].PATIENT.PHONE,        /* 8  PHONE                        */
                                replyObj[idx].PATIENT.PCP,          /* 9  PCP                          */
                                replyObj[idx].OBGYN,                /* 10 OB_GYN                       */
                                replyObj[idx].LAST_APPT,            /* 11 LAST                         */
                                replyObj[idx].LAST_APPT.APPT_TYPE,  /* 12 LAST_APPT_TYPE     DT HIDDEN */
                                replyObj[idx].LAST_APPT.DATETIME,   /* 13 LAST_APPT_DATE     DT HIDDEN */
                                replyObj[idx].LAST_APPT.LOCATION,   /* 14 LAST_APPT_LOC      DT HIDDEN */
                                replyObj[idx].LAST_APPT.PROV_NAME,  /* 15 LAST_APPT_PROV     DT HIDDEN */
                                replyObj[idx].NEXT_APPT,            /* 16 NEXT                         */
                                replyObj[idx].NEXT_APPT.APPT_TYPE,  /* 17 NEXT_APPT_TYPE     DT HIDDEN */
                                replyObj[idx].NEXT_APPT.DATETIME,   /* 18 NEXT_APPT_DATE     DT HIDDEN */
                                replyObj[idx].NEXT_APPT.LOCATION,   /* 19 NEXT_APPT_LOC      DT HIDDEN */
                                replyObj[idx].NEXT_APPT.PROV_NAME,  /* 20 NEXT_APPT_PROV     DT HIDDEN */
                                replyObj[idx].ORDERS,               /* 21 ORDER_RESULTS                */
                                replyObj[idx].ORDERS,               /* 22 ORDER_RESULTS                */
                                replyObj[idx].ORDERS,               /* 23 ENDORSED_BY                  */
                                replyObj[idx].ORDERS,               /* 24 ENDORSE_DATE                 */
                                replyObj[idx].COMMENTS,             /* 25 FOLLOW_UP_DATE               */
                                replyObj[idx].COMMENTS              /* 26 COMMENTS                     */
                            ]);
                        
                        
                            // Special stuff for subfilter modal
                            tempOptValue = replyObj[idx].ORDERS;
                            tempOptValue.forEach(function (item){
                                var itemVal;
                                
                                itemVal = item.ORD_PROV_NAME;
                                
                                if(provList.indexOf(itemVal) === -1) provList.push(itemVal);
                            });
                            
                            //We don't have to do the risks, they are set.
                                                        
                            tempOptValue = replyObj[idx].NEXT_APPT.APPT_TYPE;
                            if(   apptList.indexOf(tempOptValue) === -1
                               && tempOptValue !== '') apptList.push(tempOptValue);
                        
                        }
                    
                    }else{
                        $("#toolbar2").html('');
                        alert("No Data found for the selection");
                    }
                        
                    provList.sort();
                    apptList.sort();
                        
                    function optMaker(value){
                        return new Option(value, value, false, false);
                    };
                    
                
                    $('#HRsubfiltProv').empty();
                    $('#HRsubfiltAPPT').empty().append(optMaker('[Blank]'));
                    
                    provList = provList.map(optMaker);
                    apptList = apptList.map(optMaker);
            
                    provList.forEach(function (item){
                        $('#HRsubfiltProv').append(item);
                    });
                    apptList.forEach(function (item){
                        $('#HRsubfiltAPPT').append(item);
                    });
                    
                    HighRiskTable
                        .search('')
                        .columns().search( '' )
                        .draw();
                    NProgress.done();

                    //Not sure why I am getting multiple events.  I suspect DataTables performance optimizations...
                    $('.patientOrderLink').unbind();
                    $('.patientOrderLink').on('click', function () {
                        var data = this.id.split(':');
                        openChart(data[1],data[2],"Orders");
                    } );

                    $('.patientRecLink').unbind();
                    $('.patientRecLink').on('click', function () {
                        var data = this.id.split(':');
                        openChart(data[1],data[2],"Health Maintenance");
                    } );

                    $('[data-toggle="popover"]').popover({
                        html: true,
                        placement: 'auto',
                        container: 'body',
                        delay: { "show": 500, "hide": 100 }
                    })
                    .on("focus", function () {
                                $(this).popover("show");
                            })
                    .on("focusout", function () {
                                var _this = this;
                                if (!$(".popover:hover").length) {
                                    $(this).popover("hide");
                                }
                                else {
                                    $('.popover').mouseleave(function() {
                                        $(_this).popover("hide");
                                        $(this).off('mouseleave');
                                    });
                                }
                            });



                    $('[data-toggle="popover"]').on('shown.bs.popover', function(){
                        $('.popoverMagic').unbind();
                        $('.popoverMagic').on('click', function () {
                            var data  = this.id.split(':');

                            //remove the uniqueness text
                            data.shift();

                            //We are strings now... woops... better fix that
                            data = data.map(function(x) {return(parseInt(x))});

                            //The rest can be sent to the openResult function
                            openResult(data[0], data[1]);

                        } );
                        $('.popoverMagic2').unbind();
                        $('.popoverMagic2').on('click', function () {
                            var data  = this.id.split(':');

                            //remove the uniqueness text
                            data.shift();

                            //We are strings now... woops... better fix that
                            data = data.map(function(x) {return(parseInt(x))});

                            //The rest can be sent to the openResult function
                            openChart(data[0], data[1], 'Orders');

                        } );
                    });
                    
                    toggleModal('#HRWait');
                    
                    HighRiskLoading = false;
                }
                handleErr = function(){
                    
                    toggleModal('#HRWait');
                    
                    alert('Error loading page, possible timeout.  Try changing filters.');
                    
                    HighRiskLoading = false;
                    
                }
                console.log("cust_mp_high_risk_obgyn " + opts);
                mPageCCLCall('cust_mp_high_risk_obgyn', parseReply, null, handleErr)(opts);
            }
        }
    }
}


function updateDataTiles(){
    var shownRows = AppointmentTable.rows({filter: 'applied'})
      , odCount   = 0
      , odPer     = 0
      , turnCount = 0
      , avgTurn   = 0
      , totCount  = 0
      ;
      
    shownRows = shownRows.data().toArray();
    totCount  = shownRows.length;
    
    shownRows.forEach(function (item){
        var turnData;
        
        //Overdues
        if(item[ordLogCols.RECEIVED] === 0)  odCount++;
        
        //Turnaround
        if(item[ordLogCols.TURNAROUND] !== ''){
            //Kill the days with a replace.
            turnData = parseInt(item[ordLogCols.TURNAROUND].replace(/[^0-9]/g, ""));
            
            turnCount += 1;
            avgTurn  += turnData;
        }
    });
    
    if(totCount  > 0) odPer   = Math.round(odCount / totCount * 100);
    if(turnCount > 0) avgTurn = Math.round(avgTurn / turnCount);
    
    loadStats(odCount, odPer, avgTurn);
}


function updateHRDataTiles(){
    // We are going to make the counts dynamic on the table contents.
    
    var shownRows = HighRiskTable.rows({filter: 'applied'})
      , totCount  = 0
      , oocCount  = 0
      , hrCount   = 0
      , coloCount = 0
      , tissCount = 0
      ;
      
    shownRows = shownRows.data().toArray();
    totCount  = shownRows.length;
    
    shownRows.forEach(function (item){
        var data   = item[HRLogCols.RISKS]
          , length = 0
          , i
          ;
        
        length = item[HRLogCols.RISKS].length;
        
        data.forEach(function (data){
            if(data.REASON_FLAG === 1) oocCount++;
            if(data.REASON_FLAG === 2) hrCount++;
            if(data.REASON_FLAG === 4) coloCount++;
            if(data.REASON_FLAG === 8) tissCount++;
        });
    });
    
    loadHRStats(oocCount, hrCount, coloCount, tissCount);
    
}



function loadStats(over_cnt, over_per, avg_turn){
    //If we have data to show, show the bar
    if(over_cnt > 0 || over_per > 0 || avg_turn > 0) $('#statsRow').show();
    else $('#statsRow').hide();


    //Remove old stylings
    $('#totCol'   ).removeClass('yellow red green');
    $('#perDueCol').removeClass('yellow red green');
    $('#avgturn'  ).removeClass('yellow red green');


    //Handle Overdue tile
    if(over_per >= 0 && over_per < 10) {
        $('#totCol'   ).addClass('green');
        $('#perDueCol').addClass('green');
        
    }else if(over_per < 15){
        $('#totCol'   ).addClass('yellow');
        $('#perDueCol').addClass('yellow');
    }
    else{
        $('#totCol').addClass('red');
        $('#perDueCol').addClass('red');
    }

    $('#totCol').text(over_cnt);
    $('#perDueCol').text(over_per + '%');


    //Handle Turn around Tile
    if(avg_turn >= 0 && avg_turn < 5) $('#avgturn').addClass('green');
    else if(avg_turn < 7)             $('#avgturn').addClass('yellow');
    else                              $('#avgturn').addClass('red');


    if(avg_turn === 1) $('#avgturn').text(avg_turn + ' day');
    else $('#avgturn').text(avg_turn + ' days');

}


function loadHRStats(outCareCnt, hrCnt, colpoCnt, outstandCnt){
    //If we have data to show, show the bar
    if(outCareCnt > 0 || hrCnt > 0 || colpoCnt > 0 || outstandCnt > 0) $('#statsRowHR').show();
    else $('#statsRowHR').hide();

    $(  '#oochr').text(outCareCnt);
    $(   '#hrhr').text(hrCnt);
    $('#colpohr').text(colpoCnt);
    $(   '#tphr').text(outstandCnt);


    $(  '#oochr').unbind();
    $(   '#hrhr').unbind();
    $('#colpohr').unbind();
    $(   '#tphr').unbind();


    var genericClickhandler = function(id){
        var searchTerm;
        
        if(id === '#oochr'  ) searchTerm = 'Out of Care'
        if(id === '#hrhr'   ) searchTerm = 'High Risk'
        if(id === '#colpohr') searchTerm = 'Needs Colposcopy'
        if(id === '#tphr'   ) searchTerm = 'Tissue Pathology Outstanding'
        
        if($(id).hasClass('tileCountActive')){
            $(id).removeClass('tileCountActive');
            HighRiskTable.search('').draw();
            
        }else{
            $('#oochr,#hrhr,#colpohr,#tphr').removeClass('tileCountActive');
            $(id).addClass('tileCountActive');
            
            HighRiskTable.search(searchTerm).draw();
        }
    }

    $(  '#oochr').unbind('click').click(function () { genericClickhandler('#oochr'  );});
    $(   '#hrhr').unbind('click').click(function () { genericClickhandler('#hrhr'   );});
    $('#colpohr').unbind('click').click(function () { genericClickhandler('#colpohr');});
    $(   '#tphr').unbind('click').click(function () { genericClickhandler('#tphr'   );});
}


function saveFilters(){
    var opts, parseReply, filtObj, filtString, provData;
    
    filtObj = {
          "locations" : []
        , "providers" : []
    }
    
    if($("#select-practiceLoc").val()) {
        filtObj.locations = $("#select-practiceLoc").val().map(function(x) {return(parseInt(x))});
    }
    if($("#select-provider"   ).val()){
        provData = $('#select-provider').select2('data');
        
        provData.forEach(function(item){
            filtObj.providers.push({
                 id  : parseInt(item.id)
               , text: item.text
            });
        });
    }
    
    filtString = JSON.stringify(filtObj);

    opts = "^MINE^,value($USR_PERSONID$),^OBGYNFILT^,^" + filtString + "^"
    parseReply = function(json){
        //right now we don't really care if it is successful or not, and we already checked for errors in the call
    }
    console.log('0_maintain_cust_mpage_data ' + opts);
    mPageCCLCall('0_maintain_cust_mpage_data', parseReply)(opts);
}

function saveHRFilters(){
    var opts, parseReply, filtObj, filtString, provData;
    
    filtObj = {
          "locations" : []
        , "providers" : []
    }
    
    
    if($("#select-practiceLocHR").val()) {
        filtObj.locations = $("#select-practiceLocHR").val().map(function(x) {return(parseInt(x))});
    }
    if($("#select-hrprovider"   ).val()){
        provData = $('#select-hrprovider').select2('data');
        
        provData.forEach(function(item){
            filtObj.providers.push({
                 id  : parseInt(item.id)
               , text: item.text
            });
        });
    }
    
    filtString = JSON.stringify(filtObj);

    opts = "^MINE^,value($USR_PERSONID$),^OBGYNHRFILT^,^" + filtString + "^"
    parseReply = function(json){
        //right now we don't really care if it is successful or not, and we already checked for errors in the call
    }
    console.log('0_maintain_cust_mpage_data ' + opts);
    mPageCCLCall('0_maintain_cust_mpage_data', parseReply)(opts);
}


$(document).ready(function() {
    init_DataTables();
    init_daterangepicker();
    init_subFilts();
    NProgress.start();
    
    init_switchery();
    
    $("#OLWait").css({top: $('#tab-container').offset().top, left: $('#tab-container').offset().left});
    $("#HRWait").css({top: $('#tab-container').offset().top, left: $('#tab-container').offset().left});
    
    populateLoc();
    populateProv();

});