package Coboqo::Divide::DivideChineseWebContentString;

#funciton: divide chinese web raw text and return one array.
#author: zhaomf
#date: 2011-04-08
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
use strict;
use warnings;
use Coboqo::Divide::DivideChineseString;



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
    my $self = shift;
    my $string = shift;
    my $divide = new Coboqo::Divide::DivideChineseString($self->{db},$self->{log});
    $self->{log}->{logger}->info("before: $string");
    my $chinese = "[\x80-\xff]{2,}";
    my $chinese_punc = "[\xa1\xa3][\xa1-\xa4\xa8\xa9\xac\xae\xaf\xb0\xb2\xb1\xb6\xb7\xba\xbb\xbe\xbf]";
    #my $chinese_punc ="[[\xa1][\xa1-\xfe]|[\xa2][\xa1-\xaa]|[\xa2][\xb1-\xfc]|[\xa3][\xa1-\xfe]|[\xa4][\xa1-\xf4]|[\xa5][\xa1-\xf6]|[\xa6][\xa1-\xb8\xc1-\xd8]|[\xa6][\xe0-\xeb\xee-\xf2\xf4\xf5]|[\xa8][\x40-\x7e\x80-\x95]|[\xa8][\xa1-\xc0\xc5-\xe9]|[\xa9][\x40-\x57\x5a-\x5c\x60-\x96\xa4-\xf4]]";
    my $english_punc = "[[:punct:]]";
    $string =~ s/${chinese_punc}//g;
    $self->{log}->{logger}->info("delete chinese_punc: $string");
    $string =~ s/${english_punc}//g;
    $self->{log}->{logger}->info("delete english_punc: $string");
    my $str = $string;
    #while($string =~ /(${chinese})/g){
    #    $string = $';
    #}
    #$self->{log}->{logger}->info("match chinese: $string");
    
    my @words;
    while($str=~ /(${chinese})/g){
        $self->{log}->{logger}->info("get arry@ via match chinese: $1");
        my @res = $divide->execute($1);
        @words =(@words,@res);
        $str = $';
    }
    return @words;
}

1;
