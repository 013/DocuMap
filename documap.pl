#!/usr/bin/perl -w
# 12/04/13
use DBI;
use DBD::mysql;

use warnings;
use strict;

my $database	= "documap";
my $host		= "localhost";
my $port		= "3306";
my $user		= "username";
my $pass		= "password";
my $tbl_struct	= "
CREATE TABLE IF NOT EXISTS docu_tbl (
id				MEDIUMINT NOT NULL AUTO_INCREMENT,
name			VARCHAR(40) NOT NULL,
description		VARCHAR(300),
lat				FLOAT,
lng				FLOAT,
category		VARCHAR(120),
country_code	VARCHAR(5),	
link			VARCHAR(120),

PRIMARY KEY		(id)
);
";

# Connect to DB
my $dbh = DBI->connect("DBI:mysql:$database:localhost:$port", $user, $pass)
	or die "Error connecting to MySQL Database:" . $DBI::errstr;

# Test a query
my $query = "SELECT id FROM docu_tbl";
my $query_h = $dbh->prepare($query);

$query_h->execute()
	or die "Error quering database: " . $DBI::errstr;

sub create_static_doc {
	my $query = "SELECT DISTINCT category FROM $table";
	my $query_h = $dbh->prepare($query);


}
