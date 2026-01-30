grammar CBON;

/* ==========================================
   Parser Rules
   ========================================== */

/** エントリポイント
 * スキーマ定義の羅列、ルート宣言、またはデータ値を許容
 */
start
    : definition* schema_root+ value? EOF
    | value EOF
    ;

/* --- Schema Definition Rules --- */

definition
    : enum_def
    | regexp_def
    | accept_def
    | class_def
    | range_def
    ;

/** enum ProductType { Type1, Type2 } */
enum_def
    : DOC_COMMENT? ENUM TYPE_ID LBRACE enum_member (COMMA enum_member)* COMMA? RBRACE SEMI?
    ;

enum_member
    : DOC_COMMENT? TYPE_ID
    ;

/** regexp ProductCode /^[A-Z]{3}-[0-9]{5}$/; */
regexp_def
    : DOC_COMMENT? REGEXP TYPE_ID REGEXP_LITERAL SEMI
    ;

/** accept PaymentMethod { "CreditCard", "PayPal", "BankTransfer" } */
accept_def
    : DOC_COMMENT? ACCEPT TYPE_ID LBRACE value (COMMA value)* COMMA? RBRACE SEMI?
    ;

/** class User extends BaseEntity { ... } */
class_def
    : DOC_COMMENT? CLASS type_reference (EXTENDS type_reference)? LBRACE field_def* (group_def | initial_def)* RBRACE SEMI?
    ;

/** required string name; */
field_def
    : DOC_COMMENT? (REQUIRED | OPTIONAL | CHOOSE) union_type ID SEMI
    ;

/** exclusive is_drop_off, signature_name; */
group_def
    : DOC_COMMENT? (ONEOF | EXCLUSIVE) ID (COMMA ID)+ SEMI
    ;

/** const type "User"; */
initial_def
    : DOC_COMMENT? (CONST | DEFAULT) ID value SEMI
    ;

/** range OpenHours<time> { [09:00, 12:00), [13:00, 18:00) }; */
range_def
    : DOC_COMMENT? RANGE type_reference LBRACE intervals RBRACE SEMI?
    ;

intervals
    : interval (COMMA interval)* COMMA?
    ;

interval
    : ((LPAREN | LBRACK) scalar COMMA scalar (RPAREN | RBRACK))
    | (LPAREN ('-' INF)? COMMA scalar (RPAREN | RBRACK))
    | ((LPAREN | LBRACK) scalar COMMA INF? RPAREN)
    ;

/** schema Order return string; */
schema_root
    : SCHEMA union_type (RETURN union_type)? SEMI
    ;

/* --- Type System (Union Types) --- */

union_type
    : type_atom (PIPE type_atom)*
    ;

type_atom
    : PRIMITIVE_TYPE_ID
    | type_reference
    ;

type_reference
    : TYPE_ID type_args?
    ;

type_args
    : LANGLE union_type (COMMA union_type)* RANGLE
    ;

/* --- Data Value Rules --- */

value
    : scalar
    | collection
    | enum_value_ref
    ;

/** DeliveryStatus.InTransit */
enum_value_ref
    : TYPE_ID ('.' TYPE_ID)+
    ;

scalar
    : STRING
    | multiline_string
    | binary_literal
    | INT
    | DECIMAL
    | BOOLEAN
    | MAIL
    | DATETIME
    | DATE
    | TIME
    ;

multiline_string
    : TEXT_LINE+
    ;

binary_literal
    : HEX_BINARY
    | BASE64_BINARY
    ;

collection
    : object
    | array
    ;

/** Order { id: 1001, ... } */
object
    : type_reference LBRACE (kv_pair (COMMA kv_pair)* COMMA?)? RBRACE
    ;

kv_pair
    : ID COLON value
    ;

/** array<OrderItem> { ... } */
array
    : ARRAY LANGLE union_type RANGLE LBRACE (value (COMMA value)* COMMA?)? RBRACE
    ;

/* ==========================================
   Lexer Rules
   ========================================== */

// Keywords (すべてここで統一定義)
ENUM         : 'enum' ;
REGEXP       : 'regexp' ;
ACCEPT       : 'accept' ;
RANGE        : 'range' ;
CLASS        : 'class' ;
SCHEMA       : 'schema' ;
RETURN       : 'return' ;
ARRAY        : 'array' ;

REQUIRED     : 'required' ;
OPTIONAL     : 'optional' ;
CHOOSE       : 'choose' ;
EXTENDS      : 'extends' ;
ONEOF        : 'oneof' ;
EXCLUSIVE    : 'exclusive' ;
CONST        : 'const' ;
DEFAULT      : 'default' ;
INF          : 'inf' ;

// Symbols
LBRACE       : '{' ;
RBRACE       : '}' ;
LANGLE       : '<' ;
RANGLE       : '>' ;
COLON        : ':' ;
COMMA        : ',' ;
SEMI         : ';' ;
PIPE         : '|' ;
LBRACK       : '[' ;
RBRACK       : ']' ;
LPAREN       : '(' ;
RPAREN       : ')' ;

// Primitive Types
PRIMITIVE_TYPE_ID
    : 'string' | 'int' | 'decimal' | 'boolean' | 'mail' | 'datetime' | 'date' | 'time' | 'binary'
    ;

// Literals
REGEXP_LITERAL : '/' ( '\\/' | ~[/] )* '/' ;
BOOLEAN        : 'true' | 'false' ;
DATETIME       : [0-9]{4} '-' [0-9]{2} '-' [0-9]{2} ' ' [0-9]{2} ':' [0-9]{2} (':' [0-9]{2} ('.' [0-9]{3})?)? ;
DATE           : [0-9]{4} '-' [0-9]{2} '-' [0-9]{2} ;
TIME           : [0-9]{2} ':' [0-9]{2} (':' [0-9]{2} ('.' [0-9]{3})?)? ;
DECIMAL        : '-'? [0-9]+ '.' [0-9]+ ;
INT            : '-'? [0-9]+ ;
STRING         : '"' ( '\\"' | . )*? '"' ;
MAIL           : [a-zA-Z0-9._%+-]+ '@' [a-zA-Z0-9.-]+ '.' [a-zA-Z]{2,} ;
HEX_BINARY     : 'X\'' [0-9a-fA-F]* '\'' ;
BASE64_BINARY  : BASE64_LINE+ ;

TEXT_LINE   : '| ' ~[\r\n]* ([\r\n]+ | EOF) ;
BASE64_LINE : '$ ' [a-zA-Z0-9+/=]+ ([\r\n]+ | EOF) ;

TYPE_ID : [A-Z][a-zA-Z0-9]* ;
ID      : [a-z_][a-zA-Z0-9_]* ;

// Comments & Whitespace
DOC_COMMENT    : '/**' .*? '*/' ;
BLOCK_COMMENT  : '/*' ~[*] .*? '*/' -> skip ;
LINE_COMMENT   : '//' ~[\r\n]* -> skip ;
WS             : [ \t\r\n]+ -> skip ;
