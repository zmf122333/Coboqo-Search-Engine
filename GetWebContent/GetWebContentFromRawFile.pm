package Coboqo::GetWebContent::GetWebContentFromRawFile;

#funciton: get web raw text from html raw file.
#author: zhaomf
#date: 2011-04-08
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
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
        log=>$logObj,
    };
    bless $self,$class;
    return $self;
}

sub getContent(){
    my $self = shift;
    my $file = shift;
    #delete any comment about html.
    $file =~ s/<\!\-\-.*?\-\->//sg;
    $file =~ s/\/\*.*?\*\///sg;
    #$file =~ s/>\s+</></g;
    $file =~ s/<script.*?<\/script>/<script>/gs;
    $file =~ /<head>(.*?)<\/head>/s;
    
   # print $file;
   # exit;
    
    
    $file =~ s/\s+//g;
    my $title;
    if($file =~ /<title>(.*?)<\/title>/ig){
       $title =  $1;
    }
    my $keywords;
    if($file =~ /<metaname="keywords"content="(.*?)"\/?>/ig){
       $keywords =  $1;
    }
    my $description;
    if($file =~ /<metaname="description"content="(.*?)"\/?>/ig){
       $description =  $1;
    }
    $file =~ s/^.*<body>//g;
    # delete javascript tag.
    $file =~ s/<script.*?<\/script>//ig;
    #delete css style tag.
    $file =~ s/<style.*?<\/style>//ig;
    #delete MVC related modle tag(python/perl/ruby).
    $file =~ s/\{{1,2}.*?\}{1,2}//g;
    #delete url-link html tag.
    $file =~ s/<a.*?<\/a>//g;
    my $result;
    #get <b|p|span> content.
    while($file =~ /<[b|p|span].*?>(.*?)<\/[b|p|span]>/g){
        my $i = $1;
        $i  =~ s/<\/{0,1}.*?>//g;
        $i =~ s/\s+//g;
        $result .= $i;
    };
    my $content = {
        title=>$title,
        result=>$result,
        keywords=>$keywords,
        description=>$description,
    };
    return $content;
}


1;
