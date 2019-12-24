#!/usr/bin/perl -w
#name: coboqo search engine crawler.
#author: zhaomf
#date: 2010-11-23
#modify: 2011-06-03
#version: 0.0.0.4
#copyright (c) 2010-2011 coboqo all rights reserved.

use lib "C:/Documents and Settings/zhaomf/Desktop";
use Coboqo::DB::DBInit;
use Coboqo::LogInit::LogInit;
use DBI qw(:sql_types);
use strict;
use LWP;


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


my $browse = LWP::UserAgent->new();

#internet entrance.
my $url = "http://www.hao123.com";
#raw html files dir.
my $dir = "C:/Documents and Settings/zhaomf/Desktop/Coboqo/html/raw";
# each dir contains $num web data file.
my $num = 1000;

my $web_num;
my $web_dir;
my @uniq_url;

if(-e "$dir/uniq_url_temp.txt"){
    open(D,"$dir/uniq_url_temp.txt");
    my $last_url = <D>;
    chomp($last_url);
    close(D);
    
    open(DD,"$dir/web_dir.txt");
    my $web_dir_temp = <DD>;
    chomp($web_dir_temp);
    my @b = split(/\t/,$web_dir_temp);
    $web_dir = $b[0];
    $web_num = $b[1];
    close(DD);

    my @url_last;
    my $i = 0;
    my $id;
    open(DDD,"$dir/uniq_url.txt");
    while(<DDD>){
	chomp($_);
	$url_last[$i] = $_;
	if ($_ eq $last_url){
	     $id = $i;
	}
    $i++;
    }
    close(DDD);
    my @aa = @url_last[$id+1..$i-1];

    my $j=0;
    my @temp;
    open(DDDD,"$dir/temp.txt");
    while(<DDDD>){
	chomp($_);
	$temp[$j] = $_;
	$j++;
    }
    close(DDDD);

    my @aaa = (@aa,@temp);
    my %count;
    @uniq_url = grep {++$count{$_} < 2;} @aaa;
}else{
    $web_num = 0;
    $web_dir = &mkdir();
    @uniq_url=&coboqo($url);
}

while(1){
    open(G,">$dir/uniq_url.txt");
    foreach(@uniq_url){
	print G "$_\n";
    }
    close(G);
    my @uniq_url_temp = @uniq_url;
    my @temp=();
    foreach(@uniq_url_temp){
       next if $_ =~ /(?:cache\.baidu\.com)|(?:www\.douban\.com\/recommend\/\?url\=http\%3A\%2F\%2Fwww\.lashou\.com)
			|(?:share\.renren\.com\/share\/buttonshare\.do\?link\=http\%3A\%2F\%2Fw)
			|(?:v\.t\.sina\.com\.cn\/share\/share\.php\?appkey\=54350967\&url\=http)
			|(?:www\.kaixin001\.com\/repaste\/share\.php\?rurl\=http)
		       |(?:\.exe
                       |\.jpe?g
                       |\.ico
                       |\.png
                       |\.mp[34]
                       |\.docx?
                       |\.txt
                       |\.rar
                       |\.zip
                       |\.pdf
                       |\.xlsx?
                       |\.pptx?
                       |\.vob
                       |\.rmvb
                       |\.wav
                      )$
                     /x;
       @temp= (@temp,&coboqo($_));
       open(GG,">$dir/temp.txt");
       foreach(@temp){
	    print GG "$_\n";
	}
	close(GG);
	
	open(GGG,">$dir/uniq_url_temp.txt");
	print GGG "$_\n";
	close(GGG);
	
    	open(GGGG,">$dir/web_dir.txt");
	print GGGG "$web_dir\t$web_num\n";
	close(GGGG);
    };
    @uniq_url=@temp;
    exit(1) if (@uniq_url == 0);
}

sub coboqo(){
    my ($url) = @_;
    my $response = $browse->get($url);
    my $result = $response->content;
    my $id;
    if(judge_id_from_url($url) eq "N"){
	$id = &randId(64);
	while(judge_id_in_db($id) eq "Y"){
	    $id = &randId(64);
	}
	&url_to_db($id,$url,1);
    }else{
	$id = judge_id_from_url($url);
	&update_tag($id,1)
    }
    
    open (HTML,">$dir/$web_dir/$id.raw");
    open (URL,">$dir/$web_dir/$id.addr");
    $web_num++;
    if($web_num == $num){
	$web_dir=&mkdir();
	$web_num=0;
    }
    print HTML $result;
    close(HTML);
    print URL $url;
    close(URL);

    my @url_ref = &web_fenxi($url,$result);
    foreach(@url_ref){
	my $id_ref = &randId(64);
	while(judge_id_in_db($id_ref ) eq "Y"){
	    $id_ref = &randId(64);
	}
	&url_to_db($id_ref,$_,0);
	&url_ref_url($id_ref);
    }
    return @url_ref;
}

sub randId(){
    my ($maxLenth) = @_;
    my @a = (0..9,'a'..'z','A'..'Z');
    my  $id = join '', map { $a[int rand @a] } 0..($maxLenth-1);
    return $id;
}

sub mkdir(){
    my $id = &randId(32);
    while(-e "$dir/$id"){
        $id = &randId(32);
    }
    `mkdir "$dir/RAW_$id"`;
    return "RAW_$id";
}


sub web_fenxi(){
    my ($url,$result) = @_;
    #delete any comment about html.
    $result =~ s/<\!\-\-.*?\-\->//sg;
    $result =~ s/\/\*.*?\*\///sg;
    $result =~ s/\s+//g;
    $result =~ s/></>\n</g;
    my @url;
    my $i=0;
    while($result =~ /<ahref="(http.*?)\/{0,1}".*?>(.*?)<\/a>/ig){
        $url[$i]=$1;
        $i++;
    }
    my %count;
    my @uniq_url = grep {++$count{$_} < 2;} @url;
    return @uniq_url;
}

sub judge_id_in_db(){
    my ($id) = @_;
    my @res=$dbObj->{dbObj}->select("select 1 from url_id where id='$id'");
    if(! @res){
	return "N";
    }else{
	return "Y";
    }
}

sub judge_id_from_url(){
    my ($url) = @_;
    my $sql = "select id from url_id where url=?";
    my $cursor = $dbObj->{dbh}->prepare($sql);
    $cursor->bind_param(1, $url, SQL_VARCHAR);
    $cursor->execute();
    my @row_arr=$cursor->fetchrow_array();
    $cursor->finish;
    if(! @row_arr){
	return "N";
    }else{
	return $row_arr[0];
    }
}

sub url_to_db(){
    my ($id,$url,$tag) = @_;
    
    
    
    my $sql = "insert into url_id(id,url,tag) values(?,?,?)";
    my $cursor = $dbObj->{dbh}->prepare($sql);
    $cursor->bind_param(1, $id, SQL_VARCHAR);
    $cursor->bind_param(2, $url, SQL_VARCHAR);
    $cursor->bind_param(3, $tag);
    $cursor->execute();
    $cursor->finish;
}

sub update_tag(){
    my ($id,$tag) = @_;
    my $sth=$dbObj->{dbObj}->update("update url_id set tag='$tag' where id='$id'");
    if(! defined($sth)){
	$logObj->{logger}->info("Update error.");
    }
}

sub url_ref_url(){
    my ($id_ref) = @_;
    my @res=$dbObj->{dbObj}->select("select ref_num from url_ref where id='$id_ref'");
    if(! @res){
	my $sth=$dbObj->{dbObj}->insert("insert into url_ref(id,ref_num) values('$id_ref','1')");
	if(! defined($sth)){
	    $logObj->{logger}->info("Insert error.");
	}
    }else{
	my $ref_num = $res[0];
	print  $ref_num;
	$ref_num++;
	print  $ref_num;
	my $sth=$dbObj->{dbObj}->update("update url_ref set ref_num='$ref_num' where id='$id_ref'");
	if(! defined($sth)){
	    $logObj->{logger}->info("Update error.");
	}
    }
}
