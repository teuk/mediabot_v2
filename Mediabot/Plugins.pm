package Mediabot::Plugins;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Switch;
use String::IRC;
use Mediabot::Common;
use Mediabot::Core;
use DateTime;
use DateTime::TimeZone;

@ISA     = qw(Exporter);
@EXPORT  = qw(displayYoutubeDetails mbPluginCommand);

sub mbPluginCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $bFound = 0;
	switch($sCommand) {
		case "plugin"				{ $bFound = 1;
													botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"I'm a dummy plugin");
												}
		case "date"					{ $bFound = 1;
													displayDate(\%MAIN_CONF,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs);
												}
		else								{
													
												}
	}
	return $bFound;
}

sub displayYoutubeDetails(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,$sText) = @_;
	my %MAIN_CONF = %$Config;
	my $sYoutubeId;
	log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() $sText");
	if ( $sText =~ /http.*:\/\/www\.youtube\..*\/watch/i ) {
		$sYoutubeId = $sText;
		$sYoutubeId =~ s/^.*watch\?v=//;
		#my $sTempYoutubeId = ($sText =~ m/^.*(http:\/\/[^ ]+).*$]/)[0];
	}
	elsif ( $sText =~ /http.*:\/\/m\.youtube\..*\/watch/i ) {
		$sYoutubeId = $sText;
		$sYoutubeId =~ s/^.*watch\?v=//;
	}
	elsif ( $sText =~ /http.*:\/\/youtu\.be.*/i ) {
		$sYoutubeId = $sText;
		$sYoutubeId =~ s/^.*youtu\.be\///;
	}
	if (defined($sYoutubeId) && ( $sYoutubeId ne "" )) {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sYoutubeId = $sYoutubeId");
		unless ( open YOUTUBE_INFOS, "plugins/API_Youtube.py --id $sYoutubeId |" ) {
			log_message(0,"Could not open plugins/API_Youtube.py");
		}
		else {
			my $line;
			my $i = 0;
			my $sTitle;
			my $sDuration;
			my $sViewCount;
			while(defined($line=<YOUTUBE_INFOS>)) {
				chomp($line);
				log_message(0,"i = $i line = $line");
				if ( $i == 0 ) {
					$sTitle = $line;
				}
				elsif ( $i == 1 ) {
					$sDuration = $line;
					$sDuration =~ s/^PT//;
					my $sMin = $sDuration;
					$sMin =~ s/M.*$//;
					my $sSec = $sDuration;
					$sSec =~ s/^.*M//;
					$sSec =~ s/S$//;
					$sDuration = $sMin . "mn " . $sSec . "s";
				}
				elsif ( $i == 2 ) {
					$sViewCount = "vue $line fois";
				}
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() $line");
				$i++;
			}
			
			if (defined($sTitle) && ( $sTitle ne "" ) && defined($sDuration) && ( $sDuration ne "" ) && defined($sViewCount) && ( $sViewCount ne "" )) {
				my $sMsgSong .= String::IRC->new('You')->black('white');
				$sMsgSong .= String::IRC->new('Tube')->white('red');
				$sMsgSong .= String::IRC->new(" $sTitle ")->white('black');
				$sMsgSong .= String::IRC->new("- ")->orange('black');
				$sMsgSong .= String::IRC->new("$sDuration ")->grey('black');
				$sMsgSong .= String::IRC->new("- ")->orange('black');
				$sMsgSong .= String::IRC->new("$sViewCount")->grey('black');
				if ($sMsgSong =~ /An HTTP error 400 occurred/) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,0,"displayYoutubeDetails() API Youtube V3 DEV KEY not set in plugins/API_Youtube.py");
				}
				else {
					botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,$sMsgSong);
				}
			}
			else {
				log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() one of the youtube field is undef or empty");
				if (defined($sTitle)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sTitle=$sTitle");
				}
				else {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sTitle is undefined");
				}
				
				if (defined($sDuration)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sDuration=$sDuration");
				}
				else {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sDuration is undefined");
				}
				if (defined($sViewCount)) {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sViewCount=$sViewCount");
				}
				else {
					log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sViewCount is undefined");
				}
			}
		}
	}
	else {
		log_message($MAIN_CONF{'main.MAIN_PROG_DEBUG'},$LOG,3,"displayYoutubeDetails() sYoutubeId could not be determined");
	}
}

sub displayDate(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sNick,$sChannel,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $sDefaultTZ = 'America/New_York';
	if (defined($tArgs[0])) {
		if ( $tArgs[0] =~ /^fr$/i ) {
			$sDefaultTZ = 'Europe/Paris';
		}
		else {
			botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"Invalid parameter");	
			return undef;
		}
	}
	my $time = DateTime->now( time_zone => $sDefaultTZ );
	botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"$sDefaultTZ : " . $time->format_cldr("cccc dd/MM/yyyy HH:mm:ss"));
}