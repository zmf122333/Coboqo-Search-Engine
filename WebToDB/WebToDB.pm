package Coboqo::WebToDB::WebToDB;

#function:load web all data to database.
#author:zhaomf
#date:2011-04-08
#version: 0.0.0.2
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
use Coboqo::GetWebContent::GetWebContentFromRawFile;
use Coboqo::Divide::DivideChineseWebContentString;
use Coboqo::GetWebContent::GetKeywordCount;
#use HTML::HeadParser;
use DBI qw(:sql_types);
use strict;
use warnings;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

sub new(){
    my $class = shift;
    my $rawFile = shift;
    my $urlId = shift;
    my $url = shift;
    my $dbObj = shift;
    my $logObj = shift;
    my $where = (caller(0))[3];
    my $self = {
        rawFile=>$rawFile,
        urlId=>$urlId,
        url=>$url,
        log=>$logObj,
        db=>$dbObj,
    };
    bless $self,$class;
    return $self;
}

sub getWeb(){
    my $self = shift;
eval{
    #my $p = HTML::HeadParser->new;
    my $text =$self->{rawFile};
    #$p->parse($text) and  print "not finished";
    #my $urlTitle = $p->header('title');

    $self->{log}->{logger}->info("urlId: $self->{urlId}");
    $self->{log}->{logger}->info("url: $self->{url}");
    #get web content from raw file.
    my $webContentObj = new Coboqo::GetWebContent::GetWebContentFromRawFile($self->{log});
    my $webcontent = $webContentObj->getContent($text);
    $self->{urlTitle} = $webcontent->{'title'} || "";
    $self->{content} = $webcontent->{'result'} || "";
    $self->{keywords} = $webcontent->{'keywords'} || "";
    $self->{description} = $webcontent->{'description'} || "";
    $self->{log}->{logger}->info("title: $self->{urlTitle}");
    $self->{log}->{logger}->info("content: $self->{content}");
    $self->{log}->{logger}->info("keywords: $self->{keywords}");
    $self->{log}->{logger}->info("description: $self->{description}");
    $self->{log}->{logger}->info("Get web content from raw file OK.");
    if ($self->{url} !~ /http:\/\/(.*)(\/.*)+/){
        if( length($self->{description}) != 0){
            $self->{content} = $webcontent->{'description'};
        }elsif(length($self->{keywords}) != 0){
            $self->{content} = $webcontent->{'keywords'};
        }else{
            $self->{content} = $webcontent->{'content'};
        }
        $self->{log}->{logger}->info("showContent: $self->{content}");
    }

    #divide chinese string.
    my $divideObj = new Coboqo::Divide::DivideChineseWebContentString($self->{db},$self->{log});
    my @wordsTitle = $divideObj->execute($self->{urlTitle}) if (length($self->{urlTitle}) != 0);
    my @wordsContent = $divideObj->execute($self->{content}) if (length($self->{content}) != 0);
    $self->{log}->{logger}->info("Got one arry@ after dividing chinese string OK.");
    #count keywords of chinese string.
    my $keywordCountObj = new Coboqo::GetWebContent::GetKeywordCount($self->{log});
    my %keywordCountTitle = $keywordCountObj->keywordCount(\@wordsTitle) if (length($self->{urlTitle}) != 0);
    my %keywordCountContent = $keywordCountObj->keywordCount(\@wordsContent) if (length($self->{content}) != 0);
    $self->{log}->{logger}->info("Got one hash% after counting keywords of chinese string. OK.");
    $self->{keywordCountTitle} = \%keywordCountTitle if (length($self->{urlTitle}) != 0);
    $self->{keywordCountContent} = \%keywordCountContent if (length($self->{content}) != 0);;
 };
 if($@){
    $self->{log}->{logger}->info("Execption Thrown : $@");
 }
}


sub webToDB(){
    my $self = shift;
eval {
    if(length($self->{content}) > 4000){
        print "web content length > 4000 bytes\n";
        #first insert.
        my $sth=$self->{db}->{dbObj}->insert("insert into url values('$self->{urlId}','$self->{urlTitle}','\$self->{content}')");
        if(! defined($sth)){
            $self->{log}->{logger}->info("Insert error.");
            #print "insert error!!!";
        }
        #then update.
        my $sql = "begin update_url_clob(?,?); end;";
        my $cursor = $self->{db}->{dbh}->prepare($sql);
        $cursor->bind_param(1, $self->{content}, SQL_VARCHAR);
        $cursor->bind_param(2, $self->{urlId}, SQL_VARCHAR);
        $cursor->execute();
        $cursor->finish;
        $self->{log}->{logger}->info("web content length > 4000 bytes Insert DB ok.");
    }else{
        my $sth=$self->{db}->{dbObj}->insert("insert into url values('$self->{urlId}','$self->{urlTitle}','$self->{content}')");
        if(! defined($sth)){
        $self->{log}->{logger}->info("Insert error.");
        #print "insert error!!!";
        }
    }

    my $keywordCountTitle = $self->{keywordCountTitle};
    my $keywordCountContent = $self->{keywordCountContent};
    foreach(keys(%$keywordCountTitle)){
        my $sth=$self->{db}->{dbObj}->select("select 1 from reverse_index where keyword='$_' and urlid='$self->{urlId}'");
        if(! defined($sth)){
            my $sth=$self->{db}->{dbObj}->insert("insert into reverse_index(keyword,urlid,show_num1) values('$_','$self->{urlId}','$$keywordCountTitle{$_}')");
            if(! defined($sth)){
                #print "insert error!!!";
                $self->{log}->{logger}->info("Insert error.");
            }
        }else{
            my $sth=$self->{db}->{dbObj}->update("update reverse_index set show_num1='$$keywordCountTitle{$_}' where keyword='$_' and urlid='$self->{urlId}'");
            if(! defined($sth)){
                #print "update error!!!";
                $self->{log}->{logger}->info("Update error.");
            }
        }
    };
    foreach(keys(%$keywordCountContent)){
        my $sth=$self->{db}->{dbObj}->select("select 1 from reverse_index where keyword='$_' and urlid='$self->{urlId}'");
        if(! defined($sth)){
            my $sth=$self->{db}->{dbObj}->insert("insert into reverse_index(keyword,urlid,show_num2) values('$_','$self->{urlId}','$$keywordCountContent{$_}')");
            if(! defined($sth)){
            #print "insert error!!!";
            $self->{log}->{logger}->info("Insert error.");
            }
        }else{
            my $sth=$self->{db}->{dbObj}->update("update reverse_index set show_num2='$$keywordCountContent{$_}' where keyword='$_' and urlid='$self->{urlId}'");
            if(! defined($sth)){
                #print "update error!!!";
                $self->{log}->{logger}->info("Update error.");
            }
        }
    };
    
};

if ($@) {
        $self->{log}->{logger}->info("Execption Thrown : $@");
    }
    
}

1;
