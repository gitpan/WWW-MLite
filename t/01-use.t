#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 3 2014-05-20 12:03:24Z minus $
#
#########################################################################
use Test::More tests => 1;
BEGIN { use_ok('WWW::MLite') };
1;
