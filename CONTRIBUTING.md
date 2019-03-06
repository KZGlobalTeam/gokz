# Contributing

GOKZ is a community project. All are welcome to contribute as long as they follow the guidelines.

## General Procedure

 1. Create an issue so that we may first discuss the proposed changes or additions.
 2. Fork the repository (https://bitbucket.org/kztimerglobalteam/gokz/fork).
 3. Create a new branch off of the `dev` branch.
 4. Commit and push your code to your new branch.
 5. Create a pull request targeting our `dev` branch, making a reference to the issue.

Once your pull request is checked and approved, your branch will be merged into our `dev` branch. Keep an eye out for any comments and requested changes. Your changes will then be released in the next version of GOKZ!

## Style Guide

To keep our code beautiful and maintainable, please adhere to the style guide.

As a general rule, the style of your code should match what already exists. It is recommended to use [**SPEdit**](https://github.com/JulienKluge/Spedit) and its built-in syntax reformatter to assist formatting your code to match the project's style.

Our SourcePawn code is written in the [transitional syntax](https://wiki.alliedmods.net/SourcePawn_Transitional_Syntax) introduced with SourceMod 1.7.

### Formatting

* Use tabs for indenting.

* Use Allman style brace placement.
```
static void DoSomething()
{
	for (...)
	{
		if (...)
		{
		
		}
		else
		{

		}
	}
}
```

### Naming

* Method names begin with a uppercase letter (Pascal case), whilst variables begin with lowercase letter (camel case).
```
void SomeFunction(int someVariable)
{
	...
}
```

* Prefix the name of primitive type global variables to indicate the type of the variable.
```
int gI_SomeIntVar;
bool gB_SomeBoolVar;
float gF_SomeFloatVar;
```

* Use self-documenting function and variable names. Only comment if necessary or in `.inc` files.

### General

* Avoid introducing global variables. Instead, consider writing public accessor functions (`SetX`, `GetX`).

* Keep guard clauses (early `return`) such as `IsValidClient` checks at the top of function implementations.