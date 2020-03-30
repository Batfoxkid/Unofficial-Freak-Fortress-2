/*
	Optional:
	tf2x10

	Functions:
	float ParseFormula(int boss, const char[] key, const char[] defaultFormula, float players)
*/

#define FF2_FORMULA

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent
};

static int Operate(ArrayList sumArray, int &bracket, float value, ArrayList _operator)
{
	float sum = sumArray.Get(bracket);
	switch(_operator.Get(bracket))
	{
		case Operator_Add:
		{
			sumArray.Set(bracket, sum+value);
		}
		case Operator_Subtract:
		{
			sumArray.Set(bracket, sum-value);
		}
		case Operator_Multiply:
		{
			sumArray.Set(bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError2("[Boss] Detected a divide by 0!");
				bracket = 0;
				return;
			}
			sumArray.Set(bracket, sum/value);
		}
		case Operator_Exponent:
		{
			sumArray.Set(bracket, Pow(sum, value));
		}
		default:
		{
			sumArray.Set(bracket, value);  //This means we're dealing with a constant
		}
	}
	_operator.Set(bracket, Operator_None);
}

static void OperateString(ArrayList sumArray, int &bracket, char[] value, int size, ArrayList _operator)
{
	if(!value[0])  //Make sure 'value' isn't blank
		return;

	Operate(sumArray, bracket, StringToFloat(value), _operator);
	strcopy(value, size, "");
}

stock float ParseFormula(int boss, const char[] key, const char[] defaultFormula, float players)
{
	static char formula[1024];
	Special[boss].Kv.Rewind();
	Special[boss].Kv.GetString(key, formula, sizeof(formula), defaultFormula);

	int size = 1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i] == '(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i] == ')')
		{
			matchingBrackets++;
		}
	}

	ArrayList sumArray = new ArrayList(_, size);
	ArrayList _operator = new ArrayList(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	sumArray.Set(0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	_operator.Set(bracket, Operator_None);

	char character[2], value[16];
	for(int i; i<=strlen(formula); i++)
	{
		character[0] = formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				sumArray.Set(bracket, 0.0);
				_operator.Set(bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(_operator.Get(bracket) != Operator_None)  //Something like (5*)
				{
					char bossName[64];
					Special[boss].Kv.GetString("filename", bossName, sizeof(bossName));
					LogError2("[Boss] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return 0.0;
				}

				if(--bracket<0)  //Something like (5))
				{
					char bossName[64];
					Special[boss].Kv.GetString("filename", bossName, sizeof(bossName));
					LogError2("[Boss] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return 0.0;
				}

				Operate(sumArray, bracket, sumArray.Get(bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, players, _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
					{
						_operator.Set(bracket, Operator_Add);
					}
					case '-':
					{
						_operator.Set(bracket, Operator_Subtract);
					}
					case '*':
					{
						_operator.Set(bracket, Operator_Multiply);
					}
					case '/':
					{
						_operator.Set(bracket, Operator_Divide);
					}
					case '^':
					{
						_operator.Set(bracket, Operator_Exponent);
					}
				}
			}
		}
	}

	float result = sumArray.Get(0);
	delete sumArray;
	delete _operator;

	#if defined FF2_TIMESTEN
	return result*TimesTen_Value();
	#else
	return result;
	#endif
}
