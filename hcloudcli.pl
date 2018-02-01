#!/usr/bin/perl -w
use strict;
use JSON::XS;
use Term::ReadLine;
use lib 'lib';
use Net::hcloud;

# example usage:
# json obj output (-f json is default):
# ./hcloudcli.pl 'get_images'
# ./hcloudcli.pl 'get_images {name=>"debian-9"}'
# ./hcloudcli.pl 'get_image 1'
# ./hcloudcli.pl '(get_images {name=>"debian-9"})->[0]->{id}'
# ./hcloudcli.pl "update_ssh_key 1234, {name=>'foo'}"
# ./hcloudcli.pl 1+2
# formatted value output:
# ./hcloudcli.pl '.raw get_image(1)->{name}'
# ./hcloudcli.pl -f raw 'get_image(1)->{name}'
# ./hcloudcli.pl ".c get 'image', 1, 'name', 'type'"
# ./hcloudcli.pl ".shell get 'image', 1"
# interactive mode:
# ./hcloudcli.pl

$| = 1;
our $encoder = JSON::XS->new->allow_nonref->pretty->canonical;
our $defaultoutputformat = "json";
our %outputformatabbrev = (c=>"csv", "j"=>"json", "r"=>"raw", "s"=>"shell");
sub jsonout(@) {$encoder->encode($_[0])}
sub rawout(@) { @_, "\n" }
sub csvout(@) { join("\t", @_)."\n" }
sub shellout(@) {
    if(ref($_[0]) eq "ARRAY") { $_[0] = $_[0]->[0] }
    join("",
        map {
            my $v = $_[0]->{$_}||"";
            $v =~ s/["\\]/\\$&/g;
            "$_=\"$v\"\n"
        }
        (sort keys %{$_[0]}))
}

sub run_line($)
{
    my $in = shift;
    my $outfunc;
    my $outputformat = $defaultoutputformat;
    $in =~ s/^\.(\w+)\s+// and $outputformat = $outputformatabbrev{$1}||$1;
    $outfunc = eval "\\&${outputformat}out";
    no strict;
    my @res = eval $in;
    use strict;
    warn $@ if $@;
    print(&$outfunc(@res)) unless $@;
}

if($ARGV[0] and $ARGV[0] eq "-f") {
    shift;
    $defaultoutputformat = shift;
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
sub quit() { exit 0 }

sub get($$;@)
{
    my $type = shift;
    my $id = shift;
    my $obj = Net::hcloud::get_one_object($type, $id);
    if(@_) {
        return map {$obj->{$_}} @_;
    }
    return $obj;
}

my $term = Term::ReadLine->new('hcloud');
$term->Attribs->{completion_word} = [qw(get help quit), @Net::hcloud::EXPORT];
$term->Attribs->{'completion_entry_function'} = \&hcloud_completion;
my $prompt = "> ";
while ( defined ($_ = $term->readline($prompt)) ) {
    run_line($_);
    $term->addhistory($_) if /\S/;
}
