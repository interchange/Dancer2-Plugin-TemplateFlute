package Dancer2::Plugin::TemplateFlute;

use warnings;
use strict;

use Dancer2::Plugin;

=head1 NAME

Dancer2::Plugin::TemplateFlute - Dancer2 form handler for Template::Flute template engine

=head1 VERSION

Version 0.0002

=cut

our $VERSION = '0.0002';

=head1 SYNOPSIS

Display template with checkout form:
    
    get '/checkout' => sub {
        my $form;

        $form = form('checkout');
	
        template 'checkout', {form => $form};
    };

Retrieve form input from checkout form:

    post '/checkout' => sub {
        my ($form, $values);

        $form = form('checkout');
        $values = $form->values();
    };

Reset form after completion to prevent old data from
showing up on new form:

    $form = form('checkout');
    $form->reset;

=cut

register form => sub {
    my $plugin = shift;

    my $name = '';

    if ( @_ % 2 ) {
        $name = shift;
    }
    else {
        $name = 'main';
    }

    my $form = Dancer2::Plugin::TemplateFlute::Form->new(
        plugin => $plugin,
        name   => $name,
        @_
    );

    return $form;
};

register_plugin;

=head1 DESCRIPTION
    
C<Dancer2::Plugin::TemplateFlute> is used for forms with the
L<Dancer2::Template::TemplateFlute> templating engine.    

Form fields, values and errors are stored into and loaded from the session key
C<form>.

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
