Import-Module AzureRM.KeyVault
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$response = Invoke-WebRequest -Uri 'https://macscampingarea.com' -Method Get -UseBasicParsing

if ($response.StatusCode -ne 200)
{
  $username = 'azure_4ffd1bc7f64f364a8236fc8ae4b5b70a@azure.com'
  $password = Get-AzureKeyVaultSecret -VaultName 'macscampvault' -Name 'AppSettings--SendGridPassword' | Select-Object -ExpandProperty SecretValueText | ConvertTo-SecureString -AsPlainText -Force
  $credential = New-Object System.Management.Automation.PSCredential $username, $password

  $from = 'website@macscampingarea.com'
  $to = '2063100074@msg.fi.google.com'

  $subject = 'Error On Website'
  $body = "The server is not responding! `n It reports error $($response.StatusCode) on $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')) UTC"

  $smtpServer = 'smtp.sendgrid.net'
  Send-MailMessage -From $from -To $to -Subject $subject -Body $body -Credential $credential -UseSsl -Port 587 -SmtpServer $smtpServer
}
