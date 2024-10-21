global without sharing class ProductBulkUpdateBatch implements Database.Batchable<Integer>, Database.Stateful {
    
    String body;
    String eAddr;
    Integer[] endLines;
    Integer lastIndex;
    Integer succRec;
    Integer errRec;

    global ProductBulkUpdateBatch(String fileBody, Integer[] endLines, String emailAddr){
        body = fileBody;
        this.endLines = endLines;
        eAddr = emailAddr;
        lastIndex = 0;
        succRec = 0;
        errRec = 0;
    }

    global Integer[] start(Database.BatchableContext bc){
        return this.endLines;
    }
    
    global void execute(Database.BatchableContext bc, Integer[] scope){
        try{
            Product2[] prods = new Product2[]{};
            String[] inputValues = new String[]{};
            // System.debug('lastIndex ' + lastIndex);
            Integer prevEnd = lastIndex;
            
            for(Integer i = 0; i < scope.size(); i++){
                Product2 prod = new Product2();
                Integer endLine = scope[i];
                // System.debug('prevEnd ' + prevEnd);
                // System.debug('endLine ' + endLine);
                String line = body.substring(prevEnd, endLine);
                System.debug('Line ' + line);
                if(line.startsWith('\n')){
                    line = line.right(line.length() - 1);
                }
                lastIndex = endLine + 2;
                prevEnd = endLine + 2;

                inputValues = line.split('";"');
                System.debug('ID: ' + inputValues[0]);
                if(auraGetStringValue(inputValues[0]).startsWith('01t')){
                    prod.Id = auraGetStringValue(inputValues[0]);
                    //prod.Name = auraGetStringValue(inputValues[1]);
                    prod.Specification__c = (auraGetStringValue(inputValues[2]) == 'null') ? '' : inputValues[2];
                    prod.BusinessName__c = (auraGetStringValue(inputValues[3]) == 'null') ? '' : inputValues[3];
                    prod.BusinessNameEN__c = (auraGetStringValue(inputValues[4]) == 'null') ? '' : inputValues[4];
                    prod.Description = (auraGetStringValue(inputValues[5]) == 'null') ? '' : inputValues[5];
                    prod.ProductDescriptionCZ__c = (auraGetStringValue(inputValues[6]) == 'null') ? '' : inputValues[6];
                    prod.ProductDescriptionEN__c = (auraGetStringValue(inputValues[7]) == 'null') ? '' : inputValues[7];
                    prod.Family = (auraGetStringValue(inputValues[8]) == 'null') ? '' : inputValues[8];
                    String unitCost = auraGetDacimalValue(auraGetStringValue(inputValues[9]));
                    prod.UnitCost__c = Decimal.valueOf((unitCost == 'null') ? '0' : unitCost);
                    String unitPriceCZK = auraGetDacimalValue(auraGetStringValue(inputValues[10]));
                    prod.UnitPriceCZK__c = Decimal.valueOf((unitPriceCZK == 'null') ? '0' : unitPriceCZK);
                    String unitPriceEUR = auraGetDacimalValue(auraGetStringValue(inputValues[11]));
                    prod.UnitPriceEUR__c = Decimal.valueOf((unitPriceEUR == 'null') ? '0' : unitPriceEUR);
                    String unitPriceUSD = auraGetDacimalValue(auraGetStringValue(inputValues[12]));
                    prod.UnitPriceUSD__c = Decimal.valueOf((unitPriceUSD == 'null') ? '0' : unitPriceUSD);
                    prod.IsActive = Boolean.valueOf(auraGetStringValue(inputValues[13]));
                    prod.IsDefault__c = Boolean.valueOf(auraGetStringValue(inputValues[14]));
                    prods.add(prod);
                }
            }
            String msg;
            String errStr = '';
            String succStr = '';
            String stackTrace;
            String status;
            Database.SaveResult[] srs = Database.update(prods, false);
            for(Integer i = 0; i < srs.size(); i++){
                if(!srs[i].isSuccess()){
                    errStr += 'ERROR: ' + srs[i].getErrors() + '\n\n'+'RECORD: '+JSON.serializePretty(prods[i]+'\n\n');
                    errRec++;
                }else{
                    succStr += 'SUCCESS: ' + srs[i].getId() + '\n\n'+'RECORD: '+JSON.serializePretty(prods[i]+'\n\n');
                    succRec++;
                }
            }
            if(String.isNotEmpty(errStr)){
                stackTrace = errStr;
                status = Cst.STATUS_WARNING;
                msg = 'WARNING: Some records failed to update!';
                SyncUtils.logServiceActivity('Product Bulk Update', status, 400, msg, stackTrace, Hlp.getStringWithLength(JSON.serialize(prods),32000));
            } 
            if(String.isNotEmpty(succStr)){
                stackTrace = succStr;
                status = Cst.STATUS_SUCCESS;
                msg = 'SUSCCESS: Product updated.';
                SyncUtils.logServiceActivity('Product Bulk Update', status, 200, msg, stackTrace, Hlp.getStringWithLength(JSON.serialize(prods),32000));
            }      
            // System.debug('Body length ' + body.length()); 

        }catch(Exception e){
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[]{eAddr};
            email.setSubject('Product Update');
            email.setToAddresses( toAddresses );
            email.setPlainTextBody('Something went wrong ' + e.getMessage());
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        System.debug('XXXFINISHXXX ' + eAddr);

        Integer recCount = succRec + errRec;
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{eAddr};
        String subject ='Product Update';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('There were a total of '+ recCount +' record updates. Of these, update '+ succRec +' was successful and '+ errRec +' was unsuccessful. Details are visible in the Service Log tab.');
        if(!Test.isRunningTest()){
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }

    public static String auraGetStringValue(String quotedValue){
        if(quotedValue.startsWith('"')){
            quotedValue = quotedValue.substring(1);
        }
        if(quotedValue.endsWith('"')){
            quotedValue = quotedValue.substring(0,quotedValue.length()-1);
        }
        return quotedValue;
    }

    public static String auraGetDacimalValue(String stringValue){
        if(stringValue.contains(',')){
            stringValue = stringValue.replace(',','.');
        }
        return stringValue;
    }
}