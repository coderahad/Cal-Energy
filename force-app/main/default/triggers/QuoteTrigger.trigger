trigger QuoteTrigger on Quote (after update) {
    if(inv_QuoteTriggerHandler.disableTrigger == True) return;
  

    // if(Trigger.isAfter){
    //     inv_QuoteTriggerHandler.handleAfterTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    // }
}