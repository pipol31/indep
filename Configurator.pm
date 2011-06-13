package Configurator;
##
# Configuration file
##
our $cfg = {
	inventory_file => "ov_inventory_report.xml",
	done_file => "done.log",
	error_file => "error.csv",
	tempo_file => "tempo.cfg",
	log4perl       => eval(
		"<<'EOT';
log4perl.category = DEBUG, Screen, LogFile
log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %-10.10M{1} %m%n
log4perl.appender.LogFile = Log::Log4perl::Appender::File
log4perl.appender.LogFile.filename = indep.log
log4perl.appender.LogFile.mode = append
log4perl.appender.LogFile.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LogFile.layout.ConversionPattern = %d %-5p %-10.10M{1} %m%n
EOT"
	)
};

1;
