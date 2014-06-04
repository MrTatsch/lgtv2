# $Id: 82_LGTV2.pm 2 2014-03-17 11:05:19Z juliantatsch $
##############################################################################
#
# 82_LGTV2.pm
#
# a module to control LG TVs
#
# written 2014 by Julian Tatsch <tatsch at gmail.com>>
#
# $Id$
#
# Version = 0.4
#
##############################################################################
#
# define <name> LGTV2 <HOST>
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


sub LGTV2_displayPairingCode($);
sub LGTV2_Pair($$);
sub LGTV2_getInfo($$);
sub LGTV2_sendCommand($$);

# module specific global variables should always use the module name as prefix, as other modules can use the same global variable names.

my %LGTV2_rcCodes2011 = (
"power"=>8,
"0"=>16,
"1"=>17,
"2"=>18,
"3"=>19,
"4"=>20,
"5"=>21,
"6"=>22,
"7"=>23,
"8"=>24,
"9"=>25,
"up"=>64,
"down"=>65,
"left"=>7,
"right"=>6,
"ok"=>68,
"home"=>91,
"menu"=>67,
"back"=>40,
"volumeUp"=>2,
"volumeDown"=>3,
"mute"=>9,
"channelUp"=>0,
"channelDown"=>1,
"blue"=>97,
"green"=>113,
"red"=>114,
"yellow"=>99,
"play"=>176,
"pause"=>186,
"stop"=>177,
"fastForward"=>142,
"rewind"=>143,
"record"=>189,
"statusBar"=>35,
"quickMenu"=>69,
"premiumMenu"=>89,
"installationMenu"=>207,
"factoryAdvancedMenu1"=>251,
"factoryAdvancedMenu2"=>255,
"sleepTimer"=>14,
"underscore"=>76,
"tvRadio"=>15,
"simplink"=>126,
"input"=>11,
"componentRgbHdmi"=>152,
"component"=>191,
"rgb"=>213,
"hdmi"=>198,
"hdmi1"=>206,
"hdmi2"=>204,
"hdmi3"=>233,
"hdmi4"=>218,
"av1"=>90,
"av2"=>208,
"av3"=>209,
"usb"=>124,
"slideshowUsb1"=>238,
"slideshowUsb2"=>168,
"channelBack"=>26,
"favorites"=>30,
"teletext"=>32,
"tOpt"=>33,
"channelList"=>83,
"greyedOutAddButton"=>85,
"epg"=>169,
"info"=>170,
"liveTv"=>158,
"avMode"=>48,
"pictureMode"=>77,
"ratio"=>121,
"ratio43"=>118,
"ratio169"=>119,
"energySaving"=>149,
"cinemaZoom"=>175,
"threeD"=>220,
"factoryPictureCheck"=>252,
"audioLanguage"=>10,
"soundMode"=>82,
"factorySoundCheck"=>253,
"subtitleLanguage"=>57,
"audioDescription"=>145,
);

my %LGTV2_rcCodes2012 = (
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
LGTV2_Initialize($)
{
    my ($hash) = @_;
    $hash->{DefFn}    = "LGTV2_Define";
    $hash->{UndefFn}  = "LGTV2_Undefine";
    $hash->{SetFn}    = "LGTV2_Set";
    $hash->{GetFn}    = "LGTV2_Get";
    $hash->{AttrFn}   = "LGTV2_Attr";
    $hash->{AttrList} = "pairingcode request-timeout:1,2,3,4,5 ".$readingFnAttributes;
    
    if ($hash->{API} eq "2011")
    {
        $hash->{RcCodes} = %LGTV2_rcCodes2011;
    }
    else
    {
        $hash->{RcCodes} = %LGTV2_rcCodes2012;
    }
}

sub
LGTV2_Define($$)
{
    my ($hash, $def) = @_;
    my @args = split("[ \t]+", $def);
    my $name = $hash->{NAME};
    if (int(@args) < 3)
    {
        return "LGTV2: not enough arguments. Usage: " .
        "define <name> LGTV2 <HOST> <API>";
    }
    
    $hash->{HOST} = $args[2];
    $hash->{API} = $args[3];
    $hash->{PORT} = "8080";
    $hash->{STATE} = 'defined';
    return undef;
}

sub
LGTV2_Get($@)
{
    # not implemented yet
    
}

sub
LGTV2_Set($@)
{
    my ($hash, @args) = @_;
    my $name = $hash->{NAME};
    
    my $what = $args[1];
    my $arg = $args[2];
    
    my $usage = "Unknown argument $what, choose one of statusRequest:noArg showPairCode:noArg removePairing:noArg remoteControl:".join(",", sort keys %{$hash->{RcCodes}});
    
    if($what eq "showPairCode")
    {
        LGTV2_HttpGet($hash, "/udap/api/pairing", $what, undef, "<api type=\"pairing\"><name>showKey</name></api>");
    }
    elsif($what eq "removePairing")
    {
        LGTV2_HttpGet($hash, "/udap/api/pairing", $what, undef, "<api type=\"pairing\"><name>byebye</name><port>8080</port></api>");
    }
    elsif($what eq "statusRequest")
    {
        LGTV2_GetStatus($hash)
    }
    elsif($what eq "remoteControl" and exists($hash->{RcCodes}{$arg}))
    {
        LGTV2_HttpGet($hash, "/udap/api/command", $what, $arg, "<api type=\"command\"><name>HandleKeyInput</name><value>".$hash->{RcCodes}{$arg}."</value></api>");
    }
    else
    {
        return $usage;
    }
    
    
}

##########################
sub
LGTV2_Attr(@)
{
    my @a = @_;
    my $hash = $defs{$a[1]};
    
    if($a[0] eq "set" && $a[2] eq "pairingcode")
    {
        # if a pairing code was set as attribute, try immediatly a pairing
        LGTV2_Pair($hash, $a[3]);
    }
    elsif($a[0] eq "del" && $a[2] eq "pairingcode")
    {
        # if a pairing code is removed, start unpairing
        LGTV2_HttpGet($hash, "/udap/api/pairing", "removePairing", undef, "<api type=\"pairing\"><name>byebye</name><port>8080</port></api>") if(exists($hash->{helper}{PAIRED}) and $hash->{helper}{PAIRED} == 1);
    }
    
    return undef;
}


sub
LGTV2_Undefine($$)
{
    # no unpairing should be done at undefine. In case of a restart of FHEM a repair would be neccessary.
    #
    # unpairing should only be done by the user itself.
    
}



#################################

# start a status request by starting the neccessary requests
sub
LGTV2_GetStatus($)
{
    my ($hash) = @_;
    
    LGTV2_HttpGet($hash, "/udap/api/data?target=cur_channel", "statusRequest", "currentChannel");
    
    LGTV2_HttpGet($hash, "/udap/api/data?target=volume_info", "statusRequest", "volumeInfo");
    
    LGTV2_HttpGet($hash, "/udap/api/data?target=is_3d", "statusRequest", "is3d");
}

sub
LGTV2_ParseHttpResponse($$$)
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
            Log3 $name, 3, "LGTV2 ($name) - failed to execute \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\": Device is not paired";
            
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
                Log3 $name, 3, "LGTV2 ($name) - try repairing with pairingcode ".AttrVal($name, "pairingcode", undef);
                LGTV2_Pair($hash, AttrVal($name, "pairingcode", undef));
                return;
            }
        }
    }
    
    
    # if an error occured, write a log entry
    if($err ne "")
    {
        Log3 $name, 5, "LGTV2 ($name) - could not execute command \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\" - $err";
        
        readingsSingleUpdate($hash, "state", "off", 1);
        
    } # if the response contains data, examine it.
    elsif($data ne "")
    {
        Log3 $name, 5, "LGTV2 ($name) - got response for \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\": $data";
        
        
        
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
        
        Log3 $name, 5, "LGTV2 ($name) - got empty response for \"$cmd".(defined($arg) ? " ".(split("\\|", $arg))[0] : "")."\": $data";
        
        readingsSingleUpdate($hash, "state", "off", 1);
        
        # check the response code from a pairing request
        if($cmd eq "pairing")
        {
            if($param->{code} eq 200)
            {
                Log3 $name, 5, "LGTV2 ($name) - successful paired with code $arg";
                
                $hash->{helper}{PAIRED} = 1;
            }
            elsif($param->{code} eq 401)
            {
                Log3 $name, 5, "LGTV2 ($name) - invalid pairing code: $arg";
                
                $hash->{helper}{PAIRED} = 0;
            }
        } # check the response code from pairing removal
        elsif($cmd eq "removePairing")
        {
            if($param->{code} eq 200)
            {
                Log3 $name, 5, "LGTV2 ($name) - successful removed pairing";
                
                $hash->{helper}{PAIRED} = 1;
            }
            elsif($param->{code} eq 401)
            {
                Log3 $name, 5, "LGTV2 ($name) - remove pairing failed: unpaired";
                
                $hash->{helper}{PAIRED} = 0;
            }
        }
    }
    
    
    
}

# executes a http request with or without data and starts the HTTP request non-blocking to avoid timing problems for other modules (e.g. HomeMatic)
sub
LGTV2_HttpGet($$$$;$)
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
            callback   => \&LGTV2_ParseHttpResponse
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
            callback   => \&LGTV2_ParseHttpResponse
        });
    }
}

# sends the pairing request.
sub
LGTV2_Pair($$)
{
    my ($hash, $code) = @_;
    
    LGTV2_HttpGet($hash, "/udap/api/pairing", "pairing", $code, "<api type=\"pairing\"><name>hello</name><value>$code</value><port>8080</port></api>");
    
}




1;