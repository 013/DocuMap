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
CREATE TABLE IF NOT EXISTS docu_tbl (
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
# Creates static files:		|
# index.html				|
# js/*.js					|
# --------------------------*
sub create_static_doc {
	if (length{$_[0] // '') {
		my $s_cat = $_[0];
	} else {
		my $query = "SELECT DISTINCT category FROM $table";
		my $query_h = $dbh->prepare($query);
		$query_h->execute();
	
		if ($query_h->rows == 0) {
			return "No documentaries found.\n";
		}
	
		while (my @data = $query_h->fethrow_array()) {
			my $data;
			print $data[0];
		}
	}
	#
	#	Once the categories have be done
	#	Create the index.html
	#
}

sub create_js_cat {
	;# Create each category's JS File
}

# Check for dead links 
sub check_dead_links {
	my $rem_links = 0;
	my $query = "SELECT link FROM $table";
	if (length($_[0] // '') && $_[0] == 1 ) {
		$rem_links = 1;
	}
		
	print $rem_links;
}

#check_dead_links(1);


$dbh->disconnect;
