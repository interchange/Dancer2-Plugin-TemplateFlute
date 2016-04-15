package Dancer2::Plugin::TemplateFlute::Form;

use Hash::MultiValue;
use Types::Standard -types;
use Moo;
use namespace::clean;

=head1 NAME

Dancer2::Plugin::TemplateFlute::Form - form object for Template::Flute

=cut

#
# attributes
#

has action => (
    is        => 'rw',
    isa       => Str,
    predicate => 1,
);

has errors => (
    is      => 'rw',
    isa     => InstanceOf ['Hash::MultiValue'],
    default => sub { Hash::MultiValue->new },
    coerce  => sub {
        if ( ref( $_[0] ) eq 'Hash::MultiValue' ) {
            $_[0];
        }
        elsif ( ref( $_[0] ) eq 'HASH' ) {
            Hash::MultiValue->from_mixed( $_[0] );
        }
        else {
            Hash::MultiValue->new(@_);
        }
    },
    trigger => sub {
        $_[0]->valid(0);
    },
    clearer => 1,
);

has fields => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
    clearer => 1,
);

has log_cb => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub {
        sub { 1 }
    },
);

has name => (
    is      => 'ro',
    isa     => Str,
    default => 'main',
);

has pristine => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has session => (
    is       => 'ro',
    isa      => HasMethods [ 'read', 'write' ],
    required => 1,
);

has valid => (
    is      => 'rw',
    isa     => Bool,
    trigger => sub {
        my ( $self, $value ) = @_;

        $self->log( "debug", "Setting valid for form ",
            $self->name, " to $value." );

        $self->to_session;
    },
    clearer => 1,
);

has values => (
    is      => 'ro',
    isa     => InstanceOf ['Hash::MultiValue'],
    default => sub { Hash::MultiValue->new },
    coerce  => sub {
        if ( ref( $_[0] ) eq 'Hash::MultiValue' ) {
            $_[0];
        }
        elsif ( ref( $_[0] ) eq 'HASH' ) {
            Hash::MultiValue->from_mixed( $_[0] );
        }
        else {
            Hash::MultiValue->new(@_);
        }
    },
    trigger => sub { $_[0]->pristine(0) },
    clearer => 1,
);

#
# methods
#

sub add_error {
    my $self = shift;
    $self->errors->add(@_);
    $self->valid(0);
}

sub errors_hashed {
    my ($self) = @_;
    my (@hashed);

    for my $err ( @{ $self->errors } ) {
        push( @hashed, { name => $err->[0], label => $err->[1] } );
    }

    return \@hashed;
}

sub from_session {
    my ($self) = @_;

    if ( my $forms_ref = $self->session->read('form') ) {
        if ( exists $forms_ref->{ $self->name } ) {
            my $form = $forms_ref->{ $self->name };

            $self->fields( $form->fields ) if $form->fields;
            $self->errors( $form->errors ) if $form->errors;
            $self->values( $form->values ) if $form->values;
            $self->valid( $form->valid )   if defined $form->valid;

            return 1;
        }
    }
    return 0;
}

sub log {
    my $self = shift;
    $self->log_cb->(@_);
}

sub reset {
    my $self = shift;
    $self->clear_fields;
    $self->clear_errors;
    $self->clear_values;
    $self->clear_valid;
    $self->pristine(1);
    $self->to_session;
}

sub set_error {
    my $self = shift;
    $self->errors->set(@_);
    $self->valid(0);
}

sub to_session {
    my $self = shift;
    my ($forms_ref);

    # get current form information from session
    $forms_ref = $self->session->read('form');

    # update our form
    $forms_ref->{ $self->name } = {
        name   => $self->name,
        fields => $self->fields,
        errors => $self->errors->mixed,
        values => $self->values->mixed,
        valid  => $self->valid,
    };

    # update form information
    $self->session->write( form => $forms_ref );
}

=head1 ATTRIBUTES

=head2 name

The name of the form.

Defaults to 'main',

=head2 action

Set form action:
    
   $form->action('/checkout');

Get form action:

   $action = $form->action;

=over

=item predicate: has_action

=back

=head2 errors
    
Errors stored in a L<Hash::MultiValue> object.

Set form errors (this will overwrite all existing errors):
    
    $form->errors(
        username => 'Minimum 8 characters',
        username => 'Must contain at least one number',
        email    => 'Invalid email address',
    );

Get form errors:

   $errors = $form->errors;

=over

=item clearer: clear_errors

=back

B<NOTE:> Avoid using C<< $form->errors->add() >> or C<< $form->errors->set() >>
since doing that means that L</valid> does not automatically get set to C<0>.
Instead use one of L</add_error> or L</set_error> methods.

=head2 fields

Set form fields:
    
    $form->fields([qw/username email password verify/]);

Get form fields:

    $fields = $form->fields;

=over

=item clearer: clear_fields

=back

=head2 log_cb

A code reference that can be used to log things. Signature must be like:

  $log_cb->( $form_obj, $level, @message );

Logging is via L</log> method.

=head2 pristine

Determines whether a form is pristine or not.

This can be used to fill the form with default values and suppress display
of errors.

A form is pristine until it receives form field input from the request or
out of the session.

=head2 session

A session object. Must have methods C<read> and C<write>.

Required.

=head2 valid

Determine whether form values are valid:

    $form->valid();

Return values are 1 (valid), 0 (invalid) or
undef (unknown).

Set form status to "valid":
    
    $form->valid(1);

Set form status to "invalid":
    
    $form->valid(0);

The form status automatically changes to "invalid" when L</errors> is set
or either L</add_errors> or L</set_errors> are called.
    
=over

=item clearer: clear_valid

=back

=head2 values

Get form values as hash reference:

    $values = $form->values;

=over

=item writer: fill

Fill form values:

    $form->fill({username => 'racke', email => 'racke@linuxia.de'});

=item clearer: clear_values

=back

=head1 METHODS

=head2 add_error

Add an error:

    $form->add_error( $key, $value [, $value ... ]);

=head2 errors_hashed

Returns form errors as array reference filled with hash references
for each error.

For example these L</errors>:

    { username => 'Minimum 8 characters',
      email => 'Invalid email address' }

will be returned as:

    [
        { name => 'username', value => 'Minimum 8 characters'  },
        { name => 'email',    value => 'Invalid email address' },
    ]

=head2 from_session

Loads form data from session key C<form>.
Returns 1 if session contains data for this form, 0 otherwise.

=head2 log $level, @message

Log message via L</log_cb>.

=head2 reset

Reset form information (fields, errors, values, valid) and
updates session accordingly.

=head2 set_error

Set a specific error:

    $form->set_error( $key, $value [, $value ... ]);

=head2 to_session

Saves form name, form fields, form values and form errors into 
session key C<form>.


=head1 AUTHORS

Original Dancer plugin by:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

Initial port to Dancer2 by:

Evan Brown (evanernest), C<< <evan at bottlenose-wine.com> >>

Rehacking to Dancer2's plugin2 and general rework:

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

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
