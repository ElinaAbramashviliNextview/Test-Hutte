@isTest
private class SyncTest {
  @TestSetup
  static void makeData() {
    TestDataFactory.createSyncServiceSettings(true);
  }

  //===================================================================================================
  // ACCOUNT AND CONTACT TO SAP - ACCOUNT AND CONTACT TO SAP - ACCOUNT AND CONTACT TO SAP - ACCOUNT AND
  //===================================================================================================
  @isTest
  static void testAccountAndContactToSAPSuccess() {
    Test.setMock(HttpCalloutMock.class, new MockSyncToSAP(200, true));

    Test.startTest();

    Account acc = TestDataFactory.createAccount(true);
    // Create Opportunity to call Sync for parent Account
    TestDataFactory.createOpportunity(acc.Id, true, null);
    Contact con = TestDataFactory.createContact(acc.Id, true);

    Test.stopTest();

    con.SyncStatus__c = 'FORCE';
    update con;

    acc.SyncStatus__c = 'FORCE';
    update acc;

    List<ServiceLog__c> serviceLogs = [
      SELECT Id
      FROM ServiceLog__c
      WHERE
        (ServiceName__c = 'AccountToSAP'
        OR ServiceName__c = 'ContactsToSAP')
        AND ServiceStatus__c = 'error'
        AND ResponseCode__c = 400
    ];
    Assert.areEqual(0, serviceLogs.size(), 'Error should not have occurred');
  }

  @isTest
  static void testAccountToSAPError() {
    Test.setMock(HttpCalloutMock.class, new MockSyncToSAP(400, true));
    Test.startTest();

    Account acc = TestDataFactory.createAccount(true);
    TestDataFactory.createOpportunity(acc.Id, true, null);

    Test.stopTest();

    List<ServiceLog__c> serviceLogs = [
      SELECT Id
      FROM ServiceLog__c
      WHERE
        (ServiceName__c = 'AccountToSAP'
        OR ServiceName__c = 'ContactsToSAP')
        AND ServiceStatus__c = 'error'
        AND ResponseCode__c = 400
    ];
    Assert.areEqual(1, serviceLogs.size(), 'Error should have occurred.');
  }

  @isTest
  static void testAccountToSAPException() {
    Boolean exceptionCaught = false;
    Test.setMock(HttpCalloutMock.class, new MockSyncToSAP(500, false));

    Test.startTest();

    Account acc = TestDataFactory.createAccount(true);
    TestDataFactory.createOpportunity(acc.Id, true, null);

    Test.stopTest();

    List<ServiceLog__c> serviceLogs = [
      SELECT Id
      FROM ServiceLog__c
      WHERE
        (ServiceName__c = 'AccountToSAP'
        OR ServiceName__c = 'ContactsToSAP')
        AND ServiceStatus__c = 'error'
        AND ResponseCode__c = 400
    ];
    Assert.areEqual(
      1,
      serviceLogs.size(),
      'Exception log should have been created.'
    );
  }

  //===================================================================================================
  // ACCOUNT AND CONTACT TO SALESFORCE - ACCOUNT AND CONTACT TO SALESFORCE - ACCOUNT AND CONTACT TO SAL
  //===================================================================================================
  @isTest
  static void testAccountAndContactToSF() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    // Request with invalid token
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'INVALID TOKEN');
    RestContext.request = req;
    RestContext.response = res;
    Svc_AccountToSF.doPost();
    System.assertEquals(401, res.statusCode); // Should fail after token validation (Unauthorized)

    // Request with invalid JSON string
    req = new RestRequest();
    req.requestBody = Blob.valueOf('INVALID JSON STRING');
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    RestContext.request = req;
    RestContext.response = res;
    Svc_AccountToSF.doPost();
    System.assertEquals(400, res.statusCode); // Should fail after JSON parsing (Bad Request)

    // Valid Request
    String accJson =
      '[{' +
      '"BillingCity":"Praha",' +
      '"BillingCountryCode":"CZ",' +
      '"BillingStateCode":"XXX",' + // Wrong State Code to invoke workaround
      '"BillingPostalCode":"18600",' +
      '"BillingStreet":"Rohanské nábřeží 678",' +
      '"ShippingCountryCode":"CZ",' +
      '"CurrencyIsoCode":"CZK",' +
      '"IsValidated__c":false,' +
      '"Name":"Accolade Technologies s.r.o.",' +
      '"OwnerId":"0051t000003AtoJAAS",' +
      '"TaxNo__c":"CZ03840336",' +
      '"VatNo__c":"03840336"' +
      '}]';
    req = new RestRequest();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(accJson);
    RestContext.request = req;
    RestContext.response = res;
    Svc_AccountToSF.doPost();
    ServiceLog__c sl = [
      SELECT Id, Message__c, StackTrace__c
      FROM ServiceLog__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    System.assertEquals(
      200,
      res.statusCode,
      'MSG: ' + sl.Message__c + ' ST: ' + sl.StackTrace__c
    );

    Account[] accs1 = [
      SELECT Id, Name
      FROM Account
      WHERE Name = 'Accolade Technologies s.r.o.'
    ];
    System.assertEquals(1, accs1.size());

    // Sync again the same acc to test upsert
    String accConJson =
      '[{' +
      '"BillingCity":"Praha",' +
      '"BillingCountryCode":"CZ",' +
      '"BillingPostalCode":"18600",' +
      '"BillingStreet":"Rohanské nábřeží 678",' +
      '"ShippingCountryCode":"CZ",' +
      '"CurrencyIsoCode":"CZK",' +
      '"Id":"' +
      accs1[0].Id +
      '",' +
      '"IsValidated__c":false,' +
      '"Name":"Accolade Technologies s.r.o.",' +
      '"OwnerId":"0051t000003AtoJAAS",' +
      '"TaxNo__c":"CZ03840336",' +
      '"VatNo__c":"03840336"' +
      '}]';
    req = new RestRequest();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(accConJson);
    RestContext.request = req;
    RestContext.response = res;
    Svc_AccountToSF.doPost();
    System.assertEquals(200, res.statusCode);

    Account[] accs2 = [
      SELECT Id, Name
      FROM Account
      WHERE Name = 'Accolade Technologies s.r.o.'
    ];
    System.assertEquals(1, accs2.size());
    System.assertEquals(accs1[0].Id, accs2[0].Id);
  }

  //===================================================================================================
  // ORDER AND PRODUCT SYNC - ORDER AND PRODUCT SYNC - ORDER AND PRODUCT SYNC - ORDER AND PRODUCT SYNC
  //===================================================================================================
  @isTest
  static void testOrderAndProductToSAPandSF() {
    Test.setMock(HttpCalloutMock.class, new MockSyncToSAP(200, true));

    Test.startTest();

    // Create necessarry data
    Account acc = TestDataFactory.createAccount(false);
    acc.SyncStatus__c = Cst.STATUS_SUCCESS;
    acc.IsValidated__c = true;
    insert acc;

    Contact con = TestDataFactory.createContact(acc.Id, true);

    Product2 pdc = TestDataFactory.createProduct2(true);

    PricebookEntry pbe = [
      SELECT Id
      FROM PricebookEntry
      WHERE Product2Id = :pdc.Id AND CurrencyIsoCode = 'EUR'
      LIMIT 1
    ];

    Opportunity opp = TestDataFactory.createOpportunity(
      acc.Id,
      true,
      'Qualification'
    );

    Quote qte = new Quote(
      OpportunityId = opp.Id,
      Name = 'SAMPLE QUOTE',
      CurrencyIsoCode = 'EUR',
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert qte;
    QuoteLineItem qli = new QuoteLineItem(
      Product2Id = pdc.Id,
      QuoteId = qte.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 1,
      UnitPrice = 1000.0,
      LineCost__c = 10
    );
    insert qli;
    QuoteLineItem qli2 = new QuoteLineItem(
      Product2Id = pdc.Id,
      QuoteId = qte.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 3,
      UnitPrice = 500.0,
      LineCost__c = 10
    );
    insert qli2;

    // Set Opp to WON to create Order and call sync
    opp.StageName = Cst.OPPORTUNITY_STAGE_CLOSEDWON;
    opp.SyncedQuoteId = qte.Id;
    opp.OrderDueDate__c = Date.today().addMonths(1);
    opp.ProformaPercent__c = 10;
    opp.ProformaIssuedDatePlan__c = Date.today().addMonths(1);
    opp.ProformaPaidDatePlan__c = Date.today().addMonths(2);
    opp.RealizationStartDate__c = Date.today().addDays(3);
    opp.RealizationEndDate__c = Date.today().addMonths(3);
    update opp;

    // Get data for request JSON
    Order__c[] ordRecs = [
      SELECT
        AccountId__c,
        Amount__c,
        BillingAddressTxt__c,
        CurrencyIsoCode,
        Description__c,
        DeliveryDate__c,
        Id,
        Name,
        OwnerId,
        OwnerSAPId__c,
        OpportunityId__c,
        PrimaryContactId__c,
        SAPOrderStatus__c,
        ShippingAddressTxt__c,
        SyncStatus__c,
        (
          SELECT
            CurrencyIsoCode,
            Description__c,
            Discount__c,
            Id,
            ListPrice__c,
            LineNum__c,
            Name,
            OrderId__c,
            ProductId__c,
            ProductSAPId__c,
            Quantity__c,
            Subtotal__c,
            TotalPrice__c,
            UnitPrice__c
          FROM OrderLineItems__r
        )
      FROM Order__c
      WHERE OpportunityId__c = :opp.Id
    ];

    String ordRecsJSON =
      '[{' +
      '"AccountId__c":"' +
      ordRecs[0].AccountId__c +
      '",' +
      '"Amount__c":2500.00,' +
      '"BillingAddressTxt__c":", , ,",' +
      '"CurrencyIsoCode":"EUR",' +
      '"Id":"' +
      ordRecs[0].Id +
      '",' +
      '"Name":"TestACC2020-01-20 11:49:48",' +
      '"OwnerId":"' +
      ordRecs[0].OwnerId +
      '",' +
      '"OwnerSAPId__c":"-1",' +
      '"OpportunityId__c":"' +
      ordRecs[0].OpportunityId__c +
      '",' +
      '"SAPOrderStatus__c":"I",' +
      '"ShippingAddressTxt__c":", , ,",' +
      '"OrderLineItems__r":{ ' +
      '"records":[ ' +
      '{ ' +
      '"OrderId__c":"' +
      ordRecs[0].Id +
      '",' +
      '"Id":"",' +
      '"CurrencyIsoCode":"EUR",' +
      '"ListPrice__c":0.00,' +
      '"LineNum__c":0,' +
      '"Name":"ZZZZ",' +
      '"ProductId__c":"' +
      ordRecs[0].OrderLineItems__r[0].ProductId__c +
      '",' +
      '"Quantity__c":5.00,' +
      '"Subtotal__c":1000.00,' +
      '"TotalPrice__c":1000.00,' +
      '"UnitPrice__c":1000.00' +
      '},' +
      '{ ' +
      '"OrderId__c":"' +
      ordRecs[0].Id +
      '",' +
      '"Id":"",' +
      '"CurrencyIsoCode":"EUR",' +
      '"ListPrice__c":0.00,' +
      '"LineNum__c":1,' +
      '"Name":"XXXXX",' +
      '"ProductId__c":"' +
      ordRecs[0].OrderLineItems__r[1].ProductId__c +
      '",' +
      '"Quantity__c":3.00,' +
      '"Subtotal__c":1500.00,' +
      '"TotalPrice__c":1500.00,' +
      '"UnitPrice__c":500.00' +
      '}]}}]';

    // Call Order Sync to SF
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    // Request with invalid token
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'INVALID TOKEN');
    RestContext.request = req;
    RestContext.response = res;
    Svc_OrderToSF.doPost();
    System.assertEquals(401, res.statusCode); // Should fail after token validation (Unauthorized)

    // Request with invalid JSON string
    req = new RestRequest();
    req.requestBody = Blob.valueOf('INVALID JSON STRING');
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    RestContext.request = req;
    RestContext.response = res;
    Svc_OrderToSF.doPost();
    System.assertEquals(400, res.statusCode); // Should fail after JSON parsing (Bad Request)

    // Valid Request
    req = new RestRequest();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(ordRecsJSON);
    RestContext.request = req;
    RestContext.response = res;
    Svc_OrderToSF.doPost();
    ServiceLog__c sl = [
      SELECT Id, Message__c, StackTrace__c
      FROM ServiceLog__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    System.assertEquals(
      200,
      res.statusCode,
      'MSG: ' + sl.Message__c + ' ST: ' + sl.StackTrace__c
    );

    // Valid Request with line deletion
    String ordRecsJSON2 =
      '[{' +
      '"AccountId__c":"' +
      ordRecs[0].AccountId__c +
      '",' +
      '"Amount__c":2500.00,' +
      '"BillingAddressTxt__c":", , ,",' +
      '"CurrencyIsoCode":"EUR",' +
      '"Id":"' +
      ordRecs[0].Id +
      '",' +
      '"Name":"TestACC2020-01-20 11:49:48",' +
      '"OwnerId":"' +
      ordRecs[0].OwnerId +
      '",' +
      '"OwnerSAPId__c":"-1",' +
      '"OpportunityId__c":"' +
      ordRecs[0].OpportunityId__c +
      '",' +
      '"SAPOrderStatus__c":"I",' +
      '"ShippingAddressTxt__c":", , ,",' +
      '"OrderLineItems__r":{ ' +
      '"records":[ ' +
      '{ ' +
      '"OrderId__c":"' +
      ordRecs[0].Id +
      '",' +
      '"Id":"",' +
      '"CurrencyIsoCode":"EUR",' +
      '"ListPrice__c":0.00,' +
      '"LineNum__c":1,' +
      '"Name":"XXXXX",' +
      '"ProductId__c":"' +
      ordRecs[0].OrderLineItems__r[1].ProductId__c +
      '",' +
      '"Quantity__c":3.00,' +
      '"Subtotal__c":1500.00,' +
      '"TotalPrice__c":1500.00,' +
      '"UnitPrice__c":500.00' +
      '}]}}]';

    req = new RestRequest();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(ordRecsJSON2);
    RestContext.request = req;
    RestContext.response = res;
    Svc_OrderToSF.doPost();
    ServiceLog__c sl2 = [
      SELECT Id, Message__c, StackTrace__c
      FROM ServiceLog__c
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    System.assertEquals(
      200,
      res.statusCode,
      'MSG: ' + sl2.Message__c + ' ST: ' + sl2.StackTrace__c
    );

    Test.stopTest();

    // Call Order Sync also without product sync (already synced products)
    Opportunity opp3 = TestDataFactory.createOpportunity(
      acc.Id,
      true,
      Cst.OPPORTUNITY_STAGE_QUALIFICATION
    );
    Quote qte3 = new Quote(
      OpportunityId = opp3.Id,
      Name = 'SAMPLE QUOTE',
      CurrencyIsoCode = 'EUR',
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert qte3;
    QuoteLineItem qli3 = new QuoteLineItem(
      Product2Id = pdc.Id,
      QuoteId = qte3.Id,
      PricebookEntryId = pbe.Id,
      Quantity = 1,
      UnitPrice = 1000.0,
      LineCost__c = 10
    );
    insert qli3;

    opp3.StageName = Cst.OPPORTUNITY_STAGE_CLOSEDWON;
    opp3.SyncedQuoteId = qte3.Id;
    opp3.OrderDueDate__c = Date.today().addMonths(1);
    opp3.ProformaPercent__c = 10;
    opp3.ProformaIssuedDatePlan__c = Date.today().addMonths(1);
    opp3.ProformaPaidDatePlan__c = Date.today().addMonths(2);
    opp3.RealizationStartDate__c = Date.today().addDays(3);
    opp3.RealizationEndDate__c = Date.today().addMonths(3);
    update opp3;
  }

  @IsTest
  static void testProductToSF() {
    Test.startTest();

    String productJSON =
      '[{ ' +
      '"Description":"",' +
      '"Id":"",' +
      '"IsActive":false,' +
      '"Name":"Cello HR 290 - 2100 x 1250 x 20 mm",' +
      '"Type__c":"M-AKU_PENA",' +
      '"UnitPriceCZK__c":0.000000,' +
      '"UnitPriceUSD__c":0.000000,' +
      '"UnitPriceEUR__c":0.000000,' +
      '"SAPId__c":"A0003"' +
      '},' +
      '{ ' +
      '"Description":"",' +
      '"Id":"",' +
      '"IsActive":false,' +
      '"Name":"Cello HR 290 - 2100 x 1250 x 30 mm",' +
      '"Type__c":"M-AKU_PENA",' +
      '"UnitPriceCZK__c":0.000000,' +
      '"UnitPriceUSD__c":0.000000,' +
      '"UnitPriceEUR__c":0.000000,' +
      '"SAPId__c":"A0004"' +
      '},' +
      '{ ' +
      '"Description":"",' +
      '"Id":"",' +
      '"IsActive":false,' +
      '"Name":"MO_PRIME",' +
      '"Type__c":"V-VYROBEK",' +
      '"UnitCost__c":57162.100000,' +
      '"UnitPriceCZK__c":null,' +
      '"UnitPriceUSD__c":null,' +
      '"UnitPriceEUR__c":null,' +
      '"SAPId__c":"Z0027",' +
      '"Specification__c":"N, Y, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N",' +
      '"BOMs__r":{ ' +
      '"done":true,' +
      '"records":[{ ' +
      '"attributes":{ ' +
      '"type":"BOM__c"' +
      '},' +
      '"BundleId__c":"Z0027",' +
      '"Type__c":"4",' +
      '"BundleItemSAPId__c":"A0003",' +
      '"Quantity__c":0.500000,' +
      '"QuantityUnitOfMeasure__c":"ks",' +
      '"RowNumber__c":17,' +
      '"BundleItemId__c":""' +
      '},' +
      '{ ' +
      '"attributes":{ ' +
      '"type":"BOM__c"' +
      '},' +
      '"BundleId__c":"Z0027",' +
      '"Type__c":"4",' +
      '"BundleItemSAPId__c":"A0004",' +
      '"Quantity__c":1.000000,' +
      '"QuantityUnitOfMeasure__c":"ks",' +
      '"RowNumber__c":18,' +
      '"BundleItemId__c":""' +
      '}' +
      ']}}]';

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(productJSON);
    RestContext.request = req;
    RestContext.response = res;

    Svc_ProductToSF.doPost();
    Test.stopTest();

    Product2 p = [SELECT Id, SAPId__c FROM Product2 WHERE SAPId__c = 'A0003'];
    System.assertNotEquals(null, p.SAPID__c);
  }

  @IsTest
  static void testProductToSFwithDeletedProducts() {
    Product2 p1 = new Product2(
      Description = '',
      IsActive = true,
      Name = 'Cello HR 290 - 2100 x 1250 x 20 mm',
      Type__c = 'M-AKU_PENA',
      UnitPriceCZK__c = 0.000000,
      UnitPriceUSD__c = 0.000000,
      UnitPriceEUR__c = 0.000000,
      SAPId__c = 'A0003'
    );
    insert p1;

    Product2 p2 = new Product2(
      Description = '',
      IsActive = true,
      Name = 'Cello HR 290 - 2100 x 1250 x 30 mm',
      Type__c = 'M-AKU_PENA',
      UnitPriceCZK__c = 0.000000,
      UnitPriceUSD__c = 0.000000,
      UnitPriceEUR__c = 0.000000,
      SAPId__c = 'A0004',
      Specification__c = '1;2;3'
    );
    insert p2;

    Product2 bndl = new Product2(
      Description = '',
      IsActive = true,
      Name = 'MO_PRIME',
      Type__c = 'V-VYROBEK',
      UnitCost__c = 57162.100000,
      UnitPriceCZK__c = null,
      UnitPriceUSD__c = null,
      UnitPriceEUR__c = null,
      Specification__c = null,
      SAPId__c = 'Z0027'
    );
    insert bndl;

    BOM__c[] bomList = new List<BOM__c>{};
    bomList.add(
      new BOM__c(
        BundleId__c = bndl.Id,
        BundleItemSAPId__c = 'A0003',
        Quantity__c = 0.500000,
        QuantityUnitOfMeasure__c = 'ks',
        RowNumber__c = 17,
        BundleItemId__c = p1.Id
      )
    );
    bomList.add(
      new BOM__c(
        BundleId__c = bndl.Id,
        BundleItemSAPId__c = 'A0004',
        Quantity__c = 1.000000,
        QuantityUnitOfMeasure__c = 'ks',
        RowNumber__c = 18,
        BundleItemId__c = p2.Id
      )
    );
    insert bomList;

    Test.startTest();

    Product2 pRes = [
      SELECT Id, (SELECT Id FROM BOMs__r)
      FROM Product2
      WHERE Id = :bndl.Id
      LIMIT 1
    ];
    System.assertEquals(2, pRes.BOMs__r.size());

    String productJSON =
      '[{ ' +
      '"Description":"",' +
      '"Id":"",' +
      '"IsActive":false,' +
      '"Name":"Cello HR 290 - 2100 x 1250 x 30 mm",' +
      '"Type__c":"M-AKU_PENA",' +
      '"UnitPriceCZK__c":0.000000,' +
      '"UnitPriceUSD__c":0.000000,' +
      '"UnitPriceEUR__c":0.000000,' +
      '"SAPId__c":"A0004"' +
      '},' +
      '{ ' +
      '"Description":"",' +
      '"Id":"",' +
      '"IsActive":false,' +
      '"Name":"MO_PRIME",' +
      '"Type__c":"V-VYROBEK",' +
      '"UnitCost__c":57162.100000,' +
      '"UnitPriceCZK__c":null,' +
      '"UnitPriceUSD__c":null,' +
      '"UnitPriceEUR__c":null,' +
      '"SAPId__c":"Z0027",' +
      '"Specification__c":"N, Y, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N",' +
      '"BOMs__r":{ ' +
      '"done":true,' +
      '"records":[{ ' +
      '{ ' +
      '"attributes":{ ' +
      '"type":"BOM__c"' +
      '},' +
      '"BundleId__c":"Z0027",' +
      '"Type__c":"4",' +
      '"BundleItemSAPId__c":"A0004",' +
      '"Quantity__c":1.000000,' +
      '"QuantityUnitOfMeasure__c":"ks",' +
      '"RowNumber__c":18,' +
      '"BundleItemId__c":""' +
      '}' +
      ']}}]';

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(productJSON);
    RestContext.request = req;
    RestContext.response = res;

    Svc_ProductToSF.doPost();
    Test.stopTest();

    pRes = [
      SELECT Id, (SELECT Id FROM BOMs__r)
      FROM Product2
      WHERE Id = :bndl.Id
      LIMIT 1
    ];
    System.assertEquals(2, pRes.BOMs__r.size());
  }

  //===================================================================================================
  // INVOICE AND PAYMENT TO SALESFORCE - INVOICE AND PAYMENT TO SALESFORCE - INVOICE AND PAYMENT TO SAL
  //===================================================================================================
  @isTest
  static void testInvoiceAndPaymentToSF() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    Account acc = TestDataFactory.createAccount(false);
    acc.SyncStatus__c = Cst.STATUS_SUCCESS;
    acc.IsValidated__c = true;
    acc.AccountEID__c = 'ACC001';
    insert acc;

    Contact con = TestDataFactory.createContact(acc.Id, true);

    Opportunity opp = TestDataFactory.createOpportunity(
      acc.Id,
      true,
      Cst.OPPORTUNITY_STAGE_QUALIFICATION
    );
    Test.startTest();

    // Test Invoice Sync
    // =======================================================================

    // Request with invalid token
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'INVALID TOKEN');
    RestContext.request = req;
    RestContext.response = res;
    Svc_InvoiceToSF.doPost();
    System.assertEquals(401, res.statusCode); // Should fail after token validation (Unauthorized)

    // Request with invalid JSON string
    req = new RestRequest();
    req.requestBody = Blob.valueOf('INVALID JSON STRING');
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    RestContext.request = req;
    RestContext.response = res;
    Svc_InvoiceToSF.doPost();
    System.assertEquals(400, res.statusCode); // Should fail after JSON parsing (Bad Request)

    // Valid Request
    String invJson =
      '[{' +
      '"AccountId__c":"' +
      acc.Id +
      '",' +
      '"CurrencyIsoCode":"CZK",' +
      '"DueDate__c":"2020-01-01",' +
      '"IsCanceled__c":"false",' +
      '"IsProforma__c":"false",' +
      '"IssuedDate__c":"2020-01-01",' +
      '"Name":"INV-ABCD",' +
      '"OpportunityId__c":"' +
      opp.Id +
      '",' +
      '"SAPId__c":"ABCDEFG",' +
      '"TaxDate__c":"2020-01-01",' +
      '"TotalWithVAT__c":"1000.0"' +
      '}]';
    req = new RestRequest();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(invJson);
    RestContext.request = req;
    RestContext.response = res;
    Svc_InvoiceToSF.doPost();

    // Test Payment Sync
    // =======================================================================

    // Create also Invoice, which will be commited to DB, because of execution future methods after StopTest
    Invoice__c nInv = new Invoice__c(
      AccountId__c = acc.Id,
      CurrencyIsoCode = 'CZK',
      DueDate__c = Date.today().addMonths(1),
      IsCanceled__c = false,
      IsProforma__c = false,
      IssuedDate__c = Date.today().addMonths(1),
      Name = 'INV-ABCDEF',
      OpportunityId__c = opp.Id,
      SAPId__c = 'XYZ',
      TaxDate__c = Date.today().addMonths(1),
      TotalWithVAT__c = 1000.0
    );
    insert nInv;

    // Request with invalid token
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'INVALID TOKEN');
    RestContext.request = req;
    RestContext.response = res;
    Svc_PaymentToSF.doPost();
    System.assertEquals(401, res.statusCode); // Should fail after token validation (Unauthorized)

    // Request with invalid JSON string
    req = new RestRequest();
    req.requestBody = Blob.valueOf('INVALID JSON STRING');
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    RestContext.request = req;
    RestContext.response = res;
    Svc_PaymentToSF.doPost();
    System.assertEquals(400, res.statusCode); // Should fail after JSON parsing (Bad Request)

    // Valid Request
    String payJson =
      '[{' +
      '"AccountId__c":"' +
      acc.Id +
      '",' +
      '"AccountSAPId__c":"ACC001",' +
      '"Amount__c":3608558.800000,' +
      '"CurrencyIsoCode":"CZK",' +
      '"InvoiceSAPId__c":"XYZ",' +
      '"OrderId__c":"null",' +
      '"SAPOrderId__c":"219920158",' +
      '"SAPId__c":"PPPPPP",' +
      '"SentDate__c":"2020-01-13",' +
      '"IsProforma__c":false,' +
      '"Type__c":"Type A"' +
      '}]';
    req = new RestRequest();
    req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.addHeader('token', 'Baerer XXXXX');
    req.requestBody = Blob.valueOf(payJson);
    RestContext.request = req;
    RestContext.response = res;
    Svc_PaymentToSF.doPost();

    Test.stopTest();
    Invoice__c inv = [
      SELECT Id, SAPId__c, OpportunityId__c
      FROM Invoice__c
      WHERE SAPId__c = :'ABCDEFG'
    ];
    System.assertNotEquals(null, inv.OpportunityId__c, inv);

    Payment__c pay = [
      SELECT Id, InvoiceSAPId__c, InvoiceId__c, SAPId__c
      FROM Payment__c
      WHERE SAPId__c = 'PPPPPP'
    ];
    System.assertNotEquals(null, pay.InvoiceId__c, pay);
  }
}
