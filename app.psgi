use Plack::App::WrapCGI;
Plack::App::WrapCGI->new(script => "tokenWord.pl")->to_app;
