use Test::More tests=>5;
use lib '.';
use hcloud;

# FIXME: tests need a token and server available
# and will break when server output changes -> mock it

my $img = getimage(1);
is($img->{name}, "ubuntu-16.04", "getimage");

my @img = getimages();
is($img[0]->{name}, "ubuntu-16.04", "getimages");

my @img = getimages("?name=debian-9");
is($img[0]->{name}, "debian-9", "getimages with name filter");

my $pricing = getpricing();
is($pricing->{currency}, "EUR", "getpricing");

my @dc = getdatacenters();
is($dc[0]->{name}, "fsn1-dc8", "getdatacenters");
