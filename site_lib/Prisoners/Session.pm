package Prisoners::Session;

use strict;
use warnings;

use Carp qw(croak);
use Const::Fast;

use Prisoners::Player;

use Mouse;
extends 'Prisoners::Object';

has 'id' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

# at first stages there should be no more than two players
# but one day 'spectators' might appear
has 'players' => (
    is      => 'rw',
    isa     => 'Maybe[ArrayRef[Prisoners::Player]]',
    default => sub { [] },
);

# shows if the session was originally created in this process, or we
# joined already existing one
has 'originated' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    if ( !$args->{id} ) {
        # new session
        $class->_db_do('CreateNewSession');

        $args->{id} = $class->_db_last_insert_id();
    }
    else {
        # existing session

        my $sessions = $class->_db_fetchall( 'LoadSession', [ $args->{id} ] );

        if ( !scalar @{ $sessions // [] } ) {
            croak sprintf "There is no session with id='%s'!\n", $args->{id};
        }
        # else: the session exists and no more more than one unless db is really
        # messed up, but let's be forgiving

        $args->{originated} = 0;
    }

    return $class->$orig($args);
};

sub BUILD {
    my ($self) = @_;

    if ( $self->originated() ) {
        $self->log(
            "New game session added. New players can join using session_id=%s\n",
            $self->id()
        );
    }
    else {
        $self->log( "Session with id=%s is found. Checking players...\n", $self->id() );
        # find all external players of the session
        $self->reload_players();

        if ( !scalar @{ $self->players() } ) {
            croak "Session without players\n";
        }
    }

    return;
} ## end sub BUILD

sub add_player {
    my ( $self, $player_name ) = @_;

    my $player = Prisoners::Player->new( {
            session    => $self,
            name       => $player_name,
            originator => 1,              # first player in session
        }
    );

    $self->log( "Player %s was added to session %s\n", $player->name(), $self->id() );

    push @{ $self->players() }, $player;
    return;
}

sub join_player {
    my ( $self, $player_name ) = @_;

    if ( scalar @{ $self->players() } >= 2 ) {
        croak sprintf "It's already enough players in session %s", $self->id();
    }

    my $player = Prisoners::Player->new( {
            session    => $self,
            name       => $player_name,
            originator => 0,              # joining to existing session
        }
    );

    $self->log( "Player %s joined to session %s\n", $player->name(), $self->id() );

    push @{ $self->players() }, $player;
    return;
}

sub reload_players {
    my ($self) = @_;

    @{ $self->players() } = Prisoners::Player->players_by_session(
        $self->id(),
    );

    return;
}

# just the place for keeping MySQL queries
const my %_QUERIES => (

    # 0 - for auto-increment, other params has defaults
    CreateNewSession => q/
        INSERT INTO Active_Sessions
                    (i_session)
             VALUES (0)
    /,
    LoadSession => q/
        SELECT started_at,
               last_updated,
               step
          FROM Active_Sessions
         WHERE i_session = ?
    /,
);

sub _queries { return \%_QUERIES; }

1;
