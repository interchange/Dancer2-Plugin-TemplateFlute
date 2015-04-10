package TestApp;

use Dancer2;
use Dancer2::Plugin::Form;

post '/init_one_form' => sub {
    my $form_args = from_json(request->params->{form});

    my $form = form('test-form');
    $form->fields( $form_args->{fields} );
    $form->to_session;
    
    my $response;
    foreach( keys %{$form}) {
        next if $_ eq 'dsl';
        $response->{$_} = $form->$_;
    }     
    return to_json({ %{$response} });
};

post '/one_form' => sub {
    my $form = form('test-form');
    my $values = $form->values();
    $form->to_session;
    
    my $response;
    foreach( keys %{$form}) {
        next if $_ eq 'dsl';
        $response->{$_} = $form->{$_};
    }
    return to_json({ %{$response} });
};

get '/one_form' => sub {    
    my $form = form('test-form');
    $form->values('session');
    my $response;
    foreach( keys %{$form}) {
        next if $_ eq 'dsl';
        $response->{$_} = $form->{$_};
    }
    return to_json({ %{$response} });
};

get '/reset_test' => sub {
    my $form = form('test-form');
    $form->reset;

    my $response;
    foreach( keys %{$form}) {
        next if $_ eq 'dsl';
        $response->{$_} = $form->{$_};
    }
    return to_json({ %{$response} });        
};

get '/fill_test' => sub {
    my $form = form('test-form');
    $form->fields(['first-name', 'last-name']);
    $form->fill({
        'first-name' => 'John',
        'last-name' => 'doe'
    });
    $form->to_session;
    
    my $response;
    foreach( keys %{$form}) {
        next if $_ eq 'dsl';
        $response->{$_} = $form->{$_};
    }
    return to_json({ %{$response} });
};
get '/fail_test' => sub {
    my $form = form('test-form');
    $form->values('session');
    $form->failure( errors => {
        'last-name' => 'Last name must be capitalized.'
    });
    
    my $response;
    foreach( keys %{$form}) {
        next if $_ eq 'dsl';
        $response->{$_} = $form->{$_};
    }
    return to_json({ %{$response} });
};
1;