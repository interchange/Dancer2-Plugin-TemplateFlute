# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Dancer2::Plugin::Form' ); }

my $object = Dancer2::Plugin::Form->new ();
isa_ok ($object, 'Dancer2::Plugin::Form');


