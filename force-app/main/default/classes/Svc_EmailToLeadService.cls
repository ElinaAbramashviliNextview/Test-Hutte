global class Svc_EmailToLeadService implements Messaging.InboundEmailHandler {
	private static String SVC_NAME = 'EmailToLead';
	/* Subject paterns for sources */
	private static String SRC_SBJ_SLF = 'Zpráva z kontaktního formuláře SilentLab'; 				// SilentLab Form
	private static String SRC_SBJ_AP1 = 'Archiproducts'; 											// Archiproducts - simple
	private static String SRC_SBJ_AP2 = 'has carried out new actions on SilentLab product sheets'; 	// Archiproducts - extended
	private static String SRC_SBJ_ADF = 'ArchDaily Contact Form'; 									// ArchDaily
	private static String SRC_SBJ_ATC = 'User Request via Architonic – action required!'; 			// ARCHITONIC
	private static String[] VALID_SRCS = new String[]{SRC_SBJ_SLF,SRC_SBJ_AP1,SRC_SBJ_AP2,SRC_SBJ_ADF,SRC_SBJ_ATC};

	private static Map<String, String> fieldMappingByMarkerMap = new Map<String,String>{
		'Jméno:' => 'LastName',
		'E-mail:' => 'Email',
		'Společnost:' => 'Company',
		'Tel.:' => 'Phone',
		'Místo realizace:' => 'Locality__c',
		'Souhlas se zasíláním obchodních sdělení:' => '',
		'Zpráva:' => 'Description',
		'Name:' => 'LastName',
		'Name' => 'LastName',
		'Company/Studio Name:' => 'Company',
		'Address:' => 'Street',
		'Postcode:' => 'PostalCode',
		'Town/City:' => 'City',
		//'Country:' => 'Country',
		'Country:' => '',
		'Language:' => 'Language__c',
		'Language' => 'Language__c',
		'Privacy Policy (GDPR (UE) 2016/679)' => '',
		'FAO SILENTLAB,' => 'Description',
		'DETAILS OF PERSON REQUESTING INFORMATION' => '',
		'Surname:' => 'LastName',
		'Profession:' => 'Title',
		'Locality:' => 'Locality__c',
		'This information' => '',
		'Email:' => 'Email',
		'Phone' => 'Phone',
		'Location and date' => 'Locality__c',
		'Product' => 'Dsecription',
		'ArchDaily' => '',
		'Email' => 'Email',
		'<mailto:' => '',
		'&lt;mailto' => '',
		'Company' => 'Company',
		'City' => 'City',
		//'Country' => 'Country',
		'Country' => '',
		'[cid:' => '',
		'This information has been added to the' => ''
	};

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
		
		// Get source
		Integer srcType;
		if(String.isNotEmpty(email.Subject)){
			for(Integer i=0; i<VALID_SRCS.size(); i++){
				if(email.Subject.contains(VALID_SRCS[i])){
					srcType = i;
					break;
				}
			}
		}

		// Get origin Address
		String origEmails = 'ENVELOPE FROM ADDRESS: '+env.fromAddress+' \n EMAIL FROM NAME: '+email.fromName+' \n EMAIL FROM ADDRESS: '+email.fromAddress+' \n EMAIL HEADERS: \n------------------\n'+email.headers;

		// Get body
		String body = '';
		if(String.isNotEmpty(email.plainTextBody)){
			body = email.plainTextBody; // Get plaintex body as primary source
		} else if(String.isNotEmpty(email.htmlBody)){
			body = email.htmlBody.stripHtmlTags(); // Eventually get plain text from HTML body
		} else {
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_WARNING, 206, 'WARN: EMPTY EMAIL BODY');
			result.success = true;
			return result;
		}
		parseLeadInfo(body, srcType, origEmails, email.fromName);

		result.success = true;
		return result;
	}


	private static void parseLeadInfo(String body, Integer src, String origEmails, String fromName){
		System.debug('parseLeadInfo()');
		Lead l = new Lead();
		Boolean isValidSrc = true;
		Map<String, Integer> markerPostionMap = new Map<String, Integer>{};

		try{
			// prepare map with positions of strings
			for(String s : fieldMappingByMarkerMap.keySet()){
				markerPostionMap.put(s, body.indexOf(s));
			}
			// check if body containts Surname:, based on this, name will be put to FirstName
			Boolean hasSurnameInBody = (markerPostionMap.get('Surname:') != -1);

			// itearate over markers
			for(String mrk : fieldMappingByMarkerMap.keySet()){
				Integer mrkPosition = markerPostionMap.get(mrk);
				// if marker postion is -1, marker is not in text, move to another
				if(mrkPosition == -1){continue;}
				
				// Zpráva: is exception, this marker is used with substringAfter method, no need to find another marker
				if(mrk == 'Zpráva:'){
					l.Description = body.substringAfter('Zpráva:');
					continue;
				}
				System.debug('Actual Marker: ' + mrk + ' Position: ' + mrkPosition);
				// try to find next nearest marker in body
				Integer nextMrkPosition = -1;
				String nextMarkerText= null;
				for(String nextMarker : markerPostionMap.keySet()){
					// some Markers contains other markers inside such as Town/City (in this case city marker must be skipped)
					if(mrk == 'Town/City:' && nextMarker == 'City'){continue;}
					if(mrk == 'Company/Studio Name:' && nextMarker == 'Company'){continue;}
					// actual marker index
					Integer tmp = markerPostionMap.get(nextMarker);
					// System.debug('NextMarker: '+  nextMarker + ' pos: ' + tmp);
					if(tmp != -1 && mrkPosition < tmp && (nextMrkPosition == -1 || nextMrkPosition > tmp)){ 
						nextMrkPosition = tmp;
						nextMarkerText = nextMarker;
					}
				}

				// nextMrkPostion = -1, next marker not found, something is wrong
				if(nextMrkPosition == -1){
					System.debug('Next Marker not found for Marker: ' + mrk);
				// nextMarker found
				}else{
					System.debug('Next Marker position: ' + nextMrkPosition);
					// check if mapping from marker to SF object exits
					String sfField = fieldMappingByMarkerMap.get(mrk);
					// Mapping doesnt exists
					if(String.isBlank(sfField)){
						System.debug('SF Field mapping not found for: ' + mrk);
						continue;
					}

					String textVal = body.substringBetween(mrk, nextMarkerText).trim();
					// remove : if strings starts with it
					if(!String.isBlank(textVal) && textVal.startsWith(':')){
						textVal = textVal.replaceFirst(':', '').trim();
					}
					// email field fix
					// somethimes email is pasted with <mailto: tag, due to multiple emails in text
					// if so take string before this tag
					if(textVal.contains('<mailto:')){
						textVal = textVal.substringBefore('<mailto:');
					}
					if(textVal.contains('&lt;mailto')){
						textVal = textVal.substringBefore('&lt;mailto');
					}
					// language fix
					if(mrk.contains('Language') && textVal.contains('Location')){
						textVal = textVal.substringBefore('Location').trim();
					}
					// check if name should be put to firstName or LastName, based ing hasSurnameInBody
					if(mrk == 'Name:' && hasSurnameInBody){
						l.put('FirstName', textVal);
						System.debug('### LEAD First Name: ' + textVal);
					}else if(mrk == 'Name:' && !hasSurnameInBody){
						l.put('LastName', textVal);
						System.debug('### LEAD Last Name: ' + textVal);
					}else{
						l.put(sfField, textVal);
						System.debug('### LEAD '+ sfField +': ' + textVal);

					}
				}
			}

			System.debug('Populated Lead:');
			System.debug(l);

			if(String.isEmpty(l.Company) || (l.Company != null && String.isEmpty(l.Company.trim()))){
				l.Company = 'UNDEFINED-'+String.valueOf(Datetime.now());
			}
			if(String.isEmpty(l.LastName) || (l.LastName != null && String.isEmpty(l.LastName.trim()))){
				l.LastName = Hlp.getStringWithLength('FROM MAIL:'+fromName, 80);
			}
			l.OriginalEmails__c =  Hlp.getStringWithLength(origEmails, 9900);
			l.Message__c = Hlp.getStringWithLength(body,32000);
			l.LeadSource = 'Website';

			// Insert ignore duplicate rules to prevent fail due to them
			Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.allowSave = true;
			Database.SaveResult sr = Database.insert(l, dml);
			if(!sr.isSuccess()){
				System.debug('Error while saving lead:');
				for(Database.Error er : sr.getErrors()){
					System.debug('MSG: ' + er.message + ' FLD: ' + er.fields);
				}
			}
			if(isValidSrc){
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, 200, 'New Lead created');
			}else{
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_WARNING, 206, 'WARN: UNSUPPORTED SOURCE - New Lead created', Hlp.getStringWithLength(body,32000));
			}
		}catch(Exception e){
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 500, e.getMessage(), e.getStackTraceString(), JSON.serializePretty(l));
		}
	}

	// original parsing method
	/*private static void parseLeadInfo(String body, Integer src, String origEmails, String fromName){
		Lead l = new Lead();
		Boolean isValidSrc = true;
		try{
			switch on src {
				when 0 {
					l.LastName = body.substringBetween('Jméno:','E-mail:');
					l.Email = body.substringBetween('E-mail:','Společnost:');
					l.Company = body.substringBetween('Společnost:','Tel.:');
					l.Phone = body.substringBetween('Tel.:','Místo realizace:');
					l.Locality__c = body.substringBetween('Místo realizace:','Souhlas se zasíláním obchodních sdělení:');
					l.Description = body.substringAfter('Zpráva:');
				}
				when 1 {
					l.LastName = body.substringBetween('Name:','Company/Studio Name:');
					l.Company = body.substringBetween('Company/Studio Name:','Address:');
					l.Street = body.substringBetween('Address:','Postcode:');
					l.PostalCode = body.substringBetween('Postcode:','Town/City:');
					l.City = body.substringBetween('Town/City:','Country:');
					l.Country = body.substringBetween('Country:','E-mail:');
					l.Email = body.substringBetween('E-mail:','Tel.:');
					l.Phone = body.substringBetween('Tel.:','Language:');
					l.Language__c = body.substringBetween('Language:','Privacy Policy (GDPR (UE) 2016/679)');
					l.Description = body.substringBetween('FAO SILENTLAB,','DETAILS OF PERSON REQUESTING INFORMATION');
				}
				when 2 {
					l.FirstName = body.substringBetween('Name:','Surname:');
					l.LastName = body.substringBetween('Surname:','Profession:');
					l.Title = body.substringBetween('Profession:','Locality:');
					l.Locality__c = body.substringBetween('Locality:','Country:');
					l.Email = body.substringBetween('E-mail:','This information');
				}
				when 3 {
					l.LastName = body.substringBetween('Name:','Email:');
					l.Email = body.substringBetween('Email:','Phone');
					l.Phone = body.substringBetween('Phone','Location and date');
					l.Locality__c = body.substringBetween('Location and date','Product');
					l.Description = body.substringBetween('Product','ArchDaily');
				}
				when 4 {
					l.LastName =  body.substringBetween('Name','Email').trim();
					l.Email =  body.substringBetween('Email','<mailto:').trim();
					l.Company = body.substringBetween('Company','Name').trim();
					l.City = body.substringBetween('City','Country').trim();
					l.Country = body.substringBetween('Country','[cid:').trim();

					System.debug('l.LastName: ' + l.LastName );
					System.debug('l.Email: ' + l.Email );
					System.debug('l.Company: ' + l.Company );
					System.debug('l.City: ' + l.City );
					System.debug('l.Country: ' + l.Country );
									}
				when else {
					isValidSrc = false;
				}
			}

			if(String.isEmpty(l.Company) || (l.Company != null && String.isEmpty(l.Company.trim()))){
				l.Company = 'UNDEFINED-'+String.valueOf(Datetime.now());
			}
			if(String.isEmpty(l.LastName) || (l.LastName != null && String.isEmpty(l.LastName.trim()))){
				l.LastName = Hlp.getStringWithLength('FROM MAIL:'+fromName, 80);
			}
			l.OriginalEmails__c =  Hlp.getStringWithLength(origEmails, 9900);
			l.Message__c = Hlp.getStringWithLength(body,32000);
			l.LeadSource = 'Website';

			// Insert ignore duplicate rules to prevent fail due to them
			Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.allowSave = true;
			Database.SaveResult sr = Database.insert(l, dml); 
			if(isValidSrc){
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, 200, 'New Lead created');
			}else{
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_WARNING, 206, 'WARN: UNSUPPORTED SOURCE - New Lead created', Hlp.getStringWithLength(body,32000));
			}
		}catch(Exception e){
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 500, e.getMessage(), e.getStackTraceString(), JSON.serializePretty(l));
		}
	}*/
}