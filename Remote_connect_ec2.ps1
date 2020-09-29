#https://www.youtube.com/watch?v=BJmPvIOnwNg
### This is NOT a secure setting.
#Enable Powershell remoting
Start-Process powershell -verb runas -ArgumentList "-file fullpathofthescript"
Set-NetConnectionProfile -NetworkCategory Private #can be skipped since SkipNetworkProfileCheck is enabled dow below
Enable-PSRemoting -Force -SkipNetworkProfileCheck 
#Setting Trusted host setting to * (all instances)
#it means we can do outbound connections to any ip and it will send your CREDENTIALS!!!
Set-Item -Path WSMan:\localhost\client\TrustedHosts -Value * -Force # instead of  * put theactual IP addresses of EC2 instances


#using AWS Powershell module (should be installed prior to that and set up IAM user creds)
Set-DefaultAWSRegion -Region us-west-2 #Oregon

$InstanceList = (Get-EC2Instance).Instances.Where( { $PSItem.PublicIpAddress })


foreach ($Instance in $InstanceList) {
    #Creating and appending a property Credential to each instance
    Add-Member -InputObject $Instance -MemberType ScriptProperty -Name Credential -Value {
        #constructing prowershell credential with ec2 ip and Administrator, gettting and decrypting password and passing it into the costructor
        #so we can then use it in any other powershell commands that expect Credential object
        return  [pscredential]::new(($this.PublicIpAddress + '\Administrator'), (ConvertTo-SecureString -AsPlainText -Force -String(Get-EC2PasswordData -InstanceId $this.InstanceId -Decrypt -PemFile "$Home/Downloads/Windows.pem")))
    }
    Add-Member -InputObject $Instance -MemberType ScriptProperty -Name RemoteSession -Value {
        #check if PSSession exist
        $ThisSession = Get-PSSession -Name $this.Instanceid -ErrorAction Ignore
        #if exist return it from cash rather then create a new session
        if ($ThisSession) { return $ThisSession }
        else { return New-PSSession -ComputerName $this.PublicIpAddress -Credential $this.Credential -Name $this.InstanceId }
    }
}
#going to each instance and try to retrieve a session
$InstanceList.RemoteSession

#make sure SSM sent command to siable Windows Firewall
# Now we can run blocks of code on those machines 
Invoke-Command -Session $InstanceList.RemoteSession -ScriptBlock { $env:ComputerName } #Get a CompName

#Find last boot time 
Invoke-Command -Session $InstanceList.RemoteSession -ScriptBlock { (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootupTime }
###################################################################################################################################
Enter-PSSession -ComputerName $InstanceList