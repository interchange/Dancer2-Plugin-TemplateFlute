

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Dancer2::Plugin::Form',
    VERSION_FROM => 'lib/Dancer2/Plugin/Form.pm', # finds \$VERSION
    AUTHOR       => 'Evan Brown (evan@bottlenose-wine.com)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
