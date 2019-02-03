# Introduction to Powershell Modules
## The purpose of modules
Let's say we write a simple function, and then want to use it throughout a package, or just anywhere on our local machine:

``` powershell
# .\writelog.ps1

Function Write-Log()
{
  Param($Message, $LogFilePath)
  
  $message >> $LogFilePath
}
```
To have this function available we would need to run the code in powershell everytime we want to use it.
If we want to have it automatically available in another script, and not have to separately run writelog.ps1 beforehand,
we could resort to dot sourcing:

``` powershell
# .\anotherScript.ps1
. writelog.ps1
Write-Log -Message "Hi" -LogFilePath "C:/log.txt"
```
This is pretty useful for simple packages of scripts, but when you get to the point where you want to expand a simple package,
or reuse the code in a different project, the dot sourcing might pose a problem with file locations changing as we restructure
our code base. Also, merely changing the location of the package itself will break the dot sourcing, unless you use full path names,
or add a copy of your writelog.ps1 file to any solution using it. It's clear that none of these options are viable
in the long run.

It would also be useful to have one logging solution being available anytime we run code, even if it's just in the CLI. Maybe 
even have it possible to easily export this code to another machine and make it available there too.


## A simple module
There really isn't much to making this happen. First, we change the filename extension of our previous file from .ps1 to .psm1..
Then, we put this module file into a folder that is listed in `$PSModulePath`. This would by default be 
`$home\Documents\WindowsPowerShell\Modules\` to make this accessible for yourself, and `$pshome\Modules` to make the module 
accessible for everyone on the machine. The folder has to have the same name as the module file. In this example the path will be:

```
C:\Users\<username>\Documents\WindowsPowerShell\Modules\WriteLog\WriteLog.psm1
```

Now we can use the Write-Log function in any script by doing the following:

``` powershell
# .\aBetterSolution.ps1
Import-Module WriteLog
Write-Log -Message "Hi" -LogFilePath "C:/log.txt"
```
You can now write one module with all the functions in there and have them all be dynamically accessible from any location, 
while being stored at only one location. Installing the module is as simple as just copying the folder over to a $PSModulePath
on another computer. You can even load the module in your .profile so it will always be accessible by default in your CLI. 
A script should always include the `Import-Module <ModuleName>` line though, to make it clear that this module is required for
the script to run.

## A Root Module (aka Module Manifest)
Instead of putting every kind of custom function in one module, you might want to split your module up into different packages.
For example, you might want to put all your logging functionality in one package, and have a general package that does a lot
of custom things use that module by default.

So, let's say we create a new module, called __InfraManager__, that brings a lot of custom functions with it, like connecting to
storage solutions, creating VM's, etc. And __WriteLog__ will have to be loaded before InfraManager for it to work properly, 
as it uses functions from that module throughout its own functions.

One way to do this is to simply add `Import-Module WriteLog` at the top of InfraManager.psm1. This will only work for fully fledged
modules though, i.e. modules that are installed on the $PSModulePath. In my case, I want to split up InfraManager into a lot
of different submodules, which I don't necessarily want to install as full modules yet. I want to be able to install just 
InfraManager, and have the code segmented into submodules, and split off the submodules into their own fully fledged modules
when they are mature enough (and have a usecase outside of InfraManager, like a universal logging tool would).

For this to work we'll have to create a module manifest next to our InfraManager.psm1 file. Let's first make that file because
we havent yet in this tutorial:

``` powershell
# $home\Documents\WindowsPowerShell\Modules\InfraManager\Inframanager.psm1

Function Test-Logging()
{
  Write-Log "testest" -LogFilePath "C:/log.txt"
}
```

### Creating the module manifest
Run the following command in powershell:

``` powershell
New-ModuleManifest -Path "C:\Users\<username>\Documents\WindowsPowerShell\Modules\InfraManager\InfraManager.psd1"
```

This will create a full manifest for you. You can look here for information on the extra options in that file
[How to write a powershell manifest](https://docs.microsoft.com/en-us/powershell/developer/module/how-to-write-a-powershell-module-manifest).

For now, we will be concerned mostly with RequiredModules, and NestedModules.

The comments in the file are pretty self explanatory. If we want to preload modules that are not (directly) in the $PSModulePath
when we load the InfraManager module we can add the following to the NestedModules list:
``` powershell
NestedModules     = @(  'Modules\WriteLog\WriteLog.psm1' )
```
Notice that this path is relative to $PSScriptRoot, so make sure that the `\WriteLog\` folder is pasted under 
`C:\Users\<username>\Documents\WindowsPowerShell\Modules\InfraManager\Modules\`

If we then later change WriteLog to a full fledged module, we can copy the WriteLog folder directy under `C:\Users\<username>\Documents\WindowsPowerShell\Modules\`, 
and remove the item from NestedModules, and change RequiredModules:

``` powershell
RequiredModules = @('WriteLog')
```

### Conclusion: Why use manifests in our case
- You can use NestedModules. This allows you to separate out code into modules without:
  * Polluting the module path with half baked modules
  * Having to install a lot of modules for one solution, just copy over one folder
- Having two modules requiring eachother without going into an Import-Module loop.

Let me explain the last point a bit, because I haven't talked about it yet: Let's say WriteLog uses 
functions in InfraManager (and we don't care because both will always be installed on _our_ machines), and InfraManager uses
functions from WriteLog. You might want to add `Import-Module <the other one>` to each module, but this will result in an import
loop. You can solve this by adding:

``` powershell
If (! (Get-Module <the other module>))
{ Import-Module <the other module> }
```

It was still kind of buggy for me, but I'm sure you can make the above code work in some form or another.
Point is: manifest files are a very clean way to document all the info on your module in one location. If you're going through
the trouble of building a Root module, you might as well make the 30 minutes investment of building a manifest file.

