public class Svc_CNBRatesSync {
	private static String endpointBase = 'https://www.cnb.cz/cs/financni-trhy/devizovy-trh/kurzy-devizoveho-trhu/kurzy-devizoveho-trhu/denni_kurz.txt?date=';

	public static void syncCNBRates(){
		syncCNBRates(System.today());
	}

    @future(callout=true)
	public static void syncCNBRates(Date dt) {
		System.debug('syncCNBRates()');

		// get data from CNB endpoint
		//Date today = System.today();
		String datePart = String.valueOf(dt.day()) + '.' + String.valueOf(dt.month()) + '.' + String.valueOf(dt.year());
		System.debug(datePart);

		String endpoint = endpointBase;
		HttpRequest req = new HttpRequest();
		req.setEndpoint(endpointBase + datePart);
		req.setMethod('GET');

		Http http = new Http();
		HTTPResponse res = http.send(req);

		System.debug(res.getBody());

		//get custom settings, to detect if advacend currency sync should be used
		CNBRatesSyncSettings__c sett = CNBRatesSyncSettings__c.getValues('default');

		// prepare data from response
		String[] resRows = res.getBody().split('\n'); //split returned information by new line, each exhange rate has own line in text file
		System.debug(resRows.size());
		Map<String, ExchnageRateData> exRateDataByIsoCodeMap = new Map<String, ExchnageRateData> { };
		Integer i = 0;
		for (String s : resRows) {
			i++;
			if (i <= 2) { continue; } // skip first two rows (contains useless info)
			String[] tmpList = s.split('\\|'); // values are delimited by |
			ExchnageRateData erd = new ExchnageRateData();
			erd.amount = Double.valueOf(tmpList[2]);
			erd.code = tmpList[3];
			erd.rate = Double.valueOf(tmpList[4].replace(',', '.'));
			exRateDataByIsoCodeMap.put(erd.code, erd);
		}

		CurrencyType[] cts = [SELECT ConversionRate, IsoCode FROM CurrencyType WHERE IsActive = True AND IsCorporate = false];
		CurrencyType[] ctUpdate = new CurrencyType[] { };
		String reqBody = '{"records" :[';
		for (CurrencyType ct : cts) {
			ExchnageRateData tmp = exRateDataByIsoCodeMap.get(ct.IsoCode);
			if(sett != null && sett.isStandardCurrRateSync__c){
			// if(sett == null || !sett.isAdvancedCurrRateSync__c){ // TODO: create custom settings to swich between currencyType and DatedCurrecyType sync mode
				if (tmp != null && tmp.amount != null && tmp.rate != null) {
					Double exRate = tmp.amount / tmp.rate;
					// due to Salesforce limitation, CurrencyType object can be only updated through SOAP API
					currencyTypeSoapUpdate(tmp.code, exRate);
				}
			}
			if(sett != null && sett.isAdvancedCurrRateSync__c){
				if (tmp != null && tmp.amount != null && tmp.rate != null) {
					Double exRate = tmp.amount / tmp.rate;
					String dateTxt = String.valueOf(dt.year()) + '-' +String.valueOf(dt.month()).leftPad(2,'0') + '-' + String.valueOf(dt.day()).leftPad(2,'0');
					reqBody += getDatedConversionRateRow(tmp.code, exRate, dateTxt);
				}
			}
			
		}
		reqBody = reqBody.removeEnd(',');
		reqBody += ']}';
		System.debug(reqBody);
		if(sett != null && sett.isAdvancedCurrRateSync__c){ // TODO: create custom settings to swich between currencyType and DatedCurrecyType sync mode
			datedConversionRateSoapCallout(reqBody);
		}
	}

	//@future(callout=true)
	public static void currencyTypeSoapUpdate(String currISOCode, Double exRate){
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v47.0/sobjects/CurrencyType/');
		req.setMethod('POST');
		req.setBody('{ "IsoCode" : "'+ currISOCode + '", "DecimalPlaces" : 3, "ConversionRate" : '+ exRate +', "IsActive" : "true" }');
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		req.setHeader('Content-Type', 'application/json');
		HttpResponse res = h.send(req);
		System.debug('Currency Update: ' + res.getStatusCode() + ', ' + res.getBody());
	}

	public static String getDatedConversionRateRow(String currISOCode, Double exRate, String DateTxt){
		return '{"attributes" : {"type" : "DatedConversionRate", "referenceId" : "referenceID'+ currISOCode +'"}, "IsoCode" : "'+currISOCode+'", "ConversionRate" : "'+exRate+'", "StartDate" : "'+DateTxt+'"},';
	}

	public static void datedConversionRateSoapCallout(String body){
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v46.0/composite/tree/DatedConversionRate');
		req.setMethod('POST');
		req.setBody(body);
		req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
		req.setHeader('Content-Type', 'application/json');
		HttpResponse res = h.send(req);
		System.debug('Currency Update: ' + res.getStatusCode() + ', ' + res.getBody());
	}

	public class ExchnageRateData {
		public String code { get; set; }
		public Double rate { get; set; }
		public Double amount { get; set; }
	}

}