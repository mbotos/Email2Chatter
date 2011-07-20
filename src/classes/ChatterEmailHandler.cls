global class ChatterEmailHandler implements Messaging.InboundEmailHandler {
	static boolean sendConfirmation = false; // TODO allow per-User setting
	
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

	        //create result for email operation
	        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
	        
	        if (email.subject == null) {
	        	result.message='Sorry, your Chatter status could not be set. Please add a subject in your email.';
	            result.success = false;
	            return result;  	
	        }
        
        	Id userId;
        	
            try{
               userId = [select id from User where email = :email.fromAddress and IsActive = true limit 1].id;
            } catch (QueryException ex) {
            	userId = UserInfo.getUserId();
            }
            
            try {
               Feedpost f = new Feedpost();
               f.ParentId = userId;
               
               String bodytext;
               
               if ( email.plainTextBody != null)
                  bodytext = email.plainTextBody;
               String subjecttext = email.subject;
               
               String match;
               Integer s;
               Integer l;
               String query;
               String errormessage;
               
               if (subjecttext.lastindexof('#account') != -1)
               { 

                 s = subjecttext.lastindexof('#account');
                 s += 9;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 9;
                 subjecttext = subjecttext.substring (0,s);
                 
                 match = match.trim();
                 
                query = 'select Id from Account where name = \'' + match + '\' limit 1'; 
                                  
                 Account a = new Account();
                 try {
                        a = Database.query(query);
                        f.ParentId = a.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find an account named: '+match;
                    } 
               }
                
                if (subjecttext.lastindexof('#contact') != -1)
               { 

                 s = subjecttext.lastindexof('#contact');
                 s += 9;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 9;
                 subjecttext = subjecttext.substring (0,s);
                 
                 match = match.trim();
                 
                 Contact c = new Contact();
                 try {
                        c = [Select Id from Contact where email = :match limit 1];
                        f.ParentId = c.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find a contact with email address: '+match;
                    } 
               }
               
               if (subjecttext.lastindexof('#opportunity') != -1)
               { 

                 s = subjecttext.lastindexof('#opportunity');
                 s += 13;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 13;
                 subjecttext = subjecttext.substring (0,s);

                 match = match.trim();

                 query = 'select Id from Opportunity where name = \'' + match + '\' limit 1'; 
                 
                 Opportunity o = new Opportunity();
                 try {
                        o = Database.query(query);
                        f.ParentId = o.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find an opportunity named: '+match;
                    } 
               }
               
               if (subjecttext.lastindexof('#case') != -1)
               { 

                 s = subjecttext.lastindexof('#case');
                 s += 6;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 6;
                 subjecttext = subjecttext.substring (0,s);

                 Case ca = new Case();
                 try {
                        ca = [Select Id from Case where CaseNumber = :match limit 1];
                        f.ParentId = ca.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find case number: '+match;
                    } 
               }

               if (email.binaryAttachments != null)
               {
                   f.body = subjecttext;
                   f.Type = 'ContentPost';
                   f.ContentData = email.binaryAttachments[0].body;
                   
                   f.ContentFileName = email.binaryAttachments[0].filename;

                   if (bodytext.length() > 1000)
                   {
                      f.ContentDescription = bodytext.substring (0,1000);
                   }
                   else
                   {
                      f.ContentDescription = email.plainTextBody;
                   }

               }
               else
               {
                 if (bodytext != null && bodytext.contains('http://')) {
                 	if (subjecttext.length() > 255) {
                 		f.Title = subjecttext.substring(0, 255);
                 	} else {
                 		f.Title = subjecttext;
                 	}
                 	
                 	integer linkIndex = bodytext.indexOf('http://');
                 	f.LinkUrl = bodytext.substring(linkIndex);
                 	bodytext = bodytext.substring(0, linkIndex-1);
                 } else {                 
	                 if (bodytext != null)
	                     bodytext= subjecttext +'\n\n'+bodytext;
	                 else
	                     bodytext= subjecttext;
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
               
                if (errormessage == null)
                {
                   insert f;
                   //I'm saying that it worked, and that a new status was created.
                   if (sendConfirmation) {
                    	result.message='Your Chatter status has been successfully set to: ' + f.body;
                   }
                    result.success = true;                    
                    return result;
                }
                else
                {
                    result.message=errormessage;
                    result.success = true;                    
                    return result;
                }
                
            } catch (Exception e) {
               result.message='Sorry, your Chatter status could not be set. Error: ' + e;
               result.success = true;
                return result;
              }

    }
    
    
    // Tests won't run properly until email service is setup, so asserts are commented out for installation
    
    static testMethod void testChatterEmailHandler1(){
    	
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
       
		/*List<ContactFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from ContactFeed where ParentId =:c.Id Order By CreatedDate DESC];
		ContactFeed updatedPost = posts[0];
		System.assertEquals(updatedPost.FeedPost.Body, 'test');*/
    }
 
 	static testMethod void testChatterEmailHandler2(){
    	
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
       
      /* List<CaseFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from CaseFeed where ParentId =:ca.Id Order By CreatedDate DESC];
       CaseFeed updatedPost2 = posts[0];
       System.assertEquals('test2', updatedPost2.FeedPost.Body); */
       
       
    }
    
    static testMethod void testChatterEmailHandler3(){
    	
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
       
       
		/*List<OpportunityFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from OpportunityFeed where ParentId =:o.Id Order By CreatedDate DESC];
		OpportunityFeed updatedPost3 = posts[0];
		
        System.assertEquals('test3', updatedPost3.FeedPost.Body); */
    }    
    
    static testMethod void testChatterEmailHandler4(){
    	
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
       
		/*List<AccountFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from AccountFeed where ParentId =:a.Id Order By CreatedDate DESC]; 
		AccountFeed updatedPost = posts[0];
		System.assertEquals(updatedPost.FeedPost.Body, 'test4');	*/
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
       
       System.assertEquals(1, [select count() From NewsFeed where FeedPost.Title = :email.subject and FeedPost.LinkUrl = :link and FeedPost.Body = :postBody]);
    }

    static testMethod void testPostFromAlternateAddress() {
     	Messaging.InboundEmail email = createEmail('other@test.com');
    	handleEmail(email);
       	//System.assertEquals(1, [select count() From NewsFeed where FeedPost.Body = :email.subject]);
    }
    
    static Messaging.InboundEmail createEmail(string fromAddress) {
    	Messaging.InboundEmail email = new Messaging.InboundEmail();
       	email.subject = 'Test';
       	email.fromAddress = fromAddress;
       	return email;
    }
    
    static void handleEmail(Messaging.InboundEmail email) {
	    ChatterEmailHandler emailHandler = new ChatterEmailHandler();

    	Test.starttest();
       	emailHandler.handleInboundEmail(email, new Messaging.InboundEnvelope());
       	Test.stoptest(); 
    }
    
}