use strict;
use warnings;
use Configurator;
use XML::Simple;
use Time::HiRes qw( usleep);
use IO::CaptureOutput qw(capture_exec);
use Win32::OLE;

my $cfg = $Configurator::cfg;
my $completed_nodes;
my $done;

my $swbem_locator;
my $swbem_services;

sub main {
	my $policies;
	my @policies;
	my $policy;
	my @nodes;
	my $node;
	my $i;
	my $stdout;
	my $stderr;
	my @stdout;
	my $error;
	my $node_name;


    # Load the inventory report
	my $inventory = (
			new XML::Simple(
				ForceArray => 1,
				KeyAttr    => []
				)
			)->XMLin( $cfg->{inventory_file} );

	$swbem_locator = Win32::OLE->new('WbemScripting.SWbemLocator');
	$swbem_services =
		$swbem_locator->ConnectServer( $ENV{COMPUTERNAME},
				'root\hewlettpackard\openview\data' );

    # Get the policy items
	@policies = @{ $inventory->{policies}[0]->{policy} };

    # Create a hashtable of policy names
	foreach $policy (@policies) {
		$policies->{ $policy->{GUID} } = $policy->{name};
	}

   # Load the completed nodes
	get_completed_nodes();

    # Get the nodes items
	@nodes = @{ $inventory->{nodes}[0]->{node} };
	foreach $node (@nodes) {
		my $pol_state;
        # If the node has not been processed
		if ( !defined( $completed_nodes->{ $node->{name} } ) ) {
			if ( defined( $node->{policy} ) ) {
                # Get the policy items
				@policies = @{ $node->{policy} };

                # Build an array of policy names
				foreach $policy (@policies) {
					my $state = $policy->{state};
					$policy = $policies->{ $policy->{GUID} };
					$pol_state->{$policy} = $state;
				}
				$i         = 0;
				$error     = 0;
				foreach $policy (@policies) {
                    # Manage disabled/enabled policy state
					my $option = policy_state ( $pol_state->{$policy} );

					$i++;					
					print(  "ovpmutil.exe dep /pn " 
							. $policy . " /np "
							. $node_name
							. "$option\n" );
					( $stdout, $stderr ) =
						capture_exec( "ovpmutil.exe dep /pn " 
								. $policy . " /np "
								. $node_name 
								. " $option" );
					print( "stdout: " . $stdout );
					@stdout = split( /\n/, $stdout );
					$stdout = pop(@stdout);
					if ( !( $stdout eq "Operation completed successfully." ) ) {
						$error = 1;
						error( $node_name, $policy, $stdout );
					}
				}
                # Mark the node as completed
				if ( !($error) ) {
					done( $node->{name} );
				}

                # Give time to complete the deployment jobs
				usleep( tempo() * $i );
			}
		}
	}
}

sub policy_state {
	my ( $ref_polstate ) = @_;

	if ( $ref_polstate =~ /disabled/ ){
		return '/e FALSE';
	} 
	else {
		return '';
	}
}

sub get_completed_nodes {
	if ( -e $cfg->{done_file} ) {

# Read the done log
		open( FH, '<', $cfg->{done_file} ) or die $!;

# Build a hashtable of completed node
		while (<FH>) {
			my $node = $_;
			chomp $node;
			$completed_nodes->{$node} = 1;
		}
		close(FH) or die $!;
	}
}

sub done {
	my $node = shift;

# Write the node to the done log
	open( FH, '>>', $cfg->{done_file} ) or die $!;
	print( FH $node . "\n" );
	close(FH) or die $!;
	$completed_nodes->{$node} = 1;
}

sub error {
	my ( $node, $policy, $msg ) = @_;

# Write an error entry
	open( FH, '>>', $cfg->{error_file} ) or die $!;
	print( FH $node . "\t" . $policy . "\t" . $msg . "\n" );
	close(FH) or die $!;
}

sub tempo() {
	my $tempo = 1;
	if ( -e $cfg->{done_file} ) {

# Read the tempo file
		open( FH, '<', $cfg->{tempo_file} ) or die $!;
		$tempo = <FH>;
		close(FH) or die $!;
		$tempo = $tempo * 1000000;
		print( "tempo: " . $tempo . "\n" );
	}
	return $tempo;
}

sub primary_node_name {
	my $node_guid = shift;
	my $node =
		$swbem_services->Get( "OV_ManagedNode.Name='{" . $node_guid . "}'" );
	return $node->{PrimaryNodeName};
}

main();

