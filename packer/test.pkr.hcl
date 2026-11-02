packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

source "virtualbox-iso" "basic-example" {
  guest_os_type    = "Ubuntu_64"
  memory           = 2048
  cpus             = 2
  iso_url          = "https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso"
  iso_checksum     = "file:https://releases.ubuntu.com/24.04/SHA256SUMS"
  ssh_username     = "packer"
  ssh_password     = "packer"
  ssh_timeout      = "30m"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  http_content = {
    "/user-data" = file("${path.root}/http/user-data.yaml")
    "/meta-data" = file("${path.root}/http/meta-data.yaml")
  }
  boot_wait = "10s"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
}

build {
  sources = ["sources.virtualbox-iso.basic-example"]

  provisioner "shell" {
    inline = [
      "printf 'packer\\n' | sudo -S -p '' sh -c \"echo 'packer ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/packer\"",
      "printf 'packer\\n' | sudo -S -p '' chmod 0440 /etc/sudoers.d/packer",
      "sudo visudo -cf /etc/sudoers.d/packer"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output   = "ubuntu-base.box"
      provider_override = "virtualbox"
    }
  }
}
