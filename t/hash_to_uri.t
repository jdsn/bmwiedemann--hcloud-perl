use Test::More tests=>3;
use lib '.';
use hcloud;

is(hcloud::hash_to_uri_param({}), "", "0 params");
is(hcloud::hash_to_uri_param({name=>"foo bar&baz"}), "name=foo%20bar%26baz", "1 param with encoding");
is(hcloud::hash_to_uri_param({name=>"foo", sort=>"type"}), "name=foo&sort=type", "multiple params");
