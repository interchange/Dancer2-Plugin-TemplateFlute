package Dancer2::Plugin::TemplateFlute::Form;

use Dancer2::Core::Types -types;
use Moo;
use namespace::clean;

my %forms;

=head1 NAME

Dancer2::Plugin::TemplateFlute::Form - form object for Template::Flute

=head1 ATTRIBUTES

=head2 name

The name of the form.

Defaults to 'main',

=cut

has name => (
    is      => 'ro',
    isa     => Str,
    default => 'main',
);

has plugin => (
    is       => 'ro',
    isa      => InstanceOf ['Dancer2::Plugin'],
    required => 1,
);

has appname => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->plugin->app->name },
);

=head2 action

Set form action:
    
   $form->action('/checkout');

Get form action:

   $action = $form->action;

=cut

has action => (
    is  => 'rw',
    isa => Str,
);

=head2 fields

Set form fields:
    
    $form->fields([qw/username email password verify/]);

Get form fields:

    $fields = $form->fields;

=cut

has fields => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has errors => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=head2 valid

Determine whether form values are valid:

    $form->valid();

Return values are 1 (valid), 0 (invalid) or
undef (unknown).

Set form status to "valid":
    
    $form->valid(1);

Set form status to "invalid":
    
    $form->valid(0);

The form status automatically changes to
"invalid" when errors method is called with
error messages.
    
=over

=item clearer: clear_valid

=back

=cut

has valid => (
    is      => 'ro',
    isa     => Bool,
    trigger => sub {
        my ( $self, $value ) = @_;
        $self->plugin->app->log( "debug", "Setting valid for form ",
            $self->name, "to $value." );
        $self->to_session;
    },
    clearer => 1,
);

=head2 pristine

Determines whether a form is pristine or not.

This can be used to fill the form with default values and suppress display
of errors.

A form is pristine until it receives form field input from the request or
out of the session.

=over

=item writer: set_pristine

=back

=cut

has pristine => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
    writer  => 'set_pristine',
);

=head2 values

Hash reference of C<< $field => $value >> pairs.

=over

=item writer: fill

Fill form values:

    $form->fill({username => 'racke', email => 'racke@linuxia.de'});

Also accepts hash:

    $form->fill(username => 'racke', email => 'racke@linuxia.de');

=item clearer: clear_values

=back

=cut

has values => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
    writer  => 'fill',
    coerce  => sub { ref( $_[0] ) eq 'HASH' ? $_[0] : +{@_} },
    trigger => sub { $_[0]->set_pristine(0) },
    clearer => 1,
);

sub BUILDARGS {

    # try to load form data from session
    $self->from_session();

    return $self;
}

=head2 values

Get form values as hash reference:

    $values = $form->values;

Set form values from a hash reference:

    $values => $form->values(ref => \%input);

=cut

sub values {
    my ( $self, $scope, $data ) = @_;
    my ( %values, $params, $save );
    my $dsl = $self->_get_dsl;

    %values = %{ $self->{values} } if $self->{values};

    if ( !defined $scope ) {
        $params = $dsl->app->request->params('body');
        $save   = 1;
    }
    elsif ( $scope eq 'session' ) {
        $params = $self->{values};
    }
    elsif ( $scope eq 'body' || $scope eq 'query' ) {
        $params = $dsl->app->request->params($scope);
        $save   = 1;
    }
    elsif ( $scope eq 'ref' ) {
        $params = $data;
        $save   = 1;
    }
    else {
        $params = '';
    }

    for my $f ( @{ $self->{fields} } ) {

        $values{$f} = $params->{$f} ? $params->{$f} : $self->{values}->{$f};

        if ( $save && defined $values{$f} ) {

            # tidy form input first
            $values{$f} =~ s/^\s+//;
            $values{$f} =~ s/\s+$//;
        }
    }

    if ($save) {
        $self->{values} = \%values;
        return \%values;
    }

    return \%values;
}

=head2 errors
    
Set form errors:
    
   $form->errors({username => 'Minimum 8 characters',
                  email => 'Invalid email address'});

Get form errors as hash reference:

   $errors = $form->errors;

=cut

sub errors {
    my ( $self, $errors ) = @_;
    my ( $key, $value, @buf );

    if ($errors) {
        if ( ref($errors) eq 'HASH' ) {
            while ( ( $key, $value ) = each %$errors ) {
                push @buf, { name => $key, label => $value };
            }
            $self->{errors} = \@buf;
        }
        $self->{valid} = 0;
    }

    return $self->{errors};
}

=head2 errors_hashed

Returns form errors as array reference filled with a hash reference
for each error.

=cut

sub errors_hashed {
    my ($self) = @_;
    my (@hashed);

    for my $err ( @{ $self->{errors} } ) {
        push( @hashed, { name => $err->[0], label => $err->[1] } );
    }

    return \@hashed;
}

=head2 failure

Indicates form failure by passing form errors.

    $form->failure(errors => {username => 'Minimum 8 characters',
                              email => 'Invalid email address'});

You can also set a route for redirection:

    return $form->failure(errors => {username => 'Minimum 8 characters'},
        route => '/account');

Passing parameters for the redirection URL is also possible:

    return $form->failure(errors => {username => 'Minimum 8 characters'},
        route => '/account',
        params => {layout => 'mobile'});

Please ensure that you validate input submitted by an user before
adding them to the C<params> hash.

=cut

sub failure {
    my ( $self, %args ) = @_;
    my $dsl = $self->_get_dsl;

    $self->{errors} = $args{errors};

    # update session data about this form
    $self->to_session();

    $dsl->app->session->write(
        form_errors => '<ul>'
          . join( '',
            map { "<li>$_</li>" } CORE::values %{ $args{errors} || {} } )
          . '</ul>'
    );

    $dsl->app->session->write( form_data => $args{data} );

    if ( $args{route} ) {
        $dsl->redirect( $dsl->uri_for( $args{route}, $args{params} ) );
    }

    return;
}

=head1 METHODS

=head2 reset

Reset form information (fields, errors, values, valid) and
updates session accordingly.

=cut

sub reset {
    my $self = shift;

    $self->{fields} = [];
    $self->{errors} = [];
    $self->clear_values;
    $self->clear_valid;
    $self->set_pristine(1);
    $self->to_session;

    return 1;
}

=head2 from_session

Loads form data from session key 'form'.
Returns 1 if session contains data for this form, 0 otherwise.

=cut

sub from_session {
    my ($self) = @_;
    my ( $forms_ref, $form );
    my $dsl = $self->_get_dsl;

    if ( $forms_ref = $dsl->app->session->read('form') ) {
        if ( exists $forms_ref->{ $self->{name} } ) {
            $form = $forms_ref->{ $self->{name} };
            $self->{fields} = $form->{fields} || [];
            $self->{errors} = $form->{errors} || [];
            $self->{values} = $form->{values} || {};
            $self->{valid}  = $form->{valid};

            while ( my ( $key, $value ) = each %{ $self->{values} } ) {
                if ( defined $value ) {
                    $self->{pristine} = 0;
                    last;
                }
            }

            return 1;
        }
    }

    return 0;
}

=head2 to_session

Saves form name, form fields, form values and form errors into 
session key 'form'.

=cut

sub to_session {
    my ($self) = @_;
    my ($forms_ref);
    my $dsl = $self->_get_dsl;

    # get current form information from session
    $forms_ref = $dsl->app->session->read('form');

    # update our form
    $forms_ref->{ $self->{name} } = {
        name   => $self->{name},
        fields => $self->{fields},
        errors => $self->{errors},
        values => $self->{values},
        valid  => $self->{valid},
    };

    # update form information
    $dsl->app->session->write( form => $forms_ref );
}

=head1 AUTHORS

Original Dancer plugin by:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

Initial port to Dancer2 by:

Evan Brown (evanernest), C<< evan at bottlenose-wine.com >>

Rehacking to Dancer2's plugin2 and general rework:

Peter Mottram (SysPete), C<< peter at sysnix.com >>

=head1 BUGS

Please report any bugs or feature requests via GitHub issues:
L<https://github.com/interchange/Dancer2-Plugin-TemplateFlute/issues>.

We will be notified, and then you'll automatically be notified of progress
on your bug as we make changes.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
