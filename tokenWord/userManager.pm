package tokenWord::userManager;

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
# @param1 the user's password.
# @param2 the user's starting token balance.
#
# Example:
# addUser( "jb65", "letMeIn", 15000 );
##
sub addUser {
    my $username = $_[0];
    my $password = $_[1];
    my $startBalance = $_[2];
    
    # use regexp to untaint username
    my ( $safeUsername ) = 
        ( $username =~ /(\w+)$/ );
    
    my $userDirName = "$dataDirectory/users/$safeUsername";

   
    mkdir( "$userDirName", oct( "0777" ) );
    mkdir( "$userDirName/text", oct( "0777" ) );
    mkdir( "$userDirName/text/chunks", oct( "0777" ) );
    mkdir( "$userDirName/text/documents", oct( "0777" ) );
    
    mkdir( "$userDirName/purchasedRegions", oct( "0777" ) );
    mkdir( "$userDirName/quoteClipboard", oct( "0777" ) );

    writeFile( "$userDirName/password", 
               "$password" );
    
    writeFile( "$userDirName/balance", 
               "$startBalance" );

    print "userAdded\n";
    
}



# end of package
1;
