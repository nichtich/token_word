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
# 2003-January-8   Jason Rohrer
# Added function for transfering tokens.
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
        
        return 1;
    }
    else {
        return 0;
    }
}



##
# Checks a user login and password.
#
# @param0 the username.
# @param1 the password.
#
# @return 1 if the login and password are correct, 0 otherwise.
##
sub checkLogin {
    ( my $user, my $pass ) = @_;
    
    my $userDirName = "$dataDirectory/users/$user";
    
    if( not -e $userDirName ) {
        # user doesn't exist 
        return 0;
    }
    else {
        my $truePass = readFileValue( "$userDirName/password" );
        
        if( $truePass eq $pass ) {
            return 1;
        }
        else {
            return 0;
        }
    }
}



##
# Transfers tokens between users.
#
# @param0 the source user.
# @param1 the destination user.
# @param2 the number of tokens to transfer.
#
# @return 1 if transfer succeeded, or 0 otherwise.
#
# Example:
# my $transferSuccess = transferTokens( "jb65", "jjd4", 1544 );
##
sub transferTokens {
    ( my $srcUser, my $destUser, my $number ) = @_;
    
    my $withdrawSuccess = withdrawTokens( $srcUser, $number );

    if( not $withdrawSuccess ) {
        return 0;
    }
    else {
        depositTokens( $destUser, $number );
        return 1;
    }
}



##
# Adds tokens to a user's balance.
#
# @param0 the user.
# @param1 the number of tokens to add.
#
# Example:
# depositTokens( "jb65", 1544 );
##
sub depositTokens {
    ( my $user, my $number ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $balance = readFileValue( "$userDirName/balance" );

    $balance += $number;

    writeFile( "$userDirName/balance", $balance );
}



##
# Removes tokens from a user's balance.
#
# @param0 the user.
# @param1 the number of tokens to remove.
#
# Example:
# my $success = withdrawTokens( "jb65", 1544 );
##
sub withdrawTokens {
    ( my $user, my $number ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $balance = readFileValue( "$userDirName/balance" );

    $balance -= $number;

    writeFile( "$userDirName/balance", $balance );

    return 1;
}



##
# Gets a user's token balance.
#
# @param0 the user.
#
# Example:
# my $balance = getBalance( "jb65" );
##
sub getBalance {
    ( my $user ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $balance = readFileValue( "$userDirName/balance" );

    return $balance;
}



# end of package
1;
