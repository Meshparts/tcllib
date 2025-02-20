
[//000000001]: # (valtype::iban \- Validation types)
[//000000002]: # (Generated from file 'vtype\.inc' by tcllib/doctools with format 'markdown')
[//000000003]: # (Copyright &copy; 2011 Andreas Kupries <andreas\_kupries@users\.sourceforge\.net>)
[//000000004]: # (valtype::iban\(n\) 1\.8 tcllib "Validation types")

<hr> [ <a href="../../../../toc.md">Main Table Of Contents</a> &#124; <a
href="../../../toc.md">Table Of Contents</a> &#124; <a
href="../../../../index.md">Keyword Index</a> &#124; <a
href="../../../../toc0.md">Categories</a> &#124; <a
href="../../../../toc1.md">Modules</a> &#124; <a
href="../../../../toc2.md">Applications</a> ] <hr>

# NAME

valtype::iban \- Validation for IBAN

# <a name='toc'></a>Table Of Contents

  - [Table Of Contents](#toc)

  - [Synopsis](#synopsis)

  - [Description](#section1)

  - [API](#section2)

  - [Error Codes](#section3)

  - [Bugs, Ideas, Feedback](#section4)

  - [Keywords](#keywords)

  - [Category](#category)

  - [Copyright](#copyright)

# <a name='synopsis'></a>SYNOPSIS

package require Tcl 8\.5  
package require snit 2  
package require valtype::common  
package require valtype::iban ?1\.8?  

[__valtype::iban__ __validate__ *value*](#1)  
[__valtype::iban__ __checkdigit__ *value*](#2)  

# <a name='description'></a>DESCRIPTION

This package implements a snit validation type for an IBAN\.

A validation type is an object that can be used to validate Tcl values of a
particular kind\. For example, __snit::integer__, a validation type defined
by the __[snit](\.\./snit/snit\.md)__ package is used to validate that a
Tcl value is an integer\.

Every validation type has a __validate__ method which is used to do the
validation\. This method must take a single argument, the value to be validated;
further, it must do nothing if the value is valid, but throw an error if the
value is invalid:

    valtype::iban validate .... ;# Does nothing
    valtype::iban validate .... ;# Throws an error (bad International Bank Account Number).

The __validate__ method will always return the validated value on success,
and throw the __\-errorcode__ INVALID on error, possibly with additional
elements which provide more details about the problem\.

# <a name='section2'></a>API

The API provided by this package satisfies the specification of snit validation
types found in the documentation of *[Snit's Not Incr
Tcl](\.\./snit/snit\.md)*\.

  - <a name='1'></a>__valtype::iban__ __validate__ *value*

    This method validates the *value* and returns it, possibly in a canonical
    form, if it passes\. If the value does not pass the validation an error is
    thrown\.

  - <a name='2'></a>__valtype::iban__ __checkdigit__ *value*

    This method computes a check digit for the *value*\. Before doing so it is
    validated, except for a checkdigit\. If the value does not pass the
    validation no check digit is calculated and an error is thrown instead\.

# <a name='section3'></a>Error Codes

As said in the package description, the errors thrown by the commands of this
package in response to input validation failures use the __\-errorcode__
INVALID to distinguish themselves from package internal errors\.

To provide more detailed information about why the validation failed the
__\-errorCode__ goes actually beyond that\. First, it will contain a code
detailing the type itself\. Here this is __IBAN__\. This is then followed by
values detailing the reason for the failure\. The full set of __\-errorCode__s
which can be thrown by this package are:

  - INVALID IBAN CHARACTER

    The input value contained one or more bad characters, i\.e\. characters which
    must not occur in the input for it to be an IBAN\.

  - INVALID IBAN CHECK\-DIGIT

    The check digit of the input value is wrong\. This usually signals a
    data\-entry error, with digits transposed, forgotten, etc\. Of course, th
    input may be an outright fake too\.

# <a name='section4'></a>Bugs, Ideas, Feedback

This document, and the package it describes, will undoubtedly contain bugs and
other problems\. Please report such in the category *valtype* of the [Tcllib
Trackers](http://core\.tcl\.tk/tcllib/reportlist)\. Please also report any ideas
for enhancements you may have for either package and/or documentation\.

When proposing code changes, please provide *unified diffs*, i\.e the output of
__diff \-u__\.

Note further that *attachments* are strongly preferred over inlined patches\.
Attachments can be made by going to the __Edit__ form of the ticket
immediately after its creation, and then using the left\-most button in the
secondary navigation bar\.

# <a name='keywords'></a>KEYWORDS

[Checking](\.\./\.\./\.\./\.\./index\.md\#checking),
[IBAN](\.\./\.\./\.\./\.\./index\.md\#iban), [International Bank Account
Number](\.\./\.\./\.\./\.\./index\.md\#international\_bank\_account\_number),
[Testing](\.\./\.\./\.\./\.\./index\.md\#testing), [Type
checking](\.\./\.\./\.\./\.\./index\.md\#type\_checking),
[Validation](\.\./\.\./\.\./\.\./index\.md\#validation), [Value
checking](\.\./\.\./\.\./\.\./index\.md\#value\_checking),
[bank](\.\./\.\./\.\./\.\./index\.md\#bank),
[finance](\.\./\.\./\.\./\.\./index\.md\#finance), [isA](\.\./\.\./\.\./\.\./index\.md\#isa)

# <a name='category'></a>CATEGORY

Validation, Type checking

# <a name='copyright'></a>COPYRIGHT

Copyright &copy; 2011 Andreas Kupries <andreas\_kupries@users\.sourceforge\.net>
