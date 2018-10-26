#!/usr/bin/perl

use strict;
use warnings;

use Const::Fast;
use English qw(-no_match_vars);
use File::Basename qw{basename};
use Data::Dumper;
use Carp qw(croak);

use Prisoners::Object;
use Prisoners::Session;

const my %_ACTIONS => (
    start => \&action_start,
    usage => \&print_usage,
    join  => \&action_join,
);

const my $_DSN       => 'DBI:mysql:database=prisoners;host=localhost;port=3306';
const my $_DB_USER   => 'koldrayn';
const my $_DB_PASSWD => 'qwerty';

sub main {
    if ( !scalar @ARGV ) {
        print_usage('Nothing to do...');
        exit 0;
    }

    my $action = shift @ARGV // '';

    if ( !exists $_ACTIONS{$action} ) {
        print_usage("Unknown action '$action'");
        exit 1;
    }
    else {
        my $result = $_ACTIONS{$action}->();
        exit( $result // 0 );
    }
}

sub action_start {
    _init();

    my $session = Prisoners::Session->new();

    my $player_name = shift @ARGV // '';
    $session->add_player($player_name);

    return;
}

sub action_join {
    my $session_id = shift @ARGV // '';

    if ( !$session_id ) {
        croak "session_is is required!";
    }

    _init();

    my $session = Prisoners::Session->new( {
            id => $session_id,
        }
    );

    my $player_name = shift @ARGV // '';
    $session->join_player($player_name);

    return;
}

sub _init {
    # make sure dbh is initialized
    my $done = eval { Prisoners::Object->dbh_instance( $_DSN, $_DB_USER, $_DB_PASSWD ); };
    if ( !$done || $EVAL_ERROR ) {
        croak sprintf "Failed to initialize dbh: %s", $EVAL_ERROR // '<unknown error>';
    }

    return;
}

sub print_usage {
    my $message = shift;

    if ($message) {
        print "$message\n";
    }

    my $name = basename($PROGRAM_NAME);

    my $usage = <<"EOF";

$name --  game based on Prisoner's dillemma

Usage: $name <action>

<action>:

    usage                 Print this message.

    start [<username>]    Start new game session.

    join <session_id>     Join already started session.

EOF

    print $usage;

    return;
} ## end sub print_usage

main();
