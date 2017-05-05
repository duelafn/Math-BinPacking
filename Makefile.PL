use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Math::BinPacking',
    VERSION_FROM  => 'lib/Math/BinPacking.pm',
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    PL_FILES      => {},
    ABSTRACT      => 'Implements several simple bin packing algorithms',
    AUTHOR        => 'Dean Serenevy <dean@serenevy.net>',
);
