package Mediabot::Core;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Date::Format;
use Mediabot::Common;
use Mediabot::Database;

@ISA     = qw(Exporter);
@EXPORT  = qw(botAction botNotice botPrivmsg);

sub botPrivmsg(@) {
	my ($Config,$LOG,$dbh,$irc,$sTo,$sMsg) = @_;
	my %MAIN_CONF = %$Config;
	my $eventtype = "public";
	if (substr($sTo, 0, 1) eq '#') {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sTo:<" . $irc->nick_folded . "> $sMsg");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,undef,$eventtype,$irc->nick_folded,$sTo,$sMsg);
	}
	else {
		$eventtype = "private";
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"-> *$sTo* $sMsg");
	}
	$irc->do_PRIVMSG( target => $sTo, text => $sMsg );
}

sub botAction(@) {
	my ($Config,$LOG,$dbh,$irc,$sTo,$sMsg) = @_;
	my %MAIN_CONF = %$Config;
	my $eventtype = "action";
	if (substr($sTo, 0, 1) eq '#') {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$sTo:<" . $irc->nick_folded . ">ACTION $sMsg");
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,undef,$eventtype,$irc->nick_folded,$sTo,$sMsg);
	}
	else {
		$eventtype = "private";
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"-> *$sTo* ACTION $sMsg");
	}
	$irc->do_PRIVMSG( target => $sTo, text => "\1ACTION $sMsg\1" );
}

sub botNotice(@) {
	my ($Config,$LOG,$dbh,$irc,$sTo,$sMsg) = @_;
	my %MAIN_CONF = %$Config;
	$irc->do_NOTICE( target => $sTo, text => $sMsg );
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"-> -$sTo- $sMsg");
	if (substr($sTo, 0, 1) eq '#') {
		logBotAction(\%MAIN_CONF,$LOG,$dbh,$irc,undef,"notice",$irc->nick_folded,$sTo,$sMsg);
	}
}