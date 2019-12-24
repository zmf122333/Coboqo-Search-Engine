package Coboqo::LogInit::LogInit;

#function:log initialization.
#author:zhaomf
#date:2011-04-11
#version: 0.0.0.1
#copyright (c) 2010-2011 coboqo all rights reserved.

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Log::Log4perl qw(:levels);
use Log::Log4perl::Level;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

sub new(){
    my $class = shift;
    my $config = shift;
    my $where = (caller(0))[3];
    my $self = bless{conf=>$config}, $class;
    $self->initLog();
    bless $self,$class;
    return $self;
}

sub initLog(){
    my $self = shift;
    my $where = (caller(0))[3];
    my $config_file = $self->{conf};
    my $tree = parseXML($config_file);
    my $doc = $tree->getDocumentElement();
    return undef unless $doc;
    my @logger = $doc->findnodes("global/logger");
    my $log_conf = $logger[0]->findvalue("log_conf");
    my $log_class = $logger[0]->findvalue("log_class");
    my $log_level = $logger[0]->findvalue("log_level");
    my $rDays = $logger[0]->findvalue("log_retention");
    if (!defined ($rDays) ||  $rDays eq '') {
        $rDays = 5;
    }

    Log::Log4perl->init("$log_conf");

    $self->{logger}= Log::Log4perl->get_logger($log_class);

    if ($log_level eq "DEBUG") { 
        $self->{logger}->level($DEBUG); 
    }
    elsif ($log_level eq "INFO") { 
        $self->{logger}->level($INFO); 
    }
    elsif ($log_level eq "WARN") { 
         $self->{logger}->level($WARN);
    }
    elsif ($log_level eq "ERROR") {
         $self->{logger}->level($ERROR); 
    }
    elsif ($log_level eq "FATAL") { 
         $self->{logger}->level($FATAL); 
    }
    else {
         $self->{logger}->level($INFO);
    }
}

sub parseXML{
  my ($file) = @_;
  my $parser = XML::LibXML->new();
  my $doc = $parser->parse_file($file);
  return $doc;
}

sub getLogFileName(){
    my $log_dir = "C:/Documents and Settings/zhaomf/Desktop/Coboqo/log";
    my $seqStr = `ls -1 "$log_dir" | tail -1`;
    chomp($seqStr);
    my $seq;

    if ($seqStr =~  m/.*_(.*)\./) {
        $seq = $1;
    }
 
    if (defined($seq)) {
        $seq++;
    }
    else {
        $seq = '000';
    }

    my $logfile = "$log_dir"."/coboqo_".$seq.".log";
    return "$logfile";
}


1;
