package tokenWord::quoteClipboard;

#
# Modification History
#
# 2003-January-7   Jason Rohrer
# Created.
#
# 2003-January-8   Jason Rohrer
# Added taint checking for quote region string.
#


use tokenWord::common;
use tokenWord::documentManager;



##
# Adds a quote.
#
# @param0 the username.
# @param1 a list containing the quoted user, docID, startOffset, and length.
#
# @return the id of the new quote.
#
# Example:
# my $quoteID = addQuote( "jj55", "jdg10", 4, 14, 23 );
##
sub addQuote {
    ( my $username, my @docRegion ) = @_;
    
    my $docRegionString = join( ", ", @docRegion );

    my $layoutString = "< $docRegionString >";
    

    my $quoteDirName = "$dataDirectory/users/$username/quoteClipboard";

    my $nextID = readFileValue( "$quoteDirName/nextFreeID" );

    # untaint next id
    my ( $safeNextID ) = ( $nextID =~ /(\d+)/ );


    my $futureID = $safeNextID + 1;

    writeFile( "$quoteDirName/nextFreeID", "$futureID" );

    writeFile( "$quoteDirName/$safeNextID", "$layoutString" );
    
    return $safeNextID;

}



##
# Gets the number of quotes in a user's clipboard.
#
# @param0 the username.
#
# @return the number of quotes.
#
# Example:
# my $numberOfQuotes = getQuoteCount( "jj55" );
##
sub getQuoteCount {
    ( my $user ) = @_;
    
    my $quoteDirName = "$dataDirectory/users/$user/quoteClipboard";

    my $nextID = readFileValue( "$quoteDirName/nextFreeID" );

    # untaint next id
    my ( $safeNextID ) = ( $nextID =~ /(\d+)/ );
    
    return $safeNextID;
}



##
# Gets the region associated with a quote.
#
# @param0 the username.
# @param1 the quoteID.
#
# @return a list containing the region descriptors
#   (username, docID, startOffset, length).
#
# Example:
# my @docRegion = getQuoteRegion( "jj55", 3 );
##
sub getQuoteRegion {
    ( my $username, my $quoteID ) = @_;

    my $quoteDirName = "$dataDirectory/users/$username/quoteClipboard";   
    
    my $quoteRegionString = readFileValue( "$quoteDirName/$quoteID" );

    # untaint
    ( my $safeQuoteRegionString ) = 
        ( $quoteRegionString =~ 
          /(<\s*\w+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*>)/ );

    return extractRegionComponents( $safeQuoteRegionString );
}



##
# Gets the text content for a quote.
#
# @param0 the username.
# @param1 the quoteID.
#
# @return the text rendering of a quote.
#
# Example:
# my $quoteText = renderQuoteText( "jj55", 3 );
##
sub renderQuoteText {
    ( my $username, my $quoteID ) = @_;
                                        
    return tokenWord::documentManager::renderRegionText( 
        getQuoteRegion( $username, $quoteID ) );
}



##
# Gets the text content for all of user's quotes.
#
# @param0 the username.
#
# @return the text rendering of all quotes in an array.
#
# Example:
# my @quoteList = renderAllQuotes( "jj55" );
##
sub renderAllQuotes {
    ( my $user ) = @_;

    my $numQuotes = getQuoteCount( $user );

    my @quoteList = ();

    for( my $quoteNumber=0; $quoteNumber < $numQuotes; $quoteNumber++ ) { 
        my $text = renderQuoteText( $user, $quoteNumber );
        
        push( @quoteList, $text );          
    }
    
    return @quoteList;
}



##
# Gets the document regions for all of user's quotes.
#
# @param0 the username.
#
# @return the regions of all quotes in an array.
#
# Example:
# my @quoteRegionList = renderAllQuoteRegions( "jj55" );
##
sub getAllQuoteRegions {
    ( my $user ) = @_;
    
    my $numQuotes = getQuoteCount( $user );

    my @quoteList = ();

    for( my $quoteNumber=0; $quoteNumber < $numQuotes; $quoteNumber++ ) { 
        my @region = getQuoteRegion( $user, $quoteNumber );
        
        my $joinedRegion = join( ", ", @region );

        push( @quoteList, "< $joinedRegion >" );          
    }
    
    return @quoteList;
}



# end of package
1;
