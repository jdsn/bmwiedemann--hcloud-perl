# This file is licensed under GPLv2. See the COPYING file for details.

=head1 NAME

hcloud - access Hetzner cloud services API

=head1 SYNOPSIS

 use hcloud;
 for my $img (getimages()) {
    print "$img->{id} $img->{name}\n";
 }
 my $img = getimage(1);
 print "$img->{id} $img->{name}\n";

=head1 DESCRIPTION

 This module provides access to several APIs of Hetzner cloud services

 currently it knows about these objects:
 actions servers floating_ips locations datacenters images isos server_types
 ssh_keys pricing

 See https://docs.hetzner.cloud/ for which data fields are returned.

=head1 AUTHOR

 Bernhard M. Wiedemann <hcloud-perl@lsmod.de>
 https://github.com/bmwiedemann/hcloud-perl

=cut

use strict;
package hcloud;
use Carp;
use LWP::UserAgent ();
use URI::Escape;
use JSON::XS;
use base 'Exporter';
our @EXPORT=();

our $VERSION = 0.1;
our $debug = $ENV{HCLOUDDEBUG}||0;
our $baseURI = "https://api.hetzner.cloud/";
our $UA = LWP::UserAgent->new(requests_redirectable=>[],
    parse_head=>0, timeout=>9,
    agent=>"https://github.com/bmwiedemann/hcloud-perl $VERSION");
our $token = `cat ~/.hcloudapitoken`; chomp($token);

sub apireq($$)
{
    my $method = shift;
    my $uri = $baseURI.shift;
    my $request = HTTP::Request->new($method, $uri);
    $request->header("Authorization", "Bearer $token");
    my $response = $UA->request($request);
    if($debug) {
        print STDERR "Request: $uri\n";
        print STDERR "status: ", $response->code, " ", $response->message, "\n";
        for my $h (qw(Content-Type RateLimit-Limit RateLimit-Remaining RateLimit-Reset)) {
            print STDERR $h, ": ", $response->header($h), "\n";
        }
        print STDERR $response->content;
    }
    return decode_json($response->content);
}

sub apiget($)
{
    return apireq("GET", shift);
}

sub badreply($)
{
    print STDERR JSON::XS->new->pretty->encode( shift );
    carp "bad/unexpected API reply";
}

# in: hashref e.g. {name=>"foo", sort=>"type"}
# out: url-encoded param string: "name=foo&sort=type"
sub hash_to_uri_param($)
{
    my $h=shift;
    return join('&', map {"$_=".uri_escape($h->{$_})} sort keys(%$h));
}

sub getobjects($;$$)
{
    my $object = shift;
    my $extra = shift || "";
    if(ref($extra) eq "HASH") {$extra="?".hash_to_uri_param($extra)}
    my $targetkey = shift || $object;
    my $result = apiget("v1/$object$extra");
    my $r = $result->{$targetkey};
    badreply($result) unless $r;
    if(ref($r) eq "ARRAY") { return @$r }
    return $r;
}

sub getoneobject($$;$)
{
    my $object = shift;
    my $id = shift;
    my $extra = shift || "";
    getobjects("${object}s/$id", $extra, $object);
}

for my $o (qw(actions servers floating_ips locations datacenters images isos server_types ssh_keys pricing)) {
    eval "sub get${o}(;\$) { getobjects('${o}', shift) }";
    push(@EXPORT, "get$o");
    if($o =~m/(.*)s$/) {
        my $singular = $1;
        eval "sub get${singular}(\$;\$) { getoneobject('${singular}', shift) }";
        push(@EXPORT, "get$singular");
    }
}

1;
