package Prisoners::Player;

use strict;
use warnings;

use Carp qw(croak);
use Const::Fast;

use Mouse;
extends 'Prisoners::Object';

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# originator = 'Y' - the player is being originally added from current process
# originator = 'N' - the player is the second prisoner, that is interigated in
#               other 'room'
has 'originator' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    if ( $args->{i_session} ) {
        # no need in fetching anything from db
        return $class->$orig($args);
    }

    my $session = $args->{session};
    if ( !$session ) {
        die "Cannot create new player without existing session!\n";
    }

    if ( ( $args->{name} // '' ) eq '' ) {
        $args->{name} = sprintf(
            'Player_%s_%s',
            $session->id(),
            ( @{ $session->players() // [] } + 1 ),
        );
    }

    $class->_db_do(
        'AddPlayer',
        [
            $session->{id},
            $args->{name},
            $args->{originator} ? 'Y' : 'N',
        ]
    );

    $args->{id} = $class->_db_last_insert_id();

    return $class->$orig($args);
};

## class methods

sub players_by_session {
    my ( $class, $session_id ) = @_;

    if ( !$session_id ) {
        croak "Session id is required!";
    }

    my $players_data = $class->_db_fetchall( 'GetPlayersBySession', [$session_id] );

    my @players = ();
    foreach my $p ( @{ $players_data // [] } ) {
        my $originator = ( $p->{originator} eq 'N' ) ? 0 : 1;

        push @players, __PACKAGE__->new( {
                id         => $p->{i_player},
                i_session  => $p->{i_session},
                name       => $p->{name},
                originator => $originator,
            }
        );

        $class->log(
            "Found player '%s'%s\n",
            $p->{name},
            $originator ? ' (originator)' : '',
        );
    }

    return @players;
} ## end sub players_by_session

## queries

# just the place for keeping MySQL queries
const my %_QUERIES => (
    AddPlayer => q/
        INSERT INTO Players
                    (i_player,
                     i_session,
                     name,
                     originator)
             VALUES (0,
                     ?,
                     ?,
                     ?)
    /,
    GetPlayersBySession => q/
        SELECT i_player,
               name,
               i_session,
               originator
          FROM Players
         WHERE i_session = ?
    /,
);

sub _queries { return \%_QUERIES; }

1;
