run: install
	@plackup

install:
	@cpanm --installdeps . \
		|| echo "Installation of DB_File failed? Try 'sudo apt-get install libdb-dev' and repeat"

example:
	@cp exampleDatabase/tokenWordData.db cgi-data/

docker-image:
	@docker build --tag token_word .

docker-run:
	@docker run -p 5000:5000 --rm token_word
