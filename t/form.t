use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Dancer2::Core::Session;
use aliased 'Dancer2::Plugin::TemplateFlute::Form';
use DDP;

my ( $form, $session, $log, @logs );

# logger and session

my $log_cb = sub {
    my $level = shift;
    my $message = join( '', @_ );
    push @logs, { $level => $message };
};

is exception { $session = Dancer2::Core::Session->new( id => 1 ) }, undef,
  "create a session object";

# new with no args

like exception { Form->new }, qr/Missing required arguments: session at/,
  "Form->new with no args dies";

# new form with good log_cb and empty session

is exception { $form = Form->new( log_cb => $log_cb, session => $session ) },
  undef,
  "Form->new with valid session lives";

ok !defined $session->read('form'), "No form data in the session";
ok !@logs, "Nothing logged";

ok !defined $form->action, "action is undef";
cmp_ok ref( $form->errors ), 'eq', 'Hash::MultiValue',
  'errors is a Hash::MultiValue';
cmp_ok scalar $form->errors->keys, '==', 0, 'errors is empty';
cmp_ok ref( $form->fields ), 'eq', 'ARRAY', 'fields is an array reference';
cmp_ok @{ $form->fields }, '==', 0, 'fields is empty';
cmp_ok ref( $form->log_cb ), 'eq', 'CODE', 'log_cb is a code reference';
cmp_ok $form->name, 'eq', 'main', 'form name is "main"';
ok $form->pristine, "form is pristine";
ok $session->can('read'),  'session->can read';
ok $session->can('write'), 'session->can write';
ok !defined $form->valid, "valid is undef";
cmp_ok ref( $form->values ), 'eq', 'Hash::MultiValue',
  'values is a Hash::MultiValue';
cmp_ok scalar $form->values->keys, '==', 0, 'values is empty';

# add_error

is exception { $form->add_error( foo => "bar" ) }, undef,
  'add_error foo => "bar" ';

cmp_deeply $form->errors->mixed, { foo => "bar" }, "errors looks good";
ok $form->pristine, "form is pristine";
cmp_ok $form->valid, '==', 0, "valid is 0";

cmp_ok @logs, '==', 1, '1 log entry';
$log = pop @logs;
cmp_ok $log->{debug}, 'eq', 'Setting valid for form main to 0.',
  'got "valid is 0" debug log entry';

cmp_deeply $session->read('form'),
  {
    main => {
        errors => { foo => "bar" },
        fields => [],
        name   => "main",
        valid  => 0,
        values => {}
    },
  },
  "form in session looks good";

done_testing;
