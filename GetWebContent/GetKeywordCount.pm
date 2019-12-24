package Coboqo::GetWebContent::GetKeywordCount;

#function:count keywords of chinese string.
#author:zhaomf
#date:2011-04-08
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

sub new(){
    my $class = shift;
    my $logObj = shift;
    my $where = (caller(0))[3];
    my $self = {
        log=>$logObj
    };
    bless $self,$class;
    return $self;
}

sub keywordCount(){
    my $self =shift;
    my $words= shift;
    my $i=0;
    my %keywords;
    my @words_=();
    while(1){
        foreach(@$words){
           if ($$words[0] eq $_ ){
                $i++;
           }else{
                @words_ = (@words_,$_);
           }
        }
        $keywords{$$words[0]} = $i;
        $i=0;
        @$words = @words_;
        @words_=();
        last if @$words ==0;
    }
    return %keywords;
}

1;
