# $Id: 01_login.t,v 1.4 2003/07/31 06:49:33 struan Exp $

use Test::More tests => 21;
use WWW::Mechanize;

my $skip_yahoo = 0;

use_ok(WWW::Yahoo::Login, qw(login logout));

my $m = WWW::Mechanize->new();

SKIP: {
    skip "no connection", 20 if -f "t/SKIPLIVE";

    my $uri = 'http://address.yahoo.com/';
    my $user = $ENV{WYL_USER} || '';
    my $pass = $ENV{WYL_PASS} || '';

    $skip_yahoo = 1 unless $user and $pass;

    my %args = (
        mech    =>  $m,
        uri     =>  $uri,
        user    =>  $user,
        pass    =>  $pass,
    );

    SKIP: {
        skip 'No Yahoo User or Password', 10 if $skip_yahoo;

        ok(login(%args), 'fetched data');

        ok($m->find_link( text_regex => qr/sign out/i), 'logged in');

        ok(!login(%args), 'failed relogin');
        is($WWW::Yahoo::Login::ERROR, 'Login failed: You are already logged in', 'already logged in error');

        ok(logout(mech => $m), 'logout');

        $args{uri} = "http://www.yahoo.com/";

        ok(login(%args), 'login with no form on page');

        logout(mech => $m);

        $args{uri} = $uri;
        $args{pass} = 'bad';

        ok(!login(%args), 'login failed with bad password');
        is($WWW::Yahoo::Login::ERROR, 'Login failed: Invalid Password', 'bad password error');

        $args{pass} = $pass;
        $args{user} = rand 10;

        ok(!login(%args), 'login failed with bad user');
        is($WWW::Yahoo::Login::ERROR, 'Login failed: Invalid Yahoo ID', 'bad user error');
    }

    $args{sleep} = 0;
    $args{user} = $user;
    $args{uri} = 'http://exo.org.uk/';

    ok(!login(%args), 'login failed on page with no form');
    is($WWW::Yahoo::Login::ERROR, 'No login form or sign on link on page', 'no login form error');

    ok(!logout(%args), 'logout failed on page with no sign out');
    is($WWW::Yahoo::Login::ERROR, 'Failed to log out', 'no logout link error');

    $args{uri} = 't/missing.html'; # http://exo.org.uk/this_does_not_exist';

    ok(!login(%args), 'fetching bad uri failed');
    like($WWW::Yahoo::Login::ERROR, qr/Failed to fetch/, 'failed to fetch error');

    $args{uri} = 'http://exo.org.uk/code/www-yahoo-login/bad_form_target.html';

    ok(!login(%args), 'form submit failed');
    like($WWW::Yahoo::Login::ERROR, qr/Form submission failed:/, 'form submit failed error');

    delete $args{uri};

    ok(!login(%args), "failed if no uri");
    is($WWW::Yahoo::Login::ERROR, 'Required params missing: uri', 'missing uri param error');
}

# we er, borrowed this from the Class::DBI::Pg tests in case anyone thinks
# it looks familiar.
sub read_input {
    my $prompt = shift;
    print STDERR "$prompt: ";
    my $value = <STDIN>;
    chomp $value;
    return $value;
}

