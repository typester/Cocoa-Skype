use strict;
use warnings;

use Cocoa::Skype;
use Cocoa::EventLoop;

my $skype = Cocoa::Skype->new(
    name => 'my test application',

    on_attach_response => sub {
        my ($self, $code) = @_;
        warn 'attach: ', $code;
    },

    on_notification_received => sub {
        my ($self, $notification) = @_;
        warn 'notification: ', $notification;
    },

    on_became_available => sub {
        my $self = shift;
        warn 'became available';
    },

    on_became_unavailable => sub {
        my $self = shift;
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
            my $res = $skype->send($input);
            warn 'res: ', $res if $res;
        }
    },
);


Cocoa::EventLoop->run;
