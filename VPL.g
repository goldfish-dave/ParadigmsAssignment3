grammar VPL;

options {
	language=Python;
	backtrack=true;
//	output=AST;
//	ASTLabelType=CommonTree;
}

tokens {
	PRINT='print';
}

@init {
self.memory = {}
print "Init memory: " + str(self.memory)
def lookup(ident):
	return self.memory[ident]

def new(ident,val):
	self.memory[ident] = val
}


prog	:	m EOF
		;

m		:	f m
		|
		;

f		:	'func' IDENT p d s 'end' {
print "Function declaration"
}
		;

p		:	'(' l ')'
		;

l		:	IDENT 
		|	IDENT ',' l	
		;

d		:	'var' l ';'	{
print "Declaration"
}
		|
		;

s		:	s2 ';' s
		|	
		;

s2		:	IDENT '=' e {
print "Assignment"
}
		|	
		;

e		:	e2 '+' e {
print "Addition"
}
		|	e2 '-' e {
print "Subtraction"
}
		|	e2
		;

e2		:	e3 '*' e2 {
print "Multiplcation"
}
		|	e3 '/' e2 {
print "Division"
}
		|	e3
		;

e3		:	'min' '(' e ',' e ')' {
print "Minimization"
}
		|	'(' e ')'
		|	IDENT
		|	NUM
		;

IDENT	:	('a'..'z'|'A'..'Z'|'_')('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
		;

NUM		:	'0'..'9'+ ('.''0'..'9'+)?
		;

WHITESPACE 
		:	( '\t' | ' ' | '\r' | '\n'| '\u000C' )+ { $channel = HIDDEN; }; //sets all whitespace to hidden
