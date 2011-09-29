package DBIx::Simple::Inject;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.01';
use parent 'DBI';

package DBIx::Simple::Inject::db;
use strict;
our @ISA = qw(DBI::db);
use DBIx::Simple;

sub simple {
    my ($dbh) = @_;
    $dbh->{private_dbixsimple} ||= DBIx::Simple->connect($dbh);
}

{
    no strict 'refs';
    for my $method (
        qw(
            query
            begin
            disconnect
            select insert update delete
            iquery
        ),
        # unnecessary begin_work(), commit(), rollback(), func() and last_insert_id()
        # there are just alias
    ) {
        *$method = sub { shift->simple->$method(@_) };
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