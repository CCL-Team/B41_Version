var theme
var patientReferraOrders = ""
var patientChrgDetTbl = ""
var incmpItmsDetTbl = ""
var isTableLoaded = false;
var workQueueTable = ""
var chart_refOrder = "";
var chatWMQ = "";
var DateArr = [];
var WMQArr = [];
var WMQBuck = [];
var OrderCountArr = [];
var NRTOCountArr = [];
var EXTERNALCnt = [];
var INTERNALCnt = []
var PercArr = [];
var dateRangeStr = ""
var WMQSelected = ""
var LocSelected = ""
var bodySave = $('body')[0].innerHTML;
var fromDate = moment().subtract(6, 'day').endOf('day').format('DD-MMM-YYYY');
var locDate = $('#LocDateT').clone();
var cloneTemplate = ""
var detailsTableHtml = $("#detailsTable").html();
var iTableCounter = 1;
var toDate = moment().endOf('day').format('DD-MMM-YYYY');
var pcpDetailDiv = "<div class='widget_summary active'>\
<div class='w_left w_25 pcpname'>\
		<span>pcpNameHere</span>\
</div>\
<div class='w_center w_55'>\
		<div class='progress'>\
				<div class='progress-bar bg-green' role='progressbar' aria-valuenow='60' aria-valuemin='0' aria-valuemax='100' style='width: 0%;'>\
						<span class='sr-only'>percentOfReferrall</span>percentSpanText\
				</div>\
		</div>\
</div>\
<div class='w_right w_20'>\
		<span>pcpReferralCount</span>\
</div>\
<div class='clearfix'></div>\
</div>"

var dateLocationTemplate = '<template id="LocDateT">\
                        <div class="col-md-6" id="simsim">\
                            <div class="col-md-6">\
                                <div class="item form-group">\
                                    <label style="text-align: right;" class="control-label col-md-4 col-sm-4 col-xs-12" for="name">Ambulatory Location</label>\
                                    <div class="col-md-8 col-sm-8 col-xs-12">\
                                        <div>\
                                            <select class="selectLoc" name="select-practiceLocCR" id="select-practiceLocCR" style="width: 100%">\
                                                <option></option>\
                                            </select>\
                                        </div>\
                                    </div>\
                                </div>\
                            </div>\
                            <div class="col-md-6">\
                                <div id="reportrangeCR" class="pull-right" style="background: #fff; cursor: pointer; padding: 5px 10px; border: 1px solid #ccc">\
                                    <i class="glyphicon glyphicon-calendar fa fa-calendar"></i>\
                                    <span>December 30, 2014 - January 28, 2015</span> <b class="caret"></b>\
                                </div>\
                            </div>\
                        </div>\
                    </template>'

var orderProviderList =
    "<li class='media event orderingProvider pointer'>\
    <a class='pull-left border-aero profile_thumb'>\
    <i class='fa fa-user-md aero'></i>\
    </a>\
    <div class='media-body'>\
        <a class='title' href='#'>pcpNameHere</a>\
        <p><strong>percentOfReferrall </strong><small> of pcpReferralCount referrals</small></p>\
    </div>\
</li>"

var accessDenied = '<div class="container body">\
<div class="main_container">\
  <div class="col-md-12">\
    <div class="col-middle">\
      <div class="text-center text-center">\
        <h1 class="error-number">403</h1>\
        <h2>Access denied</h2>\
        <p>Full authentication is required to access this page. Please contact help desk if you beleive you should have access to this page <a href="#">Report this?</a>\
        </p>\
        <div class="mid_center">\
          <h3>Search</h3>\
          <form>\
            <div class="col-xs-12 form-group pull-right top_search">\
              <div class="input-group">\
                <input type="text" class="form-control" placeholder="Search for...">\
                <span class="input-group-btn">\
                        <button class="btn btn-default" type="button">Go!</button>\
                    </span>\
              </div>\
            </div>\
          </form>\
        </div>\
      </div>\
    </div>\
  </div>\
</div>\
</div>'

/*
Control Event Triggers
*/
// Location dropdown change even listener
$('#select-practiceLoc').on("change", function (e) {
    loadPatients(fromDate, toDate, $("#select-practiceLoc").select2("val"));
});

$('#select-WorkListQueue').on("change", function (e) {
    //alert("here")
    WMQSelected = $("#select-WorkListQueue").select2('data')[0]['text'].trim();
    $('#currDatelbl').html("Date: " + moment().endOf('day').format('DD-MMM-YYYY'))
    loadWorkQueue($("#select-WorkListQueue").select2("val"));
});


$("#select-practiceLocCR").on("change", function (e) {
    LocSelected = $("#select-practiceLocCR").select2('data')[0]['text'].trim();    
    loadCharges(fromDate, toDate, $("#select-WorkListQueue").select2("val"));
});


 // $('body').on('change', '.select-practiceLocCR', function (e){
   // try{
    // alert($(this).id + " " + $(this).val())
    // LocSelected = $(this).select2('data')[0]['text'].trim();
    // loadCharges(fromDate, toDate, $(this).val());
   // }
   // catch(e){alert(e.message)}
  // });


$('#patientReferraOrders tbody').on('click', 'td', function () {
  var col = patientReferraOrders.cell(this).index().columnVisible
  if (col == 0) {
    var data = patientReferraOrders.row($(this).parents('tr')).data();
    Lib.openChart(data[0], data[1], "Orders")
  }
});

// $('.patientNameLink').on('click', function () {
  // alert("")
// });


$('#patientChrgDet tbody').on('click', 'td', function () {
  var col = patientChrgDetTbl.cell(this).index().columnVisible
  if (col == 2) {
    var data = patientChrgDetTbl.row($(this).parents('tr')).data();
    Lib.openChart(data[0], data[1], "Orders")
  }
});

$('.detailsTableInfo tbody').on('click', 'td', function () {
  var col = patientChrgDetTbl.cell(this).index().columnVisible
  if (col == 2) {
    var data = patientChrgDetTbl.row($(this).parents('tr')).data();
    alert(data[0])
    // Lib.openChart(data[0], data[1], "Orders")
  }
});

 $('body table').on('click', '.detailsTableInfo', function (e){
   try{
    alert($(this).id + " " + $(this).val())
    // LocSelected = $(this).select2('data')[0]['text'].trim();
    // loadCharges(fromDate, toDate, $(this).val());
   }
   catch(e){alert(e.message)}
  })

function format(d){
        
     // `d` is the original data object for the row
     return d
     // '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">' +
         // '<tr>' +
             // '<td>Full name:</td>' +
             // '<td>' + d.name + '</td>' +
         // '</tr>' +
         // '<tr>' +
             // '<td>Extension number:</td>' +
             // '<td>' + d.extn + '</td>' +
         // '</tr>' +
         // '<tr>' +
             // '<td>Extra info:</td>' +
             // '<td>And any further details here (images etc)...</td>' +
         // '</tr>' +
     // '</table>';  
}


// Add event listener for opening and closing details
  $('#incmpItmsDet tbody').on('click', 'td.details-control', function () {    
    try{      
      var tr = $(this).closest('tr');
      var tdi = tr.find("i.far");
      var row = incmpItmsDetTbl.row(tr);
      var data = incmpItmsDetTbl.row($(this).parents('tr')).data();

      if (row.child.isShown()) {
         // This row is already open - close it
        row.child.hide();
        tr.removeClass('shown');
        tdi.first().toggleClass('fa-plus-square fa-minus-square')
        // tdi.first().removeClass('fa-minus-square');
        // tdi.first().addClass('fa-plus-square');
      }
     else {
        // Open this row
        var detailsRowData = data[10];
        //incmpItmsDetTbl.fnOpen(row, fnFormatDetails(iTableCounter, detailsTableHtml), 'details');
        row.child(fnFormatDetails(iTableCounter, detailsTableHtml)).show();
        oInnerTable = $("#detailsTable_" + iTableCounter).DataTable({
                    "bFilter": false,
                    "aaData": detailsRowData,
                    "bSort" : true, // disables sorting
                    "aoColumns": [                    
                      { "mDataProp": "PERSON_ID" },
                      { "mDataProp": "ENCNTR_ID" },
                      { "mDataProp": "PT_NAME" },
                      { "mDataProp": "ADMIT_DISCHARGE" },
                      { "mDataProp": "INC_ITEM_VC" },
                      { "mDataProp": "INC_ITEM_DAYS" }
                    ],
                    "columnDefs": [
                    {
                        "targets": [0, 1],
                        "visible": false,
                        "searchable": false
                    }],
                    "createdRow": function (row, data, index) {
                        $(row).find('td:eq(0)').addClass('patientNameLink pointer');
                    }
                });
                $("#detailsTable_" + iTableCounter+" tbody").on('click', 'td', function () {       
                  try{
                      var col = oInnerTable.cell(this).index().columnVisible
                      if (col == 0) {
                        var data = oInnerTable.row($(this).closest('tr')).data()                      
                        Lib.openChart(data["PERSON_ID"], data["ENCNTR_ID"], "")
                      }
                    }
                    catch(e){
                      alert(e.message)
                    }                   
                  //var col = oInnerTable.cell(this).index().columnVisible
                   // table.row(this).data()
                 // if (col == 2) {
                 //   var data = oInnerTable.row(this).data();
                   // alert(data)
                    // Lib.openChart(data[0], data[1], "")
                  //}
                });
                iTableCounter = iTableCounter + 1;
          // row.child().show();
        // row.child(format(data[10])).show();
        //row.child(format(detailsTableHtml).show();
        //$('#patientIncmpDetail').DataTable()
        tr.addClass('shown');
        tdi.first().toggleClass('fa-plus-square fa-minus-square')
        // tdi.first().removeClass('fa-plus-square');
        // tdi.first().addClass('fa-minus-square');
      }
    }
    catch(e){alert(e.message)}
  } );

function fnFormatDetails(table_id, html) {
    var sOut = "<table id='detailsTable_" + table_id + "' class='table table-striped table-bordered jambo_table dt-responsive' style='width:100%'>";
    sOut += html;
    sOut += "</table>";
    return sOut;
}


$('td.patientNameLink').click(function() {
    alert('ho ho ho');
});
$('.patientNameLink').click(function (event) {
alert('ho ho ho');

});
$('#pcpDiv').on('click', '.orderingProvider', function myFunction(event) {
    patientReferraOrders.search('').columns().search('').draw();
    $('#referringProviderFilter').text('')
    if ($(this).is('.activeSelection')) {
      $(this).removeClass('activeSelection');
    }
    else {
      $(this).parent().find('.activeSelection').removeClass('activeSelection')
      $(this).addClass('activeSelection');
      var pcpName = $(this).find('.title').text()      
      patientReferraOrders.column(3).search(pcpName.trim()).draw();
      $('#referringProviderFilter').text(pcpName)
    }
});

$('#pcpDiv2').on('click', '.orderingProvider', function myFunction(event) {
    patientChrgDetTbl.search('').columns().search('').draw();
    $('#attendingProviderFilter').text('')
    if ($(this).is('.activeSelection')) {
      $(this).removeClass('activeSelection');
    }
    else {
      $(this).parent().find('.activeSelection').removeClass('activeSelection')
      $(this).addClass('activeSelection');
      var pcpName = $(this).find('.title').text()
      patientChrgDetTbl.column(8).search(pcpName.trim()).draw();
      $('#attendingProviderFilter').text(pcpName)
    }
});

function openChart(personId, encntrId, location) {
    APPLINK(0, "$APP_AppName$", "/PERSONID=" + personId + " /ENCNTRID=" + encntrId + " /FIRSTTAB=^" + location + "^")
}

function sortJSON(data, key, way) {
    return data.sort(function (a, b) {
        var x = a[key]; var y = b[key];
        if (way === '123') { return ((x < y) ? -1 : ((x > y) ? 1 : 0)); }
        if (way === '321') { return ((x > y) ? -1 : ((x < y) ? 1 : 0)); }
    });
}


var iitemsCount = 0;
var returns = [];
function processIIReturns(IIRetList){
    
    var retObj = {
          QUAL_CNT         : 0
        , COSIGN_ORDERS_CNT: 0
        , DOCUMENTS_CNT    : 0
        , ENDORSEMENTS_CNT : 0
        , NOTES_CNT        : 0
        , MESSAGES_CNT     : 0
        , PROPOSED_ORD_CNT : 0
        , RESULTS_CNT      : 0
        , RX_REFILLS_CNT   : 0
        , RX_DAYSLAG_CNT   : 0
        
        , PRSNL_QUAL       : []
         
        , QUAL             : []
        
    };
    
    
    $.each(IIRetList, function (i, val) {                
        retObj.QUAL_CNT          += val.ret.QUAL_CNT         ;
        retObj.COSIGN_ORDERS_CNT += val.ret.COSIGN_ORDERS_CNT;
        retObj.DOCUMENTS_CNT     += val.ret.DOCUMENTS_CNT    ;
        retObj.ENDORSEMENTS_CNT  += val.ret.ENDORSEMENTS_CNT ;
        retObj.NOTES_CNT         += val.ret.NOTES_CNT        ;
        retObj.MESSAGES_CNT      += val.ret.MESSAGES_CNT     ;
        retObj.PROPOSED_ORD_CNT  += val.ret.PROPOSED_ORD_CNT ;
        retObj.RESULTS_CNT       += val.ret.RESULTS_CNT      ;
        retObj.RX_REFILLS_CNT    += val.ret.RX_REFILLS_CNT   ;
        retObj.RX_DAYSLAG_CNT    += val.ret.RX_DAYSLAG_CNT   ;
    
        retObj.QUAL = retObj.QUAL.concat(val.ret.QUAL);
        
        $.each(val.ret.PRSNL_QUAL, function (i2, val2) {
            
            if(retObj.PRSNL_QUAL.length === 0){
                retObj.PRSNL_QUAL.push(val2);
            }else{
                
                var idx = -1;
                for (var i = 0; i < retObj.PRSNL_QUAL.length; i++) {
                    if(retObj.PRSNL_QUAL[i].PRSNL_ID === val2.PRSNL_ID) idx = i;
                }
                
                
                if(idx >= 0) {
                    //provObj.PRSNL_ID            =
                    //provObj.LAST_LOGON          =
                    //provObj.USERNAME            =
                    //provObj.NPI                 =
                    //provObj.POSITION            =
                    //provObj.RESP_USER_NAME      =
                    retObj.PRSNL_QUAL[idx].COSIGN_ORDERS_CNT  += val2.COSIGN_ORDERS_CNT;
                    retObj.PRSNL_QUAL[idx].DOCUMENTS_CNT      += val2.DOCUMENTS_CNT    ;
                    retObj.PRSNL_QUAL[idx].ENDORSEMENTS_CNT   += val2.ENDORSEMENTS_CNT ;
                    retObj.PRSNL_QUAL[idx].NOTES_CNT          += val2.NOTES_CNT        ;
                    retObj.PRSNL_QUAL[idx].MESSAGES_CNT       += val2.MESSAGES_CNT     ;
                    retObj.PRSNL_QUAL[idx].PROPOSED_ORD_CNT   += val2.PROPOSED_ORD_CNT ;
                    retObj.PRSNL_QUAL[idx].RESULTS_CNT        += val2.RESULTS_CNT      ;
                    retObj.PRSNL_QUAL[idx].RX_REFILLS_CNT     += val2.RX_REFILLS_CNT   ;
                    retObj.PRSNL_QUAL[idx].NOTE_NOT_STARTED   += val2.NOTE_NOT_STARTED ;
                    retObj.PRSNL_QUAL[idx].IN_PROGRESS_NOTE   += val2.IN_PROGRESS_NOTE ;
                    retObj.PRSNL_QUAL[idx].FORWARDED_NOTE     += val2.FORWARDED_NOTE   ;
                    retObj.PRSNL_QUAL[idx].NEED_ENDORSEMENTS  += val2.NEED_ENDORSEMENTS;
                    retObj.PRSNL_QUAL[idx].DOCUMENTS_COUNT    += val2.DOCUMENTS_COUNT  ;
                    retObj.PRSNL_QUAL[idx].RST_PEND_ENDORS    += val2.RST_PEND_ENDORS  ;
                    retObj.PRSNL_QUAL[idx].RST_PEND           += val2.RST_PEND         ;
                    retObj.PRSNL_QUAL[idx].PROP_ORD_COUNT     += val2.PROP_ORD_COUNT   ;
                    retObj.PRSNL_QUAL[idx].COSIGN_ORD_COUNT   += val2.COSIGN_ORD_COUNT ;
                    retObj.PRSNL_QUAL[idx].MESSAGE_COUNT      += val2.MESSAGE_COUNT    ;
                    retObj.PRSNL_QUAL[idx].RX_REFILS_COUNT    += val2.RX_REFILS_COUNT  ;
                    
                    retObj.PRSNL_QUAL[idx].PDETAIL            =  retObj.PRSNL_QUAL[idx].PDETAIL.concat(val2.PDETAIL);
                }
                else{
                    retObj.PRSNL_QUAL.push(val2);
                }
            }
        });
    });
    
    return retObj;
}

function loadIIReturns(procObj){
   try{
     reply = procObj;
     
     incmpItmsDetTbl.search('');
     incmpItmsDetTbl.clear().draw();  
     
     if(reply.PRSNL_QUAL.length > 0){  
       $("#co_cnt"  ).text(reply.COSIGN_ORDERS_CNT)
       $("#doc_cnt" ).text(reply.DOCUMENTS_CNT)
       $("#end_cnt" ).text(reply.ENDORSEMENTS_CNT)
       $("#msg_cnt" ).text(reply.MESSAGES_CNT)
       $("#note_cnt").text(reply.NOTES_CNT)
       $("#prop_cnt").text(reply.PROPOSED_ORD_CNT)
       $("#rslt_cnt").text(reply.RESULTS_CNT)
       $("#rx_cnt"  ).text(reply.RX_REFILLS_CNT)
       $("#adl_cnt" ).text(reply.RX_DAYSLAG_CNT)
       
      try {
         $.each(reply.PRSNL_QUAL, function (i2, val2) {                
             incmpItmsDetTbl.row.add([    
               "",
               val2.RESP_USER_NAME,
               val2.COSIGN_ORDERS_CNT,
               val2.DOCUMENTS_CNT,
               val2.ENDORSEMENTS_CNT,
               val2.MESSAGES_CNT,
               val2.NOTES_CNT,
               val2.PROPOSED_ORD_CNT,
               val2.RESULTS_CNT,
               val2.RX_REFILLS_CNT,                    
               val2.PDETAIL,
               (val2.COSIGN_ORDERS_CNT + val2.DOCUMENTS_CNT + val2.ENDORSEMENTS_CNT +val2.MESSAGES_CNT + val2.NOTES_CNT +val2.PROPOSED_ORD_CNT +val2.RESULTS_CNT +val2.RX_REFILLS_CNT)
               ])
         });
       }
       catch (e) {
         alert(e.description);
         return;
         waitingDialog.hide();
       }       
       incmpItmsDetTbl
         .search('')
         .columns().search('')
         .draw();
       incmpItmsDetTbl.columns.adjust().draw();
       waitingDialog.hide();
     }else{
        
        $("#co_cnt"  ).text('0');
        $("#doc_cnt" ).text('0');
        $("#end_cnt" ).text('0');
        $("#msg_cnt" ).text('0');
        $("#note_cnt").text('0');
        $("#prop_cnt").text('0');
        $("#rslt_cnt").text('0');
        $("#rx_cnt"  ).text('0');
        $("#adl_cnt" ).text('0');
         
        alert("No Data for that time period.")
        console.log('Return processed, but no data.');
        waitingDialog.hide();
     }       
   }
   catch(e){
     alert(e.message + reply)
     waitingDialog.hide();
     incmpItmsDetTbl.search('');
     incmpItmsDetTbl.clear().draw();  
   }
}

function loadIncmpItms(fromDate, toDate, selVal) {
  if (selVal.length > 0 || typeof mmmtest != 'undefined' && mmmtest === 1){
    waitingDialog.show();
    var promptVal  = "^MINE^,^" + fromDate + "^, ^" + toDate + "^, 1, 1, 1, 0, 0, 0, 0, 0, 0, value(" + selVal.trim() + ".00),VALUE(0)"
    var promptVal2 = "^MINE^,^" + fromDate + "^, ^" + toDate + "^, 0, 0, 0, 1, 1, 1, 0, 0, 0, value(" + selVal.trim() + ".00),VALUE(0)"
    var promptVal3 = "^MINE^,^" + fromDate + "^, ^" + toDate + "^, 0, 0, 0, 0, 0, 0, 1, 1, 1, value(" + selVal.trim() + ".00),VALUE(0)"
    //alert(promptVal)
    // var promptVal = "^MINE^, value(" + selVal.trim() + ".00), 2, ^ENTER LAST NAME^, 0, VALUE(0), ^" + fromDate + "^, ^" + toDate + "^, 1, 1"      
    
    if(typeof mmmtest != 'undefined' && mmmtest === 1){
        //var promptVal  = "^MINE^,^10-Sep-2024 00:00:00^, ^16-Sep-2024 23:59:59^, 1, 1, 1, 0, 0, 0, 0, 0, 0, value(815479211.00),VALUE(0)";
        //var promptVal2 = "^MINE^,^10-Sep-2024 00:00:00^, ^16-Sep-2024 23:59:59^, 0, 0, 0, 1, 1, 1, 0, 0, 0, value(815479211.00),VALUE(0)";
        //var promptVal3 = "^MINE^,^10-Sep-2024 00:00:00^, ^16-Sep-2024 23:59:59^, 0, 0, 0, 0, 0, 0, 1, 1, 1, value(815479211.00),VALUE(0)";
        var promptVal  = "^MINE^,^10-Sep-2024 00:00:00^, ^16-Sep-2024 23:59:59^, 1, 1, 1, 0, 0, 0, 0, 0, 0, value(834126745.00),VALUE(0)";
        var promptVal2 = "^MINE^,^10-Sep-2024 00:00:00^, ^16-Sep-2024 23:59:59^, 0, 0, 0, 1, 1, 1, 0, 0, 0, value(834126745.00),VALUE(0)";
        var promptVal3 = "^MINE^,^10-Sep-2024 00:00:00^, ^16-Sep-2024 23:59:59^, 0, 0, 0, 0, 0, 0, 1, 1, 1, value(834126745.00),VALUE(0)";
    }
    
    iitemsCount = 0;
    returns = [];
    
    console.log("14_mp_opsdash_IItem " + promptVal);
    Lib.makeCall("14_mp_opsdash_IItem",promptVal,true,function(reply) {        
        var procObj;
        
        returns.push({call: 'Return 1', ret: JSON.parse(reply).ITEMS});
        console.log('Return 1 back');
        
        iitemsCount ++;
        
        if(iitemsCount === 3){
            procObj = processIIReturns(returns);
            loadIIReturns(procObj);
        }
        
    },function(){
        alert("Query Failed, please contact help desk with screenshot")
        console.log('Return 1 failed');
        waitingDialog.hide();
    });
    
    
    console.log("14_mp_opsdash_IItem " + promptVal2);
    Lib.makeCall("14_mp_opsdash_IItem",promptVal2,true,function(reply) {        
        var procObj;
        
        returns.push({call: 'Return 2', ret: JSON.parse(reply).ITEMS});
        console.log('Return 2 back');
        
        iitemsCount ++;
        
        if(iitemsCount === 3){
            procObj = processIIReturns(returns);
            loadIIReturns(procObj);
        }
        
    },function(){
        alert("Query Failed, please contact help desk with screenshot")
        console.log('Return 2 failed');
        waitingDialog.hide();
    });
    
    
    console.log("14_mp_opsdash_IItem " + promptVal3);
    Lib.makeCall("14_mp_opsdash_IItem",promptVal3,true,function(reply) {        
        var procObj;
        
        returns.push({call: 'Return 3', ret: JSON.parse(reply).ITEMS});
        console.log('Return 3 back');
        
        iitemsCount ++;
        
        if(iitemsCount === 3){
            procObj = processIIReturns(returns);
            loadIIReturns(procObj);
        }
        
    },function(){
        alert("Query Failed, please contact help desk with screenshot")
        console.log('Return 3 failed');
        waitingDialog.hide();
    });
    
  }else {
    alert("Please select a practice location");
  }
    
  
   
   
   // Lib.makeCall("14_mp_opsdash_IItem",promptVal,true,function(reply) {        
   //   try{
   //     reply = JSON.parse(reply).ITEMS;
   //     incmpItmsDetTbl.search('');
   //     incmpItmsDetTbl.clear().draw();  
   //     if(reply.PRSNL_QUAL.length > 0){  
   //       $("#co_cnt").text(reply.COSIGN_ORDERS_CNT)
   //       $("#doc_cnt").text(reply.DOCUMENTS_CNT)
   //       $("#end_cnt").text(reply.ENDORSEMENTS_CNT)
   //       $("#msg_cnt").text(reply.MESSAGES_CNT)
   //       $("#note_cnt").text(reply.NOTES_CNT)
   //       $("#prop_cnt").text(reply.PROPOSED_ORD_CNT)
   //       $("#rslt_cnt").text(reply.RESULTS_CNT)
   //       $("#rx_cnt").text(reply.RX_REFILLS_CNT)
   //       $("#adl_cnt").text(reply.RX_DAYSLAG_CNT)
   //       
   //      try {
   //         $.each(reply.PRSNL_QUAL, function (i2, val2) {                
   //             incmpItmsDetTbl.row.add([    
   //               "",
   //               val2.RESP_USER_NAME,
   //               val2.COSIGN_ORDERS_CNT,
   //               val2.DOCUMENTS_CNT,
   //               val2.ENDORSEMENTS_CNT,
   //               val2.MESSAGES_CNT,
   //               val2.NOTES_CNT,
   //               val2.PROPOSED_ORD_CNT,
   //               val2.RESULTS_CNT,
   //               val2.RX_REFILLS_CNT,                    
   //               val2.PDETAIL,
   //               (val2.COSIGN_ORDERS_CNT + val2.DOCUMENTS_CNT + val2.ENDORSEMENTS_CNT +val2.MESSAGES_CNT + val2.NOTES_CNT +val2.PROPOSED_ORD_CNT +val2.RESULTS_CNT +val2.RX_REFILLS_CNT)
   //               ])
   //         });
   //       }
   //       catch (e) {
   //         alert(e.description);
   //         return;
   //         waitingDialog.hide();
   //       }       
   //       incmpItmsDetTbl
   //         .search('')
   //         .columns().search('')
   //         .draw();
   //       incmpItmsDetTbl.columns.adjust().draw();
   //       waitingDialog.hide();
   //     }         
   //   }
   //   catch(e){
   //     alert(e.message + reply)
   //     waitingDialog.hide();
   //     incmpItmsDetTbl.search('');
   //     incmpItmsDetTbl.clear().draw();  
   //   }
   // },function(){alert("Query Failed, please contact help desk with screenshot")
   // waitingDialog.hide();})
   // }
};


function SortByCount(a, b){
  var aName = a.count;
  var bName = b.count; 
  return ((aName > bName) ? -1 : ((aName < bName) ? 1 : 0));
}

function compressArray(original) {
    var compressed = [];
    // make a copy of the input array
    var copy = original.slice(0);
    // first loop goes over every element
    for (var i = 0; i < original.length; i++) {
        var myCount = 0;
        // loop over every element in the copy and see if it's the same
        for (var w = 0; w < copy.length; w++) {
          if (original[i] == copy[w]) {
            // increase amount of times duplicate is found
            myCount++;
            // sets item to undefined
            delete copy[w];
          }
        }
        if (myCount > 0) {
          var a = new Object();
          a.value = original[i];
          a.count = myCount;
          //a = [original[i], myCount]
          compressed.push(a);
        }
    }
    return compressed.sort(SortByCount)
};
    
function loadCharges(fromDate, toDate, selVal) {
    if (selVal.length > 0) { 
      waitingDialog.show();
      var promptVal = "^MINE^, value(" + selVal.trim() + ".00), 2, ^ENTER LAST NAME^, 0, VALUE(0), ^" + fromDate + "^, ^" + toDate + "^, 1, 1"   
      //alert(promptVal)
      //fromDate = moment().subtract(6, 'day').startOf('day').format('DD-MMM-YYYY HH:MM:SS');
      //toDate = moment().endOf('day').format('DD-MMM-YYYY HH:MM:SS');
      Lib.makeCall("14_MP_OPsDash_ChrgRecn",promptVal,true,function(reply) {     
        try{
          patientChrgDetTbl.search('');
          patientChrgDetTbl.clear().draw(); 
          //alert(reply)
          $('#pcpDiv2').html("");          
          reply = JSON.parse(reply).PTS;
          
          if(reply.QUAL.length > 0){  
            var count = 0          
            var pcplist = []
            var pcpDetailDivHtml = "<ul class='list-unstyled top_profiles scroll-view'>";
           try {
             var tblCnt = 0
              $.each(reply.QUAL, function (i2, val2) {
                if(val2.REQUIRED_ACTION.toLowerCase() != "none")
                {
                  patientChrgDetTbl.row.add([
                    val2.PERSON_ID,
                    val2.ENCNTR_ID,
                    val2.CURRENT_APPT_DT_TM,
                    val2.APPT_TYPE_CD,
                    val2.FIN,
                    val2.PATIENT_NAME,
                    val2.APPT_NUMBER,
                    val2.REASON_FOR_VISIT,
                    val2.ATTENDING,
                    val2.RLS_YES_NO,
                    val2.ENCOUNTER_SUMMARY,
                    val2.REQUIRED_ACTION
                    ])
                    pcplist.push(val2.ATTENDING)
                    
                
                  //start
                  // if (tblCnt < 10) {                    
                    // if($.inArray(val2.ATTENDING, pcplist ) == -1)
                    // {
                      // tblCnt = tblCnt + 1
                      // count = count + 1
                      // pcplist.push(val2.ATTENDING)
                      // thisPcpDiv = orderProviderList
                      // thisPcpDiv = thisPcpDiv.replace("pcpNameHere", val2.ATTENDING)
                      // thisPcpDiv = thisPcpDiv.replace("percentOfReferrall", "")
                      // //thisPcpDiv = thisPcpDiv.replace("style='width: 0%", "style='width: " + val2.OPPERCNRTO + "%")
                      // thisPcpDiv = thisPcpDiv.replace("percentSpanText","")
                      // thisPcpDiv = thisPcpDiv.replace("of pcpReferralCount referrals","")
                      // thisPcpDiv = thisPcpDiv.replace("pcpReferralCount","")
                      // pcpDetailDivHtml = pcpDetailDivHtml + thisPcpDiv
                    // }
                  // }         
                  //end
                }
                
              });
              if(pcplist.length >0)
              {
                var sortedPcpList = compressArray(pcplist) //.sort((a, b) => b[1] - a[1]);
                //alert(sortedPcpList)
                //sortedPcpList.sort((a, b) => b[1] - a[1])
                var listLimit = sortedPcpList.length
                sortedPcpList.length > 10 ? listLimit = 10: listLimit = sortedPcpList.length
                for (var i = 0; i < listLimit; i++) {
                  thisPcpDiv = orderProviderList
                  thisPcpDiv = thisPcpDiv.replace("pcpNameHere", sortedPcpList[i].value)
                  var percentStr = sortedPcpList[i].count +" (" + ((sortedPcpList[i].count/pcplist.length)*100).toFixed(0) + "% of total)"
                  thisPcpDiv = thisPcpDiv.replace("percentOfReferrall", percentStr)
                  thisPcpDiv = thisPcpDiv.replace("style='width: 0%", "style='width: " + ((sortedPcpList[i].count/pcplist.length)*100) + "%")
                  thisPcpDiv = thisPcpDiv.replace("percentSpanText","")
                  thisPcpDiv = thisPcpDiv.replace("of pcpReferralCount referrals","")
                  thisPcpDiv = thisPcpDiv.replace("pcpReferralCount","")
                  pcpDetailDivHtml = pcpDetailDivHtml + thisPcpDiv
                }
                //console.log(newArray.sort((a, b) => b[1] - a[1]))
              }
            }
            catch (e) {
              alert(e.description);
              return;
              waitingDialog.hide();
            }       
            count = count * 66            
            $('#pcpDiv2').html(pcpDetailDivHtml + "<ul>");
            $('#pcpDiv2').css({ height: count })
            patientChrgDetTbl
              .search('')
              .columns().search('')
              .draw();
            patientChrgDetTbl.columns.adjust().draw();
            waitingDialog.hide();
          }         
        }
        catch(e){
          //alert(e.message + reply)
		  alert("No data returned for Location and date range selected");
          waitingDialog.hide();
          $('#pcpDiv2').html("");          
          patientChrgDetTbl.search('');
          patientChrgDetTbl.clear().draw();  
        }
      },function(){alert("Failed")})
    }
    else {
        alert("Please select a practice location");
    }
};

function loadPatients(fromDate, toDate, selVal) {
    if (selVal.length > 0) {
      waitingDialog.show();
      var promptVal = "^MINE^,^" + fromDate + "^,^" + toDate + "^,value(-9999999999.0), value(" + selVal.trim() + ".00),^^, value(-9999999999.0)";
      Lib.makeCall("14_MP_OPsDash_RefOrder",promptVal,true,function(reply) {        
        if (reply.trim() != "NO REFERRAL ORDERS FOUND FOR THIS SPECIFIC REPORT CRITERIA") {        
          reply = JSON.parse(reply).ORDERLIST;        
          var statCnt = reply.DATESUM.length;          
          DateArr = [];
          OrderCountArr = [];
          NRTOCountArr = [];
          PercArr = [];
          patientReferraOrders.search('');
          patientReferraOrders.clear().draw();          
          $("#totalOrder").text(reply.ORDER_TOTAL);
          $("#totalNRTO").text(reply.NRTO_TOTAL);
          $("#percNRTO").text(reply.NRTO_PERCT);
          
          if (statCnt > 0) {
            $.each(reply.DATESUM, function (i2, val2) {
              DateArr.push(val2.ORDER_DATE)
              NRTOCountArr.push(val2.NRTO_COUNT);
              EXTERNALCnt.push(val2.MEDSEXTERNAL_COUNT)
              INTERNALCnt.push(val2.MEDSINTERNAL_COUNT)
              OrderCountArr.push(val2.ORDER_COUNT)
              PercArr.push(val2.NRTO_PERCT)
            });
            if (DateArr.length > 0) {
              dateRangeStr = DateArr[0]
              if (DateArr.length > 1) {
                dateRangeStr = dateRangeStr + " - " + DateArr[DateArr.length - 1]
              }
            }
            init_echarts();
            init_gauge(reply.NRTO_PERCT)
            var pcpDetailDivHtml = "<ul class='list-unstyled top_profiles scroll-view'>";
            PCPQUAL = Lib.sortJSON(reply.OPQUAL, 'OPPERCNRTO', '123'); // 123 or 321
            var count = 0
          }
          $.each(PCPQUAL, function (i2, val2) {
            thisPcpDiv = orderProviderList
            thisPcpDiv = thisPcpDiv.replace("pcpNameHere", val2.ORDERING_PROVIDER)
            thisPcpDiv = thisPcpDiv.replace("percentOfReferrall", val2.OPPERCNRTO + "% Complete")
            thisPcpDiv = thisPcpDiv.replace("style='width: 0%", "style='width: " + val2.OPPERCNRTO + "%")
            thisPcpDiv = thisPcpDiv.replace("percentSpanText", val2.OPPERCNRTO + "%")
            thisPcpDiv = thisPcpDiv.replace("pcpReferralCount", val2.PATIENTCOUNT)
            pcpDetailDivHtml = pcpDetailDivHtml + thisPcpDiv
            count = i2 + 1
            if (i2 == 9) {
              return false;
            }
          });
          count = count * 66
          $('#pcpDiv').html(pcpDetailDivHtml + "<ul>");
          $('#pcpDiv').css({ height: count })
          var ordCnt = reply.QUAL.length;
          // alert(ordCnt)
          var ordCnt = reply.QUAL.length;
          if (ordCnt > 0) {
            try {
              $.each(reply.QUAL, function (i2, val2) {
                if (val2.REFER_TO_PROVIDER.trim() == "") {
                  patientReferraOrders.row.add([
                    val2.PERSON_ID,
                    val2.ENCNTR_ID,
                    val2.ORDER_ID,
                    val2.ORDERING_PROVIDER,
                    val2.ORDER_LDATE,
                    val2.PERSON_NAME,
                    val2.PERSON_DOB,
                    val2.PERSON_CMRN,
                    val2.ORDER_DT,
                    val2.ORDER_NAME,
                    val2.REFER_TO_LOCATION,
                    val2.SPEC_INX]
                  )
                }
              });
            }
            catch (e) {
              alert(e.description);
              return;
              waitingDialog.hide();
            }
          }
          patientReferraOrders
            .search('')
            .columns().search('')
            .draw();
          patientReferraOrders.columns.adjust().draw();
          waitingDialog.hide();
        }
      })
    }
    else {
        alert("Please select a practice location");
    }
};

function loadWorkQueue(queueId) {
    // alert(queueId)
    // if(queueId.length > 0) 
    // {
    waitingDialog.show();
    var RS = null;
    RS = new XMLCclRequest();
    RS.onreadystatechange = function () {
        if (RS.readyState == 4 || RS.readyState == "complete") {
            if (RS.status == 200) {
                var tempObj = JSON.parse(RS.responseText);
                var replyObj = tempObj.WORKQUEUE;
                var queueCnt = replyObj.QUEUE.length;
                WMQArr = [];
                WMQBuck = [];
                // alert(queueCnt)
                workQueueTable.search('');
                workQueueTable.clear().draw();
                if (queueCnt > 0) {
                    WMQArr.push(replyObj.GRP1_CNT)
                    WMQBuck.push("0 - 3 Days")
                    WMQArr.push(replyObj.GRP2_CNT)
                    WMQBuck.push("4 - 7 Days")
                    WMQArr.push(replyObj.GRP3_CNT)
                    WMQBuck.push("8 - 30 Days")
                    WMQArr.push(replyObj.GRP4_CNT)
                    WMQBuck.push("Over 30 Days")

                    init_WMQEChart()
                    $("#totalWQMCnt").text(replyObj.TOTAL_CNT);
                    $("#OLDEST_WORK_ITEM_ID").text(replyObj.OLDEST_WORK_ITEM_ID);
                    $("#OLDEST_ITEM_DT").text(replyObj.OLDEST_ITEM_DT);
                    $("#OLDEST_ITEM_OWNER").text(replyObj.OLDEST_ITEM_OWNER);
                    $("#OLDEST_ITEM_STATUS").text(replyObj.OLDEST_ITEM_STATUS);
                    $("#NEWEST_WORK_ITEM_ID").text(replyObj.NEWEST_WORK_ITEM_ID);
                    $("#NEWEST_ITEM_DT").text(replyObj.NEWEST_ITEM_DT);
                    $("#NEWEST_ITEM_OWNER").text(replyObj.NEWEST_ITEM_OWNER);
                    $("#NEWEST_ITEM_STATUS").text(replyObj.NEWEST_ITEM_STATUS);

                    var itemCnt = replyObj.QUEUE.length;
                    // alert(itemCnt)
                    for (idx = 0; idx < itemCnt; idx++) {
                        workQueueTable.row.add([
                            replyObj.QUEUE[idx].ITEM_GROUP,
                            replyObj.QUEUE[idx].CDI_WORK_ITEM_ID,
                            replyObj.QUEUE[idx].CREATE_DT,
                            replyObj.QUEUE[idx].ELAPSED_TIME,
                            replyObj.QUEUE[idx].COMMENT,
                            replyObj.QUEUE[idx].OWNER_PRSNL,
                            replyObj.QUEUE[idx].PRIORITY,
                            replyObj.QUEUE[idx].STATUS
                        ])
                    }
                }
                else {
                    $("div.toolbar2").html('');
                    $("#statsRow").css("display", "none");
                    alert("No Data found for the selection");
                }
                workQueueTable
                    .search('')
                    .columns().search('')
                    .draw();
                NProgress.done();
                loadTriggered = false;
                waitingDialog.hide();
            }
        }
    };
    RS.open('GET', '14_MP_OPsDash_WrkQueue', true)
    try {
        var promptVal = "^MINE^,value(" + queueId.trim() + ".00),^A^, ^S^";
        // alert(promptVal)
        RS.send(promptVal)
    }
    catch (e) {
        alert(e.description);
        waitingDialog.hide();
        return;
    }
    // }
    // else 
    // {
    //     alert("Please select a Queue");
    // }
}

function init_gauge(gValue) {

    if (typeof (Gauge) === 'undefined') { return; }
    var gColor = "#008000"
    if (gValue > 50) {
        gColor = "#ff9900"
    }
    if (gValue > 75) {
        gColor = "#ff0000"
    }


    var chart_gauge_settings = {
        lines: 12,
        angle: 0,
        lineWidth: 0.4,
        pointer: {
            length: 0.75,
            strokeWidth: 0.042,
            color: '#1D212A'
        },
        limitMax: 'false',
        colorStart: gColor,
        colorStop: gColor,
        strokeColor: '#F0F3F3',
        generateGradient: true
    };


    if ($('#chart_gauge_01').length) {

        var chart_gauge_01_elem = document.getElementById('chart_gauge_01');
        var chart_gauge_01 = new Gauge(chart_gauge_01_elem).setOptions(chart_gauge_settings);

    }


    if ($('#gauge-text').length) {

        chart_gauge_01.maxValue = 100;
        chart_gauge_01.animationSpeed = 10;
        chart_gauge_01.set(gValue);
        chart_gauge_01.setTextField(document.getElementById("gauge-text"));

    }
}

function init_DataTables() {
    patientReferraOrders = $('#patientReferraOrders').DataTable({
        dom: 'Bfrtip',
        responsive: true,
        "processing": true,
        "bAutoWidth": true,
        "paging": true,
        "iDisplayLength": 10,
        emptyTable: "No Data to display....Please select Location and Date",
        lengthMenu: [
            [10, 25, 50, -1],
            ['10 Referrals', '25 Referrals', '50 Referrals', 'Show all Referrals']
        ],
        buttons: [
            'pageLength'
        ],
        "columnDefs": [
            {
                "targets": [0, 1, 2],
                "visible": false,
                "searchable": false
            },
            {
                "targets": [3, 4],
                "visible": false
            }
        ],
        "createdRow": function (row, data, index) {
            $(row).find('td:eq(0)').addClass('patientNameLink pointer');
        }
    });

    workQueueTable = $('#workQueueTable').DataTable({
        dom: 'Bfrtip',
        responsive: true,
        "processing": true,
        "paging": true,
        "iDisplayLength": 10,
        lengthMenu: [
            [10, 25, 50, -1],
            ['10 Rows', '25 Rows', '50 Rows', 'Show all Rows']
        ],
        buttons: [
            'pageLength'
        ],
        emptyTable: "No Data to display....Please select a Workqueue"
        //,
        // "columnDefs": [
        //     {
        //         "targets": [0],
        //         "visible": false
        //     }
        // ]
    });

     // patientChrgDetTbl = $('#patientChrgDet').DataTable({
        // dom: 'Bfrtip',
        // responsive: true,
        // "processing": true,
        // "bAutoWidth": true,
        // "paging": true,
        // "iDisplayLength": 10,
        // emptyTable: "No Data to display....Please select Location and Date",
        // lengthMenu: [
            // [10, 25, 50, -1],
            // ['10 Referrals', '25 Referrals', '50 Referrals', 'Show all Referrals']
        // ],
        // buttons: [
            // 'pageLength'
        // ],
        // "columnDefs": [
            // {
                // "targets": [0, 1, 2],
                // "visible": false,
                // "searchable": false
            // },
            // {
                // "targets": [3, 4],
                // "visible": false
            // }
        // ],
        // "createdRow": function (row, data, index) {
            // $(row).find('td:eq(0)').addClass('patientNameLink pointer');
        // }
    // });
}

function init_echarts() {

    if (typeof (echarts) === 'undefined') { return; }
    console.log('init_echarts');

    chart_refOrder = echarts.init(document.getElementById('chart_plot_03'), theme);
    if ($('#chart_plot_03').length) {

        chart_refOrder.setOption({
            title: {
                text: dateRangeStr,
                subtext: 'Count'
            },
            tooltip: {
                trigger: 'axis'
            },
            toolbox: {
                show: true,
                feature: {
                    magicType: {
                        show: true,
                        title: {
                            line: 'Line',
                            bar: 'Bar',
                            stack: 'Stack',
                            tiled: 'Tiled'
                        },
                        type: ['line', 'bar']
                    },
                    restore: {
                        show: true,
                        title: "Restore"
                    },
                    saveAsImage: {
                        show: true,
                        title: "Save Image"
                    },
                    dataView: {
                        show: true,
                        title: "Text View",
                        lang: [
                            "Text View",
                            "Close",
                            "Refresh",
                        ],
                        readOnly: false
                    }
                }
            },
            legend: {
                data: ['Total Referrals', 'Referrals With No Referred To Provider', 'EXTERNAL', 'INTERNAL']
            },
            calculable: false,
            xAxis: [{
                type: 'category',
                data: DateArr,// ['July', 'August',   'September',    'October',  'November', 'December', 'January',  'February', 'March',    'April',    'May',  'June']
            }],
            yAxis: [{
                type: 'value'
            }],
            series: [{
                name: "Total Referrals",
                type: 'line',
                data: OrderCountArr, // ['7.32',    '6.84', '6',    '6.17', '6.65', '7.72', '9.06', '9.51', '7.84', '4.76', '2.95', '1.4'],
                markPoint: {
                    data: [{
                        type: 'max',
                        name: 'High'
                    }, {
                        type: 'min',
                        name: 'Low'
                    }]
                },
                markLine: {
                    data: [{
                        type: 'average',
                        name: 'Average'
                    }]
                }
            }, {
                name: "Referrals With No Referred To Provider",
                type: 'line',
                data: NRTOCountArr, //['0.03', '0.04', '0.04', '0.03', '0.06', '0.05', '0.97', '1.81', '3.65', '5.31', '6.06', '5.7'],
                markPoint: {
                    data: [{
                        type: 'max',
                        name: 'High'
                    }, {
                        type: 'min',
                        name: 'Low'
                    }]
                },
                markLine: {
                    data: [{
                        type: 'average',
                        name: 'Average'
                    }]
                }
            },
            {
                name: "EXTERNAL",
                type: 'line',
                data: EXTERNALCnt, //['0.03', '0.04', '0.04', '0.03', '0.06', '0.05', '0.97', '1.81', '3.65', '5.31', '6.06', '5.7'],
                markPoint: {
                    data: [{
                        type: 'max',
                        name: 'High'
                    }, {
                        type: 'min',
                        name: 'Low'
                    }]
                },
                markLine: {
                    data: [{
                        type: 'average',
                        name: 'Average'
                    }]
                }
            },
            {
                name: "INTERNAL",
                type: 'line',
                data: INTERNALCnt, //['0.03', '0.04', '0.04', '0.03', '0.06', '0.05', '0.97', '1.81', '3.65', '5.31', '6.06', '5.7'],
                markPoint: {
                    data: [{
                        type: 'max',
                        name: 'High'
                    }, {
                        type: 'min',
                        name: 'Low'
                    }]
                },
                markLine: {
                    data: [{
                        type: 'average',
                        name: 'Average'
                    }]
                }
            }]
        });

        chart_refOrder.on('click', function (params) {
            if (params.componentType === 'markPoint') {
                // patientReferraOrders
                //     .search( '' )
                //     .columns().search( '' )
                //     .draw();
                // // alert('Mark Point Series: ' + params.seriesIndex + ' Mark Point Name: ' + params.name)
                // patientReferraOrders
                //     .column(4)
                //     .search(params.name.trim())
                //     .draw();
                // $('#referringProviderFilter').text(params.name)
            }
            else if (params.componentType === 'series') {
                if (params.seriesType === 'graph') {
                    if (params.dataType === 'edge') {
                        patientReferraOrders
                            .search('')
                            .columns().search('')
                            .draw();
                        patientReferraOrders
                            .column(4)
                            .search(params.name.trim())
                            .draw();
                        $('#referringProviderFilter').text(params.name)
                        // clicked on an edge of the graph
                    }
                    else {
                        patientReferraOrders
                            .search('')
                            .columns().search('')
                            .draw();
                        patientReferraOrders
                            .column(4)
                            .search(params.name.trim())
                            .draw();
                        $('#referringProviderFilter').text(params.name)
                        // alert(params.name);
                        // clicked on a node of the graph
                    }
                }
                else {
                    patientReferraOrders
                        .search('')
                        .columns().search('')
                        .draw();
                    patientReferraOrders
                        .column(4)
                        .search(params.name.trim())
                        .draw();
                    $('#referringProviderFilter').text(params.name)
                    // alert(params.name + ' ' + params.seriesName);
                }
            }

        });
    }
}

function init_WMQEChart() {
    chatWMQ = echarts.init(document.getElementById('chart_WMQ'), theme);
    if ($('#chart_WMQ').length) {
        chatWMQ.setOption({
            title: {
                text: WMQSelected,
                subtext: 'Count'
            },
            tooltip: {
                trigger: 'axis'
            },
            toolbox: {
                show: true,
                feature: {
                    magicType: {
                        show: true,
                        title: {
                            line: 'Line',
                            bar: 'Bar',
                            stack: 'Stack',
                            tiled: 'Tiled'
                        },
                        type: ['bar', 'line']
                    },
                    restore: {
                        show: true,
                        title: "Restore"
                    },
                    saveAsImage: {
                        show: true,
                        title: "Save Image"
                    },
                    dataView: {
                        show: true,
                        title: "Text View",
                        lang: [
                            "Text View",
                            "Close",
                            "Refresh",
                        ],
                        readOnly: false
                    }
                }
            },
            legend: {
                data: ['Total Item In Queue']
            },
            calculable: false,
            xAxis: [{
                type: 'category',
                data: WMQBuck
            }],
            yAxis: [{
                type: 'value'
            }],
            series: [{
                name: "Total Item In Queue",
                type: 'bar',
                data: WMQArr,
                markPoint: {
                    data: [{
                        type: 'max',
                        name: 'High'
                    }, {
                        type: 'min',
                        name: 'Low'
                    }]
                },
                markLine: {
                    data: [{
                        type: 'average',
                        name: 'Average'
                    }]
                }
            }]
        });

        chatWMQ.on('click', function (params) {
            workQueueTable
                .search('')
                .columns().search('')
                .draw();
            var searchText = '"' + params.name + '"'

            if (params.componentType === 'markPoint') {
                // // clicked on markPoint
                // // if (params.seriesIndex === 5) {
                // //      // clicked on a markPoint which belongs to a series indexed with 5
                // // }
                // alert('Mark Point Series: ' + params.seriesIndex + ' Mark Point Name: ' + params.name)
            }
            else if (params.componentType === 'series') {
                if (params.seriesType === 'graph') {
                    if (params.dataType === 'edge') {
                        workQueueTable
                            .search('')
                            .columns().search('')
                            .draw();
                        workQueueTable
                            .column(0)
                            .search(searchText.trim())
                            .draw();

                        //alert(' Mark Point Name: 1 ' + searchText)
                    }
                    else {
                        workQueueTable
                            .search('')
                            .columns().search('')
                            .draw();
                        workQueueTable
                            .column(0)
                            .search(searchText.trim())
                            .draw();
                        //alert(' Mark Point Name: 2 ' + searchText)
                    }
                }
                else {
                    workQueueTable
                        .search('')
                        .columns().search('')
                        .draw();
                    workQueueTable
                        .column(0)
                        .search(searchText.trim())
                        .draw();
                    //alert(' Mark Point Name: 3 ' + searchText)
                }
            }

        });
    }
}

function getTheme() {
    return {
        color: [
            '#26B99A', '#34495E', '#3498DB', '#ddc000',
            '#9B59B6', '#8abb6f', '#759c6a', '#bfd3b7'
        ],

        title: {
            itemGap: 8,
            textStyle: {
                fontWeight: 'normal',
                color: '#408829'
            }
        },

        dataRange: {
            color: ['#1f610a', '#97b58d']
        },

        toolbox: {
            color: ['#408829', '#408829', '#408829', '#408829']
        },

        tooltip: {
            backgroundColor: 'rgba(0,0,0,0.5)',
            axisPointer: {
                type: 'line',
                lineStyle: {
                    color: '#408829',
                    type: 'dashed'
                },
                crossStyle: {
                    color: '#408829'
                },
                shadowStyle: {
                    color: 'rgba(200,200,200,0.3)'
                }
            }
        },

        dataZoom: {
            dataBackgroundColor: '#eee',
            fillerColor: 'rgba(64,136,41,0.2)',
            handleColor: '#408829'
        },
        grid: {
            left: '3%',
            right: '4%',
            bottom: '3%',
            containLabel: true
        },

        categoryAxis: {
            axisLine: {
                lineStyle: {
                    color: '#408829'
                }
            },
            splitLine: {
                lineStyle: {
                    color: ['#eee']
                }
            }
        },

        valueAxis: {
            axisLine: {
                lineStyle: {
                    color: '#408829'
                }
            },
            splitArea: {
                show: true,
                areaStyle: {
                    color: ['rgba(250,250,250,0.1)', 'rgba(200,200,200,0.1)']
                }
            },
            splitLine: {
                lineStyle: {
                    color: ['#eee']
                }
            }
        },
        timeline: {
            lineStyle: {
                color: '#408829'
            },
            controlStyle: {
                normal: { color: '#408829' },
                emphasis: { color: '#408829' }
            }
        },

        k: {
            itemStyle: {
                normal: {
                    color: '#68a54a',
                    color0: '#a9cba2',
                    lineStyle: {
                        width: 1,
                        color: '#408829',
                        color0: '#86b379'
                    }
                }
            }
        },
        map: {
            itemStyle: {
                normal: {
                    areaStyle: {
                        color: '#ddd'
                    },
                    label: {
                        textStyle: {
                            color: '#c12e34'
                        }
                    }
                },
                emphasis: {
                    areaStyle: {
                        color: '#99d2dd'
                    },
                    label: {
                        textStyle: {
                            color: '#c12e34'
                        }
                    }
                }
            }
        },
        force: {
            itemStyle: {
                normal: {
                    linkStyle: {
                        strokeColor: '#408829'
                    }
                }
            }
        },
        chord: {
            padding: 4,
            itemStyle: {
                normal: {
                    lineStyle: {
                        width: 1,
                        color: 'rgba(128, 128, 128, 0.5)'
                    },
                    chordStyle: {
                        lineStyle: {
                            width: 1,
                            color: 'rgba(128, 128, 128, 0.5)'
                        }
                    }
                },
                emphasis: {
                    lineStyle: {
                        width: 1,
                        color: 'rgba(128, 128, 128, 0.5)'
                    },
                    chordStyle: {
                        lineStyle: {
                            width: 1,
                            color: 'rgba(128, 128, 128, 0.5)'
                        }
                    }
                }
            }
        },
        gauge: {
            startAngle: 225,
            endAngle: -45,
            axisLine: {
                show: true,
                lineStyle: {
                    color: [[0.2, '#86b379'], [0.8, '#68a54a'], [1, '#408829']],
                    width: 8
                }
            },
            axisTick: {
                splitNumber: 10,
                length: 12,
                lineStyle: {
                    color: 'auto'
                }
            },
            axisLabel: {
                textStyle: {
                    color: 'auto'
                }
            },
            splitLine: {
                length: 18,
                lineStyle: {
                    color: 'auto'
                }
            },
            pointer: {
                length: '90%',
                color: 'auto'
            },
            title: {
                textStyle: {
                    color: '#333'
                }
            },
            detail: {
                textStyle: {
                    color: 'auto'
                }
            }
        },
        textStyle: {
            fontFamily: 'Arial, Verdana, sans-serif'
        }
    }
}

function init_sparklines() {

    if (typeof (jQuery.fn.sparkline) === 'undefined') { return; }
    console.log('init_sparklines');




    $(".sparkline_two").sparkline([2, 4, 3, 4, 5, 4, 5, 4, 3, 4, 5, 6, 7, 5, 4, 3, 5, 6], {
        type: 'bar',
        height: '40',
        barWidth: 9,
        colorMap: {
            '7': '#a1a1a1'
        },
        barSpacing: 2,
        barColor: '#26B99A'
    });


    $(".sparkline_three").sparkline([2, 4, 3, 4, 5, 4, 5, 4, 3, 4, 5, 6, 7, 5, 4, 3, 5, 6], {
        type: 'line',
        width: '200',
        height: '40',
        lineColor: '#26B99A',
        fillColor: 'rgba(223, 223, 223, 0.57)',
        lineWidth: 2,
        spotColor: '#26B99A',
        minSpotColor: '#26B99A'
    });


    $(".sparkline11").sparkline([2, 4, 3, 4, 5, 4, 5, 4, 3, 4, 6, 2, 4, 3, 4, 5, 4, 5, 4, 3], {
        type: 'bar',
        height: '40',
        barWidth: 8,
        colorMap: {
            '7': '#a1a1a1'
        },
        barSpacing: 2,
        barColor: '#26B99A'
    });


    $(".sparkline22").sparkline([2, 4, 3, 4, 7, 5, 4, 3, 5, 6, 2, 4, 3, 4, 5, 4, 5, 4, 3, 4, 6], {
        type: 'line',
        height: '40',
        width: '200',
        lineColor: '#26B99A',
        fillColor: '#ffffff',
        lineWidth: 3,
        spotColor: '#34495E',
        minSpotColor: '#34495E'
    });


    $(".sparkline_bar").sparkline([2, 4, 3, 4, 5, 4, 5, 4, 3, 4, 5, 6, 4, 5, 6, 3, 5], {
        type: 'bar',
        colorMap: {
            '7': '#a1a1a1'
        },
        barColor: '#26B99A'
    });


    $(".sparkline_area").sparkline([5, 6, 7, 9, 9, 5, 3, 2, 2, 4, 6, 7], {
        type: 'line',
        lineColor: '#26B99A',
        fillColor: '#26B99A',
        spotColor: '#4578a0',
        minSpotColor: '#728fb2',
        maxSpotColor: '#6d93c4',
        highlightSpotColor: '#ef5179',
        highlightLineColor: '#8ba8bf',
        spotRadius: 2.5,
        width: 85
    });


    $(".sparkline_line").sparkline([2, 4, 3, 4, 5, 4, 5, 4, 3, 4, 5, 6, 4, 5, 6, 3, 5], {
        type: 'line',
        lineColor: '#26B99A',
        fillColor: '#ffffff',
        width: 85,
        spotColor: '#34495E',
        minSpotColor: '#34495E'
    });


    $(".sparkline_pie").sparkline([1, 1, 2, 1], {
        type: 'pie',
        sliceColors: ['#26B99A', '#ccc', '#75BCDD', '#D66DE2']
    });


    $(".sparkline_discreet").sparkline([4, 6, 7, 7, 4, 3, 2, 1, 4, 4, 2, 4, 3, 7, 8, 9, 7, 6, 4, 3], {
        type: 'discrete',
        barWidth: 3,
        lineColor: '#26B99A',
        width: '85',
    });


};

function init_daterangepicker() {
    $('#reportrange').daterangepicker({
        singleDatePicker: true,
        singleClasses: "picker_1"
    }, cb);    
    
    fromDate = moment().subtract(6, 'day').endOf('day').format('DD-MMM-YYYY');
    toDate = moment().endOf('day').format('DD-MMM-YYYY');
    cb(moment().subtract(6, 'day').endOf('day').format('MMMM D, YYYY'), moment().endOf('day').format('MMMM D, YYYY'));    
}

//On Date range selection/change
$('#reportrange').on('apply.daterangepicker', function (ev, picker) {  
    
    var date = new Date();
    fromDate = picker.startDate.subtract(6, 'day').format('DD-MMM-YYYY');
    toDate = picker.endDate.format('DD-MMM-YYYY');    
    cb(fromDate, toDate);
    loadPatients(fromDate, toDate, $("#select-practiceLoc").select2("val"));
    
});

// Apply selected date to label/Span for display
function cb(start, end) {    
    $('#reportrange span').html(start + ' - ' + end);    
}

//Populate Ambulatory Locations
function populateDDLPL() {
    try {
        var RS = null;
        RS = new XMLCclRequest();
        RS.onreadystatechange = function () {
            if (RS.readyState == 4 || RS.readyState == "complete") {
                if (RS.status == 200) {
                    tempObj = JSON.parse(RS.responseText);
                    $('#select-practiceLoc').select2(
                        {
                            placeholder: "Select a Location",
                            allowClear: true,
                            width: 'resolve',
                            data: $.map($(tempObj.RS.QUAL), function (obj) {
                                obj.id = obj.id || obj.LOCATION_ID;
                                obj.text = obj.text || obj.LOCATION_NAME; // replace name with the property used for the text
                                return obj;
                            }),
                        }
                    );
                }
            }
        };
        RS.open('GET', '14_mp_amb_locations', true)
        try {
            var promptVal = "^MINE^";
            RS.send('MINE');
        }
        catch (e) {
            alert(e.description);
            //NProgress.done();
            return;
        }
    }
    catch (e) {
        alert("The page did not load properly, please refresh the page to try again. Error message: " + e.message);
        //NProgress.done();
        $('#select-practiceLoc').select2();
        return;
    }

}

function checkProfile() {
    var returnValue = false
	returnValue = true
    $("#mainBodyContent").css("display", "inline");
    $("#accessDenied").css("display", "none");
    loadPageOnSuccess();
    // try {
      // var promptVal = "^MINE^";
      // Lib.retrieveUserProfile("14_get_activeuser_pref", promptVal);
      // var passUsers = ["SXA300"]
      // var passPositions = ["DBA", "Physician - PI Physician", "Amb: Clinic Staff Propose Cred Preg", "Amb: Clinic Staff Propose Credentialed", "Amb: Clinic Staff Propose Non Cred Preg", "Amb: Clinic Staff Propose Non Cred-PC", "Amb: Clinic Staff Propose Non Credential", "Amb: Primary Care MA", "Amb: Rehab Outpt Manager", "Amb: Rehab Outpt Ther Stud/Asst", "Amb: Rehab Outpt Therapist", "Amb: Rehab Outpt Therapist  Orders", "Ambulatory: Clinic Manager", "Ambulatory: Clinic Staff Co-sign", "Ambulatory: Clinic Staff Co-sign Preg", "Ambulatory: Clinic Staff Co-sign-PC", "Ambulatory: Front Office Staff"]
      // if($.inArray(Lib.getSingleProfile("Logon_User_ID"), passUsers ) > -1 || $.inArray(Lib.getSingleProfile("Logon_Position"), passPositions ) > -1)
      // {
        // returnValue = true
        // $("#mainBodyContent").css("display", "inline");
        // $("#accessDenied").css("display", "none");
        // loadPageOnSuccess();
      // }
    // }
    // catch (e) {
        // alert("The page did not load properly, please refresh the page to try again. Error message: " + e.message);
    // }
    return returnValue;
}

function loadPageOnSuccess() {
    init_DataTables()
    init_daterangepicker()
    theme = getTheme()
    populateDDLPL()
    init_sparklines()
    setTimeout(initalLoadDDLCR, 1000);

    var $BODY = $('body'),
        $MENU_TOGGLE = $('#menu_toggle'),
        $Ordering_Provider = $('#pcpDiv'),
        $SIDEBAR_MENU = $('#sidebar-menu'),
        $SIDEBAR_FOOTER = $('.sidebar-footer'),
        $LEFT_COL = $('.left_col'),
        $RIGHT_COL = $('.right_col'),
        $NAV_MENU = $('.nav_menu'),
        $FOOTER = $('footer');
    hideSide()
    //$('#refOrders').click()

    function hideSide() {
        if ($('#BODY').hasClass('nav-md')) {
            $SIDEBAR_MENU.find('li.active ul').hide();
            $SIDEBAR_MENU.find('li.active').addClass('active-sm').removeClass('active');
        }
        else {
            $SIDEBAR_MENU.find('li.active-sm ul').show();
            $SIDEBAR_MENU.find('li.active-sm').addClass('active').removeClass('active-sm');
        }

        $BODY.toggleClass('nav-md nav-sm');
    }

    $SIDEBAR_MENU.find('a').on('click', function (ev) {
        console.log('clicked - sidebar_menu');
        var $li = $(this).parent();
        if ($li.is('.active')) {
            // $li.removeClass('active active-sm');
            // $('ul:first', $li).slideUp(function () {
            //     setContentHeight();
            // });
        } else {
            // prevent closing menu if we are on child menu
            if (!$li.parent().is('.child_menu')) {
                $SIDEBAR_MENU.find('li').removeClass('active active-sm');
                $SIDEBAR_MENU.find('li ul').slideUp();
            } else {
                if ($BODY.is(".nav-sm")) {
                    $SIDEBAR_MENU.find("li").removeClass("active active-sm");
                    $SIDEBAR_MENU.find("li ul").slideUp();
                }
            }
            if (this.id == "refOrders") {
                $("#referralOrderDiv").css("display", "inline");
                $("#refTrackerDiv").css("display", "none");
                $("#WMQDiv").css("display", "none");
                $("#chrgReconDiv").css("display", "none");
                $("#incmpItemsDiv").css("display", "none");                
            }
            else if (this.id == "refTracker") {
                $("#refTrackerDiv").css("display", "inline");
                $("#referralOrderDiv").css("display", "none");
                $("#WMQDiv").css("display", "none");
                $("#chrgReconDiv").css("display", "none");
                $("#incmpItemsDiv").css("display", "none");
            }
            else if (this.id == "conMsg") {
                $("#referralOrderDiv").css("display", "none");
                $("#WMQDiv").css("display", "none");
                $("#refTrackerDiv").css("display", "none");
                $("#chrgReconDiv").css("display", "none");
                $("#incmpItemsDiv").css("display", "none");
            }
            else if (this.id == "incompItems") {
                $("#referralOrderDiv").css("display", "none");
                $("#WMQDiv").css("display", "none");
                $("#refTrackerDiv").css("display", "none");
                $("#chrgReconDiv").css("display", "none");
                $("#incmpItemsDiv").css("display", "inline"); 
                loadTemplate($('#iiLDHolder'))
            }
            else if (this.id == "chrgRecon") {
                $("#referralOrderDiv").css("display", "none");
                $("#WMQDiv").css("display", "none");
                $("#refTrackerDiv").css("display", "none");
                $("#chrgReconDiv").css("display", "inline");     
                $("#incmpItemsDiv").css("display", "none");                
            }
            else if (this.id == "WQM") {
                $("#referralOrderDiv").css("display", "none");
                $("#refTrackerDiv").css("display", "none");
                $("#WMQDiv").css("display", "inline");
                $("#chrgReconDiv").css("display", "none");
                $("#incmpItemsDiv").css("display", "none");
                //init_WMQEChart()
                $('#currDatelbl').html("Date: " + moment().endOf('day').format('DD-MMM-YYYY'))
                populateWQMDDLPL();
            }
            // $('#referralOrderDiv').css
            $li.addClass('active');

            $('ul:first', $li).slideDown(function () {
                setContentHeight();
            });
        }
    });

    // $Ordering_Provider.find('a').on('click', function (ev) {
    //     // var $li = $(this).parent();
    //     if ($(this).is('.active')) {
    //         $(this).removeClass('active active-sm');            
    //     } else {            
    //         $(this).addClass('active');
    //     }
    // });
}

function initalLoadDDLCR(){
  loadTemplate($('#ldHolder'))
}

function loadTemplate(container) {
  // if( $('#ldHolder').is(':empty')) {
  if(container.is(':empty')) {
    try{
      // $('#ldHolder').append(locDate.html()) 
      var uniqueID = container.attr('id')
      var selId = "select-"+uniqueID
      var drpId = "reportrange-"+uniqueID
      var fnName = "";
      container.append(locDate.html().replace('id="select-practiceLocCR"','id="'+selId+'"').replace('id="reportrangeCR"','id="'+drpId+'"')) 
      $("#"+selId).select2({          
        allowClear: true,
        placeholder: "Select a Location",
        width: 'resolve'
      })     
      $("#"+drpId).daterangepicker({
          singleDatePicker: true,
          singleClasses: "picker_1"
      },cb2);
      fromDate = moment().subtract(6, 'day').startOf('day').format('DD-MMM-YYYY HH:mm:ss');
      toDate = moment().endOf('day').format('DD-MMM-YYYY HH:mm:ss');
      cb2(moment().subtract(6, 'day').endOf('day').format('MMMM D, YYYY'), moment().endOf('day').format('MMMM D, YYYY'));    
      switch(container.attr('id')){
        case "ldHolder":
          fnName = "loadCharges" 
          break;
        case "iiLDHolder":      
          fnName = "loadIncmpItms"
          break;
      }          
          
      //On Date range selection/change
      $("#"+drpId).on('apply.daterangepicker', function (ev, picker) {            
        var date = new Date();
        fromDate = picker.startDate.subtract(6, 'day').startOf('day').format('DD-MMM-YYYY HH:mm:ss');
        toDate = picker.endDate.endOf('day').format('DD-MMM-YYYY HH:mm:ss');   
        cb2(fromDate, toDate);
        window[fnName](fromDate, toDate, $("#"+selId).select2("val"));  //loadCharges(fromDate, toDate, $("#"+selId).select2("val"));          
      });      
      $("#"+selId).on("change", function (e) {        
         try{
          // alert($(this).id + " " + $(this).val())
          LocSelected = $(this).select2('data')[0]['text'].trim();
          window[fnName](fromDate, toDate, $("#"+selId).select2("val"))          
         }
         catch(e){alert(e.message)}
      });
      
      // Apply selected date to label/Span for display
      function cb2(start, end) {    
        $("#"+drpId+" span").html(start + ' - ' + end);    
      }
    }
    catch (e) {
      alert( e.message);
    }
  }
  var tableoptionSet = {
    dom: 'Bfrtip',
    responsive: true,
    "processing": true,
    "bAutoWidth": true,
    "paging": true,
    "iDisplayLength": 10,
    "language": {
      emptyTable: "No Data to display....Please select Location and Date"
    },            
    lengthMenu: [
        [10, 25, 50, -1],
        ['10 Rows', '25 Rows', '50 Rows', 'Show all Rows']
    ],
    buttons: [
        'pageLength'
    ]
  }
  
  switch(container.attr('id')){
    case "ldHolder":
      if ( ! $.fn.DataTable.isDataTable( '#patientChrgDet' ) ) { 
        var tableoptionSet2 ={
          "columnDefs": [
            {
              "targets": [0, 1],
              "visible": false,
              "searchable": false
            }
          ],
          "createdRow": function (row, data, index) {
              $(row).find('td:eq(2)').addClass('patientNameLink pointer');
          }
        }
        patientChrgDetTbl = $('#patientChrgDet').DataTable($.extend( tableoptionSet, tableoptionSet2 ));;
      }
      break;
    case "iiLDHolder":      
      if ( ! $.fn.DataTable.isDataTable( '#incmpItmsDet' ) ) { 
        var tableoptionSet2 ={
          "order": [[ 11, "desc" ]],
          "columns": [
            {
                "className": 'details-control',
                     "orderable": false,
                     "data": null,
                     "defaultContent": '',
                     "render": function () {
                         return '<i class="far fa-plus-square"></i>';
                     },
                     width:"15px"
            },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            { "orderable": true },
            {
              "orderable": false,
              "visible":false             
            },
             {
              "orderable": true,
              "visible":false,
              "searchable": false              
             }
          ] 
        }     
        incmpItmsDetTbl = $('#incmpItmsDet').DataTable($.extend( tableoptionSet, tableoptionSet2 ));
      }
      break;
  }
}
  
function initFilterTemplate(templateName){
  try {
    var promptVal = "^MINE^,3";
    Lib.makeCall("14_mp_amb_org_or_loc",promptVal,true,function(reply) {
      reply = JSON.parse(reply);      
      var ade = templateName.find("#select-practiceLocCR")   
      $.each(reply.RS.QUAL, function (i2, val2) {
        templateName.find("#select-practiceLocCR").append($('<option>').text(val2.LOCATION_NAME).attr('value', val2.LOCATION_ID));        
      })
      templateName.find("#reportrangeCR").daterangepicker({
        singleDatePicker: true,
        singleClasses: "picker_1"
      }, cb);          
    });
  }
  catch (e) {
    alert("The page did not load properly, please refresh the page to try again. Error message: " + e.message);
    NProgress.done();
    templateName.find("#select-practiceLocCR").select2();
    return;
  }
    
}

function populateWQMDDLPL() {
  try {
    var RS = null;
    RS = new XMLCclRequest();
    RS.onreadystatechange = function () {
        if (RS.readyState == 4 || RS.readyState == "complete") {
            if (RS.status == 200) {
                tempObj = JSON.parse(RS.responseText);
                $('#select-WorkListQueue').select2(
                    {
                        placeholder: "Select Work List Queue",
                        allowClear: true,
                        width: 'resolve',
                        data: $.map($(tempObj.RS.QUAL), function (obj) {
                            obj.id = obj.id || obj.LOCATION_ID;
                            obj.text = obj.text || obj.LOCATION_NAME; // replace name with the property used for the text
                            return obj;
                        }),
                    }
                );
                //if (gotLocPref == true && locPref != "") {
                //    $('#select-practiceLoc').val(locPref)
                //    $('#select-practiceLoc').trigger('change')
                //}                    
            }
        }
    };
    RS.open('GET', '14_mp_amb_wq_locations', true)
    try {
      var promptVal = "^MINE^";
      RS.send('MINE');
    }
    catch (e) {
      alert(e.description);
      //NProgress.done();
      return;
    }
  }
  catch(e){
    alert("The page did not load properly, please refresh the page to try again. Error message: " + e.message);
    $('#select-practiceLoc').select2();
    return;
  }
}

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

$(document).ready(function () {
    initFilterTemplate(locDate)
    if (!checkProfile()) {
        $("#mainBodyContent").css("display", "none");
        $("#accessDenied").css("display", "inline");
    }    

});