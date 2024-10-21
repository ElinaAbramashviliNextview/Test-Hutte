public without sharing class NewProductTechniciansVFController  {

	public String editProdId {get;set;}

	public NewProductTechniciansVFController(ApexPages.StandardController stdc){
		this.editProdId = Apexpages.currentpage().getparameters().get('prodId');
	}
}