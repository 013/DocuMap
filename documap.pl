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
# [^\\]\"(.*?)[^\\]\"
# \\"\1\\"
our $JS =
"
documentaries = [
{latLng: [45.05, 135.00], name: \"Wild Russia - The Secret Forest\", description: \"Wild Russia is a landmark High Definition series charting a journey across this vast land that stretches from Europe to the Pacific Ocean.\", category: \"'new' 'nature'\", link: \"http://www.youtube.com/watch?v=z9n49ViHgvY\"},
{latLng: [58.30, 93.99], name: \"Wild Russia - Siberia\", description: \"Wild Russia is a landmark High Definition series charting a journey across this vast land that stretches from Europe to the Pacific Ocean.\", category: \"'new' 'nature'\", link: \"http://www.youtube.com/watch?v=1a5s6Ouhaf8\"},
{latLng: [52.13, 5.29], name: \"Carl Sagan's Cosmos: Dutch Golden Age (1/3)\", description: \"An excerpt from Carl Sagan's Cosmos seris\", category: \"'new' 'science'\", link: \"http://www.youtube.com/watch?v=GvY8dQQI13Q\"}
];
var open_files=[\"new\"]; var gdpData={};\$(document).ready(function(){\$(function(){var e,e=new jvm.WorldMap({container:\$(\"#map\"),map:\"world_mill_en\",regionsSelectable:true,regionsSelectableOne:true,markersSelectable:true,markersSelectableOne:true,series:{regions:[{values:gdpData,scale:[\"#C8EEFF\",\"#0071A4\"],normalizeFunction:\"polynomial\"}]},onRegionLabelShow:function(e,t,n){if(!gdpData[n]){var r=0}else{var r=gdpData[n]}t.html(t.html()+\" (Documentaries: \"+r+\")\")},normalizeFunction:\"polynomial\",hoverOpacity:.4,hoverColor:false,markerStyle:{initial:{fill:\"#0071A4\",stroke:\"#fff\"},hover:{stroke:\"#fff\",r:7},selected:{fill:\"#000\"}},regionStyle:{selected:{fill:\"#7070B6\"}},onRegionSelected:function(e,t,n){\$(\"#other_info\").html(\"<p>\"+t+\"</p>\")},onMarkerSelected:function(e,t,n){name=arr[t][\"name\"];for(var r=0;r<documentaries.length;r++){a_name=documentaries[r][\"name\"];if(a_name==name){\$(\"#doc_info\").html(\"<h2>\"+documentaries[r][\"name\"]+\"</h2>\"+'<p><label>Link: </label><a href=\"'+documentaries[r][\"link\"]+'\">Click</a></p><p>'+documentaries[r][\"description\"]+\"<p>\")}}},backgroundColor:\"#383f47\"});\$(\".checkbox\").click(function(){window.arr=[];w_cats=\$(\"#cat_f\").serializeArray();e.removeAllMarkers();for(var t=0;t<w_cats.length;t++){wanted_cat=w_cats[t][\"name\"];fl_js=wanted_cat.replace(/\'/g,\"\");if(\$.inArray(fl_js,open_files)==-1){open_files.push(fl_js);\$.getScript(\"js/\"+fl_js+\".js\",function(t,n,r){for(var i=0;i<documentaries.length;i++){a_cat=documentaries[i][\"category\"];if(a_cat.indexOf(wanted_cat)!==-1){var s={latLng:documentaries[i][\"latLng\"],name:documentaries[i][\"name\"]};window.arr.push(s)}}e.addMarkers(window.arr)})}else{for(var n=0;n<documentaries.length;n++){a_cat=documentaries[n][\"category\"];if(a_cat.indexOf(wanted_cat)!==-1){var r={latLng:documentaries[n][\"latLng\"],name:documentaries[n][\"name\"]};window.arr.push(r)}}e.addMarkers(window.arr)}}});\$('input[type=\"checkbox\"]').prop(\"checked\",false);\$(\"input[name=\\\"'new'\\\"]\").click();\$(\".test\").click(function(){\$.getScript(\"js/added.js\")})})})

";

open(TFILE, ">>test2.txt");
print TFILE $JS;
close(TFILE);
die();
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
		# [2] [3] - LatLng, [1] - Name, [4] - Description, [5] - Category, [6] - Link
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
		print JSFILE $JS; # The large frontend Javascript
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
create_js_cat();
#create_static_doc();
#check_dead_links(1);


$dbh->disconnect;

