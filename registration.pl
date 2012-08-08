#! /usr/bin/perl -w
BEGIN {require('libpath.pl')}
use strict;
use VVNetwork qw(connectDatabase hashPassword);
use VVCGIGenerator qw(indexURL);
use VVUsers qw(writeUserToDataBase);
use VVFileOpreation qw(templateWithName);
use CGI;
use Data::FormValidator;
use CGI::Session;

my $q = CGI->new;
$q->charset('utf-8');
my $temp = templateWithName('registration');

my $valid = 0;

if ($q->param()) {  #If the form is submitted...
    #Check if all required forms are filled
    my %profile = (required => [qw(id pwd pwd_check email)]);
    my $missingCheckResults = Data::FormValidator->check($q,\%profile);
    if ($missingCheckResults->has_missing()) {
        foreach my $field ($missingCheckResults->missing())
        {
            if ($field eq 'id') {
                $temp->param(idTextFieldErrMsg => "入力必須項目です。");
            }
            elsif ($field eq 'pwd') {
                $temp->param(pwdTextFieldErrMsg => "入力必須項目です。");
            }
            elsif ($field eq 'pwd_check') {
                $temp->param(pwdAgainTextFieldErrMsg => "入力必須項目です。");
            }
            elsif ($field eq 'email') {
                $temp->param(mailTextFieldErrMsg => "入力必須項目です。");
            }
        }
    }
    else {
        #All forms are filled. Now check if they are valid or not.
        my %constraints = (
            id => qr/^[a-zA-Z][a-zA-Z1-9_-]{3,30}$/,
            email => qr/^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/,
            pwd =>  qr/^[A-Za-z0-9`~!@#%^&*()_+-=;:?,.]{6,31}$/,
            );
        my %constraintsProfile = (  
            required => [qw(id pwd pwd_check email)],
            constraint_methods => \%constraints
            );
        my $invalidCheckResults = Data::FormValidator->check($q,\%constraintsProfile);

        #There is invalid field...
        if ($invalidCheckResults->has_invalid()) {
            foreach my $field ($invalidCheckResults->invalid()) {
                if ($field eq 'id') {
                    $temp->param(idTextFieldErrMsg => "入力されが正しくないようです");
                }
                elsif ($field eq 'pwd') {
                    $temp->param(pwdTextFieldErrMsg => "入力されが正しくないようです");
                }
                elsif ($field eq 'email') {
                    $temp->param(mailTextFieldErrMsg => "入力されが正しくないようです");
                }
            }
        }
        else {
            # All fields are valid, Check if two passwords meet
            if ($q->param('pwd_check') eq $q->param('pwd')) {
                #every thing seems OK
                $valid = 1;
                } else {
                   $temp->param(pwdAgainTextFieldErrMsg => "パスワードが一致しません。もう一度入力してください。");
               } 
           }
       }
   }

#Fill Template
$temp->param(registraionParam($q));

# If Everything goes fine, the registration is done. Write user's data to the database.
if ($valid eq 1) {
    # Inserting the user to database. If insert suc, userID is returned. Otherwise, undef
    my $dbh = connectDatabase();
    my $userID = writeUserToDataBase($dbh,$q->param('id'),$q->param('pwd'),$q->param('email'));
    $dbh->disconnect();

    if ($userID) {
        #If the code runs to here. It means register Suc and databse insert done!
        #Get New Session for the user, and print the page.
        my $session = CGI::Session->new;
        $session->param('userID',$userID);
        print $session->header(-charset=>'utf-8');
        print $q->start_html(-title=>"会員登録|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
        require('header.pl');
        #Everything goes OK. Now redirect back to index page
        my $url = indexURL;
        my $t = 2; # time until redirect activates
        print "登録OK! <META HTTP-EQUIV=refresh CONTENT=\"$t;URL=$url\">\n";
    }
    else {
        # Something gose wrong while inserting. It cannot be a database down(will die in the 'writeUserToDataBase'.)
        # It could be the same username already exists.
        print $q->header(-charset=>'utf-8');
        print $q->start_html(-title=>"会員登録|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
        require('header.pl');
        $temp->param(idTextFieldErrMsg => "その会員IDを持つ会員が既に存在します。別の名前を入力してください。");
        print $temp->output;
        require('footer.pl');
    }

}
else {
    # Did not pass the validation. Ask the user to check the form.
    print $q->header(-charset=>'utf-8');
    print $q->start_html(-title=>"会員登録|OneV's Denの掲示板",
                     -style=>{'src'=>VVNetwork::CSS},
                    );
    require('header.pl');
    print $temp->output;
    require('footer.pl');
}

sub registraionParam {
    my $q = shift @_;
    my %param = (
        idTextField => $q->textfield({-name => 'id'}),
        pwdTextField => $q->password_field({-name => 'pwd', -override =>1, -value => ''}),
        pwdAgainTextField => $q->password_field({-name => 'pwd_check', -override =>1, -value => ''}),
        mailTextField => $q->textfield({-name => 'email'}),
        formStart => $q->start_form({-method => "POST"}),
        formEnd => $q->end_form(),
        submit => $q->submit({-name => "submit",-class => "submit",-value => "会員登録"}),
        );
}