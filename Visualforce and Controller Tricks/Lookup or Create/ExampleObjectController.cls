public class ExampleObjectController{

	public Example_Object__c newExampleObject {get; set;}
	public Account newAccount {get; set;}
	public String accountNameString {get; set;}
	public boolean displayPopup {get; set;}

	public IDP_ExampleObjectController(){
		newExampleObject = new Example_Object__c();
		newAccount = new Account();
	}

	public void closePopup() {
		displayPopup = false;
	}

	public void showPopup() {
		displayPopup = true;
	}

	public void createNewAccount(){
		if(newAccount.Name == null) closePopup();
		insert newAccount;
		newExampleObject.Account__c = newAccount.Id;
		accountNameString = newAccount.Name;
		closePopup();
	}

	public PageReference save(){
		insert newExampleObject;
		PageReference redirectPage = new ApexPages.StandardController(newExampleObject).view();
		redirectPage.setRedirect(true);
		return redirectPage;
	}

}