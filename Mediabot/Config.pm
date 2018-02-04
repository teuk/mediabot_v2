package Mediabot::Config;

use     strict;
use     vars qw(@EXPORT @ISA);
require Exporter;
use Date::Format;

@ISA     = qw(Exporter);
@EXPORT  = qw(readConfigFile);

sub readConfigFile(@) {
	my ($configFile) = @_;
	#my %MAIN_CONF = %$Config;
	unless ( -r $configFile ) {
		print STDERR time2str("[%d/%m/%Y %H:%M:%S]",time) . " Cannot open $configFile\n";
		exit 1;
	}
	print STDERR time2str("[%d/%m/%Y %H:%M:%S]",time) . " Reading configuration file $configFile\n";
	my $cfg = new Config::Simple();
	$cfg->read($configFile) or die $cfg->error();;
	#%MAIN_CONF = $cfg->vars();
	#$cfg->import_from($configFile, \%Config) or die Config::Simple->error();
	#Config::Simple->import_from($configFile, \%Config) or die Config::Simple->error();
	print STDERR time2str("[%d/%m/%Y %H:%M:%S]",time) . " $configFile loaded.\n";
	return $cfg;
}

1;
