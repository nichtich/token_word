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
    generateHeader( "login" );

    my $formText = readFileValue( "$htmlDirectory/loginForm.html" );
    
    print $formText;


    generateFooter();
}



sub generateDocPage {
    ( my $docText ) = @_;
    
    my @docElements = split( /\n\n/, $docText );

    my $docTitle = shift( @docElements );

    generateHeader( "document: $docTitle" );
    
    print "<H1>$docTitle</H1>\n";

    foreach $paragraph ( @docElements ) {
        print "$paragraph\n<p>\n";
    }
    
    generateFooter();
}


# end of package
1;
