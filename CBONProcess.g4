grammar CBONProcess;
import CBON;

start
    : definition* process_def* schema_root+ expression_def? EOF
    | expression_def EOF
    ;

/** process Main(Prompt, Data) return(Result) format Markdown; */
process_def
    : PROCESS TYPE_ID 
      LPAREN (union_type (COMMA union_type)*)? COMMA? RPAREN 
      RETURN 
      LPAREN (union_type (COMMA union_type)*)? COMMA? RPAREN 
      (FORMAT TYPE_ID)? SEMI
    ;

/** Main( Prompt{ ... }, Data{ ... } ) */
expression_def
    : value (COMMA value)* COMMA?
    | TYPE_ID LPAREN (value (COMMA value)*)? COMMA? RPAREN
    ;


// Keywords
PROCESS : 'process' ;
FORMAT  : 'format' ;