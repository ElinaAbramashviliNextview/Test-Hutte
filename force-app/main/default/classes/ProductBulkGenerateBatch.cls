global without sharing class ProductBulkGenerateBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    String separator = '";"';
    global String file = '"Id'+separator+'Name'+separator+'Specification__c'+separator+'BusinessName__c'+separator+'BusinessNameEN__c'+separator+'Description'+separator+'ProductDescriptionCZ__c'+separator+'ProductDescriptionEN__c'+separator+'Family'+separator+'UnitCost__c'+separator+'UnitPriceCZK__c'+separator+'UnitPriceEUR__c'+separator+'UnitPriceUSD__c'+separator+'IsActive'+separator+'IsDefault__c' + '"' + '\n';
    global Product2[] prods = new Product2[]{};
    private String eAddr = '';
    private Set<Id> prodIds = new Set<Id>();
    private Boolean isGdriveExport = false;
    private Boolean isEmailExport = false;
    private Boolean isRunUpdate = false;
    private String cdId = null;

    global ProductBulkGenerateBatch(Product2[] prodToExport, String emailAddr){
        for(Product2 prod : prodToExport){
            prodIds.add(prod.Id);
        }
        this.eAddr = emailAddr;
        this.isEmailExport = true;
    }
    
    // Full Products Export - manual export
    global ProductBulkGenerateBatch(String docId, String eml){
        Product2[] ps = [SELECT Id FROM Product2 WHERE IsActive = TRUE];
        for(Product2 p : ps){
            prodIds.add(p.Id);
        }
        this.isGdriveExport = true;
        if(!String.isBlank(docId)){
            this.cdId = docId;
            this.isRunUpdate = true;
        }
        if(!String.isBlank(eml)){
            this.eAddr = eml;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        System.debug('XXXSTARTXXX');
        return Database.getQueryLocator('SELECT Id, Name, UnitCost__c, Specification__c, BusinessName__c, BusinessNameEN__c, Description, ProductDescriptionCZ__c, ProductDescriptionEN__c, IsActive, IsDefault__c, UnitPriceCZK__c, UnitPriceEUR__c, UnitPriceUSD__c, Family FROM Product2 WHERE Id IN: prodIds ORDER BY Name ASC');
    }
    
    global void execute(Database.BatchableContext bc, List<Product2> scope){
        try{
            System.debug('EXECUTE');
            for(Product2 prod : scope){
                System.debug('prod ' + prod);
                String businessName, businessNameEN, shortDesc, prodDescCZ, prodDescEN, prodName;
                if(!String.isBlank(prod.Name)){
                    prodName = prod.Name.replace('"', '""');
                }
                if(!String.isBlank(prod.BusinessName__c)){
                    businessName = prod.BusinessName__c.replace('"', '""');
                }
                if(!String.isBlank(prod.BusinessNameEN__c)){
                    businessNameEN = prod.BusinessNameEN__c.replace('"', '""');
                }
                if(!String.isBlank(prod.Description)){
                    shortDesc = prod.Description.replace('"', '""');
                }
                if(!String.isBlank(prod.ProductDescriptionCZ__c)){
                    System.debug('ProductDescriptionCZ ' + prod.ProductDescriptionCZ__c);
                    prodDescCZ = prod.ProductDescriptionCZ__c.replace('"', '""');
                }
                if(!String.isBlank(prod.ProductDescriptionEN__c)){
                    System.debug('ProductDescriptionEN ' + prod.ProductDescriptionEN__c);
                    prodDescEN = prod.ProductDescriptionEN__c.replace('"', '""');
                }
                this.file += '"' + prod.Id + separator + prodName + separator + prod.Specification__c + separator + businessName + separator + businessNameEN + separator + shortDesc + separator + prodDescCZ + separator + prodDescEN + separator + prod.Family + separator + prod.UnitCost__c + separator + prod.UnitPriceCZK__c + separator + prod.UnitPriceEUR__c + separator + prod.UnitPriceUSD__c + separator + prod.IsActive + separator + prod.IsDefault__c + '"' + '\n';
                System.debug('FILE AFTER ' + file);
            }
        }catch(Exception e){
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[]{eAddr};
            email.setSubject('Product Export');
            email.setToAddresses( toAddresses );
            email.setPlainTextBody('Something went wrong ' + e.getMessage());
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        System.debug('XXXFINISHXXX ');
        if(isGdriveExport){
            /* Send Data to GDRIVE */
    		GoogleDriveAuth__c sett = GoogleDriveAuth__c.getValues('default');
            String filename = System.now().format('yyyy-MM-dd_HH-mm') + '_' + UserInfo.getLastName() + UserInfo.getFirstName() + '.csv';
            Mdl.BaseResponse res = GoogleDriveService.uploadFileGDrive(filename, 'text/csv', sett.ProdSyncFolderEID__c, EncodingUtil.base64Encode(Blob.valueOf(file)));
            
            if(!res.isSuccess && !String.isBlank(this.eAddr)){
                Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[]{eAddr};
                String subject ='Product Export failed';
                email.setSubject(subject);
                email.setToAddresses( toAddresses );
                email.setPlainTextBody('Product Backup Export to Google Drive failed. Please try again.\n If this was part of import, upload import file again.');
                if(!Test.isRunningTest()){
                    Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                }

                // workaround for uncommited work pending during tests
                if(!Test.isRunningTest()){
                    return;
                }
            }
        }

        if(isEmailExport){
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName('ProductExport.csv');
            csvAttc.setBody(Blob.valueOf(file));
    
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[]{eAddr};
            String subject ='Product Export';
            email.setSubject(subject);
            email.setToAddresses( toAddresses );
            email.setPlainTextBody('Product Export ');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        }

        if(isRunUpdate){
            ContentDocument[] cds = [SELECT LatestPublishedVersion.VersionData, Title FROM ContentDocument WHERE Id =: this.cdId];
            String fileBody = cds[0].LatestPublishedVersion.VersionData.toString();
            Integer[] endLines = new Integer[]{};
            Integer indexNL = 0;
            String lineEnd;

            if(fileBody.contains('"\r\n')){
                lineEnd = '"\r\n';
            }else{
                lineEnd = '"\n';
            }

            while(indexNL != -1){
                indexNL = fileBody.indexOf(lineEnd, indexNL + 2);
                System.debug('Index Last' + indexNL);
                if(indexNL != -1){
                    endLines.add(indexNL);
                }else{
                    endLines.add(fileBody.length());
                }
            }
            if(String.isBlank(eAddr)){
                eAddr = UserInfo.getUserEmail();
            }
            System.debug('Skip List ' + eAddr);
            Database.executeBatch(new ProductBulkUpdateBatch(fileBody, endLines, eAddr), 100);
        }
    }
}