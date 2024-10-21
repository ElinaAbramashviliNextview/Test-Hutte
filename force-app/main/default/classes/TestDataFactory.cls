/*
 Author: Dominik Cwynar (dominikcwynar@nextviewconsulting.com)
 Description: Class containing methods to create records for tests 
 */
@IsTest
global class TestDataFactory {
  public static List<SyncServiceSettings__c> createSyncServiceSettings(
    Boolean doInsert
  ) {
    SyncServiceSettings__c[] settings = new List<SyncServiceSettings__c>{};
    List<String> serviceNames = new List<String>{
      'AccountToSAP',
      'ContactsToSAP',
      'OrderToSAP',
      'ProductToSAP',
      'ProductToSF',
      'OrderToSF',
      'AccountToSF',
      'InvoiceToSF',
      'PaymentToSF'
    };

    for (String service : serviceNames) {
      settings.add(
        new SyncServiceSettings__c(
          Name = service,
          DisableSync__c = false,
          Endpoint__c = 'TestNamedCredential/test',
          Token__c = 'testToken'
        )
      );
    }

    if (doInsert) {
      insert settings;
    }

    return settings;
  }

  public static Account createAccount(Boolean doInsert) {
    Account account = new Account(
      Name = 'TestACC' + DateTime.now(),
      VatNo__c = '123456780',
      BillingCity = 'Praha'
    );

    if (doInsert) {
      insert account;
    }

    return account;
  }

  public static Contact createContact(Id accountId, Boolean doInsert) {
    if (accountId == null) {
      accountId = createAccount(true).Id;
    }

    Contact contact = new Contact(
      AccountId = accountId,
      LastName = 'TestCON' + DateTime.now().millisecond(),
      Role__c = 'End user',
      Email = 'example' + DateTime.now().millisecond() + '@example.com',
      Phone = String.valueOf(DateTime.now().millisecond())
    );

    if (doInsert) {
      insert contact;
    }

    return contact;
  }

  public static Opportunity createOpportunity(
    Id accountId,
    Boolean doInsert,
    String stageName
  ) {
    if (accountId == null) {
      accountId = createAccount(true).Id;
    }
    Opportunity oppty = new Opportunity(
      Name = 'TestACC' + DateTime.now(),
      AccountId = accountId,
      CloseDate = DateTime.now().addDays(5).date(),
      StageName = !String.isBlank(stageName)
        ? stageName
        : Cst.OPPORTUNITY_STAGE_FINALIZING,
      Street__c = 'AnyStreet 123',
      City__c = 'Prague',
      PostalCode__c = '12345',
      Country__c = 'Czech Republic',
      CurrencyIsoCode = 'EUR',
      ProformaIssuedDatePlan__c = Date.today().addMonths(2),
      ProformaPaidDatePlan__c = Date.today().addMonths(2),
      OrderDeliveryDatePlan__c = Date.today().addMonths(2)
    );

    if (doInsert) {
      insert oppty;
    }
    return oppty;
  }

  public static Product2 createProduct2(Boolean doInsert) {
    Product2 product = new Product2(Name = 'MICRO OFFICE', IsActive = true);

    if (doInsert) {
      insert product;
    }

    return product;
  }
}
