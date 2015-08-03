@RestResource(urlMapping='/ApprovalStep/*')
global class ApprovalStepRESTCallout{

    global static boolean isTest = false;

    @HttpGet
    global static String doGet(){
        try {
            System.debug('MADE IT TO THE CALLOUT');
            List<String> workItemIdList;
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            if(!isTest){
                String workItemIds = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
                workItemIdList = getWorkItemIdList(workItemIds);
            }else {
                workItemIdList = new List<String>();
                workItemIdList.add('123');
                workItemIdList.add('456');
                workItemIdList.add('789');
                workItemIdList.add('012');
                workItemIdList.add('345');
                workItemIdList.add('123');
                workItemIdList.add('456');
                workItemIdList.add('789');
                workItemIdList.add('012');
                workItemIdList.add('345');
            }
            for(String workItemId : workItemIdList){
                Approval.ProcessWorkItemRequest recallRequest = new Approval.ProcessWorkItemRequest();
                recallRequest.setWorkItemId(workItemId);
                recallRequest.setAction('Removed');
                if(!isTest) Approval.process(recallRequest);
            }
            return 'Success!';
        } catch (Exception e){
            System.debug('CALLOUT FAILED');
            return 'Failed to recall approval step';
        }
    }

    /*
        This function takes the end of our REST call and turns it into a list
        Example:
            REST call: https://na14.my.salesforce.com/
    */
    private static List<String> getWorkItemIdList(String workItemIds){
        return new List<String>(workItemIds.split(',',0));
    }

}