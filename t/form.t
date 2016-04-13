use strict;
use warnings;

use Plack::Test;
use Dancer2::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

use Test::More tests => 14;
use Data::Dumper;

use lib './t/lib/TestApp';
use TestApp;

my $test_app = "TestApp";
use_ok $test_app;
my $app = $test_app->to_app;
is( ref $app, 'CODE', 'Got app' );

my $dsl = $test_app->dsl;
$dsl->set(
    log => 'debug',
    logger => 'console',
    session => 'Simple'    
);

my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create($app);

my $test_form = {
    fields  => ['first-name', 'last-name']
};

my $res = $test->request(POST 'http://localhost:3000/init_one_form',
    [ form => $dsl->to_json({ %{$test_form} }) ]);
$jar->extract_cookies($res);
my $form = $dsl->from_json($res->content);
ok( $form->{name} eq 'test-form', 'Init form->name.');
ok( scalar @{$test_form->{fields}} == scalar @{$form->{fields}}, 'Same amount of form fields initialized.');

for (
    my $i = 0;
    $i <= (scalar @{$test_form->{fields}} - 1);
    $i++
) {
    ok( $test_form->{fields}[$i] eq $form->{fields}[$i], qq{$test_form->{fields}[$i] field added to form.} );
}

my $params = { 'first-name' => 'John', 'last-name' => 'doe', 'foo' => 'bar' };
my $req = POST 'http://localhost:3000/one_form', $params;
$jar->add_cookie_header($req);
$res = $test->request($req);
my $stored_form = $dsl->from_json($res->content);

foreach ( @{$stored_form->{fields}} ) {
    ok($stored_form->{values}->{$_} eq $params->{$_}, qq{Form object stored relevant value for $_.});
}
my %relevant_params = map { $_ => 1 } @{$stored_form->{fields}};
foreach ( keys $params ) {
    next if exists($relevant_params{$_});
    ok(!exists($relevant_params{$_}), qq{Irrelevant param $_ not stored in form object.});
}

$req = GET 'http://localhost:3000/one_form';
$jar->add_cookie_header($req);
$res = $test->request($req);
$stored_form = $dsl->from_json($res->content);
foreach (keys %relevant_params) {
    ok($stored_form->{values}->{$_} eq $params->{$_}, qq{Value for $_ stored in session correctly.});
}

$req = GET 'http://localhost:3000/reset_test';
$jar->add_cookie_header($req);
$res = $test->request($req);
$stored_form = $dsl->from_json($res->content);
ok($stored_form->{name} && @{$stored_form->{fields}} == 0, qq{Form reset successfully.});

$req = GET 'http://localhost:3000/fill_test';
$jar->add_cookie_header($req);
$res = $test->request($req);
$stored_form = $dsl->from_json($res->content);
ok($stored_form->{values}->{'first-name'} eq 'John', qq{Form filled successfully.});

$req = GET 'http://localhost:3000/fail_test';
$jar->add_cookie_header($req);
$res = $test->request($req);
$stored_form = $dsl->from_json($res->content);
ok($stored_form->{errors}->{'last-name'}, qq{Failure method successfully set errors.});
