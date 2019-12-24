#!/usr/bin/perl -w
#author:zhaomf
#date:2011-03-28
#modify:2011-06-02
#version: 0.0.0.3
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
use Coboqo::WebToDB::WebToDB;
use Coboqo::UTF8Check::UTF8Check;
use Coboqo::LogInit::LogInit;
use Coboqo::DB::DBInit;
use strict;
use Encode;

#raw html files dir.
my $dir = "C:/Documents and Settings/zhaomf/Desktop/Coboqo/html/raw";
#done html files dir.
my $dir_done = "C:/Documents and Settings/zhaomf/Desktop/Coboqo/html/done";
#coboqo config file.
my $config_file = "C:/Documents and Settings/zhaomf/Desktop/Coboqo/conf/coboqo.xml";

#Log Init...
my $logObj = new Coboqo::LogInit::LogInit($config_file);
$logObj->{logger}->info("Log init OK...") if defined($logObj);
#Database Init...
my $dbObj = new Coboqo::DB::DBInit($config_file,$logObj);
if( defined($dbObj->{dbh})){
    $logObj->{logger}->info("DB init OK...");
}else{
    $logObj->{logger}->info("DB init FAIL...");
    exit 1;
}


my $web_dir = &getOldestDir();

while(1){
    &execute();
}


sub execute(){
    my $fileName = &getOldestRawWeb();
    if (length($fileName)==0){
        `rm -fr "$dir/$web_dir"`;
        $web_dir = &getOldestDir();
        $fileName = &getOldestRawWeb();
    }
    my ($urlId,$url) = &getUrl($fileName);
    $fileName="$dir/$web_dir/$fileName";
    open(F,"$fileName");
    my $result;
    while(<F>){
        $result .=$_;
    }
    close(F);

    #Check charset...
    $logObj->{logger}->info("Check whether html raw file charset is utf8 or not...");
    my $utf8Obj = new Coboqo::UTF8Check::UTF8Check;
    if ($utf8Obj->utf8Check($result) == 1){
        $logObj->{logger}->info("Charset is NOT utf8...");
    }else{
        $logObj->{logger}->info("Char_set is utf8...");
        my $result_t = encode("gb2312",decode("utf8",$result));
        $result = $result_t;
        $logObj->{logger}->info("Char_set is converted to gb2312...");
    }
    
    my $webToDBObj =new Coboqo::WebToDB::WebToDB($result,$urlId,$url,$dbObj,$logObj);
    $webToDBObj->getWeb();
    $logObj->{logger}->info("Text of web is got from raw html file...");
    $webToDBObj->webToDB();
    $logObj->{logger}->info("Web content is loaded to DB...");

    &postWork($fileName,$urlId);
    $logObj->{logger}->info("Raw file name is changed .done...");
}


sub getOldestRawWeb(){
    my $fileName = `ls -1 -tr --ignore='*addr' --ignore='*done' "$dir/$web_dir" | head -1`;
    chomp($fileName);
    if(! defined($fileName)){
        $logObj->{logger}->info("Can not get Oldest Raw Web file, please check...");
        exit 1;
    }
    return $fileName;
}

sub getOldestDir(){
    my $web_dir = `ls -1 -tr --ignore='*txt' "$dir" | head -1`;
    chomp($web_dir);
    if(! defined($web_dir)){
        $logObj->{logger}->info("Can not get Oldest Web Dir, please check...");
        exit 1;
    }
    return $web_dir;
}

sub getUrl(){
    my ($file) = @_;
    $file =~ /^(.*)\.raw/;
    if(! defined($1)){
        $logObj->{logger}->info("Can not get ulrId, please check...");
        exit 1;
    }
    my $urlId = $1;
    my $url;
    open(U,"$dir/$web_dir/$urlId.addr");
    $url = <U>;
    chomp($url);
    close(U);
    return $urlId,$url;
}

sub postWork(){
     my ($fileName,$urlId) = @_;
     `mkdir "$dir_done/DONE_$web_dir"` unless(-e "$dir_done/DONE_$web_dir");
    `mv "$fileName" "$dir_done/DONE_$web_dir/$urlId.done"`;
    `mv "$dir/$web_dir/$urlId.addr" "$dir_done/DONE_$web_dir/$urlId.addr"`;
}
