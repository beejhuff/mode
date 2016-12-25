# Control Domain related code

# List CDom services

def list_cdom_services()
  if $os_info.match(/SunOS/)
    if $os_rel.match(/10|11/)
      if $os_info.match(/sun4v/)
        ldom_type    = "Control Domain"
        ldom_command = "ldm list |grep ^primary |awk '{print $1}'"
        list_doms(ldom_type,ldom_command)
      else
        if $verbose_mode == true
          handle_output("") 
          handle_output("Warning:\tThis service is only available on the Sun4v platform")
          handle_output("") 
        end
      end
    else
      if $verbose_mode == true
        handle_output("") 
        handle_output("Warning:\tThis service is only available on Solaris 10 or later")
        handle_output("") 
      end
    end
  else
    if $verbose_mode == true
      handle_output("") 
      handle_output("Warning:\tThis service is only available on Solaris")
      handle_output("") 
    end
  end
  return
end

def list_ldom_services()
  list_cdom_services()
  return
end

def list_gdom_services()
  return
end

# Check LDoms installed

def check_cdom_install()
  ldm_bin = "/usr/sbin/ldm"
  if !File.exists?(ldm_bin)
    if $os_rel.match(/11/)
      message = "Information:\tInstalling LDoms software"
      command = "pkg install ldomsmanager"
      execute_command(message,command)
    end
  end
  smf_service_name = "ldmd"
  enable_smf_service(smf_service_name)
  return
end

# Check LDom VCC

def check_cdom_vcc()
  message = "Information:\tChecking LDom VCC"
  command = "ldm list-services |grep 'primary-vcc'"
  output  = execute_command(message,command)
  if !output.match(/vcc/)
    message = "Information:\tEnabling VCC"
    command = "ldm add-vcc port-range=5000-5100 primary-vcc0 primary"
    execute_command(message,command)
  end
  return
end

# Check LDom VDS

def check_cdom_vds()
  message = "Information:\tChecking LDom VDS"
  command = "ldm list-services |grep 'primary-vds'"
  output  = execute_command(message,command)
  if !output.match(/vds/)
    message = "Information:\tEnabling VDS"
    command = "ldm add-vds primary-vds0 primary"
    execute_command(message,command)
  end
  return
end

# Check LDom vSwitch

def check_cdom_vsw()
  message = "Information:\tChecking LDom vSwitch"
  command = "ldm list-services |grep 'primary-vsw'"
  output  = execute_command(message,command)
  if !output.match(/vsw/)
    message = "Information:\tEnabling vSwitch"
    command = "ldm add-vsw net-dev=net0 primary-vsw0 primary"
    execute_command(message,command)
  end
  return
end

# Check LDom config

def check_cdom_config()
  message = "Information:\tChecking LDom configuration"
  command = "ldm list-config |grep 'current'"
  output  = execute_command(message,command)
  if output.match(/factory\-default/)
    config  = $q_struct["cdom_name"].value
    message = "Information:\tChecking LDom configuration "+config+" doesn't exist"
    command = "ldm list-config |grep #{config}"
    output  = execute_command(message,command)
    if output.match(/#{config}/)
      handle_output("Warning:\tLDom configuration #{config} already exists")
      exit
    end
    if $os_info.match(/T5[0-9]|T3/)
      mau     = $q_struct["cdom_mau"].value
      message = "Information:\tAllocating "+mau+"Crypto unit(s) to primary domain"
      command = "ldm set-mau #{mau} primary"
      execute_command(message,command)
    end
    vcpu    = $q_struct["cdom_vcpu"].value
    message = "Information:\tAllocating "+vcpu+"vCPU unit(s) to primary domain"
    command = "ldm set-vcpu #{vcpu} primary"
    execute_command(message,command)
    message = "Information:\tStarting reconfiguration of primary domain"
    command = "ldm start-reconf primary"
    execute_command(message,command)
    memory  = $q_struct["cdom_memory"].value
    message = "Information:\tAllocating "+memory+"to primary domain"
    command = "ldm set-memory #{memory} primary"
    execute_command(message,command)
    message = "Information:\tSaving LDom configuration of primary domain as "+config
    command = "ldm add-config #{config}"
    execute_command(message,command)
    command = "shutdown -y -g0 -i6"
    if $yes_mode == true
      message = "Warning:\tRebooting primary domain to enable settings"
      execute_command(message,command)
    else
      handle_output("Warning:\tReboot required for settings to take effect")
      handle_output("Infromation:\tExecute #{command}")
      exit
    end
  end
  return
end

# Configure LDom vntsd

def check_cdom_vntsd()
  smf_service_name = "vntsd"
  enable_smf_service(smf_service_name)
  return
end

# Configure LDom Control (primary) domain

def configure_cdom(publisher_host)
  service_name = ""
  check_dhcpd_config(publisher_host)
  populate_cdom_questions()
  process_questions(service_name)
  check_cdom_install()
  check_cdom_vcc()
  check_cdom_vds()
  check_cdom_vsw()
  check_cdom_config()
  check_cdom_vntsd()
  return
end

# Configure LDom Server (calls configure_cdom)

def configure_ldom_server(install_arch,publisher_host,publisher_port,install_service,install_file)
  configure_cdom(publisher_host)
  return
end

def configure_cdom_server(install_arch,publisher_host,publisher_port,install_service,install_file)
  configure_cdom(publisher_host)
  return
end

# Unconfigure LDom Server

def unconfigure_cdom()
  handle_output("Warning:\tCurrently unconfiguring the Control Domain must be done manually")
  exit
  return
end

def unconfigure_ldom_server()
  unconfigure_cdom()
  return
end

def unconfigure_gdom_server()
  unconfigure_cdom()
  return
end

# List LDom ISOs

def list_ldom_isos()
  return
end

def list_cdom_isos()
  return
end

def list_gdom_isos()
  return
end
