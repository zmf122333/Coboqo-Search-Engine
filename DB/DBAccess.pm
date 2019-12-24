package Coboqo::DB::DBAccess;

#function:database access interface.
#author:zhaomf
#date:2011-04-08
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();


use DBI qw(:sql_types);
use Data::Dumper;
use XML::LibXML;
#use utf8;

my $dbh = undef;

sub DESTROY {
    my $self = shift;
    if ($dbh) {
      $dbh->disconnect;
    }
    $dbh = undef;
}     
     
sub new {
  my ($class, $xmlnode, $logObj) = @_;
  my $self = bless{}, $class;

  $self->{logger}   = $logObj->{logger};

  #DB Params
  $self->{db}       = $xmlnode->findvalue("db_type");
  $self->{username} = $xmlnode->findvalue("db_user");
  $self->{password} = $xmlnode->findvalue("db_password");
  $self->{dbname}   = $xmlnode->findvalue("db_name");
  $self->{host}     = $xmlnode->findvalue("db_host");
  $self->{dbRetry}  = $xmlnode->findvalue("db_retry");
  $self->{rSleep}   = $xmlnode->findvalue("db_sleep");

  
  if (!defined ($self->{dbRetry}) || $self->{dbRetry} eq '') { 
      $self->{dbRetry} = 3;
  }

  if (!defined ($self->{rSleep}) || $self->{rSleep} eq '') { 
      $self->{rSleep} = 5;
  }

  $self->retryConnect();
  my $dumpInfo = Dumper($self);
  $self->{logger}->debug("DB  Dumper $dumpInfo");
  $self->{logger}->info("Initialized the DB Obj");
  return $self;
  
}


sub retryConnect {
    my $self = shift @_;
    my $retry = $self->{dbRetry};
    while (--$retry) {
        if ($self->connect() == 0) {
            last;
        } 
        $self->{logger}->error("Unable to Connect to DB; retrying ... ");
        sleep ($self->{rSleep});
    }
}

sub disconnect
{
    my $self = shift;
    $dbh->disconnect;
     
    if($DBI::err) {
        $self->{logger}->error("Failed to disconnect to DB.  $DBI::errstr");
        return 1;
     }
     $dbh = undef;
     $self->{logger}->info("DB disconnection successful.");
     return 0;
}

sub connect
{
    my ($self) = @_;
    my $retCode = 1; 
    eval {
        if($self->{db} eq "oracle"){
            $dbh = DBI->connect("dbi:Oracle:$self->{dbname}", $self->{username}, $self->{password}, {PrintError => 0, RaiseError => 1, AutoCommit => 1});
        }elsif($self->{db} eq "mysql"){
            $dbh = DBI->connect("dbi:mysql:database=$self->{dbname};host=$self->{host}", $self->{username}, $self->{password}, {PrintError => 0, RaiseError => 1, AutoCommit => 1});
        }
        $self->{logger}->info("DB Connection Succesfull");
        $retCode = 0;
    };
    if ($@) {
        $self->{logger}->error("Execption Thrown : $@");
    }
    return $retCode;
}

sub getDBParams
{
    my $self = shift;
    my $dbParams = {};
    $dbParams->{dbUser} = $self->{username};
    $dbParams->{dbPass} = $self->{password};
    $dbParams->{dbSid} = $self->{host};
    return $dbParams; 
}

sub getDBUser
{
    my $self = shift;
    return $self->{username};
}

sub getDBPassword
{
    my $self = shift;
    return $self->{password};
}

sub getDBSid
{
    my $self = shift;
    return $self->{host};
}

sub getHandler()
{
  my ($self) = @_;
  return $dbh;
}

sub select
{
  my ($self, $stmt) = @_;
  return $self->_dqf($stmt);
}

sub insert
{
  my ($self, $stmt) = @_;
  return $self->_dmf($stmt);
}

sub update
{
  my ($self, $stmt) = @_;
  return $self->_update($stmt);
}

sub delete
{
  my ($self, $stmt) = @_;
  return $self->_dmf($stmt);
}

sub truncate
{
  my ($self, $stmt) = @_;
  return $self->_truncate($stmt);
}

sub _truncate
{
  my ($self, $stmt) = @_;
  $self->{logger}->debug("stmt <$stmt>.");
  $self->connect() if(!$dbh);
  
  my $sth = $dbh->prepare($stmt);
  if($DBI::err) {
    $self->{logger}->fatal("prepare failed.  $DBI::errstr");
    return $DBI::err;
  }

  $sth->execute();
  if($DBI::err) {
    $self->{logger}->fatal("execute failed.  $DBI::errstr");
    return $DBI::err;
  }

  $sth->finish();
  if($DBI::err) {
    $self->{logger}->fatal("execute failed.  $DBI::errstr");
    return $DBI::err;
  }

  return 0; 
}

sub _update
{
  my ($self, $stmt) = @_;
  $self->{logger}->debug("stmt <$stmt>.");
  $self->connect() if(!$dbh);

  my $rows_modified = $dbh->do($stmt);  

  if ((!defined($rows_modified)) || $rows_modified == -1 ) {
    $self->{logger}->fatal("Do Failed.  $DBI::errstr rows_modified= $rows_modified");
    return -1; 
  }

  if ($rows_modified eq '0E0') {
      $rows_modified = 0;
  }

  $self->{logger}->debug("executed successfully.");
  return $rows_modified;
  
}

sub _dqf 
{
  my ($self, $stmt) = @_;
  my @recs = ();

  $self->{logger}->debug("stmt <$stmt>.");
   
  $self->connect() if(!$dbh);
  my $sth = $dbh->prepare($stmt);

  if($DBI::err) {
    $self->{logger}->fatal("prepare failed.  $DBI::errstr");
    #$self->{logger}->info("prepare failed.  $DBI::errstr");
    return $DBI::err;
  }

  $sth->execute();

  if($DBI::err) {
    $self->{logger}->fatal("execute failed.  $DBI::errstr");
    #$self->{logger}->info("execute failed.  $DBI::errstr");
    return $DBI::err;
  }

  while(my (@row_arr) = $sth->fetchrow_array()) {
    push @recs, \@row_arr;
  }
  $sth->finish();

  $self->{logger}->debug("executed successfully.");
  #return (0, \@recs);
  #foreach(@recs){
  #  print "$$_[0]\n";
  #}
  return @recs;
}

sub _dmf
{
  my ($self, $stmt) = @_;

  $self->{logger}->debug("stmt <$stmt>.");

  $self->connect() if(!$dbh);

  my $sth = $dbh->prepare($stmt);

  if($DBI::err) {
    $self->{logger}->fatal("prepare failed.  $DBI::errstr");
    return $DBI::err;
  }

  $sth->execute();

  if($DBI::err) {
    $self->{logger}->fatal("execute failed.  $DBI::errstr");
    return $DBI::err;
  }

  $self->{logger}->debug("executed successfully.");

  return 0;
}

sub init_logger
{
  my ($self) = @_;

  Log::Log4perl->init(\$self->{log_str});
  my $logger = get_logger();

  return $logger;
}

sub trim
{
  my ($self, $str) = @_;

  $str =~ s/^\s+//;
  $str =~ s/\s+$//;

  return $str;
}


1;
