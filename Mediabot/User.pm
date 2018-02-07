package Mediabot::User;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Date::Format;
use Switch;
use Mediabot::Common;
use Mediabot::Core;
use Mediabot::Database;
use Mediabot::Channel;

@ISA     = qw(Exporter);
@EXPORT  = qw(actChannel addChannel addUser channelAddUser channelDelUser channelJoin channelPart channelSet checkAuth checkUserChannelLevel checkUserLevel dumpCmd getIdUser getIdUserLevel getNickInfo getUserChannelLevel getUserLevel logBot msgCmd purgeChannel registerChannel sayChannel userAdd userChannelInfo userCount userCstat userDeopChannel userDevoiceChannel userIdent userInviteChannel userKickChannel userLogin userModinfo userNewPass userOnJoin userOpChannel userPass userShowcommandsChannel userTopicChannel userVoiceChannel);

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
			return($ref->{'nbUser'});
		}
		else {
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
			return($ref->{'id_user_level'});
		}
		else {
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
			my $sSetAuthQuery = "UPDATE USER SET auth=1 WHERE id_user=?";
			my $sth2 = $dbh->prepare($sSetAuthQuery);
			unless ($sth2->execute($iUserId)) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuth() SQL Error : " . $DBI::errstr . " Query : " . $sSetAuthQuery);
				return 0;
			}
			my $sQuery = "UPDATE USER SET last_login=? WHERE id_user =?";
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
}

# ident username password
sub checkAuthByUser(@) {
	my ($Config,$LOG,$dbh,$message,$sUserHandle,$sPassword) = @_;
	my %MAIN_CONF = %$Config;
	my $sCheckAuthQuery = "SELECT * FROM USER WHERE nickname=? AND password=PASSWORD(?)";
	my $sth = $dbh->prepare($sCheckAuthQuery);
	unless ($sth->execute($sUserHandle,$sPassword)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"checkAuthByUser() SQL Error : " . $DBI::errstr . " Query : " . $sCheckAuthQuery);
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
					return (0,0);
				}
				return ($id_user,0);
			}
		}
		else {
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
				return 1;
			}
			else {
				return 0;
			}
		}
		else {
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
			return($ref->{'description'});
		}
		else {
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
			return($ref->{'id_user'});
		}
		else {
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
			return ($id_user,$level);
		}
		else {
			return (undef,undef);
		}
	}
}

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
				return 0;
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"userPass() Set password for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")");
				my $sNoticeMsg = "Set password for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Password set.");
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You may now login with /msg " . $irc->nick_folded . " login $sMatchingUserHandle password");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"pass","Success");
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
				return 0;
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"userNewPass() Set password for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")");
				my $sNoticeMsg = "Set password (newpass) for $sNick id_user : $iMatchingUserId (" . $message->prefix . ")";
				noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Password set.");
				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"newpass","Success");
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

#addUser [-n] <username> <hostmask> [level]
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset #channel key <key>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset #channel chanmode <+chanmode>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset #channel description <description>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: chanset #channel auto_join <on|off>");
}

sub channelSet(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
				if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,450))) {
					if (defined($tArgs[0]) && ($tArgs[0] ne "") && defined($tArgs[1]) && ($tArgs[1] ne "")) {
						my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
						if (defined($id_channel)) {
							switch($tArgs[0]) {
								case "key"					{
																			my $sQuery = "UPDATE CHANNEL SET `key`=? WHERE id_channel=?";
																			my $sth = $dbh->prepare($sQuery);
																			unless ($sth->execute($tArgs[1],$id_channel)) {
																				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																				return undef;
																			}
																			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel key " . $tArgs[1]);
																			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,@tArgs));
																			return $id_channel;
																		}
								case "chanmode"			{
																			my $sQuery = "UPDATE CHANNEL SET chanmode=? WHERE id_channel=?";
																			my $sth = $dbh->prepare($sQuery);
																			unless ($sth->execute($tArgs[1],$id_channel)) {
																				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																				return undef;
																			}
																			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel chanmode " . $tArgs[1]);
																			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,@tArgs));
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
																				return undef;
																			}
																			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel auto_join " . $tArgs[1]);
																			logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,@tArgs));
																			return $id_channel;
																		}
								case "description"	{
																			shift @tArgs;
																			unless ( $tArgs[0] =~ /console/i ) {
																				my $sQuery = "UPDATE CHANNEL SET description=? WHERE id_channel=?";
																				my $sth = $dbh->prepare($sQuery);
																				unless ($sth->execute(join(" ",@tArgs),$id_channel)) {
																					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"channelSet() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
																					return undef;
																				}
																				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set $sChannel description " . join(" ",@tArgs));
																				logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"chanset",($sChannel,"description",@tArgs));
																				return $id_channel;
																			}
																			else {
																				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You cannot set $sChannel description to " . $tArgs[0]);
																			}
																		}
								else								{
																			channelSetSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
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
				channelSetSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " chanset command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modinfo #channel automode <user> <voice|op|none>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modinfo #channel greet <user> <greet>");
	botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax: modinfo #channel level <user> <level>");
}

sub userModinfo(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
																							return undef;
																						}
																						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set automode $sAutomode on $sChannel for " . $tArgs[1]);
																						logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"modinfo",@tArgs);
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
																						return undef;
																					}
																					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set greet ($sGreet) on $sChannel for $sUser");
																					logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"modinfo",("greet $sUser",@tArgs));
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
																								return undef;
																							}
																							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Set level " . $tArgs[2] . " on $sChannel for $sUser");
																							logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"modinfo",@tArgs);
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
				userModinfoSyntax(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,@tArgs);
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " modinfo command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sGreetChan);
				}
			}
		}
	}
}


# part #channel
sub channelPart(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : part <#channel>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " part command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : join <#channel>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " join command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# add <#channel> <handle> <level>
sub channelAddUser(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : add <#channel> <handle> <level>");
					}
				}
				else {
					my $sNoticeMsg = $message->prefix . " add user command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
					noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				}
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : add <#channel> <handle> <level>");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " add user command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
		}
	}
}

# del <#channel> <handle>
sub channelDelUser(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : del <#channel> <handle>");
					}
				}
				else {
					my $sNoticeMsg = $message->prefix . " del user command attempt for user " . $sMatchingUserHandle . " [" . $iMatchingUserLevelDesc ."])";
					noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
					botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Your level does not allow you to use this command.");
				}
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : del <#channel> <handle>");
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " del user command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
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
		return 0;
	}
	else {
		logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,undef,"registerChannel","$sNick registered user : $id_user level 500 on channel : $id_channel");
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
				return 1;
			}
			else {
				return 0;
			}
		}
		else {
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
			return $iLevel;
		}
		else {
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
									return undef;
								}
								else {
									log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Deleted channel $sChannel id_channel : $id_channel");
									$sQuery = "DELETE FROM USER_CHANNEL WHERE id_channel=?";
									$sth = $dbh->prepare($sQuery);
									unless ($sth->execute($id_channel)) {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
										return undef;
									}
									else {
										log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Deleted channel access for $sChannel id_channel : $id_channel");
										$sQuery = "INSERT INTO CHANNEL_PURGED (id_channel,name,description,`key`,chanmode,auto_join) VALUES (?,?,?,?,?,?)";
										$sth = $dbh->prepare($sQuery);
										unless ($sth->execute($id_channel,$sChannel,$sDecription,$sKey,$sChanmode,$bAutoJoin)) {
											log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# op #channel <nick>
sub userOpChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : op #channel <nick>");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : op #channel <nick>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " op command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# op #channel <nick>
sub userDeopChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : deop #channel <nick>");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : deop #channel <nick>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " deop command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# invite #channel <nick>
sub userInviteChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : invite #channel <nick>");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : invite #channel <nick>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " invite command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# voice #channel <nick>
sub userVoiceChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : voice #channel <nick>");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : voice #channel <nick>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " voice command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# voice #channel <nick>
sub userDevoiceChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : devoice #channel <nick>");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : devoice #channel <nick>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " devoice command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# kick #channel <nick>
sub userKickChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
				if (defined($iMatchingUserLevel) && ( checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Administrator") || checkUserChannelLevel(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,$iMatchingUserId,50))) {
					if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
						my $id_channel = getIdChannel(\%MAIN_CONF,$LOG,$dbh,$sChannel);
						if (defined($id_channel)) {
							log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sNick issued a kick $sChannel command");
							my $sKickNick = $tArgs[0];
							shift @tArgs;
							$irc->send_message("KICK",undef,($sChannel,$sKickNick,join(" ",@tArgs)));
							logBot(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sChannel,"kick",($sKickNick,@tArgs));
							return $id_channel;
						}
						else {
							botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Channel $sChannel does not exist");
							return undef;
						}
					}
					else {
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : kick #channel <nick> [reason]");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : kick #channel <nick> [reason]");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " kick command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# topic #channel <topic>
sub userTopicChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
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
						botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : topic #channel <topic>");
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
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : topic #channel <topic>");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " topic command attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# showcommands #channel
sub userShowcommandsChannel(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
	if (defined($iMatchingUserId)) {
		if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
			if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
				my $sChannel = $tArgs[0];
				shift @tArgs;
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"showcommands");
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : showcommands #channel");
				return undef;
			}
		}
		else {
			my $sNoticeMsg = $message->prefix . " topic showcommands attempt (user $sMatchingUserHandle is not logged in)";
			noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,$sNoticeMsg);
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

# chaninfo #channel
sub userChannelInfo(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	if (defined($tArgs[0]) && ($tArgs[0] ne "") && ( $tArgs[0] =~ /^#/)) {
		my $sChannel = $tArgs[0];
		shift @tArgs;
		my $sQuery = "SELECT nickname,last_login FROM USER,USER_CHANNEL,CHANNEL WHERE USER.id_user=USER_CHANNEL.id_user AND CHANNEL.id_channel=USER_CHANNEL.id_channel AND name=? AND level=500";
		my $sth = $dbh->prepare($sQuery);
		unless ($sth->execute($sChannel)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
		}
		else {
			if (my $ref = $sth->fetchrow_hashref()) {
				my $sUsername = $ref->{'nickname'};
				my $sLastLogin = $ref->{'last_login'};
				unless(defined($sLastLogin) && ($sLastLogin ne "")) {
					$sLastLogin = "Never";
				}
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"$sChannel is registered by $sUsername - last login: $sLastLogin");
			}
			else {
				botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"The channel $sChannel doesn't appear to be registered");
			}
		}
		
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"Syntax : showcommands #channel");
		return undef;
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
				}
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
			botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$sNick,"You must be logged to use this command - /msg mediabot login username password");
			return undef;
		}
	}
}

1;
