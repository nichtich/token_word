package tokenWord::indexSearch;

#
# Modification History
#
# 2003-January-17   Jason Rohrer
# Created.
#

use tokenWord::common;



##
# Adds a document to the index.
#
# @param0 the username.
# @param1 the docID of the document.
# @param2 the text of the document
#
# Example:
# addToIndex( "jj55", 10, "I am quoting here: a quote." );
##
sub addToIndex {
    ( my $username, my $docID, my $docText ) = @_;
    
    my $docRegion = "< $username, $docID >";

    my @docWords = split( /\s+/, $docText );

    my $indexDirectory = "$dataDirectory/index/";
    

    # we want to avoid indexing duplicate words, so hash them
    my %wordHash = ();

    foreach my $word ( @docWords ) {
        
        # untaint
        ( $word ) = ( $word =~ /(\w+)/ );

        # lowercase
        $word = lc( $word );

        $wordHash{ $word } = 1;

    }
    
    
    # now pull out the "hit" keys
    my @prunedWords = keys( %wordHash );


    # now stick them into the index
    foreach my $word ( @prunedWords ) {

        my $firstLetter = substr( $word, 0, 1 );
        
        my $letterDirectory = "$indexDirectory/$firstLetter";

        if( not -e "$letterDirectory" ) {
            mkdir( "$letterDirectory", oct( "0777" ) );
        }
        
        addToFile( "$letterDirectory/$word", "$docRegion\n" );
    }
}



##
# Searches the index for documents containing ALL specified search words.
#
# @param0 the maximum number of hits to return.
# @param1 the search words in an array.
#
# @return an array of "< username, docID >" region strings.
#
# Example:
# my @hits = searchIndex( 20, "test", "this", "search" );
##
sub searchIndex {
    ( my $maxHits, my @searchWords ) = @_;
    
    my $numFound = 0;

    my @foundDocs = ();

    
    # first untaint, lowercase, and hash to remove duplicates
    my %wordHash = ();

    foreach my $word ( @searchWords ) {
        
        # untaint
        ( $word ) = ( $word =~ /(\w+)/ );

        # lowercase
        $word = lc( $word );
        
        if( $word ne "" ) {
            $wordHash{ $word } = 1;
        }
    }

    my @cleanSearchWords = keys( %wordHash );

    # search by the first word first
    # if we don't find it, we can stop
    if( scalar( @cleanSearchWords ) > 0 ) {
        my $firstWord = shift( @cleanSearchWords );

        my $firstLetter = substr( $firstWord, 0, 1 );

        my $wordFile = "$dataDirectory/index/$firstLetter/$firstWord";
        
        if( -e $wordFile ) {

            my @docRegions = split( /\n/, readFileValue( $wordFile ) );
            
            if( scalar( @cleanSearchWords ) > 0 ) {

                foreach $region ( @docRegions ) {
                    ( my $docOwner, my $docID ) = 
                        extractRegionComponents( $region );
                
                    if( doesDocContainWords( $docOwner, $docID,
                                             @cleanSearchWords ) ) {
                        push( @foundDocs, $region );
                        $numFound += 1;
                    }
                    
                    if( $numFound == $maxHits ) {
                        return @foundDocs;
                    }
                }
            }
            else {
                # only one search word
                # return entire list, after trimming
                splice( @docRegions, $maxHits );
                return @docRegions;
            }
                        
        }
    }
    
    
    return @foundDocs;
}



##
# Gets whether a document contains a list of words.
# Words are assumed to be "properly-formatted" and lower-case.
#
# @param0 the doc owner.
# @param1 the doc ID.
# @param3 the array of words.
#
# @return 1 if the document contains ALL of the words, or 0 otherwise.
#
# Example:
# my $hits = doesDocContainWords( "jj55", 12, "test", "this", "search" );
##
sub doesDocContainWords { 
    ( my $docOwner, my $docID, my @cleanSearchWords ) = @_; 
    
    my $miss = 0;

    foreach $word ( @cleanSearchWords ) {
        
        my $firstLetter = substr( $word, 0, 1 );
        my $wordFile = "$dataDirectory/index/$firstLetter/$word";
        
        if( -e $wordFile ) {
            my @docRegions = split( /\n/, readFileValue( $wordFile ) );
            
            $miss = 1;
            foreach $region ( @docRegions ) {
                ( my $owner, my $id ) = 
                    extractRegionComponents( $region );
                if( $docOwner eq $owner and $docID == $id ) {
                    $miss = 0;
                }
            }
        }
        else {
            $miss = 1;
        }


        if( $miss ) {
            return 0;
        }
    }

    if( $miss ) {
        return 0;
    }
    else {
        return 1;
    }
}



# end of package
1;
