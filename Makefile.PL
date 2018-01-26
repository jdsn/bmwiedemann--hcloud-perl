use ExtUtils::MakeMaker;

WriteMakefile(
  NAME	=> 'hcloud',
  ABSTRACT_FROM => 'hcloud.pm',
  VERSION_FROM => 'hcloud.pm',
  AUTHOR        => 'Bernhard M. Wiedemann (hcloud-perl@lsmod.de)',
  LICENSE => 'GPL',
  MIN_PERL_VERSION => '5.00405',
  META_MERGE => {
    resources => {
      repository => 'http://github.com/bmwiedemann/hcloud-perl',
    },
  },
  BUILD_REQUIRES => {
    'Test::More' => 0,
  },
  PREREQ_PM    => {
    'JSON::XS' => 0,
    'LWP::UserAgent' => 0,
  },
);
