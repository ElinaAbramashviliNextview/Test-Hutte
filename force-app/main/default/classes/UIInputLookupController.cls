public with sharing class UIInputLookupController {
	public class LookupException extends Exception {}

	@AuraEnabled
	public static SObject[] apexSearch(String so, String q, String[]findBy, String[]fields, string andClause, Boolean showRecent, String orderBy){
		SObject[] res = new SObject[]{};
		if(string.isBlank(so)) return res;
		if(findBy == null || findBy.isEmpty()) findBy = new String[]{'Name'};
		if(fields == null || fields.isEmpty()) fields = new String[]{'Name'};

		// Search
		String whereClause = '';
		String orderClause = '';
		if(String.IsBlank(q) && showRecent){
			//if(!showRecent){ return new SObject[]{};}
			RecentlyViewed[] recent = [SELECT Id FROM RecentlyViewed WHERE Type =:so ORDER BY LastViewedDate DESC LIMIT 10];
			Set<Id> recentIds = (new Map<Id,RecentlyViewed>(recent)).keySet();
			whereClause = 'Id IN:recentIds';
		}else{
			for(String f: findBy){
				if(!String.isBlank(whereClause)) whereClause += ' OR ';
				whereClause += f + ' LIKE \'%'+ String.escapeSingleQuotes(q) + '%\' ';
		   	}
		}
		if(!string.isBlank(andClause)){
					 whereClause = '('+whereClause+') AND ' + andClause;
		}
		if(!String.isBlank(orderBy)){
			orderClause = ' ORDER BY ' + orderBy;
		}
		String query = 'SELECT ' + String.join(fields,',') + ' FROM ' + so + ' WHERE ' + whereClause + orderClause + ' LIMIT 300';
		System.debug('Query ' + query);
		return Database.query(query);
	}
}