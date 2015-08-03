public void recallSelected(){
	Map<Id, Id> approvalProcessMap = new Map<Id, Id>();
	Set<Id> approvalStepIds = new Set<Id>();
	for(ApprovalStepSelect step : approvalStepSelects){
		approvalStepIds.add(step.approvalStep.id);
	}

	for(ProcessInstanceWorkItem approvalProcessItem : getProcessWorkItems(approvalStepIds)){
		approvalProcessMap.put(approvalProcessItem.ProcessInstance.TargetObjectId, approvalProcessItem.Id);
	}

	// list of work item ids to process in web callout
	List<String> workItemIdList = new List<String>();

	List<Id> idsToRecall = new List<Id>();
	for(ApprovalStepSelect step : approvalStepSelects){
		if(step.selected && !step.approvalStep.Marked_For_Deletion__c && approvalProcessMap.get(step.approvalStep.Id) != null){
			// REST SOLUTION //////////////////////////////////////////////////////////////////////////////////////////////
			try {
				System.debug('TRYING TO DO NORMALLY');
				Approval.ProcessWorkItemRequest recallRequest = new Approval.ProcessWorkItemRequest();
				recallRequest.setWorkItemId(approvalProcessMap.get(step.approvalStep.Id));
				recallRequest.setAction('Removed');
				Approval.process(recallRequest);
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your recall request has been processed.');
				ApexPages.addMessage(myMsg);
			} catch (Exception e){
				System.debug('INSIDE RECALL CATCH');
				if(UserInfo.getUserId() == cdoc.OwnerId 
					|| UserInfo.getUserId() == cdoc.Assignee__c 
					|| UserInfo.getUserId() == step.approvalStep.Assigned_Approver__c
					|| UserInfo.getUserId() == step.approvalStep.CreatedById)
				{
					String workItemId = approvalProcessMap.get(step.approvalStep.Id);
					workItemIdList.add(workItemId);
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your recall request has been submitted. Please refresh the Controlled Document page.');
					ApexPages.addMessage(myMsg);
				} else {
					System.debug('UNAUTHORIZED RECALL');
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ask the Controlled Document owner, the assigned approver, the Exec Sec assignee, or an administrator to recall the step manually.');
					ApexPages.addMessage(myMsg);
				}
			}
			///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		}
	}
	// the actual rest callout function
	if(workItemIdList.size() != 0 && !isRecallTest){
		recallListCallout(workItemIdList);
	}
	initializeSteps();
	addNewStep();
	determineNoRowsSelected();
}

// the reason we do this callout in the future is due to our attempt to recall naturally before hand
// and the only reason we're not doing every recall request this way is that we want to keep an actual record
// of has submitted for the recall if possible - otherwise use our approver integration user
// of course, later we can adopt a new object that would store all of these requests for us
@Future(callout=true)
public static void recallListCallout(List<String> workItemIdList){
	String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
	String endpoint = baseURL.replace('--c.','.');
	endpoint = endpoint.replace('.visual.','.my.');
	endpoint = endpoint.replace('.force.','.salesforce.');

	List<Approval_Recall_User__c> approvalRecallUserList = [SELECT Id, Name, Client_Id__c, Client_Secret__c, Password__c, Token__c, Username__c 
																FROM Approval_Recall_User__c 
																LIMIT 1];

	if(approvalRecallUserList.size() == 0) {
		System.debug('ApprovalStepSelectManager.cls - Approval Recall User records not found - check custom settings');
		return;
	}

	String oauthendpoint = endpoint + '/services/oauth2/token';
	String clientId = approvalRecallUserList[0].Client_Id__c;
	String clientSecret = approvalRecallUserList[0].Client_Secret__c;
	String username = EncodingUtil.urlEncode(approvalRecallUserList[0].Username__c, 'UTF-8');
	String password = approvalRecallUserList[0].Password__c + approvalRecallUserList[0].Token__c;
	String reqbody = 'grant_type=password'
				+ '&client_id=' + clientId
				+ '&client_secret='+ clientSecret 
				+ '&username=' + username 
				+ '&password=' + password;
	System.debug('reqbody = ' + reqbody);
	
	HttpRequest oauthrequest = new HttpRequest();
	oauthrequest.setMethod('POST');
	oauthrequest.setEndpoint(oauthendpoint);
	oauthrequest.setBody(reqbody);
	Http http1 = new Http();
	HttpResponse res = http1.send(oauthrequest);
	System.debug(res);
	System.debug(res.getBody());

	String accesstoken;
	JSONParser parser = JSON.createParser(res.getBody());
	while(parser.nextToken() != null) {
		if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
			String fieldName = parser.getText();
			parser.nextToken();
			if(fieldName == 'access_token') {
				accesstoken = parser.getText();
			}
		}
	}

	if(accesstoken == null && !isRecallTest) return;

	/*
		This code takes the list workItemIdList and creates a string that is the base endpoint with the addition of each workItemId separated by a comma
		For example:
			base endpoint: https://na14.salesforce.com/services/apexrest/ApprovalStep/
			workItemIdList: {'1234','5657','0000'}
			actual endpoint: https://na14.salesforce.com/services/apexrest/ApprovalStep/1234,5657,0000
	*/
	String approvalendpoint = endpoint + '/services/apexrest/ApprovalStep/';
	for(Integer i = 0; i < workItemIdList.size(); i++){
		if(i == (workItemIdList.size()-1)){
			approvalendpoint += workItemIdList.get(i);
			continue;
		}
		approvalendpoint += workItemIdList.get(i) + ',';
	}
	System.debug('ENDPOINT = ' + approvalendpoint);		
	
	// doing 99 callouts because we've already done the one above
	for(Integer i = 0; i < 99; i++){
		HttpRequest request = new HttpRequest();
		//request.setEndpoint('callout:Approval_REST_Credentials/' + approvalendpoint);
		request.setEndpoint(approvalendpoint);
		request.setMethod('GET');
		request.setHeader('Authorization','Bearer ' + accesstoken);

		Http http2 = new Http();
		HttpResponse response = http2.send(request);
		System.debug( i + '). RESPONSE = ' + response );
		System.debug( i + '). RESPONSE.body = ' + response.getBody() );
		if(response.getBody() != null && 
			(response.getBody().contains('Success!') || response.getBody().contains('Failed'))) {
				break;
		}
	}
}