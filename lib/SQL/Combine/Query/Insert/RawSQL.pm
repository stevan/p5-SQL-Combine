package SQL::Combine::Query::Insert::RawSQL;
use Moose;

with 'SQL::Combine::Query';

has 'sql' => (
    reader   => 'to_sql',
    isa      => 'Str',
    required => 1,
);

has 'bind' => (
    traits   => [ 'Array' ],
    is       => 'bare',
    isa      => 'ArrayRef',
    required => 1,
    handles  => { 'to_bind' => 'elements' }
);

sub is_idempotent { 0 }

has '+id' => ( required => 1 ); # make this required now ...
sub locate_id { return } # this is never going to get called ...

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=cut
