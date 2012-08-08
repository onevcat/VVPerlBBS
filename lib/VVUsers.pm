#!/usr/bin/perl
package  VVUsers;
require  Exporter;
use DBI;
use DBD::mysql;
use Digest::MD5 qw(md5_hex);

@ISA=qw(Exporter);
@EXPORT=qw(changePassword userExist checkLoginInfo canDelete writeUserToDataBase);

use constant {
    USER => 1,
    DATABASE_ERROR => 100,
    NO_USER => 200,
    ADMIN => 999,
};

sub changePassword {
    my ($dbh, $userID, $newPassword) = @_;
    $dbh->do("UPDATE `users` SET `password`=? WHERE `userID`=?;",undef,hashPassword($newPassword),$userID)
            or die "Failed to insert row: ".$dbh->errstr;
}

sub userExist {
    my ($dbh,$userID) = @_;
    my $check = $dbh->prepare("SELECT userID FROM users WHERE users.userID=?");
    $check->execute( $userID ) or die $dbh->errstr;
    return ($check->rows == 1);
}

sub canDelete {
    my ($userID, $postUser, $admin) = @_;
    return ($userID && ($userID eq $postUser)) || $admin;
}

sub checkLoginInfo {
    my ($userID,$passwd,$dbh,$requestAdmin) = @_;
    my $fetch = $dbh->prepare("SELECT password,admin FROM users WHERE users.userID=?");
    $fetch->execute( $userID ) or die $dbh->errstr;
    return DATABASE_ERROR if ($fetch->rows > 1); #More than 1 user. Database must be wrong...
    return NO_USER if ($fetch->rows == 0); #No user
    my @userInfo = $fetch->fetchrow_array;
    my $passwdInMD5 = hashPassword($passwd);

    return USER if (($passwdInMD5 eq $userInfo[0]) && (!$requestAdmin || $userInfo[1]==0));
    return ADMIN if (($passwdInMD5 eq $userInfo[0]) && ($requestAdmin && $userInfo[1]==1)); #The user is administrator.
    return undef;
}

sub hashPassword {
    my $origin = shift @_;
    my $str = '{Q3%H]67Yz3<REg<%t';
    return md5_hex($origin,'$str');
}

sub writeUserToDataBase{
    my ($dbh, $userID, $passwd, $email) = @_;
    my $check = $dbh->prepare("SELECT userID FROM users WHERE users.userID=?");
    $check->execute( $userID ) or die $dbh->errstr;
    return undef unless ($check->rows == 0);

    my $passwdInMD5 = hashPassword($passwd);
    my $registerTime = time();

    $dbh->do("INSERT INTO users (userID, email, password, registrationTime) 
        VALUES (?, ?, ?, ?)",undef,$userID,$email,$passwdInMD5,$registerTime)
    or die "Failed to insert row: ".$dbh->errstr;
    
    return $userID;
}