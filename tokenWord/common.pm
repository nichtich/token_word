package tokenWord::common;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#


# define our exported variables and subroutines
sub BEGIN {
    use Exporter();
    use vars qw( $VERSIONS @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
    @ISA = qw( Exporter );
    @EXPORT = qw(
                 $dataDirectory
                 printFile
                 writeFile
                 trimWhitespace );
}



$dataDirectory = "tokenWordData";



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



# end of package
1;
