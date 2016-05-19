$headers = @{}
$baseUrl = ""
$userAgent = "OktaAPIWindowsPowerShell/0.1"

# Call this before calling Okta API functions.
function Connect-Okta($token, $baseUrl) {
    $script:headers = @{"Authorization" = "SSWS $token"; "Accept" = "application/json"; "Content-Type" = "application/json"}
    $script:baseUrl = "$baseUrl/api/v1"
}

# Factor (MFA) functions - http://developer.okta.com/docs/api/resources/factors.html

function Get-OktaFactor($userid, $factorid) {
    Invoke-Method GET "/users/$userid/factors/$factorid"
}

function Get-OktaFactors($id) {
    Invoke-Method GET "/users/$id/factors"
}

# App functions - http://developer.okta.com/docs/api/resources/apps.html

function Get-OktaAppUser($appid, $userid) {
    Invoke-Method GET "/apps/$appid/users/$userid"
}

function Set-OktaAppUser($appid, $userid, $appuser) {
    Invoke-Method POST "/apps/$appid/users/$userid" $appuser
}

# User functions - http://developer.okta.com/docs/api/resources/users.html

# $user = New-OktaUser @{profile = @{login = $login; email = $email; firstName = $firstName; lastName = $lastName}}
function New-OktaUser($user, $activate = $true) {
    Invoke-Method POST "/users?activate=$activate" $user
}

function Get-OktaUser($id) {
    Invoke-Method GET "/users/$id"
}

function Get-OktaUsers($q, $filter, $limit = 200, $url = "/users?q=$q&filter=$filter&limit=$limit") {
    Invoke-PagedMethod $url
}

function Set-OktaUser($id, $user) {
# Only the profile properties specified in the request will be modified when using the POST method.
    Invoke-Method POST "/users/$id" $user
}

function Get-OktaUserGroups($id) {
    Invoke-Method GET "/users/$id/groups"
}

function Enable-OktaUser($id, $sendEmail = $true) {
    Invoke-Method POST "/users/$id/lifecycle/activate?sendEmail=$sendEmail"
}

function Disable-OktaUser($id) {
    Invoke-Method POST "/users/$id/lifecycle/deactivate"
}

function Set-OktaUserResetPassword($id, $sendEmail = $true) {
    Invoke-Method POST "/users/$id/lifecycle/reset_password?sendEmail=$sendEmail"
}

# Group functions - http://developer.okta.com/docs/api/resources/groups.html

# $group = New-OktaGroup @{profile = @{name = "a group"; description = "its description"}}
function New-OktaGroup($group) {
    Invoke-Method POST "/groups" $group
}

function Get-OktaGroup($id) {
    Invoke-Method GET "/groups/$id"
}

# $groups = Get-OktaGroups "PowerShell" 'type eq "OKTA_GROUP"'
function Get-OktaGroups($q, $filter, $limit = 200) {
    Invoke-Method GET "/groups?q=$q&filter=$filter&limit=$limit"
}

function Get-OktaGroupMember($id, $limit = 200) {
    Invoke-Method GET "/groups/$id/users?limit=$limit"
}

function Add-OktaGroupMember($groupid, $userid) {
    $noContent = Invoke-Method PUT "/groups/$groupid/users/$userid"
}

function Remove-OktaGroupMember($groupid, $userid) {
    $noContent = Invoke-Method DELETE "/groups/$groupid/users/$userid"
}

# Event functions - http://developer.okta.com/docs/api/resources/events.html

function Get-OktaEvents($startDate, $filter, $limit = 1000) {
    Invoke-Method GET "/events?startDate=$startDate&filter=$filter&limit=$limit"
}

# Core functions

function Invoke-Method($method, $path, $body) {
    $url = $baseUrl + $path
    $jsonBody = ConvertTo-Json -compress $body
    Invoke-RestMethod $url -Method $method -Headers $headers -Body $jsonBody -UserAgent $userAgent
}

function Invoke-PagedMethod($url) {
    if ($url -notMatch '^http') {$url = $baseUrl + $url}
    $response = Invoke-WebRequest $url -Method GET -Headers $headers -UserAgent $userAgent
    $links = @{}
    if ($response.Headers.Link) { # Some searches (eg List Users with Search) do not support pagination.
        foreach ($header in $response.Headers.Link.split(",")) {
            if ($header -match '<(.*)>; rel="(.*)"') {
                $links[$matches[2]] = $matches[1]
            }
        }
    }
    @{objects = ConvertFrom-Json $response.content; nextUrl = $links.next; response = $response}
}

function Get-Error($_) {
    $responseStream = $_.Exception.Response.GetResponseStream()
    $responseReader = New-Object System.IO.StreamReader($responseStream)
    $responseContent = $responseReader.ReadToEnd()
    ConvertFrom-Json $responseContent
}
