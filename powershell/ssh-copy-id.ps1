<#
    .SYNOPSIS
    Copy ssh public key to remote account
    .DESCRIPTION
    Copies public key to target machine
    Default is .ssh\id_rsa.pub
    See copyright notice at end of script
    If this script won't run, then run this command once
    Set-ExecutionPolicy RemoteSigned CurrentUser
        refer to https://go.microsoft.com/fwlink/?LinkID=135170
 #>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $True)]
    [string]$Target <# SSH compatible Name of Target machine #>,
    [Parameter( Position = 1, Mandatory = $False)]
    [string]$IdentityFile = "id_rsa" <#Identity File, must be in .ssh directory #>,
    [switch]$Save = $False <# Save script used #>
)
$IdentityPath = Join-Path (Join-Path $env:USERPROFILE .ssh) $IdentityFile
if (-not (Test-Path -Path $IdentityPath -PathType Leaf)) {
    Write-Host Key file $IdentityFile does not exist, use ssh-keygen
    exit(1)
}
$PUBLIC_KEY = get-content "${IdentityPath}.pub"
$SCRIPT = @"
#!/bin/bash
#
PUBLIC_KEY="$PUBLIC_KEY"
umask 0077
[ -d ~/.ssh ]||mkdir -p ~/.ssh
[ -f ~/.ssh/authorized_keys ]|| touch ~/.ssh/authorized_keys
grep --quiet --fixed-strings "`$PUBLIC_KEY" ~/.ssh/authorized_keys
if [ `$? -ne 0 ]
then
    echo "`$PUBLIC_KEY" >> ~/.ssh/authorized_keys
else
   echo Key already exists, no update performed.
fi
"@
if ($Save) {
    Set-Content .\ssh-copy-id.sh -Value $SCRIPT
}

# The sed step is to convert crlf to lf for bash - it's fussy
$SCRIPT | ssh $Target -o StrictHostKeyChecking=no "sed 's/\r//' | bash"
if ($?) {
    Write-Output "You should be able to login to $Target without a password using $IdentityFile key"
}
else {
    Write-Host "Could not connect to $Target - Terminating"  -ForegroundColor Red
}
<#
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
For more information, please refer to <https://unlicense.org>
#>