@isTest 
private class Svc_CNBRatesSyncTest {

	@isTest
	private static void Svc_CNBRatesSyncTest() {
		Test.setMock(HttpCalloutMock.class, new CnbHTTPCalloutMock('01.11.2019 #212\nzemě|měna|množství|kód|kurz\nAustrálie|dolar|1|AUD|15,798\nBrazílie|real|1|BRL|5,742\nBulharsko|lev|1|BGN|13,046\nČína|žen-min-pi|1|CNY|3,253\nDánsko|koruna|1|DKK|3,415\nEMU|euro|1|EUR|25,515\nFilipíny|peso|100|PHP|45,331\nHongkong|dolar|1|HKD|2,923\nChorvatsko|kuna|1|HRK|3,422\nIndie|rupie|100|INR|32,371\nIndonesie|rupie|1000|IDR|1,632\nIsland|koruna|100|ISK|18,476\nIzrael|nový šekel|1|ILS|6,498\nJaponsko|jen|100|JPY|21,189\nJižní Afrika|rand|1|ZAR|1,516\nKanada|dolar|1|CAD|17,377\nKorejská republika|won|100|KRW|1,963\nMaďarsko|forint|100|HUF|7,771\nMalajsie|ringgit|1|MYR|5,499\nMexiko|peso|1|MXN|1,196\nMMF|ZPČ|1|XDR|31,596\nNorsko|koruna|1|NOK|2,510\nNový Zéland|dolar|1|NZD|14,726\nPolsko|zlotý|1|PLN|5,999\nRumunsko|leu|1|RON|5,366\nRusko|rubl|100|RUB|35,897\nSingapur|dolar|1|SGD|16,864\nŠvédsko|koruna|1|SEK|2,385\nŠvýcarsko|frank|1|CHF|23,168\nThajsko|baht|100|THB|75,885\nTurecko|lira|1|TRY|4,002\nUSA|dolar|1|USD|22,906\nVelká Británie|libra|1|GBP|29,666\n'));
		Svc_CNBRatesSync.syncCNBRates();
	}

	@IsTest
	private static void Svc_CNBRatesSyncSchedulableTest(){
		Svc_CNBRatesSyncSchedulable.scheduleJob();
		Svc_CNBRatesSyncSchedulable.cancel();
	}

	@IsTest
	private static void Svc_CNBRatesSyncSchedulableTest2(){
		Test.setMock(HttpCalloutMock.class, new CnbHTTPCalloutMock(''));
		Svc_CNBRatesSyncSchedulable.worker();
	}

	/*=================================================================================================*/
	/* CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT
	/*=================================================================================================*/

	public class CnbHTTPCalloutMock implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String body;
		protected Map<String, String> responseHeaders;
		public CnbHTTPCalloutMock(String body) { this.code = 200; this.body = body; }
		public CnbHTTPCalloutMock(Integer code, String body) { this.code = code; this.body = body; }
		public CnbHTTPCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
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