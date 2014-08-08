@isTest
private class ChatterEmailHandler_test {

	// Tests won't run properly until email service is setup, so asserts are commented out for installation
	
	
	static testMethod void testContact() {
	
		// Create a new email AND envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		
		String userName = UserInfo.getUserName();
		User activeUser = [SELECT Email FROM User WHERE Username = :userName LIMIT 1];
		String userEmail = activeUser.Email;
		
		
		// Create a new test Account AND insert it in the Test Method
		Account a = new account(Name = 'Test Account');
		insert a;
		
		// Create a new test Contact AND insert it in the Test Method
		Contact c = new Contact(account = a,
								lastName = 'Test Contact',
								Email = 'testc@mailop.com');
		insert c;
		
		// test with subject that matches the unsubscribe statement
		email.subject = 'test #contact testc@mailop.com';
		email.fromAddress = userEmail;
		
		// call the class AND test it with the data in the testMethod
		ChatterEmailHandler ChatterEmailHandlerTest1 = new ChatterEmailHandler();
		
		Test.starttest();
		ChatterEmailHandlerTest1.handleInboundEmail(email, env);
		Test.stoptest();
		
		if (ChatterEmailHandler.assertResults) {
			System.assertEquals(1, [SELECT count() FROM FeedItem WHERE ParentId = :c.Id LIMIT 1]);
		}
	}
	
	static testMethod void testCase() {
	
		// Create a new email AND envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
		
		String userName = UserInfo.getUserName();
		User activeUser = [SELECT Email FROM User WHERE Username = :userName LIMIT 1];
		String userEmail = activeUser.Email;
		
		// Create a new test Case AND insert it in the Test Method
		Case ca = new Case(Status = 'New', Origin = 'Phone');
		insert ca;
		
		Case testc = [SELECT CaseNumber FROM Case WHERE Id = :ca.Id];
		email.subject = 'test2 #case ' + testc.CaseNumber;
		email.fromAddress = userEmail;
		
		
		// call the class AND test it with the data in the testMethod
		ChatterEmailHandler ChatterEmailHandlerTest2 = new ChatterEmailHandler();
		
		Test.starttest();
		ChatterEmailHandlerTest2.handleInboundEmail(email, env);
		Test.stoptest();
		
		if (ChatterEmailHandler.assertResults) {
			System.assertEquals(1, [SELECT count() FROM FeedItem WHERE ParentId = :ca.Id LIMIT 1]);
			
		}
	}
	
	static testMethod void testOpportunity() {
	
		// Create a new email AND envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
		
		String userName = UserInfo.getUserName();
		User activeUser = [SELECT Email FROM User WHERE Username = :userName LIMIT 1];
		String userEmail = activeUser.Email;
		
		
		// Create a new test Account AND insert it in the Test Method
		Account a = new account(Name = 'Test Account');
		insert a;
		
		// Create a new test Opportunity AND insert it in the Test Method
		Opportunity o = new Opportunity(account = a,
										Name = 'Test Opportunity',
										CloseDate = Date.today(),
										StageName = 'Prospecting');
		insert o;
		
		// test with subject that matches the unsubscribe statement
		email.subject = 'test3 #opportunity Test Opportunity';
		email.fromAddress = userEmail;
		
		// call the class AND test it with the data in the testMethod
		ChatterEmailHandler ChatterEmailHandlerTest3 = new ChatterEmailHandler();
		
		Test.starttest();
		ChatterEmailHandlerTest3.handleInboundEmail(email, env);
		Test.stoptest();
		
		if (ChatterEmailHandler.assertResults) {
			System.assertEquals(1, [SELECT count() FROM FeedItem WHERE ParentId = :o.Id LIMIT 1]);
		}
	}
	
	static testMethod void testAccount() {
	
		// Create a new email AND envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
		
		String userName = UserInfo.getUserName();
		User activeUser = [SELECT Email FROM User WHERE Username = :userName LIMIT 1];
		String userEmail = activeUser.Email;
		
		// Create a new test Account AND insert it in the Test Method
		Account a = new account(Name = 'Test Account');
		insert a;
		
		// test with subject that matches the account
		email.subject = 'test4 #account Test Account';
		email.fromAddress = userEmail;
		
		// call the class AND test it with the data in the testMethod
		ChatterEmailHandler ChatterEmailHandlerTest4 = new ChatterEmailHandler();
		
		
		Test.starttest();
		ChatterEmailHandlerTest4.handleInboundEmail(email, env);
		Test.stoptest();
		
		if (ChatterEmailHandler.assertResults) {
			System.assertEquals(1, [SELECT count() FROM FeedItem WHERE ParentId = :a.Id LIMIT 1]);
		}
	}
	
	
	static testMethod void testLinkIsPosted() {
	
		// Create a new email AND envelope object
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
		
		String userId = UserInfo.getUserId();
		User activeUser = [SELECT Email FROM User WHERE Id = :userId LIMIT 1];
		String userEmail = activeUser.Email;
		
		// test with link title, post, AND link
		email.subject = 'Link Title';
		email.fromAddress = userEmail;
		
		String postBody = 'Post Body';
		String link = 'http://salesforce.com';
		email.plainTextBody = postBody + '\n' + link;
		
		// call the class AND test it with the data in the testMethod
		ChatterEmailHandler emailHandler = new ChatterEmailHandler();
		
		Test.starttest();
		emailHandler.handleInboundEmail(email, env);
		Test.stoptest();
		
		if (ChatterEmailHandler.assertResults) {
			for (FeedItem fi : [SELECT Id, LinkUrl, Title, Body FROM FeedItem WHERE ParentId = :activeUser.Id]) {
				System.assertEquals(fi.LinkUrl, link);
				System.assertEquals(fi.Title, email.subject);
			}
		}
	}
	
	static testMethod void testLinkBeforeText() {
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		email.subject = 'Link Title';
		
		String postBody = 'Post Body';
		String link = 'http://salesforce.com';
		email.plainTextBody = link + '\n' + postBody;
		
		handleEmail(email);
		
		if (ChatterEmailHandler.assertResults) {
		
			for (FeedItem fi : [SELECT Id, LinkUrl, Title, Body FROM FeedItem WHERE ParentId = :UserInfo.getUserId()]) {
				System.assertEquals(fi.LinkUrl, link);
				System.assertEquals(fi.Title, email.subject);
			}
		}
	}
	
	static testMethod void testSecureLink() {
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		email.subject = 'Link Title';
		
		String postBody = 'Post Body';
		String link = 'https://salesforce.com';
		email.plainTextBody = link + '\n' + postBody;
		
		handleEmail(email);
		
		if (ChatterEmailHandler.assertResults) {
		
			for (FeedItem fi : [SELECT Id, LinkUrl, Title, Body FROM FeedItem WHERE ParentId = :UserInfo.getUserId()]) {
				System.assertEquals(fi.LinkUrl, link);
				System.assertEquals(fi.Title, email.subject);
			}
		}
	}
	
	static testMethod void testAccountLinkIsPosted() {
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		
		Account a = new account(Name = 'Test Account');
		insert a;
		
		// test with link title, post, AND link
		email.subject = 'Link Title';
		
		String postBody = 'Test Body';
		String link = 'http://salesforce.com';
		email.plainTextBody = '#account ' + a.Name + '\n' + postBody + '\n' + link;
		
		handleEmail(email);
		
		if (ChatterEmailHandler.assertResults) {
		
			for (FeedItem fi : [SELECT Id, LinkUrl, Title, Body FROM FeedItem WHERE ParentId = :a.Id]) {
				System.assertEquals(fi.LinkUrl, link);
				System.assertEquals(fi.Title, email.subject);
			}
		}
	}
	
	static testMethod void testAccountBeginWithHash() {
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		
		Account a = new account(Name = 'Test Account');
		insert a;
		
		email.subject = '#account ' + a.Name;
		email.plainTextBody = 'Test Body';
		
		handleEmail(email);
		
		if (ChatterEmailHandler.assertResults) {
		
			for (FeedItem fi : [SELECT Id, LinkUrl, Title, Body FROM FeedItem WHERE ParentId = :a.Id]) {
				System.assertEquals(fi.Title, email.subject);
			}
		}
	}
	
	static testMethod void testPostFromAlternateAddress() {
		Messaging.InboundEmail email = createEmail('other@test.com');
		handleEmail(email);
		
		if (ChatterEmailHandler.assertResults) {
			System.assertEquals(1, [SELECT count() FROM FeedItem WHERE ParentId = :UserInfo.getUserId()]);
		}
	}
	
	static testMethod void testNonObjectHash() {
		Messaging.InboundEmail email = new Messaging.InboundEmail() ;
		email.subject = 'Title';
		email.plainTextBody = 'http://link.com\nTest #hash Body';
		
		handleEmail(email);
		
		if (ChatterEmailHandler.assertResults) {
		
			for (FeedItem fi : [SELECT Id, LinkUrl, Title, Body FROM FeedItem WHERE ParentId = :UserInfo.getUserId()]) {
			
				System.assertEquals(fi.LinkUrl, 'http://link.com');
				System.assertEquals(fi.Title, email.subject);
			}
		}
	}
	
	
	/*  Access to CollaborationGroup is not supported
	    static testMethod void testGroupLink() {
	    CollaborationGroup g = new CollaborationGroup(Name = 'Test Group');
	    insert g;
	
	    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
	    email.subject = '#group ' + a.Name;
	    email.plainTextBody = 'Test Body';
	
	    handleEmail(email);
	
	    System.assertEquals(1, [SELECT count() FROM CollaborationGroupFeed WHERE ParentId = :g.Id AND Body = :email.plainTextBody]);
	    }
	*/
	
	static Messaging.InboundEmail createEmail(String fromAddress) {
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