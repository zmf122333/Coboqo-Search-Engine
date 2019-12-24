package Coboqo::UTF8Check::UTF8Check;

#function:check one string's charset.
#author:zhaomf
#date:2011-04-11
#version: 0.0.0.1
#copyright (c) 2010-2011 coboqo all rights reserved.

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

sub new(){
    my $class = shift;
    my $rawfile = shift;
    my $where = (caller(0))[3];
    my $self = {};
    bless $self,$class || $class;
    return $self;
}

sub utf8Check()
{
        my ($self,$txt)=@_;
        my $ii=0;
        my $len=length($txt)-1;
        while (ord(substr($txt,$ii,1))<128 && $ii<=$len)
        {
            $ii++;
        }
        if ($ii==$len) {return 0;}
        #yes.
        if (ord(substr($txt,$ii,1))>0xE0) {return 0;}
        #no.
        return 1;
}

1;
