# -*- mode: ruby -*-
# vi: set ft=ruby :

$worker_name_prefix = "sparkworker"
$master_name = "sparkmaster"
$master_ip = "192.168.33.100"
$number_of_instances = 2 # Script requires this to be strictly less than 10

def workername(i)
  workername = "%s-%02d" % [$worker_name_prefix, i]
  return workername
end 

def appendToSparkEnvFileCmd(s)
  return "echo '%s' >> $SPARK_HOME/conf/spark-env.sh" % [s]
end

Vagrant.configure(2) do |config|
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  # Names of all VMs, including the master:
  vm_names = Array.new()
  # Static IPs of all worker VMs, thus excluding the master:
  static_ips = Array.new()
  vm_names.push($master_name)
  static_ips.push($master_ip)

  (1..$number_of_instances).each do |i|
   vm_name = "%s-%02d" % [$worker_name_prefix, i]
   vm_static_ip = "192.168.33.%d" % [100 + i]
   webui_port = "808%d" % [i]
   vm_names.push(vm_name)
   static_ips.push(vm_static_ip)

   config.vm.define(vm_name) do |cfg|
    cfg.vm.box = "danielpape/spark"

    cfg.vm.hostname = vm_name
    cfg.vm.network "private_network", ip: vm_static_ip

    cfg.vm.provider :virtualbox do |vb|
      vb.name = vm_name
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nic2", "hostonly"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    #--- Place env.sh
    cfg.vm.provision "shell", 
      inline: "source .bash_profile; cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh; #{appendToSparkEnvFileCmd('SPARK_MASTER_IP=%s')}; #{appendToSparkEnvFileCmd('SPARK_LOCAL_IP=%s')}; #{appendToSparkEnvFileCmd('SPARK_WORKER_WEBUI_PORT=%s')}" % [$master_ip, vm_static_ip, webui_port],
      privileged: false
    #---
   end
  end

  config.vm.define($master_name) do |sparkmaster|
    sparkmaster.vm.box = "danielpape/spark"
    sparkmaster.vm.hostname = $master_name
    sparkmaster.vm.network "private_network", ip: $master_ip

    sparkmaster.vm.provider :virtualbox do |vb|
      vb.name = $master_name
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nic2", "hostonly"]
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    end

    #--- Adding hostnames for resolving IPs
    static_ips_with_worker_name = static_ips.each_with_index.map { |ip,i| 
      if i == 0
        [ip, $master_name]
      else 
        [ip, "sparkworker-%02d" % [i]] 
      end 
    }

    static_ips_with_worker_name.each do |ip, name|
      sparkmaster.vm.provision "shell", 
        inline: "echo '%s %s' >> /etc/hosts" % [ip, name]
    end
    #---

    #-- Configure logging; only ERROR should be logged
    cp_log4j_template_cmd = "source .bash_profile; cp $SPARK_HOME/conf/log4j.properties.template $SPARK_HOME/conf/log4j.properties"
    update_log_level = "source .bash_profile; sed -i '/log4j.rootCategory=INFO, console/c\log4j.rootCategory=ERROR, console' /home/vagrant/spark-1.6.0-bin-hadoop2.6/conf/log4j.properties"
    
    sparkmaster.vm.provision "shell", 
      inline: "#{cp_log4j_template_cmd}; #{update_log_level};",
      privileged: false
    #--

    #--- Generating and distributing public SSH key from master to slaves
    sparkmaster.vm.provision "shell",
      inline: "sudo apt-get install sshpass"
    
    sparkmaster.vm.provision "shell",
      inline: "rm -f /home/vagrant/.ssh/id_dsa*; chown -R vagrant /home/vagrant/.ssh"
    
    sparkmaster.vm.provision "shell", 
      inline: "ssh-keygen -t rsa -P '' -f /home/vagrant/.ssh/id_dsa",
      privileged: false

    sparkmaster.vm.provision "shell",
      inline: "cat /home/vagrant/.ssh/id_dsa.pub >> /home/vagrant/.ssh/authorized_keys",
      privileged: false

    static_ips.each do |ip|
      sparkmaster.vm.provision "shell", 
        inline: "sshpass -p 'vagrant' ssh-copy-id -o 'StrictHostKeyChecking no' -i /home/vagrant/.ssh/id_dsa.pub vagrant@%s 2> /dev/null" % [ip], 
        privileged: false
    end

    static_ips_with_worker_name.each do |ip, name|
      ssh_pass_ip_cmd = "sshpass -p 'vagrant' ssh-copy-id -o 'StrictHostKeyChecking no' -i /home/vagrant/.ssh/id_dsa.pub vagrant@%s 2> /dev/null" % [ip]
      ssh_pass_name_cmd = "sshpass -p 'vagrant' ssh-copy-id -o 'StrictHostKeyChecking no' -i /home/vagrant/.ssh/id_dsa.pub vagrant@%s 2> /dev/null" % [name]
      ssh_pass_both_cmd = "#{ssh_pass_ip_cmd}; #{ssh_pass_name_cmd}"
      
      sparkmaster.vm.provision "shell", 
        inline: ssh_pass_both_cmd, 
        privileged: false
    end
    #---

    #--- Add Spark workers to slaves.sh
    remove_localhost_cmd = "source .bash_profile; sed -i '/localhost/d' $SPARK_HOME/conf/slaves"
    cp_slaves_file_cmd = "source .bash_profile; cp $SPARK_HOME/conf/slaves.template $SPARK_HOME/conf/slaves"
    add_slaves_cmd = (1..$number_of_instances).map { |i| "echo '\n#{workername(i)}' >> $SPARK_HOME/conf/slaves" }.join(";")

    sparkmaster.vm.provision "shell", 
      inline: "#{cp_slaves_file_cmd}; #{remove_localhost_cmd}; #{add_slaves_cmd}",
      privileged: false
    #---

    #--- Place env.sh
    sparkmaster.vm.provision "shell", 
      inline: "source .bash_profile; cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh; #{appendToSparkEnvFileCmd('SPARK_MASTER_IP=%s')}; #{appendToSparkEnvFileCmd('SPARK_LOCAL_IP=%s')}" % [$master_ip, $master_ip],
      privileged: false
    #---

    #-- Create base directory in which Spark events are logged
    sparkmaster.vm.provision "shell",
      inline: "source .bash_profile; mkdir -p /tmp/spark-events",
      privileged: false
    #--
    end
end
