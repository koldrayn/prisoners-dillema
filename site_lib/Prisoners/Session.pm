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

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    $class->_db_do('CreateNewSession');

    $args->{id} = $class->_db_last_insert_id();

    return $class->$orig($args);
};

sub BUILD {
    my ($self) = @_;

    $self->log(
        "New game session added. New players can join using session_id=%s\n",
        $self->id()
    );

    return;
}

sub add_player {
    my ( $self, $player_name ) = @_;

    my $player = Prisoners::Player->new( {
            session => $self,
            name    => $player_name,
            local   => 1,
        }
    );

    $self->log( "Player %s was added to session %s\n", $player->name(), $self->id() );

    push @{ $self->players() }, $player;
    return;
}

# just the place for keeping MySQL queries
const my %_QUERIES => (
    CreateNewSession => q/
        INSERT INTO Active_Sessions
                    (i_session)
             VALUES (0)
    /,
    # UpdateSession => q/
    #     UPDATE Active_Sessions
    #        SET step = step + 1,
    #            last_updated = NOW()
    #      WHERE i_session = :i_session
    # /,
);

sub _queries { return \%_QUERIES; }

1;
