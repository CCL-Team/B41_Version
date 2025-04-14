/*!
 * Print button for Buttons and DataTables.
 * 2016 SpryMedia Ltd - datatables.net/license
 */

(function( factory ){
	if ( typeof define === 'function' && define.amd ) {
		// AMD
		define( ['jquery', 'datatables.net', 'datatables.net-buttons'], function ( $ ) {
			return factory( $, window, document );
		} );
	}
	else if ( typeof exports === 'object' ) {
		// CommonJS
		module.exports = function (root, $) {
			if ( ! root ) {
				root = window;
			}

			if ( ! $ || ! $.fn.dataTable ) {
				$ = require('datatables.net')(root, $).$;
			}

			if ( ! $.fn.dataTable.Buttons ) {
				require('datatables.net-buttons')(root, $);
			}

			return factory( $, root, root.document );
		};
	}
	else {
		// Browser
		factory( jQuery, window, document );
	}
}(function( $, window, document, undefined ) {
'use strict';
var DataTable = $.fn.dataTable;


var _link = document.createElement( 'a' );

/**
 * Convert a `link` tag's URL from a relative to an absolute address so it will
 * work correctly in the popup window which has no base URL.
 *
 * @param  {node}     el Element to convert
 */
var _relToAbs = function( el ) {
	var url;
	var clone = $(el).clone()[0];
	var linkHost;

	if ( clone.nodeName.toLowerCase() === 'link' || clone.nodeName.toLowerCase() === 'script') {
		_link.href = clone.href;
		linkHost = _link.host;

		// IE doesn't have a trailing slash on the host
		// Chrome has it on the pathname
		if ( linkHost.indexOf('/') === -1 && _link.pathname.indexOf('/') !== 0) {
			linkHost += '/';
		}

		clone.href = _link.protocol+"//"+linkHost+_link.pathname+_link.search;
	}

	return clone.outerHTML;
};

var retStyle = function(tag, column)
{
	var formattedTag = '<td>' + tag + '</td>';
    
    var recREGEX = new RegExp('title="Received"');
    var notREGEX = new RegExp('title="Not Received"');
    var ovrREGEX = new RegExp('title="Not Received\/Over 7 days"');
    
    var faCheck  = $('#faCheck').html();
    var faTimes  = $('#faTimes').html();
    var faAmb    = $('#faAmb').html();
    var faPerson = $('#faPerson').html();
    
    if(column == 2){
        formattedTag = '<td style="width:120px">' + tag.replace('<i class="fas fa-user">', faPerson) + '</td>'
    }
    if(column == 4){
        formattedTag = '<td style="width:100px">' + tag + '</td>'
    }
    if(column == 5){
        formattedTag = '<td style="width:150px">' + tag + '</td>'
    }
    if(column == 6){
        formattedTag = '<td style="width:200px">' + tag + '</td>'
    }
    if(column == 9){	
        if(recREGEX.test(tag)){
            formattedTag = '<td class="text-center">' + faCheck + '</td>'
        }else if(notREGEX.test(tag)){
            formattedTag = '<td class="text-center">' + faTimes + '</td>'
        }else if(ovrREGEX.test(tag)){
            formattedTag = '<td class="text-center">' + faAmb + '</td>'
        }else{
            formattedTag = '<td></td>';
        }
	}
    if(column == 10){
        formattedTag = '<td style="width:150px">' + tag + '</td>'
    }
    if(column == 12){
        formattedTag = '<td style="width:150px">' + tag + '</td>'
    }
    return formattedTag;
}


DataTable.ext.buttons.print = {
	className: 'buttons-print',

	text: function ( dt ) {
		return dt.i18n( 'buttons.print', 'Print' );
	},

	action: function ( e, dt, button, config ) {
        var data = dt.buttons.exportData( config.exportOptions );
		
        var addRow = function ( d, tag, type ) {
			var str = '<tr>';
            var colStyle = '';

			for ( var i=2, ien=d.length ; i<ien ; i++ ) {
				if(type == 'body')
				{
					colStyle= retStyle(d[i], i)
				}
				else
				{
					colStyle = '<'+tag+'>'+d[i]+'</'+tag+'>';
				}
				str += colStyle;
			}

			return str + '</tr>';
		};
        
        // Construct a table for printing
		var html = '<table class="'+dt.table().node().className+'">';
		var tblGrpHdr ="";
		if (typeof tableGroupHeader !== 'undefined') {
			tblGrpHdr = tableGroupHeader;
			//html += '<thead>'+ tableGroupHeader + addRow( data.header, 'th' ) +'</thead>';
			// the variable is defined
		}
		
		if ( config.header ) {
			html += '<thead>'+ tblGrpHdr+addRow( data.header, 'th', 'head' ) +'</thead>';
		}
		
		html += '<tbody>';
		for ( var i=0, ien=data.body.length ; i<ien ; i++ ) {
			html += addRow( data.body[i], 'td', 'body' );
		}
		html += '</tbody>';
		
		if ( config.footer && data.footer ) {
			html += '<tfoot>'+ addRow( data.footer, 'th', 'foot' ) +'</tfoot>';
		}

		// Open a new window for the printable table
		var win = window.open( '', '' );
		var title = config.title;

		if ( typeof title === 'function' ) {
			title = title();
		}

		if ( title.indexOf( '*' ) !== -1 ) {
			title= title.replace( '*', $('title').text() );
		}

		win.document.close();

		// Inject the title and also a copy of the style and link tags from this
		// document so the table can retain its base styling. Note that we have
		// to use string manipulation as IE won't allow elements to be created
		// in the host document and then appended to the new window.
		var head = '<meta http-equiv="X-UA-Compatible" content="IE=edge"><title>'+title+'</title>';

		$('style, link').each( function () {
            head += _relToAbs( this );
		} );
        head += '<link href="I:\\MPages\\PapPathTest\\BootstrapFilesETC\\web-fonts-with-css\\css\\fontawesome-all.min.css" rel="stylesheet">'
        
        win.document.head.innerHTML = head; // Work around for Edge

        var style = win.document.createElement('style');
		style.type = 'text/css';	
		if (style.styleSheet) {
			// IE
			style.styleSheet.cssText = 
                "th { font-size: 10px; word-wrap: normal  }td { font-size: 10px; word-wrap: normal} ";
		} else {
			// Other browsers
			style.innerHTML = "th { font-size: 10px; word-wrap: normal}td { font-size: 10px; word-wrap: normal}";
		}
	
		win.document.getElementsByTagName("head")[0].appendChild( style );
        
        var whatToPrint = document.getElementById('totalMetrics').outerHTML 
		
		// Inject the table and other surrounding information
		win.document.body.innerHTML =
			whatToPrint +
			'<div>'+config.message+'</div>'+
			html;
		// $(win.document.body).html(
		// 	'<h1>'+title+'</h1>'+
		// 	'<div>'+config.message+'</div>'+
		// 	html
		// );

		if ( config.customize ) {
			config.customize( win );
		}

		setTimeout( function () {
			if ( config.autoPrint ) {
				win.print(); // blocking - so close will not
				win.close(); // execute until this is done
			}
		}, 250 );
	},

	title: '*',

	message: '',

	exportOptions: {},

	header: true,

	footer: false,

	autoPrint: true,

	customize: null
};

DataTable.ext.buttons.hrprint = {
	className: 'buttons-print',

	text: function ( dt ) {
		return dt.i18n( 'buttons.print', 'Print' );
	},

	action: function ( e, dt, button, config ) {
        var data = dt.buttons.exportData( config.exportOptions );
		
        var addRow = function ( d, tag, type ) {
			var str = '<tr>';
            var colStyle = '';

			for ( var i=0, ien=d.length ; i<ien ; i++ ) {
				//if(type == 'body')
				//{
				//	colStyle= retStyle(d[i], i)
				//}
				//else
				//{
                //being dumb... this whole print is dumb, and I could have done it better I think now that I know more.
                //But don't have time to fix it all so just copying for HR for now.
                
                // we have to hide some columns.
                if(   i !== HRLogCols.LINKS   
                   && i !== HRLogCols.PER_ID
                   && i !== HRLogCols.ENC_ID
                   && i !== HRLogCols.ORD_ID
                   && i !== HRLogCols.LOCATION
                   && i !== HRLogCols.LAST_APPT_TYPE
                   && i !== HRLogCols.LAST_APPT_DATE
                   && i !== HRLogCols.LAST_APPT_LOC
                   && i !== HRLogCols.LAST_APPT_PROV
                   && i !== HRLogCols.NEXT_APPT_TYPE
                   && i !== HRLogCols.NEXT_APPT_DATE
                   && i !== HRLogCols.NEXT_APPT_LOC
                   && i !== HRLogCols.NEXT_APPT_PROV
                  ){
                      colStyle = '<'+tag+'>'+d[i]+'</'+tag+'>';
                      str += colStyle;
                  }
                
			}

			return str + '</tr>';
		};
        
        // Construct a table for printing
		var html = '<table class="'+dt.table().node().className+'">';
		var tblGrpHdr ="";
		if (typeof hrTableGroupHeader !== 'undefined') {
			tblGrpHdr = hrTableGroupHeader;
			//html += '<thead>'+ tableGroupHeader + addRow( data.header, 'th' ) +'</thead>';
			// the variable is defined
		}
		
		if ( config.header ) {
			html += '<thead>'+ tblGrpHdr+addRow( data.header, 'th', 'head' ) +'</thead>';
		}
		
		html += '<tbody>';
		for ( var i=0, ien=data.body.length ; i<ien ; i++ ) {
			html += addRow( data.body[i], 'td', 'body' );
		}
		html += '</tbody>';
		
		if ( config.footer && data.footer ) {
			html += '<tfoot>'+ addRow( data.footer, 'th', 'foot' ) +'</tfoot>';
		}

		// Open a new window for the printable table
		var win = window.open( '', '' );
		var title = config.title;

		if ( typeof title === 'function' ) {
			title = title();
		}

		if ( title.indexOf( '*' ) !== -1 ) {
			title= title.replace( '*', $('title').text() );
		}

		win.document.close();

		// Inject the title and also a copy of the style and link tags from this
		// document so the table can retain its base styling. Note that we have
		// to use string manipulation as IE won't allow elements to be created
		// in the host document and then appended to the new window.
		var head = '<meta http-equiv="X-UA-Compatible" content="IE=edge"><title>'+title+'</title>';

		$('style, link').each( function () {
            head += _relToAbs( this );
		} );
        head += '<link href="I:\\MPages\\PapPathTest\\BootstrapFilesETC\\web-fonts-with-css\\css\\fontawesome-all.min.css" rel="stylesheet">'
        
        win.document.head.innerHTML = head; // Work around for Edge

        var style = win.document.createElement('style');
		style.type = 'text/css';	
		if (style.styleSheet) {
			// IE
			style.styleSheet.cssText = 
                "th { font-size: 10px; word-wrap: normal  }td { font-size: 10px; word-wrap: normal} ";
		} else {
			// Other browsers
			style.innerHTML = "th { font-size: 10px; word-wrap: normal}td { font-size: 10px; word-wrap: normal}";
		}
	
		win.document.getElementsByTagName("head")[0].appendChild( style );
        
        var whatToPrint = document.getElementById('totalMetricsHR').outerHTML 
		
		// Inject the table and other surrounding information
		win.document.body.innerHTML =
			whatToPrint +
			'<div>'+config.message+'</div>'+
			html;
		// $(win.document.body).html(
		// 	'<h1>'+title+'</h1>'+
		// 	'<div>'+config.message+'</div>'+
		// 	html
		// );

		if ( config.customize ) {
			config.customize( win );
		}

		setTimeout( function () {
			if ( config.autoPrint ) {
				win.print(); // blocking - so close will not
				win.close(); // execute until this is done
			}
		}, 250 );
	},

	title: '*',

	message: '',

	exportOptions: {},

	header: true,

	footer: false,

	autoPrint: true,

	customize: null
};




return DataTable.Buttons;
}));
