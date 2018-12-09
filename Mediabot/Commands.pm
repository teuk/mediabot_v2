package Mediabot::Commands;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use POSIX 'setsid';
use Switch;
use Data::Dumper;
use Memory::Usage;
use Mediabot::Common;
use Mediabot::Core;
use Mediabot::Database;
use Mediabot::Channel;
use Mediabot::User;
use Mediabot::Plugins;

@ISA     = qw(Exporter);
@EXPORT  = qw(getCommandCategory mbChangeNick mbCommandPrivate mbCommandPublic mbDbAddCommand mbDbCommand mbDbModCommand mbDbRemCommand mbDbSearchCommand mbDbShowCommand mbDebug mbJump mbRegister mbRestart mbVersion mbLastCommand);

sub mbCommandPublic(@) {
	my ($loop,$TVars,$NVars,$WVars,$Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$iConnectionTimestamp,$sChannel,$sNick,$sCommand,@tArgs)	= @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	my %hChannelsNicks = %$NVars;
	my %hTimers = %$TVars;
	my $bFound = 0;
	switch($sCommand) {
		case "quit"					{ $bFound = 1;
													mbQuit(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "nick"					{ $bFound = 1;
													mbChangeNick(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "addtimer"			{ $bFound = 1;
													%hTimers = mbAddTimer($loop,\%$TVars,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,@tArgs);
												}
		case "remtimer"			{ $bFound = 1;
													%hTimers = mbRemTimer($loop,\%$TVars,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "timers"				{ $bFound = 1;
													mbTimers(\%$TVars,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "msg"					{ $bFound = 1;
													msgCmd(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "say"					{ $bFound = 1;
													sayChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "act"					{ $bFound = 1;
													actChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "cstat"				{ $bFound = 1;
													userCstat(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "status"				{ $bFound = 1;
													mbStatus(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$iConnectionTimestamp,$sNick,$sChannel,@tArgs);
												}
		case "adduser"			{ $bFound = 1;
													addUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "users"				{ $bFound = 1;
													userStats(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "userinfo"			{ $bFound = 1;
													userInfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "addhost"			{ $bFound = 1;
													addUserHost(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "addchan"			{ $bFound = 1;
													addChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chanset"			{ $bFound = 1;
													channelSet(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "purge"				{ $bFound = 1;
													purgeChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "part"					{ $bFound = 1;
													channelPart(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "join"					{ $bFound = 1;
													channelJoin(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "add"					{ $bFound = 1;
													channelAddUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "del"					{ $bFound = 1;
													channelDelUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "modinfo"			{ $bFound = 1;
													userModinfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "op"						{ $bFound = 1;
													userOpChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "deop"					{ $bFound = 1;
													userDeopChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "invite"				{ $bFound = 1;
													userInviteChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "voice"				{ $bFound = 1;
													userVoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "devoice"			{ $bFound = 1;
													userDevoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "kick"					{ $bFound = 1;
													userKickChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "topic"				{ $bFound = 1;
													userTopicChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "showcommands"	{ $bFound = 1;
													userShowcommandsChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "chaninfo"			{ $bFound = 1;
													userChannelInfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "chanlist"			{ $bFound = 1;
													channelList(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "whoami"				{ $bFound = 1;
													userWhoAmI(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "auth"					{ $bFound = 1;
													%WHOIS_VARS = userAuthNick(\%WHOIS_VARS,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "access"				{ $bFound = 1;
													%WHOIS_VARS = userAccessChannel(\%WHOIS_VARS,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "addcmd"				{ $bFound = 1;
													mbDbAddCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "remcmd"				{ $bFound = 1;
													mbDbRemCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "modcmd"				{ $bFound = 1;
													mbDbModCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "mvcmd"				{ $bFound = 1;
													mbDbMvCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chowncmd"			{ $bFound = 1;
													mbChownCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "showcmd"			{ $bFound = 1;
													mbDbShowCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "version"			{ $bFound = 1;
													mbVersion(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$MAIN_PROG_VERSION);
												}
		case "chanstatlines"	{ $bFound = 1;
														channelStatLines(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,@tArgs);
													}
		case "whotalk"			{ $bFound = 1;
														whoTalk(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,@tArgs);
												}
		case "countcmd"			{ $bFound = 1;
														mbCountCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "topcmd"				{ $bFound = 1;
														mbTopCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "searchcmd"		{ $bFound = 1;
														mbDbSearchCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "lastcmd"			{ $bFound = 1;
														mbLastCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "owncmd"				{ $bFound = 1;
														mbDbOwnersCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "addcatcmd"		{ $bFound = 1;
														mbDbAddCategoryCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "chcatcmd"			{ $bFound = 1;
														mbDbChangeCategoryCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "topsay"				{ $bFound = 1;
														userTopSay(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "checkhostchan"		{ $bFound = 1;
															mbDbCheckHostnameNickChan(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
														}
		case "checkhost"		{ $bFound = 1;
															mbDbCheckHostnameNick(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "checknick"		{ $bFound = 1;
													mbDbCheckNickHostname(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "greet"				{ $bFound = 1;
													userGreet(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "nicklist"			{ $bFound = 1;
														channelNickList(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "rnick"				{ $bFound = 1;
														randomChannelNick(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		else								{
													$bFound = mbPluginCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs);
													unless ( $bFound ) {
														$bFound = mbDbCommand(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs);
													}
													unless ( $bFound ) {
														my $what = join(" ",($sCommand,@tArgs));
														switch($what) {
															case /how\s+old\s+are\s+you|how\s+old\s+r\s+you|how\s+old\s+r\s+u/i {
																$bFound = 1;
																displayBirthDate(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
															}
														}
													}
												}
	}
	unless ( $bFound ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"Public command '$sCommand' not found");
		return ();
	}
	else {
		my %GLOBAL_HASH;
		$GLOBAL_HASH{'WHOIS_VARS'} = \%WHOIS_VARS;
		$GLOBAL_HASH{'hTimers'} = \%hTimers;
		return %GLOBAL_HASH;
	}
}

sub mbCommandPrivate(@) {
	my ($loop,$TVars,$NVars,$WVars,$Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$iConnectionTimestamp,$sNick,$sCommand,@tArgs)	= @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	my %hChannelsNicks = %$NVars;
	my %hTimers = %$TVars;
	my $bFound = 0;
	switch($sCommand) {
		case "quit"					{ $bFound = 1;
													mbQuit(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "nick"					{ $bFound = 1;
													mbChangeNick(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "addtimer"			{ $bFound = 1;
													%hTimers = mbAddTimer($loop,\%$TVars,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "remtimer"			{ $bFound = 1;
													%hTimers = mbRemTimer($loop,\%$TVars,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "timers"				{ $bFound = 1;
													mbTimers(\%$TVars,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "register"			{ $bFound = 1;
													mbRegister(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "dump"					{ $bFound = 1;
													dumpCmd(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "msg"					{ $bFound = 1;
													msgCmd(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "say"					{ $bFound = 1;
													sayChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "act"					{ $bFound = 1;
													actChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "status"				{ $bFound = 1;
													mbStatus(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$iConnectionTimestamp,$sNick,undef,@tArgs);
												}
		case "login"				{ $bFound = 1;
													userLogin(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "pass"					{ $bFound = 1;
													userPass(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "newpass"			{ $bFound = 1;
													userNewPass(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "ident"				{ $bFound = 1;
													userIdent(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "cstat"				{ $bFound = 1;
													userCstat(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "adduser"			{ $bFound = 1;
													addUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "users"				{ $bFound = 1;
													userStats(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "userinfo"			{ $bFound = 1;
													userInfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "addhost"			{ $bFound = 1;
													addUserHost(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "addchan"			{ $bFound = 1;
													addChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chanset"			{ $bFound = 1;
													channelSet(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "purge"				{ $bFound = 1;
													purgeChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "part"					{ $bFound = 1;
													channelPart(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "join"					{ $bFound = 1;
													channelJoin(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "add"					{ $bFound = 1;
													channelAddUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "del"					{ $bFound = 1;
													channelDelUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "modinfo"			{ $bFound = 1;
													userModinfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "op"						{ $bFound = 1;
													userOpChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "deop"					{ $bFound = 1;
													userDeopChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "invite"				{ $bFound = 1;
													userInviteChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "voice"				{ $bFound = 1;
													userVoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "devoice"			{ $bFound = 1;
													userDevoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "kick"					{ $bFound = 1;
													userKickChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "topic"				{ $bFound = 1;
													userTopicChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "showcommands"	{ $bFound = 1;
													userShowcommandsChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "chaninfo"			{ $bFound = 1;
													userChannelInfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "chanlist"			{ $bFound = 1;
													channelList(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "whoami"				{ $bFound = 1;
													userWhoAmI(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "verify"				{ $bFound = 1;
													%WHOIS_VARS = userVerifyNick(\%WHOIS_VARS,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "auth"					{ $bFound = 1;
													%WHOIS_VARS = userAuthNick(\%WHOIS_VARS,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "access"				{ $bFound = 1;
													%WHOIS_VARS = userAccessChannel(\%WHOIS_VARS,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "addcmd"				{ $bFound = 1;
													mbDbAddCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "remcmd"				{ $bFound = 1;
													mbDbRemCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "modcmd"				{ $bFound = 1;
													mbDbModCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "showcmd"			{ $bFound = 1;
													mbDbShowCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chowncmd"			{ $bFound = 1;
													mbChownCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "nicklist"			{ $bFound = 1;
														channelNickList(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "rnick"				{ $bFound = 1;
														randomChannelNick(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "chanstatlines"	{ $bFound = 1;
														channelStatLines(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,$sNick,@tArgs);
													}
		case "whotalk"			{ $bFound = 1;
														whoTalk(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,$sNick,@tArgs);
												}
		else								{
												
												}
	}
	unless ( $bFound ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,$message->prefix . " Private command '$sCommand' not found");
		return ();
	}
	else {
		my %GLOBAL_HASH;
		$GLOBAL_HASH{'WHOIS_VARS'} = \%WHOIS_VARS;
		$GLOBAL_HASH{'hTimers'} = \%hTimers;
		return %GLOBAL_HASH;
	}
}

# version
sub mbVersion(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$MAIN_PROG_VERSION) = @_;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"mbVersion() by $sNick on $sChannel");
	botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$MAIN_CONF{'main.MAIN_PROG_NAME'} . " v$MAIN_PROG_VERSION");
	logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"version",undef);
}

# debug <debug_level>
sub mbDebug(@) {
	my ($cfg,$Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ($tArgs[0] =~ /[0-9]+/) && ($tArgs[0] <= 5)) {
					$cfg->param("main.MAIN_PROG_DEBUG", $tArgs[0]);
					%MAIN_CONF = $cfg->vars();
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Debug set to " . $tArgs[0]);
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Debug set to " . $tArgs[0]);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"debug",("Debug set to " . $tArgs[0]));
					return %MAIN_CONF;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: debug <debug_level>");
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"debug_level 0 to 5");
					return ();
				}
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return ();
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return ();
		}
	}
}

# restart
sub mbRestart(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				my $iCHildPid;
				if (defined($iCHildPid = fork())) {
					unless ($iCHildPid) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Restart request from $sMatchingUserHandle");
						setsid;
						exec "./mb_restart.sh",$tArgs[0];
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Restarting bot");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"restart",($MAIN_CONF{'main.MAIN_PROG_QUIT_MSG'}));
						$irc->send_message( "QUIT", undef, $MAIN_CONF{'main.MAIN_PROG_QUIT_MSG'} );
					}
				}
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"restart",undef);
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# jump
sub mbJump(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				my $sServer = pop @tArgs;
				my $sFullParams = join(" ",@tArgs);
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					$sFullParams =~ s/\-\-server=[^ ]*//g;
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,$sFullParams);
					my $iCHildPid;
					if (defined($iCHildPid = fork())) {
						unless ($iCHildPid) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Jump request from $sMatchingUserHandle");
							setsid;
							exec "./mb_restart.sh",($sFullParams,"--server=$sServer");
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Jumping to $sServer");
							logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"jump",($sServer));
							$irc->send_message( "QUIT", undef, "Changing server" );
						}
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: jump <server>");
				}
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# quit <quit message>
sub mbQuit(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"quit",@tArgs);
				$irc->send_message( "QUIT", undef, join(" ",@tArgs) );
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# status
sub mbStatus(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$iConnectionTimestamp,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"Checking uptime");
				my $sUptime = "Unknown";
				unless (open LOAD, "uptime |") {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Could not exec uptime command");
				}
				else {
					my $line;
					if (defined($line=<LOAD>)) {
						chomp($line);
						$sUptime = $line;
					}
				}
				# Uptime
				my $iUptime = time - $iConnectionTimestamp;
				my $days = int($iUptime / 86400);
				my $hours = int(($iUptime - ( $days * 86400 )) / 3600);
				$hours = sprintf("%02d",$hours);
				my $minutes = int(($iUptime - ( $days * 86400 ) - ( $hours * 3600 )) / 60);
				$minutes = sprintf("%02d",$minutes);
				my $seconds = int($iUptime - ( $days * 86400 ) - ( $hours * 3600 ) - ( $minutes * 60 ));
				$seconds = sprintf("%02d",$seconds);
				my $sAnswer = "$days days, $hours" . "h" . "$minutes" . "mn" . "$seconds" . "s";
				
				
				# Memory usage
				my $mu = Memory::Usage->new();
				$mu->record('Memory stats');

				my @tMemStateResultsArrayRef = $mu->state();
				my @tMemStateResults = $tMemStateResultsArrayRef[0][0];
				
				my ($iTimestamp,$sMessage,$fVmSize,$fResSetSize,$fSharedMemSize,$sCodeSize,$fDataStackSize);
				if (defined($tMemStateResults[0][0]) && ($tMemStateResults[0][0] ne "")) {
					$iTimestamp = $tMemStateResults[0][0];
				}
				if (defined($tMemStateResults[0][1]) && ($tMemStateResults[0][1] ne "")) {
					$sMessage = $tMemStateResults[0][1];
				}
				if (defined($tMemStateResults[0][2]) && ($tMemStateResults[0][2] ne "")) {
					$fVmSize = $tMemStateResults[0][2];
					$fVmSize = $fVmSize / 1024;
					$fVmSize = sprintf("%.2f",$fVmSize);
				}
				if (defined($tMemStateResults[0][3]) && ($tMemStateResults[0][3] ne "")) {
					$fResSetSize = $tMemStateResults[0][3];
					$fResSetSize = $fResSetSize / 1024;
					$fResSetSize = sprintf("%.2f",$fResSetSize);
				}
				if (defined($tMemStateResults[0][4]) && ($tMemStateResults[0][4] ne "")) {
					$fSharedMemSize = $tMemStateResults[0][4];
					$fSharedMemSize = $fSharedMemSize / 1024;
					$fSharedMemSize = sprintf("%.2f",$fSharedMemSize);
				}
				if (defined($tMemStateResults[0][5]) && ($tMemStateResults[0][5] ne "")) {
					$sCodeSize = $tMemStateResults[0][5];
				}
				if (defined($tMemStateResults[0][6]) && ($tMemStateResults[0][6] ne "")) {
					$fDataStackSize = $tMemStateResults[0][6];
					$fDataStackSize = $fDataStackSize / 1024;
					$fDataStackSize = sprintf("%.2f",$fDataStackSize);
				
				}
				unless (defined($sAnswer)) {
					$sAnswer = "Unknown";
				}
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$MAIN_CONF{'main.MAIN_PROG_NAME'} . " v$MAIN_PROG_VERSION Uptime : $sAnswer");
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Memory usage (VM $fVmSize MB) (Resident Set $fResSetSize MB) (Shared Memory $fSharedMemSize MB) (Data and Stack $fDataStackSize MB)");
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Server's uptime : $sUptime");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"status",undef);
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

sub mbRegister(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $sUserHandle = $tArgs[0];
	my $sPassword = $tArgs[1];
	if (defined($sUserHandle) && ($sUserHandle ne "") && defined($sPassword) && ($sPassword ne "")) {
		if (userCount(\%MAIN_CONF,$LOG,$dbh) == 0) {
 			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,$message->prefix . " wants to register");
 			my $sHostmask = getMessageHostmask($message);
 			my $id_user = userAdd(\%MAIN_CONF,$LOG,$dbh,$sHostmask,$sUserHandle,$sPassword,"Owner");
 			if (defined($id_user)) {
 				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Registered $sUserHandle (id_user : $id_user) as Owner with hostmask $sHostmask");
 				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You just registered as $sUserHandle (id_user : $id_user) as Owner with hostmask $sHostmask");
 				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"register","Success");
 				my ($id_channel,$name,$chanmode,$key) = getConsoleChan($dbh);
 				if (registerChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$id_channel,$id_user)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"registerChan successfull $name $sUserHandle");
				}
				else {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"registerChan failed $name $sUserHandle");
				}
 			}
 			else {
 				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Register failed for " . $message->prefix);
 			}
 		}
 		else {
 			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Register attempt from " . $message->prefix);
 		}
	}
}

sub mbDbCommand(@) {
	my ($NVars,$Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs) = @_;
	my %hChannelsNicks = %$NVars;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"Check SQL command : $sCommand");
	my $sQuery = "SELECT * FROM PUBLIC_COMMANDS WHERE command like ?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sCommand)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"mbDbCommand() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $id_public_commands = $ref->{'id_public_commands'};
			my $description = $ref->{'description'};
			my $action = $ref->{'action'};
			my $hits = $ref->{'hits'};
			$hits++;
			$sQuery = "UPDATE PUBLIC_COMMANDS SET hits=? WHERE id_public_commands=?";
			$sth = $dbh->prepare($sQuery);
			unless ($sth->execute($hits,$id_public_commands)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"mbDbCommand() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"SQL command found : $sCommand description : $description action : $action");
				my ($actionType,$actionTo,$actionDo) = split(/ /,$action,3);
				if ( $actionType eq 'PRIVMSG' ) {
					if ( $actionTo eq '%c' ) {
						if (defined($tArgs[0])) {
							my $sNickAction = join(" ",@tArgs);
							$actionDo =~ s/%n/$sNickAction/g;
						}
						else {
							$actionDo =~ s/%n/$sNick/g;
						}
						if ( $actionDo =~ /%r/ ) {
							my $sRandomNick = getRandomNick(\%hChannelsNicks,$sChannel);
							$actionDo =~ s/%r/$sRandomNick/g;
						}
						if ( $actionDo =~ /%R/ ) {
							my $sRandomNick = getRandomNick(\%hChannelsNicks,$sChannel);
							$actionDo =~ s/%R/$sRandomNick/g;
						}
						if ( $actionDo =~ /%s/ ) {
							$actionDo =~ s/%s/$sCommand/g;
						}
						if ( $actionDo =~ /%b/ ) {
							my $iTrueFalse = int(rand(2));
							if ( $iTrueFalse == 1 ) {
								$actionDo =~ s/%b/true/g;
							}
							else {
								$actionDo =~ s/%b/false/g;
							}
						}
						if ( $actionDo =~ /%B/ ) {
							my $iTrueFalse = int(rand(2));
							if ( $iTrueFalse == 1 ) {
								$actionDo =~ s/%B/true/g;
							}
							else {
								$actionDo =~ s/%B/false/g;
							}
						}
						$actionDo =~ s/%c/$sChannel/g;
						$actionDo =~ s/%N/$sNick/g;
						my @tActionDo = split(/ /,$actionDo);
						my $pos;
						for ($pos=0;$pos<=$#tActionDo;$pos++) {
							if ( $tActionDo[$pos] eq "%d" ) {
								$tActionDo[$pos] = int(rand(10) + 1);
							}
						}
						$actionDo = join(" ",@tActionDo);
						for ($pos=0;$pos<=$#tActionDo;$pos++) {
							if ( $tActionDo[$pos] eq "%dd" ) {
								$tActionDo[$pos] = int(rand(90) + 10);
							}
						}
						$actionDo = join(" ",@tActionDo);
						for ($pos=0;$pos<=$#tActionDo;$pos++) {
							if ( $tActionDo[$pos] eq "%ddd" ) {
								$tActionDo[$pos] = int(rand(900) + 100);
							}
						}
						$actionDo = join(" ",@tActionDo);
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$actionDo);
					}
					return 1;
				}
				elsif ( $actionType eq 'ACTION' ) {
					if ( $actionTo eq '%c' ) {
						if (defined($tArgs[0])) {
							my $sNickAction = join(" ",@tArgs);
							$actionDo =~ s/%n/$sNickAction/g;
						}
						else {
							$actionDo =~ s/%n/$sNick/g;
						}
						if ( $actionDo =~ /%r/ ) {
							my $sRandomNick = getRandomNick(\%hChannelsNicks,$sChannel);
							$actionDo =~ s/%r/$sRandomNick/g;
						}
						if ( $actionDo =~ /%R/ ) {
							my $sRandomNick = getRandomNick(\%hChannelsNicks,$sChannel);
							$actionDo =~ s/%R/$sRandomNick/g;
						}
						$actionDo =~ s/%N/$sNick/g;
						if ( $actionDo =~ /%s/ ) {
							$actionDo =~ s/%s/$sCommand/g;
						}
						if ( $actionDo =~ /%b/ ) {
							my $iTrueFalse = int(rand(2));
							if ( $iTrueFalse == 1 ) {
								$actionDo =~ s/%b/true/g;
							}
							else {
								$actionDo =~ s/%b/false/g;
							}
						}
						if ( $actionDo =~ /%B/ ) {
							my $iTrueFalse = int(rand(2));
							if ( $iTrueFalse == 1 ) {
								$actionDo =~ s/%B/true/g;
							}
							else {
								$actionDo =~ s/%B/false/g;
							}
						}
						my @tActionDo = split(/ /,$actionDo);
						my $pos;
						for ($pos=0;$pos<=$#tActionDo;$pos++) {
							if ( $tActionDo[$pos] eq "%d" ) {
								$tActionDo[$pos] = int(rand(10) + 1);
							}
						}
						$actionDo = join(" ",@tActionDo);
						for ($pos=0;$pos<=$#tActionDo;$pos++) {
							if ( $tActionDo[$pos] eq "%dd" ) {
								$tActionDo[$pos] = int(rand(90) + 10);
							}
						}
						$actionDo = join(" ",@tActionDo);
						for ($pos=0;$pos<=$#tActionDo;$pos++) {
							if ( $tActionDo[$pos] eq "%ddd" ) {
								$tActionDo[$pos] = int(rand(900) + 100);
							}
						}
						$actionDo = join(" ",@tActionDo);
						botAction(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$actionDo);
					}
					return 1;
				}
				else {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"Unknown actionType : $actionType");
					return 0;
				}
			}
		}
		else {
			return 0;
		}
	}
	$sth->finish;
}

sub getCommandCategory(@) {
	my ($Config,$LOG,$dbh,$sCategory) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT id_public_commands_category FROM PUBLIC_COMMANDS_CATEGORY WHERE description LIKE ?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sCategory)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			return ($ref->{'id_public_commands_category'});
		}
		else {
			return undef;
		}
	}
	$sth->finish;
}

# addcmd <command> <message|action> <category> <command reply> 
sub mbDbAddCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && (($tArgs[1] =~ /^message$/i) || ($tArgs[1] =~ /^action$/i)) && defined($tArgs[2]) && ($tArgs[2] ne "") && defined($tArgs[3]) && ($tArgs[3] ne "")) {
					my $sCommand = $tArgs[0];
					shift @tArgs;
					my $sType = $tArgs[0];
					shift @tArgs;
					my $sCategory = $tArgs[0];
					shift @tArgs;
					my $id_public_commands_category = getCommandCategory(\%MAIN_CONF,$LOG,$dbh,$sCategory);
					if (defined($id_public_commands_category)) {
						my $sQuery = "SELECT command FROM PUBLIC_COMMANDS WHERE command LIKE ?";
						my $sth = $dbh->prepare($sQuery);
						unless ($sth->execute($sCommand)) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
						}
						else {
							unless (my $ref = $sth->fetchrow_hashref()) {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Adding command $sCommand [$sType] " . join (" ",@tArgs));
								my $sAction;
								if ( $sType =~ /^message$/i ) {
									$sAction = "PRIVMSG %c ";
								}
								elsif ($sType =~ /^action$/i ) {
									$sAction = "ACTION %c ";
								}
								$sAction .= join(" ",@tArgs);
								$sQuery = "INSERT INTO PUBLIC_COMMANDS (id_user,id_public_commands_category,command,description,action) VALUES (?,?,?,?,?)";
								$sth = $dbh->prepare($sQuery);
								unless ($sth->execute($iMatchingUserId,$id_public_commands_category,$sCommand,$sCommand,$sAction)) {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Command $sCommand added");
									logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addcmd",("Command $sCommand added"));
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command already exists");
							}
						}
						$sth->finish;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Unknown category : $sCategory");
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: addcmd <command> <message|action> <category> <text>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " addcmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " addcmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# remcmd <command>
sub mbDbRemCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sCommand = $tArgs[0];
					shift @tArgs;
					my $sQuery = "SELECT id_user,id_public_commands FROM PUBLIC_COMMANDS WHERE command LIKE ?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sCommand)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref = $sth->fetchrow_hashref()) {
							my $id_public_commands = $ref->{'id_public_commands'};
							my $id_user = $ref->{'id_user'};
							if (($id_user == $iMatchingUserId) || checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Removing command $sCommand");
								$sQuery = "DELETE FROM PUBLIC_COMMANDS WHERE id_public_commands=?";
								my $sth = $dbh->prepare($sQuery);
								unless ($sth->execute($id_public_commands)) {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Command $sCommand removed");
									logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"remcmd",("Command $sCommand removed"));
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command belongs to another user");
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command does not exist");
						}
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: remcmd <command>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " remcmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " remcmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# mvcmd <command_old> <command_new>
sub mbDbMvCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					my $sCommand = $tArgs[0];
					my $sCommandNew = $tArgs[1];
					my $sQuery = "SELECT id_user,id_public_commands FROM PUBLIC_COMMANDS WHERE command LIKE ?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sCommand)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref = $sth->fetchrow_hashref()) {
							my $id_public_commands = $ref->{'id_public_commands'};
							my $id_user = $ref->{'id_user'};
							if (($id_user == $iMatchingUserId) || checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Renaming command $sCommand");
								$sQuery = "UPDATE PUBLIC_COMMANDS SET command=? WHERE id_public_commands=?";
								my $sth = $dbh->prepare($sQuery);
								unless ($sth->execute($sCommandNew,$id_public_commands)) {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Does command $sCommandNew already exists ?");
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Command $sCommand renamed to $sCommandNew");
									logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"mvcmd",("Command $sCommand renamed to $sCommandNew"));
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command belongs to another user");
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command does not exist");
						}
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: mvcmd <command_old> <command_new>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " mvcmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " mvcmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# chowncmd <command> <username>
sub mbChownCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					my $sCommand = $tArgs[0];
					my $sUsername = $tArgs[1];
					my $sQuery = "SELECT nickname,USER.id_user,id_public_commands FROM PUBLIC_COMMANDS,USER WHERE PUBLIC_COMMANDS.id_user=USER.id_user AND command LIKE ?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sCommand)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref = $sth->fetchrow_hashref()) {
							my $id_public_commands = $ref->{'id_public_commands'};
							my $id_user = $ref->{'id_user'};
							my $nickname = $ref->{'nickname'};
							$sQuery = "SELECT id_user,nickname FROM USER WHERE nickname LIKE ?";
							$sth = $dbh->prepare($sQuery);
							unless ($sth->execute($sUsername)) {
								log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
							}
							else {
								if (my $ref = $sth->fetchrow_hashref()) {
									my $id_user_new = $ref->{'id_user'};
									$sQuery = "UPDATE PUBLIC_COMMANDS SET id_user=? WHERE id_public_commands=?";
									$sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_user_new,$id_public_commands)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									}
									else {
										botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Changed owner of command $sCommand ($nickname -> $sUsername)");
										logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"chowncmd",("Changed owner of command $sCommand ($nickname -> $sUsername)"));
									}
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sUsername user does not exist");
								}
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command does not exist");
						}
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chowncmd <command> <username>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " chowncmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " chowncmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# modcmd <command> <message|action> <category> <command reply> 
sub mbDbModCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && (($tArgs[1] =~ /^message$/i) || ($tArgs[1] =~ /^action$/i)) && defined($tArgs[2]) && ($tArgs[2] ne "") && defined($tArgs[3]) && ($tArgs[3] ne "")) {
					my $sCommand = $tArgs[0];
					shift @tArgs;
					my $sType = $tArgs[0];
					shift @tArgs;
					my $sCategory = $tArgs[0];
					shift @tArgs;
					my $sQuery = "SELECT id_public_commands,id_user FROM PUBLIC_COMMANDS WHERE command LIKE ?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sCommand)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref = $sth->fetchrow_hashref()) {
							my $id_user = $ref->{'id_user'};
							my $id_public_commands = $ref->{'id_public_commands'};
							if (($id_user == $iMatchingUserId) || checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
								my $id_public_commands_category = getCommandCategory(\%MAIN_CONF,$LOG,$dbh,$sCategory);
								if (defined($id_public_commands_category)) {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Modifying command $sCommand [$sType] " . join (" ",@tArgs));
									my $sAction;
									if ( $sType =~ /^message$/i ) {
										$sAction = "PRIVMSG %c ";
									}
									elsif ($sType =~ /^action$/i ) {
										$sAction = "ACTION %c ";
									}
									$sAction .= join(" ",@tArgs);
									$sQuery = "UPDATE PUBLIC_COMMANDS SET id_public_commands_category=?,action=? WHERE id_public_commands=?";
									$sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_public_commands_category,$sAction,$id_public_commands)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									}
									else {
										botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Command $sCommand modified");
										logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"modcmd",("Command $sCommand modified"));
									}
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Unknown category : $sCategory");
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command belongs to another user");
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command does not exist");
						}
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modcmd <command> <message|action> <category> <text>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " modcmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " modcmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# addcatcmd <new_category>
sub mbDbAddCategoryCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sCategory = $tArgs[0];
					my $sQuery = "SELECT id_public_commands_category FROM PUBLIC_COMMANDS_CATEGORY WHERE description LIKE ?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sCategory)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref = $sth->fetchrow_hashref()) {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Category $sCategory already exists");
							$sth->finish;
						}
						else {
							# Add category
							$sQuery = "INSERT INTO PUBLIC_COMMANDS_CATEGORY (description) VALUES (?)";
							$sth = $dbh->prepare($sQuery);
							unless ($sth->execute($sCategory)) {
								log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Category $sCategory added");
								logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addcatcmd",("Category $sCategory added"));
							}
						}
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: addcatcmd <new_catgeroy>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " addcatcmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " addcatcmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# chcatcmd <new_category> <command>
sub mbDbChangeCategoryCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					my $sCategory = $tArgs[0];
					my $sQuery = "SELECT id_public_commands_category FROM PUBLIC_COMMANDS_CATEGORY WHERE description LIKE ?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sCategory)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						unless (my $ref = $sth->fetchrow_hashref()) {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Category $sCategory does not exist");
							$sth->finish;
						}
						else {
							my $id_public_commands_category = $ref->{'id_public_commands_category'};
							$sQuery = "SELECT id_public_commands FROM PUBLIC_COMMANDS WHERE command LIKE ?";
							# Change category
							$sth = $dbh->prepare($sQuery);
							unless ($sth->execute($tArgs[1])) {
								log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
							}
							else {
								unless (my $ref = $sth->fetchrow_hashref()) {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Command " . $tArgs[1] . " does not exist");
									$sth->finish;
								}
								else {
									$sQuery = "UPDATE PUBLIC_COMMANDS SET id_public_commands_category=? WHERE command like ?";
									$sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_public_commands_category,$tArgs[1])) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									}
									else {
										botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Changed category to $sCategory for " . $tArgs[1]);
										logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"chcatcmd",("Changed category to $sCategory for " . $tArgs[1]));
									}
								}
							}
						}
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chcatcmd <new_category> <command>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " chcatcmd command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " chcatcmd command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# checkhostchan <hostname>
sub mbDbCheckHostnameNickChan(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sHostname = $tArgs[0];
					my $sQuery = "SELECT nick,count(nick) as hits FROM CHANNEL_LOG,CHANNEL WHERE CHANNEL.id_channel=CHANNEL_LOG.id_channel AND name=? AND userhost like '%!%@" . $sHostname . "' GROUP BY nick ORDER by hits DESC LIMIT 10";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sChannel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						my $sResponse = "Nicks for host $sHostname on $sChannel - ";
						my $i = 0;
						while (my $ref = $sth->fetchrow_hashref()) {
							my $sNickFound = $ref->{'nick'};
							my $sHitsFound = $ref->{'hits'};
							$sResponse .= "$sNickFound ($sHitsFound) ";
							$i++;
						}
						unless ( $i ) {
							$sResponse = "No result found for hostname $sHostname on $sChannel";
						}
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sResponse);
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"checkhostchan",($sHostname));
						$sth->finish;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: checkhostchan <hostname>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " checkhostchan command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " checkhostchan command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# checkhost <hostname>
sub mbDbCheckHostnameNick(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sHostname = $tArgs[0];
					my $sQuery = "SELECT nick,count(nick) as hits FROM CHANNEL_LOG WHERE userhost like '%!%@" . $sHostname . "' GROUP BY nick ORDER by hits DESC LIMIT 10";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute()) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						my $sResponse = "Nicks for host $sHostname - ";
						my $i = 0;
						while (my $ref = $sth->fetchrow_hashref()) {
							my $sNickFound = $ref->{'nick'};
							my $sHitsFound = $ref->{'hits'};
							$sResponse .= "$sNickFound ($sHitsFound) ";
							$i++;
						}
						unless ( $i ) {
							$sResponse = "No result found for hostname : $sHostname";
						}
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sResponse);
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"checkhost",($sHostname));
						$sth->finish;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: checkhost <hostname>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " checkhost command attempt (command level [Master] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " checkhost command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# checknick <nick>
sub mbDbCheckNickHostname(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sNickSearch = $tArgs[0];
					my $sQuery = "SELECT userhost,count(userhost) as hits FROM CHANNEL_LOG WHERE nick LIKE ? GROUP BY userhost ORDER BY hits DESC LIMIT 10";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sNickSearch)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						my $sResponse = "Hostmasks for $sNickSearch - ";
						my $i = 0;
						while (my $ref = $sth->fetchrow_hashref()) {
							my $HostmaskFound = $ref->{'userhost'};
							$HostmaskFound =~ s/^.*!//;
							my $sHitsFound = $ref->{'hits'};
							$sResponse .= "$HostmaskFound ($sHitsFound) ";
							$i++;
						}
						unless ( $i ) {
							$sResponse = "No result found for nick : $sNickSearch";
						}
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sResponse);
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"checknick",($sNickSearch));
						$sth->finish;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: checknick <nick>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " checknick command attempt (command level [Master] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " checknick command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# showcmd <command>
sub mbDbShowCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		my $sCommand = $tArgs[0];
		my $sQuery = "SELECT hits,id_user,creation_date,action,PUBLIC_COMMANDS_CATEGORY.description as category FROM PUBLIC_COMMANDS,PUBLIC_COMMANDS_CATEGORY WHERE PUBLIC_COMMANDS.id_public_commands_category=PUBLIC_COMMANDS_CATEGORY.id_public_commands_category AND command LIKE ?";
		my $sth = $dbh->prepare($sQuery);
		unless ($sth->execute($sCommand)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
		}
		else {
			if (my $ref = $sth->fetchrow_hashref()) {
				my $id_user = $ref->{'id_user'};
				my $sCategory = $ref->{'category'};
				my $sUserHandle = "Unknown";
				my $sCreationDate = $ref->{'creation_date'};
				my $sAction = $ref->{'action'};
				my $hits = $ref->{'hits'};
				my $sHitsWord = ( $hits > 1 ? "$hits hits" : "0 hit" );
				if (defined($id_user)) {
					$sQuery = "SELECT * FROM USER WHERE id_user=?";
					my $sth2 = $dbh->prepare($sQuery);
					unless ($sth2->execute($id_user)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref2 = $sth2->fetchrow_hashref()) {
							$sUserHandle = $ref2->{'nickname'};
						}
					}
					$sth2->finish;
				}
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Command : $sCommand Author : $sUserHandle Created : $sCreationDate");
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sHitsWord Category : $sCategory Action : $sAction");
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command does not exist");
			}
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"showcmd",($sCommand));
		}
		$sth->finish;
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: showcmd <command>");
		return undef;
	}
}

# countcmd <command>
sub mbCountCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT count(*) as nbCommands FROM PUBLIC_COMMANDS";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		my $nbTotalCommands = 0;
		if (my $ref = $sth->fetchrow_hashref()) {
			$nbTotalCommands = $ref->{'nbCommands'};
		}
		$sQuery = "SELECT PUBLIC_COMMANDS_CATEGORY.description as sCategory,count(*) as nbCommands FROM PUBLIC_COMMANDS,PUBLIC_COMMANDS_CATEGORY WHERE PUBLIC_COMMANDS.id_public_commands_category=PUBLIC_COMMANDS_CATEGORY.id_public_commands_category GROUP by PUBLIC_COMMANDS_CATEGORY.description";
		$sth = $dbh->prepare($sQuery);
		unless ($sth->execute()) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
		}
		else {
			my $sNbCommandNotice = "$nbTotalCommands Commands in database : ";
			my $i = 0;
			while (my $ref = $sth->fetchrow_hashref()) {
				my $nbCommands = $ref->{'nbCommands'};
				my $sCategory = $ref->{'sCategory'};
				$sNbCommandNotice .= "($sCategory $nbCommands) ";
				$i++;
			}
			if ( $i ) {
				botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sNbCommandNotice);
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"countcmd",undef);
			}
			else {
				botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"No command in database");
			}
		}
	}
	$sth->finish;
}

# topcmd
sub mbTopCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT command,hits FROM PUBLIC_COMMANDS ORDER BY hits DESC LIMIT 20";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		my $sNbCommandNotice = "Top commands in database : ";
		my $i = 0;
		while (my $ref = $sth->fetchrow_hashref()) {
			my $command = $ref->{'command'};
			my $hits = $ref->{'hits'};
			$sNbCommandNotice .= "$command ($hits) ";
			$i++;
		}
		if ( $i ) {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sNbCommandNotice);
		}
		else {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"No top commands in database");
		}
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"topcmd",undef);
	}
	$sth->finish;
}

# lastcmd
sub mbLastCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT command FROM PUBLIC_COMMANDS ORDER BY creation_date DESC LIMIT 10";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		my $sCommandText;
		while (my $ref = $sth->fetchrow_hashref()) {
			my $command = $ref->{'command'};
			$sCommandText .= " $command";
			
		}
		if (defined($sCommandText) && ($sCommandText ne "")) {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"Last commands in database :$sCommandText");
		}
		else {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"No command found in databse");
		}
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"lastcmd",undef);
	}
	$sth->finish;
}

# searchcmd <keyword>
sub mbDbSearchCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		my $sCommand = $tArgs[0];
		unless ($sCommand =~ /%/) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"sCommand : $sCommand");
			my $sQuery = "SELECT * FROM PUBLIC_COMMANDS WHERE action LIKE '%" . $sCommand . "%' ORDER BY command LIMIT 20";
			my $sth = $dbh->prepare($sQuery);
			unless ($sth->execute()) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			else {
				my $sResponse;
				while (my $ref = $sth->fetchrow_hashref()) {
					my $command = $ref->{'command'};
					$sResponse .= " $command";
				}
				unless(defined($sResponse) && ($sResponse ne "")) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"keyword $sCommand not found in commands");
				}
				else {
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"Commands containing $sCommand : $sResponse");
				}
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"searchcmd",("Commands containing $sCommand"));
			}
			$sth->finish;
		}
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: searchcmd <keyword>");
		return undef;
	}
}

# owncmd
sub mbDbOwnersCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT nickname,count(command) as nbCommands FROM PUBLIC_COMMANDS,USER WHERE PUBLIC_COMMANDS.id_user=USER.id_user GROUP by nickname ORDER BY nbCommands DESC";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		my $sResponse = "Number of commands by user : ";
		my $i = 0;
		while (my $ref = $sth->fetchrow_hashref()) {
			my $nickname = $ref->{'nickname'};
			my $nbCommands = $ref->{'nbCommands'};
			$sResponse .= "$nickname($nbCommands) ";
			$i++;
		}
		unless ( $i ) {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"not found");
		}
		else {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sResponse);
		}
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"owncmd",undef);
	}
	$sth->finish;
	
}

# nick <nick>
sub mbChangeNick(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sNewNick = $tArgs[0];
					shift @tArgs;
					$irc->change_nick( $sNewNick );
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"nick",($sNewNick));
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: nick <nick>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " nick command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " nick command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# addtimer <name> <frequency> <raw>
sub mbAddTimer(@) {
	my ($loop,$TVars,$Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my %hTimers = %$TVars;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "") && ($tArgs[1] =~ /[0-9]+/) && defined($tArgs[2]) && ($tArgs[2] ne "")) {
					my $sTimerName = $tArgs[0];
					shift @tArgs;
					if (exists $hTimers{$sTimerName}) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Timer $sTimerName already exists");
						return %hTimers;
					}
					my $iFrequency = $tArgs[0];
					my $timer;
					shift @tArgs;
					my $sRaw = join(" ",@tArgs);
					$timer = IO::Async::Timer::Periodic->new(
				    interval => $iFrequency,
				    on_tick => sub {
				    	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"Timer every $iFrequency seconds : $sRaw");
    					$irc->write("$sRaw\x0d\x0a");
 						},
					);
					$hTimers{$sTimerName} = $timer;
					$loop->add( $timer );
					$timer->start;
					my $sQuery = "INSERT INTO TIMERS (name,duration,command) VALUES (?,?,?)";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sTimerName,$iFrequency,$sRaw)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Timer $sTimerName added.");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addtimer",("Timer $sTimerName added."));
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: addtimer <name> <frequency> <raw>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " addtimer command attempt (command level [Owner] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " addtimer command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
	return %hTimers;
}

# remtimer <name>
sub mbRemTimer(@) {
	my ($loop,$TVars,$Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my %hTimers = %$TVars;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sTimerName = $tArgs[0];
					shift @tArgs;
					unless (exists $hTimers{$sTimerName}) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Timer $sTimerName does not exist");
						return %hTimers;
					}
					$loop->remove($hTimers{$sTimerName});
					delete $hTimers{$sTimerName};
					my $sQuery = "DELETE FROM TIMERS WHERE name=?";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sTimerName)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Timer $sTimerName removed.");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"remtimer",("Timer $sTimerName removed."));
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: remtimer <name>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " remtimer command attempt (command level [Owner] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " remtimer command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
	return %hTimers;
}

# timers
sub mbTimers(@) {
	my ($TVars,$Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my %hTimers = %$TVars;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				my $sQuery = "SELECT * FROM TIMERS";
				my $sth = $dbh->prepare($sQuery);
				unless ($sth->execute()) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				}
				else {
					my @tTimers;
					my $i = 0;
					while (my $ref = $sth->fetchrow_hashref()) {
						my $id_timers = $ref->{'id_timers'};
						my $name = $ref->{'name'};
						my $duration = $ref->{'duration'};
						my $command = $ref->{'command'};
						my $sSecondText = ( $duration > 1 ? "seconds" : "second" );
						push @tTimers, "$name - id : $id_timers - every $duration $sSecondText - command $command";
						$i++;
					}
					if ( $i ) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Active timers :");
						foreach (@tTimers) {
						  botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$_");
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"No active timers");
					}
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"timers",undef);
				}
				$sth->finish;
			}
			else {
				my $sNoticeMsg = $message->prefix . " timers command attempt (command level [Owner] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " timers command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
	return %hTimers;
}

1;