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
# 2003-January-13   Jason Rohrer
# Fixed withdraw function.
#
# 2003-January-16   Jason Rohrer
# Added support for trial balances.
#


use tokenWord::common;



##
# Adds a user.
#
# @param0 the username.
# @param1 the user's password.
# @param2 the user's paypal email.
# @param3 the user's starting token balance, deposited into the
#   user's trail balance.
#
# @return 1 if user created successfully, or 0 otherwise
#    (for example, 0 is returned if the user already exists).
#
# Example:
# my $userCreated = addUser( "jb65", "letMeIn", "jb65@server.com", 15000 );
##
sub addUser {
    my $username = $_[0];
    my $password = $_[1];
    my $paypalEmail = $_[2];
    my $startBalance = $_[3];

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
    
        # user starts out with 0 "real" tokens
        writeFile( "$userDirName/balance", 
                   "0" );

        writeFile( "$userDirName/trialBalance", 
                   "$startBalance" );

        writeFile( "$userDirName/paypalEmail", 
                   "$paypalEmail" );

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
# Uses payer's trial tokens as much as possible.
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
        
    ( my $sucess, my $usedTrial, my $usedReal ) =
        withdrawBothTokens( $srcUser, $number );

    if( $sucess ) {
        depositTokens( $destUser, $usedReal );
        depositTrialTokens( $destUser, $usedTrial );
        return 1;
    }
    else {
        return 0;
    }

}



##
# Adds tokens to a user's "real" balance.
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
# Removes tokens from a user's "real" balance.
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

    if( $balance >= $number ) {
        $balance -= $number;
        
        writeFile( "$userDirName/balance", $balance );

        return 1;
    }
    else {
        return 0;
    }
}




##
# Adds tokens to a user's trial balance.
#
# @param0 the user.
# @param1 the number of tokens to add.
#
# Example:
# depositTrialTokens( "jb65", 1544 );
##
sub depositTrialTokens {
    ( my $user, my $number ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $balance = readFileValue( "$userDirName/trialBalance" );

    $balance += $number;

    writeFile( "$userDirName/trialBalance", $balance );
}



##
# Removes tokens from a user's trial balance.
#
# @param0 the user.
# @param1 the number of tokens to remove.
#
# Example:
# my $success = withdrawTrialTokens( "jb65", 1544 );
##
sub withdrawTrialTokens {
    ( my $user, my $number ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $balance = readFileValue( "$userDirName/trialBalance" );

    if( $balance >= $number ) {
        $balance -= $number;
        
        writeFile( "$userDirName/trialBalance", $balance );

        return 1;
    }
    else {
        return 0;
    }
}



##
# Removes tokens from a user's trial balance and real balance as
# necessary to fill the withdrawl request, favoring the trial balance.
#
# @param0 the user.
# @param1 the number of tokens to remove.
#
# Example:
# ( my $success, my $trialWithdraw, my $realWithdraw ) 
#     = withdrawTrialTokens( "jb65", 1544 );
##
sub withdrawBothTokens {
    ( my $user, my $number ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $trialBalance = readFileValue( "$userDirName/trialBalance" );
    my $realBalance = readFileValue( "$userDirName/balance" );

    if( $trialBalance >= $number ) {
        $trialBalance -= $number;
        
        writeFile( "$userDirName/trialBalance", $trialBalance );

        return ( 1, $number, 0 );
    }
    elsif( $trialBalance + $realBalance >= $number ) {
        my $usedTrialTokens = $trialBalance;
        my $usedRealTokens = $number - $trialBalance;

        $trialBalance -= $usedTrialTokens;
        $realBalance -= $usedRealTokens;
        
        writeFile( "$userDirName/trialBalance", $trialBalance );
        writeFile( "$userDirName/balance", $realBalance );

        

        return ( 1, $usedTrialTokens, $usedRealTokens );
    }
    else {
        # not enough, combined
        return ( 0, 0, 0 );
    }
}



##
# Gets a user's "real" token balance.
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



##
# Gets a user's trial token balance.
#
# @param0 the user.
#
# Example:
# my $balance = getTrialBalance( "jb65" );
##
sub getTrialBalance {
    ( my $user ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $balance = readFileValue( "$userDirName/trialBalance" );

    return $balance;
}



##
# Gets a user's paypal email.
#
# @param0 the user.
#
# Example:
# my $email = getPaypalEmail( "jb65" );
##
sub getPaypalEmail {
    ( my $user ) = @_;

    my $userDirName = "$dataDirectory/users/$user";
    
    my $email = readFileValue( "$userDirName/paypalEmail" );

    return $email;
}



# end of package
1;
