package Mediabot::Database;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Data::Dumper;
use Date::Format;
use Mediabot::Common;

@ISA     = qw(Exporter);
@EXPORT  = qw(dbConnect dbCheckHandle dbCheckTables dbLogoutUsers logBotAction);

sub dbConnect(@) {
	my ($Config,$LOG) = @_;
	my %MAIN_CONF = %$Config;
	my $connectionInfo="DBI:mysql:database=" . $MAIN_CONF{'mysql.MAIN_PROG_DDBNAME'} . ";" . $MAIN_CONF{'mysql.MAIN_PROG_DBHOST'} . ":" . $MAIN_CONF{'mysql.MAIN_PROG_DBPORT'};   # Database connection string
	# Database handle
	my $dbh;

	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"dbConnect() Connecting to Database : " . $MAIN_CONF{'mysql.MAIN_PROG_DDBNAME'});
	
	unless ( $dbh = DBI->connect($connectionInfo,$MAIN_CONF{'mysql.MAIN_PROG_DBUSER'},$MAIN_CONF{'mysql.MAIN_PROG_DBPASS'}) ) {
	        log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"dbConnect() DBI Error : " . $DBI::errstr);
	        log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"dbConnect() DBI Native error code : " . $DBI::err);
	        if ( defined( $DBI::err ) ) {
	        	clean_and_exit(\%MAIN_CONF,$LOG,undef,$dbh,3);
	        }
	}
	$dbh->{mysql_auto_reconnect} = 1;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"dbConnect() Connected to " . $MAIN_CONF{'mysql.MAIN_PROG_DDBNAME'} . ".");
	my $sQuery = "SET NAMES 'utf8'";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute() ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"dbConnect() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	$sQuery = "SET CHARACTER SET utf8";
	$sth = $dbh->prepare($sQuery);
	unless ($sth->execute() ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"dbConnect() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	$sQuery = "SET COLLATION_CONNECTION = 'utf8_general_ci'";
	$sth = $dbh->prepare($sQuery);
	unless ($sth->execute() ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"dbConnect() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	
	return $dbh;
}

sub dbLogoutUsers(@) {
	my ($Config,$LOG,$dbh) = @_;
	my %MAIN_CONF = %$Config;
	my $sLogoutQuery = "UPDATE USER SET auth=0 WHERE auth=1";
	my $sth = $dbh->prepare($sLogoutQuery);
	unless ($sth->execute) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"dbLogoutUsers() SQL Error : " . $DBI::errstr . "(" . $DBI::err . ") Query : " . $sLogoutQuery);
	}
	else {	
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Logged out all users");
	}
}

sub dbCheckTables(@) {
	my ($Config,$LOG,$dbh) = @_;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"Checking USER table");
	my $sLogoutQuery = "SELECT * FROM USER";
	my $sth = $dbh->prepare($sLogoutQuery);
	unless ($sth->execute) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"dbCheckTables() SQL Error : " . $DBI::errstr . "(" . $DBI::err . ") Query : " . $sLogoutQuery);
		if (defined($DBI::err) && ($DBI::err == 1146)) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"USER table does not exist. Check your database installation");
			clean_and_exit(\%MAIN_CONF,$LOG,undef,$dbh,1146);
		}
	}
	else {	
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"USER table exists");
	}
}

sub logBotAction(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$eventtype,$sNick,$sChannel,$sText) = @_;
	my %MAIN_CONF = %$Config;
	my $sUserhost = "";
	if (defined($message)) {
		$sUserhost = $message->prefix;
	}
	my $id_channel;
	if (defined($sChannel)) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"logBotAction() eventtype = $eventtype chan = $sChannel nick = $sNick text = $sText");
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"logBotAction() eventtype = $eventtype nick = $sNick text = $sText");
	}
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"logBotAction() " . Dumper($message));
	
	my $sQuery = "SELECT * FROM CHANNEL WHERE name=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel) ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"logBotAction() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			$id_channel = $ref->{'id_channel'};
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"logBotAction() ts = " . time2str("%Y-%m-%d %H-%M-%S",time));
			my $sQuery = "INSERT INTO CHANNEL_LOG (id_channel,ts,event_type,nick,userhost,publictext) VALUES (?,?,?,?,?,?)";
			my $sth = $dbh->prepare($sQuery);
			unless ($sth->execute($id_channel,time2str("%Y-%m-%d %H-%M-%S",time),$eventtype,$sNick,$sUserhost,$sText) ) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"logBotAction() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"logBotAction() inserted " . $eventtype . " event into CHANNEL_LOG");
			}
		}
		else {
			my $sQuery = "INSERT INTO CHANNEL_LOG (id_channel,ts,event_type,nick,userhost,publictext) VALUES (?,?,?,?,?,?)";
			my $sth = $dbh->prepare($sQuery);
			unless ($sth->execute($id_channel,time2str("%Y-%m-%d %H-%M-%S",time),$eventtype,$sNick,$sUserhost,$sText) ) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"logBotAction() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,5,"logBotAction() inserted " . $eventtype . " event into CHANNEL_LOG");
			}
		}
	}
}

1;