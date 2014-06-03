#!/usr/bin/perl -wT
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: pod-coverage.t 9 2014-05-22 13:59:37Z minus $
#
#########################################################################

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 6;

#plan skip_all => "Currently FAILS FOR MANY MODULES!";
#all_pod_coverage_ok();

pod_coverage_ok( "WWW::MLite", { trustme => [qr/^(new)$/] } );

# WWW::MLite::*
pod_coverage_ok( "WWW::MLite::Config" );
pod_coverage_ok( "WWW::MLite::Transaction" );
pod_coverage_ok( "WWW::MLite::Util" );
pod_coverage_ok( "WWW::MLite::Log" );

# WWW::MLite::Store::*
pod_coverage_ok( "MPMinus::Store::DBI", { trustme => [qr/^(new)$/] } );

1;
