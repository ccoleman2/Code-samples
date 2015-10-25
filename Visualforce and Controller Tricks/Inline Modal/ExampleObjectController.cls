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

	public void saveExistingAccount(){
		if(newExampleObject.Account__c == null) closePopup();
		Account existingAccount = [SELECT Id, Name FROM Account WHERE Id = :newExampleObject.Account__c];
		accountNameString = existingAccount.Name;
		closePopup();
	}

	public void createNewAccount(){
		if(newAccount.Name == null) closePopup();
		insert newAccount;
		newExampleObject.Account__c = newAccount.Id;
		accountNameString = newAccount.Name;
		closePopup();
	}

	public void save(){
		insert newExampleObject;
	}

}