package tokenWord::userManager;

#
# Modification History
#
# 2003-January-6   Jason Rohrer
# Created.
#
# 2003-January-7   Jason Rohrer
# Changed to return a success flag on user add.
#


use tokenWord::common;



##
# Adds a user.
#
# @param0 the username.
# @param1 the user's password.
# @param2 the user's starting token balance.
#
# @return 1 if user created successfully, or 0 otherwise
#    (for example, 0 is returned if the user already exists).
#
# Example:
# my $userCreated = addUser( "jb65", "letMeIn", 15000 );
##
sub addUser {
    my $username = $_[0];
    my $password = $_[1];
    my $startBalance = $_[2];

    my $userDirName = "$dataDirectory/users/$username";
    
    if( not -e $userDirName ) {
   
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

        writeFile( "$userDirName/text/chunks/nextFreeID", 
                   "0" );

        writeFile( "$userDirName/text/documents/nextFreeID", 
                   "0" );

        writeFile( "$userDirName/quoteClipboard/nextFreeID",
                   "0" );

        print "userAdded\n";
        
        return 1;
    }
    else {
        return 0;
    }
}



# end of package
1;
