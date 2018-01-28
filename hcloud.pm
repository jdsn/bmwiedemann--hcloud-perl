# This file is licensed under GPLv2. See the COPYING file for details.

=head1 NAME

hcloud - access Hetzner cloud services API

=head1 SYNOPSIS

 use hcloud;
 for my $img (get_images()) {
    print "$img->{id} $img->{name}\n";
 }
 my $img = get_image(1);
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

sub api_req($$;$)
{
    my $method = shift;
    my $uri = $baseURI.shift;
    my $request_body = shift;
    my $request = HTTP::Request->new($method, $uri);
    if($request_body) {
        $request->content(encode_json $request_body);
    }
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

sub api_get($)
{
    return api_req("GET", shift);
}

sub bad_reply($)
{
    print STDERR JSON::XS->new->pretty->canonical->encode( shift );
    confess "bad/unexpected API reply";
}

# in: hashref e.g. {name=>"foo", sort=>"type"}
# out: url-encoded param string: "name=foo&sort=type"
sub hash_to_uri_param($)
{
    my $h=shift;
    return join('&', map {"$_=".uri_escape($h->{$_})} sort keys(%$h));
}

sub req_objects($$;$$$)
{
    my $method = shift;
    my $object = shift;
    my $extra = shift || "";
    if(ref($extra) eq "HASH") {$extra="?".hash_to_uri_param($extra)}
    my $targetkey = shift || $object;
    my $request_body = shift;
    my $result = api_req($method, "v1/$object$extra", $request_body);
    my $r = $result->{$targetkey};
    bad_reply($result) unless $r;
    if(ref($r) eq "ARRAY") { return @$r }
    return $r;
}

sub get_objects($;$$)
{
    req_objects("GET", shift, shift, shift);
}

sub get_one_object($$;$)
{
    my $object = shift;
    my $id = shift;
    my $extra = shift || "";
    get_objects("${object}s/$id", $extra, $object);
}

for my $o (qw(actions servers floating_ips locations datacenters images isos server_types ssh_keys pricing)) {
    my $f = "get_${o}";
    eval "sub $f(;\$) { get_objects('${o}', shift) }";
    push(@EXPORT, $f);
    if($o =~m/(.*)s$/) {
        my $singular = $1;
        $f = "get_${singular}";
        eval "sub $f(\$;\$) { get_one_object('${singular}', shift) }";
        push(@EXPORT, $f);
    }
}
for my $o (qw(actions metrics)) {
    my $f = "get_server_$o";
    eval "sub $f(\$;\$) { my \$id=shift; get_objects(\"servers/\$id/${o}\", shift, '$o') }";
    push(@EXPORT, $f);
}

1;
