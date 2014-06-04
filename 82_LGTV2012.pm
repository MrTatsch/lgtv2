# $Id: 82_LGTV2012.pm 2 2014-03-17 11:05:19Z juliantatsch $
##############################################################################
#
# 82_LGTV2012.pm
#
# a module to send messages or commands to a LG TV Model Year 2012
#
# written 2014 by Julian Tatsch <tatsch at gmail.com>>
#
# $Id$
#
# Version = 0.3
#
##############################################################################
#
# define <name> LGTV2012 <HOST>
#
# set <name> <command>
# e.g set <name> mute
# get <name> <command>
# e.g. get <name> inputSourceName
##############################################################################

package main;

use warnings;
use strict;
use HttpUtils;



sub LGTV2012_displayPairingCode($);
sub LGTV2012_Pair($$);
sub LGTV2012_getInfo($$);
sub LGTV2012_sendCommand($$);

# module specific global variables should always use the module name as prefix, as other modules can use the same global variable names.
my %LGTV2012_rcCodes = (
	"power"=>1,
    "0"=>2,
	"1"=>3,
	"2"=>4,
	"3"=>5,
	"4"=>6,
	"5"=>7,
	"6"=>8,
	"7"=>9,
	"8"=>10,
	"9"=>11,
	"up"=>12,
	"down"=>13,
	"left"=>14,
	"right"=>15,
	"ok"=>20,
	"home"=>21,
	"menu"=>22,
	"back"=>23,
	"volumeUp"=>24,
	"volumeDown"=>25,
	"mute"=>26,
	"channelUp"=>27,
	"channelDown"=>28,
	"blue"=>29,
	"green"=>30,
	"red"=>31,
	"yellow"=>32,
	"play"=>33,
	"pause"=>34,
	"stop"=>35,
	"fastForward"=>36,
	"rewind"=>37,
	"skipForward"=>38,
	"skipBackward"=>39,
	"record"=>40,
	"recordingList"=>41,
	"repeat"=>42,
	"liveTv"=>43,
	"epg"=>44,
	"info"=>45,
	"ratio"=>46,
	"input"=>47,
	"PiP"=>48,
	"subtitle"=>49,
	"proglist"=>50,
	"teletext"=>51,
	"mark"=>52,
	"3Dvideo"=>400,
	"3D_L/R"=>401,
	"dash"=>402,
	"prevchannel"=>403,
	"favouriteChannel"=>404,
	"quickMenu"=>405,
	"textOption"=>406,
	"audioDescription"=>407,
	"netCast"=>408,
	"energySaving"=>409,
	"avMode"=>410,
	"simplink"=>411,
	"exit"=>412,
	"reservationProglist"=>413,
	"PiP_channelUp"=>414,
	"PiP_channelDown"=>415,
	"switchPriSecVideo"=>416,
	"myApps"=>417,
);

sub
LGTV2012_Initialize($)
{
my ($hash) = @_;
    
 $hash->{DefFn}    = "LGTV2012_Define";
 $hash->{UndefFn}  = "LGTV2012_Undefine";
 $hash->{SetFn}    = "LGTV2012_Set";
 $hash->{GetFn}    = "LGTV2012_Get";
 $hash->{AttrFn}   = "LGTV2012_Attr";
 $hash->{AttrList} = "pairingcode request-timeout:1,2,3,4,5 ".$readingFnAttributes;

}

sub
LGTV2012_Define($$)
{
    my ($hash, $def) = @_;
    my @args = split("[ \t]+", $def);
    my $name = $hash->{NAME};
    if (int(@args) < 2)
    {
        return "LGTV2012: not enough arguments. Usage: " .
        "define <name> LGTV2012 <HOST>";
    }
    
    $hash->{HOST} = $args[2];
    $hash->{PORT} = "8080";
    $hash->{INTERVAL} = 30;
    
    $hash->{STATE} = 'defined';
    return undef;
}

sub
LGTV2012_Get($@)
{
 # not implemented yet
 
}

sub
LGTV2012_Set($@)
{
    my ($hash, @args) = @_;
    my $name = $hash->{NAME};

    my $what = $args[1];
    my $arg = $args[2];

    my $usage = "Unknown argument $what, choose one of statusRequest:noArg showPairCode:noArg removePairing:noArg remoteControl:".join(",", sort keys %LGTV2012_rcCodes);

    if($what eq "showPairCode")
    {
        LGTV2012_HttpGet($hash, "/udap/api/pairing", $what, undef, "<api type=\"pairing\"><name>showKey</name></api>");
    }
    elsif($what eq "removePairing")
    {
        LGTV2012_HttpGet($hash, "/udap/api/pairing", $what, undef, "<api type=\"pairing\"><name>byebye</name><port>8080</port></api>");
    }
    elsif($what eq "statusRequest")
    {
        LGTV2012_GetStatus($hash)
    }
    elsif($what eq "remoteControl" and exists($LGTV2012_rcCodes{$arg}))
    {
        LGTV2012_HttpGet($hash, "/udap/api/command", $what, $arg, "<api type=\"command\"><name>HandleKeyInput</name><value>".$LGTV2012_rcCodes{$arg}."</value></api>");
    }
    else
    {
    return $usage;
    }
  
  
}

##########################
sub
LGTV2012_Attr(@)
{
    my @a = @_;
    my $hash = $defs{$a[1]};

    if($a[0] eq "set" && $a[2] eq "pairingcode")
    {
             # if a pairing code was set as attribute, try immediatly a pairing
             LGTV2012_Pair($hash, $a[3]);
    }
    elsif($a[0] eq "del" && $a[2] eq "pairingcode")
    {
             # if a pairing code is removed, start unpairing
             LGTV2012_HttpGet($hash, "/udap/api/pairing", "removePairing", undef, "<api type=\"pairing\"><name>byebye</name><port>8080</port></api>") if(exists($hash->{helper}{PAIRED}) and $hash->{helper}{PAIRED} == 1);
    }

    return undef;
}


sub
LGTV2012_Undefine($$)
{
  # no unpairing should be done at undefine. In case of a restart of FHEM a repair would be neccessary.
  #
  # unpairing should only be done by the user itself.
  
}



#################################

# start a status request by starting the neccessary requests
sub 
LGTV2012_GetStatus($)
{
    my ($hash) = @_;

    LGTV2012_HttpGet($hash, "/udap/api/data?target=cur_channel", "statusRequest", "currentChannel");

    LGTV2012_HttpGet($hash, "/udap/api/data?target=volume_info", "statusRequest", "volumeInfo");

    LGTV2012_HttpGet($hash, "/udap/api/data?target=is_3d", "statusRequest", "is3d");
}

sub
LGTV2012_ParseHttpResponse($$$)
{

    my ( $param, $err, $data ) = @_;    
    
    my $hash = $param->{hash};
    my $name = $hash->{NAME};
    my $cmd = $param->{cmd};
    my $arg = $param->{arg};
    
    # we successfully received a HTTP status code in the response
    if($err ne "" and exists($param->{code}))
    {
        # when a HTTP 401 was received => UNAUTHORIZED => No Pairing
        if($param->{code} eq 401)
        {
            Log3 $name, 3, "LGTV2012 ($name) - failed to execute \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\": Device is not paired";
            
            # if the device had a successful pairing...
            if($hash->{helper}{PAIRED} == 1)
            {
                # set $hash->{helper}{PAIRED} = -1   =>  try a repair.
                $hash->{helper}{PAIRED} = -1;
                
            } # if this was already the repair try, set the status to unpaired
            elsif($hash->{helper}{PAIRED} == -1)
            {
                $hash->{helper}{PAIRED} = 0;
            }
            
            # If a pairing code is set as attribute, try one repair (when $hash->{helper}{PAIRED} == -1)
            if($hash->{helper}{PAIRED} == -1 and defined(AttrVal($name, "pairingcode", undef)) and AttrVal($name, "pairingcode", undef) =~/^\d{6}$/)
            {
                Log3 $name, 3, "LGTV2012 ($name) - try repairing with pairingcode ".AttrVal($name, "pairingcode", undef);
                LGTV2012_Pair($hash, AttrVal($name, "pairingcode", undef));
                return;
            }
        }
    }
    
    
    # if an error was occured, raise a log entry
    if($err ne "")
    {
        Log3 $name, 5, "LGTV2012 ($name) - could not execute command \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\" - $err";

        readingsSingleUpdate($hash, "state", "off", 1);

    } # if the response contains data, examine it.
    elsif($data ne "")
    {
        Log3 $name, 5, "LGTV2012 ($name) - got response for \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\": $data";
    
    
       
        readingsSingleUpdate($hash, "state", "on", 1);
        
        if($cmd eq "statusRequest")
        {
            readingsBeginUpdate($hash);
            
            if($arg eq "volumeInfo")
            {
             
                if($data =~ /<level>(.+?)<\/level>/)
                {
                    readingsBulkUpdate($hash, "volume", $1);
                }
                
                if($data =~ /<mute>(.+?)<\/mute>/)
                {
                    readingsBulkUpdate($hash, "mute", $1);
                }
            }
            
            if($arg eq "currentChannel")
            {
                if($data =~ /<inputSourceName>(.+?)<\/inputSourceName>/)
                {
                    readingsBulkUpdate($hash, "input", $1);
                }
                
                if($data =~ /<chname>(.+?)<\/chname>/)
                {
                    readingsBulkUpdate($hash, "currentChannel", $1);
                }
                
                if($data =~ /<progName>(.+?)<\/progName>/)
                {
                    readingsBulkUpdate($hash, "currentProgram", $1);
                }
            }
            
            if($arg eq "is3d")
            {
                if($data =~ /<is3D>(.+?)<\/is3D>/)
                {
                    readingsBulkUpdate($hash, "3D", $1);
                }
            }

            readingsEndUpdate($hash, 1);

        }
        
    }  # successful response without content data, so lets check the HTTP response code
    elsif($data eq "" and $data eq "" and exists($param->{code}))
    {
    
        Log3 $name, 5, "LGTV2012 ($name) - got empty response for \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\": $data";
    
        readingsSingleUpdate($hash, "state", "off", 1);
    
        # check the response code from a pairing request
        if($cmd eq "pairing")
        {
            if($param->{code} eq 200)
            {
                Log3 $name, 5, "LGTV2012 ($name) - successful paired with code $arg";
                
                $hash->{helper}{PAIRED} = 1;
            }
            elsif($param->{code} eq 401)
            {
                Log3 $name, 5, "LGTV2012 ($name) - invalid pairing code: $arg";
                
                $hash->{helper}{PAIRED} = 0;
            }
        } # check the response code from pairing removal
        elsif($cmd eq "removePairing")
        {
            if($param->{code} eq 200)
            {
                Log3 $name, 5, "LGTV2012 ($name) - successful removed pairing";
                
                $hash->{helper}{PAIRED} = 1;
            }
            elsif($param->{code} eq 401)
            {
                Log3 $name, 5, "LGTV2012 ($name) - remove pairing failed: unpaired";
                
                $hash->{helper}{PAIRED} = 0;
            }
        }
    }
    
    

}

# executes a http request with or without data and starts the HTTP request non-blocking to avoid timing problems for other modules (e.g. HomeMatic)
sub
LGTV2012_HttpGet($$$$;$)
{
my ($hash, $path, $cmd, $arg, $data) = @_;


    if(defined($data))
    {
        # start a HTTP POST on the given url with content data
        HttpUtils_NonblockingGet({
                                url        => "http://".$hash->{HOST}.":8080".$path,
                                timeout    => AttrVal($hash->{NAME}, "request-timeout", 4),
                                noshutdown => 1,
                                header     => "User-Agent: Linux/2.6.18 UDAP/2.0 CentOS/5.8\r\nContent-Type: text/xml; charset=utf-8\r\nConnection: Close",
                                data       => "<?xml version=\"1.0\" encoding=\"utf-8\"?><envelope>".$data."</envelope>",
                                loglevel   => ($hash->{helper}{AVAILABLE} ? undef : 5),
                                hash       => $hash,
                                cmd        => $cmd,
                                arg        => $arg,
                                callback   => \&LGTV2012_ParseHttpResponse
                            });
    }
    else
    {
        # start a HTTP GET on the given url
        HttpUtils_NonblockingGet({
                                url        => "http://".$hash->{HOST}.":8080".$path,
                                timeout    => AttrVal($hash->{NAME}, "request-timeout", 4),
                                noshutdown => 1,
                                header     => "User-Agent: Linux/2.6.18 UDAP/2.0 CentOS/5.8",
                                loglevel   => ($hash->{helper}{AVAILABLE} ? undef : 5),
                                hash       => $hash,
                                cmd        => $cmd,
                                arg        => $arg,
                                callback   => \&LGTV2012_ParseHttpResponse
                            });
    }
}

# sends the pairing request.
sub
LGTV2012_Pair($$)
{
    my ($hash, $code) = @_;
    
    LGTV2012_HttpGet($hash, "/udap/api/pairing", "pairing", $code, "<api type=\"pairing\"><name>hello</name><value>$code</value><port>8080</port></api>");
    
}




1;
