package TestApp;

use Dancer2;
use Dancer2::Plugin::Form;

post '/init_one_form' => sub {
    my $form_args = from_json(request->params->{form});

    my $form = form('test-form');
    $form->fields( $form_args->{fields} );
    $form->to_session;

    return to_json({ %{$form} });
};

post '/one_form' => sub {
    my $form = form('test-form');
    my $values = $form->values();
    $form->to_session;
    return to_json({ %{$form} });
};

get '/one_form' => sub {    
    my $form = form('test-form');
    $form->values('session');
    return to_json({ %{$form} });
};

get '/reset_test' => sub {
    my $form = form('test-form');
    $form->reset;
    return to_json({ %{$form} });        
};

get '/fill_test' => sub {
    my $form = form('test-form');
    $form->fields(['first-name', 'last-name']);
    $form->fill({
        'first-name' => 'John',
        'last-name' => 'doe'
    });
    $form->to_session;
    return to_json({ %{$form} });
};
get '/fail_test' => sub {
    my $form = form('test-form');
    $form->values('session');
    $form->failure( errors => {
        'last-name' => 'Last name must be capitalized.'
    });
    return to_json({ %{$form} });
};
1;