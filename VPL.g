grammar VPL;

options {
	language=Python;
	backtrack=true;
}

tokens {
	PRINT='print';
}

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
@init {mapping = {}}
		:
		m[mapping] EOF
		;

m [inherited] returns [synth]
		:	f[inherited] m[inherited]
		|
		;

f [inherited] returns [synth]
/*		:	'a' '=' e[inherited] 
			{synth = $e.synth}
			{print synth}
		;
*/

		:	'func' IDENT 
			{
				synth = inherited
				synth['.functionName'] = str($IDENT.text)
			}
				p d[synth] 
			{
				synth = $d.synth
			}
			s[synth] {print $s.synth} 'end' 
		;
p 
		:	'(' l ')'
		;

l
		:	IDENT 
		|	IDENT ',' l	
		;

d [inherited] returns [synth]
@init {synth = inherited}
		:	'var' l ';'	
		|
		;

s [inherited] returns [synth]
		:	IDENT '=' e
			//variable assignment
			{
				synth = inherited
				synth[str($IDENT.text)] = $e.synth
			}
			(';' s_1=s[synth] {synth = $s_1.synth})*
		|	';' s_1=s[inherited] {synth = $s_1.synth}
		|
		;

//e values return pure integers, not the attribute grammar
/*
e [inherited] returns [synth]
@init {print inherited}
		:	e_2=e2[inherited] '+' {synth = $e_2.synth} e_1=e[synth] 
		{synth = int($e_1.synth) + int($e_2.synth)}
//		|	e2[inherited] '-' e[$e2.synth]
//		|	e_2=e2[inherited] '-' e_1=e[$e_2.synth] 
//		{synth = int($e_2.synth) - int($e_1.synth)}
		|	e2[inherited] {synth = $e2.synth}
		;

e2 [inherited] returns [synth]
		:	e3[inherited] '*' //{synth = $e3.synth} e2[synth]
//			e_3=e3[inherited] '+' e_2=e2[$e_3.synth] 
//		{synth = int($e_1.synth) + int($e_2.synth)}
		//|	e3[inherited] '/' e2[$e3.synth]
		|	e3[inherited] {synth = $e3.synth}
		;

e3 [inherited] returns [synth]
		:	/*'min' '(' e_1=e[inherited] ',' e[$e_1.synth] ')' 
		|	'(' e[inherited] ')'
		|	IDENT {synth = inherited} //make str() case
		|	NUM {synth = int($NUM.text)}
		;
*/

e returns [synth]
		:	e_2=e2 '+' e_1=e 
		{synth = int($e_1.synth) + int($e_2.synth)}
//		|	e2 '-' e[$e2.synth]
		|	e_2=e2 '-' e_1=e
		{synth = int($e_2.synth) - int($e_1.synth)}
		|	e2 {synth = $e2.synth}
		;

e2 returns [synth]
		:	//e3 '*' {synth = $e3.synth} e2
			e_3=e3 '*' e_2=e2 
		{synth = int($e_3.synth) * int($e_2.synth)}
		//|	e3 '/' e2[$e3.synth]
		|	e3 {synth = $e3.synth}
		;

e3 returns [synth]
		:	/*'min' '(' e_1=e ',' e[$e_1.synth] ')' 
		|	'(' e ')'
		|	IDENT {synth = inherited} //make str() case
		|	*/NUM {synth = int($NUM.text)}
		;

IDENT	:	('a'..'z'|'A'..'Z'|'_')('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
		;

NUM		:	'0'..'9'+ ('.''0'..'9'+)?
		;

WHITESPACE 
		:	( '\t' | ' ' | '\r' | '\n'| '\u000C' )+ { $channel = HIDDEN; }; //sets all whitespace to hidden
