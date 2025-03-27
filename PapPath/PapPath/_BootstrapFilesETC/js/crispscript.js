var DischargeMonthCategory = [];
var MonthYearCategory = [];
var PriorFYMEADischargeCount = []; 
var	ThisFYMEADischargeCount	= []; 
var PriorFYCrispDischargeCount = []; 
var ThisFYCrispDischargeCount = []; 
var PriorFyPerc = []; 
var	ThisFyPerc = [];


$(document).ready(function () {
    var institutionName = GetKey('INSTITUTIONNAME').toUpperCase();

    function LoadActivityData(fromDate, toDate) {
        
        var arrParams = new Array();
        arrParams["Facility"] = new Array(institutionName, "Text")
        arrParams["FromDate"] = new Array(fromDate, "Text")
        arrParams["Todate"] = new Array(toDate, "Text")
        var InfoQuery = new Queries("CRISPReAdmitDashFYCompare", arrParams);
        InfoQuery.Execute();

        for (var i = 0; i < InfoQuery.Values.length; i++) {
            DischargeMonthCategory.push((InfoQuery.GetValue(i, "DischargeMonth")));
            MonthYearCategory.push((InfoQuery.GetValue(i, "ThisMonthYear")));
            PriorFYMEADischargeCount.push((InfoQuery.GetValue(i, "PriorFYMEADischargeCount")));
            ThisFYMEADischargeCount.push((InfoQuery.GetValue(i, "ThisFYMEADischargeCount")));
            PriorFYCrispDischargeCount.push((InfoQuery.GetValue(i, "PriorFYCrispDischargeCount")));
            ThisFYCrispDischargeCount.push((InfoQuery.GetValue(i, "ThisFYCrispDischargeCount")));
            PriorFyPerc.push((InfoQuery.GetValue(i, "PriorFyPerc")));
            ThisFyPerc.push((InfoQuery.GetValue(i, "ThisFyPerc")));

            colIndex = 0;
        }
        init_echarts();
        
        if (percComp > 50)
        {
            document.getElementById("percComplete").className = "green";
        }

        if (percNotReady > 50) {
            document.getElementById("percComplete").className = "red";
        }
    }
});

function init_echarts() {
    
            if( typeof (echarts) === 'undefined'){ return; }
            console.log('init_echarts');
              var theme = {
              color: [
                  '#26B99A', '#34495E', '#BDC3C7', '#3498DB',
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
                      normal: {color: '#408829'},
                      emphasis: {color: '#408829'}
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
          };

          
          //echart Bar
          
        if ($('#reAdmitRatio').length ){
          
              var echartBar = echarts.init(document.getElementById('reAdmitRatio'), theme);

              echartBar.setOption({
                title: {
                  text: 'FY - 17',
                  subtext: 'Percent'
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
                }
              }
            },
                legend: {
                  data: ['FY - 17', 'FY - 18']
                },
                calculable: false,
                xAxis: [{
                  type: 'category',
                  data: DischargeMonthCategory      // ['July',	'August',	'September',	'October',	'November',	'December',	'January',	'February',	'March',	'April',	'May',	'June']
                }],
                yAxis: [{
                  type: 'value'
                }],
                series: [{
                  name: 'FY - 16',
                  type: 'line',
                  data: PriorFyPerc, // ['7.32',	'6.84',	'6',	'6.17',	'6.65',	'7.72',	'9.06',	'9.51',	'7.84',	'4.76',	'2.95',	'1.4'],
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
                },{
                  name: 'FY - 17',
                  type: 'line',
                  data: ThisFyPerc,      //['0.03',	'0.04',	'0.04',	'0.03',	'0.06',	'0.05',	'0.97',	'1.81',	'3.65',	'5.31',	'6.06',	'5.7'],
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

                echartBar.on('click', function (params) {
                        if (params.componentType === 'markPoint') {
                                // clicked on markPoint
                                // if (params.seriesIndex === 5) {
                                // 		// clicked on a markPoint which belongs to a series indexed with 5
                                // }
                                alert('Mark Point Series: '+params.seriesIndex+ ' Mark Point Name: '+params.name )
                        }
                        else if (params.componentType === 'series') {
                                if (params.seriesType === 'graph') {
                                        if (params.dataType === 'edge') {
                                            alert(params.dataType);
                                                // clicked on an edge of the graph
                                        }
                                        else {
                                            alert(params.name);
                                                // clicked on a node of the graph
                                        }
                                }
                                else{
                                    alert(params.name +' '+ params.seriesName);
                                }
                        }

                });
        }
        if ($('#reAdmitByPhysician').length ){
            
              var echartBar = echarts.init(document.getElementById('reAdmitByPhysician'), theme);
              echartBar.setOption({
                title: {
                  text: 'FY - 17',
                  subtext: 'Percent'
                },
                tooltip: {
                  trigger: 'axis'
                },
                toolbox: {
                show: true,
                feature: {
                        magicType: {
                            show: true
                        },
                        restore: {
                            show: true,
                            title: "Restore"
                        },
                        saveAsImage: {
                            show: true,
                            title: "Save Image"
                        }
                    }
                },
                legend: {
                  data: ['Crisp']
                },
                calculable: false,
                yAxis: [{
                  type: 'category',
                  data: ['Chiancone, Giancarlo Mass',	'Johnson, Karen',	'Weissman, Neil J',	'Sarabchi, Fardad',	'Nokkeo, Jay',	'Lee, Brian George',	'Sood Md, Sanjiv',	'Diphillips, Raymond P.',	'Ramakrishnan, Meera',	'Fried, Janet A.',	'Milwater, Mehrnaz',	'Luczycki, Stephen M',	'Handy, Kevin Grant',	'Zhou, Haobo',	'Rashkin, Jason J',	'Keisling, Robert W',	'Bromeland, Sarah',	'Yeomans, Charlott H.',	'Widell, Jared',	'Jani, Sandeep M',	'Cantor, Brian',	'Kabbany, Mohammad T',	'Bell, Randy S.',	'Gupta, Yudh V.',	'Pirouz, Babak Salehi',	'Zzrodriguez, Samuel',	'Vaince, Uzma Z',	'Pathak, Amit P',	'Tulu, Hunde Sado',	'Munoz, Mark L',	'Southwell, Gillian',	'Ohri, Chaand',	'Shepperd, Scott D.',	'Waris, Mohammad S',	'Obadaseraye, Iseri F.',	'Pristoop, Raphael H',	'Jakharia, Niyati K',	'Damle, Sameer',	'Warner, Elizabeth A',	'Sokolovic, Mladen']
                }],
                xAxis: [{
                  type: 'value'
                }],
                series: [{
                  name: 'Crisp',
                  type: 'bar',
                    itemStyle: {
                    normal: {
                        color: new echarts.graphic.LinearGradient(
                            0, 0, 0, 1,
                            [
                                {offset: 0, color: '#83bff6'},
                                {offset: 0.5, color: '#188df0'},
                                {offset: 1, color: '#188df0'}
                            ]
                        )
                    },
                    emphasis: {
                        color: new echarts.graphic.LinearGradient(
                            0, 0, 0, 1,
                            [
                                {offset: 0, color: '#2378f7'},
                                {offset: 0.7, color: '#2378f7'},
                                {offset: 1, color: '#83bff6'}
                            ]
                        )
                    }
                },
                  data: ['100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'100',	'81.82',	'80.65',	'80',	'78.57',	'76.92',	'75.62',	'75.42',	'75',	'74.17',	'73.29',	'72.24',	'71.43',	'70.34',	'69.78',	'69.76',	'69.23',	'68.73',	'68.53',	'67.88',	'66.67',	'66.67',	'66.67'],
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
                ]
              });

                echartBar.on('click', function (params) {
                        if (params.componentType === 'markPoint') {
                                // clicked on markPoint
                                // if (params.seriesIndex === 5) {
                                // 		// clicked on a markPoint which belongs to a series indexed with 5
                                // }
                                alert('Mark Point Series: '+params.seriesIndex+ ' Mark Point Name: '+params.name )
                        }
                        else if (params.componentType === 'series') {
                                if (params.seriesType === 'graph') {
                                        if (params.dataType === 'edge') {
                                            alert(params.dataType);
                                                // clicked on an edge of the graph
                                        }
                                        else {
                                            alert(params.name);
                                                // clicked on a node of the graph
                                        }
                                }
                                else{
                                    alert(params.name +' '+ params.seriesName);
                                }
                        }

                });
        }
        if ($('#MeaCripChart').length ){
          
              var echartBar = echarts.init(document.getElementById('MeaCripChart'), theme);

              echartBar.setOption({
                title: {
                  text: 'FY - 17',
                  subtext: 'Percent'
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
                  type: ['line', 'bar', 'stack', 'tiled']
                },
                restore: {
                  show: true,
                  title: "Restore"
                },
                saveAsImage: {
                  show: true,
                  title: "Save Image"
                }
              }
            },
                legend: {
                  data: ['Crisp', 'MEA']
                },
                calculable: false,
                xAxis: [{
                  type: 'category',
                  data: MonthYearCategory      //['Jul-16',	'Aug-16',	'Sep-16',	'Oct-16',	'Nov-16',	'Dec-16',	'Jan-17',	'Feb-17',	'Mar-17',	'Apr-17',	'May-17',	'Jun-17']
                }],
                yAxis: [{
                  type: 'value'
                }],
                series: [{
                  name: 'Crisp',
                  type: 'bar',
                  data: PriorFYCrispDischargeCount, // ['3305',	'3271',	'2798',	'2921',	'2823',	'3366',	'4071',	'4202',	'3881',	'2236',	'1925',	'854'],
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
                },{
                  name: 'MEA',
                  type: 'bar',
                  data:ThisFYCrispDischargeCount,                   //['45161',	'47792',	'46611',	'47374',	'42431',	'43609',	'44910',	'44173',	'49504',	'46960',	'65266',	'60975'],
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

                echartBar.on('click', function (params) {
                        if (params.componentType === 'markPoint') {
                                // clicked on markPoint
                                // if (params.seriesIndex === 5) {
                                // 		// clicked on a markPoint which belongs to a series indexed with 5
                                // }
                                alert('Mark Point Series: '+params.seriesIndex+ ' Mark Point Name: '+params.name )
                        }
                        else if (params.componentType === 'series') {
                                if (params.seriesType === 'graph') {
                                        if (params.dataType === 'edge') {
                                            alert(params.dataType);
                                                // clicked on an edge of the graph
                                        }
                                        else {
                                            alert(params.name);
                                                // clicked on a node of the graph
                                        }
                                }
                                else{
                                    alert(params.name +' '+ params.seriesName);
                                }
                        }

                });
        } 	   
    }