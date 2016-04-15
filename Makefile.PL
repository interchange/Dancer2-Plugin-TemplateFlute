use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Dancer2::Plugin::TemplateFlute',
    VERSION_FROM   => 'lib/Dancer2/Plugin/TemplateFlute.pm',
    ABSTRACT_FROM  => 'lib/Dancer2/Plugin/TemplateFlute.pm',
    AUTHOR         => 'Evan Brown (evan@bottlenose-wine.com)',
    BUILD_REQUIRES => {
        'aliased'       => 0,
        'JSON::MaybeXS' => 0,
        'Test::More'    => '0.94',    # subtest
        'Test::Deep'    => 0,
        'Test::Fatal'   => 0,
    },
    PREREQ_PM => {
        'Carp'             => 0,
        'Dancer2'          => '0.159002', # TODO: update with plugin2 min ver
        'Dancer2::Plugin'  => '0.159002', # TODO: update with plugin2 min ver
        'Hash::MultiValue' => '0.12',
        'Moo'              => '2.000000',
        'namespace::clean' => 0,
        'Type::Tiny'       => 0,
    },
);
