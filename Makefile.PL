use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Dancer2::Plugin::TemplateFlute',
    VERSION_FROM  => 'lib/Dancer2/Plugin/TemplateFlute.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Plugin/TemplateFlute.pm',
    AUTHOR        => 'Evan Brown (evan@bottlenose-wine.com)',
    PREREQ_PM     => {
        'Test::Simple' => 0.44,
    },
);
