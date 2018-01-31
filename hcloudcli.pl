#!/usr/bin/perl -w
use strict;
use JSON::XS;
use Term::ReadLine;
use lib 'lib';
use Net::hcloud;

# example usage:
# json list output:
# ./hcloudcli.pl '[get_images]'
# json obj output:
# ./hcloudcli.pl 'get_images {name=>"debian-9"}'
# ./hcloudcli.pl 'get_image 1'
# ./hcloudcli.pl '(get_images {name=>"debian-9"})[0]->{id}'
# ./hcloudcli.pl 1+2
# raw value output:
# ./hcloudcli.pl '.get_image(1)->{name}'
# interactive mode:
# ./hcloudcli.pl

$| = 1;
our $encoder = JSON::XS->new->allow_nonref->pretty->canonical;
sub jsonout(@) {$encoder->encode($_[0])}
sub rawout(@) { @_, "\n" }

sub run_line($)
{
    my $in = shift;
    my $outfunc = \&jsonout;
    $in =~ s/^\.// and $outfunc = \&rawout;
    no strict;
    my @res = eval $in;
    use strict;
    warn $@ if $@;
    print(&$outfunc(@res)) unless $@;
}

# non-interactive mode:
my $exit = 0;
while(@ARGV) {
    $exit = 1;
    run_line(shift);
}
exit(0) if $exit;

# interactive mode:
sub hcloud_completion
{
    my ($text, $state) = @_;
#    print STDERR "text=$text state=$state\n"; # debug
    return Term::ReadLine::Gnu->list_completion_function($text, $state);
}

sub help()
{ system('perldoc Net::hcloud') }

my $term = Term::ReadLine->new('hcloud');
$term->Attribs->{completion_word} = [@Net::hcloud::EXPORT];
$term->Attribs->{'completion_entry_function'} = \&hcloud_completion;
my $prompt = "> ";
while ( defined ($_ = $term->readline($prompt)) ) {
    run_line($_);
    $term->addhistory($_) if /\S/;
}
