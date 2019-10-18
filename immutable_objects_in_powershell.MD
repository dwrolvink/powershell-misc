# Immutable objects in Powershell 5
Immutable objects are great, but hard to do in Powershell natively. Worry not though, with only 3 short functions we can create immutable arrays, hashtables, simple types (string, int, ...) and convert custom object to be immutable too.

`Warning: I did not test the functionality of this method yet beyond the tests listed below. `

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
