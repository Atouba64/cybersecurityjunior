---
title: "Networking Basics I Wish I Knew Sooner"
date: 2025-10-17 10:00:00 -0400
categories: [Networking]
tags: [networking, basics, security, osi-model, tcp-ip, dns, ports]
image: https://placehold.co/1000x400/EC4899/FFFFFF?text=Networking+Fundamentals
excerpt: "You can't secure what you don't understand. When I started in cybersecurity, I realized I had huge gaps in my networking knowledge."
---

You can't secure what you don't understand. When I started in cybersecurity, I realized I had huge gaps in my networking knowledge. I could configure a router, but I didn't truly understand how data flows through networks. This post breaks down the networking fundamentals that every cybersecurity professional needs to know.

## The OSI Model (Simplified)

The OSI model is like a blueprint for how data travels across networks. Here's how I think about it:

### 📋 The 7 Layers (Top to Bottom)

1. **Application** - HTTP, HTTPS, FTP
2. **Presentation** - Encryption, Compression
3. **Session** - Session Management
4. **Transport** - TCP, UDP
5. **Network** - IP, Routing
6. **Data Link** - Ethernet, MAC
7. **Physical** - Cables, Wireless

## TCP vs UDP

Understanding the difference between TCP and UDP is crucial for security analysis:

### 🔄 TCP (Transmission Control Protocol)

- Connection-oriented
- Reliable delivery
- Error checking
- Flow control
- Used by: HTTP, HTTPS, SSH

### ⚡ UDP (User Datagram Protocol)

- Connectionless
- Fast delivery
- No error checking
- No flow control
- Used by: DNS, DHCP, Streaming

## IP Addressing Made Simple

IP addresses are like phone numbers for computers. Here's what you need to know:

### 🌐 IPv4 Addresses

**Format:** 192.168.1.100 (4 numbers, 0-255 each)

**Private Ranges:**
- 10.0.0.0 - 10.255.255.255
- 172.16.0.0 - 172.31.255.255
- 192.168.0.0 - 192.168.255.255

**Subnet Masks:** /24 = 255.255.255.0 (256 addresses)

## Common Ports You Should Know

Ports are like apartment numbers in a building (IP address). Here are the most important ones:

### Web Traffic
- 80 - HTTP
- 443 - HTTPS
- 8080 - HTTP Alt

### System Services
- 22 - SSH
- 23 - Telnet
- 53 - DNS
- 67/68 - DHCP

### Email
- 25 - SMTP
- 110 - POP3
- 143 - IMAP
- 993 - IMAPS

## DNS: The Internet's Phone Book

DNS (Domain Name System) converts human-readable names to IP addresses:

1. **Query:** You type "google.com"
2. **DNS Lookup:** Your computer asks DNS server for IP
3. **Response:** DNS returns "142.250.191.14"
4. **Connection:** Your computer connects to that IP

## Network Security Implications

Understanding networking helps you understand attacks:

### 🚨 Common Attack Vectors

- **Port Scanning:** Checking which ports are open
- **DNS Spoofing:** Redirecting DNS queries to malicious servers
- **Man-in-the-Middle:** Intercepting traffic between two parties
- **ARP Poisoning:** Corrupting ARP tables to redirect traffic
- **DDoS:** Overwhelming services with traffic

## Tools That Help

These tools helped me understand networking better:

- **Wireshark:** See actual network traffic
- **nmap:** Scan networks and discover services
- **ping/traceroute:** Test connectivity and routing
- **netstat:** See active connections on your machine
- **tcpdump:** Command-line packet capture

## Practical Exercise

Try this simple exercise to see networking in action:

### 🔬 Hands-On Lab

1. Open Wireshark and start capturing
2. Open a web browser and visit a website
3. Stop the capture and look at the packets
4. Find the DNS query and HTTP request
5. Notice the TCP handshake (SYN, SYN-ACK, ACK)

## Why This Matters for Security

You can't effectively secure a network if you don't understand how it works. Knowing networking fundamentals helps you:

- Identify suspicious traffic patterns
- Understand how attacks work
- Configure firewalls and security tools
- Investigate security incidents
- Design secure network architectures

### 💡 Key Takeaway

Don't try to memorize everything at once. Start with the basics—TCP/IP, common ports, and DNS. Build your understanding gradually through hands-on practice. The goal isn't to become a network engineer, but to understand enough to be an effective security professional.

