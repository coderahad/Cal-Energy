public class Inv_WorkPlanSortByWorkStepStatus {
    
    public class WorkPlanInput {
        @InvocableVariable(required=true)
        public List<WorkPlan> workPlan;
    }
    
    public class WorkPlanIdOutput {
        @InvocableVariable
        public List<Id> workplanId;
    }
    /*
	@InvocableMethod(label='Get Work Plans with Completed Steps'
                     description='Finds Work Plans of a Work Order that have completed steps')
    public static List<WorkPlan> getWorkPlans(List<WorkPlan> middayworkplans) {
        List<WorkPlan> listOfWorkPlanWithCompletedStep = new List<WorkPlan>();
        if (middayworkplans.isEmpty() || middayworkplans[0].workOrderId == null) {
            return listOfWorkPlanWithCompletedStep;
        }
        Id workOrderId = middayworkplans[0].WorkOrderId;
        
        Set<Id> workPlanIds = new Set<Id>();
        for(WorkStep ws: [SELECT Id, WorkPlanId From WorkStep Where WorkPlan.WorkOrderId = :workOrderId AND Status = 'Completed']) {
            workPlanIds.add(ws.WorkPlanId);
        }
        
        listOfWorkPlanWithCompletedStep = [SELECT Id, Name From WorkPlan Where WorkOrderId IN :workPlanIds]; 
        return listOfWorkPlanWithCompletedStep;
    }
  */
    
    @InvocableMethod(label='Get Work Plans with Completed Steps' description='Finds Work Plans of a Work Order that have completed steps')
    public static List<WorkPlanIdOutput> getWorkPlans(List<WorkPlanInput> middayworkplans) {
        system.debug('middayworkplans=='+middayworkplans);
        WorkPlanInput wpInp = middayworkplans[0];
        List<WorkPlan> listWP = wpInp.workPlan;
       // List<WorkPlan> listOfWorkPlanWithCompletedStep = new List<WorkPlan>();
        
       // List<Id> workPlanIds = new List<Id>();
        
        List<WorkPlanIdOutput> workPlanOutputs = new List<WorkPlanIdOutput>();
        
        if (listWP.isEmpty() || listWP[0].workOrderId == null) {
            return workPlanOutputs;
        }
        
        Id workOrderId = listWP[0].WorkOrderId;
        
        
        List<Id> listIds = new List<Id>();
        WorkPlanIdOutput wpio = new WorkPlanIdOutput();
        for(WorkStep ws: [SELECT Id, WorkPlanId From WorkStep Where WorkPlan.WorkOrderId = :workOrderId AND Status = 'Completed' AND WorkPlanId != null]) {
            system.debug('ws :'+ws);
            listIds.add(ws.WorkPlanId);
            //wpio.workplanId.add(ws.id);
        }
         wpio.workplanId = listIds;
         workPlanOutputs.add(wpio);
        
        System.debug(workPlanOutputs);
        return workPlanOutputs;
       // listOfWorkPlanWithCompletedStep = [SELECT Id, Name From WorkPlan Where WorkOrderId IN :workPlanIds];
       // System.debug(listOfWorkPlanWithCompletedStep);
       // System.debug(listOfWorkPlanWithCompletedStep.size());
       // return listOfWorkPlanWithCompletedStep;
    }
}