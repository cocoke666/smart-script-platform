# ============================================================
# 端到端联调脚本（真实 MySQL + 真实 HTTP）
#
# 前置条件：
#   1) MySQL 已建库：mysql -uroot -p < src/main/resources/db/schema.sql
#   2) 服务已启动：java -jar target/auth-server-1.0.0.jar --spring.profiles.active=dev
#      并把输出写入本脚本的 -LogPath（开发环境 MockSmsProvider 会把验证码打印到日志）
#
# 用法：powershell -File scripts/verify-e2e.ps1
#       （Windows PowerShell 5.1 与 PowerShell 7 均可；脚本以 UTF-8 BOM 保存，避免 5.1 按 ANSI 解析中文）
# ============================================================
param(
    [string]$BaseUrl = 'http://127.0.0.1:8080',
    [string]$LogPath = (Join-Path $PSScriptRoot '..\server_run.log'),
    [string]$MysqlExe = 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe',
    [string]$DbPassword = '123456',
    [int]$CooldownWaitSeconds = 61
)

$ErrorActionPreference = 'Stop'
$script:failures = 0

Add-Type -AssemblyName System.Net.Http
$script:http = New-Object System.Net.Http.HttpClient
$script:http.Timeout = [TimeSpan]::FromSeconds(30)

function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) {
        Write-Host ("  [PASS] {0}" -f $name) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] {0} {1}" -f $name, $detail) -ForegroundColor Red
        $script:failures++
    }
}

# 统一请求：无论 2xx 还是 4xx/5xx 都能拿到状态码与响应体
# （不用 Invoke-WebRequest：Windows PowerShell 5.1 下它读不到错误响应的响应体）
function Call([string]$method, [string]$path, $body = $null, [string]$token = $null) {
    $httpMethod = if ($method -eq 'GET') { [System.Net.Http.HttpMethod]::Get } else { [System.Net.Http.HttpMethod]::Post }
    $request = New-Object System.Net.Http.HttpRequestMessage($httpMethod, "$BaseUrl$path")
    if ($token) { $request.Headers.Add('Authorization', "Bearer $token") }
    if ($null -ne $body) {
        $json = $body | ConvertTo-Json -Compress
        $request.Content = New-Object System.Net.Http.StringContent(
            $json, [System.Text.Encoding]::UTF8, 'application/json')
    }
    $response = $script:http.SendAsync($request).Result
    $content = $response.Content.ReadAsStringAsync().Result
    $json = $null
    if ($content) { $json = $content | ConvertFrom-Json }
    return [pscustomobject]@{
        Status  = [int]$response.StatusCode
        Code    = if ($json) { $json.code } else { $null }
        Message = if ($json) { $json.message } else { $null }
        Data    = if ($json) { $json.data } else { $null }
        Raw     = $content
    }
}

# 开发环境 MockSmsProvider 会把验证码打印到服务端日志。
# 注意：Java 输出经控制台编码转换后中文可能变成乱码，因此这里只依据 ASCII 片段
# （[mock-sms] 标记 + 场景名）定位日志行，并取该行最后一个数字串作为验证码。
function Get-SmsLines([string]$scene) {
    if (-not (Test-Path $LogPath)) { return [string[]]@() }
    $content = Get-Content $LogPath -Raw -Encoding Default
    $matched = $content -split "`r?`n" | Where-Object {
        $_.Contains('[mock-sms]') -and $_ -like "*$scene*"
    }
    return [string[]]@($matched)
}

function Get-LastSmsCode([string]$line) {
    $runs = [regex]::Matches($line, '\d+')
    if ($runs.Count -eq 0) { return $null }
    return $runs[$runs.Count - 1].Value
}

function Wait-SmsCode([string]$scene, [int]$knownCount) {
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 500
        # 必须显式转成数组：只有一行时 PowerShell 会把单元素数组解包成字符串，
        # 那样 $lines[0] 取到的是第一个字符，验证码就会变成 1 位数字。
        $lines = [string[]]@(Get-SmsLines $scene)
        if ($lines.Count -gt $knownCount) {
            return Get-LastSmsCode $lines[$lines.Count - 1]
        }
    }
    throw "未能从日志中取到 $scene 场景的验证码（请确认服务日志写入了 $LogPath）"
}

function Count-SmsLog([string]$scene) {
    return ([string[]]@(Get-SmsLines $scene)).Count
}

# 用 MYSQL_PWD 传递口令，避免命令行告警干扰输出
function Query-Db([string]$sql) {
    $env:MYSQL_PWD = $DbPassword
    $result = & $MysqlExe -uroot -N -B -e "use script_platform; $sql" 2>$null
    return ("$result").Trim()
}

$phone = '138' + (Get-Random -Minimum 10000000 -Maximum 99999999)
$phone2 = '139' + (Get-Random -Minimum 10000000 -Maximum 99999999)
$masked = $phone.Substring(0, 3) + '****' + $phone.Substring(7)
$deviceId = 'e2e-script'

Write-Host "`n== 1. 发送验证码（LOGIN） ==" -ForegroundColor Cyan
$sendLog = Count-SmsLog 'LOGIN'
$r = Call POST '/api/v1/auth/sms/send' @{ phone = $phone; scene = 'LOGIN' }
Check '响应 code=0' ($r.Code -eq 0) "→ $($r.Code) $($r.Message)"
Check 'HTTP 200' ($r.Status -eq 200) "→ $($r.Status)"
Check '返回 requestId' (-not [string]::IsNullOrEmpty($r.Data.requestId))
Check '返回 cooldownSeconds=60' ($r.Data.cooldownSeconds -eq 60) "→ $($r.Data.cooldownSeconds)"
$code = Wait-SmsCode 'LOGIN' $sendLog
Check '响应体不含验证码明文' ($r.Raw -notlike "*$code*")

Write-Host "`n== 2. 手机号冷却（60 秒内重复发送） ==" -ForegroundColor Cyan
$r2 = Call POST '/api/v1/auth/sms/send' @{ phone = $phone; scene = 'LOGIN' }
Check '重复发送返回 1002' ($r2.Code -eq 1002) "→ $($r2.Code)"
Check 'HTTP 429' ($r2.Status -eq 429) "→ $($r2.Status)"

Write-Host "`n== 3. 验证码登录（新手机号自动注册） ==" -ForegroundColor Cyan
$login = Call POST '/api/v1/auth/sms/login' @{
    phone = $phone; code = $code; agreementVersion = '1.0'; deviceId = $deviceId; deviceName = 'e2e'
}
Check '登录成功' ($login.Code -eq 0) "→ $($login.Code) $($login.Message)"
Check 'isNewUser=true（自动注册）' ($login.Data.isNewUser -eq $true)
Check 'tokenType=Bearer' ($login.Data.tokenType -eq 'Bearer')
Check 'expiresIn=7200' ($login.Data.expiresIn -eq 7200) "→ $($login.Data.expiresIn)"
Check '手机号已脱敏' ($login.Data.user.phone -eq $masked) "→ $($login.Data.user.phone)"
Check '响应不含完整手机号' ($login.Raw -notlike "*$phone*")
Check '响应不含 passwordHash' ($login.Raw -notlike '*passwordHash*')
Check '默认昵称已生成' ($login.Data.user.nickname -like '用户_*') "→ $($login.Data.user.nickname)"
$access = $login.Data.accessToken
$refresh = $login.Data.refreshToken

Write-Host "`n== 4. Token 鉴权（/me） ==" -ForegroundColor Cyan
$me = Call GET '/api/v1/auth/me' $null $access
Check '/me 成功' ($me.Code -eq 0) "→ $($me.Code)"
Check '返回脱敏手机号' ($me.Data.phone -eq $masked)

Write-Host "`n== 5. 未登录与协议校验 ==" -ForegroundColor Cyan
$noToken = Call GET '/api/v1/auth/me'
Check '无 Token 返回 1014' ($noToken.Code -eq 1014) "→ $($noToken.Code) $($noToken.Message)"
Check 'HTTP 401' ($noToken.Status -eq 401) "→ $($noToken.Status)"
Check '错误响应也是统一结构' ($noToken.Raw -like '*"data":null*') "→ $($noToken.Raw)"

$sendLog2 = Count-SmsLog 'LOGIN'
$r3 = Call POST '/api/v1/auth/sms/send' @{ phone = $phone2; scene = 'LOGIN' }
$code2 = Wait-SmsCode 'LOGIN' $sendLog2
$badAgreement = Call POST '/api/v1/auth/sms/login' @{
    phone = $phone2; code = $code2; agreementVersion = '0.9'
}
Check '协议版本不符返回 1013' ($badAgreement.Code -eq 1013) "→ $($badAgreement.Code)"

Write-Host "`n== 6. 错误验证码 ==" -ForegroundColor Cyan
$wrongCode = Call POST '/api/v1/auth/sms/login' @{
    phone = $phone2; code = '000000'; agreementVersion = '1.0'
}
Check '错误验证码返回 1003' ($wrongCode.Code -eq 1003) "→ $($wrongCode.Code)"

Write-Host "`n== 7. Refresh Token 轮换与重放保护 ==" -ForegroundColor Cyan
$refreshed = Call POST '/api/v1/auth/token/refresh' @{ refreshToken = $refresh; deviceId = $deviceId }
Check '刷新成功' ($refreshed.Code -eq 0) "→ $($refreshed.Code) $($refreshed.Message)"
Check '签发了新的 refreshToken' ($refreshed.Data.refreshToken -ne $refresh)
Check '新的 accessToken 可用' ((Call GET '/api/v1/auth/me' $null $refreshed.Data.accessToken).Code -eq 0)
$replay = Call POST '/api/v1/auth/token/refresh' @{ refreshToken = $refresh }
Check '旧 refreshToken 重放被拒（1012）' ($replay.Code -eq 1012) "→ $($replay.Code)"
Check '重放后新 refreshToken 也失效（整用户撤销）' `
    ((Call POST '/api/v1/auth/token/refresh' @{ refreshToken = $refreshed.Data.refreshToken }).Code -eq 1012)

Write-Host "`n== 8. 设置密码（按 Token 解析手机号）与密码登录 ==" -ForegroundColor Cyan
# 重新登录拿一对新令牌（上一步已把会话全部撤销）
$sendLog3 = Count-SmsLog 'LOGIN'
Write-Host "  等待 $CooldownWaitSeconds 秒，验证真实 60 秒冷却逻辑..." -ForegroundColor DarkGray
Start-Sleep -Seconds $CooldownWaitSeconds
Call POST '/api/v1/auth/sms/send' @{ phone = $phone; scene = 'LOGIN' } | Out-Null
$code3 = Wait-SmsCode 'LOGIN' $sendLog3
$login2 = Call POST '/api/v1/auth/sms/login' @{
    phone = $phone; code = $code3; agreementVersion = '1.0'; deviceId = $deviceId
}
Check '冷却结束后可再次发送并登录' ($login2.Code -eq 0) "→ $($login2.Code) $($login2.Message)"
$access2 = $login2.Data.accessToken

$setLog = Count-SmsLog 'SET_PASSWORD'
$setSend = Call POST '/api/v1/auth/sms/send' @{ scene = 'SET_PASSWORD' } $access2
Check '携带 Token 且不带手机号可发送验证码' ($setSend.Code -eq 0) "→ $($setSend.Code) $($setSend.Message)"
$setCode = Wait-SmsCode 'SET_PASSWORD' $setLog
$setPwd = Call POST '/api/v1/auth/password/set' @{ code = $setCode; password = 'Abcd1234' } $access2
Check '设置密码成功' ($setPwd.Code -eq 0) "→ $($setPwd.Code) $($setPwd.Message)"
Check '/me 显示 hasPassword=true' ((Call GET '/api/v1/auth/me' $null $access2).Data.hasPassword -eq $true)
$pwdLogin = Call POST '/api/v1/auth/password/login' @{ phone = $phone; password = 'Abcd1234'; deviceId = $deviceId }
Check '账号密码登录成功' ($pwdLogin.Code -eq 0) "→ $($pwdLogin.Code) $($pwdLogin.Message)"
$pwdWrong = Call POST '/api/v1/auth/password/login' @{ phone = $phone; password = 'Wrong1234' }
Check '密码错误返回 1008' ($pwdWrong.Code -eq 1008) "→ $($pwdWrong.Code)"

Write-Host "`n== 9. 退出登录后 Refresh Token 失效 ==" -ForegroundColor Cyan
$access3 = $pwdLogin.Data.accessToken
$refresh3 = $pwdLogin.Data.refreshToken
$logout = Call POST '/api/v1/auth/logout' @{ refreshToken = $refresh3 } $access3
Check '退出登录成功' ($logout.Code -eq 0) "→ $($logout.Code) $($logout.Message)"
Check '退出后 refreshToken 不可用（1012）' `
    ((Call POST '/api/v1/auth/token/refresh' @{ refreshToken = $refresh3 }).Code -eq 1012)

Write-Host "`n== 10. 微信/QQ 入口预留 ==" -ForegroundColor Cyan
$oauth = Call POST '/api/v1/auth/oauth/wechat/login' @{ authCode = 'dummy'; deviceId = $deviceId }
Check '返回 1018 未开放' ($oauth.Code -eq 1018) "→ $($oauth.Code)"
Check 'HTTP 501' ($oauth.Status -eq 501) "→ $($oauth.Status)"

Write-Host "`n== 11. 数据库落库检查 ==" -ForegroundColor Cyan
$userCount = Query-Db "select count(*) from user where phone='$phone'"
Check '用户表只有 1 条该手机号记录' ($userCount -eq '1') "→ $userCount"

$hash = Query-Db "select left(password_hash,4) from user where phone='$phone'"
Check '密码以 BCrypt 保存' ($hash -like '$2*') "→ $hash"

$consent = Query-Db "select count(*) from user_consent_log where user_id=(select id from user where phone='$phone')"
Check '协议留痕 2 条（用户协议 + 隐私政策）' ($consent -eq '2') "→ $consent"

$plain = Query-Db "select count(*) from sms_verification_code where code_hash regexp '^[0-9]{6}$'"
Check '验证码表中没有明文验证码' ($plain -eq '0') "→ $plain"

$sessionRevoked = Query-Db "select count(*) from user_refresh_token where revoked_at is null and user_id=(select id from user where phone='$phone')"
Check '退出登录后该用户无有效会话' ($sessionRevoked -eq '0') "→ $sessionRevoked"

Write-Host ""
if ($script:failures -eq 0) {
    Write-Host "端到端联调全部通过 ✅" -ForegroundColor Green
    exit 0
}
Write-Host "存在 $($script:failures) 项失败 ❌" -ForegroundColor Red
exit 1
