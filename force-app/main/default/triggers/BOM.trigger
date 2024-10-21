trigger BOM on BOM__c (before insert, before update, after insert, after update, after delete) {
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. BIU------        > Preset BOM values from product
1. -----AIUD        > Add Unit Cost to Bundle Product
----------------------------------------------------------------------------------------------------------------------
*/
	/* 0. */
	if(Trigger.isBefore){
		Set<Id> prodIds = new Set<Id>();
		for(BOM__c n : Trigger.new){
			prodIds.add(n.BundleItemId__c);
		}
		Map<Id,Product2> prodMap = new Map<Id,Product2>([SELECT Id,Name,ProductCode,SAPId__c, UnitCost__c, Specification__c, IsTemplateProduct__c FROM Product2 WHERE Id IN:prodIds]);
		for(BOM__c n : Trigger.new){
			Product2 bi = prodMap.get(n.BundleItemId__c);
			n.BundleItemId__c = bi.Id;
			n.Name = Hlp.getStringWithLength(bi.Name, 80);
			n.ProductCode__c = bi.ProductCode;
			n.BundleItemSAPId__c = bi.SAPId__c;
			n.UnitCost__c = bi.UnitCost__c;
			n.IsRecalculate__c = false;
			n.IsTemplateProduct__c = bi.IsTemplateProduct__c;
			Boolean hasSpecifiation = (bi.Specification__c != null);
			n.IsVisible__c = hasSpecifiation;
			n.IsEditable__c = hasSpecifiation;
			n.IsVisibleOnPDF__c = SyncUtils.isPDFVisible(bi.Specification__c);
		}
	}
	/* 1. */

	// MAYBE TEMPORARLY COMMENTED

	/*if(Trigger.isAfter){
		Set<Id> bundleIds = new Set<Id>();

		if(Trigger.isDelete){		
			for(BOM__c o: Trigger.old){
				bundleIds.add(o.BundleId__c);
			}
		}else{
			for(BOM__c n : Trigger.new){
				bundleIds.add(n.BundleId__c);
			}
		}
		BOM__c[] boms = [SELECT Id, BundleItemId__c, BundleItemId__r.UnitCost__c, BundleId__c, Quantity__c FROM BOM__c WHERE BundleId__c IN: bundleIds];
		Product2[] bundles = [SELECT Id, UnitCost__c FROM Product2 WHERE Id IN: bundleIds];

		System.debug('Bundles ' + bundles);
		for(Product2 bundle : bundles){
			bundle.UnitCost__c = 0;
			for(BOM__c bom : boms){
				if(bundle.Id == bom.BundleId__c){
					System.debug('BOM Id: ' + bom.Id);
					System.debug('Bundle Id: ' + bundle.Id);
					System.debug('BOM Bundle Id: ' + bom.BundleId__c);
					System.debug('BOM Quantity Id: ' + bom.Quantity__c);
					System.debug('BOM Bundle Item Id: ' + bom.BundleItemId__c);
					System.debug('BOM Bundle Item Unit Cost: ' + bom.BundleItemId__r.UnitCost__c);
					bundle.UnitCost__c += (bom.BundleItemId__r.UnitCost__c * bom.Quantity__c);
				}
			}
		}
		update bundles;
	}*/
}