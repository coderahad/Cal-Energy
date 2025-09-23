trigger inv_AccountTrigger on Account (after insert) {
    if(inv_AccountTriggerHandler.disableTrigger == True) return;
    // if(Trigger.isBefore){
    //     inv_OpportunityTriggerHandler.handleBeforeTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    // }

    if(Trigger.isAfter){
        inv_AccountTriggerHandler.handleAfterTrigger(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
    }
}