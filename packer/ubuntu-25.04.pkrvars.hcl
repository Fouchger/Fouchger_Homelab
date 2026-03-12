# ================================================================
# File: packer/ubuntu-25.04.pkrvars.hcl
# Purpose:
#   Define the curated Ubuntu 25.04 Proxmox template build inputs.
#
# Notes:
#   - This file extends the curated set beyond the original upstream subset.
#   - Uses the same Ubuntu autoinstall assets as the other modern Ubuntu builds.
# ================================================================

# renovate: datasource=custom.ubuntuLinuxRelease
name           = "ubuntu-25.04-template"
iso_file       = "ubuntu-25.04-live-server-amd64.iso"
iso_url        = "https://old-releases.ubuntu.com/releases/25.04/ubuntu-25.04-live-server-amd64.iso"
iso_checksum   = "file:https://old-releases.ubuntu.com/releases/25.04/SHA256SUMS"
http_directory = "./http/ubuntu"
boot_wait      = "5s"
boot_command = [
  "c<wait> ",
  "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
  "<enter><wait>",
  "initrd /casper/initrd",
  "<enter><wait>",
  "boot",
  "<enter>"
]
provisioner = [
  "cloud-init clean",
  "rm /etc/cloud/cloud.cfg.d/*",
  "userdel --remove --force packer"
]
