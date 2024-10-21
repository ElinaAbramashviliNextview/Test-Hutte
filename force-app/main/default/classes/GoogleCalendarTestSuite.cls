@isTest 
private class GoogleCalendarTestSuite {

	@isTest
	private static void GoogleCalendarOAuthControllerTest() {
		GoogleCalendarOAuthController con = new GoogleCalendarOAuthController();
		PageReference pr = con.CalendarAuth();
		Test.setMock(HttpCalloutMock.class, new GoogleCalendarHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		con.AccessToken();
	}


	@isTest
	private static void GoogleCalendarCreateEventTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = 'token';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;


		Test.setMock(HttpCalloutMock.class, new GoogleCalendarHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Order__c ord = new Order__c(Name='test', ShippingAddressTxt__c = 'test', RealizationEndDate__c = System.today(), RealizationStartDate__c = System.today());
		insert ord;
		Test.startTest();
		GoogleCalendarService.createEvent(System.today(), System.today(), 'Name', 'Desc', 'LocString',ord.Id);
		Test.stopTest();
	}


	@isTest
	private static void GoogleCalendarServiceResfreshTokenTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = 'token';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.setMock(HttpCalloutMock.class, new GoogleCalendarHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));
		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleCalendarServiceResfreshTokenTest2() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleCalendarServiceResfreshTokenTest3() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = null;
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

		@isTest
	private static void GoogleCalendarServiceResfreshTokenTest4() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = null;
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = 'xxx';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleCalendarServiceResfreshTokenTest5() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = null;
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = 'xxx';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleCalendarServiceResfreshTokenTest6() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = null;
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = 'xxx';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleCalendarServiceResfreshTokenTest7() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;
		
		
		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = null;
		gca.RefreshToken__c = 'xxx';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.startTest();
		GoogleCalendarService.refreshAuthToken();
		Test.stopTest();
	}

	@isTest
	private static void GoogleCalendarGetUpdatedGoogleCalEventsTest() {
		TriggerSettings__c ts = new TriggerSettings__c();
		ts.SetupOwnerId = UserInfo.getUserId();
		ts.Disable_All__c = true;
		insert ts;

		GoogleCalendarAuth__c gca = new GoogleCalendarAuth__c();
		gca.Name = 'default';
		gca.AccessToken__c = 'xxx';
		gca.ClientSecret__c = 'sec';
		gca.ClientId__c = 'id';
		gca.RedirectURI__c = 'test';
		gca.RefreshToken__c = 'token';
		gca.Scope__c = 'scope';
		gca.TokenExpireDate__c = System.today().addDays(5);
		gca.TokenType__c = 'Bearer';
		insert gca;

		Test.setMock(HttpCalloutMock.class, new GoogleCalendarHTTPCalloutMock('{ "items": [ { "id": "kmptac8dvknv692s4r0dc2mlts", "x_start": { "x_dateTime": "2020-03-31T13:00:00+02:00" }, "x_end": { "x_dateTime": "2020-03-31T14:00:00+02:00" } }, { "id": "e478dvpprnl2vfbbaik3ciuiog", "x_start": { "x_date": "2020-04-01" }, "x_end": { "x_date": "2020-04-01" } }, { "id": "k6clogta9u5375fnri5n63ghbk", "x_start": { "x_date": "2020-04-02" }, "x_end": { "x_date": "2020-04-02" } }, { "id": "crta584cp827b86hq554qmupj0", "x_start": { "x_date": "2020-04-06" }, "x_end": { "x_date": "2020-04-10" } }, { "id": "4ukvg3253lt0pap9uq54gnek97", "x_start": { "x_date": "2020-04-06" }, "x_end": { "x_date": "2020-04-08" } } ] }'));
		Test.startTest();
		GoogleCalendarService.getUpdatedGoogleCalEvents();
		Test.stopTest();
	}

	@IsTest
	private static void GoogleCalendarSyncSchedulableTest(){
		GoogleCalendarSyncSchedulable.scheduleJob();
		GoogleCalendarSyncSchedulable.cancel();
		
	}

	/*=================================================================================================*/
	/* CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT
	/*=================================================================================================*/

	public class GoogleCalendarHTTPCalloutMock implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String body;
		protected Map<String, String> responseHeaders;
		public GoogleCalendarHTTPCalloutMock(String body) { this.code = 200; this.body = body; }
		public GoogleCalendarHTTPCalloutMock(Integer code, String body) { this.code = code; this.body = body; }
		public GoogleCalendarHTTPCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
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