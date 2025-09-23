trigger projectTrigger on Opportunity (after update) {
    if(inv_ProjectTriggerHandler.disableTrigger == True) return;
  

    if(Trigger.isAfter){
        inv_ProjectTriggerHandler.handleAfterTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    }
}