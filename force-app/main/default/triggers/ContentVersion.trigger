trigger ContentVersion on ContentVersion (after insert) {
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
Do nothing for now - trigger were previously created for functionality which is not used anymore and code was deleted
----------------------------------------------------------------------------------------------------------------------
*/
	if(trigger.isAfter || trigger.isInsert){ }
}