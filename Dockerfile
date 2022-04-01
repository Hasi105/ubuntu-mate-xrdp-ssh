FROM ubuntu:latest

ARG user=${user:-docker}
ARG password=${password:-docker}
ARG lang_short=${lang_short:-de}
ARG lang=${lang:-de_DE:de}
ARG lang_ext=${lang_ext:-de_DE.UTF-8}
# English (US) = standard
ARG variant=${variant:-"German (US keyboard with German letters)"}
# UTC = standard
ARG timezone=${timezone:-"Europe/Berlin"}

ENV DEBIAN_FRONTEND noninteractive
ENV USER ${user}
ENV LANG ${lang_ext}
ENV LANGUAGE ${lang_ext}
ENV LC_ALL "de_DE.UTF-8"
ENV LC_CTYPE "de_DE.UTF-8"

RUN apt-get update -y && apt-get upgrade -y \
	&& apt-get install --no-install-recommends -y locales expect  sudo bash openssh-server supervisor \
	&& sed -e 's/# en_US.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' -i /etc/locale.gen \
	&& locale-gen de_DE de_DE.UTF-8 && locale > /etc/default/locale \
	&& dpkg-reconfigure locales \
	&& apt-get install -y xrdp \
	&& sed -e 's/%sudo\(.*\)ALL$/%sudo\1NOPASSWD:ALL/g' -i /etc/sudoers \
	&& useradd -m ${user} -s /bin/bash \
	&& adduser ${user} ssl-cert \
	&& usermod -aG sudo ${user} \
	&& adduser ${user} sudo \
	&& echo ${user}':'${password} | chpasswd \
	&& mkdir -p /var/run/sshd && mkdir xrdp && cd xrdp && rm -rf xrdp && cd /etc/xrdp \
	&& echo "[console]\nname=console\nlib=libvnc.so\n" >> xrdp.ini \
    && sed -i '/TerminalServerUsers/d' /etc/xrdp/sesman.ini \
    && sed -i '/TerminalServerAdmins/d' /etc/xrdp/sesman.ini \
    && xrdp-keygen xrdp auto \
	&& sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
	&& ln -fs /usr/share/zoneinfo/${timezone} /etc/localtime \
	&& dpkg-reconfigure -f noninteractive tzdata

RUN apt-get install -y ubuntu-mate-desktop firefox \
    && apt-get autoclean && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && echo "mate-session" > /home/${user}/.xsession

EXPOSE 3389 22

RUN echo "[program:xrdp-sesman]\ncommand=/usr/sbin/xrdp-sesman --nodaemon\nprocess_name = xrdp-sesman\n\n" > /etc/supervisor/conf.d/xrdp.conf && \
	echo "[program:xrdp]\ncommand=/usr/sbin/xrdp -nodaemon\nprocess_name = xrdp" >> /etc/supervisor/conf.d/xrdp.conf && \
	apt-get remove blueman -y

CMD service ssh start \
	&& /usr/bin/supervisord -n
