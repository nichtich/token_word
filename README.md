# token_word

> a deep quotation system with micropayments

This git repository has been exportet from a CVS repository at <http://hypertext.cvs.sourceforge.net/viewvc/> with `git cvsimport` (subdirectory `token_word`). See also the original [project page at SourceForge](https://sourceforge.net/projects/hypertext/).

## Requirements and Installation

token_word was created as Perl CGI script in 2003. It still runs on modern Perl with some additional modules to wrap the legacy code. The modules are listed in `cpanfile`. Installation of module `DB_File` requires Berkeley Database Libraries (e.g. run `sudo apt-get install libdb-dev`).

*The following instructions have been adopted from the original `siteInstall.txt`*

1.  Clone or copy the content of this repository.

2.  Install required Perl modules:

        cpanm --installdeps .
    
3.  Optionally edit `htmlTemplates/depositConfirm.html`
	--Change `jcr13@users.sourceforge.net` to the email address associated
      with your site's paypal account.
	--Change the "return" and "cancel-return" parameter value URLs to 
	  http://myserver.com/location-of-token_word/
    --Change the "notify_url" parameter value URLs to
	  http://myserver.com/location-of-token_word/

4.  Start the application

        plackup

5.  Open <http://localhost:5000/> with a web browser.
    The "login" page should be displayed.

6.  Check that `cgi-data/tokenWordData` has been created.

7.  If step 6 or 7 fails, look in `tokenWord_errors.log` for
    error messages.
 
## Author

Jason Rohrer

## License

GNU General Public License version 2.0 (GPLv2)
