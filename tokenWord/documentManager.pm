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


use tokenWord::common;
use tokenWord::chunkManager;


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
