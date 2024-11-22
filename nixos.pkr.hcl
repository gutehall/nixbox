packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    vmware = {
      source  = "github.com/hashicorp/vmware"
      version = "~> 1"
    }
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = "~> 1"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1"
    }
     parallels = {
      version = ">= 1.1.0"
      source  = "github.com/Parallels/parallels"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

locals {
  iso_url = "https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-aarch64-linux.iso"
}

variable "hcp_client_id" {
  type    = string
  default = "${env("HCP_CLIENT_ID")}"
}

variable "hcp_client_secret" {
  type    = string
  default = "${env("HCP_CLIENT_SECRET")}"
}

variable "version" {
  type    = string
  default = "2024.11.22"
}

variable "box_tag" {
  type    = string
  default = "gutehall/nixos24-11"
}

variable "builder" {
  description = "builder"
  type        = string
  default     = "vmware-iso.vmware"
}

variable "arch" {
  description = "The system architecture of NixOS to build (Default: x86_64)"
  type        = string
  default     = "aarch64"
}

variable "iso_checksum" {
  description = "A ISO SHA256 value"
  type        = string
  default     = "910bb26c0653b788830897469e75f7bbe52afaa51f23b6e58a2a8f781fc587d7"
}

variable "disk_size" {
  type    = string
  default = "10240"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "boot_wait" {
  description = "The amount of time to wait for VM boot"
  type        = string
  default     = "120s"
}

variable "qemu_accelerator" {
  type    = string
  default = "kvm"
}

variable "cloud_repo" {
  type    = string
  default = "nixbox/nixos"
}

variable "cloud_token" {
  type    = string
  default = "${env("ATLAS_TOKEN")}"
}

variable "vagrant_cloud_arch" {
  type = map(string)
  default = {
    "i386"    = "i386"
    "x86-64"  = "amd64"
    "aarch64" = "arm64"
  }
}

source "hyperv-iso" "hyperv" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/install_ed25519.pub > .ssh/authorized_keys<enter>",
    "sudo su --<enter>", "nix-env -iA nixos.linuxPackages.hyperv-daemons<enter><wait10>",
    "$(find /nix/store -executable -iname 'hv_kvp_daemon' | head -n 1)<enter><wait10>",
    "systemctl start sshd<enter>"
  ]
  boot_wait            = var.boot_wait
  communicator         = "ssh"
  differencing_disk    = true
  disk_size            = var.disk_size
  enable_secure_boot   = false
  generation           = 1
  headless             = true
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  memory               = var.memory
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_private_key_file = "./scripts/install_ed25519"
  ssh_timeout          = "1h"
  ssh_username         = "nixos"
  switch_name          = "Default Switch"
}

source "qemu" "qemu" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/install_ed25519.pub > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
  boot_wait            = var.boot_wait
  disk_interface       = "virtio-scsi"
  disk_size            = var.disk_size
  format               = "qcow2"
  headless             = true
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  qemuargs             = [["-m", var.memory]]
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_private_key_file = "./scripts/install_ed25519"
  ssh_username         = "nixos"
}

source "qemu" "qemu-efi" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/install_ed25519.pub > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
  boot_wait            = var.boot_wait
  disk_interface       = "virtio-scsi"
  disk_size            = var.disk_size
  format               = "qcow2"
  headless             = true
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  qemuargs             = [["-m", var.memory]]
  shutdown_command     = "sudo shutdown -h now"
  machine_type         = "q35"
  ssh_port             = 22
  ssh_private_key_file = "./scripts/install_ed25519"
  ssh_username         = "nixos"
  efi_firmware_code    = "./efi_data/OVMF_CODE_4M.ms.fd"
  #efi_firmware_vars    = "./efi_data/OVMF_VARS_4M.ms.fd"
}

source "virtualbox-iso" "virtualbox" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "echo '{{ .SSHPublicKey }}' > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
  boot_wait            = "45s"
  disk_size            = var.disk_size
  format               = "ova"
  guest_additions_mode = "disable"
  guest_os_type        = "Linux_64"
  headless             = true
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_username         = "nixos"
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--memory", var.memory, "--vram", "128", "--clipboard", "bidirectional"]]
}

source "virtualbox-iso" "virtualbox-efi" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "echo '{{ .SSHPublicKey }}' > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
  boot_wait            = "55s"
  disk_size            = var.disk_size
  format               = "ova"
  guest_additions_mode = "disable"
  guest_os_type        = "Linux_64"
  headless             = true
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  iso_interface        = "sata"
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_username         = "nixos"
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--memory", var.memory, "--vram", "128", "--clipboard", "bidirectional", "--firmware", "EFI"]]
}

source "vmware-iso" "vmware" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/install_ed25519.pub > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
  boot_wait            = "45s"
  disk_size            = var.disk_size
  guest_os_type        = "Linux"
  headless             = true
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  memory               = var.memory
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_private_key_file = "./scripts/install_ed25519"
  ssh_username         = "nixos"
}

source "parallels-iso" "parallels" {
  boot_command = [
    "mkdir -m 0700 .ssh<enter>",
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/install_ed25519.pub > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>",
    "sudo systemctl status sshd<enter>"
  ]
  boot_wait            = "60s"  # Increased boot wait time
  disk_size            = var.disk_size
  guest_os_type        = "linux-2.6"
  # headless             = true
  parallels_tools_flavor = "lin-arm"
  http_directory       = "scripts"
  iso_checksum         = var.iso_checksum
  iso_url              = local.iso_url
  memory               = var.memory
  shutdown_command     = "sudo shutdown -h now"
  ssh_port             = 22
  ssh_private_key_file = "./scripts/install_ed25519"
  ssh_username         = "nixos"
}


build {
  sources = [
    "source.hyperv-iso.hyperv",
    "source.qemu.qemu",
    "source.qemu.qemu-efi",
    "source.virtualbox-iso.virtualbox",
    "source.virtualbox-iso.virtualbox-efi",
    "source.vmware-iso.vmware",
    "source.parallels-iso.parallels"
  ]

  provisioner "shell" {
    execute_command = "sudo su -c '{{ .Vars }} {{ .Path }}'"
    script          = "./scripts/install.sh"
  }

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = false
      only                = ["virtualbox-iso.virtualbox", "qemu.qemu", "hyperv-iso.hyperv", "virtualbox-iso.virtualbox-efi", "qemu.qemu-efi", "parallels-iso.parallels"]
      output              = "nixos-${var.version}.box"
    }

    post-processor "vagrant-registry" {
      client_id        = "${var.hcp_client_id}"
      client_secret    = "${var.hcp_client_secret}"
      box_tag          = "${var.box_tag}"
      version          = "${var.version}"
      no_release       = "true"
      no_direct_upload = "true"
    }
  }
}
