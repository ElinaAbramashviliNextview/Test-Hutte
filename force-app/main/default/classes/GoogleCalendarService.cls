public class GoogleCalendarService  {
	public class GoogleCalendarServiceException extends Exception {}

	// Drive Token response used as is sale for google drive and google calendar
	// TODO: rename model properly
	public static Mdl.DriveTokenRefreshResponse refreshAuthToken(){
		Mdl.DriveTokenRefreshResponse res = new Mdl.DriveTokenRefreshResponse();
		GoogleCalendarAuth__c authSettings = GoogleCalendarAuth__c.getInstance('default');
		if(authSettings == null){
			res.msg = 'No settings defined, authorize first.';
			return res;
		}
		if(authSettings.RefreshToken__c == null){
			res.msg ='Refresh token missing, cannot refresh Authorization Token';
			return res;
		}
		if(authSettings.AccessToken__c == null){
			res.msg ='Refresh token missing, cannot refresh Authorization Token';
			return res;
		}
		if(authSettings.ClientId__c == null){
			res.msg ='Client ID missing, configure Custom Settings';
			return res;
		}
		if(authSettings.ClientSecret__c == null){
			res.msg ='Client Secret missing, configure Custom Settings';
			return res;
		}
		if(authSettings.RedirectURI__c == null){
			res.msg ='Redirect URI missing, configure Custom Settings';
			return res;
		}

		String body = 'client_id='+authSettings.ClientId__c+'&client_secret='+authSettings.ClientSecret__c+'&refresh_token='+authSettings.RefreshToken__c+'&grant_type=refresh_token';

		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
		req.setHeader('content-type', 'application/x-www-form-urlencoded');
		req.setBody(body);
		req.setTimeout(60*1000);
		Http h = new Http();
		HttpResponse httpRes;
		try{	        
			httpRes = h.send(req);
			Mdl.DriveOAuthResponse OauthResp = (Mdl.DriveOAuthResponse)JSON.deserialize(httpRes.getBody(), Mdl.DriveOAuthResponse.class);
			res.authTkn = OauthResp.access_token;
			res.validTo = Datetime.now().addSeconds(OauthResp.expires_in);
			res.isSuccess = true;
		}catch(Exception e){
			System.debug(e.getMessage());
			res.msg = e.getMessage();
		}
		return res;
	}

	public static void createEvent(Date startDate, Date endDate, String name, String descr, String loc, Id ordId){
		String SVC_NAME = 'GC_CreateEvent';
		Mdl.CreateEventResult res = new Mdl.CreateEventResult();

		GoogleCalendarAuth__c authSettings = GoogleCalendarAuth__c.getInstance('default');
		if(authSettings == null){
			res.msg = 'No settings defined, authorize first.';
			return;
		}
		// check if token expires in following 5 mins, if so refresh
		if(authSettings.TokenExpireDate__c.addMinutes(-5) <= Datetime.now()){
			Mdl.DriveTokenRefreshResponse refrehRes = refreshAuthToken();
			if(!refrehRes.isSuccess){
				res.msg = 'Token refresh failed: ' + refrehRes.msg;
				return;
			}else{
				authSettings.AccessToken__c = refrehRes.authTkn;
				authSettings.TokenExpireDate__c = refrehRes.validTo;
			}
		}

		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint('https://www.googleapis.com/calendar/v3/calendars/'+ authSettings.CalendarId__c +'/events');
		req.setHeader('content-type', 'application/json');
		req.setHeader('Authorization', 'Bearer ' + authSettings.AccessToken__c);
		String body = '{ "end": { "date": "'+ getFormatedDate(endDate) + '" }, "start": { "date": "'+ getFormatedDate(startDate)+'" }, "summary": "'+ name +'", "description": "'+ descr +'", "location": "'+ loc +'", "reminders": { "useDefault": false } }';
		req.setBody(body);
		req.setTimeout(60000);

		Http h = new Http();
		HttpResponse httpRes = new HttpResponse();
		try{	        
			httpRes = h.send(req);
			String calendarResString = httpRes.getBody();
			//replace id and name properties to be able to deserialize to model (SF limitation)
			//driveResString = driveResString.replace('"id"','"x_id"').replace('"name"', '"x_name"');
			System.debug('Create event response: ' + calendarResString);
			
			Mdl.CreateEventResult evtRes = (Mdl.CreateEventResult)JSON.deserialize(calendarResString, Mdl.CreateEventResult.class);
			
			System.debug('Returned event ID: ' + evtRes.id);
			res.isSuccess = true;

			Order__c ord = new Order__c(Id= ordId, Eid__c = evtRes.id);
			update ord;
			update authSettings;
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, httpRes.getStatusCode(), 'SUCCESS: Event created('+ordId+')', body);
		}
		catch (Exception e){
			res.msg = 'Create event failed: ' + e.getMessage();
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, httpRes.getStatusCode(), 'ERROR - something wents wrong: ' + httpRes.getStatus(), String.valueOf(httpRes), body);
		}
		return;
	}

	@Future(callout=true)
	public static void getUpdatedGoogleCalEvents(){
		Mdl.CreateEventResult res = new Mdl.CreateEventResult();

		GoogleCalendarAuth__c authSettings = GoogleCalendarAuth__c.getInstance('default');
		if(authSettings == null){
			res.msg = 'No settings defined, authorize first.';
			return;
		}
		// check if token expires in following 5 mins, if so refresh
		if(authSettings.TokenExpireDate__c.addMinutes(-5) <= Datetime.now()){
			Mdl.DriveTokenRefreshResponse refrehRes = refreshAuthToken();
			if(!refrehRes.isSuccess){
				res.msg = 'Token refresh failed: ' + refrehRes.msg;
				return;
			}else{
				authSettings.AccessToken__c = refrehRes.authTkn;
				authSettings.TokenExpireDate__c = refrehRes.validTo;
			}
		}

		String endpoint = 'https://www.googleapis.com/calendar/v3/calendars/'+ authSettings.CalendarId__c +'/events?fields=items(id,start,end)';
		if(authSettings.LastSyncDate__c != null){
			//google only accepts datetime in format yyyy-MM-ddTHH:mm:ss:SSSZ
			endpoint += '&updatedMin=' + authSettings.LastSyncDate__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS')+'Z';
		}
		System.debug('endpoint: ' + endpoint);
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(endpoint);
		req.setHeader('Authorization', 'Bearer ' + authSettings.AccessToken__c);
		req.setTimeout(60000);

		Http h = new Http();
		try{	        
			HttpResponse httpRes = h.send(req);
			String calendarResString = httpRes.getBody();
			//replace reserved names so we can deserialize JSON to our model
			calendarResString = calendarResString.replace('"date"','"x_date"').replace('"dateTime"', '"x_dateTime"').replace('"start"', '"x_start"').replace('"end"', '"x_end"');
			System.debug('GetCalendarItems response: ' + calendarResString);
			
			Mdl.CalendarEvents evtRes = (Mdl.CalendarEvents)JSON.deserialize(calendarResString, Mdl.CalendarEvents.class);
			
			Order__c[] ords = new Order__c[]{};
			for(Mdl.Item item : evtRes.items){
				Order__c tmp = new Order__c();
				tmp.EId__c = item.id;
				// check and populate start date
				if(item.x_start.x_date != null){
					tmp.RealizationStartDate__c = item.x_start.x_date;
				}else if(item.x_start.x_dateTime != null){
					tmp.RealizationStartDate__c = item.x_start.x_dateTime.date();
				}else{
					System.debug('Event from Google Calendar not contain Start date or datetime ('+ item.id+')');
					continue;
				}
				// check and populate end date
				if(item.x_end.x_date != null){
					tmp.RealizationEndDate__c = item.x_end.x_date;
				}else if(item.x_end.x_dateTime != null){
					tmp.RealizationEndDate__c = item.x_end.x_dateTime.date();
				}else{
					System.debug('Event from Google Calendar not contain End date or datetime ('+ item.id+')');
					continue;
				}

				// fix for multiday events (Google returns end date +1 for events longer than 1 day)
				if(tmp.RealizationEndDate__c > tmp.RealizationStartDate__c){
					tmp.RealizationEndDate__c= tmp.RealizationEndDate__c.addDays(-1);
				}
				ords.add(tmp);
			}

			if(ords.size() > 0){
				Database.upsert(ords, Order__c.EId__c, false);
			}
			authSettings.LastSyncDate__c = Datetime.now();
			update authSettings;

		}
		catch (Exception e){
			res.msg = 'GetCalendarItems failed: ' + e.getMessage();
			System.debug(res.msg);
		}
		return;
	
	}

	public static String getFormatedDate(Date d){
		return d.year() + '-' + String.valueOf(d.month()).leftPad(2, '0') + '-' + String.valueOf(d.day()).leftPad(2, '0');
	}
	
}