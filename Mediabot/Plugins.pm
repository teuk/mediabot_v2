package Mediabot::Plugins;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;

use Switch;
use Mediabot::Core;

@ISA     = qw(Exporter);
@EXPORT  = qw(mbPluginCommand);

sub mbPluginCommand(@) {
	my ($Config,$LOG,$dbh,$irc,$message,$sChannel,$sNick,$sCommand,@tArgs) = @_;
	my %MAIN_CONF = %$Config;
	my $bFound = 0;
	switch($sCommand) {
		case "plugin"				{ $bFound = 1;
													botPrivmsg(\%MAIN_CONF,$LOG,$dbh,$irc,$sChannel,"I'm a dummy plugin");
												}
		else								{
													
												}
	}
}