use strict;
use warnings;

use Cocoa::Skype;
use Cocoa::EventLoop;

my $skype = Cocoa::Skype->new(
    name => 'my test application',

    on_attach_response => sub {
        warn 'attach: ', $_[0];
    },

    on_notification_received => sub {
        warn 'notification: ', $_[0];
    },

    on_became_available => sub {
        warn 'became available';
    },

    on_became_unavailable => sub {
        warn 'became unavailable';
    },
);

$skype->connect;

my $stdin = Cocoa::EventLoop->io(
    fh   => *STDIN,
    poll => 'r',
    cb   => sub {
        my $input = <STDIN>;
        if (defined $input) {
            $skype->send($input) if $input;
        }
    },
);


Cocoa::EventLoop->run;
