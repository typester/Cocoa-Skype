use inc::Module::Install;
use File::Spec;

# check OS and version
die 'OS unsupported' unless ($^O eq 'darwin');

name 'Cocoa-Skype';
all_from 'lib/Cocoa/Skype.pm';

requires 'File::ShareDir';

test_requires 'Test::More' => '0.88';

use_ppport '3.19';

if ($ENV{DEBUG}) {
    cc_append_to_ccflags '-g', '-DDEBUG';
}

cc_append_to_ccflags sprintf '-I%s',
    File::Spec->rel2abs(File::Spec->catfile('share', 'Skype.framework', 'Versions', 'A', 'Headers'));
makemaker_args->{dynamic_lib} = {
    OTHERLDFLAGS => '-framework Foundation',
};

install_share;

{
    # http://www.mail-archive.com/makemaker@perl.org/msg02823.html
    # Add some required machinery to support .m files
    package MY;
    sub c_o {
        my $inherited = shift->SUPER::c_o(@_);
        $inherited .= <<'EOMESS';
.m$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.m

EOMESS
        $inherited;
    }

    sub xs_c {
        my $inherited = shift->SUPER::xs_c(@_);
        $inherited .= <<'EOMESS';
.xs.m:
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) $*.xs > $*.xsm && $(MV) $*.xsm $*.m

EOMESS
        $inherited;
    }

    sub init_dirscan {
        my $self = shift;
        $self->SUPER::init_dirscan;
    
        foreach my $name ($self->lsdir($self->curdir)) {
            next unless $name =~ /\.m$/;
            push @{$self->{'C'}}, $name;
            $name =~ s/\.m$/$self->{'OBJ_EXT'}/;
            push @{$self->{'O_FILES'}}, $name;
        }
    }
}

WriteAll;
