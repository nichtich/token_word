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
# Added db implementation.
# Added function for populating database from a tarball.
#



# the db file interface
use DB_File;
use Fcntl;



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
                 updateDatabaseFromDataTarball
                 trimWhitespace
                 extractRegionComponents );
}



$dataDirectoryName = "tokenWordData";
$dataDirectory = "../../cgi-data/tokenWordData";
$dataDirectoryPath = "../../cgi-data/";
$htmlDirectory = "htmlTemplates";

$dbFile = "../../cgi-data/tokenWordData.db";

# 1 to use db file
# 0 to use filesytem
$useDB = 1;


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
        tie my %db_hash, 
            "DB_File", $dbFile, O_CREAT | O_RDONLY, # | O_SHLOCK, 
            0666, $DB_HASH;
        my $value = $db_hash{ $fileName };
        untie %db_hash;
        
        print $value;
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
        tie my %db_hash, 
            "DB_File", $dbFile, O_CREAT | O_RDONLY, # | O_SHLOCK, 
            0666, $DB_HASH;
        my $value = $db_hash{ $fileName };
        untie %db_hash;
        
        return $value;
    }
    else {
        return bypass_readFileValue( $fileName );
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
        tie my %db_hash, 
            "DB_File", $dbFile, O_CREAT | O_RDONLY, # | O_SHLOCK, 
            0666, $DB_HASH;
        my $exists = 0;
        if( $db_hash{ $fileName } ) {
            $exists = 1;
        }
        untie %db_hash;
        
        return $exists;
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
        tie my %db_hash, 
            "DB_File", $dbFile, O_CREAT | O_RDWR, # | O_EXLOCK, 
            0666, $DB_HASH;
        $db_hash{ $fileName } = $stringToPrint;
        untie %db_hash;
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
        tie my %db_hash, 
            "DB_File", $dbFile, O_CREAT | O_RDWR, # | O_EXLOCK, 
            0666, $DB_HASH;
        my $oldValue = $db_hash{ $fileName };
        $db_hash{ $fileName } = "$oldValue$stringToPrint";
        untie %db_hash;

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
        tie my %db_hash, 
            "DB_File", $dbFile, O_CREAT | O_RDWR, # | O_EXLOCK, 
            0666, $DB_HASH;
        # marker entry
        $db_hash{ $fileName } = "directory";
        untie %db_hash;
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
# Updates the database using a data tarball.
##
sub updateDatabaseFromDataTarball {
    my $oldPath = $ENV{ "PATH" };
    $ENV{ "PATH" } = "";

    # extract the tar file
    my $outcome = 
        `cd $dataDirectory/..; /bin/cat ./$dataDirectoryName.tar.gz | /bin/gzip -d - > ./$dataDirectoryName.tar`;

    # first, get a file list
    my $fileList =
        `cd $dataDirectory/..; /bin/cat ./$dataDirectoryName.tar | /bin/tar tf -`;

    my @files = split( /\s+/, $fileList );

    my $fileCount = 1;
    my $totalFiles = scalar( @files );

    foreach $file ( @files ) {
	my ( $safeFileName ) = ( $file =~ /([\w\/]+)/ );
        
	$fullFileName = "$dataDirectoryPath$safeFileName";

	my @fileNameParts = split( //, $fullFileName );

	if( $fileNameParts[ length( $fullFileName ) - 1 ] eq "/" ) {
	    # a directory

	    # strip off trailing "/"
	    pop( @fileNameParts );
	    $fullFileName = join( "", @fileNameParts );

	    print 
	     "$fileCount/$totalFiles: Inserting directory $fullFileName<BR>\n";
	    makeDirectory( $fullFileName, oct( "0777" ) )
	    }
	else {
	    print "$fileCount/$totalFiles: Inserting file $fullFileName<BR>\n";

	    my $fileContents = 
		`cd $dataDirectory/..; /bin/cat ./$dataDirectoryName.tar | /bin/tar xOf - $safeFileName`;
	    writeFile( $fullFileName, $fileContents );
	}
	$fileCount = $fileCount + 1;
    }
    my $outcome2 =
        `cd $dataDirectory/..; /bin/rm ./$dataDirectoryName.tar`;
    print "Outcome = $outcome $outcome2 <BR>(blank indicates no error)";
    
    $ENV{ "PATH" } = $oldPath;
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
