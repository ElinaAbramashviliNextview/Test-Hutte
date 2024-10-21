public class GoogleDriveController
{
    //Fetched from URL
    public String code {get;set;}
    private string key = '12660517366-tudb2kfvhuap6tc64tm0d9gelov8ha5o.apps.googleusercontent.com' ;
    private string secret = '-Ggayt0TpHTvtDdcZDAiZuDi' ;
    private string redirect_uri = 'https://silentlab--dev--c.visualforce.com/apex/GoogleDrive' ;
	private string resp;
    
    public GoogleDriveController(){
        code = ApexPages.currentPage().getParameters().get('code') ;
		GoogleDriveAuth__c sett = GoogleDriveAuth__c.getInstance('default');
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
    
    public PageReference DriveAuth(){
        //Authenticating
        PageReference pg = new PageReference(GoogleDriveAuthUri(key, redirect_uri)) ;
        return pg ;
    }
    

	// TODO: check state parameter documantation
	// https://developers.google.com/identity/protocols/OAuth2InstalledApp
    public String GoogleDriveAuthUri(String Clientkey,String redirect_uri){
        String key = EncodingUtil.urlEncode(Clientkey,'UTF-8');
        String uri = EncodingUtil.urlEncode(redirect_uri,'UTF-8');
        String authuri = '';
        authuri = 'https://accounts.google.com/o/oauth2/auth?'+
        'client_id='+key+
        '&response_type=code'+
        '&scope=https://www.googleapis.com/auth/drive'+
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

   public void DriveAuthComplete(){
		upsertSettings(resp);
   }

   public void upsertSettings(String httpRespBody){
		Mdl.DriveOAuthResponse OauthResp = (Mdl.DriveOAuthResponse)JSON.deserialize(httpRespBody, Mdl.DriveOAuthResponse.class);

		GoogleDriveAuth__c sett = new GoogleDriveAuth__c();
		sett.Name = 'default';
		sett.AccessToken__c = OauthResp.access_token;
		sett.RefreshToken__c = OauthResp.refresh_token;
		sett.Scope__c = OauthResp.scope;
		sett.TokenType__c = OauthResp.token_type;
		sett.TokenExpireDate__c = System.now().addSeconds(OauthResp.expires_in);

		upsert sett Name;   
   }
}