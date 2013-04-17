#!/usr/bin/perl -w
# 12/04/13
use DBI;
use DBD::mysql;

use warnings;
use strict;
use POSIX qw(strftime);

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
our $JS = # This is only shortened the help the readability of this perl script
"var open_files=[\"new\"];\$(document).ready(function(){\$(function(){var e,e=new jvm.WorldMap({container:\$(\"#map\"),map:\"world_mill_en\",regionsSelectable:true,regionsSelectableOne:true,markersSelectable:true,markersSelectableOne:true,series:{regions:[{values:gdpData,scale:[\"#C8EEFF\",\"#0071A4\"],normalizeFunction:\"polynomial\"}]},onRegionLabelShow:function(e,t,n){if(!gdpData[n]){var r=0}else{var r=gdpData[n]}t.html(t.html()+\" (Documentaries: \"+r+\")\")},normalizeFunction:\"polynomial\",hoverOpacity:.4,hoverColor:false,markerStyle:{initial:{fill:\"#0071A4\",stroke:\"#fff\"},hover:{stroke:\"#fff\",r:7},selected:{fill:\"#000\"}},regionStyle:{selected:{fill:\"#7070B6\"}},onRegionSelected:function(e,t,n){\$(\"#other_info\").html(\"<p>\"+t+\"</p>\")},onMarkerSelected:function(e,t,n){name=arr[t][\"name\"];for(var r=0;r<documentaries.length;r++){a_name=documentaries[r][\"name\"];if(a_name==name){\$(\"#doc_info\").html(\"<h2>\"+documentaries[r][\"name\"]+\"</h2>\"+'<p><label>Link: </label><a href=\"'+documentaries[r][\"link\"]+'\">Click</a></p><p>'+documentaries[r][\"description\"]+\"<p>\")}}},backgroundColor:\"#383f47\"});\$(\".checkbox\").click(function(){window.arr=[];w_cats=\$(\"#cat_f\").serializeArray();e.removeAllMarkers();for(var t=0;t<w_cats.length;t++){wanted_cat=w_cats[t][\"name\"];fl_js=wanted_cat.replace(/\'/g,\"\");if(\$.inArray(fl_js,open_files)==-1){open_files.push(fl_js);\$.getScript(\"js/\"+fl_js+\".js\",function(t,n,r){for(var i=0;i<documentaries.length;i++){a_cat=documentaries[i][\"category\"];if(a_cat.indexOf(wanted_cat)!==-1){var s={latLng:documentaries[i][\"latLng\"],name:documentaries[i][\"name\"]};window.arr.push(s)}}e.addMarkers(window.arr)})}else{for(var n=0;n<documentaries.length;n++){a_cat=documentaries[n][\"category\"];if(a_cat.indexOf(wanted_cat)!==-1){var r={latLng:documentaries[n][\"latLng\"],name:documentaries[n][\"name\"]};window.arr.push(r)}}e.addMarkers(window.arr)}}});\$('input[type=\"checkbox\"]').prop(\"checked\",false);\$(\"input[name=\\\"'new'\\\"]\").click();\$(\".test\").click(function(){\$.getScript(\"js/added.js\")})})})";
our $HTML = "<!DOCTYPE html><html><head><title>DocuMap</title><link rel=\"stylesheet\" href=\"css/stylesheet.css\" type=\"text/css\" media=\"screen\"/><link rel='shortcut icon' href=\"favicon.ico\" type=\"image/x-icon\"/></head><body><div id=\"map\"></div><div class=\"container\"><div id=\"lower_half\" class=\"row\"><div id=\"categories\" class=\"span4\"><h2>Categories:</h2><form id=\"cat_f\" name=\"cat_c\"><ul class=\"cat_choice\"><li><label class=\"checkbox\"><input name=\"'new'\" type=\"checkbox\" value=\"1\" unchecked>New</label></li><li><label class=\"checkbox\"><input name=\"'newsandpolitics'\" type=\"checkbox\" value=\"1\">News & Politics</label></li><li><label class=\"checkbox\"><input name=\"'technology'\" type=\"checkbox\" value=\"1\">Technology</label></li><li><label class=\"checkbox\"><input name=\"'food'\" type=\"checkbox\" value=\"1\">Food</label></li><li><label class=\"checkbox\"><input name=\"'crime'\" type=\"checkbox\" value=\"1\">Crime</label></li><li><label class=\"checkbox\"><input name=\"'culture'\" type=\"checkbox\" value=\"1\">Culture</label></li></ul></form></div><div id=\"doc_info\" class=\"span4\"><h2>Documentary Info</h2></div><div id=\"other_info\" class=\"span4\"><button class=\"test\">Test</button></div></div></div><script src=\"jquery/jquery.min.js\" ></script><script src=\"jquery/jquery-jvectormap-1.2.2.min.js\" ></script><script src=\"jquery/jquery-jvectormap-world-mill-en.js\" ></script><script src=\"js/documentaries.js\" ></script></body></html>";

#Connect to DB
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
	# Remove old index file
	unlink "index.html";
	if (length($_[0] // '') ) {
		# If a variable is passed, only created that one JS file
		unlink glob("js/$_[0].js");
		create_js_cat($_[0]);
	} else {
		# Assumes all JS files want to be re-created
		unlink glob("js/*.js");
		my $query = "SELECT DISTINCT category FROM $table"; # Get a list of categories
		my $query_h = $dbh->prepare($query);
		$query_h->execute();
		
		if ($query_h->rows == 0) {
			return "No documentaries found.\n";
		}
		
		while (my @data = $query_h->fetchrow_array()) {
			my $cat = $data[0];
			# Get each category between single quotes
			# Since the category column is like :
			# 'new', 'technology', 'SomeOtherCategory'
			create_js_cat($_) for $cat =~ /\'(.*?)\'/g;
		}
		# This will create js/documentaries.js
		create_js_cat();
		
	} # At this point, all js/*.js files should be created
	#
	#
	#	Once the categories have be done
	#	Create the index.html
	#

	open(HTML_FILE, ">>index.html");
	print HTML_FILE $HTML;
	close(HTML_FILE);

	return 0;
}

sub create_js_cat {
	# Create each category's JS File
	my $var_nam = "documentaries";
	my $query = "";
	if (length($_[0] // '') && $_[1] ne 1) {
		# If a variable has been passed, that is now the var and file name
		$var_nam = $_[0];
		#my $category = '%category%'; # Don't think is needed ?
		$query = "SELECT id, name, lat, lng, description, category, link, country_code FROM $table WHERE category LIKE ?";
	}
	if (length($_[1] // '') && $_[1] eq 1) {
		my $cc = 1;
		$var_nam = $_[0];
		$query = "SELECT id, name, lat, lng, description, category, link, country_code FROM $table WHERE country_code = ?";
	}
	
	my $query_h = $dbh->prepare($query);
	if ($var_nam eq "documentaries" ) {
		# If we are creating the documentaries.js file, we only want to include new documentaries
		$query_h->bind_param( 1, "%new%");
	} elsif ($_[1] ne 1) {
		$query_h->bind_param( 1, "%$var_nam%");
	} else {
		$query_h->bind_param( 1, $var_nam);
	}
	$query_h->execute();
	
	my $date = strftime "%d/%m/%Y", localtime; 
	# Time at the top of the file so we know when it was made
	my $file_c = "//\n// $date\n//\n//\n$var_nam = [\n";
	# Temp variable for each documentary
	my $entry;
	my $gdp = "var gdpData = {\n";
	# Temp variable for gdpData
	my $xx;
	while (my @data = $query_h->fetchrow_array()) {
		$entry = sprintf("{latLng: [%.2f, %.2f], name: \"%s\", description: \"%s\", category: \"%s\", link: \"%s\"},\n", $data[2], $data[3], $data[1], $data[4], $data[5], $data[6]);
		# [2] [3] - LatLng, [1] - Name, [4] - Description, [5] - Category, [6] - Link
		$file_c .= $entry;
		# Count Country_codes
		my $cc = $data[7];
		my $qh = $dbh->prepare("SELECT COUNT(country_code) FROM $table WHERE country_code=?");
		$qh->bind_param(1, $cc);
		$qh->execute();
		$xx = $qh->fetchrow();
		$gdp .= "\"$cc\" : $xx,\n";
	}
	if ($query_h->rows != 0) {
		$gdp = substr($gdp, 0, -2) . "\n};\n\n";
		$file_c = substr($file_c, 0, -2) . "\n];\n\n";
	} else {
		$gdp .= "\n};\n";
		$file_c .= "\n];\n";
	}
	
	open(JSFILE, ">>", "js/$var_nam.js") or die("Can't open js/$var_nam.js");
	print JSFILE $file_c;
	
	if ($var_nam ne "documentaries" ) {
		print JSFILE "documentaries = documentaries.concat($var_nam);\n";
	} else {
		print JSFILE $gdp;
		print JSFILE $JS; # The large frontend Javascript
	}
	close(JSFILE);
	$query_h->finish;
	return 0;
}

sub create_js_cc {
	my $query = "SELECT DISTINCT country_code FROM $table";
	my $query_h = $dbh->prepare($query);
	$query_h->execute();
	
	if ($query_h->rows == 0) {
		return "No country codes found.\n";
	}
	
	while (my @data = $query_h->fetchrow_array()) {
		# Send the cc to the create_js_cat() function
		my $cc = $data[0];
		#print $cc;
		unlink "js/$cc.js";
		create_js_cat($cc, 1)
	}
	
	return 0;
}

# Check for dead links
sub check_dead_links {
	# A youtube video would 
	my $rem_links = 0;
	if (length($_[0] // '') && $_[0] == 1 ) {
		$rem_links = 1;
	}
	my $query = "SELECT id, link FROM $table";
	my $query_h = $dbh->prepare($query);
	$query_h->execute();
	while (my @data = $query_h->fetchrow_array()) {
		print "$data[0] - $data[1]\n";
	}
	
	#print $rem_links;
}

sub insert_doc {
	my $name = $_[0];
	my $description = $_[1];
	my $query = "INSERT INTO $table VALUES(NULL, 'name3', 'description3', 103, 53, \"'new', 'aaa'\", 'UK', 'http://swiftler.com/3')";
	my $query_h = $dbh->prepare($query);
	$query_h->execute() or die "Error inserting into database: " . $DBI::errstr;
}

#insert_doc();
#create_js_cat();
#create_js_cc();
#create_static_doc();
#check_dead_links(1);

$dbh->disconnect;

