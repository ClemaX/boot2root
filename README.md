# boot2root

This is a reverse-engineering and security challenge.
The objective is to gain privileged access to the system contained in an ISO disk image.

## Powering up

To boot up the vm, I use an utility script `vm.sh`:
```bash
./vm.sh up
```

To access the vm easily, I setup a DNS route with the name `boot2root.vm`:
```bash
sudo pdnsd-ctl add a "$(./vm.sh ip)" "boot2root.vm"
```

You could also edit the `/etc/hosts` file or use the vm's ip address directly.

## Service discovery
To discover the services that are exposed to the local network, we can use an nmap service identification scan:
```bash
cd services

TARGET=boot2root.vm

nmap -sV "$TARGET" -oN map
```

The result will be saved in human-readable format into a file called `map`:
```
# Nmap 7.92 scan initiated Mon Jun 13 15:29:04 2022 as: nmap -sV -oN map 192.168.56.101
Nmap scan report for 192.168.56.101
Host is up (0.00016s latency).
Not shown: 994 closed tcp ports (conn-refused)
PORT    STATE SERVICE  VERSION
21/tcp  open  ftp      vsftpd 2.0.8 or later
22/tcp  open  ssh      OpenSSH 5.9p1 Debian 5ubuntu1.7 (Ubuntu Linux; protocol 2.0)
80/tcp  open  http     Apache httpd 2.2.22 ((Ubuntu))
143/tcp open  imap     Dovecot imapd
443/tcp open  ssl/http Apache httpd 2.2.22
993/tcp open  ssl/imap Dovecot imapd
Service Info: Host: 127.0.1.1; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Mon Jun 13 15:29:16 2022 -- 1 IP address (1 host up) scanned in 12.97 seconds
```

As we can see, there are `SSH`, `FTP`, `HTTP/S` and `IMAP` servers which we can try to access.

We do not have any credentials yet, so let's try to access the public web services.

### http

The `HTTP` server running on port `80` contains placeholder page:

---

<div id="wrapper">
    <h3>Hack me</h1>
    <h4>We're Coming Soon</h2>
    <p>We're wetting our shirts to launch the website.<br />
    In the mean time, you can connect with us trought</p>
    <p><a href="https://fr-fr.facebook.com/42Born2Code">Facebook</a> <a href="https://plus.google.com/+42Frborn2code">Google +</a> <a href="https://twitter.com/42born2code">Twitter</a></p>
</div>

---

### https

On the `HTTPS` server running on port `443` we get a `404`:

---

<h3>Not Found</h1>
<p>The requested URL / was not found on this server.</p>
<hr>
<address>Apache/2.2.22 (Ubuntu) Server at boot2root.vm Port 443</address>

---

Because there is no index, we can use a directory enumeration tool:
```bash
dirstalk scan --no-check-certificate --scan-depth 0 "https://$TARGET" --dictionary /usr/share/wordlists/dirb/small.txt
```

```
4 results found
/
├── cgi-bin
├── forum
├── phpmyadmin
└── webmail

https://boot2root.vm/cgi-bin/ [403] [GET]
https://boot2root.vm/forum [301] [GET]
https://boot2root.vm/phpmyadmin [301] [GET]
https://boot2root.vm/webmail [301] [GET]
```

Using a depth of zero will save us a lot of time, as we are trying to make a broad discovery.

The `webmail` and `phpmyadmin` are probably authenticated, so let's try to access the `forum` instead.
