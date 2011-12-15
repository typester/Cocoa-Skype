use strict;
use warnings;

use Cocoa::Skype;
use Cocoa::EventLoop;
use AnyEvent;

my $skype = Cocoa::Skype->new(
    name => 'my test application',

    on_attach_response => sub {
        warn 'attach: ', $_[0];
    },

    on_notification_received => sub {
        my ($msg) = @_;
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

my $stdin; $stdin = AE::io *STDIN, 0, sub {
    my $input = <STDIN>;
    return unless defined $input;

    $skype->send($input);
};

AE::cv->recv;
