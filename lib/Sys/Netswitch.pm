package Sys::Netswitch;
use strict;
use warnings;
use Sys::Netswitch::Factory;

our $VERSION = '0.001';

our %STATES = (
    start => 2,
    on => 1,
    off => 0,
);

gen_accessors qw/ config_file running dhcp_pid wifi_pid /;
gen_default_accessor state => $STATES{start};
gen_default_accessor physical => "eth0";
gen_default_accessor wireless => "wlan0";
gen_default_accessor dhcp_prog => '/sbin/dhcpcd -B -t 10 -d ';
gen_default_accessor wifi_prog => "wpa_supplicant -Dwext -c /etc/wpa_supplicant/wpa_supplicant.conf -i";
gen_default_accessor debug => sub {};

sub new {
    my $class = shift;
    my %params = @_;
    return bless \%params, $class
}

sub run {
    my $self = shift;

    $self->running(1);
    $self->debug->( "Netswitch starting" );
    $self->physical_on();
    $self->state( $STATES{on});
    sleep 5;

    while ( $self->running ) {
        $self->switch if $self->state_changed;
        sleep 1;
    }
}

sub state_changed {
    my $self = shift;
    my $state = $self->refresh_state;
    return 0 if $state == $self->state;
    $self->debug->( "physical connection state change" );
    $self->state( $state );
    return 1;
}

sub refresh_state {
    my $self = shift;
    my $net = $self->physical;
    open( my $state_file, "<", "/sys/class/net/$net/carrier" ) || die "$!";
    chomp( my $state = <$state_file> || 0 );
    close( $state_file );
    return $state;
}

sub switch {
    my $self = shift;
    $self->debug->( "Switching Connections" );
    return $self->do_physical() if $self->state;
    return $self->do_wireless();
}

sub do_physical {
    my $self = shift;
    $self->wireless_off;
    $self->physical_on;
}

sub do_wireless {
    my $self = shift;
    $self->physical_off;
    $self->wireless_on;
}

sub physical_on {
    my $self = shift;
    $self->debug->( "Starting physical connection" );
    $self->dhcp_start( $self->physical );
}

sub physical_off {
    my $self = shift;
    $self->debug->( "Stopping physical connection" );
    $self->dhcp_stop;
}

sub wireless_on {
    my $self = shift;
    $self->debug->( "Starting wireless connection" );

    my $pid = fork();

    exec( $self->wifi_prog . $self->wireless )
        unless $pid;

    $self->wifi_pid( $pid );

    $self->dhcp_start( $self->wireless );
}

sub wireless_off {
    my $self = shift;
    $self->dhcp_stop();

    return unless $self->wifi_pid;
    $self->debug->( "Stopping wireless connection" );

    kill( 15, $self->wifi_pid ) || die "Could not kill wifi";
    waitpid( $self->wifi_pid, 0 );

    $self->wifi_pid(undef);
}

sub dhcp_start {
    my $self = shift;
    my ( $if ) = @_;
    $self->debug->( "Starting DHCP $if" );

    my $pid = fork();

    exec $self->dhcp_prog . " $if"
        unless $pid;

    $self->dhcp_pid( $pid );
}

sub dhcp_stop {
    my $self = shift;
    return unless $self->dhcp_pid;
    $self->debug->( "Stopping DHCP" );

    kill( 15, $self->dhcp_pid ) || die "Could not kill dhcp";
    waitpid( $self->dhcp_pid, 0 );

    $self->dhcp_pid(undef);
}

1;
