package tokenWord::indexSearch;

#
# Modification History
#
# 2003-January-17   Jason Rohrer
# Created.
# Fixed a bug in indexing empty words.
#
# 2003-January-18   Jason Rohrer
# Changed to sort documents in most-quoted-first order.
#
# 2003-April-30   Jason Rohrer
# Changed to use subroutine to check for file existence.
# Changed to use subroutine to make directories.
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

    my $indexDirectory = "$dataDirectory/index";
    

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
        
        if( $word ne "" ) {

            my $firstLetter = substr( $word, 0, 1 );
        
            my $letterDirectory = "$indexDirectory/$firstLetter";

            if( not doesFileExist( "$letterDirectory" ) ) {
                makeDirectory( "$letterDirectory", oct( "0777" ) );
            }
            addToFile( "$letterDirectory/$word", "$docRegion\n" );
        }
    }


    
    # increment indexed doc count

    my $docCountFileName = 
        "$dataDirectory/index/docCount";

    my $docCount = readFileValue( $docCountFileName );

    # untaint doc count
    ( $docCount ) = ( $docCount =~ /(\d+)/ );


    my $newCount = $docCount + 1;

    writeFile( $docCountFileName, $newCount );

}



##
# Gets the number of documents in the index.
#
# @return the indexed document count.
##
sub getIndexedDocCount {
    return readFileValue( "$dataDirectory/index/docCount" );
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
        
        if( doesFileExist( $wordFile ) ) {

            my @docRegions = split( /\n/, readFileValue( $wordFile ) );
            
            # collect quote count for each document
            my @quoteCounts = ();

            foreach $region ( @docRegions ) {
                ( my $docOwner, my $docID ) = 
                    extractRegionComponents( $region );

                my $quoteCount = 
                  tokenWord::documentManager::getQuoteCount( $docOwner,
                                                             $docID );
                push( @quoteCounts, $quoteCount );
            }
            
            # sort indices by comparing their quote counts
            # sort in decending order
            my @sortedIndices = 
                sort { $quoteCounts[ $b ] <=> $quoteCounts[ $a ] } 
                     0 .. $#quoteCounts;
            
            # now re-order the document regions
            @docRegions = @docRegions[ @sortedIndices ];
            
            # note:  We only need to do this sort for the documents
            # containing the first word, since only those documents
            # are possible hit documents

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
# Used internally
##




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
        
        if( doesFileExist( $wordFile ) ) {
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
