// MOST RECENT SOLUTION ////////////////////////////////////////////////////////////////////////////////////////
try {
	//idsToRecall.add(approvalProcessMap.get(step.approvalStep.Id));
	System.debug('TRIED DOING IT NATURALLY');
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
		|| UserInfo.getUserId() == step.approvalStep.Assigned_Approver__c)
	{
		System.debug('NOW HAFTA DO IT VIA BATCH');
		Approval_Step_Recall_Request__c approvalStepToRecall = new Approval_Step_Recall_Request__c();
		approvalStepToRecall.Approval_Step__c = step.approvalStep.Id;
		approvalStepToRecall.Work_Item_Id__c = approvalProcessMap.get(step.approvalStep.Id);
		approvalStepToRecall.Status__c = 'Pending';
		insert approvalStepToRecall;
		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Your recall request has been submitted. Please allow some time for the system to process it.');
		ApexPages.addMessage(myMsg);
	} else {
		System.debug('UNAUTHORIZED RECALL');
		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ask the Controlled Document owner, the Exec Sec assignee, or an administrator to recall the step manually.');
		ApexPages.addMessage(myMsg);
	}
}