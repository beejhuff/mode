# Common Docker code

# Install docker

def install_docker()
	if $os_name.match(/Darwin/)
		if !Dir.exist?("/Applications/Docker.app")
			puts "Information:\tDocker no installed"
			puts "Download:\thttps://docs.docker.com/docker-for-mac/"
			exit
		end
	end
	return
end

# Check docker is installed

def check_docker_is_installed()
	installed = "yes"
	if $os_name.match(/Darwin/)
		[ "docker", "docker-compose", "docker-machine" ].each do |check_file|
			file_name = "/usr/local/bin/"+check_file
			if !File.exist?(file_name) and !File.symlink?(file_name)
				installed = "no"
			end
		end
	end
	if installed == "no"
		puts "Information:\tDocker not installed"
		exit
	end
	return
end

