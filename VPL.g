grammar VPL;

options {
	language=Python;
	backtrack=true;
}

/*tokens {
	print='print';
}*/

@init {
self.memory = {}

# Function definitions
def lookup(ident):
	return self.memory[ident]

def new(ident,val):
	self.memory[ident] = val
}

@after {
}


prog		
@init {mapping = []}
		:
		m[mapping] EOF
		{ print ($m.allFunctions) }
		;

// breaks the file into functions
m [someFunctions] returns [allFunctions]
		:	f { someFunctions.append($f.function) } m_1=m[someFunctions] { allFunctions = $m_1.allFunctions }
		|   { allFunctions = someFunctions }
		;

// breaks functions into their name, parameters, declared local variables and statements
f returns [function]
		:	'func' IDENT
			//define function name here
			{
				function = {}
				function["funcName"] = str($IDENT.text)
				emptyStatements = []
			}
			p { function["parameters"] = $p.parameters } d { function["declarations"] = $d.declarations }
			s[emptyStatements] 'end' 
			{ function["statements"] = $s.allStatements }
		;

// breaks down the function parameters
p returns [parameters] 
		:	{ emptyVariables = [] } '(' l[emptyVariables] ')' 
		{  parameters = $l.allVariables } 
		;

// breaks down the function variable declarations
d returns [declarations]
		:	{ emptyVariables = [] } 'var' l[emptyVariables] ';'
		{ declarations = $l.allVariables }
		| 
		{ declarations = [] }
		;

// breaks down a series of declarations, used by both parameters and declarations
l [someVariables] returns [allVariables]
		:	IDENT 
		{ someVariables.append(str($IDENT.text))
		  allVariables = someVariables }
		|	IDENT 
		{ someVariables.append(str($IDENT.text)) } 
			',' l_1=l[someVariables]
		{ allVariables = $l_1.allVariables }
		;

// breaks down the statements of a function
s [someStatements] returns [allStatements]
		:	s2 
		{ statement = $s2.statement
		  someStatements.append(statement) }
			';' s_1=s[someStatements]
		{ allStatements = $s_1.allStatements }
		| { allStatements = someStatements }
		;

// a single statement
s2 returns [statement]
		:	IDENT '=' e 
		{ rhs = $e.expression
		  lhs = str($IDENT.text)
		  statement = (lhs , rhs)
		}
		;

// breaks down expressions into e2 or plus/mins 
e returns [expression]
		:	e2'+' e_1=e
		{ op = "+"
		  arg1 = $e2.expression
		  arg2 = $e_1.expression
		  expression = [op, arg1, arg2]
		}
		|	e2 '-' e_1=e 
		{ op = "-"
		  arg1 = $e2.expression
		  arg2 = $e_1.expression
		  expression = [op, arg1, arg2]
		}
		|	e2 	 { expression = $e2.expression }
		;

// breaks down expressions into e3 or mult/div
e2 returns [expression]
		:	e3 '*' e2_1=e2
		{ op = "*"
		  arg1 = $e3.expression
		  arg2 = $e2_1.expression
		  expression = [op, arg1, arg2]
		}
		|	e3 '/' e2_1=e2 
		{ op = "/"
		  arg1 = $e3.expression
		  arg2 = $e2_1.expression
		  expression = [op, arg1, arg2]
		}
		|	e3 { expression = $e3.expression }
		;

// breaks expressions down into min calls, parenthesis, idents or nums
e3 returns [expression]
		:	'min' '(' e_1=e ',' e_2=e ')' 
		{ op = "min"
		  arg1 = $e_1.expression
		  arg2 = $e_2.expression 
		  expression = [op, arg1, arg2]
		}
		|	'(' e ')' { expression = $e.expression }
		|	IDENT { expression = str($IDENT.text) }
		|	NUM   { expression = float($NUM.text) }
		;

IDENT	:	('a'..'z'|'A'..'Z'|'_')('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
		;

NUM		:	'0'..'9'+ ('.''0'..'9'+)?
		;

WHITESPACE 
		:	( '\t' | ' ' | '\r' | '\n'| '\u000C' )+ { $channel = HIDDEN; }; //sets all whitespace to hidden
