@isTest 
private class GoogleDriveTestSuite {

	@isTest
	private static void GoogleDriveGontrollerTest() {
		GoogleDriveController con = new GoogleDriveController();
		PageReference pr = con.DriveAuth();
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		con.AccessToken();
	}

	@isTest
	private static void GoogleDriveServiceCreateFolderTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		gda.OppParentFolderEId__c = 'xxx';
		insert gda;

		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		Opportunity o = new Opportunity();
		o.Name = 'tset';
		o.Street__c = 'street';
		o.City__c = 'City';
		o.Country__c = 'street';
		o.PostalCode__c = '14700';
		o.StageName = 'Quoted';
		o.CloseDate = System.today();
		insert o;
		GoogleDriveService.createOppFolderStructure(o);
		Test.stopTest();
	}

	
	@isTest
	private static void GoogleDriveServiceCreateFolder2Test() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.now().addMinutes(-10);
		gda.TokenType__c = 'Bearer';
		gda.OppParentFolderEId__c = 'xxx';
		insert gda;

		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		Opportunity o = new Opportunity();
		o.Name = 'tset';
		o.Street__c = 'street';
		o.City__c = 'City';
		o.Country__c = 'street';
		o.PostalCode__c = '14700';
		o.StageName = 'Quoted';
		o.CloseDate = System.today();
		insert o;
		GoogleDriveService.createOppFolderStructure(o);
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServiceResfreshTokenTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		Opportunity o = new Opportunity();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServiceResfreshTokenTest2() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		Test.startTest();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServiceResfreshTokenTest3() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = null;
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.startTest();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}

		@isTest
	private static void GoogleDriveServiceResfreshTokenTest4() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = null;
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'xxx';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.startTest();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServiceResfreshTokenTest5() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = null;
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'xxx';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.startTest();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServiceResfreshTokenTest6() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = null;
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'xxx';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.startTest();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServiceResfreshTokenTest7() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = null;
		gda.RefreshToken__c = 'xxx';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today().addDays(5);
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.startTest();
		GoogleDriveService.refreshAuthToken();
		Test.stopTest();
	}
	
	@isTest
	private static void GoogleDriveServicegetFileInfoTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		GoogleDriveService.getFileInfo('xxx');
		Test.stopTest();
	}

	
	@isTest
	private static void GoogleDriveServicegetUploadFileGDriveTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;

		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		GoogleDriveService.uploadFileGDrive('fileName', 'text/csv', '1QJwd85a8Sq97eG7xL2QzrR67f1dYkYht', 'row1,row2,row3');
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServicesSaveDocusignPDFtoGDriveTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;
		
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		ContentVersion cv=new Contentversion();
		cv.title='ABC';
		cv.PathOnClient = 'abc';
		Blob b=Blob.valueOf('This is version data');
		cv.versiondata=b;
		insert cv;

		Opportunity o = new Opportunity(Name = 'Test', CloseDate = System.today(), StageName = 'Qualification');
		o.GDriveFolderStructureJSON__c = '{"msg":null,"isSuccess":false,"structure":{"subfolders":[{"subfolders":[],"folderName":"01 Archiv","folderId":"1b8ZT8lPAKBynjEy6gxNSU6tgXlMVjVav"},{"subfolders":[],"folderName":"02 Podklady","folderId":"1Sqiid4SpfIJeOPMndxiKFh8Qs2gQK_tZ"},{"subfolders":[],"folderName":"03 Nabidky Subdodavatel","folderId":"1pf7NN4ZfzXXiPmbL-AWpDHn8sKXREVBL"},{"subfolders":[],"folderName":"04 Objednavka Smlouva Specifikace","folderId":"1-GprT1349hQIaIH5Wky69WYWDgQo_ZIr"},{"subfolders":[],"folderName":"05 Predavaci protokol","folderId":"15GFelFfe-nTyvmM-COXOlxSI8gh0X3nA"},{"subfolders":[],"folderName":"06 Foto realizace","folderId":"1EVATEyQRnri0ZDL9L0fWfxau5UpfCUKF"},{"subfolders":[],"folderName":"07 Schvalena dokumentace","folderId":"164R3CUHLOsfFEnZMwAT4kTJTW8km-9bz"}],"folderName":"2200000.01_test docusing pdfs","folderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"},"parentFolderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"}';
		insert o;
		System.enqueueJob(new GoogleDriveQueueableService(o.Id, new Set<Id>{cv.Id}));
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServicesSaveDocusignPDFtoGDrive2Test() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;
		
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		ContentVersion cv=new Contentversion();
		cv.title='ABC';
		cv.PathOnClient = 'abc';
		Blob b=Blob.valueOf('This is version data');
		cv.versiondata=b;
		insert cv;

		Opportunity o = new Opportunity(Name = 'Test', CloseDate = System.today(), StageName = 'Qualification');
		o.GDriveFolderStructureJSON__c = '{"msg":null,"isSuccess":false,"structure":{"subfolders":[{"subfolders":[],"folderName":"01 Archiv","folderId":"1b8ZT8lPAKBynjEy6gxNSU6tgXlMVjVav"},{"subfolders":[],"folderName":"02 Podklady","folderId":"1Sqiid4SpfIJeOPMndxiKFh8Qs2gQK_tZ"},{"subfolders":[],"folderName":"03 Nabidky Subdodavatel","folderId":"1pf7NN4ZfzXXiPmbL-AWpDHn8sKXREVBL"},{"subfolders":[{"subfolders":[],"folderName":"Podepsané docu-sign","folderId":"1eBk5GN5AODzXpT3_T3VVM-eTbNpx_N58"}],"folderName":"04 Objednavka Smlouva Specifikace","folderId":"1-GprT1349hQIaIH5Wky69WYWDgQo_ZIr"},{"subfolders":[],"folderName":"05 Predavaci protokol","folderId":"15GFelFfe-nTyvmM-COXOlxSI8gh0X3nA"},{"subfolders":[],"folderName":"06 Foto realizace","folderId":"1EVATEyQRnri0ZDL9L0fWfxau5UpfCUKF"},{"subfolders":[],"folderName":"07 Schvalena dokumentace","folderId":"164R3CUHLOsfFEnZMwAT4kTJTW8km-9bz"}],"folderName":"2200000.01_test docusing pdfs","folderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"},"parentFolderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"}';
		insert o;
		System.enqueueJob(new GoogleDriveQueueableService(o.Id, new Set<Id>{cv.Id}));
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServicesSaveDocusignPDFtoGDrive3Test() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;
		
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		ContentVersion cv=new Contentversion();
		cv.title='ABC_completed';
		cv.PathOnClient = 'abc';
		Blob b=Blob.valueOf('This is version data');
		cv.versiondata=b;
		insert cv;

		Opportunity o = new Opportunity(Name = 'Test', CloseDate = System.today(), StageName = 'Qualification');
		o.GDriveFolderStructureJSON__c = '{"msg":null,"isSuccess":false,"structure":{"subfolders":[{"subfolders":[],"folderName":"01 Archiv","folderId":"1b8ZT8lPAKBynjEy6gxNSU6tgXlMVjVav"},{"subfolders":[],"folderName":"02 Podklady","folderId":"1Sqiid4SpfIJeOPMndxiKFh8Qs2gQK_tZ"},{"subfolders":[],"folderName":"03 Nabidky Subdodavatel","folderId":"1pf7NN4ZfzXXiPmbL-AWpDHn8sKXREVBL"},{"subfolders":[{"subfolders":[],"folderName":"blabol","folderId":"1eBk5GN5AODzXpT3_T3VVM-eTbNpx_N58"}],"folderName":"04 Objednavka Smlouva Specifikace","folderId":"1-GprT1349hQIaIH5Wky69WYWDgQo_ZIr"},{"subfolders":[],"folderName":"05 Predavaci protokol","folderId":"15GFelFfe-nTyvmM-COXOlxSI8gh0X3nA"},{"subfolders":[],"folderName":"06 Foto realizace","folderId":"1EVATEyQRnri0ZDL9L0fWfxau5UpfCUKF"},{"subfolders":[],"folderName":"07 Schvalena dokumentace","folderId":"164R3CUHLOsfFEnZMwAT4kTJTW8km-9bz"}],"folderName":"2200000.01_test docusing pdfs","folderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"},"parentFolderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"}';
		insert o;
		System.enqueueJob(new GoogleDriveQueueableService(o.Id, new Set<Id>{cv.Id}));
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServicesSaveDocusignPDFtoGDrive4Test() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;
		
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		ContentVersion cv=new Contentversion();
		cv.title='ABC_completed';
		cv.PathOnClient = 'abc';
		Blob b=Blob.valueOf('This is version data');
		cv.versiondata=b;
		insert cv;

		Opportunity o = new Opportunity(Name = 'Test', CloseDate = System.today(), StageName = 'Qualification');
		o.GDriveFolderStructureJSON__c = '{"msg":null,"isSuccess":false,"structure":{"subfolders":[{"subfolders":[],"folderName":"01 Archiv","folderId":"1b8ZT8lPAKBynjEy6gxNSU6tgXlMVjVav"},{"subfolders":[],"folderName":"02 Podklady","folderId":"1Sqiid4SpfIJeOPMndxiKFh8Qs2gQK_tZ"},{"subfolders":[],"folderName":"03 Nabidky Subdodavatel","folderId":"1pf7NN4ZfzXXiPmbL-AWpDHn8sKXREVBL"},{"subfolders":[{"subfolders":[],"folderName":"blabol","folderId":"1eBk5GN5AODzXpT3_T3VVM-eTbNpx_N58"}],"folderName":"04 Objednavka Smlouva Specifikace","folderId":"1-GprT1349hQIaIH5Wky69WYWDgQo_ZIr"},{"subfolders":[],"folderName":"05 Predavaci protokol","folderId":"15GFelFfe-nTyvmM-COXOlxSI8gh0X3nA"},{"subfolders":[],"folderName":"06 Foto realizace","folderId":"1EVATEyQRnri0ZDL9L0fWfxau5UpfCUKF"},{"subfolders":[],"folderName":"07 Schvalena dokumentace","folderId":"164R3CUHLOsfFEnZMwAT4kTJTW8km-9bz"}],"folderName":"2200000.01_test docusing pdfs","folderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"},"parentFolderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"}';
		insert o;
		System.enqueueJob(new GoogleDriveQueueableService(o.Id, new Set<Id>{cv.Id}, '1Sqiid4SpfIJeOPMndxiKFh8Qs2gQK_tZ'));
		Test.stopTest();
	}

	@isTest
	private static void GoogleDriveServicesSavePDFtoGDriveTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleDriveAuth__c gda = new GoogleDriveAuth__c();
		gda.Name = 'default';
		gda.AccessToken__c = 'xxx';
		gda.ClientSecret__c = 'sec';
		gda.ClientId__c = 'id';
		gda.RedirectURI__c = 'test';
		gda.RefreshToken__c = 'token';
		gda.Scope__c = 'scope';
		gda.TokenExpireDate__c = System.today();
		gda.TokenType__c = 'Bearer';
		insert gda;
		
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		ContentVersion cv=new Contentversion();
		cv.title='ABC';
		cv.PathOnClient = 'abc';
		Blob b=Blob.valueOf('This is version data');
		cv.versiondata=b;
		insert cv;

		Opportunity o = new Opportunity(Name = 'Test', CloseDate = System.today(), StageName = 'Qualification');
		o.GDriveFolderStructureJSON__c = '{"msg":null,"isSuccess":false,"structure":{"subfolders":[{"subfolders":[],"folderName":"01 Archiv","folderId":"1b8ZT8lPAKBynjEy6gxNSU6tgXlMVjVav"},{"subfolders":[],"folderName":"02 Podklady","folderId":"1Sqiid4SpfIJeOPMndxiKFh8Qs2gQK_tZ"},{"subfolders":[],"folderName":"03 Nabidky Subdodavatel","folderId":"1pf7NN4ZfzXXiPmbL-AWpDHn8sKXREVBL"},{"subfolders":[],"folderName":"04 Objednavka Smlouva Specifikace","folderId":"1-GprT1349hQIaIH5Wky69WYWDgQo_ZIr"},{"subfolders":[],"folderName":"05 Predavaci protokol","folderId":"15GFelFfe-nTyvmM-COXOlxSI8gh0X3nA"},{"subfolders":[],"folderName":"06 Foto realizace","folderId":"1EVATEyQRnri0ZDL9L0fWfxau5UpfCUKF"},{"subfolders":[],"folderName":"07 Schvalena dokumentace","folderId":"164R3CUHLOsfFEnZMwAT4kTJTW8km-9bz"}],"folderName":"2200000.01_test docusing pdfs","folderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"},"parentFolderId":"1V7ZoURnCWCaonMe9uNSKOiftperNKrSm"}';
		insert o;

		Quote q = new Quote(Name = 'test', OpportunityId = o.Id);
		insert q;

		o.SyncedQuoteId = q.Id;
		update o;

		GoogleDriveService.savePDFtoGDrive(false, cv.Id, q.Id);
		Test.stopTest();
	}

	/*=================================================================================================*/
	/* CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT
	/*=================================================================================================*/

	public class GoogleDriveHTTPCalloutMock implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String body;
		protected Map<String, String> responseHeaders;
		public GoogleDriveHTTPCalloutMock(String body) { this.code = 200; this.body = body; }
		public GoogleDriveHTTPCalloutMock(Integer code, String body) { this.code = code; this.body = body; }
		public GoogleDriveHTTPCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
			this.code = code; this.status = status; this.body = body; this.responseHeaders = responseHeaders;
		}
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			if (responseHeaders != null) {
				for (String key : this.responseHeaders.keySet()) { res.setHeader(key, this.responseHeaders.get(key)); }
			}
			res.setBody(this.body);
			res.setStatusCode(this.code);
			if (String.isNotEmpty(this.status)) { res.setStatus(this.status); }
			return res;
		}
	}
}