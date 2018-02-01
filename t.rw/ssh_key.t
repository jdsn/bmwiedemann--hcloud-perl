use Test::More tests=>9;
use lib 'lib';
use Net::hcloud;

# FIXME: tests need a token and server available
# and will break when server output changes -> mock it

# note: will do write operations on server - run it scarcely

my $newkey = add_ssh_key("test", "ssh-dss AAAAB3NzaC1kc3MAAACBAK14UGK8CohXq1mS/OZy0k/TVeUwsM5Smfpvat0gLQ/kPjl1CYr8flgB7qdYLJfp64LoLcivQQElLX9xxOgAig/v6PrzMT0b8UUKzLN3OZMng/YxD4kVYkaaLWWIGRbmeJY1k0SUv8Rm7ae+0UbU8hHfEzXGBikNFbuQIAQoMwuRAAAAFQCmJDjYwoikIHhkaDTXGvLW7HD1dQAAAIBq9iw4IPxDWp3fyo9sBLv6V7+x+C0MnBaC72vduwZ9vvh5NwoOtBoIULLVdha4GI1Kf5yUO0u6dyVSxbjfC6jg4VZyMSssvN7XUOK0SDzVffK5i0ByTaeKYg1a+fbonT0vbKuwGEUCtXuwDUfJybtZx4jK2AF2n8dd2mISqgelNQAAAIB0ncD+X2mUpRYs4IKeR/KhVgw4k47RDB4wo7BwXp75ptUCoHoKVdIknN+WjATqWa3oeIKlwUb+QqXvwHn0BVgrX4f+S6HzL8YnYPx6UZEDRGC3GDfQ8p8DN7s+brBawjo0aPwJIIdAh7T3XojWL/nRegeczKBRkFqpR/zq2ZfDgg== root\@lsmod.de");
is($newkey->{name}, "test", "add_ssh_key");
print STDERR "new key ID=$newkey->{id}\n";
my $renamedkey = eval{update_ssh_key($newkey->{id}, {name=>"test2"})};
my $keys = eval{get_ssh_keys({name=>"test2"})};
del_ssh_key($newkey->{id});

is($renamedkey->{name}, "test2", "rename changed name");
is($renamedkey->{id}, $newkey->{id}, "rename kept id");
is($renamedkey->{fingerprint}, $newkey->{fingerprint}, "rename kept fingerprint");
is($renamedkey->{public_key}, $newkey->{public_key}, "rename kept public_key");

is($#$keys, 0, "1 matching key returned");
is($keys->[0]->{name}, $renamedkey->{name}, "renamed key found has correct name");
is($keys->[0]->{id}, $renamedkey->{id}, "renamed key found has correct id");

my $nokey = eval {get_ssh_key($newkey->{id})};
is($nokey, undef, "key gone after delete");
