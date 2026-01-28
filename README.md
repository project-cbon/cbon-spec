# Class-Based Object Notation (CBON) Specification

**Class-Based Object Notation (CBON)** は、厳密な型定義、継承、および高度なバリデーション機能を備えた、データ記述およびスキーマ定義のための言語仕様です。

JSONやYAMLの柔軟性に、静的型付け言語のような型安全性とドメイン特化なデータ型（mail, datetime等）を組み合わせています。

---

## 主な特徴

* **強力な型システム**: プリミティブ型に加え、Union型 (`A | B`) やジェネリクス (`array<T>`) をサポート。
* **クラスベースの構造**: 継承 (`extends`) により、共通フィールドを効率的に管理。
* **高度な制約**: 正規表現によるバリデーション (`regexp`) や数値・時間の範囲制限 (`range`)、フィールド間の排他制御 (`exclusive`) が可能。
* **セマンティックデータ型**: `mail`, `datetime`, `date` など、現代的なアプリケーションで頻用される型をネイティブでサポート。

---

## 規則と命名規約

CBONでは、識別子のケース（大文字・小文字）によって役割が明確に区別されます。

### 1. 型の命名規則
| 種類 | 書式 | 例 | 備考 |
| :--- | :--- | :--- | :--- |
| **カスタム型** | **PascalCase** | `User`, `OrderCode` | `class`, `enum`, `regexp`, `range` 等で定義。 |
| **ビルトイン型** | **lowercase** | `string`, `int`, `mail` | 言語が標準で提供する型。 |
| **フィールド名** | **snake_case** | `created_at`, `is_active` | オブジェクト内のプロパティ名。 |

---

## スキーマ定義例

`example.cbon`

```
/** 商品コードの形式を定義 */
regexp ProductCode /^[A-Z]{3}-[0-9]{5}$/;

/** 自然数の定義（範囲制約） */
range Natural<int> { [1, inf) }

/** 営業時間の定義（時間の範囲制約） */
range OpenHours<time> { [09:00, 12:00), [13:00, 18:00) }

/** 配送ステータスの定義 */
enum DeliveryStatus {
    Pending,
    InTransit,
    Delivered,
    Returned
}

/** 基底クラス */
class BaseEntity {
    required string type;
    required Natural<int> id;
    optional datetime created_at;
}

/** ユーザー情報 */
class User extends BaseEntity {
    required string name;
    required mail email;
    const type "User";
}

/** 注文アイテム */
class OrderItem {
    required ProductCode code;
    required Natural<int> quantity;
    required int|decimal unit_price; 
}

/** 配送情報 */
class Delivery {
    required DeliveryStatus status;
    choose boolean is_drop_off;
    choose string signature_name;
    
    exclusive is_drop_off, signature_name;
}

/** メインの注文スキーマ */
class Order extends BaseEntity {
    required User customer;
    required array<OrderItem> items;
    required Delivery logistics;
    const type "Order";
}

/* スキーマのルート宣言 */
schema Order;
```


---

## 文法定義 (ANTLR4)

```antlr4
grammar CBON;

/* ==========================================
    Parser Rules
   ========================================== */

start
    : definition* schema_root+ value? EOF
    | value EOF
    ;

definition
    : enum_def | regexp_def | accept_def | class_def | range_def
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

enum_def
    : DOC_COMMENT? ENUM TYPE_ID LBRACE enum_member (COMMA enum_member)* COMMA? RBRACE SEMI?
    ;

enum_member
    : DOC_COMMENT? TYPE_ID
    ;

regexp_def
    : DOC_COMMENT? REGEXP TYPE_ID REGEXP_LITERAL SEMI
    ;

accept_def
    : DOC_COMMENT? ACCEPT TYPE_ID LBRACE value (COMMA value)* COMMA? RBRACE SEMI?
    ;

class_def
    : DOC_COMMENT? CLASS type_reference (EXTENDS type_reference)? LBRACE field_def* (group_def | initial_def)* RBRACE
    ;

field_def
    : DOC_COMMENT? (REQUIRED | OPTIONAL | CHOOSE) union_type ID SEMI
    ;

group_def
    : DOC_COMMENT? (ONEOF | EXCLUSIVE) ID (COMMA ID)+ SEMI
    ;

initial_def
    : DOC_COMMENT? (CONST | DEFAULT) ID value SEMI
    ;

schema_root
    : SCHEMA union_type (RETURN union_type)? SEMI
    ;

union_type
    : type_atom (PIPE type_atom)*
    ;

type_atom
    : PRIMITIVE_TYPE_ID | type_reference
    ;

type_reference
    : TYPE_ID type_args?
    ;

type_args
    : LANGLE union_type (COMMA union_type)* RANGLE
    ;

value
    : scalar | collection | enum_value_ref
    ;

enum_value_ref
    : TYPE_ID ('.' TYPE_ID)+
    ;

scalar
    : STRING | INT | DECIMAL | BOOLEAN | MAIL | DATETIME | DATE | TIME
    ;

collection
    : object | array
    ;

object
    : type_reference LBRACE (kv_pair (COMMA kv_pair)* COMMA?)? RBRACE
    ;

kv_pair
    : ID COLON value
    ;

array
    : ARRAY LANGLE union_type RANGLE LBRACE (value (COMMA value)* COMMA?)? RBRACE
    ;

/* ==========================================
    Lexer Rules
   ========================================== */

ENUM      : 'enum' ;
REGEXP    : 'regexp' ;
ACCEPT    : 'accept' ;
RANGE     : 'range' ;
CLASS     : 'class' ;
SCHEMA    : 'schema' ;
RETURN    : 'return' ;
ARRAY     : 'array' ;
REQUIRED  : 'required' ;
OPTIONAL  : 'optional' ;
CHOOSE    : 'choose' ;
EXTENDS   : 'extends' ;
ONEOF     : 'oneof' ;
EXCLUSIVE : 'exclusive' ;
CONST     : 'const' ;
DEFAULT   : 'default' ;
INF       : 'inf' ;

LBRACE : '{' ; RBRACE : '}' ; LANGLE : '<' ; RANGLE : '>' ;
COLON  : ':' ; COMMA  : ',' ; SEMI   : ';' ; PIPE   : '|' ;
LBRACK : '[' ; RBRACK : ']' ; LPAREN : '(' ; RPAREN : ')' ;

PRIMITIVE_TYPE_ID
    : 'string' | 'int' | 'decimal' | 'boolean' | 'mail' | 'datetime' | 'date' | 'time'
    ;

REGEXP_LITERAL : '/' ( '\\/' | ~[/] )* '/' ;
BOOLEAN        : 'true' | 'false' ;
DATETIME       : [0-9]{4} '-' [0-9]{2} '-' [0-9]{2} ' ' [0-9]{2} ':' [0-9]{2} (':' [0-9]{2} ('.' [0-9]{3})?)? ;
DATE           : [0-9]{4} '-' [0-9]{2} '-' [0-9]{2} ;
TIME           : [0-9]{2} ':' [0-9]{2} (':' [0-9]{2} ('.' [0-9]{3})?)? ;
DECIMAL        : '-'? [0-9]+ '.' [0-9]+ ;
INT            : '-'? [0-9]+ ;
STRING         : '"' ( '\\"' | . )*? '"' ;
MAIL           : [a-zA-Z0-9._%+-]+ '@' [a-zA-Z0-9.-]+ '.' [a-zA-Z]{2,} ;

TYPE_ID : [A-Z][a-zA-Z0-9]* ;
ID      : [a-z_][a-zA-Z0-9_]* ;

DOC_COMMENT   : '/**' .*? '*/' ;
BLOCK_COMMENT : '/*' ~[*] .*? '*/' -> skip ;
LINE_COMMENT  : '//' ~[\r\n]* -> skip ;
WS            : [ \t\r\n]+ -> skip ;
```
