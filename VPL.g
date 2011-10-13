grammar VPL;

options {
	language=Python;
	backtrack=true;
}
/**
* In this grammar file we defined an attribute grammar to parse valid vpl.
* After the parsing, a variable labeled mapping will exist, which is a list
* of function objects. This list is iterated over, using the attributes in 
* the function objects to print out the appropriate x86_64 assembly.
*
* Function objects have the following attributes:
* function =
*   {
*     'funcName' : string,
*     'parameters' : list of strings,
*     'declarations' : list of strings,
*     'statements' : list of statements to be executed,
*     'linearVars' : int
*   }
*  NB: linearVars is used as an upper bound on the number of temporary local
*      variables that will be needed to evaluate an expression.
*  
*  NB': statements are eithers lists, with the function at the start, or atoms
        , much like lisp data types
*/
prog		
@init {mapping = []}
		:	m[mapping] EOF
{
import format

# This line will print out the appropriate assembly
format.parseAttributeGrammar( $m.allFunctions )
}
		;

// breaks the file into functions
m [someFunctions] returns [allFunctions]
		:	f { someFunctions.append($f.function) } m_1=m[someFunctions] { allFunctions = $m_1.allFunctions }
		|   { allFunctions = someFunctions }
		;

// breaks functions into their name, parameters, declared local variables and statements
f returns [function]
@init { 
# computes the maximum number of temporary vars required
def maxTempVars(statements):
  return max(map(tempVars, statements))

def tempVars(statement):
  return exprTempVars(statement[1])

def exprTempVars(expr):
  if type(expr) is not list:
    return 0
  return 1 + sum([exprTempVars(xp) for xp in expr])
}
		:	'func' IDENT
			{
				function = {}
				function["funcName"] = str($IDENT.text)
				emptyStatements = []
			}
			p { function["parameters"] = $p.parameters } d { function["declarations"] = $d.declarations }
			s[emptyStatements] 'end' 
			{ function["statements"] = $s.allStatements
			  function["linearVars"] = maxTempVars(function["statements"]) }
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

// Identification is an important part of keeping our citizens safe.
// Please keep your identification with you at all times, or you will 
// be processed.
IDENT	:	('a'..'z'|'A'..'Z'|'_')('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
		;

// I'm tired of being what you want me to be
// Feeling so faithless, lost under the surface
// I don't know what you're expecting of me
// Put under the pressure of walking in your shooooooooeeeeeeeeeess
NUM		:	'0'..'9'+ ('.''0'..'9'+)?
		;

// No space like white space
WHITESPACE 
		:	( '\t' | ' ' | '\r' | '\n'| '\u000C' )+ { $channel = HIDDEN; }; //sets all whitespace to hidden
