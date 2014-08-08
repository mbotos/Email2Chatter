global class ChatterEmailHandler implements Messaging.InboundEmailHandler {
	static Boolean sendConfirmation = false; // TODO allow per-User setting
	static Pattern objectHashPattern = Pattern.compile('#(\\w+)\\s+([\\w@\\. ]+)');
	static Pattern linkPattern = Pattern.compile('(https?://[^\\s]+)');
	static Map<String, String> objectQueryField = new Map<String, String> {'contact' => 'email', 'case' => 'casenumber'};
	static Map<String, String> objectFromHash = new Map<String, String> {'group' => 'CollaborationGroup'};
	
	@TestVisible
	private static Boolean assertResults = UserInfo.getOrganizationId().startsWith('00DE0000000KW41'); // turn off before deploying to orgs that have not enabled feeds for all objects
	
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
	
		//create result for email operation
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
		if (email.subject == null) {
			result.message = 'Sorry, your Chatter status could not be set. Please add a subject in your email.';
			result.success = false;
			return result;
		}
		
		try {
			FeedItem f = new FeedItem();
			f.ParentId = parseParentId(email);
			System.debug('parentId ' + f.parentId);
			
			if (f.ParentId == null) {
				result.success = false;
				result.message = 'Unable to find a matching object in your email:\n\n' + email.subject + '\n\n' + email.plainTextBody;
				return result;
			}
			
			Boolean removeHash = !isUserId(f.parentId);
			System.debug('removeHash ' + removeHash);
			String bodytext = getBodyText(email, removeHash);
			String subjecttext = getSubjectText(email, removeHash);
			
			if (email.binaryAttachments != null) {
				f.body = subjecttext;
				f.Type = 'ContentPost';
				f.ContentData = email.binaryAttachments[0].body;
				
				f.ContentFileName = email.binaryAttachments[0].filename;
				
				if (bodytext != null) {
					if (bodytext.length() > 1000) {
						f.ContentDescription = bodytext.substring(0, 1000);
					}
					else {
						f.ContentDescription = email.plainTextBody;
					}
				}
				
			}
			else {
				System.debug('bodytext ' + bodytext);
				
				if (bodytext != null) {
					Matcher linkMatcher = linkPattern.matcher(bodytext);
					
					if (linkMatcher.find()) {
						f.linkUrl = linkMatcher.group(1);
						bodytext = bodytext.replace(f.LinkUrl, '');
						
						if (subjecttext.length() > 255) {
							f.Title = subjecttext.substring(0, 255);
						}
						else {
							f.Title = subjecttext;
						}
						
						System.debug('Parsed link ' + f.LinkUrl);
					}
				}
				
				if (f.LinkUrl == null) {
					System.debug('No link');
					
					if (bodytext != null) {
						if (subjecttext != null)  {
							bodytext = subjecttext + '\n\n' + bodytext;
						}
					}
					else {
						bodytext = subjecttext;
					}
				}
				
				if (bodytext.length() > 1000) {
					f.body = bodytext.substring(0, 1000);
				}
				else {
					f.body = bodytext;
				}
				
			}
			
			System.debug('FeedItem ' + f);
			insert f;
			
			if (sendConfirmation) {
				result.message = 'Your Chatter status has been successfully set to: ' + f.body;
			}
			
			result.success = true;
			
		}
		catch (Exception e) {
			result.message = 'Sorry, your Chatter status could not be set.\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
			result.success = false;
			
			if (assertResults && Test.isRunningTest()) {
				throw e;
			}
		}
		
		return result;
	}
	
	String getBodyText(Messaging.InboundEmail email, Boolean removeHash) {
		String bodytext;
		
		if (email.plainTextBody != null) {
			bodytext = email.plainTextBody;
			
			if (removeHash) {
				integer hashIndex = bodytext.indexOf('#');
				
				if (hashIndex != -1) {
					integer linkeBreak = bodyText.indexOf('\n', hashIndex);
					String hashText;
					
					if (linkeBreak != -1) {
						hashText = bodytext.substring(hashIndex, linkeBreak);
					}
					else {
						hashText = bodytext.substring(hashIndex);
					}
					
					bodytext = bodytext.replace(hashText, '');
				}
			}
		}
		
		return bodytext;
	}
	
	String getSubjectText(Messaging.InboundEmail email, Boolean removeHash) {
		String text = email.subject;
		
		if (removeHash) {
			integer hashIndex = text.indexOf('#');
			
			if (hashIndex > 1) {
				text = text.substring(0, hashIndex - 1).trim();
			}
			else if (hashIndex == 0) {
				text = null;
			}
		}
		
		return text;
	}
	
	Boolean isUserId(Id i) {
		Schema.sObjectType sot = i.getSobjectType();
		return (sot == User.sObjectType);
		//return i.startsWith('005');
	}
	
	Id parseParentId(Messaging.InboundEmail email) {
		Id parentId;
		
		System.debug('Parsing parentId FROM email ' + email);
		
		if (email.subject.indexOf('#') != -1) {
		
			parentId = parseParentId(email.subject);
			
		}
		else if (email.plainTextBody != null && email.plainTextBody.indexOf('#') != -1) {
		
			parentId = parseParentId(email.plainTextBody);
			
		}
		
		if (parentId == null) {
			try {
				parentId = [SELECT Id FROM User WHERE email = :email.fromAddress AND IsActive = true LIMIT 1].Id;
			}
			catch (QueryException ex) {
				parentId = UserInfo.getUserId();
			}
			
		}
		
		return parentId;
	}
	
	String getObjectName(String hashName) {
		Map<String, String> objectFromHashFull = new Map<String, String>();
		
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		
		for (String sobjectName : globalDescribe.keySet()) {
			String label = globalDescribe.get(sobjectName).getDescribe().getLabel();
			objectFromHashFull.put(label.replace(' ', '').toLowerCase(), sobjectName);
		}
		
		objectFromHashFull.putAll(objectFromHash);
		System.debug(objectFromHashFull);
		
		return objectFromHashFull.get(hashName);
	}
	
	Id parseParentId(String text) {
		Id parentId;
		String objectName;
		String recordName;
		String queryField = 'name';
		
		Matcher objectHashMatcher = objectHashPattern.matcher(text);
		
		System.debug(objectHashPattern);
		System.debug('Parsing parentId FROM ' + text);
		
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
				list<SObject> objects = Database.query('SELECT Id FROM ' + objectName + ' WHERE ' + queryField + ' = \'' + recordName + '\' LIMIT 1');
				
				if (objects.size() > 0) {
					parentId = objects[0].Id;
				}
			}
			catch (QueryException ex) {
				if (ex.getMessage().indexOf('sObject type') == -1) { // ignore plain hashtags that aren't sObject types
					System.debug('Rethrowing');
					throw ex;
				}
			}
		}
		
		return parentId;
	}
	
	
}