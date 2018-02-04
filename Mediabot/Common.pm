package Mediabot::Common;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Date::Format;

@ISA     = qw(Exporter);
@EXPORT  = qw(log_message init_log init_pid clean_and_exit getMessageHostmask getMessageNickIdentHost);

sub init_log(@) {
	my ($Config) = @_;
	my %MAIN_CONF = %$Config;
	my $sLogFilename = $MAIN_CONF{'main.MAIN_LOG_FILE'};
	my $LOG;
	unless (open $LOG, ">>$sLogFilename") {
		print STDERR "Could not open $sLogFilename for writing.\n";
		clean_and_exit(\%MAIN_CONF,undef,undef,undef,1);
	}
	$|=1;
	print $LOG "+--------------------------------------------------------------------------------------------------+\n";
	return $LOG;
}

sub log_message(@) {
	my ($MAIN_PROG_DEBUG,$LOG,$iLevel,$sMsg) = @_;
	if (defined($sMsg) && ($sMsg ne "")) {
		my $sDisplayMsg = time2str("[%d/%m/%Y %H:%M:%S]",time) . " ";
		select $LOG;
		$|=1;
		if ( $MAIN_PROG_DEBUG >= $iLevel ) {
			if ( $iLevel == 0 ) {
				$sDisplayMsg .= "$sMsg\n";
				print $LOG $sDisplayMsg;
			}
			else {
				$sDisplayMsg .= "[DEBUG" . $iLevel . "] $sMsg\n";
				print $LOG $sDisplayMsg;
			}
			select STDOUT;
			print $sDisplayMsg;
		}
	}
}

sub init_pid(@) {
	my ($Config,$LOG,$irc) = @_;
	my %MAIN_CONF = %$Config;
	my $sPidFilename = $MAIN_CONF{'main.MAIN_PID_FILE'};
	unless (open PID, ">$sPidFilename") {
		print STDERR "Could not open $sPidFilename for writing.\n";
		clean_and_exit(\%MAIN_CONF,$LOG,undef,undef,2);
	}
	else {
		# TBD schedule pid refresh
		#if (defined($irc)) {
		#	$conn->schedule(120, \&init_pid, $MAIN_PID_FILE);
		#}
		print PID "$$";
		close PID;
	}
}

sub clean_and_exit(@) {
	my ($Config,$LOG,$irc,$dbh,$iRetValue) = @_;
	my %MAIN_CONF = %$Config;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Cleaning and exiting...");
	# TBD disconnect
	if (defined($irc) && 0) {
		#if ( $conn->{'connected'} eq 1 ) {
		#	$conn->quit($CONN_DEFAULT_QUIT_MSG);
		#	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Quits " . $irc->nick_folded . " : $CONN_DEFAULT_QUIT_MSG");
		#}
	}
	if (defined($dbh) && ($dbh != 0)) {
		if ( $iRetValue != 1146 ) {
			#dbLogoutUsers();
		}
		$dbh->disconnect();
	}
	
	if(defined(fileno(LOG))) { close LOG; }
	
	exit $iRetValue;
}

sub getMessageHostmask(@) {
	my ($message) = @_;
	my $sHostmask = $message->prefix;
	$sHostmask =~ s/.*!//;
	if (substr($sHostmask,0,1) eq '~') {
		$sHostmask =~ s/.//;
	}
	return ("*" . $sHostmask);
}

sub getMessageNickIdentHost(@) {
	my ($message) = @_;
	my $sNick = $message->prefix;
	$sNick =~ s/!.*$//;
	my $sIdent = $message->prefix;
	$sIdent =~ s/^.*!//;
	$sIdent =~ s/@.*$//;
	my $sHost = $message->prefix;
	$sHost =~ s/^.*@//;
	
	return ($sNick,$sIdent,$sHost);
}

1;
