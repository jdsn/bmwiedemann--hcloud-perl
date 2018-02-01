use ExtUtils::MakeMaker;

WriteMakefile(
  NAME	=> 'Net::hcloud',
  ABSTRACT_FROM => 'lib/Net/hcloud.pm',
  VERSION_FROM => 'lib/Net/hcloud.pm',
  AUTHOR        => 'Bernhard M. Wiedemann (hcloud-perl@lsmod.de)',
  LICENSE => 'GPL',
  MIN_PERL_VERSION => '5.00405',
  META_MERGE => {
    resources => {
      repository => 'http://github.com/bmwiedemann/hcloud-perl',
    },
  },
  EXE_FILES => ['hcloudcli.pl'],
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'YAML' => 0,
  },
  PREREQ_PM    => {
    'JSON::XS' => 0,
    'LWP::UserAgent' => 0,
    'Term::ReadLine::Gnu' => 0,
  },
);
