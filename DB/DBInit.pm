package Coboqo::DB::DBInit;

#function:database initialization.
#author:zhaomf
#date:2011-04-08
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
use strict;
use warnings;
use XML::LibXML;
use Coboqo::DB::DBAccess;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

sub new(){
    my $class = shift;
    my $config = shift;
    my $logObj = shift;
    my $where = (caller(0))[3];
    my $self = {
        conf=>$config,
        log=>$logObj,
    };
    bless $self,$class;
    $self->initDatabase();
    return $self;
}

sub initDatabase(){
    my $self = shift;
    my $where = (caller(0))[3];
    my $config_file = $self->{conf};
    my $tree = parseXML($config_file);
    my $doc = $tree->getDocumentElement();
    return undef unless $doc;
    $self->{doc} = $doc;

    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
    $year = $year + 1900;
    $mon  = $mon + 1; # Months 0-11
    my $date = sprintf("%04d%02d%02d", $year, $mon, $mday);
 
    #Init Database
    my @dbnodes = $doc->findnodes("global/database");
    $self->{dbObj} = new Coboqo::DB::DBAccess($dbnodes[0], $self->{log});
    $self->{dbh} = $self->{dbObj}->getHandler();
  
    if (!defined ($self->{dbh})) {
        $self->{log}->{logger}->error("$where : Cannot Connect to Database; Please check the connection setting");
        return undef;
    }
}

sub parseXML{
  my ($file) = @_;
  my $parser = XML::LibXML->new();
  my $doc = $parser->parse_file($file);
  
  return $doc;
}


1;
