package tokenWord::userWorkspace;

#
# Modification History
#
# 2003-January-7   Jason Rohrer
# Created.
#
# 2003-January-8   Jason Rohrer
# Added function for extracting abstract quotes.
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

    # for tracking locations of quotes in this document
    my $netDocOffset = 0;
    my @quotesToNote = ();


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

            my @docRegion = 
                tokenWord::quoteClipboard::getQuoteRegion( $username,  
                                                           $quoteNumber );
            
            # add this quote to our list of quotes to note

            my $quoteLength = $docRegion[3];
            
            my $quotedDocRegionString = join( ",", @docRegion );
            my $quotingDocRegionString = 
                "$username, DOC_ID, $netDocOffset, $quoteLength";

            push( @quotesToNote, 
                  "< $quotedDocRegionString > | < $quotingDocRegionString >" );

            $netDocOffset += $quoteLength;



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

            $netDocOffset += $chunkLength;
        }
        
    }

    my $concreteDocumentString = join( "\n", @docRegions );

    my $newDocID = tokenWord::documentManager::addDocument( $username, 
                                                    $concreteDocumentString );
    
    # note our quotes in the document manager

    foreach my $quoteString ( @quotesToNote ) {

        my @quoteParts = split( /\s*\|\s*/, $quoteString );
        
        # insert new doc ID into placeholder
        $quoteParts[1] =~ s/DOC_ID/$newDocID/;
        
        tokenWord::documentManager::noteQuote( @quoteParts );
    }
    

    return $newDocID;
}



##
# Extracts a quoted region from abstract document (text and quote tag pair).
#
# @param0 the quoting user.
# @param1 the quoted user.
# @param3 the quoted documentID.
# @param4 the abstract document string.
#
# @return the id of the new quote.
#
# Example:
# my $quoteID = extractAbstractQuote( "jj55", "jdg1", 10, 
#                                     "This is a <q>test document</q>." );
##
sub extractAbstractQuote {
    ( my $quotingUser, my $quotedUser, my $docID, my $docText ) = @_;
    
    
    # split around quote tags
    my @splitDocument = split( /<\s*\/?\s*q\s*>/, $docText );

    my $quoteOffset = length( $splitDocument[0] );
    my $quoteLength = length( $splitDocument[1] );
    
    tokenWord::quoteClipboard::addQuote( $quotingUser,
                                         $quotedUser,
                                         $docID,
                                         $quoteOffset,
                                         $quoteLength );
}



# end of package
1;
