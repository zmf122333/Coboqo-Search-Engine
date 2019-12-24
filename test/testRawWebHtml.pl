#!/usr/bin/perl -w
use strict;
use lib "C:/Documents and Settings/zhaomf/Desktop";
use Coboqo::UTF8Check::UTF8Check;
use strict;
use Encode;
use Data::Dumper;

#raw html files dir.
my $dir = "C:/Documents and Settings/zhaomf/Desktop/test/coboqo/html/";

&execute;


sub execute(){
    my $fileName = &getOldestRawWeb();
    exit if length($fileName)==0;
    my ($urlId,$url) = &getUrl($fileName);
    $fileName=$dir.$fileName;
    open(F,"$fileName");
    my $result;
    while(<F>){
        $result .=$_;
    }
    close(F);

    #Check charset...
    my $utf8Obj = new Coboqo::UTF8Check::UTF8Check;
    if ($utf8Obj->utf8Check($result) == 1){
        #print "\n\$result is NOT utf8!!!\n";
    }else{
        #print "\$result IS utf8!!!\n";
        my $result_t = encode("gb2312",decode("utf8",$result));
        $result = $result_t;
    }
    &getContent($result);
}



sub getOldestRawWeb(){
    my $fileName = `ls "$dir*.raw" | head -1`;
    $fileName =~ /^.*\/(.*)$/;
    $fileName = $1;
    return $fileName;
}
sub getUrl(){
    my ($file) = @_;
    $file =~ /^(.*)\.raw/;
    my $urlId = $1;
    my $url;
    open(U,$dir.$urlId.".addr");
    $url = <U>;
    chomp($url);
    close(U);
    return $urlId,$url;
}

sub tagStartEnd(){
    my ($tag,@html_tag) = @_;
    my @_tag;
    my $i=0;
    foreach(@html_tag){
        if($_->{tag} =~ /^\/?${tag}$/){
             $_tag[$i] = $_->{tag}.":".$_->{id}.":".$i;
             $i++;
        }
    }
    my @temp;
    my $tag_tag={};
    my $x=0;
    while(1){
        foreach(@_tag){
            if($_ =~ /^\/${tag}/){
                $_ =~ /.*?:(\d+):(\d+)/;
                my $end_tag_id = $1;
                my $sid = $2;
                my $last_tag = $_tag[$sid-1-$x*2];
                $last_tag =~ /.*?:(\d+):(\d+)/;
                my $start_tag_id = $1;
                my $achor = $sid-1-$x*2;
                @temp = (@_tag[0..$achor-1],@_tag[$achor+2..@_tag-1]);
                $tag_tag->{$start_tag_id} = $end_tag_id;
                last;
            }
        }
        my $len = @temp;
        @_tag =  @temp;
        last if ($len == 0);
        $x++;
    }
    return $tag_tag;
  } 


sub getContent(){
    my $file = shift;
    #delete any comment about html.
    #$file =~ s/<\!\-\-.*?\-\->//sg;
    #$file =~ s/\/\*.*?\*\///sg;
    #$file =~ s/>\s+</></g;
    $file =~ s/<script(.*?)>.*?<\/script>/<script$1>/gs;
    my @html_tag;
    my $j = 0;
    my $_attr = {};
    while($file =~ /(<(\/?([a-zA-Z]+?))((\s+(.+?)="(.*?)")*?)(\s*\/*)>)/g){
        my $tag = $2;
        my $attr = $4;   
        if (length($attr) == 0){
        }else{
            $attr =~ s/^(\s+)|(\s+)$//;
            while($attr =~ /([a-zA-Z\-]+?)="(.*?)"/g){
                 my ($attr_name,$value) = ($1,$2);
                 $_attr->{$attr_name} = $value;
            }
        }
         $html_tag[$j] = {
                id => $j,
                tag => $tag,
                attr => $_attr,
            };
        $_attr = {};
        $j++; 
    }
    
    my $dumpInfo = Dumper(@html_tag);
    
    print $dumpInfo;
    exit;

    my @html_tag_temp;
    my $k=0;
    foreach my $p(@html_tag){
        if( $p->{tag} !~ /^\//){
            $html_tag_temp[$k] = $p->{tag};
            $k++;
        }
    }
    my @tag_uniq =sort keys %{ {map {$_ => 1} @html_tag_temp} };
    
    print Dumper(@tag_uniq);
    
    
    foreach(@tag_uniq){
        my $tag_tag = &tagStartEnd($_,@html_tag);
        my $e_id = $tag_tag->{id};
        print Dumper($_,$tag_tag);
        print "===================\n";
    }
  
    
    exit;
    
    
    $file =~ s/\s+//g;
    my $title;
    if($file =~ /<title>(.*?)<\/title>/ig){
       $title =  $1;
    }
    my $keywords;
    if($file =~ /<metaname="keywords"content="(.*?)\/>/ig){
       $keywords =  $1;
    }
    my $description;
    if($file =~ /<metaname="description"content="(.*?)\/>/ig){
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
