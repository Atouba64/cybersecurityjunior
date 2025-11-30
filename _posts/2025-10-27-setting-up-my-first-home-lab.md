---
title: Setting Up My First Home Lab
date: 2025-10-27
categories: [Home Lab]
tags: [homelab, virtualization, proxmox, cybersecurity]
---

This is it! The first major step in my hands-on learning journey. Building a home lab felt incredibly intimidating, but I decided to just dive in. My main goal was to create a sandboxed environment where I could practice offensive and defensive techniques without, you know, breaking the law or my own network.

## My Goals for the Lab

I wanted to keep it simple and budget-friendly. My primary objectives were:

- Learn virtualization (I chose Proxmox)
- Understand network segmentation (using pfSense)
- Build a basic Active Directory environment (a classic target)
- Deploy a vulnerable machine to attack (like Metasploitable)

## The Hardware

You don't need a massive server rack! I started with an old desktop PC I had lying around.

- **Model:** Old Dell OptiPlex
- **CPU:** Intel i5 (8th Gen)
- **RAM:** 16GB (I did upgrade this, cost about $40)
- **Storage:** 500GB SSD

## The Software Stack

Here's what I installed and why:

### Proxmox VE
The hypervisor that runs everything. Free, powerful, and perfect for learning.

### pfSense
Firewall and router. Essential for network segmentation and security testing.

### Windows Server 2019
For Active Directory. The bread and butter of enterprise environments.

### Metasploitable 3
Intentionally vulnerable Linux box for practicing attacks safely.

## Network Architecture

I created three separate VLANs:

- **Management VLAN:** For accessing Proxmox and pfSense
- **Lab VLAN:** Where my vulnerable machines live
- **Attacker VLAN:** Where I run my Kali Linux VM

## Lessons Learned

This project taught me more than I expected:

- Virtualization concepts and resource allocation
- Network fundamentals and VLAN configuration
- Firewall rules and network security
- Active Directory basics and user management
- Linux administration and service configuration

## Next Steps

Getting this up and running took a whole weekend and a lot of troubleshooting, but the feeling of seeing my virtual machines talking to each other (and attacking each other) was incredible. Next up, I'll be documenting how I installed and configured Active Directory, and then we'll dive into some actual penetration testing!

> **💡 Pro Tip:** Start small! You don't need enterprise-grade hardware to learn. An old desktop with 16GB RAM can run 3-4 VMs comfortably. Focus on understanding the concepts rather than having the latest hardware.

