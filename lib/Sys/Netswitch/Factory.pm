package Sys::Netswitch::Factory;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/gen_accessor gen_accessors gen_default_accessor/;

sub gen_accessor {
    my ( $name, $package ) = @_;
    $package ||= caller;
    no strict 'refs';
    *{"$package\::$name"} = sub {
        my $self = shift;
        ( $self->{$name} ) = @_ if @_;
        return $self->{$name}
    };
}

sub gen_accessors {
    my @names = @_;
    my $package = caller;
    gen_accessor( $_, $package ) for @names;
}

sub gen_default_accessor {
    my ( $name, $default ) = @_;
    my $package = caller;
    gen_accessor( "_$name", $package );

    no strict 'refs';
    *{"$package\::$name"} = sub {
        my $self = shift;

        ( $self->{$name} ) = @_ if @_;

        unless (exists $self->{$name}) {
            if ( ref $default eq 'CODE' ) {
                $self->{$name} = $default->( $self );
            }
            else {
                $self->{$name} = $default;
            }
        }

        return $self->{$name}
    };
}

1;
