use Test::More tests=>9;

sub c(@)
{
    die "cannot fork: $!" unless defined ($pid = open(SAFE_KID, "-|"));
    if ($pid == 0) {
        exec('./hcloudcli.pl', @_) or die "can't exec hcloudcli.pl: $!";
    } else {
        local $/ = undef;
        $output = <SAFE_KID>;
        close SAFE_KID; # $? contains status
    }
    return $output;
}

is(c('1+2'), "3\n", "default number out");
is(c('-f', 'json', '"foo"."bar"'), "\"foobar\"\n", "json string out");
is(c('.r "foo"."bar"'), "foobar\n", "raw string out");
is(c('.j [1, "foo"]'), "[\n   1,\n   \"foo\"\n]\n", "json out");
is(c('.csv (1, 7, "foo")'), "1\t7\tfoo\n", "csv out");
is(c('-f', 'csv', '(1, 7, "foo")'), "1\t7\tfoo\n", "-f csv out");
is(c('.s {name=>"foo bar\\\\slash\"quote", foo=>27}'), "foo=\"27\"\nname=\"foo bar\\\\slash\\\"quote\"\n", "shell out");
is(c(".c get 'image', 1, 'name', 'type'"), "ubuntu-16.04\tsystem\n", "get element extraction");
#is(c('.raw get_image(1)->{name}'), "ubuntu-16.04\n", "raw image type");
is(c('(get_images {name=>"debian-9"})->[0]->{id}'), "2\n", "get_images");