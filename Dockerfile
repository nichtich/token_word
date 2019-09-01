FROM perl:5.20
MAINTAINER Jakob Voss <voss@gbv.de>

RUN apt-get install -y libdb-dev

COPY . /usr/src/token_word
WORKDIR /usr/src/token_word

RUN cpanm --installdeps --notest .
RUN cp exampleDatabase/tokenWordData.db cgi-data

CMD ["plackup"]

EXPOSE 5000
