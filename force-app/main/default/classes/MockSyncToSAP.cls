/*
 Author: Dominik Cwynar (dominikcwynar@nextviewconsulting.com)
 Description: Test Class allowing to mock Http Responses for testing purposes of Sync To SAP Services
 */
@IsTest
global class MockSyncToSAP implements HttpCalloutMock {
  public Integer statusCode;
  public Boolean isSuccess;

  public MockSyncToSAP(Integer statusCode, Boolean isSuccess) {
    this.statusCode = statusCode;
    this.isSuccess = isSuccess;
  }

  global HttpResponse respond(HttpRequest req) {
    if (!isSuccess) {
      throw new CalloutException('Mock callout failed');
    }

    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setStatusCode(this.statusCode);
    res.setBody(
      this.statusCode == 200 ? '{"success":true}' : '{"success":false}'
    );

    return res;
  }
}
