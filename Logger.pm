package Logger;

use strict;
use Log::Log4perl qw(:easy :levels);
use PadWalker qw(var_name);
use Data::Dumper;
use Configurator;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(trace debug info error debug_dump error_dump debug_argv);

Log::Log4perl->init(\$Configurator::cfg->{log4perl});

our $logger = get_logger();

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse  = 1;

sub trace {
	_log( $TRACE, @_ ) if $TRACE;
}

sub info {
	_log( $INFO, @_ ) if $INFO;
}

sub debug {
	_log( $DEBUG, @_ ) if $DEBUG;
}

sub error {
	_log( $ERROR, @_ ) if $ERROR;
}

sub debug_dump {
	_log_dump( $DEBUG, @_ ) if $DEBUG;
}

sub error_dump {
	_log_dump( $ERROR, @_ ) if $ERROR;
}

sub _log {
	my $log_level = shift;
	my $format    = shift;
	my @argv;
	my $arg;
	my $log_message;
	my $count;
	local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 2;
	foreach (@_) {
		$arg = _dump_var($_);
		push( @argv, $arg );
	}
	if (@argv) {
		$count = ( $format =~ tr/\%/\%/ );
		if ( $count != scalar(@_) ) {
			while ( $count >= scalar(@argv) ) {
				push( @argv, 'undef' );
			}
		}
		$log_message = sprintf( $format, @argv );
	}
	else {
		$log_message = $format;
	}
	$log_message =~ s/\n/\\n/g;
	$logger->log( $log_level, $log_message );
}

sub _dump_var {
	my $var     = shift;
	my $var_ref = ref($var);
	if ( ( $var_ref eq 'ARRAY' ) or ( $var_ref eq 'HASH' ) ) {
		return Data::Dumper->Dump( [$var] );
	}
	if ( defined($var) ) {
		return $var;
	}
	return 'undef';
}

sub _log_dump {
	my $log_level   = shift;
	my $log_message = '';
	local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 2;
	foreach (@_) {
		$log_message =
		    $log_message . ', '
		  . var_name( $Log::Log4perl::caller_depth, $_ ) . ' = '
		  . _dump_ref($_);
	}
	$log_message = substr( $log_message, 2 );
	$log_message =~ s/\n/\\n/g;
	$logger->log( $log_level, $log_message );
}

sub _dump_ref {
	my $ref = shift;
	my $ref_ref;
	$ref_ref = ref($ref);
	if ( ( $ref_ref eq 'ARRAY' ) or ( $ref_ref eq 'HASH' ) ) {
		return Data::Dumper->Dump( [$ref], ["*"] );
	}
	return _dump_var( ${$ref} );
}

sub debug_argv {
	local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
	$logger->debug( '@_ = ', _dump_ref(@_) ) if $DEBUG;
}

1;
