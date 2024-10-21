public class Svc_OrderToSAP implements Queueable, Database.AllowsCallouts {
    private static String SVC_NAME = 'OrderToSAP';

    public Set<Id> recIds{get;set;}

    public Svc_OrderToSAP(Set<Id> rIds){
        recIds = rIds;
    }

    public void execute(QueueableContext qc) {
        syncToSAP(recIds);
    }

    public static void syncToSAP(Set<Id> recIds){
        SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
        if(stt.DisableSync__c){ SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 503, 'ERROR: Service is disabled'); return; }
        String dataStr;
        try{
            //SyncUtils.validateAccess(SVC_NAME);
            Order__c[] ords = [SELECT AccountId__c, AccountSAPId__c, BillingAddressTxt__c, CurrencyIsoCode, DueDate__c, OpportunityId__r.Dispatch_Date__c, Description__c, Id, Name, OpportunityNo__c, OpportunityId__r.ClientReferenceNumber__c, OwnerSAPId__c, OnSiteContactId__c, SAPOrderStatus__c, ShippingAddressTxt__c, SyncStatus__c,
                                    (SELECT Description__c, Discount__c, Id, IsDefault__c, LineNum__c, ListPrice__c, Name, OrderId__c, ProductSAPId__c, Quantity__c, QuoteLineItemId__c, Subtotal__c, TotalPrice__c, UnitPrice__c, Type__c
                                    FROM OrderLineItems__r)
                                FROM Order__c WHERE Id IN:recIds];

            Set<Id> qliIds = new Set<Id>();
            for(Order__c o : ords){
                for(OrderLineItem__c oli : o.OrderLineItems__r){
                    qliIds.add(oli.QuoteLineItemId__c);
                }
            }

            // Get primary quote Line Items (also with QLSIs)
            QuoteLineItem[] qlis = [SELECT Id,
                                        (SELECT Id, Name, Product2Id__c, Product2Id__r.SAPID__c, Product2Id__r.Description, ProductName__c, Quantity__c, QuoteLineItemId__c, Position__c
                                        FROM QuoteLineSubItems__r)
                                    FROM QuoteLineItem WHERE Id IN:qliIds];
            
            Map<Id,QuoteLineSubItem__c[]> qlsiMap = new Map<Id,QuoteLineSubItem__c[]>();

            for(QuoteLineItem qli : qlis){
                System.debug('#qli: '+qli);
                QuoteLineSubItem__c[] qlsis = (!qli.QuoteLineSubItems__r.isEmpty()) ? qli.QuoteLineSubItems__r : new QuoteLineSubItem__c[]{};
                System.debug('#qlis: '+qlis);
                qlsiMap.put(qli.Id,qlsis);
            }

            Mdl.SfOrder[] recs = new Mdl.SfOrder[]{};
            for(Order__c o : ords){
                // Map Order fields
                Mdl.SfOrder nsfo = new Mdl.SfOrder();
                nsfo.AccountId = o.AccountId__c;
                nsfo.AccountSAPId = o.AccountSAPId__c;
                nsfo.BillingAddressTxt = o.BillingAddressTxt__c;
                nsfo.CurrencyIsoCode = o.CurrencyIsoCode;
                nsfo.DueDate = o.DueDate__c;
                nsfo.DeliveryDate = o.OpportunityId__r.Dispatch_Date__c;
                nsfo.Description = o.Description__c;
                nsfo.Id = o.Id;
                nsfo.Name = o.Name;
                nsfo.OwnerSAPId = o.OwnerSAPId__c;
                nsfo.OpportunityNo = o.OpportunityNo__c;
                nsfo.PrimaryContactId = o.OnSiteContactId__c;
                nsfo.RefNo = o.OpportunityId__r.ClientReferenceNumber__c;
                nsfo.SAPOrderStatus = o.SAPOrderStatus__c;
                nsfo.ShippingAddressTxt = o.ShippingAddressTxt__c;
                nsfo.SyncStatus = o.SyncStatus__c;
                Mdl.SfOrderLineItem[] lineItems = new Mdl.SfOrderLineItem[]{};
                for(OrderLineItem__c oli : o.OrderLineItems__r){
                    // Map Order Line Item fields
                    Mdl.SfOrderLineItem noli = new Mdl.SfOrderLineItem();
                    noli.Description = oli.Description__c;
                    noli.Discount = oli.Discount__c;
                    noli.Id = oli.Id;
                    noli.IsDefault = oli.IsDefault__c;
                    noli.LineNum = (Integer)oli.LineNum__c;
                    noli.ListPrice = oli.ListPrice__c;
                    noli.Name = oli.Name;
                    noli.OrderId = oli.OrderId__c;
                    noli.ProductSAPId = oli.ProductSAPId__c;
                    noli.Quantity = oli.Quantity__c;
                    noli.Subtotal = oli.Subtotal__c;
                    noli.TotalPrice = oli.TotalPrice__c;
                    noli.UnitPrice = oli.UnitPrice__c;
                    noli.Type = oli.Type__c;
                    Mdl.SfOrderLineSubItem[] subItems = new Mdl.SfOrderLineSubItem[]{};
                    QuoteLineSubItem__c[] sis = qlsiMap.get(oli.QuoteLineItemId__c);
                    System.debug('#sis: '+sis);
                    for(QuoteLineSubItem__c si : sis){
                        // Map Order Line Sub Item fields
                        Mdl.SfOrderLineSubItem nosli = new Mdl.SfOrderLineSubItem();
                        nosli.Description = si.Product2Id__r.Description;
                        nosli.Id = si.Id;
                        nosli.Name = si.Name;
                        nosli.Product2Id = si.Product2Id__c;
                        nosli.ProductSAPId = si.Product2Id__r.SAPID__c;
                        nosli.ProductName = si.ProductName__c;
                        nosli.Quantity = si.Quantity__c;
                        nosli.QuoteLineItemId = si.QuoteLineItemId__c;
                        nosli.Position = si.Position__c;
                        subItems.add(nosli);
                    }
                    noli.OrderLineSubItems.put('Records',subItems);
                    lineItems.add(noli);
                }
                nsfo.OrderLineItems.put('Records',lineItems);
                recs.add(nsfo);
            }

            dataStr = JSON.serialize(recs, false);

            HttpResponse res = SyncUtils.sendData(SVC_NAME, dataStr);
            String status;
            if(res.getStatusCode() == 200){
                status = Cst.STATUS_SUCCESS;
                SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, res.getStatusCode(), 'SUCCESS: orders synced ('+String.join(new List<Id>(recIds),', ')+')', null, dataStr);
            }else{
                status = Cst.STATUS_ERROR;
                SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, res.getStatusCode(), 'ERROR - something wents wrong: ' + res.getStatus(), String.valueOf(res), dataStr);
            }
            // Set result recs
            Order__c[] recsToUpdate = new Order__c[]{};
            OrderLineItem__c[] recLinesToUpdate = new OrderLineItem__c[]{};
            for(Order__c r : ords){
                r.SyncStatus__c = status;
                recsToUpdate.add(r);
                for(OrderLineItem__c i : r.OrderLineItems__r){
                    i.SyncStatus__c = status;
                    recLinesToUpdate.add(i);
                }
            }
            update recsToUpdate;
            update recLinesToUpdate;
        }catch(Exception e){
            SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 0, e.getMessage(), dataStr, e.getStackTraceString());
        }
    }
}