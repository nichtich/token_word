package tokenWord::documentManager;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#


use tokenWord::common;


##
# Adds a document.
#
# @param0 the username.
# @param1 the layout string for the document.
#
# Example:
# addUser( "jb65", "<jd45, 12, 104, 20>\n<jd45, 15, 23, 102>" );
##
sub addDocument {
    my $username = $_[0];
    my $layoutString = $_[1];
    
    my $docDirName = "$dataDirectory/users/$username/text/documents";

    my $nextID = readFileValue( "$docDirName/nextFreeID" );

    # untaint next id
    my ( $safeNextID ) = ( $nextID =~ /(\d+)/ );


    my $futureID = $safeNextID + 1;

    writeFile( "$docDirName/nextFreeID", "$futureID" );

    writeFile( "$docDirName/$safeNextID", "$layoutString" );
    
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
    
    
    my @selectedRegions = ();
    
    my $lengthSum = 0;
    
    my @regions = split( /\n/, $docString );

    foreach my $region ( @regions ) {
        
        my @regionParts = split( /;/, $region );        

        # we only care about the first part here (discard document info)
        my @regionElements = split( /<*\s*,\s*>*/, $regionParts[0] );
        print "region parts = $regionParts[0]\n";

        #FIXME

        my $regionLength = $regionElements[3];

        if( $lengthSum + $regionLength < $startOffset ) {
            # skip this region
        }
        elsif( $lengthSum > $startOffset + $length ) {
            # skip this region
        }
        elsif( $lengthSum < $startOffset && 
                 $lengthSum + $regionLength >= $startOffset ) {
            # partially include this region
            my $excess = $lengthSum + $regionLength - $startOffset;

            my $joinedElements = join( ", ", 
                                       ( $regionElements[0],
                                         $regionElements[1],
                                         $regionElements[2] + $excess,
                                         $regionElements[3] - $excess ) );
            push( @selectedRegions, "< $joinedElements >" );
        }
        elsif( $lengthSum >= $startOffset && 
                 $lengthSum + $regionLength <= $startOffset + $length ) {
            # fully include this region
            my $joinedElements = join( ", ", @regionElements );
            push( @selectedRegions, "< $joinedElements >" );
        }
        elsif( $lengthSum >= $startOffset && 
                 $lengthSum + $regionLength > $startOffset + $length ) {
            # partially include this region
            my $excess = $lengthSum + $regionLength - 
                ( $startOffset + $length );

            my $joinedElements = join( ", ", 
                                       ( $regionElements[0],
                                         $regionElements[1],
                                         $regionElements[2],
                                         $regionElements[3] - $excess ) );
            push( @selectedRegions, "< $joinedElements >" );
        }
        
        $lengthSum = $lengthSum += $regionLength;
    }

    return @regions;

}



##
# Gets the text in a region.
#
# @param0 a list, containing username, docID, startOffset, and length.
#
# @return the text for the region.
#
# Example:
# my $text = getRegionText( "jb55", 5, 104, 23 );
##
sub getRegionText {
    
    my @chunks = getRegionChunks( @_ );
    

    my @chunkText = ();

    foreach my $region ( @chunks ) {
        my @regionElements = split( /<\s+,\s+>/, $region );
        
        push( @chunkText, 
              chunkManager::getRegion( @regionElements ) );
    }
    
    return join( "", @chunkText );
}



# end of package
1;
