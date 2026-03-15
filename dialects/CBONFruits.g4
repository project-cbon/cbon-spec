grammar CBONFruits;
import CBON;

definition
    : enum_def
    | regexp_def
    | accept_def
    | class_def
    | range_def
    | alias_def
    | define_def
    | entries_def
    ;

/** alias array<Person> as People; */
alias_def
    : decorators ALIAS union_type AS TYPE_ID SEMI
    ;

/** define Nothing {} as Null; */
define_def
    : decorators DEFINE value AS TYPE_ID SEMI
    ;

/** entries KeyValuePair<string, string>; */
entries_def
    : decorators ENTRIES TYPE_ID LANGLE union_type (COMMA union_type)* RANGLE SEMI
    ;

/** prefix code "$"; */
initial_def
    : decorators (CONST | DEFAULT) ID value SEMI
    : decorators (PREFIX | SUFFIX) ID value SEMI
    : decorators (PREPEND | APPEND) ID LBRACE value (COMMA value)* RBRACE SEMI
    ;

/** type-variables T */
union_type
    : type_atom (PIPE type_atom)*
    | TYPE_VARIABLES type_atom
    ;

/** type-reference Person */
value
    : scalar
    | collection
    | enum_value_ref
    | TYPE_REFERENCE union_type
    ;

// Keywords
AS      : 'as' ;
ALIAS   : 'alias' ;
DEFINE  : 'define' ;
ENTRIES : 'entries' ;
PREFIX  : 'prefix' ;
SUFFIX  : 'suffix' ;
PREPEND : 'prepend' ;
APPEND  : 'append' ;

TYPE_VARIABLES : 'type-variables' ;
TYPE_REFERENCE : 'type-reference' ;
