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
    ( my $docOwner, my $docID, my $docText ) = @_;
    
    my @docElements = split( /\n\n/, $docText );

    my $docTitle = shift( @docElements );

    generateHeader( "document: $docTitle" );
    
    print "<CENTER><TABLE WIDTH=75% BORDER=0><TR><TD>\n";

    print "<H1>$docTitle</H1>\n";

    foreach $paragraph ( @docElements ) {
        print "$paragraph<BR><BR>\n";
    }
    
    print "<BR><BR>\n";

    print "<A HREF=\"tokenWord.pl?action=extractQuoteForm";
    print "&docOwner=$docOwner&docID=$docID\">";
    print "extract a quote</A>\n";

    print "</TD></TR></TABLE>\n";

    print "</CENTER>\n";

    generateFooter();
}



sub generateQuoteListPage {
    my @quotes = @_;

    generateHeader( "quote list" );
    
    print "<CENTER><TABLE WIDTH=75% BORDER=0><TR><TD>\n";

    if( scalar( @quotes ) > 0 ) {
        print "<H1>Quotes:</H1>\n";
    
        print "<TABLE CELLSPACING=5 BORDER=1>\n";
        
        print "<TR><TD>quote number</TD><TD>quote</TD></TR>\n";

        my $quoteCounter = 0;
        foreach $quote ( @quotes ) {
            print "<TR><TD>&#60;q $quoteCounter&#62;</TD>";
            print "<TD>\n";

            my @quoteElements = split( /\n\n/, $quote );
            
            foreach $paragraph ( @quoteElements ) {
                print "$paragraph<BR><BR>\n";
            }
            
            

            print "</TD></TR>\n";
            
            $quoteCounter += 1;
        }
    
        print "</TABLE>\n";
        
    }
    else {
        print "no quotes present\n";
    }
    print "</TD></TR></TABLE></CENTER>\n";
    
    generateFooter();
}



sub generateExtractQuoteForm {
    ( my $docOwner, my $docID, my $docText ) = @_;

    generateHeader( "extract quote" );

    my $formText = readFileValue( "$htmlDirectory/extractQuoteForm.html" );

    $formText =~ s/<!--#DOC_OWNER-->/$docOwner/;
    $formText =~ s/<!--#DOC_ID-->/$docID/;
    $formText =~ s/<!--#DOC_TEXT-->/$docText/;
    
    print $formText;


    generateFooter();
}



# end of package
1;
