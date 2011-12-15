    cpanm Module::Install
    cpanm Module::Install::XSUtil
    cpanm --installdeps .
    cpanm Cocoa::EventLoop # for example
    
    perl Makefile.PL
    make
    
    perl -Iblib/lib -Iblib/arch example/example.pl
