public with sharing class SalesFeeManagerController {
    
    @AuraEnabled
    public static ProjectSalesFee__c[] auraGetSettings(){
        return [SELECT Name, Reward__c, LowerRange__c, HigherRange__c, Id FROM ProjectSalesFee__c ORDER BY LowerRange__c ASC];
    }

    @AuraEnabled
    public static SalesFeeMdl auraSave(ProjectSalesFee__c[] salesSettings){
        SalesFeeMdl sfm = new SalesFeeMdl();
        System.debug('AuraSave() ' + salesSettings);
        try {
            upsert salesSettings;
            sfm.isSuccess = true;
        } catch (Exception e) {
            sfm.isSuccess = false;
            sfm.message = e.getMessage();
        }
        return sfm;
    }

    public class SalesFeeMdl{
        @AuraEnabled public String 		message 		{ get; set; }
        @AuraEnabled public Boolean		isSuccess		{ get; set; }
        public SalesFeeMdl(){
        	this.isSuccess = false;
        }
    }
}