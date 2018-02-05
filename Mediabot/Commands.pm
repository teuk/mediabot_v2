package Mediabot::Commands;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Switch;
use Mediabot::Common;
use Mediabot::Core;
use Mediabot::Database;
use Mediabot::Channel;
use Mediabot::User;

@ISA     = qw(Exporter);
@EXPORT  = qw(mbCommandPrivate mbCommandPublic mbDbCommand mbDebug mbRegister mbVersion);

sub mbCommandPublic(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$sChannel,$sNick,$sCommand,@tArgs)	= @_;
	my %MAIN_CONF = %$Config;
	my $bFound = 0;
	switch($sCommand) {
		case "msg"					{ $bFound = 1;
													msgCmd(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "say"					{ $bFound = 1;
													sayChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "act"					{ $bFound = 1;
													actChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "adduser"			{ $bFound = 1;
													addUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "addchan"			{ $bFound = 1;
													addChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chanset"			{ $bFound = 1;
													channelSet(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "purge"				{ $bFound = 1;
													purgeChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "part"					{ $bFound = 1;
													channelPart(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "join"					{ $bFound = 1;
													channelJoin(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "add"					{ $bFound = 1;
													channelAddUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "del"					{ $bFound = 1;
													channelDelUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "modinfo"			{ $bFound = 1;
													userModinfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "op"						{ $bFound = 1;
													userOpChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "deop"					{ $bFound = 1;
													userDeopChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "invite"				{ $bFound = 1;
													userInviteChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "voice"				{ $bFound = 1;
													userVoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "devoice"			{ $bFound = 1;
													userDevoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "kick"					{ $bFound = 1;
													userKickChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "topic"				{ $bFound = 1;
													userTopicChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "showcommands"	{ $bFound = 1;
													userShowcommandsChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chaninfo"			{ $bFound = 1;
													userChannelInfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "version"			{ $bFound = 1;
													mbVersion(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$MAIN_PROG_VERSION);
												}
		else								{
													$bFound = mbDbCommand(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs);
												}
	}
	unless ( $bFound ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"Public command '$sCommand' not found");
	}
}

sub mbCommandPrivate(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$MAIN_PROG_VERSION,$sNick,$sCommand,@tArgs)	= @_;
	my %MAIN_CONF = %$Config;
	my $bFound = 0;
	switch($sCommand) {
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
		case "adduser"			{ $bFound = 1;
													addUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "addchan"			{ $bFound = 1;
													addChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chanset"			{ $bFound = 1;
													channelSet(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "purge"				{ $bFound = 1;
													purgeChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "part"					{ $bFound = 1;
													channelPart(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "join"					{ $bFound = 1;
													channelJoin(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "add"					{ $bFound = 1;
													channelAddUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "del"					{ $bFound = 1;
													channelDelUser(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "modinfo"			{ $bFound = 1;
													userModinfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "op"						{ $bFound = 1;
													userOpChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "deop"					{ $bFound = 1;
													userDeopChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "invite"				{ $bFound = 1;
													userInviteChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "voice"				{ $bFound = 1;
													userVoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "devoice"			{ $bFound = 1;
													userDevoiceChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "kick"					{ $bFound = 1;
													userKickChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "topic"				{ $bFound = 1;
													userTopicChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "showcommands"	{ $bFound = 1;
													userShowcommandsChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		case "chaninfo"			{ $bFound = 1;
													userChannelInfo(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
												}
		else								{
												
												}
	}
	unless ( $bFound ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,$message->prefix . " Private command '$sCommand' not found");
	}
}

sub mbVersion(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$MAIN_PROG_VERSION) = @_;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"mbVersion() by $sNick on $sChannel");
	botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$MAIN_CONF{'main.MAIN_PROG_NAME'} . " v$MAIN_PROG_VERSION �2017-2018 TeuK");
}

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
					return %MAIN_CONF;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : debug <debug_level>");
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"debug_level 0 to 5");
					return undef;
				}
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs) = @_;
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
}

1;