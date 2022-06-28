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

#### forum

The page is titled `HackMe` and there are several topics:

---
- Welcome to this new Forum ! - admin
- Probleme login ? - lmezard
- Gasolina - qudevide
    - Gasolina - zaz
- Les mouettes ! 
    - Les mouettes ! - thor
---

There is a list of the users:

---
| Username | Type  |  Email  |
|----------|-------|:-------:|
| admin    | Admin | &#9745; |
| lmezard  | User  | &#9744; |
| qudevide | User  | &#9744; |
| thor     | User  | &#9744; |
| wandre   | User  | &#9744; |
| zaz      | User  | &#9744; |
---

After quickly looking over each topic, one seems to be interesting:

---
<h3>Probleme login ?</h3>
<p class="author">by <strong>lmezard</strong>, Thursday, October 08, 2015, 00:10 <span class="ago">(2454 days ago)</span><br />
<span class="edited">edited by admin, Thursday, October 08, 2015, 00:17</span></p>

```
Oct  5 08:44:40 BornToSecHackMe sshd[7482]: input_userauth_request: invalid user test [preauth]
[...]
Oct  5 17:51:15 BornToSecHackMe sshd[1782]: pam_unix(sshd:session): session opened for user admin by (uid=0)
```
---

The user called `lmezard` posted the content of a log file divulging some user information.

Because the log is pretty verbose, I have decided to build a filter to identify each interaction.

There are five kinds of interactions in this log file:

- login
- logout
- success
- failure
- sudo

Using the `success` filter, we can find out which users had `SSH` access:
```bash
cd sshd
< log ./filter.sh success
```
```
success:    admin@62.210.32.157:61495
success:    admin@62.210.32.157:56050
success:    admin@62.210.32.157:60098
success:    admin@62.210.32.157:50755
success:    admin@62.210.32.157:54025
success:    admin@62.210.32.157:64745
success:    admin@62.210.32.157:54511
success:    admin@62.210.32.157:51320
success:    admin@62.210.32.157:56349
success:    admin@62.210.32.157:54915
success:    admin@62.210.32.157:60970
success:    admin@62.210.32.157:56754
```

Using the `sudo` filter, we can find out which users can gain privileges on the machine:

```bash
< log ./filter.sh sudo
```
```
sudo:       admin@pts/0 as root in /home/admin /bin/sh
sudo:       root@pts/0 as root in /home/admin /usr/sbin/service vsftpd restart
sudo:       root@pts/0 as root in /home/admin /usr/sbin/service vsftpd restart
sudo:       admin@pts/0 as root in /home /bin/sh
sudo:       admin@pts/0 as root in /home/admin /bin/sh
sudo:       admin@pts/0 as root in /home/admin /bin/sh
```

Using the `failure` filter, we can find out which users attempted to connect:

```bash
< log ./filter.sh failure
```
```
failure:    test@161.202.39.38:53781
failure:    user@161.202.39.38:54109
failure:    admin@161.202.39.38:54501
failure:    PlcmSpIp@161.202.39.38:54827
failure:    pi@161.202.39.38:56275
failure:    test@161.202.39.38:56630
failure:    admin@161.202.39.38:57011
failure:    nvdb@161.202.39.38:57329
failure:    !q\]Ej?*5K5cy*AJ@161.202.39.38:57764
failure:    admin@104.245.98.119:22717
failure:    guest@104.245.98.119:24338
failure:    ubnt@104.245.98.119:24710
failure:    support@104.245.98.119:25965
failure:    test@104.245.98.119:27190
failure:    user@104.245.98.119:27769
failure:    admin@104.245.98.119:28290
failure:    PlcmSpIp@104.245.98.119:29308
failure:    ftpuser@104.245.98.119:30401
failure:    pi@104.245.98.119:30558
failure:    test@104.245.98.119:31167
failure:    admin@104.245.98.119:32271
failure:    naos@104.245.98.119:32805
failure:    adm@104.245.98.119:33503
failure:    admin@46.159.82.56:38179
```

One of the usernames seems pretty uncommon: `!q\]Ej?*5K5cy*AJ`.
Let's try to find it's context:

```bash
< log ./filter.sh | grep '5K5cy' --context=3
```
```
failure:    test@161.202.39.38:56630
failure:    admin@161.202.39.38:57011
failure:    nvdb@161.202.39.38:57329
failure:    !q\]Ej?*5K5cy*AJ@161.202.39.38:57764
login:      lmezard@(uid=1040)
logout:     lmezard
logout:     root
```

Immediately after the failed authentication, the user `lmezard` logged in successfully.

Maybe he mistakenly put his password in the username prompt.

Let's try to connect using `SSH` with these credentials:
```bash
ssh lmezard@boot2root.vm
```
```
        ____                _______    _____           
       |  _ \              |__   __|  / ____|          
       | |_) | ___  _ __ _ __ | | ___| (___   ___  ___ 
       |  _ < / _ \| '__| '_ \| |/ _ \\___ \ / _ \/ __|
       | |_) | (_) | |  | | | | | (_) |___) |  __/ (__ 
       |____/ \___/|_|  |_| |_|_|\___/_____/ \___|\___|

                       Good luck & Have fun
lmezard@boot2root.vm's password: 
Permission denied, please try again.
```

The permission is denied, which may be the reason why he created this topic.

The `forum` has a login button. Let's try the credentials there.

The login is successfull and we can now post topics as the user `lmezard`.
We can also access his private profile area, where we can find his email address: `laurie@borntosec.net`.

The directory enumeration found a directory called `webmail`.
Let's try to access it using this email address.

#### webmail

The mail application is called `SquirrelMail`.

The login is successfull and leads us to an inbox containing some mail:
- DB Access - qudevide@mail.borntosec.net
- Very interesting !!!! - qudevide@mail.borntosec.net

The mail titled `DB Access` seems very interesting, as it seems to contain root access to some databases.

```
Hey Laurie,

You cant connect to the databases now. Use root/Fg-'kKXBj87E:aJ$

Best regards.
```

The enumeration also found a directory called `phpmyadmin`, which may enable us to interact with SQL databases.
