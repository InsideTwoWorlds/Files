<# PeekMessageA function wrapper for TwoWorlds.exe
The altered function discards passed wMsgFilterMin and wMsgFilterMax parameters and replaces them with WM_KEYFIRST(0x100) and WM_KEYLAST(0x109) respectively

0:  55                      push   ebp
1:  89 e5                   mov    ebp,esp
3:  57                      push   edi
4:  8b 45 18                mov    eax,DWORD PTR [ebp+0x18]
7:  50                      push   eax
8:  68 09 01 00 00          push   0x109
d:  68 00 01 00 00          push   0x100
12: 6a 00                   push   0x0
14: 8b 45 08                mov    eax,DWORD PTR [ebp+0x8]
17: 50                      push   eax
18: 8b 3d a8 53 97 00       mov    edi,DWORD PTR ds:0x9753a8
1e: ff d7                   call   edi
20: 5f                      pop    edi
21: 5d                      pop    ebp
22: c2 14 00                ret    0x14
#>
function ApplyTextInputFixes([Parameter(Mandatory = $true)] [byte[]]$bytes)
{
	"Injecting PeekMessageA function wrapper..."
	$offset = 0x00573d20
	$bytes[$offset++] = 0x55
	$bytes[$offset++] = 0x89
	$bytes[$offset++] = 0xe5
	$bytes[$offset++] = 0x57
	$bytes[$offset++] = 0x8b
	$bytes[$offset++] = 0x45
	$bytes[$offset++] = 0x18
	$bytes[$offset++] = 0x50
	$bytes[$offset++] = 0x68
	$bytes[$offset++] = 0x09
	$bytes[$offset++] = 0x01
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0x68
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0x01
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0x6a
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0x8b
	$bytes[$offset++] = 0x45
	$bytes[$offset++] = 0x08
	$bytes[$offset++] = 0x50
	$bytes[$offset++] = 0x8b
	$bytes[$offset++] = 0x3d
	$bytes[$offset++] = 0xa8
	$bytes[$offset++] = 0x53
	$bytes[$offset++] = 0x97
	$bytes[$offset++] = 0x00
	$bytes[$offset++] = 0xff
	$bytes[$offset++] = 0xd7
	$bytes[$offset++] = 0x5f
	$bytes[$offset++] = 0x5d
	$bytes[$offset++] = 0xc2
	$bytes[$offset++] = 0x14
	$bytes[$offset] = 0x00
	
	"Injecting PeekMessageA function wrapper pointer..."
	$offset = 0x00573d18
	$bytes[$offset++] = 0x20
	$bytes[$offset++] = 0x49
	$bytes[$offset++] = 0x97
	$bytes[$offset] = 0x00
	

	"Replacing PeekMessageA function addresses..."
	$offset = 0x002dfb9a
	$bytes[$offset++] = 0x18
	$bytes[$offset++] = 0x49
	$bytes[$offset++] = 0x97
	$bytes[$offset] = 0x00
}

"============================================"
"Patching TwoWorlds.exe"
"============================================"
$hash = Get-FileHash TwoWorlds.exe -Algorithm MD5
if ($hash.Hash -ne '1E7D410354B56E156DADABC3D8C2FCBC')
{
	'Invalid exe version'
	Read-Host -Prompt "Press ENTER to exit"
	throw 'Invalid exe version'
}
[byte[]]$bytes = Get-Content TwoWorlds.exe -Encoding Byte -Raw
ApplyTextInputFixes  -bytes $bytes
,$bytes |Set-Content TwoWorlds.exe -Encoding Byte
"All patched!"
Read-Host -Prompt "Press ENTER to exit"