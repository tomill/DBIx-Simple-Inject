
# see https://github.com/tomi-ru/DBIx-Simple-Inject/issues/1

use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    DBI
    DBD::SQLite
    Test::Exception
    DBIx::Connector
);

use Test::Exception;
use DBIx::Simple::Inject;
use DBIx::Connector;

# The base case, no DBIx::Simple::Inject
{
    my $dbixc = DBIx::Connector->new('dbi:SQLite:dbname=foo.db','yourname');
    my $dbh = $dbixc->dbh;

    # Reality check connection
    note $dbh->selectrow_array("SELECT 'foo'");

    lives_ok( sub {
        $dbh->disconnect;
        note $dbixc->dbh->selectrow_array("SELECT 'foo'")
    }, "Without DBIx::Simple::Inject: auto-reconnect after dbh->disconnect");

    lives_ok( sub {
        $dbixc->disconnect;
        note $dbixc->dbh->selectrow_array("SELECT 'foo'")
    }, "Without DBIx::Simple::Inject: auto-reconnect after dbixc->disconnect");
}

# With DBIx::Simple::Inject
{
    my $dbixc = DBIx::Connector->new('dbi:SQLite:dbname=foo.db','yourname', undef, {
        RootClass => 'DBIx::Simple::Inject',
    });
    my $dbh = $dbixc->dbh;

    # Reality check connection
    note $dbh->selectrow_array("SELECT 'foo'");

    lives_ok( sub {
        $dbh->disconnect;
        note $dbixc->dbh->selectrow_array("SELECT 'foo'")
    }, "WITH DBIx::Simple::Inject: auto-reconnect after dbh->disconnect");

    # Currently fails here.
    lives_ok( sub {
        $dbixc->disconnect;
        note $dbixc->dbh->selectrow_array("SELECT 'foo'")
    }, "WITH DBIx::Simple::Inject: auto-reconnect after dbixc->disconnect");
}

done_testing();
