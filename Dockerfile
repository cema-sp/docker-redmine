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
    bzr \
    cmake \
    cvs \
    curl \
    g++ \
    gcc \
    git \
    gsfonts \
    imagemagick \
    libc6-dev \
    libcurl3 \
    libffi5 \
    libpq5 \
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
    patch \
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

RUN echo 'gem: --no-document' >> /etc/gemrc \
  && gem install bundler

COPY assets/setup/ /app/setup/
COPY assets/config/ /app/setup/config/
RUN chmod 755 /app/setup/install
RUN /app/setup/install

COPY assets/init /app/init
RUN chmod 755 /app/init

EXPOSE 80
EXPOSE 443

VOLUME ["/home/redmine/data"]
VOLUME ["/var/log/redmine"]

VOLUME ["/redmine-gitolite"]

WORKDIR /home/redmine/redmine
ENTRYPOINT ["/app/init"]
CMD ["app:start"]
