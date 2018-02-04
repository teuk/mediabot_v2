#!/usr/bin/perl

# +---------------------------------------------------------------------------+
# !          MEDIABOT      (Net::Async::IRC bot)                              !
# +---------------------------------------------------------------------------+

# +---------------------------------------------------------------------------+
# !          MODULES                                                          !
# +---------------------------------------------------------------------------+
BEGIN {push @INC, '.';}
use strict;
use warnings;
use diagnostics;
use POSIX 'setsid';

use File::Basename;
use Date::Language;
use Date::Format;
use Date::Manip;
use Date::Parse;
use IO::Async::Loop;
use Net::Async::IRC;
use String::IRC;
use Data::Dumper;
use Time::HiRes qw( usleep );
use Getopt::Long;
use Config::Simple;
use IO::Socket::INET;
use Net::Server::NonBlocking;
use WordList::Phrase::FR::Proverb::Wikiquote;
use Memory::Usage;
use DBI;

use Mediabot::Common;
use Mediabot::Config;
use Mediabot::Database;
use Mediabot::Channel;
use Mediabot::Commands;
use Mediabot::Core;
use Mediabot::User;

# +---------------------------------------------------------------------------+
# !          SETTINGS                                                         !
# +---------------------------------------------------------------------------+

# Main Settings
my %MAIN_CONF;
my $CONFIG_FILE;
<<<<<<< HEAD
my $MAIN_PROG_VERSION = '2.0beta';
=======
my $MAIN_PROG_VERSION = '2.0alpha';
>>>>>>> c17f139035ebf4390005bf8767d1ef95a1eba62d
my $MAIN_PROG_VERSION_LIVR = $MAIN_PROG_VERSION;
my $MAIN_PID_FILE;
my $MAIN_PROG_DAEMON = 0;
my $LOG;

# +---------------------------------------------------------------------------+
# !          CONSTANT                                                         !
# +---------------------------------------------------------------------------+

# Connection default settings
my $CONN_SERVER_NETWORK;
my $CONN_SERVER;
my $CONN_NICK;
my $CONN_NICK_ALTERNATE;
my $CONN_IRCNAME;
my $CONN_USERNAME;
my $CONN_USERMODE;
my $CONN_MAX_RETRY = 3;
my $CONN_RETRY = 0;

# Network types
my $NETWORK_TYPE_OTHER=0;
my $NETWORK_TYPE_UNDERNET=1;
my $NETWORK_TYPE_FREENODE=2;
my $NETWORK_TYPE_EPIKNET=3;

# Global levels
my $LEVEL_OWNER = 0;
my $LEVEL_MASTER = 1;
my $LEVEL_ADMINISTRATOR = 2;
my $LEVEL_USER = 3;

my $DB_AUTORECONNECT_DELAY = 120;

# +---------------------------------------------------------------------------+
# !          GLOBAL VARS                                                      !
# +---------------------------------------------------------------------------+
my $iConnectionTimestamp;


# +---------------------------------------------------------------------------+
# !          SUBS DECLARATION                                                 !
# +---------------------------------------------------------------------------+

# +---------------------------------------------------------------------------+
# !          BOT FUNCTIONS                                                    !
# +---------------------------------------------------------------------------+

# Core functions
sub usage(@);

# +---------------------------------------------------------------------------+
# !          IRC FUNCTIONS                                                    !
# +---------------------------------------------------------------------------+
sub on_login(@);
sub on_private(@);
sub on_motd(@);
sub on_message_INVITE(@);
sub on_message_KICK(@);
sub on_message_MODE(@);
sub on_message_NICK(@);
sub on_message_NOTICE(@);
sub on_message_QUIT(@);
sub on_message_PART(@);
sub on_message_PRIVMSG(@);
sub on_message_TOPIC(@);
sub on_message_LIST(@);
sub on_message_NAMES(@);
sub on_message_WHO(@);
sub on_message_WHOIS(@);
sub on_message_WHOWAS(@);
sub on_message_JOIN(@);

sub on_message_001(@);
sub on_message_002(@);
sub on_message_003(@);


# +---------------------------------------------------------------------------+
# !          MAIN                                                             !
# +---------------------------------------------------------------------------+

# Check command line parameters
my $result = GetOptions (
        "conf=s" => \$CONFIG_FILE,
        "daemon" => \$MAIN_PROG_DAEMON,
);

unless (defined($CONFIG_FILE)) {
        usage("You must specify a config file");
}

# Starts LOG MARK in foreground
unless ( $MAIN_PROG_DAEMON ) {
	print STDERR "+--------------------------------------------------------------------------------------------------+\n";
}

# Try to read $CONFIG_FILE
my $cfg = readConfigFile($CONFIG_FILE);
%MAIN_CONF = $cfg->vars();

my $EVENT_CTCP_VERSION_REPLY = $MAIN_CONF{'main.MAIN_PROG_NAME'} . "v$MAIN_PROG_VERSION, " . $MAIN_CONF{'main.MAIN_PROG_URL'};
my $CONN_DEFAULT_QUIT_MSG = $EVENT_CTCP_VERSION_REPLY;

# Init main log
$LOG = init_log(\%MAIN_CONF);

# Daemon mode actions
if ( $MAIN_PROG_DAEMON != 0 ) {
		
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"Starting in daemon mode");
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"Daemon mode actions starting");
		
		chdir '/'                 or die "Can't chdir to /: $!";
		umask 0;
		open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
		open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
		open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";
		defined(my $pid = fork)   or die "Can't fork: $!";
		exit if $pid;
		setsid                    or die "Can't start a new session: $!";
}

# Main starts to log
log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,$MAIN_CONF{'main.MAIN_PROG_NAME'} . " v$MAIN_PROG_VERSION Starting (pid : $$)");

# Init pid file
init_pid(\%MAIN_CONF,$LOG,undef);

# Establish a MySQL connection
my $dbh = dbConnect(\%MAIN_CONF,$LOG);

unless (defined($dbh)) {
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Could not connect to database");
	clean_and_exit(\%MAIN_CONF,$LOG,undef,$dbh,3);
}

# Check USER table and fail if not present
dbCheckTables(\%MAIN_CONF,$LOG,$dbh);

# Log out all user at start
dbLogoutUsers(\%MAIN_CONF,$LOG,$dbh);

# Pick a server in db default on $CONN_SERVER_NETWORK
my $sQuery = "SELECT SERVERS.server_hostname FROM NETWORK,SERVERS WHERE NETWORK.id_network=SERVERS.id_network AND NETWORK.network_name like ? ORDER BY RAND() LIMIT 1";
my $sth = $dbh->prepare($sQuery);
unless ($sth->execute($MAIN_CONF{'connection.CONN_SERVER_NETWORK'})) {
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Startup select SERVER, SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
}
else {	
	if (my $ref = $sth->fetchrow_hashref()) {
		$CONN_SERVER = $ref->{'server_hostname'};
	}
}

unless (defined($MAIN_CONF{'connection.CONN_SERVER_NETWORK'}) && ($MAIN_CONF{'connection.CONN_SERVER_NETWORK'} ne "")) {
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"No CONN_SERVER_NETWORK defined in $CONFIG_FILE");
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Run ./configure at first use or ./configure -s to set it properly");
	clean_and_exit(\%MAIN_CONF,$LOG,undef,$dbh,4);
}
unless (defined($CONN_SERVER) && ($CONN_SERVER ne "")) {
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"No server found for network " . $MAIN_CONF{'connection.CONN_SERVER_NETWORK'} . " defined in $CONFIG_FILE");
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Run ./configure at first use or ./configure -s to set it properly");
	clean_and_exit(\%MAIN_CONF,$LOG,undef,$dbh,4);
}

my $loop = IO::Async::Loop->new;

my $irc = Net::Async::IRC->new(
  on_message_text => \&on_private,
  on_message_motd => \&on_motd,
  on_message_INVITE => \&on_message_INVITE,
  on_message_KICK => \&on_message_KICK,
  on_message_MODE => \&on_message_MODE,
  on_message_NICK => \&on_message_NICK,
  on_message_NOTICE => \&on_message_NOTICE,
  on_message_QUIT => \&on_message_QUIT,
  on_message_PART => \&on_message_PART,
  on_message_PRIVMSG => \&on_message_PRIVMSG,
  on_message_TOPIC => \&on_message_TOPIC,
  on_message_LIST => \&on_message_LIST,
  on_message_NAMES => \&on_message_NAMES,
  on_message_WHO => \&on_message_WHO,
  on_message_WHOIS => \&on_message_WHOIS,
  on_message_WHOWAS => \&on_message_WHOWAS,
  on_message_JOIN => \&on_message_JOIN,
  
  on_message_001 => \&on_message_001,
  on_message_002 => \&on_message_002,
  on_message_003 => \&on_message_003,
);

$loop->add( $irc );

my $sConnectionNick = $MAIN_CONF{'connection.CONN_NICK'};
if (($MAIN_CONF{'connection.CONN_NETWORK_TYPE'} == 1) && ($MAIN_CONF{'connection.CONN_USERMODE'} =~ /x/)) {
	my @chars = ("A".."Z", "a".."z");
	my $string;
	$string .= $chars[rand @chars] for 1..8;
	$sConnectionNick = $string . (int(rand(100))+10);
}

$irc->login(
  nick => $sConnectionNick,
  host => $CONN_SERVER,
  user => $MAIN_CONF{'connection.CONN_USERNAME'},
  realname => $MAIN_CONF{'connection.CONN_IRCNAME'},
  on_login => \&on_login,
)->get;

$loop->run;

# +---------------------------------------------------------------------------+
# !          SUBS                                                             !
# +---------------------------------------------------------------------------+

sub usage(@) {
        my ($strErr) = @_;
        if (defined($strErr)) {
                print STDERR "Error : " . $strErr . "\n";
        }
        print STDERR "Usage: " . basename($0) . "--conf <config_file> [--daemon]\n";
        exit 4;
}

sub on_login(@) {
	my ( $self, $message, $hints ) = @_;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"on_login() Logged to irc server $CONN_SERVER");
	$iConnectionTimestamp = time;
	
	# Undernet : authentication to channel service if credentials are defined
	if (defined($MAIN_CONF{'connection.CONN_NETWORK_TYPE'}) && ( $MAIN_CONF{'connection.CONN_NETWORK_TYPE'} == 1 ) && defined($MAIN_CONF{'undernet.UNET_CSERVICE_LOGIN'}) && ($MAIN_CONF{'undernet.UNET_CSERVICE_LOGIN'} ne "") && defined($MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'}) && ($MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'} ne "") && defined($MAIN_CONF{'undernet.UNET_CSERVICE_PASSWORD'}) && ($MAIN_CONF{'undernet.UNET_CSERVICE_PASSWORD'} ne "")) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"on_login() Logging to " . $MAIN_CONF{'undernet.UNET_CSERVICE_LOGIN'});
		botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$self,$MAIN_CONF{'undernet.UNET_CSERVICE_LOGIN'},"login " . $MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'} . " "  . $MAIN_CONF{'undernet.UNET_CSERVICE_PASSWORD'});
  }

  # Set user modes
  if (defined($MAIN_CONF{'connection.CONN_USERMODE'})) {
  	if ( substr($MAIN_CONF{'connection.CONN_USERMODE'},0,1) eq '+') {  		
  		my $sUserMode = $MAIN_CONF{'connection.CONN_USERMODE'};
  		if (defined($MAIN_CONF{'connection.CONN_NETWORK_TYPE'}) && ( $MAIN_CONF{'connection.CONN_NETWORK_TYPE'} == 1 )) {
  			$sUserMode =~ s/x//;
  		}
  		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"on_login() Setting user mode $sUserMode");
  		$self->write("MODE " . $MAIN_CONF{'connection.CONN_NICK'} . " +" . $sUserMode . "\x0d\x0a");
  	}
  }
  
  # First join console chan
  my ($id_channel,$name,$chanmode,$key) = getConsoleChan($dbh);
  unless (defined($id_channel)) {
  	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Warning no console channel defined, run configure again or read documentation");
  }
  else {
  	joinChannel($self,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$name,$key);
  }
  
  # Join other channels
  unless (($MAIN_CONF{'connection.CONN_NETWORK_TYPE'} == 1) && ($MAIN_CONF{'connection.CONN_USERMODE'} =~ /x/)) {
		joinChannels($dbh,$self,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG);
	}
}

sub on_private(@) {
	my ($self,$message,$hints) = @_;
	my ($who, $what) = @{$hints}{qw<prefix_name text>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"on_private() -$who- $what");
}

sub on_message_INVITE(@) {
	my ($self,$message,$hints) = @_;
	my ($inviter_nick,$invited_nick,$target_name) = @{$hints}{qw<inviter_nick invited_nick target_name>};
	unless ($self->is_nick_me($inviter_nick)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"* $inviter_nick invites you to join $target_name");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"invite",$inviter_nick,undef,$target_name);
		my ($iMatchingUserId,$iMatchingUserLevel,$iMatchingUserLevelDesc,$iMatchingUserAuth,$sMatchingUserHandle,$sMatchingUserPasswd,$sMatchingUserInfo1,$sMatchingUserInfo2) = getNickInfo(\%MAIN_CONF,$LOG,$dbh,$message);
		if (defined($iMatchingUserId)) {
			if (defined($iMatchingUserAuth) && $iMatchingUserAuth) {
				if (defined($iMatchingUserLevel) && checkUserLevel(\%MAIN_CONF,$LOG,$dbh,$iMatchingUserLevel,"Master")) {
					joinChannel($self,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$target_name);
					noticeConsoleChan(\%MAIN_CONF,$LOG,$dbh,$irc,"Joined $target_name after $inviter_nick invite (user $sMatchingUserHandle)");
	    	}
			}
		}
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$invited_nick has been invited to join $target_name");
	}
}

sub on_message_KICK(@) {
	my ($self,$message,$hints) = @_;
	my ($kicker_nick,$target_name,$kicked_nick,$text) = @{$hints}{qw<kicker_nick target_name kicked_nick text>};
	if ($self->is_nick_me($kicked_nick)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"* you were kicked from $target_name by $kicker_nick ($text)");
		joinChannel($self,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$target_name);
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"$target_name: $kicked_nick was kicked by $kicker_nick ($text)");
	}
	logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"kick",$kicker_nick,$target_name,"$kicked_nick ($text)");
}

sub on_message_MODE(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name,$modechars,$modeargs) = @{$hints}{qw<target_name modechars modeargs>};
	
	#log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"$target_name " . Dumper($message));
	my ($sNick,$sIdent,$sHost) = getMessageNickIdentHost($message);
	my @tArgs = $message->args;
	if ( substr($target_name,0,1) eq '#' ) {
		shift @tArgs;
		my $sModes = $tArgs[0];
		shift @tArgs;
		my $sTargetNicks = join(" ",@tArgs);
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"<$target_name> $sNick sets mode $sModes $sTargetNicks");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"mode",$sNick,$target_name,"$sModes $sTargetNicks");
		my ($Config,$LOG,$dbh,$irc,$message,$eventtype,$sNick,$sChannel,$sText) = @_;
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"$target_name sets mode " . $tArgs[1]);
	}
}

sub on_message_NICK(@) {
	my ($self,$message,$hints) = @_;
	my ($old_nick,$new_nick) = @{$hints}{qw<old_nick new_nick>};
	if ($self->is_nick_me($old_nick)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"* Your nick is now $new_nick");
		$self->_set_nick($new_nick);
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"* $old_nick is now known as $new_nick");
	}
	logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"nick",$old_nick,undef,$new_nick);
}

sub on_message_NOTICE(@) {
	my ($self,$message,$hints) = @_;
	my ($who, $what) = @{$hints}{qw<prefix_name text>};
	my ($sNick,$sIdent,$sHost) = getMessageNickIdentHost($message);
	my @tArgs = $message->args;
	if (defined($who) && ($who ne "")) {
		if (defined($tArgs[0]) && (substr($tArgs[0],0,1) eq '#')) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"-$who:" . $tArgs[0] . "- $what");
			logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"notice",$sNick,$tArgs[0],$what);
		}
		else {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"-$who- $what");
		}
		if (defined($MAIN_CONF{'connection.CONN_NETWORK_TYPE'}) && ( $MAIN_CONF{'connection.CONN_NETWORK_TYPE'} == 1 ) && defined($MAIN_CONF{'undernet.UNET_CSERVICE_LOGIN'}) && ($MAIN_CONF{'undernet.UNET_CSERVICE_LOGIN'} ne "") && defined($MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'}) && ($MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'} ne "") && defined($MAIN_CONF{'undernet.UNET_CSERVICE_PASSWORD'}) && ($MAIN_CONF{'undernet.UNET_CSERVICE_PASSWORD'} ne "")) {
			my $sSuccesfullLoginFrText = "AUTHENTIFICATION R.USSIE pour " . $MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'};
			my $sSuccesfullLoginEnText = "AUTHENTICATION SUCCESSFUL as " . $MAIN_CONF{'undernet.UNET_CSERVICE_USERNAME'};
			if (($who eq "X") && (($what =~ /USSIE/) || ($what eq $sSuccesfullLoginEnText)) && defined($MAIN_CONF{'connection.CONN_NETWORK_TYPE'}) && ($MAIN_CONF{'connection.CONN_NETWORK_TYPE'} == 1) && ($MAIN_CONF{'connection.CONN_USERMODE'} =~ /x/)) {
				$self->write("MODE " . $self->nick_folded . " +x\x0d\x0a");
				$self->change_nick( $MAIN_CONF{'connection.CONN_NICK'} );
				joinChannels($dbh,$self,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG);
		  }
		}
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$what");
	}
}

sub on_message_QUIT(@) {
	my ($self,$message,$hints) = @_;
	my ($text) = @{$hints}{qw<text>};
	unless(defined($text)) { $text="";}
	my ($sNick,$sIdent,$sHost) = getMessageNickIdentHost($message);
	if (defined($text) && ($text ne "")) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2," * Quits: $sNick ($sIdent\@$sHost) ($text)");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"quit",$sNick,undef,$text);
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2," * Quits: $sNick ($sIdent\@$sHost) ()");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"quit",$sNick,undef,"");
	}
}

sub on_message_PART(@){
	my ($self,$message,$hints) = @_;
	my ($target_name,$text) = @{$hints}{qw<target_name text>};
	unless(defined($text)) { $text="";}
	my ($sNick,$sIdent,$sHost) = getMessageNickIdentHost($message);
	my @tArgs = $message->args;
	shift @tArgs;
	if (defined($tArgs[0]) && ($tArgs[0] ne "")) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"<$target_name> * Parts: $sNick ($sIdent\@$sHost) (" . $tArgs[0] . ")");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"part",$sNick,$target_name,$tArgs[0]);
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"<$target_name> * Parts: $sNick ($sIdent\@$sHost)");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"part",$sNick,$target_name,"");
	}
	
}

sub on_message_PRIVMSG(@) {
	my ($self, $message, $hints) = @_;
	my ($who, $where, $what) = @{$hints}{qw<prefix_nick targets text>};
	if ( substr($where,0,1) eq '#' ) {
		# Message on channel
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"$where: <$who> $what");
		if (substr($what, 0, 1) eq $MAIN_CONF{'main.MAIN_PROG_CMD_CHAR'}) {
        my ($sCommand,@tArgs) = split(/\s+/,$what);
        $sCommand = substr($sCommand,1);
        $sCommand =~ tr/A-Z/a-z/;
        if (defined($sCommand) && ($sCommand ne "")) {
        	mbCommandPublic(\%MAIN_CONF,$LOG,$dbh,$self,$message,$MAIN_PROG_VERSION,$where,$who,$sCommand,@tArgs);
        }
		}
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"public",$who,$where,$what);
	}
	else {
		# Private message hide passwords
		unless ( $what =~ /^login|^register|^pass|^newpass|^ident/i) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"<$who> $what");
		}
		my ($sCommand,@tArgs) = split(/\s+/,$what);   
    $sCommand =~ tr/A-Z/a-z/;
    if (defined($sCommand) && ($sCommand ne "")) {
    	if ( $sCommand =~ /debug/i) {
    		%MAIN_CONF = mbDebug($cfg,\%MAIN_CONF,$LOG,$dbh,$irc,$message,$who,@tArgs);
    	}
    	else {
    		mbCommandPrivate(\%MAIN_CONF,$LOG,$dbh,$self,$message,$MAIN_PROG_VERSION,$who,$sCommand,@tArgs);
    	}
    }
	}	
}

sub on_message_TOPIC(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name,$text) = @{$hints}{qw<target_name text>};
	my ($sNick,$sIdent,$sHost) = getMessageNickIdentHost($message);
	unless(defined($text)) { $text="";}
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"<$target_name> $sNick changes topic to '$text'");
	logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"topic",$sNick,$target_name,$text);
}

sub on_message_LIST(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name) = @{$hints}{qw<target_name>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"on_message_LIST() $target_name");
}

sub on_message_NAMES(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name) = @{$hints}{qw<target_name>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"on_message_NAMES() $target_name");
}

sub on_message_WHO(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name) = @{$hints}{qw<target_name>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"on_message_WHO() $target_name");
}

sub on_message_WHOIS(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name) = @{$hints}{qw<target_name>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"on_message_WHOIS() $target_name");
}

sub on_message_WHOWAS(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name) = @{$hints}{qw<target_name>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"on_message_WHOWAS() $target_name");
}

sub on_message_JOIN(@) {
	my ($self,$message,$hints) = @_;
	my ($target_name) = @{$hints}{qw<target_name>};
	my ($sNick,$sIdent,$sHost) = getMessageNickIdentHost($message);
	if ( $sNick eq $self->nick ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2," * Now talking in $target_name");
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,2,"<$target_name> * Joins $sNick ($sIdent\@$sHost)");
		userOnJoin(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$target_name,$sNick);
	}
	logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,$message,"join",$sNick,$target_name,"");
}

sub on_message_001(@) {
	my ($self,$message,$hints) = @_;
	my ($text) = @{$hints}{qw<text>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"001 $text");
}

sub on_message_002(@) {
	my ($self,$message,$hints) = @_;
	my ($text) = @{$hints}{qw<text>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"002 $text");
}

sub on_message_003(@) {
	my ($self,$message,$hints) = @_;
	my ($text) = @{$hints}{qw<text>};
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"003 $text");
}

sub on_motd(@) {
	my ($self,$message,$hints) = @_;
	my @motd_lines = @{$hints}{qw<motd>};
	foreach my $line (@{$motd_lines[0]}) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"-motd- $line");
	}
}