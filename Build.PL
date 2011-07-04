#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Sys::Netswitch',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    dist_abstract => "blah",
    create_readme => 0,
    requires => {
    },
    build_requires => {
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Netswitch',
            bugtracker  => 'http://github.com/exodist/Netswitch/issues',
            homepage    => 'http://open-exodus.net/projects/Fennec'
        },
    }
);

$build->create_build_script;
