package tokenWord::userWorkspace;

#
# Modification History
#
# 2003-January-7   Jason Rohrer
# Created.
#


use tokenWord::common;
use tokenWord::chunkManager;
use tokenWord::documentManager;
use tokenWord::quoteClipboard;



##
# Submits an abstract document (text and quote tags).
#
# @param0 the username.
# @param1 the text of the document.
#
# @return the id of the new document.
#
# Example:
# my $docID = submitAbstractDocument( "jj55", "I am quoting here: <q 10>" );
##
sub submitAbstractDocument {
    ( my $username, my $docText ) = @_;
    
    # replace < and > with @< and >@
    $docText =~ s/</@</;
    $docText =~ s/>/>@/;
    
    my @docSections = split( /@/, $docText );

    my @docRegions = ();

    foreach my $section ( @docSections ) {
        if( $section =~ m/<\s*q\s*\d+\s*>/ ) {
            # a quote
            
            #extract the quote number
            $section =~ s/[<q>]//g;
            $section =~ s/\s//;

            my $quoteNumber = $section;

            # build a < chunkLocator; docLocator > style locator for each 
            # chunk in this quote, where the docLocator points to the
            # document being quoted now

            my @docRegion = getQuoteRegion( "jj55",  $quoteNumber );
            
            my @quoteChunks =
              tokenWord::documentManager::getRegionChunks( @docRegion );
            
            my $docOwner = $docRegion[0];
            my $docNumber = $docRegion[1];
            my $currentDocOffset = $docRegion[2];

            foreach $chunk ( @quoteChunks ) {

                my @chunkElements = extractRegionComponents( $chunk );
                
                my $chunkLength = $chunkElements[3];
                
                my $chunkLocator = join( ", ", @chunkElements );

                my $docLocator = join( ", ", ( $docOwner, $docNumber,
                                               $currentDocOffset ) );

                my $fullChunkLocator =
                    join( "; ", ( $chunkLocator, $docLocator ) );
                
                push( @docRegions, "< $fullChunkLocator >" );
                
                $currentDocOffset += $chunkLength;
            }

        }
        else {
            # a new chunk

            my $chunkID = 
              tokenWord::chunkManager::addChunk( $username, 
                                                 $section );
            my $chunkLength = length( $section );

            my $chunkString = "< $username, $chunkID, 0, $chunkLength >";
            
            push( @docRegions, $chunkString );
        }
        
    }
    
    my $concreteDocumentString = join( "\n", @docRegions );

    return tokenWord::documentManager::addDocument( $username, 
                                                    $concreteDocumentString );
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
    my $quoteDirName = "$dataDirectory/users/$username/quoteClipboard";

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
    
    $quoteRegionString = readFileValue( "$quoteDirName/$quoteID" );

    return extractRegionComponents( $quoteRegionString );
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
# my @quoteText = renderQuoteText( "jj55", 3 );
##
sub renderQuoteText {
    ( my $username, my $quoteID ) = @_;
                                        
    return tokenWord::documentManager::renderRegionText( 
        getQuoteRegion( $username, $quoteID ) );
}



# end of package
1;
