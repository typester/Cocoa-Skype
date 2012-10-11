package Cocoa::Skype;
use strict;
use warnings;
use XSLoader;
use Carp;

our $VERSION = '0.03';

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

=head1 NAME

Cocoa::Skype - Perl interface to Skype.framework

=head1 SYNOPSIS

  use Cocoa::Skype;
  use Cocoa::EventLoop;

  my $skype = Cocoa::Skype->new(
      name => 'my test application',
      on_attach_response => sub {
          my ($code) = @_;
          if ($code == 1) { # on success
              $self->send('PROTOCOL 8');
          }
      },
      on_notification_received => sub {
          my ($notification) = @_;

          ...
      },
  );
  $skype->connect;

  Cocoa::EventLoop->run;

=head1 DESCRIPTION

Cocoa::Skype provides Perl interface to Skype.framework.

=head1 METHODS

=head2 C<new>

=over 4

=item name => 'Skype::Any' : Str

Name of your application. This name will be shown to the user, when your application uses Skype.

=item on_attach_response => sub { my ($code) = @_; ... }

This callback is called after Skype API client application has called connect.
$code is 0 on failure and 1 on success.

=item on_notification_received => sub { my ($notification) = @_; ... }

This is callback Skype uses to send information to your application.
$notification is Skype API string.

=item on_became_available => sub { ... }

This callback is called after Skype has been launched.

=item on_became_unavailable => sub { ... }

This callback is called after Skype has quit.

=back

=head2 C<connect>

  $skype->connect;

Try to connect your application to Skype.

=head2 C<disconnect>

  $skype->disconnect;

Disconnects your application from Skype.

=head2 C<send>

  $skype->send($msg);

Use this method to control Skype or request information. $msg is a Skype API string.

=head2 C<isRunning>

  $skype->isRunning;

Return 1, when Skype is running and 0 otherwise.

=head2 C<isAvailable>

  $skype->isAvailable;

Return 1, when Skype is available and 0 otherwise.

=head1 AUTHOR

Daisuke Murase E<lt>typester@cpan.orgE<gt>

Takumi Akiyama E<lt>t.akiym at gmail.comE<gt>

=head1 SEE ALSO

L<Public API Reference|https://developer.skype.com/public-api-reference>

L<Skype::Any>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
