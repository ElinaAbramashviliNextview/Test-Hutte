public class GoogleCalendarOAuthController
{
    //Fetched from URL
    public String code {get;set;}
    private string key = '12660517366-tudb2kfvhuap6tc64tm0d9gelov8ha5o.apps.googleusercontent.com' ;
    private string secret = '-Ggayt0TpHTvtDdcZDAiZuDi' ;
    private string redirect_uri = 'https://silentlab--dev--c.visualforce.com/apex/GoogleCalendarOAuth' ;
	private string resp;
    
    public GoogleCalendarOAuthController(){
        code = ApexPages.currentPage().getParameters().get('code') ;
		GoogleCalendarAuth__c sett = GoogleCalendarAuth__c.getInstance('default');
		if(sett != null){
			this.key = sett.ClientId__c;
			this.secret = sett.ClientSecret__c;
			this.redirect_uri = sett.RedirectURI__c;
		}
        //Get the access token once we have code
        /*if(code != '' && code != null)
        {
            AccessToken() ;
        }*/
    }
    
    public PageReference CalendarAuth(){
        //Authenticating
        PageReference pg = new PageReference(GoogleCalendarAuthUri(key, redirect_uri)) ;
        return pg ;
    }
    

	// TODO: check state parameter documantation
	// https://developers.google.com/identity/protocols/OAuth2InstalledApp
    public String GoogleCalendarAuthUri(String Clientkey,String redirect_uri){
        String key = EncodingUtil.urlEncode(Clientkey,'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri,'UTF-8');
        String authuri = '';
        authuri = 'https://accounts.google.com/o/oauth2/auth?'+
        'client_id='+key+
        '&response_type=code'+
        '&scope=https://www.googleapis.com/auth/calendar'+
        '&redirect_uri='+uri+
        '&access_type=offline';
        return authuri;
    }
    
    
    public void AccessToken(){
        //Getting access token from google
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        String messageBody = 'code='+code+'&client_id='+key+'&client_secret='+secret+'&redirect_uri='+redirect_uri+'&grant_type=authorization_code';
        req.setHeader('Content-length', String.valueOf(messageBody.length()));
        req.setBody(messageBody);
        req.setTimeout(60*1000);

        Http h = new Http();
        HttpResponse res = h.send(req);
        resp = res.getBody();
        
        System.debug(' You can parse the response to get the access token ::: ' + resp);
		upsertSettings(resp);
   }

   public void CalendarAuthComplete(){
		upsertSettings(resp);
   }

   public void upsertSettings(String httpRespBody){
		Mdl.DriveOAuthResponse OauthResp = (Mdl.DriveOAuthResponse)JSON.deserialize(httpRespBody, Mdl.DriveOAuthResponse.class);

		GoogleCalendarAuth__c sett = new GoogleCalendarAuth__c();
		sett.Name = 'default';
		sett.AccessToken__c = OauthResp.access_token;
		sett.RefreshToken__c = OauthResp.refresh_token;
		sett.Scope__c = OauthResp.scope;
		sett.TokenType__c = OauthResp.token_type;
		sett.TokenExpireDate__c = System.now().addSeconds(OauthResp.expires_in);

		upsert sett Name;   
   }
}