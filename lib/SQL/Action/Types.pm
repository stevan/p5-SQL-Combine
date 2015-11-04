package SQL::Action::Types;
use Moose::Util::TypeConstraints;

class_type 'SQL::Composer::Select';
class_type 'SQL::Composer::Insert';
class_type 'SQL::Composer::Update';
class_type 'SQL::Composer::Delete';

no Moose::Util::TypeConstraints;

1;
