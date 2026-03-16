grammar CBONProcess;
/** import CBON; */
import CBONFruits;

start
    : (definition | output_def)* process_def* schema_root+ expression_def? EOF
    | expression_def EOF
    ;

/** output Markdown<Result> template "**@(type)**: @(message format Markdown)"; */
output_def
    : decorators OUTPUT TYPE_ID (LANGLE union_type RANGLE)? TEMPLATE
      template_block SEMI
    ;

template_block
    : STRING
    | TEXT_LINE+
    ;

/** process Main(Prompt, Data) return(Result) format Markdown; */
process_def
    : decorators PROCESS TYPE_ID 
      LPAREN (union_type (COMMA union_type)*)? COMMA? RPAREN 
      RETURN 
      LPAREN (union_type (COMMA union_type)*)? COMMA? RPAREN 
      (FORMAT TYPE_ID (WRAP (template_block | TYPE_ID)))? SEMI
    ;

/** Main( Prompt{ ... }, Data{ ... } ) */
expression_def
    : value (COMMA value)* COMMA?
    | TYPE_ID LPAREN (value (COMMA value)*)? COMMA? RPAREN
    ;


// Keywords
OUTPUT   : 'output' ;
TEMPLATE : 'template' ;
PROCESS : 'process' ;
FORMAT  : 'format' ;
WRAP    : 'wrap' ;
