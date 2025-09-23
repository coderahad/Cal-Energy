trigger inv_ProductTrigger on Product2 (after update, after insert) {
    if(inv_ProductTriggerHandler.disableTrigger == True) return;
    // if(Trigger.isBefore){
    //     inv_OpportunityTriggerHandler.handleBeforeTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    // }

    if(Trigger.isAfter){
        inv_ProductTriggerHandler.handleAfterTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    }
}