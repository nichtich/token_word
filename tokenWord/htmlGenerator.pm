package tokenWord::htmlGenerator;

#
# Modification History
#
# 2003-January-8   Jason Rohrer
# Created.
#


use tokenWord::common;



sub generateHeader {
    ( my $title ) = @_;

    my $headerText = readFileValue( "$htmlDirectory/header.html" );

    $headerText =~ s/<!--#TITLE-->/$title/;
    
    print $headerText;
}



sub generateFooter {

    my $footerText = readFileValue( "$htmlDirectory/footer.html" );
    
    print $footerText;
}



sub generateLoginForm {
    ( my $message ) = @_;
 
    generateHeader( "login" );

    my $formText = readFileValue( "$htmlDirectory/loginForm.html" );

    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFooter();
}



sub generateCreateUserForm {
    ( my $message ) = @_;
 
    generateHeader( "create new user" );

    my $formText = readFileValue( "$htmlDirectory/createUserForm.html" );

    $formText =~ s/<!--#MESSAGE-->/$message/;
    
    print $formText;


    generateFooter();
}



sub generateMainPage {
    ( my $user ) = @_;
 
    generateHeader( "main page" );

    my $pageText = readFileValue( "$htmlDirectory/mainPage.html" );

    $pageText =~ s/<!--#USER-->/$user/;
    
    print $pageText;


    generateFooter();
}



sub generateCreateDocumentForm {
    
    generateHeader( "create document" );

    my $formText = readFileValue( "$htmlDirectory/createDocumentForm.html" );
    
    print $formText;


    generateFooter();
}


sub generateDocPage {
    ( my $docText ) = @_;
    
    my @docElements = split( /\n\n/, $docText );

    my $docTitle = shift( @docElements );

    generateHeader( "document: $docTitle" );
    
    print "<CENTER><TABLE WIDTH=75% BORDER=0><TR><TD>\n";

    print "<H1>$docTitle</H1>\n";

    foreach $paragraph ( @docElements ) {
        print "<p>$paragraph</p>\n";
    }
    
    print "</TD></TR></TABLE></CENTER>\n";

    generateFooter();
}


# end of package
1;
