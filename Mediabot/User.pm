package Mediabot::User;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Date::Format;
use Switch;
use String::IRC;
use Mediabot::Common;
use Mediabot::Core;
use Mediabot::Database;
use Mediabot::Channel;

@ISA     = qw(Exporter);
@EXPORT  = qw(actChannel addChannel addUser addUserHost channelAddUser channelDelUser channelJoin channelList channelNickList channelPart channelSet channelStatLines checkAuth checkUserChannelLevel checkUserLevel dumpCmd getIdUser getIdUserLevel getNickInfo getNickInfoWhois getUserChannelLevel getUserChannelLevelByName getUserLevel logBot msgCmd purgeChannel randomChannelNick registerChannel sayChannel userAdd userAccessChannel userAuthNick userChannelInfo userCount userCstat userDeopChannel userDevoiceChannel userGreet userIdent userInfo userInviteChannel userKickChannel userLogin userModinfo userNewPass userOnJoin userOpChannel userPass userShowcommandsChannel userStats userTopicChannel userTopSay userVerifyNick userVoiceChannel userWhoAmI whoTalk);

sub userCount(@) {
	my ($Config,$LOG,$dbh) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT count(*) as nbUser FROM USER";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"userCount() " . $ref->{'nbUser'});
			my $nbUser = $ref->{'nbUser'};
			$sth->finish;
			return($nbUser);
		}
		else {
			$sth->finish;
			return 0;
		}
	}
}

sub getIdUserLevel(@) {
	my ($Config,$LOG,$dbh,$sLevel) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT id_user_level FROM USER_LEVEL WHERE description like ?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sLevel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $id_user_level = $ref->{'id_user_level'};
			$sth->finish;
			return $id_user_level;
		}
		else {
			$sth->finish;
			return undef;
		}
	}
}

sub userAdd(@) {
	my ($Config,$LOG,$dbh,$sHostmask,$sUserHandle,$sPassword,$sLevel) = @_;
	my %MAIN_CONF = %$Config;
	unless (defined($sHostmask) && ($sHostmask =~ /^.+@.+/)) {
		return undef;
	}
	my $id_user_level = getIdUserLevel(\%MAIN_CONF,$LOG,$dbh,$sLevel);
	if (defined($sPassword) && ($sPassword ne "")) {
		my $sQuery = "INSERT INTO USER (hostmasks,nickname,password,id_user_level) VALUES (?,?,PASSWORD(?),?)";
		my $sth = $dbh->prepare($sQuery);
		unless ($sth->execute($sHostmask,$sUserHandle,$sPassword,$id_user_level)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			return undef;
		}
		else {
			my $id_user = $sth->{ mysql_insertid };
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"userAdd() Added user : $sUserHandle with hostmask : $sHostmask id_user : $id_user as $sLevel password set : yes");
			return ($id_user);
		}
		$sth->finish;
	}
	else {
		my $sQuery = "INSERT INTO USER (hostmasks,nickname,id_user_level) VALUES (?,?,?)";
		my $sth = $dbh->prepare($sQuery);
		unless ($sth->execute($sHostmask,$sUserHandle,$id_user_level)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			return undef;
		}
		else {
			my $id_user = $sth->{ mysql_insertid };
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Added user : $sUserHandle with hostmask : $sHostmask id_user : $id_user as $sLevel password set : no");
			return ($id_user);
		}
		$sth->finish;
	}
}

sub getNickInfo(@) {
	my ($Config,$LOG,$dbh,$message) = @_;
	my %MAIN_CONF = %$Config;
	my $iMatchingUserId;
	my $iMatchingUserLevel;
	my $iMatchingUserLevelDesc;
	my $iMatchingUserAuth;
	my $sMatchingUserHandle;
	my $sMatchingUserPasswd;
	my $sMatchingUserInfo1;
	my $sMatchingUserInfo2;
	
	my $sCheckQuery = "SELECT * FROM USER";
	my $sth = $dbh->prepare($sCheckQuery);
	unless ($sth->execute ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"getNickInfo() SQL Error : " . $DBI::errstr . " Query : " . $sCheckQuery);
	}
	else {	
		while (my $ref = $sth->fetchrow_hashref()) {
			my @tHostmasks = split(/,/,$ref->{'hostmasks'});
			foreach my $sHostmask (@tHostmasks) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() Checking hostmask : " . $sHostmask);
				$sHostmask =~ s/\./\\./g;
				$sHostmask =~ s/\*/.*/g;
				$sHostmask =~ s/\[/\\[/g;
				$sHostmask =~ s/\]/\\]/g;
				$sHostmask =~ s/\{/\\{/g;
				$sHostmask =~ s/\}/\\}/g;
				if ( $message->prefix =~ /^$sHostmask/ ) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getNickInfo() $sHostmask matches " . $message->prefix);
					$sMatchingUserHandle = $ref->{'nickname'};
					if (defined($ref->{'password'})) {
						$sMatchingUserPasswd = $ref->{'password'};
					}
					$iMatchingUserId = $ref->{'id_user'};
					my $iMatchingUserLevelId = $ref->{'id_user_level'};
					my $sGetLevelQuery = "SELECT * FROM USER_LEVEL WHERE id_user_level=?";
					my $sth2 = $dbh->prepare($sGetLevelQuery);
				        unless ($sth2->execute($iMatchingUserLevelId)) {
                				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"getNickInfo() SQL Error : " . $DBI::errstr . " Query : " . $sGetLevelQuery);
        				}
        				else {
               					while (my $ref2 = $sth2->fetchrow_hashref()) {
							$iMatchingUserLevel = $ref2->{'level'};
							$iMatchingUserLevelDesc = $ref2->{'description'};
						}
					}
					$iMatchingUserAuth = $ref->{'auth'};
					if (defined($ref->{'info1'})) {
						$sMatchingUserInfo1 = $ref->{'info1'};
					}
					if (defined($ref->{'info2'})) {
						$sMatchingUserInfo2 = $ref->{'info2'};
					}
				}
			}
		}
	}
	$sth->finish;
	if (defined($iMatchingUserId)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getNickInfo() iMatchingUserId : $iMatchingUserId");
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getNickInfo() iMatchingUserId is undefined with this host : " . $message->prefix);
		return (undef,undef,undef,undef,undef,undef,undef);
	}
	if (defined($iMatchingUserLevel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() iMatchingUserLevel : $iMatchingUserLevel");
	}
	if (defined($iMatchingUserLevelDesc)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() iMatchingUserLevelDesc : $iMatchingUserLevelDesc");
	}
	if (defined($iMatchingUserAuth)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() iMatchingUserAuth : $iMatchingUserAuth");
	}
	if (defined($sMatchingUserHandle)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() sMatchingUserHandle : $sMatchingUserHandle");
	}
	if (defined($sMatchingUserPasswd)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() sMatchingUserPasswd : $sMatchingUserPasswd");
	}
	if (defined($sMatchingUserInfo1)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() sMatchingUserInfo1 : $sMatchingUserInfo1");
	}
	if (defined($sMatchingUserInfo2)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfo() sMatchingUserInfo2 : $sMatchingUserInfo2");
	}
	
	return ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2);
}

sub checkAuth(@) {
	my ($Config,$LOG,$dbh,$iUserId,$sUserHandle,$sPassword) = @_;
	my %MAIN_CONF = %$Config;
	my $sCheckAuthQuery = "SELECT * FROM USER WHERE id_user=? AND nickname=? AND password=PASSWORD(?)";
	my $sth = $dbh->prepare($sCheckAuthQuery);
	unless ($sth->execute($iUserId,$sUserHandle,$sPassword)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuth() SQL Error : " . $DBI::errstr . " Query : " . $sCheckAuthQuery);
		return 0;
	}
	else {	
		if (my $ref = $sth->fetchrow_hashref()) {
			my $sQuery = "UPDATE USER SET auth=1 WHERE id_user=?";
			my $sth2 = $dbh->prepare($sQuery);
			unless ($sth2->execute($iUserId)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuth() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				return 0;
			}
			$sQuery = "UPDATE USER SET last_login=? WHERE id_user =?";
			$sth = $dbh->prepare($sQuery);
			unless ($sth->execute(time2str("%Y-%m-%d %H-%M-%S",time),$iUserId)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuth() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			return 1;
		}
		else {
			return 0;
		}
	}
	$sth->finish;
}

# ident username password
sub checkAuthByUser(@) {
	my ($Config,$LOG,$dbh,$message,$sUserHandle,$sPassword) = @_;
	my %MAIN_CONF = %$Config;
	my $sCheckAuthQuery = "SELECT * FROM USER WHERE nickname=? AND password=PASSWORD(?)";
	my $sth = $dbh->prepare($sCheckAuthQuery);
	unless ($sth->execute($sUserHandle,$sPassword)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuthByUser() SQL Error : " . $DBI::errstr . " Query : " . $sCheckAuthQuery);
		$sth->finish;
		return 0;
	}
	else {	
		if (my $ref = $sth->fetchrow_hashref()) {
			my $sHostmask = getMessageHostmask($message);
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"checkAuthByUser() Hostmask : $sHostmask to add to $sUserHandle");
			my $sCurrentHostmasks = $ref->{'hostmasks'};
			my $id_user = $ref->{'id_user'};
			if ( $sCurrentHostmasks =~ /\Q$sHostmask/ ) {
				return ($id_user,1);
			}
			else {
				my $sNewHostmasks = "$sCurrentHostmasks,$sHostmask";
				my $Query = "UPDATE USER SET hostmasks=? WHERE id_user=?";
				my $sth = $dbh->prepare($Query);
				unless ($sth->execute($sNewHostmasks,$id_user)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuthByUser() SQL Error : " . $DBI::errstr . " Query : " . $Query);
					$sth->finish;
					return (0,0);
				}
				$sth->finish;
				return ($id_user,0);
			}
		}
		else {
			$sth->finish;
			return (0,0);
		}
	}
}

sub checkUserLevel(@) {
	my ($Config,$LOG,$dbh,$iUserLevel,$sLevelRequired) = @_;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"isUserLevel() $iUserLevel vs $sLevelRequired");
	my $sQuery = "SELECT level FROM USER_LEVEL WHERE description like ?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sLevelRequired)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $level = $ref->{'level'};
			if ( $iUserLevel <= $level ) {
				$sth->finish;
				return 1;
			}
			else {
				$sth->finish;
				return 0;
			}
		}
		else {
			$sth->finish;
			return 0;
		}
	}
}

sub getUserLevel(@) {
	my ($Config,$LOG,$dbh,$level) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT description FROM USER_LEVEL WHERE level=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($level)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $sDescription = $ref->{'description'};
			$sth->finish;
			return $sDescription;
		}
		else {
			$sth->finish;
			return undef;
		}
	}
}

sub getIdUser(@) {
	my ($Config,$LOG,$dbh,$sUserHandle) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT id_user FROM USER WHERE nickname=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sUserHandle)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $id_user = $ref->{'id_user'};
			$sth->finish;
			return $id_user;
		}
		else {
			$sth->finish;
			return undef;
		}
	}
}

sub getIdUserChannelLevel(@) {
	my ($Config,$LOG,$dbh,$sUserHandle,$sChannel) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT USER.id_user,USER_CHANNEL.level FROM CHANNEL,USER,USER_CHANNEL WHERE CHANNEL.id_channel=USER_CHANNEL.id_channel AND USER.id_user=USER_CHANNEL.id_user AND USER.nickname=? AND CHANNEL.name=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sUserHandle,$sChannel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $id_user = $ref->{'id_user'};
			my $level = $ref->{'level'};
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getIdUserChannelLevel() $id_user $level");
			$sth->finish;
			return ($id_user,$level);
		}
		else {
			$sth->finish;
			return (undef,undef);
		}
	}
}

# log commands in ACTIONS_LOG
sub logBot(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$action,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	my $sHostmask = $message->prefix;
	my $id_user = undef;
	my $sUser = "Unknown user";
	if (defined($iMatchingUserId)) {
		$id_user = $iMatchingUserId;
		$sUser = $sMatchingUserHandle;
	}
	my $id_channel = undef;
	if (defined($sChannel)) {
		$id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
	}
	my $sQuery = "INSERT INTO ACTIONS_LOG (ts,id_user,id_channel,hostmask,action,args) VALUES (?,?,?,?,?,?)";
	my $sth = $dbh->prepare($sQuery);
	unless (defined($tArgs[0])) {
		$tArgs[0] = "";
	}
	unless ($sth->execute(time2str("%Y-%m-%d %H-%M-%S",time),$id_user,$id_channel,$sHostmask,$action,join(" ",@tArgs))) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"logBot() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		my $sNoticeMsg = "($sUser : $sHostmask) command $action";
		if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
			$sNoticeMsg .= " " . join(" ",@tArgs);
		}
		if (defined($sChannel)) {
			$sNoticeMsg .= " on $sChannel";
		}
		noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"logBot() $sNoticeMsg");
	}
	$sth->finish;
}

#login username password
sub userLogin(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	#login <username> <password>
	if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
		my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
		if (defined($iMatchingUserId)) {
			unless (defined($sMatchingUserPasswd)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your password is not set. Use /msg " . $irc->nick_folded() . " pass password");
			}
			else {
				if (checkAuth(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserId,$tArgs[0],$tArgs[1])) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Login successfull as $sMatchingUserHandle (Level : $iMatchingUserLevelDesc)");
					my $sNoticeMsg = $message->prefix . " Successfull login as $sMatchingUserHandle (Level : $iMatchingUserLevelDesc)";
					noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"login",($tArgs[0],"Success"));
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Login failed (Bad password).");
					my $sNoticeMsg = $message->prefix . " Failed login (Bad password)";
					noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"login",($tArgs[0],"Failed (Bad password)"));
				}
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " Failed login (hostmask may not be present in database)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"login",($tArgs[0],"Failed (Bad hostmask)"));
		}
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax error : /msg " . $irc->nick_folded . " login <username> <password>");
	}
}

#login username password
sub userIdent(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	#login <username> <password>
	if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
		my ($id_user,$bAlreadyExists) = checkAuthByUser(\%MAIN_CONF,$LOG,$dbh,$message,$tArgs[0],$tArgs[1]);
		if ( $bAlreadyExists ) {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"This hostmask is already set");
		}
		elsif ( $id_user ) {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Ident successfull as " . $tArgs[0] . " new hostmask added");
			my $sNoticeMsg = $message->prefix . " Ident successfull from $sNick as " . $tArgs[0] . " id_user : $id_user";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"ident",$tArgs[0]);
		}
		else {
			my $sNoticeMsg = $message->prefix . " Ident failed (Bad password)";
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,$sNoticeMsg);
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"ident",$sNoticeMsg);
		}
	}
}

#pass <password>
sub userPass(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
		if (defined($iMatchingUserId) && (defined($sMatchingUserHandle))) {
			my $sQuery = "UPDATE USER SET password=PASSWORD(?) WHERE id_user=?";
			my $sth = $dbh->prepare($sQuery);
			unless ($sth->execute($tArgs[0],$iMatchingUserId)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				$sth->finish;
				return 0;
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"userPass() Set password for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")");
				my $sNoticeMsg = "Set password for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Password set.");
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You may now login with /msg " . $irc->nick_folded . " login $sMatchingUserHandle password");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"pass","Success");
				$sth->finish;
				return 1;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " Failed pass command, unknown user $sNick (" . $message->prefix . ")";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"pass","Failed unknown user $sNick");
			return 0;
		}
	}
}

#newpass <password>
sub userNewPass(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
		if (defined($iMatchingUserId) && (defined($sMatchingUserHandle))) {
			my $sQuery = "UPDATE USER SET password=PASSWORD(?) WHERE id_user=?";
			my $sth = $dbh->prepare($sQuery);
			unless ($sth->execute($tArgs[0],$iMatchingUserId)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				$sth->finish;
				return 0;
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"userNewPass() Set password for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")");
				my $sNoticeMsg = "Set password (newpass) for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Password set.");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"newpass","Success");
				$sth->finish;
				return 1;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " Failed newpass command, unknown user $sNick (" . $message->prefix . ")";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"newpass",$sNoticeMsg);
			return 0;
		}
	}
}

#adduser [-n] <username> <hostmask> [level]
sub addUser(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $bNotify = 0;
	if (defined($tArgs[0]) && ($tArgs[0] eq "-n")) {
		$bNotify = 1;
		shift @tArgs;
	}
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"addUser() " . $tArgs[0] . " " . $tArgs[1]);
					my $id_user = getIdUser(\%MAIN_CONF,$LOG,$dbh,$tArgs[0]);
					if (defined($id_user)) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User " . $tArgs[0] . " already exists (id_user : $id_user)");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"adduser","User " . $tArgs[0] . " already exists (id_user : $id_user)");
						return undef;
					}
					my $sLevel = "User";
					if (defined($tArgs[2]) && ($tArgs[2] ne "")) {
						if (defined(getIdUserLevel(\%MAIN_CONF,$LOG,$dbh,$tArgs[2]))) {
							$sLevel = $tArgs[2];
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$tArgs[2] . " is not a valid user level");
							return undef;
						}
					}
					if ((getUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel) eq "Master") && ($sLevel eq "Owner")) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Masters cannot add a user with Owner level");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"adduser","Masters cannot add a user with Owner level");
						return undef;
					}
					$id_user = userAdd(\%MAIN_CONF,$LOG,$dbh,$tArgs[1],$tArgs[0],undef,$sLevel);
					if (defined($id_user)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"addUser() id_user : $id_user " . $tArgs[0] . " Hostmask : " . $tArgs[1] . " (Level:" . $sLevel . ")");
						noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,"Added user " . $tArgs[0] . " id_user : $id_user with hostmask " . $tArgs[1] . " (Level:" . $sLevel .")");
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Added user " . $tArgs[0] . " id_user : $id_user with hostmask " . $tArgs[1] . " (Level:" . $sLevel .")");
						if ( $bNotify ) {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$tArgs[0],"You've been added to " . $irc->nick_folded . " as user " . $tArgs[0] . " (Level : " . $sLevel . ")");
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$tArgs[0],"/msg " . $irc->nick_folded . " pass password");
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$tArgs[0],"replace 'password' with something strong and that you won't forget :p");
						}
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"adduser","Added user " . $tArgs[0] . " id_user : $id_user with hostmask " . $tArgs[1] . " (Level:" . $sLevel .")");
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Could not add user " . $tArgs[0]);
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: adduser [-n] <username> <hostmask> [level]");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix;
				$sNoticeMsg .= " adduser command attempt, (command level [1] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"This command is not available for your level. Contact a bot master.");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"adduser",$sNoticeMsg);
			}
		}
		else {
			my $sNoticeMsg = $message->prefix;
			$sNoticeMsg .= " adduser command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command : /msg " . $irc->nick_folded . " login username password");
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"adduser",$sNoticeMsg);
		}
	}
}

sub dumpCmd(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Owner")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sDumpCommand = join(" ",@tArgs);
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a dump command : $sDumpCommand");
					$irc->write("$sDumpCommand\x0d\x0a");
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"dump",@tArgs);
    		}
    		else {
    			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax error : dump <irc raw command>");
    		}
    	}
    	else {
    		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
}

# msg <target> <text>
sub msgCmd(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					my $sTarget = $tArgs[0];
					shift @tArgs;
					my $sMsg = join(" ",@tArgs);
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a msg command : $sTarget $sMsg");
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sTarget,$sMsg);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"msg",($sTarget,@tArgs));
    		}
    		else {
    			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax error : msg <target> <text>");
    		}
    	}
    	else {
    		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
}

# say #channel <message>
sub sayChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "") && ( $tArgs[0] =~ /^#/)) {
					my (undef,@tArgsTemp) = @tArgs;
					my $sChannelText = join(" ",@tArgsTemp);
					log_message(0,"$sNick issued a say command : " . $tArgs[0] . " $sChannelText");
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$tArgs[0],$sChannelText);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"say",@tArgs);
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: say <#channel> <text>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " say command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " say command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
}

# act #channel <text>
sub actChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "") && ( $tArgs[0] =~ /^#/)) {
					my (undef,@tArgsTemp) = @tArgs;
					my $sChannelText = join(" ",@tArgsTemp);
					log_message(0,"$sNick issued a act command : " . $tArgs[0] . "ACTION $sChannelText");
					botAction(\%MAIN_CONF,$LOG,$dbh,$irc,$tArgs[0],$sChannelText);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"act",@tArgs);
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: act <#channel> <text>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " act command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " act command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
}

# addchan #channel <user>
sub addChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/) && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					my $sChannel = $tArgs[0];
					my $sUser = $tArgs[1];
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued an addchan command $sChannel $sUser");
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					unless (defined($id_channel)) {
						my $id_user = getIdUser(\%MAIN_CONF,$LOG,$dbh,$sUser);
						if (defined($id_user)) {
							my $sQuery = "INSERT INTO CHANNEL (name,description,auto_join) VALUES (?,?,1)";
							my $sth = $dbh->prepare($sQuery);
							unless ($sth->execute($sChannel,$sChannel)) {
								log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
								$sth->finish;
								return undef;
							}
							else {
								my $id_channel = $sth->{ mysql_insertid };
								log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"addChannel() Added channel : $sChannel id_channel : $id_channel");
								my $sNoticeMsg = $message->prefix . " addchan command $sMatchingUserHandle added $sChannel (id_channel : $id_channel)";
								noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
								logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addchan",($sChannel,@tArgs));
								joinChannel($irc,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$sChannel,undef);
								if (registerChannel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$id_channel,$id_user)) {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"registerChannel successfull $sChannel $sUser");
								}
								else {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"registerChannel failed $sChannel $sUser");
								}
								$sth->finish;
								return $id_channel;
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User $sUser does not exist");
							return undef;
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel already exists");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: addchan <#channel> <user>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " addchan command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " addchan command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# chanset #channel key <key>
# chanset #channel chanmode <+chanmode>
# chanset #channel description <description>
# chanset #channel auto_join <on|off>
sub channelSetSyntax(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset [#channel] key <key>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset [#channel] chanmode <+chanmode>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset [#channel] description <description>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset [#channel] auto_join <on|off>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset [#channel] <+value|-value>");
}

sub channelSet(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				channelSetSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,450))) {
				if ( (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) || (defined($tArgs[0]) && ($tArgs[0] ne "") && ((substr($tArgs[0],0,1) eq "+") || (substr($tArgs[0],0,1) eq "-"))) ) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						switch($tArgs[0]) {
							case "key"					{
																		my $sQuery = "UPDATE CHANNEL SET `key`=? WHERE id_channel=?";
																		my $sth = $dbh->prepare($sQuery);
																		unless ($sth->execute($tArgs[1],$id_channel)) {
																			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																			$sth->finish;
																			return undef;
																		}
																		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel key " . $tArgs[1]);
																		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,@tArgs));
																		$sth->finish;
																		return $id_channel;
																	}
							case "chanmode"			{
																		my $sQuery = "UPDATE CHANNEL SET chanmode=? WHERE id_channel=?";
																		my $sth = $dbh->prepare($sQuery);
																		unless ($sth->execute($tArgs[1],$id_channel)) {
																			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																			$sth->finish;
																			return undef;
																		}
																		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel chanmode " . $tArgs[1]);
																		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,@tArgs));
																		$sth->finish;
																		return $id_channel;
																	}
							case "auto_join"		{
																		my $bAutoJoin;
																		if ( $tArgs[1] =~ /on/i ) {
																			$bAutoJoin = 1;
																		}
																		elsif ( $tArgs[1] =~ /off/i ) {
																			$bAutoJoin = 0;
																		}
																		else {
																			channelSetSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
																			return undef;
																		}
																		my $sQuery = "UPDATE CHANNEL SET auto_join=? WHERE id_channel=?";
																		my $sth = $dbh->prepare($sQuery);
																		unless ($sth->execute($bAutoJoin,$id_channel)) {
																			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																			$sth->finish;
																			return undef;
																		}
																		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel auto_join " . $tArgs[1]);
																		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,@tArgs));
																		$sth->finish;
																		return $id_channel;
																	}
							case "description"	{
																		shift @tArgs;
																		unless ( $tArgs[0] =~ /console/i ) {
																			my $sQuery = "UPDATE CHANNEL SET description=? WHERE id_channel=?";
																			my $sth = $dbh->prepare($sQuery);
																			unless ($sth->execute(join(" ",@tArgs),$id_channel)) {
																				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																				$sth->finish;
																				return undef;
																			}
																			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel description " . join(" ",@tArgs));
																			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,"description",@tArgs));
																			$sth->finish;
																			return $id_channel;
																		}
																		else {
																			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You cannot set $sChannel description to " . $tArgs[0]);
																			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",("You cannot set $sChannel description to " . $tArgs[0]));
																		}
																	}
							else								{
																		if ((substr($tArgs[0],0,1) eq "+") || (substr($tArgs[0],0,1) eq "-")){
																			my $sChansetValue = substr($tArgs[0],1);
																			my $sChansetAction = substr($tArgs[0],0,1);
																			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"chansetFlag $sChannel $sChansetAction$sChansetValue");
																			my $id_chanset_list = getIdChansetList(\%MAIN_CONF,$LOG,$dbh,$sChansetValue);
																			unless (defined($id_chanset_list)) {
																				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Undefined flag $sChansetValue");
																				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,"Undefined flag $sChansetValue"));
																				return undef;
																			}
																			my $id_channel_set = getIdChannelSet(\%MAIN_CONF,$LOG,$dbh,$sChannel,$id_chanset_list);
																			if ( $sChansetAction eq "+" ) {
																				if (defined($id_channel_set)) {
																					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Flag +$sChansetValue is already set for $sChannel");
																					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",("Flag +$sChansetValue is already set"));
																					return undef;
																				}
																				my $sQuery = "INSERT INTO CHANNEL_SET (id_channel,id_chanset_list) VALUES (?,?)";
																				my $sth = $dbh->prepare($sQuery);
																				unless ($sth->execute($id_channel,$id_chanset_list)) {
																					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																				}
																				else {
																					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",("Flag $sChansetValue set"));
																				}
																				$sth->finish;
																				return $id_channel;
																			}
																			else {
																				unless (defined($id_channel_set)) {
																					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Flag $sChansetValue is not set for $sChannel");
																					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",("Flag $sChansetValue is not set"));
																					return undef;
																				}
																				my $sQuery = "DELETE FROM CHANNEL_SET WHERE id_channel_set=?";
																				my $sth = $dbh->prepare($sQuery);
																				unless ($sth->execute($id_channel_set)) {
																					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																				}
																				else {
																					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",("Flag $sChansetValue unset"));
																				}
																				$sth->finish;
																				return $id_channel;
																			}
																			
																		}
																		else {
																			channelSetSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
																			return undef;
																		}
																	}
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					channelSetSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " chanset command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " chanset command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# modinfo #channel automode <user> <voice|op|none>
# modinfo #channel greet <user> <greet>
# modinfo #channel level <user> <level>
sub userModinfoSyntax(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modinfo [#channel] automode <user> <voice|op|none>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modinfo [#channel] greet <user> <greet>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modinfo [#channel] level <user> <level>");
}

sub userModinfo(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				userModinfoSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,400))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "") && defined($tArgs[2]) && ($tArgs[2] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						my ($id_user,$level) = getIdUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$tArgs[1],$sChannel);
						if (defined($id_user)) {
							my (undef,$iMatchingUserLevelChannel) = getIdUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$sMatchingUserHandle,$sChannel);
							if (($iMatchingUserLevelChannel > $level) || (checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator"))) {
								switch($tArgs[0]) {
									case "automode"			{
																				my $sAutomode = $tArgs[2];
																				if ( ($sAutomode =~ /op/i ) || ($sAutomode =~ /voice/i) || ($sAutomode =~ /none/i)) {
																					$sAutomode = uc($sAutomode);
																					my $sQuery = "UPDATE USER_CHANNEL SET automode=? WHERE id_user=? AND id_channel=?";
																					my $sth = $dbh->prepare($sQuery);
																					unless ($sth->execute($sAutomode,$id_user,$id_channel)) {
																						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"userModinfo() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																						$sth->finish;
																						return undef;
																					}
																					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set automode $sAutomode on $sChannel for " . $tArgs[1]);
																					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"modinfo",@tArgs);
																					$sth->finish;
																					return $id_channel;
																												}
																					
																				else {
																					userModinfoSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
																					return undef;
																				}
																			}
									case "greet"				{
																				my $sUser = $tArgs[1];
																				splice @tArgs,0,2;
																				my $sGreet = join(" ",@tArgs);
																				my $sQuery = "UPDATE USER_CHANNEL SET greet=? WHERE id_user=? AND id_channel=?";
																				my $sth = $dbh->prepare($sQuery);
																				unless ($sth->execute($sGreet,$id_user,$id_channel)) {
																					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"userModinfo() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																					$sth->finish;
																					return undef;
																				}
																				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set greet ($sGreet) on $sChannel for $sUser");
																				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"modinfo",("greet $sUser",@tArgs));
																				$sth->finish;
																				return $id_channel;
																			}
									case "level"				{
																				my $sUser = $tArgs[1];
																				if ( $tArgs[2] =~ /[0-9]+/ ) {
																					if ( $tArgs [2] <= 500 ) {
																						my $sQuery = "UPDATE USER_CHANNEL SET level=? WHERE id_user=? AND id_channel=?";
																						my $sth = $dbh->prepare($sQuery);
																						unless ($sth->execute($tArgs[2]	,$id_user,$id_channel)) {
																							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"userModinfo() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																							$sth->finish;
																							return undef;
																						}
																						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set level " . $tArgs[2] . " on $sChannel for $sUser");
																						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"modinfo",@tArgs);
																						$sth->finish;
																						return $id_channel;
																					}
																					else {
																						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Cannot set user access higher than 500.");
																					}
																				}
																				else {
																					userModinfoSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
																					return undef;
																				}
																			}
									else								{
																				userModinfoSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
																				return undef;
																			}
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Cannot modify a user with equal or higher access than your own.");
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User " . $tArgs[1] . " does not exist on $sChannel");
							return undef;
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					userModinfoSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " modinfo command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " modinfo command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

sub userOnJoin(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		my $sChannelUserQuery = "SELECT * FROM USER_CHANNEL,CHANNEL WHERE USER_CHANNEL.id_channel=CHANNEL.id_channel AND name=? AND id_user=?";
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,$sChannelUserQuery);
		my $sth = $dbh->prepare($sChannelUserQuery);
		unless ($sth->execute($sChannel,$iMatchingUserId)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"on_join() SQL Error : " . $DBI::errstr . " Query : " . $sChannelUserQuery);
		}
		else {
			if (my $ref = $sth->fetchrow_hashref()) {
				my $sAutoMode = $ref->{'automode'};
				if (defined($sAutoMode) && ($sAutoMode ne "")) {
					if ($sAutoMode eq 'OP') {
						$irc->send_message("MODE", undef, ($sChannel,"+o",$sNick));
					}
					elsif ($sAutoMode eq 'VOICE') {
						$irc->send_message("MODE", undef, ($sChannel,"+v",$sNick));
					}
				}
				my $sGreetChan = $ref->{'greet'};
				if (defined($sGreetChan) && ($sGreetChan ne "")) {
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"($sMatchingUserHandle) $sGreetChan");
				}
			}
		}
		$sth->finish;
	}
}


# part #channel
sub channelPart(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (!defined($sChannel) || (defined($tArgs[0]) && ($tArgs[0] ne ""))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					$sChannel = $tArgs[0];
					shift @tArgs;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: part <#channel>");
					return undef;
				}
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,500))) {
				my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
				if (defined($id_channel)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a part $sChannel command");
					partChannel($irc,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$sChannel,"At the request of $sMatchingUserHandle");
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"part","At the request of $sMatchingUserHandle");
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " part command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " part command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# join #channel
sub channelJoin(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
				if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,450))) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a join $sChannel command");
						my $sKey;
						my $sQuery = "SELECT `key` FROM CHANNEL WHERE id_channel=?";
						my $sth = $dbh->prepare($sQuery);
						unless ($sth->execute($id_channel)) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
						}
						else {
							if (my $ref = $sth->fetchrow_hashref()) {
								$sKey = $ref->{'key'};
							}
						}
						if (defined($sKey) && ($sKey ne "")) {
							joinChannel($irc,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$sChannel,$sKey);
						}
						else {
							joinChannel($irc,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$sChannel,undef);
						}
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"join","");
						$sth->finish;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					my $sNoticeMsg = $message->prefix . " join command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
					noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
					return undef;
				}
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: join <#channel>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " join command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# add <#channel> <handle> <level>
sub channelAddUser(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: add <#channel> <handle> <level>");
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,400))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] =~ /[0-9]+/)) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a add user $sChannel command");
						my $sUserHandle = $tArgs[0];
						my $iLevel = $tArgs[1];
						my $id_user = getIdUser(\%MAIN_CONF,$LOG,$dbh,$tArgs[0]);
						if (defined($id_user)) {
							my $iCheckUserLevel = getUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$id_user);
							if ( $iCheckUserLevel == 0 ) {
								if ( $iLevel < getUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId) || checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
									my $sQuery = "INSERT INTO USER_CHANNEL (id_user,id_channel,level) VALUES (?,?,?)";
									my $sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_user,$id_channel,$iLevel)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									}
									else {
										logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"add",@tArgs);
									}
									$sth->finish;
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You can't add a user with a level equal or greater than yours");
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User $sUserHandle on $sChannel already added at level $iCheckUserLevel");
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User $sUserHandle does not exist");
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: add <#channel> <handle> <level>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " add user command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " add user command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
}

# del <#channel> <handle>
sub channelDelUser(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: del <#channel> <handle>");
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,400))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a del user $sChannel command");
						my $sUserHandle = $tArgs[0];
						my $id_user = getIdUser(\%MAIN_CONF,$LOG,$dbh,$tArgs[0]);
						if (defined($id_user)) {
							my $iCheckUserLevel = getUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$id_user);
							if ( $iCheckUserLevel != 0 ) {
								if ( $iCheckUserLevel < getUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId) || checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
									my $sQuery = "DELETE FROM USER_CHANNEL WHERE id_user=? AND id_channel=?";
									my $sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_user,$id_channel)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									}
									else {
										logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"del",@tArgs);
									}
									$sth->finish;
								}
								else {
									botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You can't del a user with a level equal or greater than yours");
								}
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User $sUserHandle does not appear to have access on $sChannel");
							}
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User $sUserHandle does not exist");
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: del <#channel> <handle>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " del user command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " del user command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
		}
	}
}

sub registerChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$id_channel,$id_user) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "INSERT INTO USER_CHANNEL (id_user,id_channel,level) VALUES (?,?,500)";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($id_user,$id_channel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
		$sth->finish;
		return 0;
	}
	else {
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"registerChannel","$sNick registered user : $id_user level 500 on channel : $id_channel");
		$sth->finish;
		return 1;
	}
}

sub checkUserChannelLevel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$id_user,$level) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT level FROM CHANNEL,USER_CHANNEL WHERE CHANNEL.id_channel=USER_CHANNEL.id_channel AND name=? AND id_user=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel,$id_user)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $iLevel = $ref->{'level'};
			if ( $iLevel >= $level ) {
				$sth->finish;
				return 1;
			}
			else {
				$sth->finish;
				return 0;
			}
		}
		else {
			$sth->finish;
			return 0;
		}
	}	
}

sub getUserChannelLevel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$id_user) = @_;
	my %MAIN_CONF = %$Config;
	my $sQuery = "SELECT level FROM CHANNEL,USER_CHANNEL WHERE CHANNEL.id_channel=USER_CHANNEL.id_channel AND name=? AND id_user=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel,$id_user)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $iLevel = $ref->{'level'};
			$sth->finish;
			return $iLevel;
		}
		else {
			$sth->finish;
			return 0;
		}
	}	
}

# purge <#channel>
sub purgeChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					my $sChannel = $tArgs[0];
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued an purge command $sChannel");
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						my $sQuery = "SELECT * FROM CHANNEL WHERE id_channel=?";
						my $sth = $dbh->prepare($sQuery);
						unless ($sth->execute($id_channel)) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
						}
						else {
							if (my $ref = $sth->fetchrow_hashref()) {
								my $sDecription = $ref->{'description'};
								my $sKey = $ref->{'key'};
								my $sChanmode = $ref->{'chanmode'};
								my $bAutoJoin = $ref->{'auto_join'};
								$sQuery = "DELETE FROM CHANNEL WHERE id_channel=?";
								$sth = $dbh->prepare($sQuery);
								unless ($sth->execute($id_channel)) {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									$sth->finish;
									return undef;
								}
								else {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Deleted channel $sChannel id_channel : $id_channel");
									$sQuery = "DELETE FROM USER_CHANNEL WHERE id_channel=?";
									$sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_channel)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
										$sth->finish;
										return undef;
									}
									else {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Deleted channel access for $sChannel id_channel : $id_channel");
										$sQuery = "INSERT INTO CHANNEL_PURGED (id_channel,name,description,`key`,chanmode,auto_join) VALUES (?,?,?,?,?,?)";
										$sth = $dbh->prepare($sQuery);
										unless ($sth->execute($id_channel,$sChannel,$sDecription,$sKey,$sChanmode,$bAutoJoin)) {
											log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
											$sth->finish;
											return undef;
										}
										else {
											log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Added $sChannel id_channel : $id_channel to CHANNEL_PURGED");
											partChannel($irc,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$sChannel,"Channel purged");
											logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"purge","$sNick purge $sChannel id_channel : $id_channel");
										}
									}
								}
							}
							else {
								$sth->finish;
								return undef;
							}
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: purge <#channel>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " purge command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " purge command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# op #channel <nick>
sub userOpChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: op #channel <nick>");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,100))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a op $sChannel command");
						$irc->send_message("MODE",undef,($sChannel,"+o",$tArgs[0]));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"op",@tArgs);
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: op #channel <nick>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " op command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " op command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# deop #channel <nick>
sub userDeopChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: deop #channel <nick>");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,100))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a deop $sChannel command");
						$irc->send_message("MODE",undef,($sChannel,"-o",$tArgs[0]));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"deop",@tArgs);
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: deop #channel <nick>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " deop command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " deop command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# invite #channel <nick>
sub userInviteChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: invite #channel <nick>");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,100))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued an invite $sChannel command");
						$irc->send_message("INVITE",undef,($tArgs[0],$sChannel));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"invite",@tArgs);
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: invite #channel <nick>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " invite command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " invite command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# voice #channel <nick>
sub userVoiceChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: voice #channel <nick>");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,25))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a voice $sChannel command");
						$irc->send_message("MODE",undef,($sChannel,"+v",$tArgs[0]));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"voice",@tArgs);
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: voice #channel <nick>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " voice command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " voice command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# voice #channel <nick>
sub userDevoiceChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: devoice #channel <nick>");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,25))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a devoice $sChannel command");
						$irc->send_message("MODE",undef,($sChannel,"-v",$tArgs[0]));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"devoice",@tArgs);
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: devoice #channel <nick>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " devoice command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " devoice command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# kick #channel <nick>
sub userKickChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: kick #channel <nick> [reason]");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,50))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a kick $sChannel command");
						my $sKickNick = $tArgs[0];
						shift @tArgs;
						my $sKickReason = join(" ",@tArgs);
						$irc->send_message("KICK",undef,($sChannel,$sKickNick,"($sMatchingUserHandle) $sKickReason"));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"kick",($sKickNick,@tArgs));
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: kick #channel <nick> [reason]");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " kick command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " kick command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# topic #channel <topic>
sub userTopicChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				$sChannel = $tArgs[0];
				shift @tArgs;
			}
			unless (defined($sChannel)) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: topic #channel <topic>");
				return undef;
			}
			if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,50))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
					if (defined($id_channel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a topic $sChannel command");
						$irc->send_message("TOPIC",undef,($sChannel,join(" ",@tArgs)));
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"topic",@tArgs);
						return $id_channel;
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
						return undef;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: topic #channel <topic>");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " topic command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " topic command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# showcommands #channel
sub userShowcommandsChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (!defined($sChannel) || (defined($tArgs[0]) && ($tArgs[0] ne ""))) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					$sChannel = $tArgs[0];
					shift @tArgs;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: showcommands #channel");
					return undef;
				}
			}
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Available commands on $sChannel");
			my ($id_user,$level) = getIdUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$sMatchingUserHandle,$sChannel);
			if ( $level >= 500) { botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level 500: part"); }
			if ( $level >= 450) { botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level 450: join chanset"); }
			if ( $level >= 400) { botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level 400: add del modinfo"); }
			if ( $level >= 100) { botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level 100: op deop invite"); }
			if ( $level >= 50) { botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level  50: kick topic"); }
			if ( $level >= 25) { botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level  25: voice devoice"); }
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level   0: access chaninfo login pass newpass ident showcommands");
		}
		else {
			my $sNoticeMsg = $message->prefix . " showcommands attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to see available commands for your level - /msg " . $irc->nick_folded . " login username password");
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level   0: access chaninfo login pass newpass ident showcommands");
			return undef;
		}
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Level   0: access chaninfo login pass newpass ident showcommands");
	}
}

# chaninfo #channel
sub userChannelInfo(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
		$sChannel = $tArgs[0];
		shift @tArgs;
	}
	unless (defined($sChannel)) {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chaninfo #channel");
		return undef;
	}
	my $sQuery = "SELECT * FROM USER,USER_CHANNEL,CHANNEL WHERE USER.id_user=USER_CHANNEL.id_user AND CHANNEL.id_channel=USER_CHANNEL.id_channel AND name=? AND level=500";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $sUsername = $ref->{'nickname'};
			my $sLastLogin = $ref->{'last_login'};
			my $creation_date = $ref->{'creation_date'};
			my $description = $ref->{'description'};
			my $sKey = $ref->{'key'};
			$sKey = ( defined($sKey) ? $sKey : "Not set" );
			my $chanmode = $ref->{'chanmode'};
			$chanmode = ( defined($chanmode) ? $chanmode : "Not set" );
			my $sAutoJoin = $ref->{'auto_join'};
			$sAutoJoin = ( $sAutoJoin ? "True" : "False" );
			unless(defined($sLastLogin) && ($sLastLogin ne "")) {
				$sLastLogin = "Never";
			}
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sChannel is registered by $sUsername - last login: $sLastLogin");
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Creation date : $creation_date - Description : $description");
			my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
			if (defined($iMatchingUserId)) {
				if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
					if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Chan modes : $chanmode - Key : $sKey - Auto join : $sAutoJoin");
					}
				}
			}
			$sQuery = "SELECT chanset FROM CHANSET_LIST,CHANNEL_SET,CHANNEL WHERE CHANNEL_SET.id_channel=CHANNEL.id_channel AND CHANNEL_SET.id_chanset_list=CHANSET_LIST.id_chanset_list AND name like ?";
			$sth = $dbh->prepare($sQuery);
			unless ($sth->execute($sChannel)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			else {
				my $sChansetFlags = "Channel flags ";
				my $i;
				while (my $ref = $sth->fetchrow_hashref()) {
					my $chanset = $ref->{'chanset'};
					$sChansetFlags .= "+$chanset ";
					$i++;
				}
				if ( $i ) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sChansetFlags);
				}
			}
		}
		else {
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"The channel $sChannel doesn't appear to be registered");
		}
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chaninfo",@tArgs);
	}
	$sth->finish;
}

# chanlist
sub channelList(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					$sChannel = $tArgs[0];
					shift @tArgs;
				}
				unless (defined($sChannel)) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanlist #channel");
					return undef;
				}
				my $sQuery="SELECT name,count(id_user) as nbUsers FROM CHANNEL,USER_CHANNEL WHERE CHANNEL.id_channel=USER_CHANNEL.id_channel GROUP BY name ORDER by creation_date LIMIT 20";
				my $sth = $dbh->prepare($sQuery);
				unless ($sth->execute()) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				}
				else {
					my $sNoticeMsg = "[#chan (users)] ";
					while (my $ref = $sth->fetchrow_hashref()) {
						my $name = $ref->{'name'};
						my $nbUsers = $ref->{'nbUsers'};
						$sNoticeMsg .= "$name ($nbUsers) ";
					}
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sNoticeMsg);
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " chanlist command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " chanlist command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# users
sub userStats(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				my $sQuery="SELECT count(*) as nbUsers FROM USER";
				my $sth = $dbh->prepare($sQuery);
				unless ($sth->execute()) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				}
				else {
					my $sNoticeMsg = "Numbers of users : ";
					if (my $ref = $sth->fetchrow_hashref()) {
						my $nbUsers = $ref->{'nbUsers'};
						$sNoticeMsg .= "$nbUsers - ";
						$sQuery="SELECT description,count(nickname) as nbUsers FROM USER,USER_LEVEL WHERE USER.id_user_level=USER_LEVEL.id_user_level GROUP BY description ORDER BY level";
						$sth = $dbh->prepare($sQuery);
						unless ($sth->execute()) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
						}
						else {
							my $i = 0;
							while (my $ref = $sth->fetchrow_hashref()) {
								my $nbUsers = $ref->{'nbUsers'};
								my $description = $ref->{'description'};
								$sNoticeMsg .= "$description($nbUsers) ";
								$i++;
							}
							unless ( $i ) {
								#This shoud never happen
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"No user in database");
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sNoticeMsg);
							}
						}
					}
					else {
						# This should never happen since bot need to be registered
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"No user in database");
					}
					
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " users command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " users command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# nicklist #channel
sub channelNickList(@) {
	my ($NVars,$Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %hChannelsNicks = %$NVars;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					$sChannel = $tArgs[0];
					shift @tArgs;
				}
				unless (defined($sChannel)) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: nicklist #channel");
					return undef;
				}
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Users on $sChannel : " . join(" ",@{$hChannelsNicks{$sChannel}}));
			}
			else {
				my $sNoticeMsg = $message->prefix . " nicklist command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " nicklist command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# rnick #channel
sub randomChannelNick(@) {
	my ($NVars,$Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %hChannelsNicks = %$NVars;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					$sChannel = $tArgs[0];
					shift @tArgs;
				}
				unless (defined($sChannel)) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: rnick #channel");
					return undef;
				}
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Random nick on $sChannel : " . getRandomNick(\%hChannelsNicks,$sChannel));
			}
			else {
				my $sNoticeMsg = $message->prefix . " nicklist command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " nicklist command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# cstat 
sub userCstat(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				my $sGetAuthUsers = "SELECT nickname,description,level FROM USER,USER_LEVEL WHERE USER.id_user_level=USER_LEVEL.id_user_level AND auth=1 ORDER by level";
				my $sth = $dbh->prepare($sGetAuthUsers);
				unless ($sth->execute) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"userCstat() SQL Error : " . $DBI::errstr . " Query : " . $sGetAuthUsers);
				}
				else {
					my $sAuthUserStr;
					while (my $ref = $sth->fetchrow_hashref()) {
						$sAuthUserStr .= $ref->{'nickname'} . " (" . $ref->{'description'} . ") ";
					}
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Utilisateurs authentifiés : " . $sAuthUserStr);
					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"cstat",@tArgs);
				}
				$sth->finish;
			}
			else {
				my $sNoticeMsg = $message->prefix . " cstat command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " cstat command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# whoami 
sub userWhoAmI(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		my $sNoticeMsg = "User $sMatchingUserHandle ($iMatchingUserLevelDesc)";
		my $sQuery = "SELECT password,hostmasks,creation_date,last_login FROM USER WHERE id_user=?";
		my $sth = $dbh->prepare($sQuery);
		unless ($sth->execute($iMatchingUserId)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
		}
		else {
			if (my $ref = $sth->fetchrow_hashref()) {
				my $sPasswordSet = defined($ref->{'creation_date'}) ? "Password set" : "Password not set";
				$sNoticeMsg .= " - created " . $ref->{'creation_date'} . " - last login " . $ref->{'last_login'};
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sPasswordSet);
				$sNoticeMsg = "Hostmasks : " . $ref->{'hostmasks'};
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sNoticeMsg);
			}
		}
		$sNoticeMsg = "Infos : ";
		if (defined($sMatchingUserInfo1)) {
			$sNoticeMsg .= $sMatchingUserInfo1;
		}
		else {
			$sNoticeMsg .= "N/A";
		}
		$sNoticeMsg .= " - ";
		if (defined($sMatchingUserInfo2)) {
			$sNoticeMsg .= $sMatchingUserInfo2;
		}
		else {
			$sNoticeMsg .= "N/A";
		}
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,$sNoticeMsg);
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"whoami",@tArgs);
		$sth->finish;
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User not found with this hostmask");
	}
}

sub getNickInfoWhois(@) {
	my ($Config,$LOG,$dbh,$sWhoisHostmask) = @_;
	my %MAIN_CONF = %$Config;
	my $iMatchingUserId = undef;
	my $iMatchingUserLevel = undef;
	my $iMatchingUserLevelDesc = undef;
	my $iMatchingUserAuth = undef;
	my $sMatchingUserHandle = undef;
	my $sMatchingUserPasswd = undef;
	my $sMatchingUserInfo1 = undef;
	my $sMatchingUserInfo2 = undef;
	
	my $sCheckQuery = "SELECT * FROM USER";
	my $sth = $dbh->prepare($sCheckQuery);
	unless ($sth->execute ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"getNickInfoWhois() SQL Error : " . $DBI::errstr . " Query : " . $sCheckQuery);
	}
	else {	
		while (my $ref = $sth->fetchrow_hashref()) {
			my @tHostmasks = split(/,/,$ref->{'hostmasks'});
			foreach my $sHostmask (@tHostmasks) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() Checking hostmask : " . $sHostmask);
				$sHostmask =~ s/\./\\./g;
				$sHostmask =~ s/\*/.*/g;
				if ( $sWhoisHostmask =~ /^$sHostmask/ ) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getNickInfoWhois() $sHostmask matches " . $sWhoisHostmask);
					$sMatchingUserHandle = $ref->{'nickname'};
					if (defined($ref->{'password'})) {
						$sMatchingUserPasswd = $ref->{'password'};
					}
					$iMatchingUserId = $ref->{'id_user'};
					my $iMatchingUserLevelId = $ref->{'id_user_level'};
					my $sGetLevelQuery = "SELECT * FROM USER_LEVEL WHERE id_user_level=?";
					my $sth2 = $dbh->prepare($sGetLevelQuery);
				        unless ($sth2->execute($iMatchingUserLevelId)) {
                				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"getNickInfoWhois() SQL Error : " . $DBI::errstr . " Query : " . $sGetLevelQuery);
        				}
        				else {
               					while (my $ref2 = $sth2->fetchrow_hashref()) {
							$iMatchingUserLevel = $ref2->{'level'};
							$iMatchingUserLevelDesc = $ref2->{'description'};
						}
					}
					$iMatchingUserAuth = $ref->{'auth'};
					if (defined($ref->{'info1'})) {
						$sMatchingUserInfo1 = $ref->{'info1'};
					}
					if (defined($ref->{'info2'})) {
						$sMatchingUserInfo2 = $ref->{'info2'};
					}
					$sth2->finish;
				}
			}
		}
	}
	$sth->finish;
	if (defined($iMatchingUserId)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getNickInfoWhois() iMatchingUserId : $iMatchingUserId");
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getNickInfoWhois() iMatchingUserId is undefined with this host : " . $sWhoisHostmask);
		return (undef,undef,undef,undef,undef,undef,undef);
	}
	if (defined($iMatchingUserLevel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() iMatchingUserLevel : $iMatchingUserLevel");
	}
	if (defined($iMatchingUserLevelDesc)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() iMatchingUserLevelDesc : $iMatchingUserLevelDesc");
	}
	if (defined($iMatchingUserAuth)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() iMatchingUserAuth : $iMatchingUserAuth");
	}
	if (defined($sMatchingUserHandle)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() sMatchingUserHandle : $sMatchingUserHandle");
	}
	if (defined($sMatchingUserPasswd)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() sMatchingUserPasswd : $sMatchingUserPasswd");
	}
	if (defined($sMatchingUserInfo1)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() sMatchingUserInfo1 : $sMatchingUserInfo1");
	}
	if (defined($sMatchingUserInfo2)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,4,"getNickInfoWhois() sMatchingUserInfo2 : $sMatchingUserInfo2");
	}
	return ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2);
}

# verify <nick> 
sub userVerifyNick(@) {
	my ($WVars,$Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		$WHOIS_VARS{'nick'} = $tArgs[0];
		$WHOIS_VARS{'sub'} = "userVerifyNick";
		$WHOIS_VARS{'caller'} = $sNick;
		$WHOIS_VARS{'channel'} = undef;
		$WHOIS_VARS{'message'} = $message;
		$irc->send_message("WHOIS", undef, $tArgs[0]);
		return %WHOIS_VARS;
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: verify <nick>");
	}
}

# auth <nick> 
sub userAuthNick(@) {
	my ($WVars,$Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					$WHOIS_VARS{'nick'} = $tArgs[0];
					$WHOIS_VARS{'sub'} = "userAuthNick";
					$WHOIS_VARS{'caller'} = $sNick;
					$WHOIS_VARS{'channel'} = undef;
					$WHOIS_VARS{'message'} = $message;
					$irc->send_message("WHOIS", undef, $tArgs[0]);
					return %WHOIS_VARS;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: auth <nick>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " auth command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " auth command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

sub getUserChannelLevelByName(@) {
	my ($Config,$LOG,$dbh,$sChannel,$sHandle) = @_;
	my %MAIN_CONF = %$Config;
	my $iChannelUserLevel = 0;
	my $sQuery = "SELECT level FROM USER,USER_CHANNEL,CHANNEL WHERE USER.id_user=USER_CHANNEL.id_user AND USER_CHANNEL.id_channel=CHANNEL.id_channel AND CHANNEL.name=? AND USER.nickname=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel,$sHandle)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"getUserChannelLevelByName() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			$iChannelUserLevel = $ref->{'level'};
		}
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"getUserChannelLevelByName() iChannelUserLevel = $iChannelUserLevel");
	}
	$sth->finish;
	return $iChannelUserLevel;
}

# access #channel <nickhandle>
# access #channel =<nick>
sub userAccessChannel(@) {
	my ($WVars,$Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %WHOIS_VARS = %$WVars;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
		$sChannel = $tArgs[0];
		shift @tArgs;
	}
	unless (defined($sChannel)) {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: access #channel [=]<nick>");
		return ();
	}
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		if (substr($tArgs[0], 0, 1) eq '=') {
			$tArgs[0] = substr($tArgs[0],1);
			$WHOIS_VARS{'nick'} = $tArgs[0];
			$WHOIS_VARS{'sub'} = "userAccessChannel";
			$WHOIS_VARS{'caller'} = $sNick;
			$WHOIS_VARS{'channel'} = $sChannel;
			$WHOIS_VARS{'message'} = $message;
			$irc->send_message("WHOIS", undef, $tArgs[0]);
			return %WHOIS_VARS;
		}
		else {
			my $iChannelUserLevelAccess = getUserChannelLevelByName(\%MAIN_CONF,$LOG,$dbh,$sChannel,$tArgs[0]);
			if ( $iChannelUserLevelAccess == 0 ) {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"No Match!");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"access",($sChannel,@tArgs));
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"USER: " . $tArgs[0] . " ACCESS: $iChannelUserLevelAccess");
				my $sQuery = "SELECT automode,greet FROM USER,USER_CHANNEL,CHANNEL WHERE CHANNEL.id_channel=USER_CHANNEL.id_channel AND USER.id_user=USER_CHANNEL.id_user AND nickname like ? AND CHANNEL.name=?";
				my $sth = $dbh->prepare($sQuery);
				unless ($sth->execute($tArgs[0],$sChannel)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
				}
				else {
					my $sAuthUserStr;
					if (my $ref = $sth->fetchrow_hashref()) {
						my $sGreetMsg = $ref->{'greet'};
						my $sAutomode = $ref->{'automode'};
						unless (defined($sGreetMsg)) {
							$sGreetMsg = "None";
						}
						unless (defined($sAutomode)) {
							$sAutomode = "None";
						}							
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"CHANNEL: $sChannel -- Automode: $sAutomode");
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"GREET MESSAGE: $sGreetMsg");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"access",($sChannel,@tArgs));
					}
				}
				$sth->finish;
			}
			return ();
		}
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: access #channel [=]<nick>");
		return ();
	}
}

# chanstatlines #channel
sub channelStatLines(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && (substr($tArgs[0],0,1) eq '#')) {
					my $sChannel = $tArgs[0];
					my $sQuery = "SELECT COUNT(*) as nbLinesPerHour FROM CHANNEL,CHANNEL_LOG WHERE CHANNEL.id_channel=CHANNEL_LOG.id_channel AND CHANNEL.name like ? AND ts > date_sub('" . time2str("%Y-%m-%d %H:%M:%S",time) . "', INTERVAL 1 HOUR)";
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,$sQuery);
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sChannel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						if (my $ref = $sth->fetchrow_hashref()) {
							my $nbLinesPerHour = $ref->{'nbLinesPerHour'};
							my $sLineTxt = "line";
							if ( $nbLinesPerHour > 0 ) {
								$sLineTxt .= "s";
							}
							botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"$nbLinesPerHour $sLineTxt per hour on $sChannel");
							logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"chanstatlines",@tArgs);
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel is not registered");
						}
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanstatlines #channel");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " chanstatlines command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " chanstatlines command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

# whotalk #channel
sub whoTalk(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && (substr($tArgs[0],0,1) eq '#')) {
					my $sChannel = $tArgs[0];
					my $sQuery = "SELECT nick,COUNT(nick) as nbLinesPerHour FROM CHANNEL,CHANNEL_LOG WHERE CHANNEL.id_channel=CHANNEL_LOG.id_channel AND CHANNEL.name like ? AND ts > date_sub('" . time2str("%Y-%m-%d %H:%M:%S",time) . "', INTERVAL 1 HOUR) GROUP BY nick ORDER BY nbLinesPerHour DESC LIMIT 5";
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,$sQuery);
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sChannel)) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						my $sResult = "Top 5 talker ";
						while (my $ref = $sth->fetchrow_hashref()) {
							my $nbLinesPerHour = $ref->{'nbLinesPerHour'};
							my $sCurrentNick = $ref->{'nick'};
							$sResult .= "$sCurrentNick ($nbLinesPerHour) ";
						}
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"$sResult per hour on $sChannel");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"whotalk",@tArgs);
					}
					$sth->finish;
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: whotalk #channel");
					return undef;
				}
			}
			else {
				my $sNoticeMsg = $message->prefix . " whotalk command attempt (command level [Administrator] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " whotalk command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg " . $irc->nick_folded . " login username password");
			return undef;
		}
	}
}

#addhost <username> <hostmask>
sub addUserHost(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"addUserHost() " . $tArgs[0] . " " . $tArgs[1]);
					my $id_user = getIdUser(\%MAIN_CONF,$LOG,$dbh,$tArgs[0]);
					unless (defined($id_user)) {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User " . $tArgs[0] . " does not exists");
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addhost","User " . $tArgs[0] . " does not exists");
						return undef;
					}
					else {
						my $sQuery = "SELECT nickname FROM USER WHERE hostmasks LIKE '%" . $tArgs[1] . "%'";
						my $sth = $dbh->prepare($sQuery);
						unless ($sth->execute()) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"addUserHost() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
						}
						else {
							if (my $ref = $sth->fetchrow_hashref()) {
								my $sUser = $ref->{'nickname'};
								my $sNoticeMsg = $message->prefix . " Hostmask " . $tArgs[1] . " already exist for user for user $sUser";
								log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,$sNoticeMsg);
								noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
								logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addhost",$sNoticeMsg);
							}
							else {
								$sQuery = "SELECT hostmasks FROM USER WHERE id_user=?";
								$sth = $dbh->prepare($sQuery);
								unless ($sth->execute($id_user)) {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"addUserHost() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
								}
								else {
									my $sHostmasks = "";
									if (my $ref = $sth->fetchrow_hashref()) {
										$sHostmasks = $ref->{'hostmasks'};
									}
									$sQuery = "UPDATE USER SET hostmasks=? WHERE id_user=?";
									$sth = $dbh->prepare($sQuery);
									unless ($sth->execute($sHostmasks . "," . $tArgs[1],$id_user)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"addUserHost() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
									}
									else {
										my $sNoticeMsg = $message->prefix . " Hostmask " . $tArgs[1] . " added for user " . $tArgs[0];
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,$sNoticeMsg);
										noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
										logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addhost",$sNoticeMsg);
									}
								}
							}
						}
						$sth->finish;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: addhost <username> <hostmask>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix;
				$sNoticeMsg .= " addhost command attempt, (command level [1] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"This command is not available for your level. Contact a bot master.");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addhost",$sNoticeMsg);
			}
		}
		else {
			my $sNoticeMsg = $message->prefix;
			$sNoticeMsg .= " addhost command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command : /msg " . $irc->nick_folded . " login username password");
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"addhost",$sNoticeMsg);
		}
	}
}

#userinfo <username>
sub userInfo(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
						my $sQuery = "SELECT * FROM USER,USER_LEVEL WHERE USER.id_user_level=USER_LEVEL.id_user_level AND nickname LIKE ?";
						my $sth = $dbh->prepare($sQuery);
						unless ($sth->execute($tArgs[0])) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"addUserHost() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
						}
						else {
							if (my $ref = $sth->fetchrow_hashref()) {
								my $id_user = $ref->{'id_user'};
								my $sUser = $ref->{'nickname'};
								my $creation_date = $ref->{'creation_date'};
								my $sHostmasks = $ref->{'hostmasks'};
								my $sPassword = $ref->{'password'};
								my $sDescription = $ref->{'description'};
								my $sInfo1 = $ref->{'info1'};
								my $sInfo2 = $ref->{'info2'};								
								my $last_login = $ref->{'last_login'};
								my $auth = $ref->{'auth'};
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User : $sUser (Id: $id_user - $sDescription) - created $creation_date - last login $last_login");
								my $sPasswordSet = (defined($sPassword) ? "Password set" : "Password is not set" );
								my $sLoggedIn = (($auth) ? "logged in" : "not logged in" );
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sPasswordSet ($sLoggedIn)");
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Hostmasks : $sHostmasks");
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Infos : " . (defined($sInfo1) ? $sInfo1 : "N/A") . " - " . (defined($sInfo2) ? $sInfo2 : "N/A"));								
							}
							else {
								botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"User " . $tArgs[0] . " does not exist");
							}
							my $sNoticeMsg = $message->prefix . " userinfo on " . $tArgs[0];
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,$sNoticeMsg);
							noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
							logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"userinfo",$sNoticeMsg);
							$sth->finish;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: userinfo <username>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix;
				$sNoticeMsg .= " userinfo command attempt, (command level [1] for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"This command is not available for your level. Contact a bot master.");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"userinfo",$sNoticeMsg);
			}
		}
		else {
			my $sNoticeMsg = $message->prefix;
			$sNoticeMsg .= " userinfo command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command : /msg " . $irc->nick_folded . " login username password");
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"userinfo",$sNoticeMsg);
		}
	}
}

#topsay <nick>
sub userTopSay(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator")) {
				my $sChannelDest = $sChannel;
				if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
					$sChannel = $tArgs[0];
					shift @tArgs;
				}
				unless (defined($sChannel)) {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: topsay [#channel] <nick>");
					return undef;
				}
				if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
					my $sQuery = "SELECT event_type,publictext,count(publictext) as hit FROM CHANNEL,CHANNEL_LOG WHERE (event_type='public' OR event_type='action') AND CHANNEL.id_channel=CHANNEL_LOG.id_channel AND name=? AND nick like ? GROUP BY publictext ORDER by hit DESC LIMIT 30";
					my $sth = $dbh->prepare($sQuery);
					unless ($sth->execute($sChannel,$tArgs[0])) {
						log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
					}
					else {
						my $sTopSay = $tArgs[0] . " : ";
						my $i = 0;
						while (my $ref = $sth->fetchrow_hashref()) {
							my $publictext = $ref->{'publictext'};
							my $event_type = $ref->{'event_type'};
							my $hit = $ref->{'hit'};
							$publictext =~ s/(.)/(ord($1) == 1) ? "" : $1/egs;
							unless (($publictext =~ /^\s*$/) || ($publictext eq ':)') || ($publictext eq ';)') || ($publictext eq ':p') || ($publictext eq ':P') || ($publictext eq ':d') || ($publictext eq ':D') || ($publictext eq ':o') || ($publictext eq ':O') || ($publictext eq '(:') || ($publictext eq '(;') || ($publictext =~ /lol/i) || ($publictext eq 'xD') || ($publictext eq 'XD') || ($publictext eq 'heh') || ($publictext eq 'hah') || ($publictext eq 'huh') || ($publictext eq 'hih') || ($publictext eq '!bang') || ($publictext eq '!reload') || ($publictext eq '!tappe') || ($publictext eq '!duckstats') || ($publictext eq '=D') || ($publictext eq '=)') || ($publictext eq ';p') || ($publictext eq ':>') || ($publictext eq ';>')) {
								if ( $event_type eq "action" ) {
									$sTopSay .= String::IRC->new("$publictext ($hit) ")->bold;
								}
								else {
									$sTopSay .= "$publictext ($hit) ";
								}
								$i++;
							}
						}
						if ( $i ) {
							botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannelDest,substr($sTopSay,0,300));
						}
						else {
							botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannelDest,"No results.");
						}
						my $sNoticeMsg = $message->prefix . " topsay on " . $tArgs[0];
						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"topsay",$sNoticeMsg);
						$sth->finish;
					}
				}
				else {
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: topsay [#channel] <nick>");
				}
			}
			else {
				my $sNoticeMsg = $message->prefix;
				$sNoticeMsg .= " topsay command attempt for user " . $sMatchingUserHandle . "[" . $iMatchingUserLevel ."])";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"This command is not available for your level. Contact a bot master.");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"topsay",$sNoticeMsg);
			}
		}
		else {
			my $sNoticeMsg = $message->prefix;
			$sNoticeMsg .= " topsay command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command : /msg " . $irc->nick_folded . " login username password");
			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"topsay",$sNoticeMsg);
		}
	}
}

#greet <nick>
sub userGreet(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
			my $sQuery = "SELECT greet FROM USER,USER_CHANNEL,CHANNEL WHERE USER.id_user=USER_CHANNEL.id_user AND CHANNEL.id_channel=USER_CHANNEL.id_channel AND name=? AND nickname=?";
			my $sth = $dbh->prepare($sQuery);
			unless ($sth->execute($sChannel,$tArgs[0])) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			else {
				if (my $ref = $sth->fetchrow_hashref()) {
					my $greet = $ref->{'greet'};
					if (defined($greet)) {
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"(" . $tArgs[0] . ") $greet");
					}
					else {
						botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"No greet for " . $tArgs[0] . " on $sChannel");
					}
				}
				else {
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"No greet for " . $tArgs[0] . " on $sChannel");
				}
				my $sNoticeMsg = $message->prefix . " greet on " . $tArgs[0] . " for $sChannel";
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"greet",$sNoticeMsg);
				$sth->finish;
		}
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: greet <nick>");
	}
}

1;
