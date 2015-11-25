FROM debian:wheezy
MAINTAINER Semen Pisarev <s.a.pisarev@gmail.com>

# Local sources (for speed-up)
COPY ./sources.list.ru /etc/apt/sources.list

ENV DEBIAN_FRONTEND noninteractive
RUN echo "APT::Install-Recommends 0;" >> /etc/apt/apt.conf.d/01norecommends \
  && echo "APT::Install-Suggests 0;" >> /etc/apt/apt.conf.d/01norecommends \
  && apt-get -q update \
  && apt-get install -y -q \
    apt-utils \
    wget \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv C3173AA6 \
  && echo 'deb http://mirror.yandex.ru/debian/ jessie main' > \
    /etc/apt/sources.list.d/jess.list \
  && wget -O - http://nginx.org/keys/nginx_signing.key | apt-key add - \
  && echo 'deb http://nginx.org/packages/debian/ wheezy nginx' > \
    /etc/apt/sources.list.d/nginx.list \
  && apt-get -q update \
  && apt-get install -y -q \
    build-essential \
    bzr \
    cmake \
    curl \
    cvs \
    g++ \
    gcc \
    git \
    gsfonts \
    imagemagick \
    libc6-dev \
    libcurl3 \
    libffi5 \
    libgpg-error-dev \
    libpq5 \
    libssh2-1 \
    libssh2-1-dev \
    libssl1.0.0 \
    libxml2-dev \
    libxslt1.1 \
    libyaml-0-2 \
    locales \
    logrotate \
    make \
    mercurial \
    nginx \
    openssh-client \
    openssh-server \
    patch \
    perl \
    pkg-config \
    postgresql-client \
    rsync \
    ruby \
    ruby-dev \
    subversion \
    sudo \
    supervisor \
    zlib1g \
    zlib1g-dev \
  && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
  && apt-get purge -y -q --auto-remove apt-utils \
  && apt-get autoremove -y -q \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# ------------- Gitolite ----------------------------

WORKDIR /gitolite

# To avoid annoying "perl: warning: Setting locale failed." errors,
# do not allow the client to pass custom locals, see:
# http://stackoverflow.com/a/2510548/15677
# http://stackoverflow.com/questions/22547939/docker-gitlab-container-ssh-git-login-error
RUN sed -i '/^AcceptEnv LANG LC_\*$/d' /etc/ssh/sshd_config \
  && sed -i '/session\s*required\s*pam_loginuid.so/d' /etc/pam.d/sshd

RUN mkdir /var/run/sshd

# RUN adduser --system --group --shell /bin/sh git

# RUN su git -c "mkdir /home/git/bin"

RUN git clone --progress -v git://github.com/sitaramc/gitolite . \
  && ./install -ln /usr/local/bin

# https://github.com/docker/docker/issues/5892
# RUN chown -R git:git /gitolite /home/git

# Addind volume for repositories directory
VOLUME /repositories

# ------------- Redmine -----------------------------

RUN echo 'gem: --no-document' >> /etc/gemrc \
  && gem install bundler

WORKDIR /app

COPY assets/setup/ setup/
COPY assets/config/ setup/config/

# Redmine version for plugins compatibility
ENV REDMINE_VERSION 2.6.3

RUN chmod 755 setup/install
RUN setup/install

COPY assets/init init
RUN chmod 755 init

EXPOSE 22
EXPOSE 80
EXPOSE 443

# Adding volume for redmine configuration files
VOLUME /home/redmine/data
# Adding volume for log files storage
VOLUME /var/log/redmine

WORKDIR /home/redmine/redmine
ENTRYPOINT ["/app/init"]
CMD ["app:start"]
