package tokenWord::chunkManager;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#


use tokenWord::common;



##
# Adds a user.
#
# @param0 the username.
# @param1 the chunk string.
#
# Example:
# addUser( "jb65", "This is a new chunk." );
##
sub addChunk {
    my $username = $_[0];
    my $chunkText = $_[1];
    
    # use regexp to untaint username
    my ( $safeUsername ) = 
        ( $username =~ /(\w+)$/ );
    
    my $chunkDirName = "$dataDirectory/users/$safeUsername/text/chunks";

    my $nextID = readFileValue( "$chunkDirName/nextFreeID" );

    # untaint next id
    my ( $safeNextID ) = ( $nextID =~ /(\d+)/ );


    my $futureID = $safeNextID + 1;

    writeFile( "$chunkDirName/nextFreeID", "$futureID" );

    writeFile( "$chunkDirName/$safeNextID", "$chunkText" );
    
}



##
# Gets a region.
#
# @param0 a list, containing username, chunkID, startOffset, and length.
#
# @return the text for the region
#
# Example:
# my $text = getRegion( "jb55", 5, 104, 23 );
##
sub getRegion {

    ( my $username, my $chunkID, my $startOffset, my $length ) = @_;


    my $chunkDirName = "$dataDirectory/users/$username/text/chunks";

    
    
    $chunkString = readFileValue( "$chunkDirName/$chunkID" );
    
    return substr( $chunkString, $startOffset, $length );

}



# end of package
1;
