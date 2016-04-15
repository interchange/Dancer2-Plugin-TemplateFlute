use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;
use Dancer2::Core::Session;
use aliased 'Dancer2::Plugin::TemplateFlute::Form';
use DDP;

my ( $form, $session, $log, @logs );

# test fixtures

{

    package TestObjNoMethods;
    use Moo;
}
{

    package TestObjReadOnly;
    use Moo;
    sub read { }
}
{

    package TestObjWriteOnly;
    use Moo;
    sub write { }
}
{

    package TestObjReadAndWrite;
    use Moo;
    sub read  { }
    sub write { }
}

my $log_cb = sub {
    my $level = shift;
    my $message = join( '', @_ );
    push @logs, { $level => $message };
};

is exception { $session = Dancer2::Core::Session->new( id => 1 ) }, undef,
  "create a session object";

subtest 'form attribute types and coercion' => sub {
    my $session;

    like exception { Form->new }, qr/Missing required arguments: session at/,
      "Form->new with no args dies";

    like exception { Form->new( session => 'string' ) },
      qr/string.+did not pass type constraint.+HasMethods/,
      "Form->new with string as session value dies";

    like exception { Form->new( session => TestObjNoMethods->new ) },
      qr/bless.+TestObjNoMethods.+did not pass type constraint.+HasMethods/,
      "Form->new with session TestObjNoMethods dies";

    like exception { Form->new( session => TestObjReadOnly->new ) },
      qr/bless.+TestObjReadOnly.+did not pass type constraint.+HasMethods/,
      "Form->new with session TestObjReadOnly dies";

    like exception { Form->new( session => TestObjWriteOnly->new ) },
      qr/bless.+TestObjWriteOnly.+did not pass type constraint.+HasMethods/,
      "Form->new with session TestObjWriteOnly dies";

    is exception { Form->new( session => TestObjReadAndWrite->new ) },
      undef,
      "Form->new with session TestObjReadAndWrite lives";

    is exception { $session = Dancer2::Core::Session->new( id => 1 ) }, undef,
      "create a session object";

    is exception { $form = Form->new( session => $session ) },
      undef,
      "Form->new with valid session lives";

    like exception { Form->new( session => $session, action => undef ) },
      qr/Undef did not pass type constraint "Defined"/,
      "Form->new with undef action dies";

    like exception { Form->new( session => $session, action => $session ) },
      qr/bless.+did not pass type constraint "Str"/,
      "Form->new with bad action dies";

    like exception { Form->new( session => $session, errors => 'qq' ) },
      qr/Unable to coerce errors/,
      "Form->new with scalar errors dies";

    like exception { Form->new( session => $session, errors => 'qq' ) },
      qr/Unable to coerce errors/,
      "Form->new with scalar errors dies";

};

#done_testing;
#__END__

subtest 'empty form creation with add_error, set_error and reset' => sub {

    @logs = ();

    is
      exception { $form = Form->new( log_cb => $log_cb, session => $session ) },
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
    cmp_deeply $form->errors_hashed, [ { name => "foo", label => "bar" } ],
      "errors_hashed looks good";

    ok $form->pristine, "form is pristine";
    cmp_ok $form->valid, '==', 0, "valid is 0";

    cmp_ok @logs, '==', 1, '1 log entry' or diag explain @logs;
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

    # set_error

    is exception { $form->set_valid(1) }, undef, "set valid to 1";

    cmp_ok @logs, '==', 1, '1 log entry' or diag explain @logs;
    $log = pop @logs;
    cmp_ok $log->{debug}, 'eq', 'Setting valid for form main to 1.',
      'got "valid is 1" debug log entry';

    cmp_deeply $session->read('form'),
      {
        main => {
            errors => { foo => "bar" },
            fields => [],
            name   => "main",
            valid  => 1,
            values => {}
        },
      },
      "form in session looks good";

    is exception { $form->set_error( "buzz", "one", "two", "three" ) }, undef,
      'set_error "buzz", "one", "two", "three"';

    cmp_deeply $form->errors->mixed,
      { buzz => [ "one", "two", "three" ], foo => "bar" }, "errors looks good";

    cmp_deeply $form->errors_hashed,
      bag(
        { name => "foo",  label => "bar" },
        { name => "buzz", label => "one" },
        { name => "buzz", label => "two" },
        { name => "buzz", label => "three" },
      ),
      "errors_hashed looks good";

    ok $form->pristine, "form is pristine";
    cmp_ok $form->valid, '==', 0, "valid is 0";

    cmp_ok @logs, '==', 1, '1 log entry' or diag explain @logs;
    $log = pop @logs;
    cmp_ok $log->{debug}, 'eq', 'Setting valid for form main to 0.',
      'got "valid is 0" debug log entry';

    cmp_deeply $session->read('form'),
      {
        main => {
            errors => { buzz => bag( "one", "two", "three" ), foo => "bar" },
            fields => [],
            name   => "main",
            valid  => 0,
            values => {}
        },
      },
      "form in session looks good";

    # reset

    is exception { $form->reset }, undef, "form reset lives";

    cmp_ok ref( $form->errors ), 'eq', 'Hash::MultiValue',
      'errors is a Hash::MultiValue';
    cmp_ok scalar $form->errors->keys, '==', 0, 'errors is empty';
    cmp_ok ref( $form->fields ), 'eq', 'ARRAY', 'fields is an array reference';
    cmp_ok @{ $form->fields }, '==', 0, 'fields is empty';
    cmp_ok $form->name, 'eq', 'main', 'form name is "main"';
    ok $form->pristine, "form is pristine";
    ok !defined $form->valid, "valid is undef";
    cmp_ok ref( $form->values ), 'eq', 'Hash::MultiValue',
      'values is a Hash::MultiValue';
    cmp_ok scalar $form->values->keys, '==', 0, 'values is empty';

    cmp_deeply $session->read('form'),
      {
        main => {
            errors => {},
            fields => [],
            name   => "main",
            valid  => undef,
            values => {}
        },
      },
      "form in session looks good";
};

done_testing;
