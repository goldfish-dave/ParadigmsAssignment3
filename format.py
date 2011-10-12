"""[
	{	'declarations': ['x', 'y', 'z'],
	 	'statements': [],
	 	'parameters': ['a', 'b', 'c'],
	 	'funcName': 'mymin'
	}
]


	
remember, statements are only of the form:

IDENT = factor
IDENT = factor op factor

and in the simple case a factor is either a variable or a constant

so expect statements to look like this:

statements = 
	[ 
		( 'c' , 'b' ),
		( 'x' , [ 'a', 'plus', 'c' ] ),
		( 'a' , [ 'x', 'mult', 'b' ] ),
		( 'y' , [ 'a', 'min' , 'x' ] )
	]

"""

funcdef =	[
				{
					'declarations' : ['x', 'y', 'z']
					, 'statements' : [('c', 20), ('c', ['c', 'plus', 'b'])]
					, 'parameters' : ['a', 'b', 'c']
					, 'funcName' : 'mymin'
				}

			]


class registryMap:
	def __init__(self, parameters, local):
		self.mapping = {}

		parameterRegisters = ['%rsi', '%rdx', '%rcx', '%r8', 'r9']
		for parameter in range(len(parameters)):
			self.mapping[parameters[parameter]] = "movq " + parameterRegisters[parameter] + ', %s' 

		
		varspot = 0
		for var in local:
			self.mapping[var] = "#assign " + str(varspot) + "th variable to %s"
			self.mapping +="""
	movq %rdi, %s
	imulq $4, %s, %s
	addq $16, %s
	imulq $""" + str(varspot) + """, %s, %s
	subq %rbp, %s
	negq %s
	andq $-16, %s"""


			varspot += 1
		print self.mapping

def createLocals(localVars):
	assignMemory = """
#creating memory for local variables
	blah %i
	""".strip() % len(localVars)
	
	print assignMemory

def createPreamble(name):

	preamble = """
#function definitions
	%s %s %s
	""" % (name, name, name)
	print preamble

def generateStatements(statements, regmap):
	pass

if __name__ == "__main__":
	print funcdef
	
	for func in funcdef:
		
		createPreamble(func['funcName'])
		createLocals(func['declarations'])
		
		regmap = registryMap(func['parameters'], func['declarations'])

		generateStatements(func['statements'], regmap)
