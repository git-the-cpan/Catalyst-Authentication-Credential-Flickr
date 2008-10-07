use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Catalyst::Authentication::Credential::Flickr',
    VERSION_FROM => 'lib/Catalyst/Authentication/Credential/Flickr.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Flickr authentication for Catalyst',
    PREREQ_PM    => {
                     'Catalyst::Plugin::Authentication' => 0.10,
                     'Class::Accessor::Fast'            => 0,
                     'Flickr::API'                      => 1.00,
                     'LWP::UserAgent'                   => 5.802,
                     'Test::MockObject'                 => 0,
                     'Test::More'                       => 0,
                     'XML::Simple'                      => 0,
                    },
);
