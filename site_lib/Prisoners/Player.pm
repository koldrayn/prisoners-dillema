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

# local = 'Y' - the player is being originally added from current process
# local = 'N' - the player is the second prisoner, that is interigated in
#               other 'room'
has 'local' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    my $session = $args->{session};
    if ( !$session ) {
        die "Cannot create new player without existing session!\n";
    }

    if ( $args->{local} ) {
        if ( ( $args->{name} // '' ) eq '' ) {
            $args->{name} = sprintf(
                'Player_%s_%s',
                $session->id(),
                ( @{ $session->players() // [] } + 1 ),
            );
        }

        $class->_db_do( 'AddPlayer', [ $session->{id}, $args->{name} ] );

        $args->{id} = $class->_db_last_insert_id();
    }
    else {
        # try to connect existing user by name

        if ( !$args->{name} ) {
            die "Cannot find player without name!\n";
        }

        # TODO connect user to existing session
        croak "Not implemented yet";
    }

    return $class->$orig($args);
};

# just the place for keeping MySQL queries

const my %_QUERIES => (
    AddPlayer => q/
        INSERT INTO Players
                    (i_player,
                     i_session,
                     name)
             VALUES (0,
                     ?,
                     ?)
    /,
    # GetUserByName => q/
    #     SELECT i_player
    #       FROM Players
    #      WHERE i_session = :i_session
    #        AND name = :name
    # /,
);

sub _queries { return \%_QUERIES; }

1;
