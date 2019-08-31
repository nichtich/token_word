# token_word

> a deep quotation system with micropayments

This git repository has been exportet from a CVS repository at <http://hypertext.cvs.sourceforge.net/viewvc/> with `git cvsimport` (subdirectory `token_word`). See also the original [project page at SourceForge](https://sourceforge.net/projects/hypertext/).

## Requirements and Usage

token_word was created as Perl CGI script in 2003. It still runs on modern Perl with some additional modules to wrap the legacy code. The modules are listed in `cpanfile`. Installation of module `DB_File` requires Berkeley Database Libraries (e.g. run `sudo apt-get install libdb-dev`).

Install required modules:

    cpanm --installdeps .

Start the web application at http://localhost:5000/:

    plackup

## Author

Jason Rohrer

## License

GNU General Public License version 2.0 (GPLv2)
