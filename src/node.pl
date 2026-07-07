% node.pl — Node representation
%
% A node is an ordinary Prolog term.  There are two shapes:
%
%   animal(Name)            — a leaf: the program's guess (Name is an atom)
%   question(Text, Yes, No) — an internal node: a yes/no question whose
%                             Yes / No children are themselves nodes
%
% This is where Prolog earns its keep over the Forth version.  The Forth build
% hand-managed a five-cell heap block per node (NODE-TYPE, NODE-TEXT, NODE-TLEN,
% NODE-YES, NODE-NO), copied strings onto the heap, and needed free-node to
% release them.  Here a node is just a term:
%
%   * construction is unification — no ALLOCATE, no copy-str;
%   * strings are immutable atoms, structurally shared for free;
%   * there is no free-node — unreachable terms are reclaimed by the GC.
%
% Every predicate below is a thin, declarative accessor over that term shape.

% is_leaf(?Node) — true when Node is an animal (leaf) node.
is_leaf(animal(_)).

% is_question(?Node) — true when Node is a question (internal) node.
is_question(question(_, _, _)).

% make_animal(+Name, -Node) — a leaf node for the given animal name.
make_animal(Name, animal(Name)).

% make_question(+Text, +Yes, +No, -Node) — an internal question node.
make_question(Text, Yes, No, question(Text, Yes, No)).

% node_text(+Node, -Text) — the node's text (animal name or question text).
node_text(animal(Name),      Name).
node_text(question(Text, _, _), Text).

% node_yes(+QuestionNode, -Yes) — the yes-child of a question node.
node_yes(question(_, Yes, _), Yes).

% node_no(+QuestionNode, -No) — the no-child of a question node.
node_no(question(_, _, No), No).
