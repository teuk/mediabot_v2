package Mediabot::Channel;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Mediabot::Common;
use Mediabot::Core;
use Mediabot::Database;

@ISA     = qw(Exporter);
@EXPORT  = qw(joinChannels joinChannel getConsoleChan getIdChannel noticeConsoleChan partChannel getIdChansetList getIdChannelSet);

sub joinChannels(@) {
	# Join channel with auto_join set
	my ($loop,$TVars,$Config,$dbh,$irc,$LOG) = @_;
	my %MAIN_CONF = %$Config;
	my %hTimers = %$TVars;
	my $sQuery = "SELECT * FROM CHANNEL WHERE auto_join=1 and description !='console'";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		my $i = 0;
		while (my $ref = $sth->fetchrow_hashref()) {
			if ( $i == 0 ) {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Auto join channels");
			}
			my $id_channel = $ref->{'id_channel'};
			my $name = $ref->{'name'};
			my $chanmode = $ref->{'chanmode'};
			my $key = $ref->{'key'};
			joinChannel($irc,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,$name,$key);
			$i++;
		}
		if ( $i == 0 ) {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"No channel to auto join");
		}
	}
	
	# Set timers at startup
	$sQuery = "SELECT * FROM TIMERS";
	$sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Checking timers to set at startup");
		my $i = 0;
		while (my $ref = $sth->fetchrow_hashref()) {
			my $id_timers = $ref->{'id_timers'};
			my $name = $ref->{'name'};
			my $duration = $ref->{'duration'};
			my $command = $ref->{'command'};
			my $sSecondText = ( $duration > 1 ? "seconds" : "second" );
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"Timer $name - id : $id_timers - every $duration $sSecondText - command $command");
			my $timer = IO::Async::Timer::Periodic->new(
			    interval => $duration,
			    on_tick => sub {
			    	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"Timer every $duration seconds : $command");
  					$irc->write("$command\x0d\x0a");
					},
			);
			$hTimers{$name} = $timer;
			$loop->add( $timer );
			$timer->start;
			$i++;
		}
		if ( $i ) {
			my $sTimerText = ( $i > 1 ? "timers" : "timer" );
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"$i active $sTimerText set at startup");
		}
		else {
			log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"No timer to set at startup");
		}
	}
	$sth->finish;
	return %hTimers;
}

sub joinChannel(@) {
	my ($irc,$MAIN_PROG_DEBUG,$LOG,$channel,$key) = @_;
	if (defined($key) && ($key ne "")) {
		log_message($MAIN_PROG_DEBUG,$LOG,0,"Trying to join $channel with key $key");
		$irc->send_message("JOIN", undef, ($channel,$key));
	}
	else {
		log_message($MAIN_PROG_DEBUG,$LOG,0,"Trying to join $channel");
		$irc->send_message("JOIN", undef, $channel);
	}
}

sub partChannel(@) {
	my ($irc,$MAIN_PROG_DEBUG,$LOG,$channel,$sPartMsg) = @_;
	if (defined($sPartMsg) && ($sPartMsg ne "")) {
		log_message($MAIN_PROG_DEBUG,$LOG,0,"Parting $channel $sPartMsg");
		$irc->send_message("PART", undef, ($channel,$sPartMsg));
	}
	else {
		log_message($MAIN_PROG_DEBUG,$LOG,0,"Parting $channel");
		$irc->send_message("PART", undef,$channel);
	}
}

sub getConsoleChan(@) {
	my ($dbh,$MAIN_PROG_DEBUG,$LOG) = @_;
	my $sQuery = "SELECT * FROM CHANNEL WHERE description='console'";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute()) {
		log_message($MAIN_PROG_DEBUG,$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			my $id_channel = $ref->{'id_channel'};
			my $name = $ref->{'name'};
			my $chanmode = $ref->{'chanmode'};
			my $key = $ref->{'key'};
			return($id_channel,$name,$chanmode,$key);
		}
		else {
			return (undef,undef,undef,undef);
		}
	}
	$sth->finish;
}

sub noticeConsoleChan(@) {
	my ($Config,$LOG,$dbh,$irc,$sMsg) = @_;
	my %MAIN_CONF = %$Config;
	my ($id_channel,$name,$chanmode,$key) = getConsoleChan($dbh,$MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG);
	unless(defined($name) && ($name ne "")) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"No console chan defined ! Run ./configure to setup the bot");
	}
	else {
		botNotice(\%MAIN_CONF,$LOG,$dbh,$irc,$name,$sMsg);
	}
}

sub getIdChannel(@) {
	my ($Config,$LOG,$dbh,$sChannel) = @_;
	my %MAIN_CONF = %$Config;
	my $id_channel = undef;
	my $sQuery = "SELECT id_channel FROM CHANNEL WHERE name=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel) ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"getIdChannel() SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			$id_channel = $ref->{'id_channel'};
		}
	}
	$sth->finish;
	return $id_channel;
}

sub getIdChansetList(@) {
	my ($Config,$LOG,$dbh,$sChansetValue) = @_;
	my %MAIN_CONF = %$Config;
	my $id_chanset_list;
	my $sQuery = "SELECT id_chanset_list FROM CHANSET_LIST WHERE chanset=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChansetValue) ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			$id_chanset_list = $ref->{'id_chanset_list'};
		}
	}
	$sth->finish;
	return $id_chanset_list;
}

sub getIdChannelSet(@) {
	my ($Config,$LOG,$dbh,$sChannel,$id_chanset_list) = @_;
	my %MAIN_CONF = %$Config;
	my $id_channel_set;
	my $sQuery = "SELECT id_channel_set FROM CHANNEL_SET,CHANNEL WHERE CHANNEL_SET.id_channel=CHANNEL.id_channel AND name=? AND id_chanset_list=?";
	my $sth = $dbh->prepare($sQuery);
	unless ($sth->execute($sChannel,$id_chanset_list) ) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,1,"SQL Error : " . $DBI::errstr . " Query : " . $sQuery);
	}
	else {
		if (my $ref = $sth->fetchrow_hashref()) {
			$id_channel_set = $ref->{'id_channel_set'};
		}
	}
	$sth->finish;
	return $id_channel_set;
}

1;
