#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'CTK'                   => 1.16,
        'DBI'                   => 0,
        'Digest::MD5'           => 2.36,
        'Module::Load'          => 0,
    };

WriteMakefile(
    'NAME'                  => 'WWW::MLite',
    'DISTNAME'              => 'WWW-MLite',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/WWW/MLite.pm', 
    'ABSTRACT_FROM'         => 'lib/WWW/MLite.pm', ,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'gpl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.com',
            repository      => 'http://svn.serzik.com/WWW-MLite/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
);

1;
