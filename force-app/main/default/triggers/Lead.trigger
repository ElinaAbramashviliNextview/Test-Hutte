trigger Lead on Lead (before insert)  { 
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. BI-------        > Remove default Country if other values are blank
----------------------------------------------------------------------------------------------------------------------
*/

	/* 0. */	
	if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
		for(Lead n : Trigger.new){
			If(String.isNotEmpty(n.CountryCode) &&
				String.isEmpty(n.PostalCode) && String.isEmpty(n.StateCode) && String.isEmpty(n.City) && String.isEmpty(n.Street)){
				n.CountryCode = null;
			}
		}
	}
}