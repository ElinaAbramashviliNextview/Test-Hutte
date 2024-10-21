trigger QuoteLineSubItem on QuoteLineSubItem__c (before insert, before update)  { 
	
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. BIU----        > Fill CurrencyIsoCode by QuoteLineItem
----------------------------------------------------------------------------------------------------------------------
*/

	// GLOBAL TRIGGER DISABLE
    TriggerSettings__c userTs = TriggerSettings__c.getInstance( UserInfo.getUserID() );
    TriggerSettings__c profileTs = TriggerSettings__c.getInstance( UserInfo.getProfileId() );
    // Return if all or curent trigger disabled
    if((userTs != null && (userTs.Disable_All__c || userTs.DisableQuoteLineSubItem__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.DisableQuoteLineSubItem__c))) return;

	for(QuoteLineSubItem__c n : Trigger.new){
		n.CurrencyIsoCode = n.QuoteLineItemId__r.CurrencyIsoCode;
	}
}