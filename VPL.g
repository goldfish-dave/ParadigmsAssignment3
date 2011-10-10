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
		;

m [inherited] returns [synth]
		:	f[inherited] m[inherited]
		|
		;

f [inherited] returns [synth]
		:	'func' IDENT
			//define function name here
			{
				newFunction = {}
				newFunction["funcName"] = str($IDENT.text)
				inherited.append(newFunction)
				statements = []
			}
			p[inherited] {synth = $p.synth} d[synth] {synth = $d.synth}
			s[statements] 'end' 
			{ inherited[-1]["statements"] = $s.synth
			  synth = inherited 
			  print synth }
		;
p [inherited] returns [synth] 
		:	{ parameters = [] }
			'(' l[parameters] ')' 
			{ inherited[-1]["parameters"] =  $l.synth
			  synth = inherited
			  print synth }
		;

l [inherited] returns [synth]
		:	IDENT 
		{ inherited.append(str($IDENT.text))
		  synth = inherited }
		|	IDENT 
		{ inherited.append(str($IDENT.text)) } 
			',' l_1=l[inherited]
		{ synth = $l_1.synth }
		;

d [inherited] returns [synth]
		:	{ parameters = [] }
			'var' l[parameters] ';'
		{ inherited[-1]["declarations"] = $l.synth
		  synth = inherited }
		| 
		{ inherited[-1]["declarations"] = []
		  synth = inherited }
		;

s [inherited] returns [synth]
		:	IDENT '=' e { synth = [] }
			//variable assignment occurs here, check if variable exists etc.
			(';' s[None] )*
//			(';' s_1=s[synth] {synth = $s_1.synth})*
		|	';' s_1=s[None] {synth = []}
		|
		;

//e values return pure floategers, not the attribute grammar
/*
e [inherited] returns [synth]
@init {print inherited}
		:	e_2=e2[inherited] '+' {synth = $e_2.synth} e_1=e[synth] 
		{synth = float($e_1.synth) + float($e_2.synth)}
//		|	e2[inherited] '-' e[$e2.synth]
//		|	e_2=e2[inherited] '-' e_1=e[$e_2.synth] 
//		{synth = float($e_2.synth) - float($e_1.synth)}
		|	e2[inherited] {synth = $e2.synth}
		;

e2 [inherited] returns [synth]
		:	e3[inherited] '*' //{synth = $e3.synth} e2[synth]
//			e_3=e3[inherited] '+' e_2=e2[$e_3.synth] 
//		{synth = float($e_1.synth) + float($e_2.synth)}
		//|	e3[inherited] '/' e2[$e3.synth]
		|	e3[inherited] {synth = $e3.synth}
		;

e3 [inherited] returns [synth]
		:	/*'min' '(' e_1=e[inherited] ',' e[$e_1.synth] ')' 
		|	'(' e[inherited] ')'
		|	IDENT {synth = inherited} //make str() case
		|	NUM {synth = float($NUM.text)}
		;
*/

e returns [synth]
		:	e_2=e2 '+' e_1=e 
		{synth = float($e_1.synth) + float($e_2.synth)}
		|	e_2=e2 '-' e_1=e
		{synth = float($e_2.synth) - float($e_1.synth)}
		|	e2 {synth = $e2.synth}
		;

e2 returns [synth]
		:	e_3=e3 '*' e_2=e2 
		{synth = float($e_3.synth) * float($e_2.synth)}
		|	e_3=e3 '/' e_2=e2
		{synth = float($e_3.synth) / float($e_2.synth)}
		|	e3 {synth = $e3.synth}
		;

e3 returns [synth]
		:	'min' '(' e_1=e ',' e_2=e ')' 
		{synth = min(float($e_1.synth), float($e_2.synth))}
		|	'(' e ')' {synth = $e.synth}
//		|	IDENT {synth = inherited} //make str() case, do lookup here
		|	NUM {synth = float($NUM.text)}
		;

IDENT	:	('a'..'z'|'A'..'Z'|'_')('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
		;

NUM		:	'0'..'9'+ ('.''0'..'9'+)?
		;

WHITESPACE 
		:	( '\t' | ' ' | '\r' | '\n'| '\u000C' )+ { $channel = HIDDEN; }; //sets all whitespace to hidden
