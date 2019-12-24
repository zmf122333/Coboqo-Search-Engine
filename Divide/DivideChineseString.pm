package Coboqo::Divide::DivideChineseString;

#function:divide chinese character string.
#author:zhaomf
#date:2011-03-26
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

sub new(){
    my $class = shift;
    my $dbObj = shift;
    my $logObj = shift;
    my $where = (caller(0))[3];
    my $self = {
        db=>$dbObj,
        log=>$logObj,
    };
    bless $self,$class;
    return $self;
}

sub execute(){
    my ($self,$string) = @_;  
    #input chinese character string.
    my $rawString = $string;
    #$self->{logger}->info($rawString);
    my $maxLenOfTerm = $self->getMaxLenOfTerm();
    my @res;
    my $maxLenOfTerm_ = $maxLenOfTerm;
    while(1){
        my $subString = $self->getSubString($rawString,$maxLenOfTerm);
        #$self->{logger}->info($subString);
        my $matchTag = $self->match($subString);
        if (! defined($matchTag)){
             $maxLenOfTerm--;
              $subString = $self->getSubString($rawString,$maxLenOfTerm);
             if(length($subString)==2){
                 $self->insertCikuNew($subString);
                 push(@res,$subString);
                $rawString = $self->getSubRawString($rawString,$maxLenOfTerm);
                $maxLenOfTerm = $maxLenOfTerm_;
                if(length($rawString)/2 < $maxLenOfTerm_){
                $maxLenOfTerm = length($rawString)/2;
              }
            }
        }
         if(defined($matchTag)){
             push(@res,$subString);
             $rawString = $self->getSubRawString($rawString,$maxLenOfTerm);
             $maxLenOfTerm = $maxLenOfTerm_;
             if(length($rawString)/2 < $maxLenOfTerm_){
                 $maxLenOfTerm = length($rawString)/2;
            }
        }
         
        if(length($rawString) <= 2 ){
            push(@res,$rawString) if(length($rawString) == 2);
            last;
        }  
        if(length($subString) == 0 ){
            last;
        }
    }
    return @res;
}

sub getSubString(){
    my ($self,$string,$len) = @_;
    #$self->{logger}->info($string);
    if (length($string)/2 <= $len){
        return $string;
    }
    $len = $len*2;
    if ($string =~ /^([\x80-\xff]{${len}})/){
        return $1;
    }
}

sub getSubRawString(){
    my ($self,$string,$len) = @_;
    $len = $len*2;
    if ($string =~ /^[\x80-\xff]{${len}}(.*$)/){
        return $1;
    }
}

sub match(){
    my ($self,$sub) = @_;
    my $matchTag = $self->dbMatch($sub);
    return $matchTag;  
}

sub dbMatch(){
    my ($self,$sub) = @_;
    #$self->{log}->{logger}->info("select 1 from ciku where term='$sub'");
    my @res=$self->{db}->{dbObj}->select("select 1 from ciku where term='$sub'");
     #$self->{logger}->debug("dbMatch is $res[0]");
    return $res[0];
}

sub getMaxLenOfTerm(){
    my $self = shift;
    #$self->{log}->{logger}->info("select length from (select length(term) length from ciku order by length(term) desc) where rownum=1");
    my @res=$self->{db}->{dbObj}->select("select length from (select length(term) length from ciku order by length(term) desc) where rownum=1"); 
    #$self->{logger}->debug("getMaxLenOfTerm is $res[0][0]");
    return $res[0][0];
    
}

sub insertCikuNew(){
    my ($self,$word) = @_;
    #$self->{log}->{logger}->info("select 1 from ciku_new where term='$word'");
    my @res=$self->{db}->{dbObj}->select("select 1 from ciku_new where term='$word'");
    if(! defined($res[0])){
        #$self->{log}->{logger}->info("insert into ciku_new values('$word')");
        my $sth=$self->{db}->{dbObj}->insert("insert into ciku_new values('$word')");
        return $sth;
    }   
}

1;