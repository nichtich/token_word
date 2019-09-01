# token_word

> an experimental online literature system featuring deep quotation, deep reuse, and usable micropayments

The following paper describes token_word in great detail: "token_word: a Xanalogical Transclusion and Micropayment System."
([pdf](papers/rohrer__token_word.pdf), [ps.gz](papers/rohrer__token_word.ps.gz)).

## Table of contents

* [What is token_word, exactly?](#what-is-token_word-exactly)
  * [frequently asked questions](#frequently-asked-questions)
  * [token_word history](#token_word-history)
* [Requirements and Installation](#requirements-and-installation)
* [Author](#author)
* [Republication](#republication)
* [License](#license)

## What is token_word, exactly?

token_word is an online literature system built around the notion of content quotation and reuse---the aim of this system is to make reuse completely frictionless.

quotation is a common, if not mundane, writing device.  We might view it simply as a necessary evil, as secondary to the act of creation.  Why, then, does token_word focus so heavily on quotation?  Because quotation works differently in token_word, and the way it works is far from mundane.

when one token_word document quotes another, the quote is preserved as a deep reference.  In other words, the characters quoted from the first document are not simply copied into the quoting document.  Thus, by following the quote reference, the original context of the quote can be obtained.

token_word does not stop at one level of indirection:  a quote can contain a quote, which can again contain another quote, et cetera.  The reference chain can continue indefinitely, and it can likewise be explored indefinitely.   

what happens when quotation and reference-chasing becomes automatic?  Quotation can become transparent, and all those quotation opacifiers (like "quotation marks", block-indents, and reference flags) can disappear.  We suddenly have a universe of words and ideas that can be assembled, rearranged, and distilled over and over.  The origins of particular words in such a collage can be traced as necessary, but references no longer need to obscure the words themselves. 

and what about links?  token_word provides no explicit linking mechanism, though quotes can be used effectively as links (which can be viewed by clicking on the "show embedded quotes" link below).  For example, you can get more information about token_word by chasing the references in the following quotes:

[frequently asked questions](#frequently-asked-questions)
 
[token_word history](#token_word-history)

along with frictionless, deep quotation, token_word delivers a frictionless micropayment system.  Each character in the token_word universe is worth one token.  Thus, a 3000-character article is worth 3000 tokens.  When a user accesses the article for the first time, he or she pays 3000 tokens.  This payment does not go entirely to the author of the article, but is instead split up among the original authors of the words in the article (some of which may have been written by the author of the article).  If the 3000-character article contains 2300 original characters and a 700-character quote, 2300 tokens are transfered to the article author and 700 are transfered to the quote author.

Readers only spend tokens for the words in an article once.  Whenever an article quotes words that the reader already owns, those words are free, and only the new words use up tokens.

with both reference-chasing and micropayments in place, authors can encourage free reuse of their writing.  The more an author's words are reused, the more tokens that author is likely to receive.   

token_word is inspired by the ideas of Ted Nelson, the inventor of hypertext, transclusion, and transcopyright.

### frequently asked questions

**Q:  how can links be created between documents?**

**A:**  in token_word, the only available mechanism is the quote, which can effectively be used as a link.  Simply quote relevant words from the document that you want to link to---the quoted words will serve as the "link anchor" in your document.  The "link" can be seen by readers when they click the "show embedded quotes" link at the bottom of your document.  Since quotes can be tracked in both directions (by using the "documents that quote this document" link), quotes are actually more powerful than the link mechanisms supported in certain other hypertext systems.

**Q:  what is the difference between "trial" tokens and "real" tokens?**

**A:**  trial tokens are given to you for free when you create a token word account, and they have no real-world monetary value (they cannot be withdrawn in exchange for real money).  Their only value is their purchasing power inside token_word.  Real tokens are deposited into token_word in exchange for real money.  The system tracks both kinds of tokens---trial tokens can only be transfered into the trial balance of another user, and real tokens can only be transfered between real balances.  When you purchase a document, the token_word system favors payment with trial tokens as long as they are available.

**Q:  what is the point of having two token types?**

**A:**  we want to give new users free tokens, but we also do not want to get ourselves into a sticky financial situation.  Imagine if a particular user (perhaps with the help of other conspiring users) accumulated billions of free tokens and then tried to cash out for real-world money.  Trial tokens allow new users to try out the system for free without financial risk on our part.

### token_word history

token_word was coded from scratch using perl in approximately nine days (January 8, 2002 -- January 17, 2002) by jason rohrer (me, jcr13).

token_word is based on the ideas of Ted Nelson, which have been evolving over the last 40 years.  I had been thinking about Ted's ideas for about one year, and my thoughts on these matters culminated with the frantic production of the token_word system.

in terms of code, token_word relies on CGI.pm (by Lincoln D. Stein), MD5.pm (by Neil Winton), and ispell (by a large group of people over a large number of years).

## Requirements and Installation

token_word was created as Perl CGI script in 2002/2003. It still runs on modern Perl with some additional modules to wrap the legacy code. The modules are listed in `cpanfile`. Installation of module `DB_File` requires Berkeley Database Libraries (e.g. run `sudo apt-get install libdb-dev`).

*The following instructions have been adopted from the original `siteInstall.txt`*

1.  Clone or copy the content of this repository.

2.  Install required Perl modules:

        cpanm --installdeps .
    
3.  Optionally edit `htmlTemplates/depositConfirm.html`

	- Change `jcr13@users.sourceforge.net` to the email address associated
      with your site's paypal account.
	- Change the "return" and "cancel-return" parameter value URLs to 
	  http://myserver.com/location-of-token_word/
    - Change the "notify_url" parameter value URLs to
	  http://myserver.com/location-of-token_word/

4.  Start the application

        plackup

5.  Open <http://localhost:5000/> with a web browser.
    The "login" page should be displayed.

If you don't want to start from scratch, copy file `exampleDatabase/tokenWordData.db` into directory `cgi-data`. You will get a user with username `user` and password `password` and s set of sample documents. See document "Summary" for an example of deep transclusion. 

## Author

Jason Rohrer

## Republication

This git repository has been exported by Jakob Voß from a CVS repository at <http://hypertext.cvs.sourceforge.net/viewvc/> with `git cvsimport` (subdirectory `token_word`). See the original [project page at SourceForge](https://sourceforge.net/projects/hypertext/) for original sources. Jason's account name (jcr13) has been changed to the current name and email used at GitHub projects.

See the git history for additional modifications in the directory layout and documentation.

## License

GNU General Public License version 2.0 (GPLv2)
