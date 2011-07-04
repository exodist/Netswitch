#!/usr/bin/perl
use strict;
use warnings;
use Sys::Netswitch;

Sys::Netswitch->new(
    debug => sub { print @_, "...\n" },
)->run();
