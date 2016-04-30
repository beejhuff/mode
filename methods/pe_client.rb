# Windows related code

# Populate post install commands

def populate_pe_post_list(admin_username,admin_password,install_label,install_shell)
  post_list = []
  post_list.push("cmd.exe /c powershell -Command \"Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force\",Set Execution Policy 64 Bit,true")
  post_list.push("C:\\Windows\\SysWOW64\\cmd.exe /c powershell -Command \"Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force\",Set Execution Policy 32 Bit,true")
  if install_shell.match(/winrm/)
    post_list.push("cmd.exe /c winrm quickconfig -q,winrm quickconfig -q,true")
    post_list.push("cmd.exe /c winrm quickconfig -transport:http,winrm quickconfig -transport:http,true")
    post_list.push("cmd.exe /c winrm set winrm/config @{MaxTimeoutms=\"1800000\"},Win RM MaxTimoutms,true")
    if install_label.match(/2012|2016/)
      post_list.push("cmd.exe /c winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"800\"}',Win RM MaxMemoryPerShellMB,true")
    else
      post_list.push("cmd.exe /c winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"0\"}',Win RM MaxMemoryPerShellMB,true")
    end
    post_list.push("cmd.exe /c winrm set winrm/config/service @{AllowUnencrypted=\"true\"},Win RM AllowUnencrypted,true")
    post_list.push("cmd.exe /c winrm set winrm/config/service/auth @{Basic=\"true\"},Win RM auth Basic,true")
    post_list.push("cmd.exe /c winrm set winrm/config/client/auth @{Basic=\"true\"},Win RM client auth Basic,true")
    post_list.push("cmd.exe /c winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port=\"5985\"},Win RM listener Address/Port,true")
    post_list.push("cmd.exe /c netsh advfirewall firewall set rule group=\"remote administration\" new enable=yes,Win RM adv firewall enable,true")
    post_list.push("cmd.exe /c netsh advfirewall firewall add rule name=\"WinRM-HTTP\" dir=in localport=5985 protocol=TCP action=allow,Allow WinRM HTTP,true")
    if install_label.match(/2008/)
      post_list.push("cmd.exe /c winrm set winrm/config/winrs '@{MaxProcessesPerShell=\"0\"}',Win RM MaxProcessesPerShell,true")
    end
    post_list.push("cmd.exe /c net stop winrm,Stop Win RM Service,true")
    post_list.push("cmd.exe /c sc config winrm start= auto,Win RM Autostart,true")
    post_list.push("cmd.exe /c net start winrm,Start Win RM Service,true")
  end
  if install_shell.match(/ssh/)
    post_list.push("cmd.exe /c netsh advfirewall firewall add rule name=\"INSTALL-HTTP\" dir=out localport=8888 protocol=TCP action=allow,Allow WinRM HTTP,true")
    post_list.push("cmd.exe /c C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -File  A:\\openssh.ps1,Install OpenSSH,true")
  end
  post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\ /v HideFileExt /t REG_DWORD /d 0 /f,Show file extensions in Explorer,false")
  post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKCU\\Console /v QuickEdit /t REG_DWORD /d 1 /f,Enable QuickEdit mode,false")
  post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\ /v Start_ShowRun /t REG_DWORD /d 1 /f,Show Run command in Start Menu,false")
  post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\ /v StartMenuAdminTools /t REG_DWORD /d 1 /f,Show Administrative Tools in Start Menu,false")
  post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKLM\\SYSTEM\\CurrentControlSet\\Control\\Power\\ /v HibernateFileSizePercent /t REG_DWORD /d 0 /f,Zero Hibernation File,false")
  post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKLM\\SYSTEM\\CurrentControlSet\\Control\\Power\\ /v HibernateEnabled /t REG_DWORD /d 0 /f,Zero Hibernation File,false")
  if install_label.match(/2012|2016/)
    post_list.push("cmd.exe /c reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Network\\NewNetworkWindowOff\",Turn off Network Location Wizard,false")
    post_list.push("%SystemRoot%\\System32\\reg.exe ADD HKLM\\SYSTEM\\CurrentControlSet\\Control\\Network\\NetworkLocationWizard\\ /t REG_DWORD /d 1 /f,Hide Network Wizard,false")
  end
  post_list.push("cmd.exe /c net user #{admin_username} #{admin_password},Set #{admin_username} password,true")
  post_list.push("cmd.exe /c wmic useraccount where \"name='#{admin_username}'\" set PasswordExpires=FALSE,Disable password expiration for #{admin_username} user,false")
  return post_list
end

# Create Autounattend.xml
def output_pe_client_profile(install_client,install_ip,install_mac,output_file,install_service,install_type,install_label,install_license,install_shell)
  xml_output      = []
  command          = ""
  description      = ""
  userinput        = ""
  counter         = 1
  number          = ""
  locale          = $q_struct["locale"].value
  timezone        = $q_struct["timezone"].value
  boot_disk_size  = $q_struct["boot_disk_size"].value
  admin_fullname  = $q_struct["admin_fullname"].value
  admin_username  = $q_struct["admin_username"].value
  admin_password  = $q_struct["admin_password"].value
  organisation    = $q_struct["organisation"].value
  cpu_arch        = $q_struct["cpu_arch"].value
  install_license = $q_struct["license_key"].value
  install_network = $q_struct["network_type"].value
  if install_network.match(/hostonly|bridged/)
    network_name    = $q_struct["network_name"].value
    network_cidr    = $q_struct["network_cidr"].value
    network_ip      = $q_struct["ip_address"].value
    gateway_ip      = $q_struct["gateway_address"].value
    nameserver_ip   = $q_struct["nameserver_ip"].value
    search_domain   = $q_struct["search_domain"].value
  end
  # Put in some Microsoft Eval Keys if no license specified
  if !install_license.match(/[0-9]/)
    if install_label.match(/2008/)
      install_license = "YC6KT-GKW9T-YTKYR-T4X34-R7VHC"
    else
      install_license = "D2N9P-3P6X9-2R39C-7RTCD-MDVJX"
    end
  end
  post_list = populate_pe_post_list(admin_username,admin_password,install_label,install_shell)
  xml       = Builder::XmlMarkup.new(:target => xml_output, :indent => 2)
  xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  xml.unattend(:xmlns => "urn:schemas-microsoft-com:unattend") {
    if install_label.match(/2012|2016/)
      xml.settings(:pass => "windowsPE") {
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-International-Core-WinPE", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.SetupUILanguage {
            xml.UILanguage("#{locale}")
          }
          xml.InputLocale("#{locale}")
          xml.SystemLocale("#{locale}")
          xml.UILanguage("#{locale}")
          xml.UILanguageFallback("#{locale}")
          xml.UserLocale("#{locale}")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Setup", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.DiskConfiguration {
            xml.Disk(:"wcm:action" => "add") {
              xml.CreatePartitions {
                xml.CreatePartition(:"wcm:action" => "add") {
                  xml.Type("Primary")
                  xml.Order("1")
                  xml.Size("#{boot_disk_size}")
                }
                xml.CreatePartition(:"wcm:action" => "add") {
                  xml.Order("2")
                  xml.Type("Primary")
                  xml.Extend("true")
                }
              }
              xml.ModifyPartitions {
                xml.ModifyPartition(:"wcm:action" => "add") {
                  xml.Active("true")
                  xml.Format("NTFS")
                  xml.Label("boot")
                  xml.Order("1")
                  xml.PartitionID("1")
                }
                xml.ModifyPartition(:"wcm:action" => "add") {
                  xml.Format("NTFS")
                  xml.Label("Windows")
                  xml.Letter("C")
                  xml.Order("2")
                  xml.PartitionID("2")
                }
              }
              xml.DiskID("0")
              xml.WillWipeDisk("true")
            }
          }
          xml.ImageInstall {
            xml.OSImage {
              xml.InstallFrom {
                xml.MetaData(:"wcm:action" => "add") {
                  xml.Key("/IMAGE/NAME")
                  xml.Value("#{install_label}")
                }
              }
              xml.InstallTo {
                xml.DiskID("0")
                xml.PartitionID("2")
              }
            }
          }
          xml.UserData {
            xml.ProductKey {
              xml.Key("#{install_license}")
              xml.WillShowUI("Never")
            }
            xml.AcceptEula("true")
            xml.FullName("#{admin_fullname}")
            xml.Organization("#{organisation}")
          }
        }
      }
      xml.settings(:pass => "specialize") {
        if install_network.match(/hostonly|bridged/)
          if network_ip.match(/[0-9]/)
            xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-TCPIP", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
              xml.Interfaces {
                xml.Interface(:"wcm:action" => "add") {
                  xml.Ipv4Settings {
                    xml.DhcpEnabled("false")
                  }
                  xml.Identifier("#{network_name}")
                  xml.UnicastIpAddresses {
                    xml.IpAddress("#{network_ip}#{$default_cidr}", :"wcm:action" => "add", :"wcm:keyValue" => "1")
                  }
                  xml.Routes {
                    xml.Route(:"wcm:action" => "add") {
                      xml.Identifier("0")
                      xml.Prefix("0.0.0.0/0")
                      xml.Metric("20")
                      xml.NextHopAddress("#{gateway_ip}")
                    }
                  }
                }
              }
            }
          end
        end
        if install_network.match(/hostonly|bridged/)
          if nameserver_ip.match(/[0-9]/)
            xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-DNS-Client", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
              xml.Interfaces {
                xml.Interface(:"wcm:action" => "add") {
                  xml.DNSServerSearchOrder {
                    xml.IpAddress("#{nameserver_ip}", :"wcm:action" => "add", :"wcm:keyValue" => "1")
                  }
                  xml.Identifier("#{network_name}")
                  xml.EnableAdapterDomainNameRegistration("false")
                  xml.DNSDomain("#{search_domain}")
                  xml.DisableDynamicUpdate("false")
                }
              }
              xml.UseDomainNameDevolution("false")
              xml.DNSDomain("#{search_domain}")
            }
          end
        end
        xml.component(:name => "Microsoft-Windows-Shell-Setup", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.OEMInformation {
            xml.HelpCustomized("false")
          }
          xml.ComputerName("#{install_client}")
          xml.TimeZone("#{timezone}")
          xml.RegisteredOwner
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-ServerManager-SvrMgrNc", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.DoNotOpenServerManagerAtLogon("true")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-IE-ESC", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.IEHardenAdmin("false")
          xml.IEHardenUser("false")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-OutOfBoxExperience", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.DoNotOpenInitialConfigurationTasksAtLogon("true")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Security-SPP-UX", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.SkipAutoActivation("true")
        }
      }
      xml.settings(:pass => "oobeSystem") {
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Shell-Setup", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.UserAccounts {
            xml.AdministratorPassword {
              xml.Value("#{admin_username}")
              xml.PlainText("true")
            }
            xml.LocalAccounts {
              xml.LocalAccount(:"wcm:action" => "add") {
                xml.Password {
                  xml.Value("#{admin_password}")
                  xml.PlainText("true")
                }
                xml.DisplayName("#{admin_fullname}")
                xml.Description("#{admin_fullname} User")
                xml.Group("administrators")
                xml.Name("#{admin_username}")
              }
            }
          }
          xml.OOBE {
            xml.HideEULAPage("true")
            xml.HideLocalAccountScreen("true")
            xml.HideOEMRegistrationScreen("true")
            xml.HideOnlineAccountScreens("true")
            xml.HideWirelessSetupInOOBE("true")
            xml.NetworkLocation("Home")
            xml.ProtectYourPC("1")
          }
          xml.AutoLogon {
            xml.Password {
              xml.Value("#{admin_password}")
              xml.PlainText("true")
            }
            xml.Username("#{admin_username}")
            xml.Enabled("true")
          }
          xml.FirstLogonCommands {
            post_list.each do |item|
              (command,description,userinput) = item.split(/\,/)
              xml.SynchronousCommand(:"wcm:action" => "add") {
                xml.CommandLine("#{command}")
                xml.Description("#{description}")
                number = counter.to_s
                xml.Order("#{number}")
                counter = counter+1
                if userinput.match(/true/)
                  xml.RequiresUserInput("true")
                end
              }
            end
          }
        }
      }
      xml.settings(:pass => "offlineServicing") {
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-LUA-Settings", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.EnableLUA("false")
        }
      }
      xml.tag!(:"cpi:offlineImage", :"xmlns:cpi" => "urn:schemas-microsoft-com:cpi", :"cpi:source" => "catalog:d:/sources/install_#{install_label.downcase}.clg")
    end
    if install_label.match(/2008/)
      xml.servicing
      xml.settings(:pass => "windowsPE") {
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Setup", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.DiskConfiguration {
            xml.Disk(:"wcm:action" => "add") {
              xml.CreatePartitions {
                xml.CreatePartition(:"wcm:action" => "add") {
                  xml.Order("1")
                  xml.Type("Primary")
                  xml.Extend("true")
                }
              }
              xml.ModifyPartitions {
                xml.ModifyPartition(:"wcm:action" => "add") {
                  xml.Active("false")
                  xml.Format("NTFS")
                  xml.Letter("C")
                  xml.Order("1")
                  xml.PartitionID("1")
                  xml.Label("Windows")
                }
              }
              xml.DiskID("0")
              xml.WillWipeDisk("true")
            }
            xml.WillShowUI("OnError")
          }
          xml.UserData {
            xml.AcceptEula("true")
            xml.FullName("#{admin_fullname}")
            xml.Organization("#{organisation}")
            xml.ProductKey {
              xml.Key("#{install_license}")
              xml.WillShowUI("Never")
            }
          }
          xml.ImageInstall {
            xml.OSImage {
              xml.InstallTo {
                xml.DiskID("0")
                xml.PartitionID("1")
              }
              xml.WillShowUI("OnError")
              xml.InstallToAvailablePartition("false")
              xml.InstallFrom {
                xml.MetaData(:"wcm:action" => "add") {
                  xml.Key("/IMAGE/NAME")
                  xml.Value("#{install_label}")
                }
              }
            }
          }
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-International-Core-WinPE", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.SetupUILanguage {
            xml.UILanguage("#{locale}")
          }
          xml.InputLocale("#{locale}")
          xml.SystemLocale("#{locale}")
          xml.UILanguage("#{locale}")
          xml.UILanguageFallback("#{locale}")
          xml.UserLocale("#{locale}")
        }
      }
      xml.settings(:pass => "offlineServicing") {
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-LUA-Settings", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.EnableLUA("false")
        }
      }
      xml.settings(:pass => "oobeSystem") {
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Shell-Setup", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.UserAccounts {
            xml.AdministratorPassword {
              xml.Value("#{admin_username}")
              xml.PlainText("true")
            }
            xml.LocalAccounts {
              xml.LocalAccount(:"wcm:action" => "add") {
                xml.Password {
                  xml.Value("#{admin_password}")
                  xml.PlainText("true")
                }
                xml.DisplayName("#{admin_fullname}")
                xml.Description("#{admin_fullname} User")
                xml.Group("administrators")
                xml.Name("#{admin_username}")
              }
            }
          }
          xml.OOBE {
            xml.HideEULAPage("true")
            xml.HideWirelessSetupInOOBE("true")
            xml.NetworkLocation("Home")
          }
          xml.AutoLogon {
            xml.Password {
              xml.Value("#{admin_password}")
              xml.PlainText("true")
            }
            xml.Username("#{admin_username}")
            xml.Enabled("true")
          }
          xml.FirstLogonCommands {
            post_list.each do |item|
              (command,description,userinput) = item.split(/\,/)
              xml.SynchronousCommand(:"wcm:action" => "add") {
                xml.CommandLine("#{command}")
                xml.Description("#{description}")
                number = counter.to_s
                xml.Order("#{number}")
                counter = counter+1
                if userinput.match(/true/)
                  xml.RequiresUserInput("true")
                end
              }
            end
          }
        }
      }
      xml.settings(:pass => "specialize") {
        if install_network.match(/hostonly|bridged/)
          if network_ip.match(/[0-9]/)
            xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-TCPIP", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
              xml.Interfaces {
                xml.Interface(:"wcm:action" => "add") {
                  xml.Ipv4Settings {
                    xml.DhcpEnabled("false")
                  }
                  xml.Identifier("#{network_name}")
                  xml.UnicastIpAddresses {
                    xml.IpAddress("#{network_ip}#{$default_cidr}", :"wcm:action" => "add", :"wcm:keyValue" => "1")
                  }
                  xml.Routes {
                    xml.Route(:"wcm:action" => "add") {
                      xml.Identifier("0")
                      xml.Prefix("0.0.0.0/0")
                      xml.Metric("20")
                      xml.NextHopAddress("#{gateway_ip}")
                    }
                  }
                }
              }
            }
          end
        end
        if install_network.match(/hostonly|bridged/)
          if nameserver_ip.match(/[0-9]/)
            xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-DNS-Client", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
              xml.Interfaces {
                xml.Interface(:"wcm:action" => "add") {
                  xml.DNSServerSearchOrder {
                    xml.IpAddress("#{nameserver_ip}", :"wcm:action" => "add", :"wcm:keyValue" => "1")
                  }
                  xml.Identifier("#{network_name}")
                  xml.EnableAdapterDomainNameRegistration("false")
                  xml.DNSDomain("#{search_domain}")
                  xml.DisableDynamicUpdate("false")
                }
              }
              xml.UseDomainNameDevolution("false")
              xml.DNSDomain("#{search_domain}")
            }
          end
        end
        xml.component(:name => "Microsoft-Windows-Shell-Setup", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.OEMInformation {
            xml.HelpCustomized("false")
          }
          xml.ComputerName("#{install_client}")
          xml.TimeZone("#{timezone}")
          xml.RegisteredOwner
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-ServerManager-SvrMgrNc", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.DoNotOpenServerManagerAtLogon("true")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-IE-ESC", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.IEHardenAdmin("false")
          xml.IEHardenUser("false")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-OutOfBoxExperience", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.DoNotOpenInitialConfigurationTasksAtLogon("true")
        }
        xml.component(:"xmlns:wcm" => "http://schemas.microsoft.com/WMIConfig/2002/State", :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", :name => "Microsoft-Windows-Security-SPP-UX", :processorArchitecture => "#{cpu_arch}", :publicKeyToken => "31bf3856ad364e35", :language => "neutral", :versionScope => "nonSxS") {
          xml.SkipAutoActivation("true")
        }
      }
      xml.tag!(:"cpi:offlineImage", :"xmlns:cpi" => "urn:schemas-microsoft-com:cpi", :"cpi:source" => "catalog:d:/sources/install_#{install_label.downcase}.clg")
    end
  }
  file = File.open(output_file,"w")
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Information:\tValidating Windows configuration for "+install_client
  command = "xmllint #{output_file}"
  execute_command(message,command)
  return
end

# Populate Windows winrm powershell script

def populate_winrm_psh()
  winrm_psh = []
  winrm_psh.push("netsh advfirewall firewall set rule group=\"remote administration\" new enable=yes")
  winrm_psh.push("netsh advfirewall firewall add rule name=\"Open Port 5985\" dir=in action=allow protocol=TCP localport=5985")
  winrm_psh.push("")
  winrm_psh.push("winrm quickconfig -q")
  winrm_psh.push("winrm quickconfig -transport:http")
  winrm_psh.push("winrm set winrm/config '@{MaxTimeoutms=\"7200000\"}'")
  winrm_psh.push("winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"0\"}'")
  winrm_psh.push("winrm set winrm/config/winrs '@{MaxProcessesPerShell=\"0\"}'")
  winrm_psh.push("winrm set winrm/config/winrs '@{MaxShellsPerUser=\"0\"}'")
  winrm_psh.push("winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'")
  winrm_psh.push("winrm set winrm/config/service/auth '@{Basic=\"true\"}'")
  winrm_psh.push("winrm set winrm/config/client/auth '@{Basic=\"true\"}'")
  winrm_psh.push("")
  winrm_psh.push("net stop winrm")
  winrm_psh.push("sc.exe config winrm start= auto")
  winrm_psh.push("net start winrm")
  return winrm_psh
end

# Populate Windows OpenSSH powershell script

def populate_openssh_psh()
  openssh_psh = []
  openssh_psh.push("")
  return openssh_psh
end

# Output Windows winrm powershell script

def output_psh(install_client,output_psh,output_file)
  file = File.open(output_file,"a")
  output_psh.each do |item|
    line = item+"\n"
    file.write(line)
  end
  file.close
  if $verbose_mode == 1
    message = "Information:\tContents of Windows powershell file: "+output_file+" for: "+install_client
    command = "cat #{output_file}"
    execute_command(message,command)
  end
  return
end
