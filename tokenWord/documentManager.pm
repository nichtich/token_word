package tokenWord::documentManager;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#
# 2003-January-7   Jason Rohrer
# Fixed regexp matching bugs.
# Changed to return new ID when document added.
# Fixed subregion bugs.
# Added function for rendering entire document.
#
# 2003-January-8   Jason Rohrer
# Added support for quote lists.
# Added more untainting.
#
# 2003-January-9   Jason Rohrer
# Fixed a bug in chunk inclusion.
#
# 2003-January-10   Jason Rohrer
# Added quote counter for each document.
#
# 2003-January-13   Jason Rohrer
# Added function for getting document title.
#
# 2003-January-14   Jason Rohrer
# Added support for most recent and most quoted lists.
#
# 2003-January-16   Jason Rohrer
# Fixed bug in most-quoted list.
# Added function for checking document existence.
#
# 2003-January-16   Jason Rohrer
# Added function for getting the quote count.
#
# 2003-April-30   Jason Rohrer
# Changed to use subroutine to check for file existence.
#


use tokenWord::common;
use tokenWord::chunkManager;


my $recentDocumentListSize = 10;
my $quotedDocumentListSize = 10;




##
# Adds a document.
#
# @param0 the username.
# @param1 the layout string for the document.
#
# @return the documentID of the new document.
#
# Example:
# my $docID = addDocument( "jb65", 
#                          "<jd45, 12, 104, 20>\n<jd45, 15, 23, 102>" );
##
sub addDocument {
    my $username = $_[0];
    my $layoutString = $_[1];
    
    my $docDirName = "$dataDirectory/users/$username/text/documents";

    my $nextID = readFileValue( "$docDirName/nextFreeID" );

    # untaint next id
    ( my $safeNextID ) = ( $nextID =~ /(\d+)/ );


    my $futureID = $safeNextID + 1;

    writeFile( "$docDirName/nextFreeID", "$futureID" );

    writeFile( "$docDirName/$safeNextID", "$layoutString" );

    # create a quote list
    writeFile( "$docDirName/$safeNextID.quoteList", "" );
    
    # create quote count
    writeFile( "$docDirName/$safeNextID.quoteCount", "0" );
    
    
    # add to most recent file
    
    my $mostRecentFile = "$dataDirectory/topDocuments/mostRecent";
    
    my $mostRecentString = readFileValue( $mostRecentFile );

    my @mostRecent = split( /\n/, $mostRecentString );

    my $docString = "< $username, $safeNextID >";
    
    if( scalar( @mostRecent ) >= $recentDocumentListSize ) {
        # remove least recent document
        pop( @mostRecent );
    }

    # add to top of list
    unshift( @mostRecent, $docString );
    
    my $newMostRecentString = join( "\n", @mostRecent );

    writeFile( $mostRecentFile, $newMostRecentString );



    return $safeNextID;
}



##
# Notes a quote between documents.
#
# @param0 the quoted document region string.
# @param1 the quoting document region string.
#
# Example:
# noteQuote( "<jd45, 12, 104, 20>", "<jcd14, 24, 10, 20>" ); 
##
sub noteQuote {
    ( my $quotedDocRegion, my $quotingDocRegion ) = @_;

    my @quotedRegionElements = extractRegionComponents( $quotedDocRegion );

    my $quotedUsername = $quotedRegionElements[0];
    my $quotedDocID = $quotedRegionElements[1];

    my $quoteListFileName = 
  "$dataDirectory/users/$quotedUsername/text/documents/$quotedDocID.quoteList";
    
    addToFile( $quoteListFileName, "$quotedDocRegion|$quotingDocRegion\n" );

    my $quoteCountFileName = 
 "$dataDirectory/users/$quotedUsername/text/documents/$quotedDocID.quoteCount";

    # for backwards compat with old database
    if( not doesFileExist( $quoteCountFileName ) ) {
        writeFile( $quoteCountFileName, "0" );
    }


    my $quoteCount = readFileValue( $quoteCountFileName );

    # untaint quote count
    ( $quoteCount ) = ( $quoteCount =~ /(\d+)/ );


    my $newCount = $quoteCount + 1;

    writeFile( $quoteCountFileName, $newCount );

    

    # check if this belongs in the most quoted file
    
    my $mostQuotedFile = "$dataDirectory/topDocuments/mostQuoted";

    # keep it simple and inefficient
    # Remove document from list if it's already there

    my $mostQuotedString = readFileValue( $mostQuotedFile );

    my @mostQuoted = split( /\n/, $mostQuotedString );

    my $foundExisting = 0;
    my $existingIndex = 0;
    my $currentIndex = 0;

    foreach $quoted ( @mostQuoted ) {
        ( my $docRegion, my $count ) = split( /\|/, $quoted );
        
        my @docRegionElements = extractRegionComponents( $docRegion );
        
        if( $docRegionElements[0] eq $quotedUsername and
            $docRegionElements[1] == $quotedDocID and
            not $foundExisting ) {
            
            # found doc in list
            $foundExisting = 1;
            $existingIndex = $currentIndex;
        }
        $currentIndex += 1;
    }
    
    if( $foundExisting ) {
        # remove it from list
        splice( @mostQuoted, $existingIndex, 1 );
    }


    # now find a spot for the document on the list

    my $foundSpot = 0;
    my $foundIndex = 0;
    $currentIndex = 0;

    foreach $quoted ( @mostQuoted ) {
        ( my $docRegion, my $count ) = split( /\|/, $quoted );
        
        if( $newCount > $count and not $foundSpot ) {
            $foundSpot = 1;
            $foundIndex = $currentIndex;
        }
        $currentIndex += 1;
    }
    

    if( $foundSpot ) {

        my $docString = "< $quotedUsername, $quotedDocID >|$newCount";
        
        
        if( scalar( @mostQuoted ) >= $quotedDocumentListSize ) {
            # remove least quoted document
            pop( @mostQuoted );
        }

        # add to spot in list
        splice( @mostQuoted, $foundIndex, 0, $docString );
    
        my $newMostQuotedString = join( "\n", @mostQuoted );

        writeFile( $mostQuotedFile, $newMostQuotedString );
    }
    elsif( scalar( @mostQuoted ) <= $quotedDocumentListSize ) {
        # there's room for this document at the end of the list

        my $docString = "< $quotedUsername, $quotedDocID >|$newCount";

        push( @mostQuoted, $docString );
        
        my $newMostQuotedString = join( "\n", @mostQuoted );

        writeFile( $mostQuotedFile, $newMostQuotedString );
    }

}



##
# Gets the number of quotes pointing at a document
#
# @param0 the username.
# @param1 the docID.
#
# @return the quote count.
##
sub getQuoteCount {
    ( my $username, my $docID ) = @_;
    my $quoteCountFileName = 
        "$dataDirectory/users/$username/text/documents/$docID.quoteCount";

    return readFileValue( $quoteCountFileName );
}



##
# Gets the most quoted documents.
#
# @return an array of <document>|numQuotes strings.
#
# Example:
# my @mostQuoted = getMostQuotedDocuments();
##
sub getMostQuotedDocuments {
    
    my $mostQuotedFile = "$dataDirectory/topDocuments/mostQuoted";
    
    my $mostQuotedString = readFileValue( $mostQuotedFile );

    my @mostQuoted = split( /\n/, $mostQuotedString );
}



##
# Gets the most recently created documents.
#
# @return an array of <document> strings.
#
# Example:
# my @recent = getMostRecentDocuments();
##
sub getMostRecentDocuments {
    
    my $mostRecentFile = "$dataDirectory/topDocuments/mostRecent";
    
    my $mostRecentString = readFileValue( $mostRecentFile );

    my @mostRecent = split( /\n/, $mostRecentString );
}



##
# Gets whether a document exists.
#
# @param0 the username.
# @param1 the docID.
#
# @return 1 if the document exist, and 0 otherwise.
#
# Example:
# my $exists = doesDocumentExist( "jb55", 5 );
##
sub doesDocumentExist {
    ( my $username, my $docID  ) = @_;

    my $docDirName = "$dataDirectory/users/$username/text/documents";

    
    if( doesFileExist( "$docDirName/$docID" ) ) { 
        return 1;
    }
    else {
        return 0;
    }
}



##
# Gets the chunks in a region.
#
# @param0 a list, containing username, docID, startOffset, and length.
#
# @return the chunks for the region.
#
# Example:
# my @regions = getRegionChunks( "jb55", 5, 104, 23 );
##
sub getRegionChunks {

    ( my $username, my $docID, my $startOffset, my $length ) = @_;


    my $docDirName = "$dataDirectory/users/$username/text/documents";

    
    
    $docString = readFileValue( "$docDirName/$docID" );

    $safeDocString = untaintDocString( $docString );

    # replace region separators with newlines
    $safeDocString =~ s/>\s*</>\n</;
    
    # accumulate "hit" regions (trimmed when necessary) here 
    my @selectedRegions = ();
    
    my $lengthSum = 0;
    
    my @regions = split( /\n/, $safeDocString );

    foreach my $region ( @regions ) {
        my @regionElements = extractRegionComponents( $region );

        my $regionLength = $regionElements[3];

        if( $lengthSum + $regionLength < $startOffset ) {
            # skip this region
        }
        elsif( $lengthSum > $startOffset + $length ) {
            # skip this region
        }
        elsif( $lengthSum < $startOffset && 
                 $lengthSum + $regionLength >= $startOffset ) {
            # partially include this region, trimming start
            my $startExcess = $startOffset - $lengthSum;
            
            my $endExcess = 0;
            
            if( $lengthSum + $regionLength > $startOffset + $length ) {
                # trim end also
                $endExcess = $lengthSum + $regionLength - 
                    ( $startOffset + $length );
            }
            

            my $joinedElements = join( ", ", 
                                       ( $regionElements[0],
                                         $regionElements[1],
                                         $regionElements[2] + $startExcess,
                                         $regionElements[3] - 
                                             $startExcess - $endExcess ) );
            push( @selectedRegions, "< $joinedElements >" );
        }
        elsif( $lengthSum >= $startOffset && 
                 $lengthSum + $regionLength <= $startOffset + $length ) {
            # fully include this region
            my $joinedElements = join( ", ", 
                                       ( $regionElements[0],
                                         $regionElements[1],
                                         $regionElements[2],
                                         $regionElements[3] ) );
            push( @selectedRegions, "< $joinedElements >" );
        }
        elsif( $lengthSum >= $startOffset && 
                 $lengthSum + $regionLength > $startOffset + $length ) {
            # partially include this region, trimming end
            my $endExcess = $lengthSum + $regionLength - 
                ( $startOffset + $length );

            my $joinedElements = join( ", ", 
                                       ( $regionElements[0],
                                         $regionElements[1],
                                         $regionElements[2],
                                         $regionElements[3] - $endExcess ) );
            push( @selectedRegions, "< $joinedElements >" );
        }
        
        $lengthSum = $lengthSum += $regionLength;
    }

    return @selectedRegions;
}



##
# Gets the text in a region.
#
# @param0 a list, containing username, docID, startOffset, and length.
#
# @return the text for the region.
#
# Example:
# my $text = renderRegionText( "jb55", 5, 104, 23 );
##
sub renderRegionText {
    
    my @chunks = getRegionChunks( @_ );

    return renderMultiChunkText( @chunks );
}



##
# Gets the title (the first paragraph) of a document.
#
# @param0 the username.
# @param1 the documentID.
#
# @return the title of the document.
#
# Example:
# my $title = getDocTitle( "jb55", 5 );
##
sub getDocTitle {
    ( my $username, my $docID ) = @_;

    my @chunks = getAllChunks( $username, $docID );


    # accumulate text for each chunk in this array
    my @chunkText = ();

    foreach my $region ( @chunks ) {
        my @regionElements = extractRegionComponents( $region );

        my $regionText = 
          tokenWord::chunkManager::getRegionText( @regionElements );

        push( @chunkText, $regionText );

        # try joining to see if we contain two newlines yet
        my $allText = join( "", @chunkText );
        
        if( $allText =~ /\n\n/ ) {
            # we've already got the title, so return it
            my @paragraphs = split( /\n\n/, $allText );
            return $paragraphs[0];
        }
    }
    
    # if we got here, then the document does not conain 
    # two consecutive newlines...   the whole doc is the title
    return join( "", @chunkText );    
}



##
# Gets a list of other documents that quote a document.
#
# @param0 the username.
# @param1 the documentID.
#
# @return list of document regions that quote this document.
#
# Example:
# my @quotingRegions = getQuotingDocuments( "jb55", 5 );
##
sub getQuotingDocuments {
    ( my $username, my $docID ) = @_;
    
    my $quoteListFileName = 
  "$dataDirectory/users/$username/text/documents/$docID.quoteList";
    
    my $quoteListText = readFileValue( $quoteListFileName );
    
    my @quoteList = split( /\n/, $quoteListText );

    # accumulate quoting docs here
    my @quotingDocs = ();

    foreach $quote ( @quoteList ) {
        
        my @quoteParts = split( /\|/, $quote );
        
        push( @quotingDocs, $quoteParts[1] );
    }

    return @quotingDocs;
}



##
# Gets all regions that make up a document.
#
# @param0 the username.
# @param1 the documentID.
#
# @return a list of all regions in the document.
#
# Example:
# my @regions = getAllChunks( "jb55", 5 );
##
sub getAllChunks {
    ( my $username, my $docID ) = @_;

    my $docDirName = "$dataDirectory/users/$username/text/documents";

    my $docString = readFileValue( "$docDirName/$docID" );

    my $safeDocString = untaintDocString( $docString );

    # replace region separators with newlines
    $safeDocString =~ s/>\s*</>\n</;

    my @regions = split( /\n/, $safeDocString );
    
    return @regions;
}



##
# Gets the full content text of a document.
#
# @param0 the username.
# @param1 the documentID.
#
# @return the rendered text of the document.
#
# Example:
# my $text = renderDocumentText( "jb55", 5 );
##
sub renderDocumentText {
    return renderMultiChunkText( getAllChunks( @_ ) );
}



##
# Gets the text rendering of a series of chunks.
#
# @param0 a list of chunks.
#
# @return the text rendering of the chunks.
##
sub renderMultiChunkText {
    my @chunks = @_;
    
    
    # accumulate text for each chunk in this array
    my @chunkText = ();

    foreach my $region ( @chunks ) {
        my @regionElements = extractRegionComponents( $region );

        my $regionText = 
          tokenWord::chunkManager::getRegionText( @regionElements );

        push( @chunkText, $regionText );
    }
    
    return join( "", @chunkText );
}



##
# Untaints a document string.
#
# @param0 the string to untaint.
#
# @return the untainted string.
##
sub untaintDocString {
    my $docString = $_[0];
    
    my @docParts = split( /\n/, $docString );

    my @safeParts = ();

    for my $part ( @docParts ) {
        my ( $safePart ) = ( $part =~ 
/(<\s*\w+\s*,\s*\d+\s*,\s*\d+\s*,\s*\d+\s*;?\s*\w*\s*,?\s*\d*\s*,?\s*\d*\s*>)/
                             );
        
        push( @safeParts, $safePart );
    }

    my $safeDocString = join( "\n", @safeParts );

    return $safeDocString;
}



# end of package
1;
