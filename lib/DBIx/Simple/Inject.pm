package DBIx::Simple::Inject;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.01';
use parent 'DBI';

package DBIx::Simple::Inject::db;
use strict;
our @ISA = qw(DBI::db);

use Class::Load;
use DBIx::Simple;
use Scalar::Util qw/weaken/;

sub simple {
    my ($dbh) = @_;
    $dbh->{private_dbixsimple} ||= do {
        my $dbis = DBIx::Simple->connect($dbh);
        weaken($dbis->{dbh});
        
        for my $k (keys %{ $dbh->{private_dbixsimple_props} || {} }) {
            my $v = $dbh->{private_dbixsimple_props}{$k};
            # lvalue method
            $dbis->$k = ref $v eq 'CODE' ? $v->($dbh)
                      : $k eq 'abstract' ? _abstract($dbis->{dbh}, $v) : $v;
        }
        
        $dbis;
    };
}

sub _abstract {
    my ($dbh, $class) = @_;
    Class::Load::load_class($class);
    if ($class eq 'SQL::Abstract') {
        $class->new();
    } elsif ($class eq 'SQL::Abstract::Limit') {
        $class->new(limit_dialect => $dbh);
    } elsif ($class eq 'SQL::Maker') {
        $class->new(driver => $dbh->{Driver});
    } else {
        $class->new($dbh); # fallback
    }
}

{
    no strict 'refs';
    for my $method (
        qw(
            error
            query
            begin
            disconnect
            select insert update delete
            iquery
        ),
        # unnecessary begin_work(), commit(), rollback(), func() and last_insert_id()
        # there are just alias for DBI::db::*
    ) {
        *$method = sub { shift->simple->$method(@_) };
    }
    
    for my $method (
        qw(
            keep_statements
            lc_columns
            result_class
            abstract
        ),
    ) {
        *$method = sub {
            my ($self, $val) = @_;
            if ($val) {
                $self->simple->$method = $val;
            } else {
                $self->simple->$method;
            }
        };
    }
}

package DBIx::Simple::Inject::st;
our @ISA = qw(DBI::st);

1;

__END__

=encoding utf-8

=head1 NAME

DBIx::Simple::Inject - Inject DBIx::Simple into DBI

=head1 SYNOPSIS

  use DBI;
  my $db = DBI->connect(
      'dbi:SQLite:dbname=:memory:', '', '', {
          RootClass          => 'DBIx::Simple::Inject',
          RaiseError         => 1,
          PrintError         => 0,
          ShowErrorStatement => 1,
      }
  );
  
  $db->query('select * from foo where id = ?', 123);
  $db->insert(foo => {
      name => "John",
  });

=head1 DESCRIPTION

DBIx::Simple::Inject is bla bla.

I wrote this to use DBIx::Simple with DBIx::Connector.

=head1 SEE ALSO

L<DBIx::Simple>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
