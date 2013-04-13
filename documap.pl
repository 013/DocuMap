#!/usr/bin/perl -w
# 12/04/13
use DBI;
use DBD::mysql;

use warnings;
use strict;

# Create all variables
my $database    = "documap";
our $table      = "documentaries";
my $host        = "localhost";
my $port        = "3306";
my $user        = "username";
my $pass        = "password";
my $tbl_struct  = "
CREATE TABLE IF NOT EXISTS $table (
id              MEDIUMINT NOT NULL AUTO_INCREMENT,
name            VARCHAR(40) NOT NULL,
description     VARCHAR(300),
lat             FLOAT,
lng             FLOAT,
category        VARCHAR(120),
country_code    VARCHAR(5),	
link            VARCHAR(120),

PRIMARY KEY     (id)
);
";

# Connect to DB
our $dbh = DBI->connect("DBI:mysql:$database:localhost:$port", $user, $pass)
	or die "Error connecting to MySQL Database:" . $DBI::errstr;

# Test a query 
my $query_h = $dbh->prepare($tbl_struct);

$query_h->execute() # Creates the table - if it doesn't exist
	or die "Error quering database: " . $DBI::errstr;
undef $query_h;

# --------------------------*
# Creates static files:     |
# index.html                |
# js/*.js                   |
# --------------------------*
sub create_static_doc {
	# Remove old file
	unlink "index.html";
	if (length($_[0] // '') ) {
		print $_[0];
		# create_js_cat($_[0]);
		unlink glob("js/$_[0].js");
	} else {
		unlink glob("js/*.js");
		my $query = "SELECT DISTINCT category FROM $table";
		my $query_h = $dbh->prepare($query);
		$query_h->execute();
	
		if ($query_h->rows == 0) {
			return "No documentaries found.\n";
		}
	
		while (my @data = $query_h->fetchrow_array()) {
			#print "bleh";#my $data;
			print $data[0];
			# create_js_cat($data[0]);
		}
		# This will create js/new.js
		# create_js_cat();
		
	} # At this point, all js/*.js files should be created
	# 
	#
	#	Once the categories have be done
	#	Create the index.html
	#

}

sub create_js_cat {
	# Create each category's JS File
	my $var_nam = "documentaries";
	if (length($_[0] // '')) {
		$var_nam = $_[0];
	}
	my $category = '%category%';
	my $query = "SELECT id, name, lat, lng, description, category, link, country_code FROM $table WHERE category LIKE ?";
	my $query_h = $dbh->prepare($query);
	$query_h->execute($category);

	my $file_c = "//\n// TDATEA\n//\n//\n\n$var_nam = [\n";
	my $entry;
	my $gdp = "var gdpData = {\n";
	my $xx;
	while (my @data = $query_h->fetchrow_array()) {
		$entry = sprintf("{latLng: [%.2f, %.2f], name: \"%s\", description: \"%s\", category: \"%s\", link: \"%s\"},\n", $data[2], $data[3], $data[1], $data[4], $data[5], $data[6]);
		$file_c .= $entry;
		# Count Country_codes
		my $cc = $data[7];
		my $qh = $dbh->prepare("SELECT COUNT(country_code) FROM $table WHERE country_code=?");
		$qh->execute($cc);
		$xx = $qh->fetchrow();
		$gdp .= "\"$cc\" : $xx,\n";
	}
	$gdp = substr($gdp, 0, -2) . "\n};\n\n";
	$file_c = substr($file_c, 0, -2) . "\n];\n\n";
	
	open(JSFILE, ">>js/$var_nam.js");
	print JSFILE $file_c;
	
	if ($var_nam ne "documentaries" ) {
		print JSFILE "documentaries = documentaries.concat($var_nam);\n";
		close(JSFILE);
	} else {
		print JSFILE $gdp;
		#my $c_codes = "var gdpData = {};";
	}
	$query_h->finish;
	return 0;
}

# Check for dead links 
sub check_dead_links {
	my $rem_links = 0;
	if (length($_[0] // '') && $_[0] == 1 ) {
		$rem_links = 1;
	}
	my $query = "SELECT link FROM $table";
		
	print $rem_links;
}

sub insert_doc {
	my $name = $_[0];
	my $description = $_[1];
	my $query = "INSERT INTO $table VALUES(NULL, 'name2', 'description2', 101, 51, 'category2', 'UK', 'http://swiftler.com/2')";
	my $query_h = $dbh->prepare($query);
	$query_h->execute() or die "Error inserting into database: " . $DBI::errstr;
}

#insert_doc();
#create_js_cat();
#create_static_doc();
#check_dead_links(1);


$dbh->disconnect;

our $JS =
"
//
// 09/04/13 - 18:33
//
//
var open_files = ['new'];

	\$(document).ready(function() {
		\$(function(){
			var map,

			map = new jvm.WorldMap({
				container: \$('#map'),
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
				//scaleColors: ['#C8EEFF', '#0071A4'],
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
					\$('#other_info').html(\"<p>\"+el+\"</p>\");
				},
				onMarkerSelected: function(e, el, code) {
					name = arr[el][\"name\"];
					// Needs to be cleaned up -
					for (var p = 0; p < documentaries.length; p++) {
						a_name = documentaries[p][\"name\"];
						if (a_name == name) {
							\$('#doc_info').html(
								\"<h2>\"+documentaries[p][\"name\"] + \"</h2>\"+
								//\"<p>\"+documentaries[p][\"category\"]+
								\"<p><label>Link: </label><a href=\\\"\"+documentaries[p][\"link\"]+\"\\\">Click</a></p><p>\" +
								documentaries[p][\"description\"]+\"<p>\"
							);
						}
					}
				},
				backgroundColor: '#383f47'
			});
			\$(\".checkbox\").click(function() {
				//\$.inArray(value, array)
				window.arr=[];

				w_cats = \$(\"#cat_f\").serializeArray();

				map.removeAllMarkers();

				for (var i = 0; i < w_cats.length; i++) {
					wanted_cat = w_cats[i][\"name\"];

					fl_js = wanted_cat.replace(/\\'/g, '');
					// If the file isn't in the open array, add to array and open file
					if (\$.inArray(fl_js, open_files) == -1) {
						open_files.push(fl_js);

						\$.getScript(\"js/\"+ fl_js + '.js', function(data, textStatus, jqxhr) {
						for (var p = 0; p < documentaries.length; p++) {
							a_cat = documentaries[p][\"category\"];
							//If the wanted category is a substring of a_cat
							if (a_cat.indexOf(wanted_cat) !== -1) {
								var obj = {
									latLng: documentaries[p][\"latLng\"],
									name: documentaries[p][\"name\"]
								};
								window.arr.push(obj);
							}
						}
						map.addMarkers(window.arr);
						});

					} else {
					for (var p = 0; p < documentaries.length; p++) {
						a_cat = documentaries[p][\"category\"];
						//If the wanted category is a substring of a_cat
						if (a_cat.indexOf(wanted_cat) !== -1) {
							var obj = {
								latLng: documentaries[p][\"latLng\"],
								name: documentaries[p][\"name\"]
							};
							window.arr.push(obj);
						}
					}
					map.addMarkers(window.arr);
					}
				}
		});
		// Checks the new category, also running the function to add markers
		\$('input[type=\"checkbox\"]').prop(\"checked\", false);
		\$('input[name=\"\\'new\\'\"]').click();

		\$(\".test\").click(function() {
			//
			\$.getScript(\"js/added.js\");
		});

	});
});


//var arr= [];

";

#open(TFILE, ">>test.txt");
#print TFILE $JS;
#close(TFILE);
