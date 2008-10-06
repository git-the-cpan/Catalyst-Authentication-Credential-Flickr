package Catalyst::Authentication::Credential::Flickr;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

BEGIN {
    __PACKAGE__->mk_accessors(qw/_xml _flickr key secret perms/);
}

our $VERSION = "0.01_01";

use Catalyst::Exception ();
use Flickr::API;
use XML::Simple;

sub new {
    my ($class, $config, $c, $realm) = @_;
    my $self = {};
    bless $self, $class;

    # Hack to make lookup of the configuration parameters less painful
    my $params = { %{ $config }, %{ $realm->{config} } };

    # Check for required params (yes, nasty)
    for my $param (qw/key secret perms/) {
        $self->$param($params->{$param}) or
            Catalyst::Exception->throw("$param not defined") 
    }

    # Create a Flickr::API instance
    $self->_flickr(Flickr::API->new({ key => $self->key, 
                                      secret => $self->secret }));

    # Create a XML::Simple instance
    $self->_xml(XML::Simple->new());

    return $self;
}

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

    my $frob = $c->req->params->{frob} or return;
    
    my $api_response = $self->_flickr->execute_method( 'flickr.auth.getToken',
        { frob => $frob, } );

    my $xml = $self->_xml->XMLin($api_response->decoded_content);

    # "Flatten" returned XML a little
    foreach(keys %{$xml->{auth}{user}}) { 
        $xml->{auth}{$_} = delete $xml->{auth}{user}{$_};
    }
    delete $xml->{auth}{user};
    
    my $user_obj = $realm->find_user( $xml->{auth}, $c );
    return ref $user_obj ? $user_obj : undef;
}
    
sub authenticate_flickr_url {
    my ($self, $c) = @_;

    my $uri = $self->_flickr->request_auth_url($self->perms);
    return $uri;
}

=head1 NAME

Catalyst::Authentication::Credential::Flickr - Flickr authentication for Catalyst

=head1 SYNOPSIS

In MyApp.pm

 use Catalyst qw/
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
 /;
 
 MyApp->config(
     "Plugin::Authentication" => {
         default_realm => "flickr",
         realms => {
             flickr => {
                 credential => {
                     class => "Flickr",
                 },

                 key    => 'flickr-key-here',
                 secret => 'flickr-secret-here',
                 perms  => 'read',
             },
         },
     },
 );

And then in your Controller:

 sub login : Local {
    my ($self, $c) = @_;
    
    my $realm = $c->get_auth_realm('flickr');
    $c->res->redirect( $realm->credential->authenticate_flickr_url($c) );
 }

And finally the callback you specified in your API key request (e.g.
example.com/flickr/ ):

 sub flickr : Local {
    my ($self, $c) = @_;
    
    $c->authenticate();
    $c->res->redirect("/super/secret/member/area");
 }

=head1 DESCRIPTION

When L<Catalyst::Plugin::Authentication> 0.10 was released, the API had 
changed, resulting in broken code for some of my projects. They claim to
have some backward compatibility however, so it was most likely just my
own bad coding that broke stuff.

Anyways, L<Catalyst::Plugin::Authentication::Credential::Flickr> didn't
do what I wanted it to do and so I decided to rewrite the code, based on
the new API.

This version tries to follow the guidelines of the new API and should almost
be a drop in replacement for C::P::Authentication::Credential::Flickr. Well,
at least code changes are kept to a minimal.

=head1 METHODS

As per guidelines of L<Catalyst::Plugin::Authentication>, there are two
mandatory methods, C<new> and C<authenticate>. Since this is not really
enough for the Flickr API, I've added one more (and an alias).

=head2 new()

Will not be called by you directly, but will use the configuration you
provide (see above). Mandatory parameters are C<key>, C<secret> and
C<perms>. Please see L<Flickr::API> for more details on them.

=head2 request_auth_url( $c )

This method will return the authentication URL. Bounce your users there
before calling the C<authentication> method.

=head2 authenticate_flickr_url( $c )

Alias for C<request_auth_url> ('cause C::P::Authentication::Credential::Flickr
used to call the method like this).

=head2 authenticate()

Handles the authentication. Nothing more, nothing less.

=head1 AUTHOR

M. Blom
E<lt>blom@cpan.orgE<gt>
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Flickr::API>

=head1 BUGS

C<Bugs? Impossible!>. Please report bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Catalyst-Authentication-Credentials-Flickr>

=head1 THANKS

Thanks go out Daisuke Murase for writing C::P::A::Credential::Flickr,
Ashley Pond for inspiration and help in C::A::Credential::OpenID,
Cal Henderson for Flickr::API.

=cut

1;
