//
// 09/04/13 - 18:33
//
//

documentaries = [
{latLng: [45.05, 135.00], name: "Wild Russia - The Secret Forest", description: "Wild Russia is a landmark High Definition series charting a journey across this vast land that stretches from Europe to the Pacific Ocean.", category: "'new' 'nature'", link: "http://www.youtube.com/watch?v=z9n49ViHgvY"},
{latLng: [58.30, 93.99], name: "Wild Russia - Siberia", description: "Wild Russia is a landmark High Definition series charting a journey across this vast land that stretches from Europe to the Pacific Ocean.", category: "'new' 'nature'", link: "http://www.youtube.com/watch?v=1a5s6Ouhaf8"},
{latLng: [52.13, 5.29], name: "Carl Sagan's Cosmos: Dutch Golden Age (1/3)", description: "An excerpt from Carl Sagan's Cosmos seris", category: "'new' 'science'", link: "http://www.youtube.com/watch?v=GvY8dQQI13Q"}
];
country = [];

var gdpData = {
	"GB" : 1,
	"KP" : 1,
	"MX" : 1,
	"US" : 2,
	"RU" : 2,
	"AR" : 1,
	"NL" : 1,
	"CN" : 1
};

var open_files = ['new'];

	$(document).ready(function() {
		$(function(){
			var map,
			map = new jvm.WorldMap({
				container: $('#map'),
				map: 'world_mill_en',
				regionsSelectable: true,
				regionsSelectableOne: true,
				markersSelectable: true,
				markersSelectableOne: true,
				series: {
					regions: [{
						values: gdpData,
						scale: ['#C8EEFF', '#0071A4'],
						normalizeFunction: 'polynomial'
					}],
				},
				onRegionLabelShow: function(event, label, index) {
					if (! gdpData[index]) {
						var total_docs = 0;
					} else {
						var total_docs = gdpData[index];
					}
					label.html(label.html()+' (Documentaries: '+total_docs+')');
				},
				normalizeFunction: 'polynomial',
				hoverOpacity: 0.4,
				hoverColor: false,
				markerStyle: {
					initial: {
						fill: '#0071A4',
						stroke: '#fff'
					},
					hover: {
						stroke: '#fff',
						r: 7
					},
					selected: {
						fill: '#000'
					}
				},
				regionStyle: {
					selected: {
						fill: '#7070B6'
					}
				},
				onRegionSelected: function(e, el, code) {
					$('#other_info').html("<p>"+el+"</p>");
					country_code = el;
					if ($.inArray(country_code, open_files) == -1) {
						open_files.push(country_code);
						$.getScript("js/"+ country_code + ".js", function(data, textStatus, jqxhr) {
							//id = doc
							console.log(country);
							
							for (var i = 0; i < country.length; i++) {
								console.log(country);
								da_cc = country[i]["country_code"];
								//alert(da_cc);
								if (da_cc.indexOf(country_code) !== -1) {
									var o_info = {
										name: country[i]["name"],
										description: country[i]["description"]
									};
									$('#other_info').html(
										$('#other_info').html() + 
										"<p>" + o_info["name"] + "<br> - " + o_info["description"] + "<p>"
									);
								}
							}
						});
					}

				},
				onMarkerSelected: function(e, el, code) {
					name = arr[el]["name"];
					// Needs to be cleaned up -
					for (var p = 0; p < documentaries.length; p++) {
						a_name = documentaries[p]["name"];
						if (a_name == name) {
							$('#doc_info').html(
								"<h2>"+documentaries[p]["name"] + "</h2>"+
								//"<p>"+documentaries[p]["category"]+
								"<p><label>Link: </label><a href=\""+documentaries[p]["link"]+"\">Click</a></p><p>" +
								documentaries[p]["description"]+"<p>"
							);
						}
					}
				},
				backgroundColor: '#383f47'
			});
			$(".checkbox").click(function() {
				//$.inArray(value, array)
				window.arr=[];

				w_cats = $("#cat_f").serializeArray();

				map.removeAllMarkers();

				for (var i = 0; i < w_cats.length; i++) {
					wanted_cat = w_cats[i]["name"];

					fl_js = wanted_cat.replace(/\'/g, '');
					// If the file isn't in the open array, add to array and open file
					if ($.inArray(fl_js, open_files) == -1) {
						open_files.push(fl_js);

						$.getScript("js/"+ fl_js + '.js', function(data, textStatus, jqxhr) {
						for (var p = 0; p < documentaries.length; p++) {
							a_cat = documentaries[p]["category"];
							//If the wanted category is a substring of a_cat
							if (a_cat.indexOf(wanted_cat) !== -1) {
								var obj = {
									latLng: documentaries[p]["latLng"],
									name: documentaries[p]["name"]
								};
								window.arr.push(obj);
							}
						}
						map.addMarkers(window.arr);
						});

					} else {
					for (var p = 0; p < documentaries.length; p++) {
						a_cat = documentaries[p]["category"];
						//If the wanted category is a substring of a_cat
						if (a_cat.indexOf(wanted_cat) !== -1) {
							var obj = {
								latLng: documentaries[p]["latLng"],
								name: documentaries[p]["name"]
							};
							window.arr.push(obj);
						}
					}
					map.addMarkers(window.arr);
					}
				}
		});
		// Checks the new category, also running the function to add markers
		$('input[type="checkbox"]').prop("checked", false);
		$('input[name="\'new\'"]').click();
	});
});


//var arr= [];
