package Cocoa::Skype;
use strict;
use warnings;
use XSLoader;
use Carp;

our $VERSION = '0.1';

use File::ShareDir ();
use File::Spec;

our $FRAMEWORK_DIR = do {
    (my $dist = __PACKAGE__) =~ s/::/-/g;
    File::Spec->catfile(File::ShareDir::dist_dir($dist), 'Skype.framework');
};

XSLoader::load __PACKAGE__, $VERSION;

do {
    my $INSTANCE;

    sub new {
        my ($class, %args) = @_;

        croak 'Cocoa::Skype is already initialized'
            if $INSTANCE;

        $args{name} ||= __PACKAGE__ . '/' . $VERSION;
        
        $INSTANCE = bless \%args, $class;

        _setup($INSTANCE);

        $INSTANCE;
    }
};

1;

__END__
