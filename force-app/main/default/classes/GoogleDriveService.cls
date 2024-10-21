public class GoogleDriveService  {
	public class GoogleDriveServiceException extends Exception {}


	public static Mdl.DriveTokenRefreshResponse refreshAuthToken(){
		Mdl.DriveTokenRefreshResponse res = new Mdl.DriveTokenRefreshResponse();
		GoogleDriveAuth__c authSettings = GoogleDriveAuth__c.getInstance('default');
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


	public static void createOppFolderStructure(Opportunity opp){
		Mdl.CreateFolderStructureResult res = new Mdl.CreateFolderStructureResult();
		// get main folder id from custom settings
		GoogleDriveAuth__c authSettings = GoogleDriveAuth__c.getInstance('default');
		if(authSettings == null){
			res.msg = 'No settings defined, authorize first.';
			return;
		}
		if(authSettings.OppParentFolderEId__c == null){
			res.msg = 'No Parent folder defined. Update Custom settings first.';
			return;
		}
		// create parent opp folder
		try {
			String oppName = ((opp.OpportunityNo__c != null) ? opp.OpportunityNo__c + '_' : '') + opp.Name;
			Mdl.CreateFolderResult parentRes = createFolder(oppName, authSettings.OppParentFolderEId__c);
			if(parentRes.isSuccess){
				res.parentFolderId = parentRes.folderID;
				res.structure = new Mdl.DriveFolderInfo();
				res.structure.folderId  = parentRes.folderID;
				res.structure.folderName = oppName;
			}else{
				res.msg = parentRes.msg;
				throw new GoogleDriveServiceException('Create parent folder failed.');
			}
			
			for(String s : Cst.OPP_SUBFOLDER_NAMES_LIST){
				Mdl.CreateFolderResult subfolderRes = createFolder(s, res.parentFolderId);
				if(subfolderRes.isSuccess){
					Mdl.DriveFolderInfo tmp = new Mdl.DriveFolderInfo();
					tmp.folderName = s;
					tmp.folderId = subfolderRes.folderID;
					res.structure.subfolders.add(tmp);
				}else{
					res.msg = subfolderRes.msg;
					throw new GoogleDriveServiceException('Create subfolder failed.');
				}
			}

			Opportunity o = new Opportunity(Id = opp.Id);
			o.GDriveFolderStructureJSON__c = Json.serialize(res);
			o.DriveFolderId__c = res.parentFolderId;
			update o;
			res.isSuccess = true;
		} catch (Exception e) {
			SyncUtils.logServiceActivity('OppGDriveStruct', 'error', 500, 'CreateOppFolderStructure failed', '' , '','Response: ' + res.msg + ' Exception: ' + e.getMessage());
		}
	}

	public static Mdl.CreateFolderResult createFolder(String folderName, String parentId){
		Mdl.CreateFolderResult res = new Mdl.CreateFolderResult();

		GoogleDriveAuth__c authSettings = GoogleDriveAuth__c.getInstance('default');
		if(authSettings == null){
			res.msg = 'No settings defined, authorize first.';
			return res;
		}
		// check if token expires in following 5 mins, if so refresh
		if(authSettings.TokenExpireDate__c.addMinutes(-5) <= Datetime.now()){
			Mdl.DriveTokenRefreshResponse refrehRes = refreshAuthToken();
			if(!refrehRes.isSuccess){
				res.msg = 'Token refresh failed: ' + refrehRes.msg;
				return res;
			}else{
				authSettings.AccessToken__c = refrehRes.authTkn;
				authSettings.TokenExpireDate__c = refrehRes.validTo;
			}
		}

		
		// TEST RELATED
		if(Test.isRunningTest()){
			res.isSuccess = true;
			res.folderID = 'folderID'+System.now();
			return res;
		}
		
		// HTTP Callout
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint('https://www.googleapis.com/drive/v3/files?supportsAllDrives=true');
		req.setHeader('content-type', 'application/json');
		req.setHeader('Authorization', 'Bearer ' + authSettings.AccessToken__c);
		req.setBody('{"name": "'+folderName+'", "parents":["' + parentId + '"],"mimeType": "application/vnd.google-apps.folder" }');
		req.setTimeout(60000);
		
		Http h = new Http();
		try{	        
			HttpResponse httpRes = h.send(req);
			String driveResString = httpRes.getBody();
			System.debug('resp: ' + driveResString);

			if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201){
				Mdl.DriveCreateFolderResponse driveRes = (Mdl.DriveCreateFolderResponse)JSON.deserialize(driveResString, Mdl.DriveCreateFolderResponse.class);
				res.folderID = driveRes.id;
				res.isSuccess = true;
			}else{
				res.msg = 'Status code: ' + httpRes.getStatusCode() + ' ' + httpRes.getBody();
			}
		}
		catch (Exception e){
			res.msg = 'Create folder failed: ' + e.getMessage();
		}
		return res;

		// opp link template 
		//"https://drive.google.com/drive/folders/" + returnedId from google
	}

	public static void getFileInfo(String fileId){
		Mdl.DriveTokenRefreshResponse res = new Mdl.DriveTokenRefreshResponse();

		GoogleDriveAuth__c authSettings = GoogleDriveAuth__c.getInstance('default');
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
		req.setMethod('GET');
		req.setEndpoint('https://www.googleapis.com/drive/v3/files/' + fileId + '?supportsAllDrives=true');
		//req.setHeader('content-type', 'application/json');
		req.setHeader('Authorization', 'Bearer ' + authSettings.AccessToken__c);
		//req.setBody('{"name": "'+folderName+'", "mimeType": "application/vnd.google-apps.folder" }');
		req.setTimeout(60000);

		Http h = new Http();
		try{	        
			HttpResponse httpRes = h.send(req);
			String driveResString = httpRes.getBody();
			//replace id and name properties to be able to deserialize to model (SF limitation)
			//driveResString = driveResString.replace('"id"','"x_id"').replace('"name"', '"x_name"');
			
			System.debug(driveResString);

		}
		catch (Exception e){
			res.msg = 'Get Google Drive File Info failed: ' + e.getMessage();
		}
		return;
	}

	public static Mdl.BaseResponse uploadFileGDrive(String filename, String fileType, String folderId, String base64encodeFile){
		Mdl.BaseResponse res = new Mdl.BaseResponse();
		String SVC_NAME = 'UploadFileGDrive';
		String boundary = '----------9889464542212'; // boundary must be unique and not contained else in body
		String delimiter = '\r\n--' + boundary + '\r\n';
		String close_delim = '\r\n--' + boundary + '--';

		GoogleDriveAuth__c authSettings = GoogleDriveAuth__c.getInstance('default');
		if(authSettings == null){
			res.msg = 'No settings defined, authorize first.';
			return res;
		}
		// check if token expires in following 5 mins, if so refresh
		if(authSettings.TokenExpireDate__c.addMinutes(-5) <= Datetime.now()){
			Mdl.DriveTokenRefreshResponse refrehRes = refreshAuthToken();
			if(!refrehRes.isSuccess){
				res.msg = 'Token refresh failed: ' + refrehRes.msg;
				return res;
			}else{
				authSettings.AccessToken__c = refrehRes.authTkn;
				authSettings.TokenExpireDate__c = refrehRes.validTo;
			}
		}


		String body = delimiter + 'Content-Type: application/json\r\n\r\n' + '{ "name" : "' + filename + '",' + ' "mimeType" : "' + fileType + '",' + '"parents":["'+ folderId +'"]}' + delimiter + 'Content-Type: ' + filetype + '\r\n' + 'Content-Transfer-Encoding: base64\r\n' + '\r\n' + base64encodeFile + close_delim;

		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true');
		req.setHeader('Authorization', 'Bearer ' + authSettings.AccessToken__c);
		req.setHeader('Content-Type', 'multipart/mixed; boundary="' + boundary + '"');
		req.setBody(body);
		req.setTimeout(60000);

		Http h = new Http();
		try{	        
			HttpResponse httpRes = h.send(req);
			String driveResString = httpRes.getBody();
			//replace id and name properties to be able to deserialize to model (SF limitation)
			//driveResString = driveResString.replace('"id"','"x_id"').replace('"name"', '"x_name"');
			
			System.debug(driveResString);
			res.msg = httpRes.getBody();
			res.isSuccess = true;

		}catch (Exception e){
			res.msg = 'Google Drive file upload failed: ' + e.getMessage();
			SyncUtils.logServiceActivity(SVC_NAME, 'error', 500, 'Google Drive file upload failed: ' + e.getMessage(), '' , '');
		}
		SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, 200, 'SUCCESS: Document "'+filename+' transferred ('+res.msg+')');
		return res;
	}
	
	@future(callout=true)
	public static void savePDFtoGDrive(Boolean isQuotePdf, Id cvId, Id quoteId){
		System.debug('savePDFtoGDrive isQuotePdf: ' + isQuotePdf + ' cvId: ' + cvId + ' quoteId' + quoteId);
		
		// get content version with data
		ContentVersion cv = [SELECT Id, Title, VersionData, FileType, FileExtension FROM ContentVersion WHERE ID=: cvId];
		
		// get quote info
		Quote q = [SELECT Id, OpportunityId FROM Quote WHERE Id=: quoteId];

		// get opp and parse gdrive folder structure
		Opportunity opp = [SELECT Id, GDriveFolderStructureJSON__c FROM Opportunity WHERE Id =: q.OpportunityId];

		if(String.isBlank(opp.GDriveFolderStructureJSON__c)){
			system.debug('No gdrive folder structure found, cant upload file.');
			return;
		}
		// parse gdrive folder structure
		Mdl.CreateFolderStructureResult gdr = (Mdl.CreateFolderStructureResult)JSON.deserialize(opp.GDriveFolderStructureJSON__c, Mdl.CreateFolderStructureResult.class);

		// quotePDF goes to opportunity folder root
		String folderId = null;
		if(isQuotePdf){
			folderId = gdr?.parentFolderId;
		}else{
			for(Mdl.DriveFolderInfo dfi : gdr.structure.subfolders){
				System.debug(dfi.folderName + ' ' + dfi.folderId);
				if(dfi.folderName.startsWith('02 Podklady')){
					folderId = dfi.folderId;
				}
			}
		}

		if(folderId == null){
			System.debug('no folder id found.');
			SyncUtils.logServiceActivity('SavePDFtoGDrive', 'error', 500, 'No folder id found', '' , '');
			return;
		}
		system.debug('Folderid: ' + folderId);

		uploadFileGDrive(cv.Title + '.' + cv.FileExtension, 'application/pdf', folderId, EncodingUtil.base64Encode(cv.VersionData));
	}
}