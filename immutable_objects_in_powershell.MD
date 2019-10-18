# Immutable objects in Powershell 5
I got interested in functional programming, and although I still don't feel like purely functional programming
is something that I'd like to do, many of the ideas are pretty useful even in an object-obsessed language like powershell.

The two ideas that I like the most are pure functions and immutable variables. When writing powershell scripts, I try
to write most functions as pure functions, and then I have imperative super-functions (that I like to call routines), that
call these small nugget-sized pure functions to solve higher order tasks.

Immutable objects are just nice because you never have to worry about what the code does with it after declaration
(good for code that you've written months ago). While you could just decide not to mutate variables after declaration, it's
nice to have a safeguard.

This last thing though, creating immutable objects in powershell, is insanely convoluted in powershell 5.
The code below is my attempt to easily declare immutable objects. To use this code, just strip out the examples and dot source
it to your script. 

> You could make a powershell module, but that would entail renaming constant() to New-Constant() if you want to avoid
warning and I don't like the way that looks! Also, modules are great, but they make projects less portable.

If you want to see examples of the code below, just scroll down to the example section.

```powershell
# Creates new hashtable that is immutable from input hashtable
# NOTE: this is a helper function for constant()
# accepted input types: hashtables
function New-ImmutableHashtable() {
    param($hashtable)
    $immutable = New-Object PSObject
 
    $hashtable.Keys | %{ 
        $value = $hashtable[$_]
        $closure = { $value }.GetNewClosure()
        $immutable | Add-Member -name $_ -memberType ScriptProperty -value $closure
    }
     
    return $immutable
}

# Make given custom object immutable
# accepted input types: pscustomobjects, objects from custom classes
function Lock-Object{
    param($object)

    # Loop over each object property
    $object.PSObject.Properties | %{ 

        # get closure of value
        $value = $_.Value # we need to draw out the value from the loop variable from some reason. (won't work otherwise)
        $cvalue = { $value }.GetNewClosure()

        # Remove old property
        $object.PSObject.Properties.Remove($_)

        # Create new script property that returns the cached value
        $object.PSObject.Properties.Add( (New-Object PSScriptProperty $_.Name, $cvalue  ))
    }
}

# Makes new variable with given name where the variable is immutable
# accepted input types: simple types (strings, ints, etc), hashtables, arrays
function constant
{
    param([string]$name, $value)

    # array
    If ($value.GetType().BaseType.Name -eq 'Array'){
        New-Variable -Name $name -Value ([System.Collections.ObjectModel.Collection[object]] $value) -Option ReadOnly -Scope 1
    }
    # hashtable-like object
    ElseIf ($value.GetType().Name -eq 'Hashtable') {
        New-Variable -Name $name -Value (New-ImmutableHashtable -hashtable $value) -Option ReadOnly -Scope 1
    }
    # string, int, etc
    Else {
        New-Variable -Name $name -Value $value -Option ReadOnly -Scope 1
    }
    
}



# ==========================================================================
# EXAMPLES OF CONSTANT()
# ==========================================================================

# simple types
constant 'string' -value 'a'
write-host $string -ForegroundColor green
$string = 'b'
Remove-Variable -Name string -Force

# hashtables
constant 'hashtable' -value @{name='a'}
write-host $hashtable.name -ForegroundColor green
$hashtable.name = 'b'
Remove-Variable -Name hashtable -Force

# arrays
constant 'array' -value @(1,2)
write-host $array[0] -ForegroundColor green
$array[0] = 'a'
Remove-Variable -Name array -Force


# ==========================================================================
# EXAMPLES OF LOCK-OBJECT()
# ==========================================================================

# Normal object:
class Contact
{
    [ValidateNotNullOrEmpty()][string]$First
    [ValidateNotNullOrEmpty()][string]$Last
    [ValidateNotNullOrEmpty()][string]$Phone

    # test method to show it is conserved
    [boolean] foo(){
        return $true
   }
}

# Instantiate normal object
$donttouchme = [Contact]@{
   First = "Foo"
   Last = "Bar"
}

# Make object immutable
Lock-Object $donttouchme

# Test property conservation
write-host $donttouchme.First -ForegroundColor green

# Test method conservation
If($donttouchme.foo){
    write-host 'Success' -ForegroundColor green
} else {
    write-error 'Big oof'
}

# Test mutability
$donttouchme.First = 'prod'


# ==========================================================================
# SUMMARY
# ==========================================================================
constant 'string'    -value 'a'
constant 'array'     -value @(1,2)
constant 'hashtable' -value @{name='a'}
Lock-Object $object
```
