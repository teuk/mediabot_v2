package Mediabot::Commands;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use POSIX 'setsid';
use Switch;
use Mediabot::Common;
use Mediabot::Core;
use Mediabot::Database;
use Mediabot::Channel;
use Mediabot::User;
use Mediabot::Plugins;

@ISA     = qw(Exporter);
@EXPORT  = qw(getCommandCategory mbChangeNick mbCommandPrivate mbCommandPublic mbDbAddCommand mbDbCommand mbDbModCommand mbDbRemCommand mbDbSearchCommand mbDbShowCommand mbDebug mbJump mbRegister mbRestart mbVersion mbLastCommand);

sub mbCommandPublic(@) {
	my ($NVars,$WVars,$Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$sChannel,$sNick,$sCommand,@tArgs)	= @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	my %hChannelsNicks = %$NVars;
	my $bFound = 0;
	switch($sCommand) {
		case "quit"					{ $bFound = 1;
													mbQuit(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "nick"					{ $bFound = 1;
													mbChangeNick(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
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
		case "adduser"			{ $bFound = 1;
													addUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
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
		case "showcmd"			{ $bFound = 1;
													mbDbShowCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "version"			{ $bFound = 1;
													mbVersion(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$MAIN_PROG_VERSION);
												}
		case "chanstatlines"	{ $bFound = 1;
														channelStatLines(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
													}
		case "countcmd"			{ $bFound = 1;
														mbCountCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "searchcmd"		{ $bFound = 1;
														mbDbSearchCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "lastcmd"			{ $bFound = 1;
														mbLastCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "addcatcmd"		{ $bFound = 1;
														mbDbAddCategoryCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		case "chcatcmd"			{ $bFound = 1;
														mbDbChangeCategoryCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
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
														log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"what $what");
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
		return %WHOIS_VARS;
	}
}

sub mbCommandPrivate(@) {
	my ($NVars,$WVars,$Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$sNick,$sCommand,@tArgs)	= @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	my %hChannelsNicks = %$NVars;
	my $bFound = 0;
	switch($sCommand) {
		case "quit"					{ $bFound = 1;
													mbQuit(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "nick"					{ $bFound = 1;
													mbChangeNick(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
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
		case "nicklist"			{ $bFound = 1;
														channelNickList(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		case "rnick"				{ $bFound = 1;
														randomChannelNick(\%hChannelsNicks,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,undef,@tArgs);
												}
		else								{
												
												}
	}
	unless ( $bFound ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,$message->prefix . " Private command '$sCommand' not found");
		return ();
	}
	else {
		return %WHOIS_VARS;
	}
}

sub mbVersion(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$MAIN_PROG_VERSION) = @_;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"mbVersion() by $sNick on $sChannel");
	botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$MAIN_CONF{'main.MAIN_PROG_NAME'} . " v$MAIN_PROG_VERSION ©2017-2018 TeuK");
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
					return %MAIN_CONF;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : debug <debug_level>");
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
				#if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
				#	$irc->write("QUIT :" . join(" ",@tArgs) . "\x0d\x0a");
				#}
				#else {
				#	$irc->write("QUIT\x0d\x0a");
				#}
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
			my $description = $ref->{'description'};
			my $action = $ref->{'action'};
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
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax addcmd <command> <message|action> <category> <text>");
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
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax remcmd <command>");
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
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax mvcmd <command_old> <command_new>");
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
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax modcmd <command> <message|action> <category> <text>");
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
							}
						}
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax addcatcmd <new_catgeroy>");
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
									}
								}
							}
						}
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax chcatcmd <new_category> <command>");
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

# showcmd <command>
sub mbDbShowCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		my $sCommand = $tArgs[0];
		my $sQuery = "SELECT id_user,creation_date,action,PUBLIC_COMMANDS_CATEGORY.description as category FROM PUBLIC_COMMANDS,PUBLIC_COMMANDS_CATEGORY WHERE PUBLIC_COMMANDS.id_public_commands_category=PUBLIC_COMMANDS_CATEGORY.id_public_commands_category AND command LIKE ?";
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Category : $sCategory Action : $sAction");
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sCommand command does not exist");
			}
		}
		$sth->finish;
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : showcmd <command>");
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
		if (my $ref = $sth->fetchrow_hashref()) {
			my $nbCommands = $ref->{'nbCommands'};
			my $sCommandText = "command";
			if ( $nbCommands > 1 ) {
				$sCommandText .= "s";
			}
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"$nbCommands $sCommandText in database");
		}
		else {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"mbCountCommand() Empty result");
		}
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
			}
			$sth->finish;
		}
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : searchcmd <keyword>");
		return undef;
	}
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

1;