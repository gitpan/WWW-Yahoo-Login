# $Id: Login.pm,v 1.10 2003/08/06 07:53:19 struan Exp $
package WWW::Yahoo::Login;

use strict;

use constant LOGIN_FORM =>  'login_form';
use constant BAD_PASS   =>  '';
use constant BAD_ID     =>  '';

use Exporter ();
use vars qw($VERSION $ERROR @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw ();
@EXPORT_OK = qw( login logout );
%EXPORT_TAGS = ();

$VERSION = '0.10';

sub login {
    my %params = @_;

    my @missing = grep { ! defined $params{$_} } qw( mech uri user pass );

    if ( @missing ) {
        $ERROR = "Required params missing: " . join(', ', @missing);
        return undef;
    }

    my $sleep = defined $params{sleep} ? $params{sleep} : 5;
    my $mech = $params{mech};

    my $resp = $mech->get($params{uri});

    unless ( $mech->success() ) {
        $ERROR = "Failed to fetch $params{uri}: " . $resp->message;
        return undef;
    }

    if ( $mech->find_link( text_regex => qr/sign out/i ) ) {
        $ERROR = "Login failed: You are already logged in";
        return undef;
    }
    
    sleep($sleep) if $sleep;

    unless ( $mech->form_name(LOGIN_FORM) ) {
        unless ( $mech->follow_link( text_regex => qr/sign in/i ) 
                    and $mech->form_name(LOGIN_FORM) ) {
            $ERROR = "No login form or sign on link on page";
            return undef;
        }
    }
    
    $resp = $mech->submit_form(
                form_name   =>  LOGIN_FORM,
                fields      =>  {
                        login   =>  $params{user},
                        passwd  =>  $params{pass},
                },
            );

    unless ( $mech->success() ) {
        $ERROR = "Form submission failed: " . $resp->message;
        return undef;
    }
            
    while (my $redirect = $mech->res->header('Location')) {
       my $resp = $mech->get($redirect);
       unless ( $mech->success() ) {
           $ERROR = "Failed to follow redirect: " . $resp->message;
           return undef;
       }
    }

    if ( $mech->content =~ m#window.location.replace\("([^"]*?)"# ) {
        my $resp = $mech->get($1);
        unless ( $mech->success() ) {
           $ERROR = "Failed to follow JavaScript redirect: " . $resp->message;
           return undef;
       }
    }

    if ( $mech->content =~ m/invalid password/i ) {
        $ERROR = "Login failed: Invalid Password";
        return undef;
    } elsif ( $mech->content =~ m/This Yahoo! ID does not exist/i ) {
        $ERROR = "Login failed: Invalid Yahoo ID";
        return undef;
    }
    
    sleep($sleep) if $sleep;
    return 1;
}

sub logout {
    my %params = @_;

    my @missing = grep { ! defined $params{$_} } qw( mech );

    if ( @missing ) {
        $ERROR = "Required params missing: " . join(', ', @missing);
        return undef;
    }

    my $mech = $params{mech};

    my $resp = $mech->get($params{uri});

    unless ( $mech->success() ) {
        $ERROR = "Failed to fetch $params{uri}: " . $resp->message;
        return undef;
    }

    unless ( $mech->follow_link( text_regex => qr/sign out/i ) ) {
        $ERROR = "Failed to log out";
        return undef;
    }

    return 1;
}


1;

__END__

=head1 NAME 

WWW::Yahoo::Login - Login and out of Yahoo Web Sites

=head1 SYNOPSIS

Lots of people have data in Yahoo. Some of them are Perl programmers who
might want to use the scripty goodness of Perl to access that data.
WWW::Yahoo::Login takes the pain out of the first step.

  use WWW::Yahoo::Login qw( login logout );
  use WWW::Mechanize;

  my $mech = WWW::Mechanize->new();

  $resp = login(
      mech    =>  $mech,
      uri     =>  'http://mail.yahoo.com/',
      user    =>  'a_yahoo_user',
      pass    =>  'asecret',
  );

  if ($resp) {
    print $mech->content;
  } else {
    warn $WWW::Yahoo::Login::ERROR;
  }

  # do some things
    
  unless ( logout(mech => $mech) ) {
    warn $WWW::Yahoo::Login::ERROR;
  }

=head1 DESCRIPTION

WWW::Yahoo::Login provides a login and a logout function, neither of
which are exported by default. 


=head2 login

  login(
    mech    =>  $mech,      
    uri     =>  'http://address.yahoo.com/', 
    user    =>  'a_user',  
    pass    =>  'secret', 
    sleep   =>  1,       
  );

login takes 5 parameters:

=over 4

=item mech

A WWW::Mechanize object.

=item uri

The URI of the Yahoo page to login or out of.

=item user

The Yahoo ID to use when signing in.

=item pass

The password for the user.

=item sleep

This is optional and defines how many second to sleep between requests. 
If not supplied then the default of 5 seconds is used. It's generally 
considered the polite thing to do for a bot to sleep for a few seconds 
between requests.

=item back

login returns 1 on success or undef on error. If there is an error
$WWW::Yahoo::Login::ERROR is set. See below for possible error messages.

=head2 logout

  logout( mech => $mech );

logout only accepts a mech paramater. As with login it returns 1 on
success and undef on failure. $WWW::Yahoo::Login::ERROR contains any
error.

=head1 ERRORS

The possible error messages that WWW::Yahoo::Login can generate are:


=head2 Required params missing: [list of missing params]

You didn't supply all the paramaters that either login or logout require

=head2 Failed to fetch [uri]: [error message]

The uri in question could not be fetched.

=head2 Login failed: You are already logged in

As far as login can tell you are already logged in. In practice it means
there was a sign out link on the page.

=head2 No login for or sign on link on page

login couldn't find either the Yahoo login form or a sign on link on the
page.

=head2 Form submission failed: [error message]

There was some sort of problem submitting the login form.

=head2 Failed to follow redirect: [error message]

Somewhere amongst the fleet of redirects that takes place in the Yahoo
login process there was a problem.

=head2 Failed to follow Javascript redirect: [error message]

Another type of redirect problem.

=head2 Login failed: Invalid Yahoo ID

Exactly what it says.

=head2 Login failed: Invalid Password

Exactly what it says.

=head2 Failed to log out

logout couldn't find a sign out link on the page.

=head1 CAVEATS

WWW::Yahoo::Login relies on WWW::Mechanize. It assumes you are going to
use WWW::Mechanize for all your access to Yahoo. 

I've only tested it on perl 5.6.1 on Debian i386.

=head1 SUPPORT

author email.

=head1 AUTHOR

	Struan Donald
	modules@exo.org.uk
	http://www.exo.org.uk/code/

=head1 COPYRIGHT

Copyright (C) 2003 Struan Donald. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), WWW::Mechanize.

=cut
