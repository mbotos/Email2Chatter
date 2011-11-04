global class ChatterEmailHandler implements Messaging.InboundEmailHandler {
	public static map<string, string> objectQueryField = new map<string, string>{'contact' => 'email', 'case' => 'casenumber'};

	static boolean sendConfirmation = false; // TODO allow per-User setting
	static Pattern objectHashPattern = Pattern.compile('#(\\w+)\\s+([\\w@\\. ]+)');
	static Pattern linkPattern = Pattern.compile('(https?://[^\\s]+)');
	static map<string, string> objectFromHash = new map<string, string>{'group' => 'CollaborationGroup'};
	static boolean assertResults = UserInfo.getOrganizationId().startsWith('00DE0000000KW41'); // turn off before deploying to orgs that have not enabled feeds for all objects
	
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

	        //create result for email operation
	        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
	        
	        if (email.subject == null) {
	        	result.message='Sorry, your Chatter status could not be set. Please add a subject in your email.';
	            result.success = false;
	            return result;  	
	        }
        
            try {
               Feedpost f = new Feedpost();
               f.ParentId = parseParentId(email);
               System.debug('parentId ' + f.parentId);
               
               if (f.ParentId == null) {
               		result.success = false;
               		result.message = 'Unable to find a matching object in your email:\n\n' + email.subject + '\n\n' + email.plainTextBody;
               		return result;
               }
               
               boolean removeHash = !isUserId(f.parentId);
               System.debug('removeHash ' + removeHash);
               String bodytext = getBodyText(email, removeHash);
               String subjecttext = getSubjectText(email, removeHash);
               
               System.debug('email ' + email);
               if (email.binaryAttachments != null)
               {
                   f.body = subjecttext;
                   f.Type = 'ContentPost';
                   f.ContentData = email.binaryAttachments[0].body;
                   
                   f.ContentFileName = email.binaryAttachments[0].filename;

				   if (bodytext != null) {
	                   if (bodytext.length() > 1000)
	                   {
	                      f.ContentDescription = bodytext.substring (0,1000);
	                   }
	                   else
	                   {
	                      f.ContentDescription = email.plainTextBody;
	                   }
				   }

               }
               else
               {
               	System.debug('bodytext ' + bodytext);
    			
                if (bodytext != null) {
     				Matcher linkMatcher = linkPattern.matcher(bodytext);
                	
                	if (linkMatcher.find()) {
	                 	f.linkUrl = linkMatcher.group(1);
	                 	bodytext = bodytext.replace(f.LinkUrl, '');

	                 	if (subjecttext.length() > 255) {
	                 		f.Title = subjecttext.substring(0, 255);
	                 	} else {
	                 		f.Title = subjecttext;
	                 	}	    
	                 	             	
	                 	System.debug('Parsed link ' +f.LinkUrl);	                 	
                	}
                 } 

				 if (f.LinkUrl == null) {   
                 	System.debug('No link');
	                 if (bodytext != null) {
	                     if (subjecttext != null)  {             	                 
	                     	bodytext= subjecttext +'\n\n'+bodytext;
	                     }
	                 } else {
	                     bodytext= subjecttext;
	                 }
                 }
                     
                 if (bodytext.length() > 1000)
                   {
                      f.body = bodytext.substring (0,1000);
                   }
                   else
                   {
                      f.body = bodytext;
                   }

               }
               
               System.debug('FeedPost ' + f);
               insert f;

               if (sendConfirmation) {
                	result.message='Your Chatter status has been successfully set to: ' + f.body;
               }
               
               result.success = true;                    
                
            } catch (Exception e) {
               result.message='Sorry, your Chatter status could not be set.\n\n' + e.getMessage() + '\n\n' +e.getStackTraceString();
               result.success = false;
               
               if (assertResults && Test.isRunningTest()) {
               		throw e;
               }
            }

            return result;
    }
    
    string getBodyText(Messaging.InboundEmail email, boolean removeHash) {
    	string bodytext;
    	               
       	if (email.plainTextBody != null) {
          	bodytext = email.plainTextBody;
       
       		if (removeHash) {
		        integer hashIndex = bodytext.indexOf('#');   
		        
		        if (hashIndex != -1) {
                 	integer linkeBreak = bodyText.indexOf('\n', hashIndex);
                 	string hashText;
                 	
                 	if (linkeBreak != -1) {
                 		hashText = bodytext.substring(hashIndex, linkeBreak);
                 	} else {
                 		hashText = bodytext.substring(hashIndex);                 		
                 	}
                 	
                 	bodytext = bodytext.replace(hashText, '');
		        }
       		}
       	}
       	
    	return bodytext;
    }
    
    string getSubjectText(Messaging.InboundEmail email, boolean removeHash) {
    	string text = email.subject.replace('Fwd: ', '');
    	
    	if (removeHash) {
	        integer hashIndex = text.indexOf('#');   
	        if (hashIndex > 1) {
	       		text = text.substring(0, hashIndex-1).trim();
	        } else if (hashIndex == 0) {
	        	text = null;
	        }
    	}
    	
    	return text;    	
    }
    
    boolean isUserId(string i) {
    	return i.startsWith('005');
    }
    
    string getObjectName(string hashName) {
    	map<string, string> objectFromHashFull = new map<string, string>();
    	
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        for (string sobjectName : globalDescribe.keySet()) {
       		string label = globalDescribe.get(sobjectName).getDescribe().getLabel();
        	objectFromHashFull.put(label.replace(' ', '').toLowerCase(), sobjectName);
         }
        
        objectFromHashFull.putAll(objectFromHash);
        System.debug(objectFromHashFull);
    	
    	return objectFromHashFull.get(hashName);
    }
    
    Id parseParentId(Messaging.InboundEmail email) {
    	Id parentId;
    	
    	System.debug('Parsing parentId from email ' + email);
    	
    	if (email.subject.indexOf('#') != -1) {   		
    		parentId = parseParentId(email.subject);   		
    	} 
    	
    	if (parentId == null && email.plainTextBody != null && email.plainTextBody.indexOf('#') != -1) {    		
    		parentId = parseParentId(email.plainTextBody);     		   		
    	} 

		if (parentId == null) {  		
    		try {
               parentId = [select id from User where email = :email.fromAddress and IsActive = true limit 1].id;
            } catch (QueryException ex) {
            	parentId = UserInfo.getUserId();
            }
    		
    	}
    	
    	return parentId;
    }
    
    Id parseParentId(string text) {
    	Id parentId;
    	string objectName;
    	string recordName;
    	string queryField = 'name';
    	
     	Matcher objectHashMatcher = objectHashPattern.matcher(text);
    	
    	System.debug(objectHashPattern);
    	System.debug('Parsing parentId from ' + text);
    	
    	if (objectHashMatcher.find()) {
    		objectName = getObjectName(objectHashMatcher.group(1).toLowerCase());
    		recordName = objectHashMatcher.group(2);
    		
    		if (objectQueryField.containsKey(objectName)) {
    			queryField = objectQueryField.get(objectName);
    		}		
    	}
 	
 		if (objectName != null) {
			if (objectQueryField.containsKey(objectName)) {
				queryField = objectQueryField.get(objectName);
			}		
			
			try {
				list<SObject> objects = Database.query('select Id from ' + objectName + ' where ' + queryField + ' = \'' + recordName + '\' limit 1');
				if (objects.size() > 0) {
					parentId = objects[0].Id;
				}  
			} catch (QueryException ex) {
				if (ex.getMessage().indexOf('sObject type') == -1) { // ignore plain hashtags that aren't sObject types
					System.debug('Rethrowing');
					throw ex;
				}
			} 	
 		}
    	
    	return parentId;
    }
    
    
    // Tests won't run properly until email service is setup, so asserts are commented out for installation
    
    static testMethod void testContact(){
    	
    	 // Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
       String userName = UserInfo.getUserName();
       User activeUser = [Select Email From User where Username = :userName limit 1];
       String userEmail = activeUser.Email;
    	
    	
    	 // Create a new test Account and insert it in the Test Method        
       Account a = new account(Name='Test Account');
       insert a;
    
    // Create a new test Contact and insert it in the Test Method  
       Contact c = new Contact( account = a, 
                    lastName='Test Contact', 
                    Email='testc@mailop.com');
       insert c;
       
       // test with subject that matches the unsubscribe statement
       email.subject = 'test #contact testc@mailop.com';
       email.fromAddress = userEmail;
       
       // call the class and test it with the data in the testMethod
       ChatterEmailHandler ChatterEmailHandlerTest1 = new ChatterEmailHandler();
       
       Test.starttest();
       ChatterEmailHandlerTest1.handleInboundEmail(email, env );
       Test.stoptest(); 
       
       if (assertResults) {
			System.assertEquals(1, [select count() from ContactFeed where ParentId =:c.Id and FeedPost.Body = 'test']);
       }
    }
 
 	static testMethod void testCase(){
    	
       // Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
       String userName = UserInfo.getUserName();
       User activeUser = [Select Email From User where Username = :userName limit 1];
       String userEmail = activeUser.Email;
    	
       // Create a new test Case and insert it in the Test Method  
       Case ca = new Case( Status = 'new', 
                    Origin ='Phone' );
       insert ca;
       
       Case testc = [Select case.CaseNumber from Case where case.Id = :ca.Id];
       email.subject = 'test2 #case '+testc.CaseNumber;       
       email.fromAddress = userEmail;
       
       
       // call the class and test it with the data in the testMethod
       ChatterEmailHandler ChatterEmailHandlerTest2 = new ChatterEmailHandler();
       
       Test.starttest();
       ChatterEmailHandlerTest2.handleInboundEmail(email, env );  
       Test.stoptest(); 
       
       if (assertResults) {
			System.assertEquals(1, [select count() from CaseFeed where ParentId =:ca.Id and FeedPost.Body = 'test2']);
    
       }
   }
    
    static testMethod void testOpportunity(){
    	
    	// Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
       String userName = UserInfo.getUserName();
       User activeUser = [Select Email From User where Username = :userName limit 1];
       String userEmail = activeUser.Email;
    	
    	
    	 // Create a new test Account and insert it in the Test Method        
       Account a = new account(Name='Test Account');
       insert a;
       
       // Create a new test Opportunity and insert it in the Test Method  
       Opportunity o = new Opportunity( account = a, 
                    Name='Test Opportunity', 
                    CloseDate=Date.today(),
                    StageName='Prospecting');
       insert o;    
       
       // test with subject that matches the unsubscribe statement
       email.subject = 'test3 #opportunity Test Opportunity';
       email.fromAddress = userEmail;
       
       // call the class and test it with the data in the testMethod
       ChatterEmailHandler ChatterEmailHandlerTest3 = new ChatterEmailHandler();
       
       Test.starttest();
       ChatterEmailHandlerTest3.handleInboundEmail(email, env );
       Test.stoptest(); 
       
       if (assertResults) {
			System.assertEquals(1, [select count() from OpportunityFeed where ParentId =:o.Id and FeedPost.Body = 'test3']);
       }
    }    
    
    static testMethod void testAccount(){
    	
       // Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
       String userName = UserInfo.getUserName();
       User activeUser = [Select Email From User where Username = :userName limit 1];
       String userEmail = activeUser.Email;
    	
       // Create a new test Account and insert it in the Test Method        
       Account a = new account(Name='Test Account');
       insert a;
       
       // test with subject that matches the account
       email.subject = 'test4 #account Test Account';
       email.fromAddress = userEmail;
       
       // call the class and test it with the data in the testMethod
       ChatterEmailHandler ChatterEmailHandlerTest4 = new ChatterEmailHandler();
      
       
       Test.starttest();
       ChatterEmailHandlerTest4.handleInboundEmail(email, env );
       Test.stoptest(); 
       
       if (assertResults) {
       			System.assertEquals(1, [select count() from AccountFeed where ParentId =:a.Id and FeedPost.Body = 'test4']);
       }
    }

  
    static testMethod void testLinkIsPosted(){
    	
       // Create a new email and envelope object
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
       String userName = UserInfo.getUserName();
       User activeUser = [Select Email From User where Username = :userName limit 1];
       String userEmail = activeUser.Email;
    	
       // test with link title, post, and link
       email.subject = 'Link Title';
       email.fromAddress = userEmail;
       
       string postBody = 'Post Body';
       string link = 'http://salesforce.com';
       email.plainTextBody = postBody + '\n' + link;
       
       // call the class and test it with the data in the testMethod
       ChatterEmailHandler emailHandler = new ChatterEmailHandler();     
       
       Test.starttest();
       emailHandler.handleInboundEmail(email, env );
       Test.stoptest(); 
       
       if (assertResults) {
              System.assertEquals(1, [select count() From NewsFeed where FeedPost.Title = :email.subject and FeedPost.LinkUrl = :link and FeedPost.Body = :postBody]);
       }
    }

    static testMethod void testLinkBeforeText(){
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       email.subject = 'Link Title';
       
       string postBody = 'Post Body';
       string link = 'http://salesforce.com';
       email.plainTextBody = link + '\n' + postBody;
       
       handleEmail(email);
       
       System.assertEquals(1, [select count() From NewsFeed where FeedPost.Title = :email.subject and FeedPost.LinkUrl = :link and FeedPost.Body = :postBody]);
    }

    static testMethod void testSecureLink(){
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       email.subject = 'Link Title';
       
       string postBody = 'Post Body';
       string link = 'https://salesforce.com';
       email.plainTextBody = link + '\n' + postBody;
       
       handleEmail(email);
       
       System.assertEquals(1, [select count() From NewsFeed where FeedPost.Title = :email.subject and FeedPost.LinkUrl = :link and FeedPost.Body = :postBody]);
    }

    static testMethod void testAccountLinkIsPosted(){
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       
       Account a = new account(Name='Test Account');
       insert a;

       // test with link title, post, and link
       email.subject = 'Link Title';
        
       string postBody = 'Test Body';
       string link = 'http://salesforce.com';
       email.plainTextBody = '#account ' + a.Name + '\n' + postBody + '\n' + link;
       
       handleEmail(email);
       
       if (assertResults) {
       		System.assertEquals(1, [select count() From AccountFeed where ParentId = :a.id and FeedPost.Title = :email.subject and FeedPost.LinkUrl = :link and FeedPost.Body = :postBody]);
    	}
    }

    static testMethod void testAccountBeginWithHash(){
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       
       Account a = new account(Name='Test Account');
       insert a;

       email.subject = '#account ' + a.Name;
       email.plainTextBody = 'Test Body';
       
       handleEmail(email);
       
       if (assertResults) {
       		System.assertEquals(1, [select count() From AccountFeed where ParentId = :a.id and FeedPost.Body = :email.plainTextBody]);
    	}
    }

    static testMethod void testPostFromAlternateAddress() {
     	Messaging.InboundEmail email = createEmail('other@test.com');
    	handleEmail(email);
    
       if (assertResults) { 	
       		System.assertEquals(1, [select count() From NewsFeed where FeedPost.Body = :email.subject]);
    	}
   	}
    
    static testMethod void testNonObjectHash(){
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       email.subject = 'Title';
       email.plainTextBody = 'http://link.com\nTest #hash Body';
       
       handleEmail(email);
       
       if (assertResults) {
       		System.assertEquals(1, [select count() From NewsFeed where FeedPost.Title = :email.subject]);
    	}
    }

    static testMethod void testNonObjectHashSubjectWithObjectHashBody(){
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;

       Account a = new account(Name='Test Account');
       insert a;

       email.subject = '#hash';
       string body = 'Test Body';
       email.plainTextBody = '#account ' + a.Name + '\n' + body;
       
       handleEmail(email);
       
       if (assertResults) {
       		System.assertEquals(1, [select count() From AccountFeed where ParentId = :a.id and FeedPost.Body = :body]);
    	}
   }

    /* Access to CollaborationGroup is not supported
    static testMethod void testGroupLink() {      
       CollaborationGroup g = new CollaborationGroup(Name = 'Test Group');
       insert g;

       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       email.subject = '#group ' + a.Name;       
       email.plainTextBody = 'Test Body';
       
       handleEmail(email);
       
       System.assertEquals(1, [select count() From CollaborationGroupFeed where ParentId = :g.id and FeedPost.Body = :email.plainTextBody]);   	
    }
    */
    
    static Messaging.InboundEmail createEmail(string fromAddress) {
    	Messaging.InboundEmail email = new Messaging.InboundEmail();
       	email.subject = 'Test';
       	email.fromAddress = fromAddress;
       	return email;
    }
    
    public static void handleEmail(Messaging.InboundEmail email) {
	    ChatterEmailHandler emailHandler = new ChatterEmailHandler();

    	Test.starttest();
       	emailHandler.handleInboundEmail(email, new Messaging.InboundEnvelope());
       	Test.stoptest(); 
    }
    
}