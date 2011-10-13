funcdef =	[
				{
					'declarations' : ['x', 'y', 'z']
#					, 'statements' : [('c', 20), ('c', ['c', 'plus', ['a', 'plus' 'b']])]
			
					, 'statements' : [('c', ['plus', ['mult', 'a', 'b'], ['mult', 'a', 'b']]) , ('x', 20), ('c', ['plus', '100', 40])]

#					, 'statements' : [('c', ['plus', 'a', 'b'])]
#					, 'statements' : [('c', ['plus' , ['plus', ['plus', 'a', 'a'], 'c'] , ['plus', 'd', 20]])]
#					, 'statements' : [('c', ['plus' , 'c' , ['plus', ['plus', 'c', 'd'], 'b']])]
#					, 'statements' : [('x', 20)]#, ('c', 'x')]
					, 'parameters' : ['a', 'b', 'c']
					, 'funcName' : 'mymin'
					, 'linearVars' : 10
				}

			]

operationCode = """
movq %rdi, %rbx
shrq $2, %rbx
jz .loop_end<loopcounter>

.loop_begin<loopcounter>:
movaps (%rax), %xmm0
movaps (%r10), %xmm1

#operation
<operation> %xmm0, %xmm1

movaps %xmm1, (%r11)

addq $16, %rax
addq $16, %r11
decq %rbx
jnz .loop_begin<loopcounter>

.loop_end<loopcounter>:
"""

assignmentCode = """
movq %rdi, %rbx
shl $2, %rbx
jz .loop_end<loopcounter>

.loop_begin<loopcounter>:

movaps (%rax), %xmm0
movaps %xmm0, (%r10)

addq $16, %rax
addq $16, %r10
decq %rbx
jnz .loop_begin<loopcounter>

.loop_end<loopcounter>:
"""

class registryMap: #used to store all the assembly needed to access the variables as well as variables needed to write the assembly
	def __init__(self, parameters, local, linearVars, loopVal): #takes in the parameters and locals the function takes, as well as the minimum int of variables needed to linearise all the statements
		self.mapping = {}
		self.constants = []

		#tempvars contains all the unused temporary variables for linearisation, lock/unlock scheme
		self.tempVars = []
		self.usedTempVars = [] 

		self.loopVal = loopVal #used for the unique identifier for .loop_begin() etc.

		parameterRegisters = ['%rsi', '%rdx', '%rcx', '%r8', 'r9'] #contain (in order) the arguments of the function and their corrosponding register
		for parameter in range(len(parameters)):
			self.mapping[parameters[parameter]] = "movq " + parameterRegisters[parameter] + ', %s' 
		
		varspot = 1
		for var in local: #maps all local vars to the assembly required to access them
			self.mapping[var] = "#assign #" + str(varspot) + " variable to %s\n"
			self.mapping[var] +="""
movq %rdi, %s
imulq $4, %s, %s
addq $16, %s
imulq $""" + str(varspot * 16) + """, %s, %s
subq %rbp, %s
negq %s
andq $-16, %s"""

			varspot += 1

		for i in range(linearVars): #maps all linear variables to the assembly required to access them
			self.tempVars += ['.' + str(i)]
			self.mapping['.' + str(i)] ="""
movq %rdi, %s
imulq $4, %s, %s
addq $16, %s
imulq $""" + str(varspot * 16) + """, %s, %s
subq %rbp, %s
negq %s
andq $-16, %s"""

			varspot += 1

	def getTempVar(self): #returns the name of an unlocked temp variable and locks it 
		self.usedTempVars.append(self.tempVars.pop())
		return self.usedTempVars[-1]
	
	def resetTempVars(self): #unlocks all temp variables making them free to use again
		self.tempVars += self.usedTempVars
		self.usedTempVars = []

	def putVar(self, var, register): #generates the assembly to put the memory address of variable var into the register specified
		if var not in self.mapping: #check if it's a constant
			try:
				self.constants += [float(var)]
				return 'leaq .const' + str(self.constants[-1]) + ', ' + register

			except ValueError:
				print "undeclared variable"
		return self.mapping[var].replace('%s', register)
	
	def getLoopVal(self): #returns a unique int for use in .loop_begin<int> etc.
		self.loopVal += 1
		return self.loopVal

def createPreamble(name):
	preamble = """####Function Definitions####

.text
.global %s
.type %s, @function
.p2align 4,,15

%s:

pushq %rbp
movq %rsp, %rbp
pushq %rbx
""".replace('%s', name)
	print preamble

def createLocals(localVars, linearVars):
	assignMemory = """####Creating memory for local variables####

movq %rdi, %rax
imulq $4, %rax, %rax
addq $16, %rax
imulq $%s, %rax, %rax
subq %rax, %rsp
andq $-16, %rsp
""".replace('%s', str(len(localVars) + linearVars))
	
	print assignMemory

def generateStatements(statements, regmap):
	print '####Function body####\n'
	print "##suffix '.' means temporary variable used for linearisation##"
	loopval = 0

	for statement in statements:
#		print statement
		"""
		if type(statement[1]) ==  type(list()): 

			#assignment involving operations, x = a + b

			if statement[1][1] == 'plus':
				print "##%s = %s + %s##\n" %(statement[0], statement[1][0], statement[1][2])
				print regmap.putVar(statement[1][0], '%rax')
				print regmap.putVar(statement[1][2], '%r10')
				print regmap.putVar(statement[0], '%r11')
				print operationCode.replace('<loopcounter>', str(loopval)).replace('<operation>', 'addps')

		else: #straight assignment, x = y
			print "##%s = %s##\n" % (statement[0], statement[1])
			print regmap.putVar(statement[0], '%r10')
			constcheck = regmap.putVar(statement[1], '%rax')

			print constcheck
			if constcheck.split()[0] == 'leaq':
				print assignmentCode.replace('<loopcounter>', str(loopval)).replace('addq $16, %rax', '#line "addq $16, %rax" removed because RHS is a constant\n')
			else:
				print assignmentCode.replace('<loopcounter>', str(loopval))

		loopval += 1
		"""
		generateAssembly(unwrap(statement, regmap), regmap, regmap.getLoopVal())
		regmap.resetTempVars()

	return regmap

def unwrap(expression, regmap): #unwraps a statement: ('c', ['a', 'plus' ['a', 'plus', 'b']]) ==> <x1 = a + b>, <c = a + x1>
	#recursively breaks down the contents of statement to it's basic form

	if type(expression) in [type(str()), type(int()), type(float())]:
		return expression

	if type(expression) == type(tuple()): #special case, tuple represents the root node
		return (expression[0], unwrap(expression[1], regmap)) 
	
	if type(expression) == type(list()):
		expr1 = expression[1]
		expr2 = expression[2]

		#checks if the expression can be further broken down
		if type(expression[1]) == type(list()):
			expr1 = regmap.getTempVar()
			generateAssembly([expr1, unwrap(expression[1], regmap)], regmap, regmap.getLoopVal())

		if type(expression[2]) == type(list()):
			expr2 = regmap.getTempVar()
			generateAssembly([expr2, unwrap(expression[2], regmap)], regmap, regmap.getLoopVal())

		return [expression[0], unwrap(expr1, regmap), unwrap(expr2, regmap)] 

def generateAssembly(statement, regmap, loopval):
	operations = {'+' : 'addps', '*' : 'mulps', '-' : 'subps', '/' : 'divps', 'min' : 'minps'} #operations from the attribute grammar mapping to their equivalent assembly intructions

	if type(statement[1]) ==  type(list()): #type list indicates a operation 

		#assignment involving operations, x = a + b

		if statement[1][0] in operations:
			print "##%s = %s + %s##" %(statement[0], statement[1][1], statement[1][2])

			#loads the required address into the 'destination' register
			print regmap.putVar(statement[0], '%r11')
			
			#loads the required addresses into the 'source' registers
			constcheck1 = regmap.putVar(statement[1][1], '%rax')
			constcheck2 = regmap.putVar(statement[1][2], '%r10')
			
			print constcheck1
			print constcheck2
			
			#check for constants in the 'sources', which requires specific lines to be deleted
			temp = operationCode.replace('<loopcounter>', str(loopval)).replace('<operation>', operations[statement[1][0]])
			if constcheck1.split()[0] == 'leaq':
				temp = temp.replace('addq $16, %rax', '#line "addq $16, %rax" removed because the source is a constant')
			if constcheck2.split()[0] == 'leaq':
				temp = temp.replace('addq $16, %r10', '#line "addq $16, %r10" removed because the source is a constant')

			print temp

	else: #straight assignment, x = y
		print "##%s = %s##" % (statement[0], statement[1])

		#destination address loading
		print regmap.putVar(statement[0], '%r10')
		
		#checks if RHS is a constant
		constcheck = regmap.putVar(statement[1], '%rax')
		print constcheck
		if constcheck.split()[0] == 'leaq':
			print assignmentCode.replace('<loopcounter>', str(loopval)).replace('addq $16, %rax', '#line "addq $16, %rax" removed because RHS is a constant\n')
		else:
			print assignmentCode.replace('<loopcounter>', str(loopval))

def createPostamble(regmap):
	print "####Function Epilogue####"
	print """
popq	%rbx
leave
ret"""
	if regmap.constants: #if the function had constants which required to be defined
		print """
.data
.align 16"""
		for constant in regmap.constants:
			print """.const%f:
	.float %f
	.float %f
	.float %f
	.float %f""".replace('%f', str(constant))

def parseAttributeGrammar(funcdef): #main function to call everything in order
	regmap = registryMap([], [], 0, -1)
	for func in funcdef:
		createPreamble(func['funcName'])
		createLocals(func['declarations'], func['linearVars'])
		
		regmap = registryMap(func['parameters'], func['declarations'], func['linearVars'], regmap.getLoopVal())
		updatedRegmap = generateStatements(func['statements'], regmap)
		
		createPostamble(updatedRegmap)

if __name__ == "__main__":
	
	parseAttributeGrammar(funcdef)
