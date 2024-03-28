# Vaultwarden Raspberry PI

A self-hosted Vaultwarden (Bitwarden) deployment, accessible via LAN and seamlessly reachable from anywhere via VPN integration with Tailscale.

![Overview](./docs/overview.svg)

**Everything is Dockerized** apart from optional UFW and IPTABLES configuration so should be easily deployable to any system supporting Docker.

Modular setup options:

- **Flexible Domain:** 
    - Cloudflare (your domain), or 
    - DuckDNS (setup without a domain).

- **LAN or LAN+VPN:** 
    - LAN-only access, or 
    - Access from anywhere with Tailscale (VPN).

- **UFW and IPTABLES Setup (Optional):** 
    - Implement optional firewall configurations for heightened security.

- **Encrypted Backups (Optional):** 
    - Optional backups, utilizing Dropbox and Gmail.

- **Minimal Hardware Requirements:** Built/tested on a Raspberry Pi Zero 2 W.  

## What is Vaultwarden

Vaultwarden is a password management service, a lightweight version of the popular open-source password manager Bitwarden.

**Note:** This repository only deploys a functinal Vaultwarden server for you. For configuring and using Vaultwarden securely please visit [The Official Vaultwarden Repository](https://github.com/dani-garcia/vaultwarden)

## What does this do?

It sets up containerized services so that you can self-host your own Vaultwarden (Bitwarden) service. Either under a domain name you own, or through a DuckDNS subdomain.

The deployment is designed to be deployed privately, that is, it is not exposed to the internet, but if desired, accessible from anywhere through VPN.

This is suitable to host on a mini Single Board Computer (SBC) like the Raspberry Pi Zero 2 W.

## Which Modules are Available?

- ### Barebones Setup with Cloudflare or DuckDNS
The bare bones setup sets up a Vaultwarden Service, and uses Caddy as a reverse proxy to access the Vaultwarden Service. Depeding on your DNS choice the Vaultwarden service will be accessible through your own domain name, or through a DuckDNS subdomain. It will be completely blocked to outside access as all domain names resolve to your local ip address.

- ### Optional Tailscale Service
Tailscale is a private and encrypted mesh network service that allows users to easily access resources across different devices and networks, without the need for complex configurations or VPN setups.

Tailscale is based on WireGuard, which is a modern open-source VPN protocol known for its simplicity and efficiency.

Setting up a Tailscale container allows you to access the Vaultwarden service you are hosting to be accessible by devices on your Tailscale network, even when you are not connected to your LAN. Utilizing a VPN network through authenticated devices

- ### Optional Backup Service

The backup service enhances a basic Docker Python container setup by implementing a seamless process that includes:

- Creating an encrypted backup package of your Vaultwarden Database and essential files, adhering to the [Vaultwarden Backup Guidelines.]((https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault))
- Uploading this encrypted backup package to your Dropbox account.
- Notifying your Gmail account of the backup status and securely emailing you the decryption key.

While it's true that there are other well-developed backup services tailored for Vaultwarden deployments available:

- [BruceForce Vaultwarden Backup](https://github.com/Bruceforce/vaultwarden-backup/tree/main)
- [ttionya Vaultwarden Backup](https://github.com/ttionya/vaultwarden-backup)

our solution offers a unique advantage. By customizing your backup process, you gain the assurance of not solely relying on the security of a Docker container hosted externally.

- ### Optional UFW, IPTABLES Hardening

Although the Vaultwarden service in this deployment is hosted locally, there is not excuse not to implement additional security. Using UFW we isolate the machine hosting the service and only allow ssh access to it.

We also use IPTABLES to secure the docker network such that only allowed Local and Tailscale IP addresses can access the Docker network.

We can also block some MAC ADDRESSES which are in our local network from accessing the Docker Network (e.g., nosy IOT devices, or people allowed in our local network)

## How do I install it?

You can either use the included install script `utils/install.sh` or manually set everything up.

### Using the Installer

In principle, the installation is very simple using the installer

1. You run the installer with the `--init` flag to prepare your config file
2. you fill out your config file
3. You run the installer with the `--install` flag to complete the setup.

Depending on your module choices though you will need to setup certain accounts, and the more modules you use, the more work you will need to do to complete the config file.

Please read the [HOW TO FILL OUT THE CONFIG FILE](#how-to-fill-out-the-config-file) section for details on the modules and how to fill out your config file.

**Note:** Depending on architecture you might have to replace the caddy executeable under `./caddy/caddy` The caddy executable used here is for Linux ARM64 (for raspberrypi).

You will need to include caddy-dns/cloudflare and caddy-dns/duckdns feature in the build

You can download the executable for your architecture using [this link](https://caddyserver.com/download?package=github.com%2Fcaddy-dns%2Fcloudflare&package=github.com%2Fcaddy-dns%2Fduckdns)

Or you can opt to build it yourself.

#### Instructions

1. Clone or Download the repo to a local folder on your device

```bash
git clone [LATER]
```

2. Run the installer with the `--init` flag
```bash
chomd +x ./install.sh
./install.sh --init
```

This will ask you a couple of questions regarding which modules/options you want to include in your setup and prepare your config file `./utils/config.conf`

3. Fill out **all uncommented** fields in `./utils/config.conf`. See [HOW TO FILL OUT THE CONFIG FILE](#how-to-fill-out-the-config-file)

<br>

4. Run the installer again with the `--install` flag

```bash
./install.sh --install
```

5. Follow the instructions of the installer.

**Note:** The installer is designed to tell you what it is about to do, and ask you for confirmation before it does anything. If you are setting this up on a fresh device (e.g., newly acquired Raspberry Pi Zero 2 W) you will be more fault tolerant.

If you are runnnig the installer on a machine where your are already running dnsmasq, docker or related services, ufw, iptables etc. please pay attention to what the installer is about to do and backup your data.

Here is briefly what the installer will do:

- The installer will, at various steps, and depending on your options, install **docker**, **ca-certificates**, **curl**, **gnupg**, **dnsmasq**, **ufw**, **iptables-persistent** on your machine 

- After **docker** installation, if you opted to enable **Tailscale**, it will create certificates for Tailscale, allow Caddy access to Tailscale socket, and find your Tailscale IP and updates it in necessary parts of .env and config files

- It will also setup **dnsmasq** and configure it such that wether you are connecting through **LAN** or **Tailscale** your domain name resolves to the correct IP address

- If you opted to enable **UFW and IPTABLES** it will install **UFW**, block all incoming connections apart from the ssh port (22), and setup **IPTABLES** such that only the **Tailscale IP Addresses** and **Local IP Addresses** you allowed in the **config.conf** can access the Docker Network. It will also blacklist any **MAC ADDRESSES** you specified in the config.conf file from accessing the Docker Network

- Finally it will setup the docker-compose service as a **systemd service** so that it restarts automatically at reboot

6. After installation

- If you are using Tailscale, you will need to configure DNS settings in your Tailscale account.
See: [TAILSCALE AFTER INSTALL](#tailscale-after-install)

- You will want to uncomment and create an **ADMIN_TOKEN** in ./vaultwarden/vaultwarden.env for your initial vaultwarden configuration

Please refer to the official documentation [The Official Vaultwarden Repository](https://github.com/dani-garcia/vaultwarden)

### Manual Installation

[TBD]

## HOW TO FILL OUT THE CONFIG FILE

The config file is divided into sections, not all fields need to be filled and depending on your choices when you run 

```bash
chmod +x
./utils/install.sh --init
```
The fields you do not need to fill will be commented out.

We will also handle the fields here in sections

### Mandatory Fields

These fields are mandatory regardless of shich option you choose. RASPBERRY_PI_STATIC_LOCAL_IP
is the static ip of the machine you are installing this deployment, does not have to be a raspberry pi. But please do set a local static ip for your machine, e.g., 192.168.1.33

```bash
#your email address
YOUR_EMAIL=me@mymail.com
RASPBERRY_PI_STATIC_LOCAL_IP=192.168.1.33
```

### Cloudflare or DuckDNS Fields

One group or the other will be commented out depending on your choices. We are going to confgure Caddy to obtain Let's Encrypt certs via the DNS challange.

See the official documentation here: [https://github.com/dani-garcia/vaultwarden/wiki/Running-a-private-vaultwarden-instance-with-Let%27s-Encrypt-certs]

#### Cloudflare

If you are using cloudflare, you will need your own domain. e.g, **mysite.com**

- Set up an A record for your domain in cloudflare, and point it to the static ip of your device. it should look something like this

|Type|Name|Content|Proxy Status|TTL|
|A|*|192.168.1.33|DNS only - reserved IP|Auto|

- You will need an API Token from Cloudflare. See here for details [https://github.com/dani-garcia/vaultwarden/wiki/Running-a-private-vaultwarden-instance-with-Let%27s-Encrypt-certs#cloudflare-setup]

1. In the upper right corner, click the person icon and navigate to `My Profile`, and then select the `API Tokens` tab.
1. Click the `Create Token` button, and then `Use template` on `Edit zone DNS`.
1. Edit the `Token name` field if you prefer a more descriptive name.
1. Under `Permissions`, the `Zone / DNS / Edit` permission should already be populated. Add another permission: `Zone / Zone / Read`.
1. Under `Zone Resources`, set `Include / Specific zone / example.com` (replacing `example.com` with your domain).
1. Under `TTL`, set an End Date for when your token will become inactive. You might want to choose one far in the future.
1. Create the token and copy the token value.

Now in the config file fill out these two values. e.g,

```bash
YOUR_DOMAIN=https://vaultwarden.mysite.com
CLOUDFLARE_API_TOKEN=your_cloudflare_token
```

#### DuckDNS

If you do not have your own domain, you can also use DuckDNS to configure caddy o use a DNS Challange.

1. You will need to go to [duckdns.org](https://www.duckdns.org/) and open an account. 
1. Create a subdomain
1. Point the subdomain to your machine's static local ip, e.g. 192.168.1.33 (you need to write your static local ip in the current ip box)
1. Also take note of your Duck DNS token

Now in the config file fill out these two values

```bash
DUCKDNS_DOMAIN=https://vaultwarden.duckdns.org
DUCKDNS_TOKEN=your_duckdns_token
```

### TAILSCALE FIELDS

If you want to use tailscale as a VPN service so that you can connect to your Vaultwarden instance remotely, you will need to register an account on Tailscale and add all devices you want to be in your tailscale network in there.

Go to [tailscale.com](https://tailscale.com/) and create an account. At this point, register a device on your tailscale network, e.g, your laptop computer which needs remote access to your Vaultwarden.

In the machines, section you should see the device you registered in the tailscale network.

The installer will setup tailscale for our deployment automatically, but it will need an authorization key.

Go to Settings -> Keys -> Generate auth key, with these settings:

- Expiration: anything
- Ephemeral: off
- Pre-approved: on
- Tags: anything

Generate this key and record it somewhere

Now go to DNS, and copy your TAILNET NAME e.b. tail0557b.ts.net

Now you can fill out these fields in the config file

```bash
#leave this one blank, it will be filled by install.sh
TAILSCALE_IP_RASPBERRY_PI=
#tailscale domain without protocol
TAILSCALE_DOMAIN_NOPROT=tail0557b.ts.net
#give a name for your machine, eg vaultwardents
TAILSCALE_SUBDOMAIN=vaultwardents
TAILSCALE_AUTHKEY=<your_tailscale_auth_key>
```

TAILSCALE_AUTHKEY is the authorization key you just created
TAILSCALE_SUBDOMAIN is a machine name you choose for your machine that will host vaultwarden, could be anything, e.g., geronimo, or more descritively vaultwardents
TAILSCALE_DOMAIN_NOPROT is TAILSCALE_SUBDOMAIN followed by TAILNET NAME e.g., vaultwardents.tail0557b.ts.net

**NOTE:** You will need to come back to tailsclae admin console and do one last change after the installer runs

### TAILSCALE AFTER INSTALL

After the installation is complete, you will see your machine that hosts vaultwarden added in tailscale with the TAILSCALE_SUBDOMAIN name of your choice.

It should have its own unique IP address such as 100.100.94.876

Now go to the DNS section, click add nameserver and in the nameserver section input this unique id.
You need to switch **Restrict to Domain** on, and add your domain name here:

Following our examples:

if using cloudflare: mysite.com
if using duckdns: duckdns.org

#### Why do we do this?

We want our domain name to always resolve to the correct machine whether we are on LAN or on Tailscale. We setup cloudflare or duckdns to resolve your domain to your local machine.

When we are on tailscale though this resolution is not going to work, so instead we configure tailscale to use the tailscale installed host machine as the DNS. The installer will install a lightweight dns forwarder (dnsmasq) to handle this dns request and mak sure it resolves properly.


### BACKUP FIELDS

**Note:** You will need Dropbox and Gmail for this to run properly. You will also need to create an app token for Dropbox and setup smtp for Gmail.

**Note:** Please create a separate Gmail account for this procedure, or use an account where you do not have personal or sensitive information. Why?

1. You will need to create an app key for Gmail, which is a potential security risk if leaked
1. If your Dropbox is linked to your Gmail account, if your Gmail account gets compromised, the separation of the encrypted files and the key would not mean much.
1. Please note that even in such a case your vault would still retain its encryption.

The backup procedure uses a barebones python docker container. It archives the required files as [stated by the official vaultwarden documentation ](https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault) in a gpg encrypted file and sends this file to your Dropbox.

The decrytion key for this file, along with a backup status message will be emailed to your Gmail.

#### How to create an app password for Gmail

See the [Official Documentation Here](https://support.google.com/mail/answer/185833?hl=en) to create an app password for Gmail. Please create a separate Gmail account for this procedure, or use an account where you do not have personal or sensitive information. See the note in the BACKUP FIELDS section for details.

Keep this password somewhere safe

#### Setting up a Dropbox App

We will need to setup a Dropbox App that is allowed to only read from/ write into a specific folder in Dropbox, tat is only accessible by you. For this app to work correctly you will need to generate a refresh token.

Navigate to [dropbox.com/developers](https://www.dropbox.com/developers) and click on App Console

Click on Create App, choose App folder in Scoped Accesss and then give your app a Name. let's call it my_app.

Set Allow public clients (Implicit Grant & PKCE) to Disallow


In the next page, make note of the App key and App secret
Go to permissions and check

- files.metadata.read
- files.content.write
- files.content.read

##### Generating the Refresh Token

Now visit the following link, replace **your_app_key_here** in the link with your App Key

https://www.dropbox.com/oauth2/authorize?client_id=your_app_key_here&token_access_type=offline&response_type=code

and copy the Access Code that is Generated

Now make a curl request to obtain your refresh token.

```bash
curl https://api.dropbox.com/oauth2/token \
	-d code=<access_code_that_you_just_copied> \
    -d grant_type=authorization_code \
    -d client_id=<your_app_key> \
    -d client_secret=<your_app_secret>
```
If you get a code expired message, regenerate your Access Code and try again.

Copy the refresh token from the response.

Now you are ready to fill out these fields in the config file.

In the root of your Dropbox folder please create a folder with the same name as your App name if it is not already created

```bash
#gmail address setup with an app password
NOTIFIER_EMAIL=example@gmail.com  
#gmail app password  
NOTIFIER_APP_PASSWORD=<your_gmail_app_password>
## This is your backup schedule, it needs to be in a cronjob format
## e.g, setting this to 0 16 * * * will run the backup job on 16:00 UTC every day 
BACKUP_SCHEDULE="0 16 * * *"
DBOX_REFRESH_TOKEN=<your_dbox_refresh_token>
DBOX_APP_KEY=<your_dbox_app_key>
DBOX_APP_SECRET=<your_dbox_app_secret>
#this must be the same name of your Dropbox app
DBOX_APP_FOLDER=<your_dbox_app_name>
```

### IPTABLES Fields

These fields consist of 3 values

- ##### MAC_ADDRESSES_TO_BLOCK (Comma seperated MAC Addresses, no spaces)

These mac addresses will be blocked from accessing the docker network inside your host machine. This is useful to block IOT devices in your home, or if your share your local network with strangers, you can block their devices. Please write comma seperated MAC ADDRESSES with no spaces in between.

```bash
MAC_ADDRESSES_TO_BLOCK=AB:CD:EF:12:34:56,12:34:AB:CD:EF:78
```

- ##### LOCAL NETWORK IP RANGE (Comma seperated CIDR IP Addresses, no spaces)

These local IP addresses will be allowed to access the docker network. you can combine CIDR ranges with individual IP addresses, e.g.,

```bash
# ip addresses between 192.168.11.10  192.168.11.24, and 192.168.11.132
LOCAL_NETWORK_IP_RANGE=192.168.11.10/28,192.168.11.132
```

- ##### TAILSCALE IP RANGE (Comma seperated CIDR IP Addresses, no spaces)
These Tailscale IP addresses will be allowed to access the docker network. you can combine CIDR ranges with individual IP addresses, e.g.,

```bash
TAILSCALE_IP_RANGE=100.100.55.10/28,100.100.55.13
```

## References and Acknowledgements

- [Official Vaultwarden Repository:](https://github.com/dani-garcia/vaultwarden) The official source for Vaultwarden, which also has great articles and links to additional methods of deployment. A must visit.
- [A Better Vaultwarden Deployment:](https://nachtimwald.com/2023/11/26/a-better-vaultwarden-deployment/) A lot of the ideas/methods used here, and hardening tips are taken from this deployment by John Schember
- [Securing Access to Vaultwarden with Tailscale and Caddy](https://mijo.remotenode.io/posts/tailscale-caddy-docker/) by Michael Johansson. A deployment that uses Tailscale as an alternative to native wireguard.
- [Securing my Home Network with dnsmasq and Tailscale](https://simpsonian.ca/blog/securing-home-network-dnsmasq-tailscale/) by Simpsonian. Thanks for the tips on configuring Tailscale and dnsmasq together for consistent domain resolution.
