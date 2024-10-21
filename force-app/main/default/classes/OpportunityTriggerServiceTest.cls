/**
 * Created by David Martinka on 10.01.2023.
 * Mooza Inspire s.r.o.
 */
@IsTest
public with sharing class OpportunityTriggerServiceTest {
    @IsTest
    static void should_populateFieldsFromAccount_when_beforeInsertTest() {
        Account invoicingDepartmentAccount = new Account(Name = 'Invoicing Department Account', BillingCity = 'City', BillingCountry = 'Czech Republic', BillingStreet = 'Street');
        insert invoicingDepartmentAccount;

        Account account = new Account(
                Name = 'Test Account',
                ProformaPaymentTerm__c = 50,
                FinalInvoicePaymentTerm__c = 50,
                ProformaPercent_Acc__c = 50.25,
                BillingCity = 'City',
                BillingCountry = 'Czech Republic',
                BillingStreet = 'Street'
        );
        insert account;

        Contact invoicingDepartmentContact = new Contact(FirstName = 'Contact', LastName = 'Test', Email = 'invocing@department-contact.com', Role__c='End user');
        insert invoicingDepartmentContact;

        account.Invoicing_Department_Acc__c = invoicingDepartmentContact.Id;
        update account;

        insert new Opportunity(Name = 'Testing Opportunity', AccountId = account.Id, CloseDate = System.today().addMonths(12), StageName = 'Qualification');

        List<Opportunity> opportunities = [SELECT Id, PaymentTerm__c, FinalInvoicePaymentTerm__c, Invoicing_Department__c, ProformaPercent__c FROM Opportunity WHERE Name = 'Testing Opportunity'];
        System.assertEquals(opportunities.get(0).PaymentTerm__c, account.ProformaPaymentTerm__c, 'This field should be automatically populated by before insert trigger from Account');
        System.assertEquals(opportunities.get(0).FinalInvoicePaymentTerm__c, account.FinalInvoicePaymentTerm__c, 'This field should be automatically populated by before insert trigger from Account');
        System.assertEquals(opportunities.get(0).Invoicing_Department__c, account.Invoicing_Department_Acc__c, 'This field should be automatically populated by before insert trigger from Account');
        System.assertEquals(opportunities.get(0).ProformaPercent__c, account.ProformaPercent_Acc__c, 'This field should be automatically populated by before insert trigger from Account');
    }
}