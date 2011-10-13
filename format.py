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

class registryMap:
	def __init__(self, parameters, local, linearVars):
		self.mapping = {}
		self.constants = []
		self.tempVars = []
		self.usedTempVars = []
		self.loopVal = -1

		parameterRegisters = ['%rsi', '%rdx', '%rcx', '%r8', 'r9']
		for parameter in range(len(parameters)):
			self.mapping[parameters[parameter]] = "movq " + parameterRegisters[parameter] + ', %s' 

		
		varspot = 1
		for var in local:
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

		for i in range(linearVars):
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
	
	def getLoopVal(self):
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

def unwrap(expression, regmap): #unwraps a statement: ('c', ['a', 'plus' ['a', 'plus', 'b']]) ==> [<x1 = a + b>, <c = a + x1>]
	
	if type(expression) in [type(str()), type(int()), type(float())]:
		return expression

	if type(expression) == type(tuple()):
		return (expression[0], unwrap(expression[1], regmap)) 
	
	if type(expression) == type(list()):
		expr1 = expression[1]
		expr2 = expression[2]
		
		if type(expression[1]) == type(list()):
			expr1 = regmap.getTempVar()
#			print [expr1, unwrap(expression[1], regmap)]
			generateAssembly([expr1, unwrap(expression[1], regmap)], regmap, regmap.getLoopVal())

		if type(expression[2]) == type(list()):
			expr2 = regmap.getTempVar()
#			print [expr2, unwrap(expression[2], regmap)]
			generateAssembly([expr2, unwrap(expression[2], regmap)], regmap, regmap.getLoopVal())

		return [expression[0], unwrap(expr1, regmap), unwrap(expr2, regmap)] 

def generateAssembly(statement, regmap, loopval):
	operations = {'plus' : 'addps', 'mult' : 'mulps', 'sub' : 'subps', '/' : 'divps', 'min' : 'minps'}

	if type(statement[1]) ==  type(list()): 

		#assignment involving operations, x = a + b

		if statement[1][0] in operations:
			print "##%s = %s + %s##" %(statement[0], statement[1][1], statement[1][2])
			print regmap.putVar(statement[0], '%r11')

			constcheck1 = regmap.putVar(statement[1][1], '%rax')
			constcheck2 = regmap.putVar(statement[1][2], '%r10')
			
			print constcheck1
			print constcheck2

			temp = operationCode.replace('<loopcounter>', str(loopval)).replace('<operation>', operations[statement[1][0]])
			if constcheck1.split()[0] == 'leaq':
				temp = temp.replace('addq $16, %rax', '#line "addq $16, %rax" removed because the source is a constant')
			if constcheck2.split()[0] == 'leaq':
				temp = temp.replace('addq $16, %r10', '#line "addq $16, %r10" removed because the source is a constant')

			print temp

	else: #straight assignment, x = y
		print "##%s = %s##" % (statement[0], statement[1])
		print regmap.putVar(statement[0], '%r10')
		constcheck = regmap.putVar(statement[1], '%rax')

		print constcheck
		if constcheck.split()[0] == 'leaq':
			print assignmentCode.replace('<loopcounter>', str(loopval)).replace('addq $16, %rax', '#line "addq $16, %rax" removed because RHS is a constant\n')
		else:
			print assignmentCode.replace('<loopcounter>', str(loopval))
#
def createPostamble(regmap):
	print "####Function Epilogue####"
	print """
popq	%rbx
leave
ret"""
	if regmap.constants:
		print """
.data
.align 16"""
		for constant in regmap.constants:
			print """.const%f:
	.float %f
	.float %f
	.float %f
	.float %f""".replace('%f', str(constant))

def parseAttributeGrammar(funcdef):
	for func in funcdef:
		
		createPreamble(func['funcName'])
		createLocals(func['declarations'], func['linearVars'])
		
		regmap = registryMap(func['parameters'], func['declarations'], func['linearVars'])
		updatedRegmap = generateStatements(func['statements'], regmap)
		
		createPostamble(updatedRegmap)


if __name__ == "__main__":
	
	parseAttributeGrammar(funcdef)
