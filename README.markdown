About
-----

Fork of [Force.com Labs Email2Chatter App ](http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003GKAOEA4) which supports posting to all standard and custom objects, multiple attachments, and parses links into the appropriate Chatter post fields. 

For links:

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
 
To install the source code in a Salesforce org, use the [GitHub Salesforce Deploy Tool](https://githubsfdeploy.herokuapp.com/?owner=mbotos&repo=Email2Chatter).
