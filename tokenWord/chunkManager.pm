package tokenWord::chunkManager;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#
# 2003-January-7   Jason Rohrer
# Changed to return new ID when chunk added.
#


use tokenWord::common;


##
# Adds a chunk.
#
# @param0 the username.
# @param1 the chunk string.
#
# @return the chunkID of the new chunk.
#
# Example:
# my $chunkID = addChunk( "jb65", "This is a new chunk." );
##
sub addChunk {
    my $username = $_[0];
    my $chunkText = $_[1];
    
    my $chunkDirName = "$dataDirectory/users/$username/text/chunks";

    my $nextID = readFileValue( "$chunkDirName/nextFreeID" );

    # untaint next id
    my ( $safeNextID ) = ( $nextID =~ /(\d+)/ );


    my $futureID = $safeNextID + 1;

    writeFile( "$chunkDirName/nextFreeID", "$futureID" );

    writeFile( "$chunkDirName/$safeNextID", "$chunkText" );
    
    return $safeNextID;
}



##
# Gets text for a region.
#
# @param0 a list, containing username, chunkID, startOffset, and length.
#
# @return the text for the region
#
# Example:
# my $text = getRegionText( "jb55", 5, 104, 23 );
##
sub getRegionText {

    ( my $username, my $chunkID, my $startOffset, my $length ) = @_;

    
    my $chunkDirName = "$dataDirectory/users/$username/text/chunks";

    $chunkString = readFileValue( "$chunkDirName/$chunkID" );
    
    return substr( $chunkString, $startOffset, $length );

}



# end of package
1;
