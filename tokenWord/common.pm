package tokenWord::common;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#
# 2003-January-7   Jason Rohrer
# Added a function for extracting region components.
#
# 2003-January-8   Jason Rohrer
# Fixed an extra newline bug in readFileValue.
#
# 2003-January-17   Jason Rohrer
# Moved data directory to a safer location (so tw directory does not
# have to be world-writeable).
#


# define our exported variables and subroutines
sub BEGIN {
    use Exporter();
    use vars qw( $VERSIONS @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
    @ISA = qw( Exporter );
    @EXPORT = qw(
                 $dataDirectoryName
                 $dataDirectory
                 $htmlDirectory
                 printFile
                 readFileValue
                 writeFile
                 addToFile
                 trimWhitespace
                 extractRegionComponents );
}



$dataDirectoryName = "tokenWordData";
$dataDirectory = "../../cgi-data/tokenWordData";
$htmlDirectory = "htmlTemplates";



##
# Prints the contents of a file to standard out.
#
# @param0 the name of the file.
#
# Example:
# printFile( "myFile.txt" );
##
sub printFile {
    my $fileName = $_[0];
    open( FILE, "$fileName" ) or die;
    flock( FILE, 1 ) or die;

    my @lineList = <FILE>;

    print @lineList;

    close FILE;
}



##
# Reads file as a string.
#
# @param0 the name of the file.
#
# @return the file contents as a string.
#
# Example:
# my $value = readFileValue( "myFile.txt" );
##
sub readFileValue {
    my $fileName = $_[0];
    open( FILE, "$fileName" ) or die;
    flock( FILE, 1 ) or die;

    my @lineList = <FILE>;

    my $value = join( "", @lineList );

    close FILE;
 
    return $value;
}



##
# Writes a string to a file.
#
# @param0 the name of the file.
# @param1 the string to print.
#
# Example:
# writeFile( "myFile.txt", "the new contents of this file" );
##
sub writeFile {

    my $fileName = $_[0];
    my $stringToPrint = $_[1];

    open( FILE, ">$fileName" ) or die;
    flock( FILE, 2 ) or die;

    print FILE $stringToPrint;

    close FILE;
}



##
# Appends a string to a file.
#
# @param0 the name of the file.
# @param1 the string to append.
#
# Example:
# addToFile( "myFile.txt", "the new contents of this file" );
##
sub addToFile {

    my $fileName = $_[0];
    my $stringToPrint = $_[1];

    open( FILE, ">>$fileName" ) or die;
    flock( FILE, 2 ) or die;

    print FILE $stringToPrint;

    close FILE;
}



##
# Trims any whitespace from the beginning and end of a string.
#
# @param0 the string to trim.
#
# @return the trimmed string.
##
sub trimWhitespace {   

    foreach( $_[0] )
    {
        # trim from front of string
        s/^\s+//;

        # trim from end of string
        s/\s+$//;
    }
}



##
# Converts the text representation of a region to a list.
#
# @param0 the text representation of a region.
#
# @return a list of components describing the region.
#
# Example:
# my @regionComponents = extractRegionComponents( "<jb55, 5, 104, 23>" );
##
sub extractRegionComponents {
    my $regionText = $_[0];
    
    # first remove all < or >
    $regionText =~ s/[<>]//g;
    trimWhitespace( $regionText );

    # replace ; with ,
    $regionText =~ s/;/,/;
    
    my @regionElements = split( /\s*,\s*/, $regionText );

    return @regionElements;
}



# end of package
1;
