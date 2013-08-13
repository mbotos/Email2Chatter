About
-----

Fork of [Force.com Labs Email2Chatter App ](http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003GKAOEA4) which supports posting to all standard and custom objects, and parses links into the appropriate Chatter post fields. Specifically:

- Subject becomes link Title
- Link is extracted from email body and becomes LinkUrl
- Remaining email body becomes post body 

The object hashtag should be the object's label stripped of markup, ie. Custom_Object__c becomes #CustomObject (case-insensitive). Objects will be matched based on the exact name following the hashtag.

This should be particularly useful for the following cases:

- Consultants who are frequently logged into client orgs instead of their internal org
- Mobile users who use a variety of apps to read and share pages
- Frequent posters who want to bypass multiple copy-paste into the link title/location fields  

Installation
------------
 
For an easy, 1-click installation: [Email2Chatter Unmanaged Package v1.2](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tE0000000HDpr)

To use the source code with a Salesforce org: [How To Use Github and the Force.com IDE](http://blog.sforce.com/sforce/2011/04/how-to-use-git-github-force-com-ide-open-source-labs-apps.html) 
