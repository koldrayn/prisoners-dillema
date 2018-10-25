package Prisoners::Object;

use strict;
use warnings;

use Mouse;
use DBI;
use File::Slurp;
use FindBin qw($Bin);
use Carp qw(croak);

## no critic (ProhibitBuiltinHomonyms)
## no critic (RequireArgUnpacking)
sub log {
    my $self = shift;

    return if !scalar @_;    # nothing to log

    ( scalar @_ > 1 ) ? ( printf @_ ) : ( print @_ );
    return;
}
## use critic

sub dbh_instance {
    my ( $class, $dsn, $user, $password ) = @_;

    # make sure there is only ony connection
    CORE::state $dbh = DBI->connect(
        $dsn,
        $user,
        $password,
        {
            RaiseError => 1,
            PrintError => 1,
        },
    );

    return $dbh;
}

sub _db_last_insert_id {
    my ($self) = @_;

    # from perl DBI:
    # $rv = $dbh->last_insert_id($catalog, $schema, $table, $field);
    # For some drivers the $catalog, $schema, $table, and $field parameters
    # are required, for others they are ignored (e.g., mysql).
    return $self->dbh_instance()->last_insert_id( undef, undef, undef, undef );
}

sub _db_do {
    my ( $self, $query_name, $params ) = @_;

    my $queries = $self->_queries();

    if ( !$query_name || !exists $queries->{$query_name} ) {
        croak sprintf "Unknown query '%s' for '%s'", $query_name // '<unknown>', ref $self;
    }

    return $self->dbh_instance()->do(
        $queries->{$query_name},
        undef,
        @{ $params // [] }
    );
}

# sub _db_fetchall_arrayref {
#     my ($self, $query_name, $params) = @_;
#
#     my $queries = $self->_queries();
#
#     if (!$query_name || !exists $queries->{$query_name}) {
#         croak sprintf "Unknown query '%s' for '%s'", $query_name // '<unknown>', ref $self;
#     }
#
#     my $sth = $self->dbh_instance()->prepare($queries->{$query_name});
#     $sth->execute($params);
#
#     return $sth->fetchall_arrayref();
# }

# place for common queries (in case there would be any)
sub _queries {
    return {};
}

1;
