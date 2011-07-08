About
-----

Fork of [Force.com Labs Email2Chatter App ](http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003GKAOEA4) which parses links into the appropriate Chatter post fields. Specifically:
- Subject becomes link Title
- Link is extracted from email body and becomes LinkUrl
- Remaining email body becomes post body 

In the current implementation, the link *must* be the last item in the email.  

Installation
------------
 
For an easy, 1-click installation: [Email2Chatter Unmanaged Package v1.1](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tE0000000HDpm).

To use the source code with a Salesforce org: [How To Use Github and the Force.com IDE](http://blog.sforce.com/sforce/2011/04/how-to-use-git-github-force-com-ide-open-source-labs-apps.html) 

Future Ideas
------------

- More flexible link parsing
- Automate setup by creating email service and individual email addresses
- Add plug-in support for custom processing (ie. custom hashtag -> custom object)