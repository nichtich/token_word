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
# 2003-April-30   Jason Rohrer
# Added skeleton for using db database instead of filesystem.
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
                 bypass_printFile
                 readFileValue
                 bypass_readFileValue
                 doesFileExist
                 bypass_doesFileExist
                 writeFile
                 bypass_writeFile
                 addToFile
                 bypass_addToFile
                 makeDirectory
                 bypass_makeDirectory
                 trimWhitespace
                 extractRegionComponents );
}



$dataDirectoryName = "tokenWordData";
$dataDirectory = "../../cgi-data/tokenWordData";
$htmlDirectory = "htmlTemplates";

$dbFile = "../../cgi-data/tokenWordData.db";

# 1 to use db file
# 0 to use filesytem
$useDB = 0;


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

    if( $useDB ) {
    }
    else {    
        bypass_printFile( $fileName );
    }
}



##
# Prints the contents of a file (from filesystem, ignoring any db)
# to standard out.
#
# @param0 the name of the file.
#
# Example:
# bypass_printFile( "myFile.txt" );
##
sub bypass_printFile {
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
    
    if( $useDB ) {
    }
    else {
        bypass_readFileValue( $fileName );
    }
}



##
# Reads file as a string, accessing the filesystem directly (ignoring any db).
#
# @param0 the name of the file.
#
# @return the file contents as a string.
#
# Example:
# my $value = bypass_readFileValue( "myFile.txt" );
##
sub bypass_readFileValue {
    my $fileName = $_[0];
    open( FILE, "$fileName" ) or die;
    flock( FILE, 1 ) or die;

    my @lineList = <FILE>;

    my $value = join( "", @lineList );

    close FILE;
 
    return $value;
}



##
# Checks if a file exists.
#
# @param0 the name of the file.
#
# @return 1 if it exists, and 0 otherwise.
#
# Example:
# $exists = doesFileExist( "myFile.txt" );
##
sub doesFileExist {
    my $fileName = $_[0];
        
    if( $useDB ) {
    }
    else {
        return bypass_doesFileExist( $fileName ); 
    }
}



##
# Checks if a file exists in the filesystem, ignoring any db.
#
# @param0 the name of the file.
#
# @return 1 if it exists, and 0 otherwise.
#
# Example:
# $exists = bypass_doesFileExist( "myFile.txt" );
##
sub bypass_doesFileExist {
    my $fileName = $_[0];
    if( -e $fileName ) {
        return 1;
    }
    else {
        return 0;
    }
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
    
    if( $useDB ) {
    }
    else {
        bypass_writeFile( $fileName, $stringToPrint );
    }
}



##
# Writes a string to a file in the filesystem, bypassing any db.
#
# @param0 the name of the file.
# @param1 the string to print.
#
# Example:
# bypass_writeFile( "myFile.txt", "the new contents of this file" );
##
sub bypass_writeFile {
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
        
    if( $useDB ) {
    }
    else {
        bypass_addToFile( $fileName, $stringToPrint );
    }
}



##
# Appends a string to a file in the filesystem, bypassing any db.
#
# @param0 the name of the file.
# @param1 the string to append.
#
# Example:
# bypass_addToFile( "myFile.txt", "the new contents of this file" );
##
sub bypass_addToFile {
    my $fileName = $_[0];
    my $stringToPrint = $_[1];
        
    open( FILE, ">>$fileName" ) or die;
    flock( FILE, 2 ) or die;
        
    print FILE $stringToPrint;
        
    close FILE;
}



##
# Makes a directory file.
#
# @param0 the name of the directory.
# @param1 the octal permission mask.
#
# Example:
# makeDirectory( "myDir", oct( "0777" ) );
##
sub makeDirectory {
    my $fileName = $_[0];
    my $permissionMask = $_[1];
    
    if( $useDB ) {
    }
    else {
        bypass_makeDirectory( $fileName, $permissionMask );
    }
}



##
# Makes a directory file in the filesystem, bypassing any db.
#
# @param0 the name of the directory.
# @param1 the octal permission mask.
#
# Example:
# bypass_makeDirectory( "myDir", oct( "0777" ) );
##
sub bypass_makeDirectory {
    my $fileName = $_[0];
    my $permissionMask = $_[1];
    
    mkdir( $fileName, $permissionMask );
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
