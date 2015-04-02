public static void createApprovalStepPermissions(){
	PermissionSet pset = new PermissionSet();
	pset.Name = 'ModifyAllApprovalSteps_for_' + UserInfo.getFirstName() + '_' + UserInfo.getLastName();
	pset.Label = 'ModifyAllApprovalSteps_for_' + UserInfo.getFirstName() + '_' + UserInfo.getLastName();
	insert pset;

	ObjectPermissions CDObjPermissions = new ObjectPermissions();
	CDObjPermissions.ParentId = pset.Id;
	CDObjPermissions.SobjectType = 'Custom_Object__c'; // this is the parent object to the custom approval step below
	CDObjPermissions.PermissionsRead = true;
	CDObjPermissions.PermissionsViewAllRecords = true;
	insert CDObjPermissions;

	// this is a custom approval step named Approval_Step__c
	ObjectPermissions AStepObjPermissions = new ObjectPermissions();
	AStepObjPermissions.ParentId = pset.Id;
	AStepObjPermissions.SobjectType = 'Approval_Step__c';
	AStepObjPermissions.PermissionsRead = true;
	AStepObjPermissions.PermissionsEdit = true;
	AStepObjPermissions.PermissionsDelete = true;
	AStepObjPermissions.PermissionsViewAllRecords = true;
	AStepObjPermissions.PermissionsModifyAllRecords = true;
	insert AStepObjPermissions;

	PermissionSetAssignment psetAssign = new PermissionSetAssignment();
	psetAssign.AssigneeId = UserInfo.getUserId();
	psetAssign.PermissionSetId = pset.Id;
	insert psetAssign;
}

// attempts to delete the permission set above using a LIKE query - this will look for any permission set that starts with querystring
public static void deleteApprovalStepPermissions(){
	String queryString = 'ModifyAllApprovalSteps_for_%';
	List<PermissionSet> pset = [SELECT Id FROM PermissionSet WHERE Name LIKE :queryString];
	if(pset.size() > 0){
		List<PermissionSetAssignment> psetAssignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :pset[0].Id];
		delete psetAssignments;
		delete pset;
	}
}